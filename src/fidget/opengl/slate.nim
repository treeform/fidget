import flippy, snappy, streams, strformat

type SlateImage* = object
  mipmaps*: seq[Image]

func width*(slate: SlateImage): int =
  slate.mipmaps[0].width

func height*(slate: SlateImage): int =
  slate.mipmaps[0].height

proc save*(slate: SlateImage, filePath: string) =
  ## Slate is a special file format that is fast to load and save with mip maps.
  var f = newFileStream(filePath, fmWrite)
  defer: f.close()

  f.write("slate!!\0")
  for mip in slate.mipmaps:
    var zipped = snappy.compress(mip.data)
    f.write("mip!")
    f.write(mip.width.uint32)
    f.write(mip.height.uint32)
    f.write(len(zipped).uint32)
    f.writeData(zipped[0].addr, len(zipped))

proc pngToSlate*(pngPath, slatePath: string) =
  var
    image = loadImage(pngPath)
    slate = SlateImage()
  image.alphaBleed()
  var mip = image
  while true:
    slate.mipmaps.add mip
    if mip.width == 1 or mip.height == 1:
      break
    mip = mip.minify(2)
  slate.save(slatePath)

proc loadSlate*(filePath: string): SlateImage =
  ## Slate is a special file format that is fast to load and save with mip maps.
  var f = newFileStream(filePath, fmRead)
  defer: f.close()

  if f.readStr(8) != "slate!!\0":
    raise newException(Exception, &"Invalid slate header {filePath}.")

  while not f.atEnd():
    if f.readStr(4) != "mip!":
      raise newException(Exception, &"Invalid slate sub header {filePath}.")

    var mip = Image()
    mip.width = int f.readUint32()
    mip.height = int f.readUint32()
    mip.channels = 4
    let zippedLen = f.readUint32().int
    var zipped = newSeq[uint8](zippedLen)
    let read = f.readData(zipped[0].addr, zippedLen)
    if read != zippedLen:
      raise newException(Exception, "Slate read error.")
    mip.data = snappy.uncompress(zipped)
    result.mipmaps.add(mip)
