import unicode
import vmath


type
  Button* = enum
    UNBOUND = 0

    MOUSE_LEFT = 1
    MOUSE_RIGHT = 2
    MOUSE_MIDDLE = 3

    SPACE = 32
    APOSTROPHE = 39
    COMMA = 44
    MINUS = 45
    PERIOD = 46
    SLASH = 47
    NUMBER_0 = 48
    NUMBER_1 = 49
    NUMBER_2 = 50
    NUMBER_3 = 51
    NUMBER_4 = 52
    NUMBER_5 = 53
    NUMBER_6 = 54
    NUMBER_7 = 55
    NUMBER_8 = 56
    NUMBER_9 = 57
    SEMICOLON = 59
    EQUAL = 61
    LETTER_A = 65
    LETTER_B = 66
    LETTER_C = 67
    LETTER_D = 68
    LETTER_E = 69
    LETTER_F = 70
    LETTER_G = 71
    LETTER_H = 72
    LETTER_I = 73
    LETTER_J = 74
    LETTER_K = 75
    LETTER_L = 76
    LETTER_M = 77
    LETTER_N = 78
    LETTER_O = 79
    LETTER_P = 80
    LETTER_Q = 81
    LETTER_R = 82
    LETTER_S = 83
    LETTER_T = 84
    LETTER_U = 85
    LETTER_V = 86
    LETTER_W = 87
    LETTER_X = 88
    LETTER_Y = 89
    LETTER_Z = 90
    LEFT_BRACKET = 91
    BACKSLASH = 92
    RIGHT_BRACKET = 93
    GRAVE_ACCENT = 96
    WORLD_1 = 161
    WORLD_2 = 162

#[ Function keys ]#
    ESCAPE = 256
    ENTER = 257
    TAB = 258
    BACKSPACE = 259
    INSERT = 260
    DELETE = 261
    RIGHT = 262
    LEFT = 263
    DOWN = 264
    UP = 265
    PAGE_UP = 266
    PAGE_DOWN = 267
    HOME = 268
    END = 269
    CAPS_LOCK = 280
    SCROLL_LOCK = 281
    NUM_LOCK = 282
    PRINT_SCREEN = 283
    PAUSE = 284
    F1 = 290
    F2 = 291
    F3 = 292
    F4 = 293
    F5 = 294
    F6 = 295
    F7 = 296
    F8 = 297
    F9 = 298
    F10 = 299
    F11 = 300
    F12 = 301
    F13 = 302
    F14 = 303
    F15 = 304
    F16 = 305
    F17 = 306
    F18 = 307
    F19 = 308
    F20 = 309
    F21 = 310
    F22 = 311
    F23 = 312
    F24 = 313
    F25 = 314
    KP_0 = 320
    KP_1 = 321
    KP_2 = 322
    KP_3 = 323
    KP_4 = 324
    KP_5 = 325
    KP_6 = 326
    KP_7 = 327
    KP_8 = 328
    KP_9 = 329
    KP_DECIMAL = 330
    KP_DIVIDE = 331
    KP_MULTIPLY = 332
    KP_SUBTRACT = 333
    KP_ADD = 334
    KP_ENTER = 335
    KP_EQUAL = 336
    LEFT_SHIFT = 340
    LEFT_CONTROL = 341
    LEFT_ALT = 342
    LEFT_SUPER = 343
    RIGHT_SHIFT = 344
    RIGHT_CONTROL = 345
    RIGHT_ALT = 346
    RIGHT_SUPER = 347

  ModKey* = enum
    SHIFT = 0x0001
    CONTROL = 0x0002
    ALT = 0x0004
    SUPER = 0x0008


var
  buttonDown* = newSeq[bool](348)
  buttonUp* = newSeq[bool](348)
  buttonToggle* = newSeq[bool](348)
  buttonPress* = newSeq[bool](348)

  mousePos*: Vec2
  mousePosPrev*: Vec2
  mouseDelta*: Vec2
  mouseWheelDelta*: float

  typingMode*: bool
  typingCursor*: int
  typingRunes* = newSeq[Rune]()
  typingText*: string


proc `[]`*(buttons: seq[bool], button:Button): bool =
  return buttons[cast[int](button)]

proc `[]=`*(buttons: var seq[bool], button:Button, value: bool) =
  buttons[cast[int](button)] = value




