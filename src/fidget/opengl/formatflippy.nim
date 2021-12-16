import pixie, streams, supersnappy, chroma, strformat

const version = 1

type
  Flippy* = object
    mipmaps*: seq[Image]

func width*(flippy: Flippy): int =
  flippy.mipmaps[0].width

func height*(flippy: Flippy): int =
  flippy.mipmaps[0].height

proc alphaBleed*(image: Image) =
  ## PNG saves space by encoding alpha = 0 areas as black however
  ## scaling such images lets the black or gray come out.
  ## This bleeds the real colors into invisible space.

  proc minifyBy2Alpha(image: Image): Image =
    ## Scales the image down by an integer scale.
    result = newImage(image.width div 2, image.height div 2)
    for y in 0 ..< result.height:
      for x in 0 ..< result.width:
        var
          sumR = 0
          sumG = 0
          sumB = 0
          count = 0
        proc use(rgba: ColorRGBA) =
          if rgba.a > 0.uint8:
            sumR += int rgba.r
            sumG += int rgba.g
            sumB += int rgba.b
            count += 1
        use image.unsafe[x * 2 + 0, y * 2 + 0]
        use image.unsafe[x * 2 + 1, y * 2 + 0]
        use image.unsafe[x * 2 + 1, y * 2 + 1]
        use image.unsafe[x * 2 + 0, y * 2 + 1]
        if count > 0:
          var rgba: ColorRGBA
          rgba.r = uint8(sumR div count)
          rgba.g = uint8(sumG div count)
          rgba.b = uint8(sumB div count)
          rgba.a = 255
          result.unsafe[x, y] = rgba

  # scale image down in layers, only using opaque pixels
  var
    layers: seq[Image]
    min = image.minifyBy2Alpha()
  while min.width >= 2 and min.height >= 2:
    layers.add min
    min = min.minifyBy2Alpha()

  # walk over all transparent pixels, going up layers to find best colors
  for y in 0 ..< image.height:
    for x in 0 ..< image.width:
      var rgba = image.unsafe[x, y]
      if rgba.a == 0:
        var
          xs = x
          ys = y
        for l in layers:
          xs = min(xs div 2, l.width - 1)
          ys = min(ys div 2, l.height - 1)
          rgba = l.unsafe[xs, ys]
          if rgba.a > 0.uint8:
            break
        rgba.a = 0
      image.unsafe[x, y] = rgba

proc save*(flippy: Flippy, filePath: string) =
  ## Flippy is a special file format that is fast to load and save with mip maps.
  var f = newFileStream(filePath, fmWrite)
  defer: f.close()

  f.write("flip")
  f.write(version.uint32)
  for mip in flippy.mipmaps:
    # TODO Talk to Ryan about format data compression.
    var s = newStringStream()
    for c in mip.data:
      s.write(c.color.rgba())
    s.setPosition(0)
    var stringData = s.readAll()
    var zipped = compress(stringData)
    #var zipped = compress(mip.data)

    f.write("mip!")
    f.write(mip.width.uint32)
    f.write(mip.height.uint32)
    f.write(len(zipped).uint32)
    f.writeData(zipped[0].addr, len(zipped))

proc pngToFlippy*(pngPath, flippyPath: string) =
  var
    image = readImage(pngPath)
    flippy = Flippy()
  image.alphaBleed()
  var mip = image
  while true:
    flippy.mipmaps.add mip
    if mip.width == 1 or mip.height == 1:
      break
    mip = mip.minifyBy2()
  flippy.save(flippyPath)

proc loadFlippy*(filePath: string): Flippy =
  ## Flippy is a special file format that is fast to load and save with mip maps.
  var f = newFileStream(filePath, fmRead)
  defer: f.close()

  if f.readStr(4) != "flip":
    raise newException(IOError, &"Invalid Flippy header {filePath}.")

  if f.readUint32() != version:
    raise newException(IOError, &"Invalid Flippy version {filePath}.")

  while not f.atEnd():
    if f.readStr(4) != "mip!":
      raise newException(IOError, &"Invalid Flippy sub header {filePath}.")

    var mip = Image()
    mip.width = int f.readUint32()
    mip.height = int f.readUint32()
    let zippedLen = f.readUint32().int
    var zipped = newSeq[uint8](zippedLen)
    let read = f.readData(zipped[0].addr, zippedLen)
    if read != zippedLen:
      raise newException(IOError, "Flippy read error.")

    # TODO: Talk to ryan about compression
    var unzipped = uncompress(zipped)
    var s = newStringStream(cast[string](unzipped))
    mip.data = newSeq[ColorRGBX](mip.width * mip.height)
    for c in mip.data.mitems:
      var rgba: ColorRGBA
      s.read(rgba)
      c = rgba
    #mip.data = uncompress(zipped)

    result.mipmaps.add(mip)

proc outlineBorder*(image: Image, borderPx: int): Image =
  ## Adds n pixel border around alpha parts of the image.
  result = newImage(
    image.width + borderPx * 2,
    image.height + borderPx * 3,
  )
  for y in 0 ..< result.height:
    for x in 0 ..< result.width:
      var filled = false
      for bx in -borderPx .. borderPx:
        for by in -borderPx .. borderPx:
          var rgba = image[x + bx - borderPx, y - by - borderPx]
          if rgba.a > 0.uint8:
            filled = true
            break
        if filled:
          break
      if filled:
        result.unsafe[x, y] = rgba(255, 255, 255, 255)
