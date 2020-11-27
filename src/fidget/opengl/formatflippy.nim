import pixie, streams, supersnappy, chroma, strformat, vmath

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
        use image.getRgbaUnsafe(x * 2 + 0, y * 2 + 0)
        use image.getRgbaUnsafe(x * 2 + 1, y * 2 + 0)
        use image.getRgbaUnsafe(x * 2 + 1, y * 2 + 1)
        use image.getRgbaUnsafe(x * 2 + 0, y * 2 + 1)
        if count > 0:
          var rgba: ColorRGBA
          rgba.r = uint8(sumR div count)
          rgba.g = uint8(sumG div count)
          rgba.b = uint8(sumB div count)
          rgba.a = 255
          result.setRgbaUnsafe(x, y, rgba)

  # scale image down in layers, only using opaque pixels
  var
    layers: seq[Image]
    min = image.minifyBy2Alpha()
  while min.width >= 1 and min.height >= 1:
    layers.add min
    min = min.minifyBy2Alpha()

  # walk over all transparent pixels, going up layers to find best colors
  for y in 0 ..< image.height:
    for x in 0 ..< image.width:
      var rgba = image.getRgbaUnsafe(x, y)
      if rgba.a == 0:
        var
          xs = x
          ys = y
        for l in layers:
          xs = min(xs div 2, l.width - 1)
          ys = min(ys div 2, l.height - 1)
          rgba = l.getRgbaUnsafe(xs, ys)
          if rgba.a > 0.uint8:
            break
        rgba.a = 0
      image.setRgbaUnsafe(x, y, rgba)

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
      s.write(c)
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
    mip.data = newSeq[ColorRGBA](mip.width * mip.height)
    for c in mip.data.mitems:
      s.read(c)
    #mip.data = uncompress(zipped)

    result.mipmaps.add(mip)

proc fill2*(image: Image, rgba: ColorRGBA) =
  ## Fills the image with a solid color.
  var i = 0
  while i < image.data.len:
    cast[ptr uint32](image.data[i + 0].addr)[] = cast[uint32](rgba)
    # This accomplishes the same thing as:
    # image.data[i + 0] = rgba.r
    # image.data[i + 1] = rgba.g
    # image.data[i + 2] = rgba.b
    # image.data[i + 3] = rgba.a
    i += 4

proc blitUnsafe*(destImage: Image, srcImage: Image, src, dest: Rect) =
  ## Blits rectangle from one image to the other image.
  ## * No bounds checking *
  ## Make sure that src and dest rect are in bounds.
  ## Make sure that channels for images are the same.
  ## Failure in the assumptions will case unsafe memory writes.
  ## Note: Does not do alpha or color mixing.
  let c = 4
  for y in 0 ..< int(dest.h):
    let
      srcIdx = int(src.x) + (int(src.y) + y) * srcImage.width
      destIdx = int(dest.x) + (int(dest.y) + y) * destImage.width
    copyMem(
      destImage.data[destIdx*c].addr,
      srcImage.data[srcIdx*c].addr,
      int(dest.w) * c
    )

proc blit*(destImage: Image, srcImage: Image, src, dest: Rect) =
  ## Blits rectangle from one image to the other image.
  ## Note: Does not do alpha or color mixing.
  doAssert src.w == dest.w and src.h == dest.h
  doAssert src.x >= 0 and src.x + src.w <= srcImage.width.float32
  doAssert src.y >= 0 and src.y + src.h <= srcImage.height.float32

  # See if the image hits the bounds and needs to be adjusted.
  var
    src = src
    dest = dest
  if dest.x < 0:
    dest.w += dest.x
    src.x -= dest.x
    src.w += dest.x
    dest.x = 0
  if dest.x + dest.w > destImage.width.float32:
    let diff = destImage.width.float32 - (dest.x + dest.w)
    dest.w += diff
    src.w += diff
  if dest.y < 0:
    dest.h += dest.y
    src.y -= dest.y
    src.h += dest.y
    dest.y = 0
  if dest.y + dest.h > destImage.height.float32:
    let diff = destImage.height.float32 - (dest.y + dest.h)
    dest.h += diff
    src.h += diff

  # See if image is entirely outside the bounds:
  if dest.x + dest.w < 0 or dest.x > destImage.width.float32:
    return
  if dest.y + dest.h < 0 or dest.y > destImage.height.float32:
    return

  # Faster path using copyMem:
  blitUnsafe(destImage, srcImage, src, dest)

proc line*(image: Image, at, to: Vec2, rgba: ColorRGBA) =
  ## Draws a line from one at vec to to vec.
  let
    dx = to.x - at.x
    dy = to.y - at.y
  var x = at.x
  while true:
    if dx == 0:
      break
    let y = at.y + dy * (x - at.x) / dx
    image[int x, int y] = rgba
    if at.x < to.x:
      x += 1
      if x > to.x:
        break
    else:
      x -= 1
      if x < to.x:
        break

  var y = at.y
  while true:
    if dy == 0:
      break
    let x = at.x + dx * (y - at.y) / dy
    image[int x, int y] = rgba
    if at.y < to.y:
      y += 1
      if y > to.y:
        break
    else:
      y -= 1
      if y < to.y:
        break

proc fillRect*(image: Image, rect: Rect, rgba: ColorRGBA) =
  ## Draws a filled rectangle.
  let
    minX = max(int(rect.x), 0)
    maxX = min(int(rect.x + rect.w), image.width)
    minY = max(int(rect.y), 0)
    maxY = min(int(rect.y + rect.h), image.height)
  for y in minY ..< maxY:
    for x in minX ..< maxX:
      image.setRgbaUnsafe(x, y, rgba)

proc strokeRect*(image: Image, rect: Rect, rgba: ColorRGBA) =
  ## Draws a rectangle borders only.
  let
    at = rect.xy
    wh = rect.wh - vec2(1, 1) # line width
  image.line(at, at + vec2(wh.x, 0), rgba)
  image.line(at + vec2(wh.x, 0), at + vec2(wh.x, wh.y), rgba)
  image.line(at + vec2(0, wh.y), at + vec2(wh.x, wh.y), rgba)
  image.line(at + vec2(0, wh.y), at, rgba)

proc blit*(destImage: Image, srcImage: Image, pos: Vec2) =
  ## Blits rectangle from one image to the other image.
  ## Note: Does not do alpha or color mixing.
  destImage.blit(
    srcImage,
    rect(0.0, 0.0, srcImage.width.float32, srcImage.height.float32),
    rect(pos.x, pos.y, srcImage.width.float32, srcImage.height.float32)
  )

proc fillCircle*(image: Image, pos: Vec2, radius: float, rgba: ColorRGBA) =
  ## Draws a filled circle with antialiased edges.
  let
    minX = max(int(pos.x - radius), 0)
    maxX = min(int(pos.x + radius), image.width)
    minY = max(int(pos.y - radius), 0)
    maxY = min(int(pos.y + radius), image.height)
  for x in minX ..< maxX:
    for y in minY ..< maxY:
      let
        pixelPos = vec2(float x, float y) + vec2(0.5, 0.5)
        pixelDist = pixelPos.dist(pos)
      if pixelDist < radius - sqrt(0.5):
        image.setRgbaUnsafe(x, y, rgba)
      elif pixelDist < radius + sqrt(0.5):
        var touch = 0
        const n = 5
        const r = (n - 1) div 2
        for aay in -r .. r:
          for aax in -r .. r:
            if pos.dist(pixelPos + vec2(aay / n, aax / n)) < radius:
              inc touch
        var rgbaAA = rgba
        rgbaAA.a = uint8(float(touch) * 255.0 / (n * n))
        image.setRgbaUnsafe(x, y, rgbaAA)

proc strokeCircle*(
  image: Image, pos: Vec2, radius, border: float, rgba: ColorRGBA
) =
  ## Draws a border of circle with antialiased edges.
  let
    minX = max(int(pos.x - radius - border), 0)
    maxX = min(int(pos.x + radius + border), image.width)
    minY = max(int(pos.y - radius - border), 0)
    maxY = min(int(pos.y + radius + border), image.height)
  for y in minY ..< maxY:
    for x in minX ..< maxX:
      let
        pixelPos = vec2(float x, float y) + vec2(0.5, 0.5)
        pixelDist = pixelPos.dist(pos)
      if pixelDist > radius - border / 2 - sqrt(0.5) and
          pixelDist < radius + border / 2 + sqrt(0.5):
        var touch = 0
        const
          n = 5
          r = (n - 1) div 2
        for aay in -r .. r:
          for aax in -r .. r:
            let dist = pos.dist(pixelPos + vec2(aay / n, aax / n))
            if dist > radius - border/2 and dist < radius + border/2:
              inc touch
        var rgbaAA = rgba
        rgbaAA.a = uint8(float(touch) * 255.0 / (n * n))
        image.setRgbaUnsafe(x, y, rgbaAA)

proc fillRoundedRect*(
  image: Image, rect: Rect, radius: float, rgba: ColorRGBA
) =
  ## Fills image with a rounded rectangle.
  image.fill2(rgba)
  let
    borderWidth = radius
    borderWidthPx = int ceil(radius)
  var corner = newImage(borderWidthPx, borderWidthPx)
  corner.fillCircle(vec2(borderWidth, borderWidth), radius, rgba)
  image.blit(corner, vec2(0, 0))
  corner = corner.flipHorizontal()
  image.blit(corner, vec2(rect.w - borderWidth, 0)) # NE
  corner = corner.flipVertical()
  image.blit(corner, vec2(rect.w - borderWidth, rect.h - borderWidth)) # SE
  corner = corner.flipHorizontal()
  image.blit(corner, vec2(0, rect.h - borderWidth)) # SW

proc strokeRoundedRect*(
  image: Image, rect: Rect, radius, border: float, rgba: ColorRGBA
) =
  ## Fills image with a stroked rounded rectangle.
  #var radius = min(radius, rect.w/2)
  for i in 0 ..< int(border):
    let f = float i
    image.strokeRect(rect(
      rect.x + f,
      rect.y + f,
      rect.w - f * 2,
      rect.h - f * 2,
    ), rgba)
  let borderWidth = (radius + border / 2)
  let borderWidthPx = int ceil(borderWidth)
  var corner = newImage(borderWidthPx, borderWidthPx)
  corner.strokeCircle(vec2(borderWidth, borderWidth), radius, border, rgba)
  let s = borderWidth.ceil
  image.blit(corner, vec2(0, 0)) # NW
  corner = corner.flipHorizontal()
  image.blit(corner, vec2(rect.w - s, 0)) # NE
  corner = corner.flipVertical()
  image.blit(corner, vec2(rect.w - s, rect.h - s)) # SE
  corner = corner.flipHorizontal()
  image.blit(corner, vec2(0, rect.h - s)) # SW

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
        result.setRgbaUnsafe(x, y, rgba(255, 255, 255, 255))
