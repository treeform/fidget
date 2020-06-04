import vmath, chroma

type

  FontName* = object
    family*: string
    style*: string

  TextCase* = enum
    tcOriginal
    tcUpper
    tcLower
    tcTitle

  TextDecoration* = enum
    tdNone
    tdUnderline
    tdStrikeThrough

  ArcData* = object
    startingAngle*: float32
    endingAngle*: float32
    innerRadius*: float32

  BlendMode* = enum
    bmPassThrough
    bmNormal
    bmDarken
    bmMultiply
    bmLinearBurn
    bmColorBurn
    bmLighten
    bmScreen
    bmLinearDodge
    bmColorDodge
    bmOverlay
    bmSoftLight
    bmHardLight
    bmDifference
    bmExclusion
    bmHue
    bmSaturation
    bmColor
    bmLuminosity

  ShadowEffectKind* = enum
    seDropShadow
    seInnerShadow

  ShadowEffect* = object
    kind*: ShadowEffectKind
    color*: ColorRGBA
    offset*: Vec2
    radius: float32
    visible: bool
    blendMode: BlendMode

  BlurEffectKind* = enum
    beLayerBlur
    beBackgroundBlur

  BlurEffect* = object
    kind*: BlurEffectKind
    radius*: float32
    visible*: bool

  Effect* = ShadowEffect | BlurEffect

  ConstraintKind* = enum
    cMin
    cCenter
    cMax
    cStretch
    cScale

  Constraints* = object
    horizontal*: ConstraintKind
    vertical*: ConstraintKind

  SolidPaint* = object
    visible*: bool
    color*: ColorRGBA
    opacity*: float32
    blendMode*: BlendMode

  ColorStop* = object
    position*: float32
    color*: ColorRGBA

  GradientPaintKind* = enum
    GradientLinear
    GradientRadial
    GradientAngular
    GradientDiamond

  GradientPaint* = object
    kind*: GradientPaintKind
    gradientTransform*: Mat3
    gradientStops*: seq[ColorStop]

    visible*: bool
    opacity*: float32
    blendMode*: BlendMode

  ImageFilters* = object
    exposure*: float32
    contrast*: float32
    saturation*: float32
    temperature*: float32
    tint*: float32
    highlights*: float32
    shadows*: float32

  ImageScaleMode* = enum
    msFill
    msFit
    msCrop
    msTile

  ImagePaint* = object
    scaleMode: ImageScaleMode
    imageHash: string
    imageTransform: Mat3
    scalingFactor: float32
    filters: ImageFilters

    visible*: bool
    opacity*: float32
    blendMode*: BlendMode

  Paint* = SolidPaint | GradientPaint | ImagePaint

  WindingRule* = enum
    wrNonZero
    wrEvenOdd

  StrokeCap* = enum
    scNone
    scRound
    scSquare
    scArrowLines
    scArrowEquilateral

  StrokeJoin* = enum
    sjMiter
    sjBevel
    sjRound

  HandleMirroring* = enum
    hmNone
    hmAngle
    hmAngleAndLength

  VectorVertex* = object
    pos*: Vec2
    strokeCap*: StrokeCap
    strokeJoin*: StrokeJoin
    cornerRadius*: float32
    handleMirroring*: HandleMirroring
