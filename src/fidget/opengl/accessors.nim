import opengl

type
  AccessorKind* = enum
    akSCALAR, akVEC2, akVEC3, akVEC4, akMAT2, akMAT3, akMAT4

func size*(componentType: GLenum): Positive =
  case componentType:
    of cGL_BYTE, cGL_UNSIGNED_BYTE:
      1
    of cGL_SHORT, cGL_UNSIGNED_SHORT:
      2
    of GL_UNSIGNED_INT, cGL_FLOAT:
      4
    else:
      raise newException(Exception, "Unexpected componentType")

func componentCount*(accessorKind: AccessorKind): Positive =
  case accessorKind:
    of akSCALAR:
      1
    of akVEC2:
      2
    of akVEC3:
      3
    of akVEC4, akMAT2:
      4
    of akMAT3:
      9
    of akMAT4:
      16
