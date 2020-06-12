type
  Button* = enum
    UNBOUND = 0

    MOUSE_LEFT = 1
    MOUSE_RIGHT = 2
    MOUSE_MIDDLE = 3
    MOUSE_BACK = 4
    MOUSE_FORWARD = 5

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

    # Function keys
    ESCAPE = 256
    ENTER = 257
    TAB = 258
    BACKSPACE = 259
    INSERT = 260
    DELETE = 261
    ARROW_RIGHT = 262
    ARROW_LEFT = 263
    ARROW_DOWN = 264
    ARROW_UP = 265
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
  buttonRelease* = newSeq[bool](348)
  buttonToggle* = newSeq[bool](348)
  buttonPress* = newSeq[bool](348)

proc `[]`*(buttons: seq[bool], button: Button): bool =
  return buttons[cast[int](button)]

proc `[]=`*(buttons: var seq[bool], button: Button, value: bool) =
  buttons[cast[int](button)] = value

when defined(js):
  import tables

  let mouseButtonToButton* = {
    0: MOUSE_LEFT,
    2: MOUSE_RIGHT,
    1: MOUSE_MIDDLE,
    3: MOUSE_BACK,
    4: MOUSE_FORWARD,
  }.toTable()

  let keyCodeToButton* = {
    32: SPACE,
    222: APOSTROPHE,
    188: COMMA,
    189: MINUS,
    190: PERIOD,
    191: SLASH,
    48: NUMBER_0,
    49: NUMBER_1,
    50: NUMBER_2,
    51: NUMBER_3,
    52: NUMBER_4,
    53: NUMBER_5,
    54: NUMBER_6,
    55: NUMBER_7,
    56: NUMBER_8,
    57: NUMBER_9,
    186: SEMICOLON,
    187: EQUAL,
    65: LETTER_A,
    66: LETTER_B,
    67: LETTER_C,
    68: LETTER_D,
    69: LETTER_E,
    70: LETTER_F,
    71: LETTER_G,
    72: LETTER_H,
    73: LETTER_I,
    74: LETTER_J,
    75: LETTER_K,
    76: LETTER_L,
    77: LETTER_M,
    78: LETTER_N,
    79: LETTER_O,
    80: LETTER_P,
    81: LETTER_Q,
    82: LETTER_R,
    83: LETTER_S,
    84: LETTER_T,
    85: LETTER_U,
    86: LETTER_V,
    87: LETTER_W,
    88: LETTER_X,
    89: LETTER_Y,
    90: LETTER_Z,
    219: LEFT_BRACKET,
    220: BACKSLASH,
    221: RIGHT_BRACKET,
    192: GRAVE_ACCENT,
    0: WORLD_1,
    0: WORLD_2,

    # Function keys
    27: ESCAPE,
    13: ENTER,
    9: TAB,
    8: BACKSPACE,
    45: INSERT,
    46: DELETE,
    39: ARROW_RIGHT,
    37: ARROW_LEFT,
    40: ARROW_DOWN,
    38: ARROW_UP,
    33: PAGE_UP,
    34: PAGE_DOWN,
    36: HOME,
    35: END,
    20: CAPS_LOCK,
    145: SCROLL_LOCK,
    144: NUM_LOCK,
    44: PRINT_SCREEN,
    19: PAUSE,
    112: F1,
    113: F2,
    114: F3,
    115: F4,
    116: F5,
    117: F6,
    118: F7,
    119: F8,
    120: F9,
    121: F10,
    122: F11,
    124: F12,
    96: KP_0,
    97: KP_1,
    98: KP_2,
    99: KP_3,
    100: KP_4,
    101: KP_5,
    102: KP_6,
    103: KP_7,
    104: KP_8,
    105: KP_9,
    110: KP_DECIMAL,
    111: KP_DIVIDE,
    106: KP_MULTIPLY,
    109: KP_SUBTRACT,
    107: KP_ADD,
    0: KP_ENTER,
    0: KP_EQUAL,

    16: LEFT_SHIFT,
    17: LEFT_CONTROL,
    18: LEFT_ALT,
    91: LEFT_SUPER,
    0: RIGHT_SHIFT,
    0: RIGHT_CONTROL,
    0: RIGHT_ALT,
    92: RIGHT_SUPER,

    93: LEFT_SUPER

  }.toTable()
