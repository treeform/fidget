import streams, strformat
import flippy, snappy, print, opengl
import textures, perf


type SlateImage* = object
  mipmaps*: seq[Image]


proc width*(slate: SlateImage): int =
  slate.mipmaps[0].width


proc height*(slate: SlateImage): int =
  slate.mipmaps[0].height


proc save*(slate: SlateImage, filePath: string) =
  ## Slate is a special file format that is fast to load and save with mip maps
  var f = newFileStream(filePath, fmWrite)
  f.write("slate!!\0")
  for mip in slate.mipmaps:
    f.write("mip!")
    f.write(uint32 mip.width)
    f.write(uint32 mip.height)
    #f.writeData(unsafeAddr mip.data[0], mip.data.len)
    let zipped = snappy.compress(mip.data)
    f.write(uint32 zipped.len)
    f.writeData(unsafeAddr zipped[0], zipped.len)
  f.close()


proc pngToSlate*(pngPath, slatePath: string) =
  var image = loadImage(pngPath)
  var slate = SlateImage()
  image.alphaBleed()
  var mip = image
  while true:
    slate.mipmaps.add mip
    if mip.width == 1 or mip.height == 1:
      break
    mip = mip.minify(2)
  slate.save(slatePath)


proc loadSlate*(filePath: string): SlateImage =
  ## Slate is a special file format that is fast to load and save with mip maps
  var slate = SlateImage()
  var f = newFileStream(filePath, fmRead)
  if f.readStr(8) != "slate!!\0":
    raise newException(Exception, &"Invalid slate header {filePath}.")
  while not f.atEnd():
    if f.readStr(4) != "mip!":
      raise newException(Exception, &"Invalid slate sub header {filePath}.")
    var mip = Image()
    mip.width = int f.readUInt32()
    mip.height = int f.readUInt32()
    mip.channels = 4
    # mip.data = newSeq[uint8](mip.width * mip.height * 4)
    # let read = f.readData(unsafeAddr mip.data[0], mip.data.len)
    # if read != mip.data.len:
    #   raise newException(Exception, "Slate read error.")
    let zippedLen = int f.readUInt32()
    let zipped = newSeq[uint8](zippedLen)
    let read = f.readData(unsafeAddr zipped[0], zippedLen)
    if read != zippedLen:
      raise newException(Exception, "Slate read error.")
    mip.data = snappy.uncompress(zipped)
    slate.mipmaps.add mip

  return slate