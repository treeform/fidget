#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Declaration of the Document Object Model for the `JavaScript backend
## <backends.html#backends-the-javascript-target>`_.
# import std/private/since
template since(foo, body: untyped) = body
when not defined(js) and not defined(Nimdoc):
  {.error: "This module only works on the JavaScript platform".}

const
  DomApiVersion* = 3 ## the version of DOM API we try to follow. No guarantees though.

type
  EventTarget* = ref EventTargetObj
  EventTargetObj {.importc.} = object of RootObj
    onabort*: proc (event: Event) {.closure.}
    onblur*: proc (event: Event) {.closure.}
    onchange*: proc (event: Event) {.closure.}
    onclick*: proc (event: Event) {.closure.}
    ondblclick*: proc (event: Event) {.closure.}
    onerror*: proc (event: Event) {.closure.}
    onfocus*: proc (event: Event) {.closure.}
    onkeydown*: proc (event: Event) {.closure.}
    onkeypress*: proc (event: Event) {.closure.}
    onkeyup*: proc (event: Event) {.closure.}
    onload*: proc (event: Event) {.closure.}
    onmousedown*: proc (event: Event) {.closure.}
    onmousemove*: proc (event: Event) {.closure.}
    onmouseout*: proc (event: Event) {.closure.}
    onmouseover*: proc (event: Event) {.closure.}
    onmouseup*: proc (event: Event) {.closure.}
    onreset*: proc (event: Event) {.closure.}
    onselect*: proc (event: Event) {.closure.}
    onsubmit*: proc (event: Event) {.closure.}
    onunload*: proc (event: Event) {.closure.}
    onloadstart*: proc (event: Event) {.closure.}
    onprogress*: proc (event: Event) {.closure.}
    onloadend*: proc (event: Event) {.closure.}

  DomEvent* {.pure.} = enum
    ## see `docs<https://developer.mozilla.org/en-US/docs/Web/Events>`_
    Abort = "abort",
    BeforeInput = "beforeinput",
    Blur = "blur",
    Click = "click",
    CompositionEnd = "compositionend",
    CompositionStart = "compositionstart",
    CompositionUpdate = "compositionupdate",
    DblClick = "dblclick",
    Error = "error",
    Focus = "focus",
    FocusIn = "focusin",
    FocusOut = "focusout",
    Input = "input",
    KeyDown = "keydown",
    KeyPress = "keypress",
    KeyUp = "keyup",
    Load = "load",
    MouseDown = "mousedown",
    MouseEnter = "mouseenter",
    MouseLeave = "mouseleave",
    MouseMove = "mousemove",
    MouseOut = "mouseout",
    MouseOver = "mouseover",
    MouseUp = "mouseup",
    Resize = "resize",
    Scroll = "scroll",
    Select = "select",
    Unload = "unload",
    Wheel = "wheel"

  PerformanceMemory* {.importc.} = ref object
    jsHeapSizeLimit*: float
    totalJSHeapSize*: float
    usedJSHeapSize*: float

  PerformanceTiming* {.importc.} = ref object
    connectStart*: float
    domComplete*: float
    domContentLoadedEventEnd*: float
    domContentLoadedEventStart*: float
    domInteractive*: float
    domLoading*: float
    domainLookupEnd*: float
    domainLookupStart*: float
    fetchStart*: float
    loadEventEnd*: float
    loadEventStart*: float
    navigationStart*: float
    redirectEnd*: float
    redirectStart*: float
    requestStart*: float
    responseEnd*: float
    responseStart*: float
    secureConnectionStart*: float
    unloadEventEnd*: float
    unloadEventStart*: float

  Performance* {.importc.} = ref object
    memory*: PerformanceMemory
    timing*: PerformanceTiming

  Range* {.importc.} = ref object
    ## see `docs{https://developer.mozilla.org/en-US/docs/Web/API/Range}`_
    collapsed*: bool
    commonAncestorContainer*: Node
    endContainer*: Node
    endOffset*: int
    startContainer*: Node
    startOffset*: int

  Selection* {.importc.} = ref object
    ## see `docs<https://developer.mozilla.org/en-US/docs/Web/API/Selection>`_
    anchorNode*: Node
    anchorOffset*: int
    focusNode*: Node
    focusOffset*: int
    isCollapsed*: bool
    rangeCount*: int
    `type`*: cstring

  LocalStorage* {.importc.} = ref object

  Window* = ref WindowObj
  WindowObj {.importc.} = object of EventTargetObj
    document*: Document
    event*: Event
    history*: History
    location*: Location
    closed*: bool
    defaultStatus*: cstring
    devicePixelRatio*: float
    innerHeight*, innerWidth*: int
    locationbar*: ref LocationBar
    menubar*: ref MenuBar
    name*: cstring
    outerHeight*, outerWidth*: int
    pageXOffset*, pageYOffset*: int
    scrollX*: float
    scrollY*: float
    personalbar*: ref PersonalBar
    scrollbars*: ref ScrollBars
    statusbar*: ref StatusBar
    status*: cstring
    toolbar*: ref ToolBar
    frames*: seq[Frame]
    screen*: Screen
    performance*: Performance
    onpopstate*: proc (event: Event)
    localStorage*: LocalStorage

  Frame* = ref FrameObj
  FrameObj {.importc.} = object of WindowObj

  ClassList* = ref ClassListObj
  ClassListObj {.importc.} = object of RootObj

  NodeType* = enum
    ElementNode = 1,
    AttributeNode,
    TextNode,
    CDATANode,
    EntityRefNode,
    EntityNode,
    ProcessingInstructionNode,
    CommentNode,
    DocumentNode,
    DocumentTypeNode,
    DocumentFragmentNode,
    NotationNode

  Node* = ref NodeObj
  NodeObj {.importc.} = object of EventTargetObj
    attributes*: seq[Node]
    childNodes*: seq[Node]
    children*: seq[Node]
    data*: cstring
    firstChild*: Node
    lastChild*: Node
    nextSibling*: Node
    nodeName*: cstring
    nodeType*: NodeType
    nodeValue*: cstring
    parentNode*: Node
    content*: Node
    previousSibling*: Node
    ownerDocument*: Document
    innerHTML*: cstring
    outerHTML*: cstring
    innerText*: cstring
    textContent*: cstring
    style*: Style

  Document* = ref DocumentObj
  DocumentObj {.importc.} = object of NodeObj
    activeElement*: Element
    documentElement*: Element
    alinkColor*: cstring
    bgColor*: cstring
    body*: Element
    charset*: cstring
    cookie*: cstring
    defaultCharset*: cstring
    fgColor*: cstring
    head*: Element
    lastModified*: cstring
    linkColor*: cstring
    referrer*: cstring
    title*: cstring
    URL*: cstring
    vlinkColor*: cstring
    anchors*: seq[AnchorElement]
    forms*: seq[FormElement]
    images*: seq[ImageElement]
    applets*: seq[Element]
    embeds*: seq[EmbedElement]
    links*: seq[LinkElement]
    fonts*: FontFaceSet

  Element* = ref ElementObj
  ElementObj {.importc.} = object of NodeObj
    classList*: ClassList
    checked*: bool
    defaultChecked*: bool
    defaultValue*: cstring
    disabled*: bool
    form*: FormElement
    name*: cstring
    readOnly*: bool
    options*: seq[OptionElement]
    selectedOptions*: seq[OptionElement]
    clientWidth*, clientHeight*: int
    contentEditable*: cstring
    isContentEditable*: bool
    dir*: cstring
    offsetHeight*: int
    offsetWidth*: int
    offsetLeft*: int
    offsetTop*: int

  ValidityState* = ref ValidityStateObj ## see `docs<https://developer.mozilla.org/en-US/docs/Web/API/ValidityState>`_
  ValidityStateObj {.importc.} = object
    badInput*: bool
    customError*: bool
    patternMismatch*: bool
    rangeOverflow*: bool
    rangeUnderflow*: bool
    stepMismatch*: bool
    tooLong*: bool
    tooShort*: bool
    typeMismatch*: bool
    valid*: bool
    valueMissing*: bool

  Blob* = ref BlobObj ## see `docs<https://developer.mozilla.org/en-US/docs/Web/API/Blob>`_
  BlobObj {.importc.} = object of RootObj
    size*: int
    `type`*: cstring

  File* = ref FileObj ## see `docs<https://developer.mozilla.org/en-US/docs/Web/API/File>`_
  FileObj {.importc.} = object of Blob
    lastModified*: int
    name*: cstring

  TextAreaElement* = ref TextAreaElementObj ## see `docs<https://developer.mozilla.org/en-US/docs/Web/API/HTMLTextAreaElement>`_
  TextAreaElementObj {.importc.} = object of Element
    value*: cstring
    selectionStart*, selectionEnd*: int
    selectionDirection*: cstring
    rows*, cols*: int

  InputElement* = ref InputElementObj ## see `docs<https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement>`_
  InputElementObj {.importc.} = object of Element
    # Properties related to the parent form
    formAction*: cstring
    formEncType*: cstring
    formMethod*: cstring
    formNoValidate*: bool
    formTarget*: cstring

    # Properties that apply to any type of input element that is not hidden
    `type`*: cstring
    autofocus*: bool
    required*: bool
    value*: cstring
    validity*: ValidityState
    validationMessage*: cstring
    willValidate*: bool

    # Properties that apply only to elements of type "checkbox" or "radio"
    indeterminate*: bool

    # Properties that apply only to elements of type "image"
    alt*: cstring
    height*: cstring
    src*: cstring
    width*: cstring

    # Properties that apply only to elements of type "file"
    accept*: cstring
    files*: seq[Blob]

    # Properties that apply only to text/number-containing or elements
    autocomplete*: cstring
    maxLength*: int
    size*: int
    pattern*: cstring
    placeholder*: cstring
    min*: cstring
    max*: cstring
    selectionStart*: int
    selectionEnd*: int
    selectionDirection*: cstring

    # Properties not yet categorized
    dirName*: cstring
    accessKey*: cstring
    list*: Element
    multiple*: bool
    labels*: seq[Element]
    step*: cstring
    valueAsDate*: cstring
    valueAsNumber*: float

  LinkElement* = ref LinkObj
  LinkObj {.importc.} = object of ElementObj
    target*: cstring
    text*: cstring
    x*: int
    y*: int

  EmbedElement* = ref EmbedObj
  EmbedObj {.importc.} = object of ElementObj
    height*: int
    hspace*: int
    src*: cstring
    width*: int
    `type`*: cstring
    vspace*: int

  AnchorElement* = ref AnchorObj
  AnchorObj {.importc.} = object of ElementObj
    text*: cstring
    x*, y*: int

  OptionElement* = ref OptionObj
  OptionObj {.importc.} = object of ElementObj
    defaultSelected*: bool
    selected*: bool
    selectedIndex*: int
    text*: cstring
    value*: cstring

  FormElement* = ref FormObj ## see `docs<https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement>`_
  FormObj {.importc.} = object of ElementObj
    acceptCharset*: cstring
    action*: cstring
    autocomplete*: cstring
    elements*: seq[Element]
    encoding*: cstring
    enctype*: cstring
    length*: int
    `method`*: cstring
    noValidate*: bool
    target*: cstring

  ImageElement* = ref ImageObj
  ImageObj {.importc.} = object of ElementObj
    border*: int
    complete*: bool
    height*: int
    hspace*: int
    lowsrc*: cstring
    src*: cstring
    vspace*: int
    width*: int

  Style* = ref StyleObj
  StyleObj {.importc.} = object of RootObj
    alignContent*: cstring
    alignItems*: cstring
    alignSelf*: cstring
    all*: cstring
    animation*: cstring
    animationDelay*: cstring
    animationDirection*: cstring
    animationDuration*: cstring
    animationFillMode*: cstring
    animationIterationCount*: cstring
    animationName*: cstring
    animationPlayState*: cstring
    animationTimingFunction*: cstring
    backdropFilter*: cstring
    backfaceVisibility*: cstring
    background*: cstring
    backgroundAttachment*: cstring
    backgroundBlendMode*: cstring
    backgroundClip*: cstring
    backgroundColor*: cstring
    backgroundImage*: cstring
    backgroundOrigin*: cstring
    backgroundPosition*: cstring
    backgroundRepeat*: cstring
    backgroundSize*: cstring
    blockSize*: cstring
    border*: cstring
    borderBlock*: cstring
    borderBlockColor*: cstring
    borderBlockEnd*: cstring
    borderBlockEndColor*: cstring
    borderBlockEndStyle*: cstring
    borderBlockEndWidth*: cstring
    borderBlockStart*: cstring
    borderBlockStartColor*: cstring
    borderBlockStartStyle*: cstring
    borderBlockStartWidth*: cstring
    borderBlockStyle*: cstring
    borderBlockWidth*: cstring
    borderBottom*: cstring
    borderBottomColor*: cstring
    borderBottomLeftRadius*: cstring
    borderBottomRightRadius*: cstring
    borderBottomStyle*: cstring
    borderBottomWidth*: cstring
    borderCollapse*: cstring
    borderColor*: cstring
    borderEndEndRadius*: cstring
    borderEndStartRadius*: cstring
    borderImage*: cstring
    borderImageOutset*: cstring
    borderImageRepeat*: cstring
    borderImageSlice*: cstring
    borderImageSource*: cstring
    borderImageWidth*: cstring
    borderInline*: cstring
    borderInlineColor*: cstring
    borderInlineEnd*: cstring
    borderInlineEndColor*: cstring
    borderInlineEndStyle*: cstring
    borderInlineEndWidth*: cstring
    borderInlineStart*: cstring
    borderInlineStartColor*: cstring
    borderInlineStartStyle*: cstring
    borderInlineStartWidth*: cstring
    borderInlineStyle*: cstring
    borderInlineWidth*: cstring
    borderLeft*: cstring
    borderLeftColor*: cstring
    borderLeftStyle*: cstring
    borderLeftWidth*: cstring
    borderRadius*: cstring
    borderRight*: cstring
    borderRightColor*: cstring
    borderRightStyle*: cstring
    borderRightWidth*: cstring
    borderSpacing*: cstring
    borderStartEndRadius*: cstring
    borderStartStartRadius*: cstring
    borderStyle*: cstring
    borderTop*: cstring
    borderTopColor*: cstring
    borderTopLeftRadius*: cstring
    borderTopRightRadius*: cstring
    borderTopStyle*: cstring
    borderTopWidth*: cstring
    borderWidth*: cstring
    bottom*: cstring
    boxDecorationBreak*: cstring
    boxShadow*: cstring
    boxSizing*: cstring
    breakAfter*: cstring
    breakBefore*: cstring
    breakInside*: cstring
    captionSide*: cstring
    caretColor*: cstring
    clear*: cstring
    clip*: cstring
    clipPath*: cstring
    color*: cstring
    colorAdjust*: cstring
    columnCount*: cstring
    columnFill*: cstring
    columnGap*: cstring
    columnRule*: cstring
    columnRuleColor*: cstring
    columnRuleStyle*: cstring
    columnRuleWidth*: cstring
    columnSpan*: cstring
    columnWidth*: cstring
    columns*: cstring
    contain*: cstring
    content*: cstring
    counterIncrement*: cstring
    counterReset*: cstring
    counterSet*: cstring
    cursor*: cstring
    direction*: cstring
    display*: cstring
    emptyCells*: cstring
    filter*: cstring
    flex*: cstring
    flexBasis*: cstring
    flexDirection*: cstring
    flexFlow*: cstring
    flexGrow*: cstring
    flexShrink*: cstring
    flexWrap*: cstring
    cssFloat*: cstring
    font*: cstring
    fontFamily*: cstring
    fontFeatureSettings*: cstring
    fontKerning*: cstring
    fontLanguageOverride*: cstring
    fontOpticalSizing*: cstring
    fontSize*: cstring
    fontSizeAdjust*: cstring
    fontStretch*: cstring
    fontStyle*: cstring
    fontSynthesis*: cstring
    fontVariant*: cstring
    fontVariantAlternates*: cstring
    fontVariantCaps*: cstring
    fontVariantEastAsian*: cstring
    fontVariantLigatures*: cstring
    fontVariantNumeric*: cstring
    fontVariantPosition*: cstring
    fontVariationSettings*: cstring
    fontWeight*: cstring
    gap*: cstring
    grid*: cstring
    gridArea*: cstring
    gridAutoColumns*: cstring
    gridAutoFlow*: cstring
    gridAutoRows*: cstring
    gridColumn*: cstring
    gridColumnEnd*: cstring
    gridColumnStart*: cstring
    gridRow*: cstring
    gridRowEnd*: cstring
    gridRowStart*: cstring
    gridTemplate*: cstring
    gridTemplateAreas*: cstring
    gridTemplateColumns*: cstring
    gridTemplateRows*: cstring
    hangingPunctuation*: cstring
    height*: cstring
    hyphens*: cstring
    imageOrientation*: cstring
    imageRendering*: cstring
    inlineSize*: cstring
    inset*: cstring
    insetBlock*: cstring
    insetBlockEnd*: cstring
    insetBlockStart*: cstring
    insetInline*: cstring
    insetInlineEnd*: cstring
    insetInlineStart*: cstring
    isolation*: cstring
    justifyContent*: cstring
    justifyItems*: cstring
    justifySelf*: cstring
    left*: cstring
    letterSpacing*: cstring
    lineBreak*: cstring
    lineHeight*: cstring
    listStyle*: cstring
    listStyleImage*: cstring
    listStylePosition*: cstring
    listStyleType*: cstring
    margin*: cstring
    marginBlock*: cstring
    marginBlockEnd*: cstring
    marginBlockStart*: cstring
    marginBottom*: cstring
    marginInline*: cstring
    marginInlineEnd*: cstring
    marginInlineStart*: cstring
    marginLeft*: cstring
    marginRight*: cstring
    marginTop*: cstring
    mask*: cstring
    maskBorder*: cstring
    maskBorderMode*: cstring
    maskBorderOutset*: cstring
    maskBorderRepeat*: cstring
    maskBorderSlice*: cstring
    maskBorderSource*: cstring
    maskBorderWidth*: cstring
    maskClip*: cstring
    maskComposite*: cstring
    maskImage*: cstring
    maskMode*: cstring
    maskOrigin*: cstring
    maskPosition*: cstring
    maskRepeat*: cstring
    maskSize*: cstring
    maskType*: cstring
    maxBlockSize*: cstring
    maxHeight*: cstring
    maxInlineSize*: cstring
    maxWidth*: cstring
    minBlockSize*: cstring
    minHeight*: cstring
    minInlineSize*: cstring
    minWidth*: cstring
    mixBlendMode*: cstring
    objectFit*: cstring
    objectPosition*: cstring
    offset*: cstring
    offsetAnchor*: cstring
    offsetDistance*: cstring
    offsetPath*: cstring
    offsetRotate*: cstring
    opacity*: cstring
    order*: cstring
    orphans*: cstring
    outline*: cstring
    outlineColor*: cstring
    outlineOffset*: cstring
    outlineStyle*: cstring
    outlineWidth*: cstring
    overflow*: cstring
    overflowAnchor*: cstring
    overflowBlock*: cstring
    overflowInline*: cstring
    overflowWrap*: cstring
    overflowX*: cstring
    overflowY*: cstring
    overscrollBehavior*: cstring
    overscrollBehaviorBlock*: cstring
    overscrollBehaviorInline*: cstring
    overscrollBehaviorX*: cstring
    overscrollBehaviorY*: cstring
    padding*: cstring
    paddingBlock*: cstring
    paddingBlockEnd*: cstring
    paddingBlockStart*: cstring
    paddingBottom*: cstring
    paddingInline*: cstring
    paddingInlineEnd*: cstring
    paddingInlineStart*: cstring
    paddingLeft*: cstring
    paddingRight*: cstring
    paddingTop*: cstring
    pageBreakAfter*: cstring
    pageBreakBefore*: cstring
    pageBreakInside*: cstring
    paintOrder*: cstring
    perspective*: cstring
    perspectiveOrigin*: cstring
    placeContent*: cstring
    placeItems*: cstring
    placeSelf*: cstring
    pointerEvents*: cstring
    position*: cstring
    quotes*: cstring
    resize*: cstring
    right*: cstring
    rotate*: cstring
    rowGap*: cstring
    scale*: cstring
    scrollBehavior*: cstring
    scrollMargin*: cstring
    scrollMarginBlock*: cstring
    scrollMarginBlockEnd*: cstring
    scrollMarginBlockStart*: cstring
    scrollMarginBottom*: cstring
    scrollMarginInline*: cstring
    scrollMarginInlineEnd*: cstring
    scrollMarginInlineStart*: cstring
    scrollMarginLeft*: cstring
    scrollMarginRight*: cstring
    scrollMarginTop*: cstring
    scrollPadding*: cstring
    scrollPaddingBlock*: cstring
    scrollPaddingBlockEnd*: cstring
    scrollPaddingBlockStart*: cstring
    scrollPaddingBottom*: cstring
    scrollPaddingInline*: cstring
    scrollPaddingInlineEnd*: cstring
    scrollPaddingInlineStart*: cstring
    scrollPaddingLeft*: cstring
    scrollPaddingRight*: cstring
    scrollPaddingTop*: cstring
    scrollSnapAlign*: cstring
    scrollSnapStop*: cstring
    scrollSnapType*: cstring
    scrollbar3dLightColor*: cstring
    scrollbarArrowColor*: cstring
    scrollbarBaseColor*: cstring
    scrollbarColor*: cstring
    scrollbarDarkshadowColor*: cstring
    scrollbarFaceColor*: cstring
    scrollbarHighlightColor*: cstring
    scrollbarShadowColor*: cstring
    scrollbarTrackColor*: cstring
    scrollbarWidth*: cstring
    shapeImageThreshold*: cstring
    shapeMargin*: cstring
    shapeOutside*: cstring
    tabSize*: cstring
    tableLayout*: cstring
    textAlign*: cstring
    textAlignLast*: cstring
    textCombineUpright*: cstring
    textDecoration*: cstring
    textDecorationColor*: cstring
    textDecorationLine*: cstring
    textDecorationSkipInk*: cstring
    textDecorationStyle*: cstring
    textDecorationThickness*: cstring
    textEmphasis*: cstring
    textEmphasisColor*: cstring
    textEmphasisPosition*: cstring
    textEmphasisStyle*: cstring
    textIndent*: cstring
    textJustify*: cstring
    textOrientation*: cstring
    textOverflow*: cstring
    textRendering*: cstring
    textShadow*: cstring
    textTransform*: cstring
    textUnderlineOffset*: cstring
    textUnderlinePosition*: cstring
    top*: cstring
    touchAction*: cstring
    transform*: cstring
    transformBox*: cstring
    transformOrigin*: cstring
    transformStyle*: cstring
    transition*: cstring
    transitionDelay*: cstring
    transitionDuration*: cstring
    transitionProperty*: cstring
    transitionTimingFunction*: cstring
    translate*: cstring
    unicodeBidi*: cstring
    verticalAlign*: cstring
    visibility*: cstring
    whiteSpace*: cstring
    widows*: cstring
    width*: cstring
    willChange*: cstring
    wordBreak*: cstring
    wordSpacing*: cstring
    writingMode*: cstring
    zIndex*: cstring

  EventPhase* = enum
    None = 0,
    CapturingPhase,
    AtTarget,
    BubblingPhase

  Event* = ref EventObj ## see `docs<https://developer.mozilla.org/en-US/docs/Web/API/Event>`_
  EventObj {.importc.} = object of RootObj
    bubbles*: bool
    cancelBubble*: bool
    cancelable*: bool
    composed*: bool
    currentTarget*: Node
    defaultPrevented*: bool
    eventPhase*: int
    target*: Node
    `type`*: cstring
    isTrusted*: bool

  UIEvent* = ref UIEventObj ## see `docs<https://developer.mozilla.org/en-US/docs/Web/API/UIEvent>`_
  UIEventObj {.importc.} = object of Event
    detail*: int64
    view*: Window

  KeyboardEvent* = ref KeyboardEventObj ## see `docs<https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent>`_
  KeyboardEventObj {.importc.} = object of UIEvent
    altKey*, ctrlKey*, metaKey*, shiftKey*: bool
    code*: cstring
    isComposing*: bool
    key*: cstring
    keyCode*: int
    location*: int

  KeyboardEventKey* {.pure.} = enum ## see `docs<https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/key/Key_Values>`_
    # Modifier keys
    Alt,
    AltGraph,
    CapsLock,
    Control,
    Fn,
    FnLock,
    Hyper,
    Meta,
    NumLock,
    ScrollLock,
    Shift,
    Super,
    Symbol,
    SymbolLock,

    # Whitespace keys
    ArrowDown,
    ArrowLeft,
    ArrowRight,
    ArrowUp,
    End,
    Home,
    PageDown,
    PageUp,

    # Editing keys
    Backspace,
    Clear,
    Copy,
    CrSel,
    Cut,
    Delete,
    EraseEof,
    ExSel,
    Insert,
    Paste,
    Redo,
    Undo,

    # UI keys
    Accept,
    Again,
    Attn,
    Cancel,
    ContextMenu,
    Escape,
    Execute,
    Find,
    Finish,
    Help,
    Pause,
    Play,
    Props,
    Select,
    ZoomIn,
    ZoomOut,

    # Device keys
    BrigtnessDown,
    BrigtnessUp,
    Eject,
    LogOff,
    Power,
    PowerOff,
    PrintScreen,
    Hibernate,
    Standby,
    WakeUp,

    # Common IME keys
    AllCandidates,
    Alphanumeric,
    CodeInput,
    Compose,
    Convert,
    Dead,
    FinalMode,
    GroupFirst,
    GroupLast,
    GroupNext,
    GroupPrevious,
    ModeChange,
    NextCandidate,
    NonConvert,
    PreviousCandidate,
    Process,
    SingleCandidate,

    # Korean keyboards only
    HangulMode,
    HanjaMode,
    JunjaMode,

    # Japanese keyboards only
    Eisu,
    Hankaku,
    Hiragana,
    HiraganaKatakana,
    KanaMode,
    KanjiMode,
    Katakana,
    Romaji,
    Zenkaku,
    ZenkakuHanaku,

    # Function keys
    F1,
    F2,
    F3,
    F4,
    F5,
    F6,
    F7,
    F8,
    F9,
    F10,
    F11,
    F12,
    F13,
    F14,
    F15,
    F16,
    F17,
    F18,
    F19,
    F20,
    Soft1,
    Soft2,
    Soft3,
    Soft4,

    # Phone keys
    AppSwitch,
    Call,
    Camera,
    CameraFocus,
    EndCall,
    GoBack,
    GoHome,
    HeadsetHook,
    LastNumberRedial,
    Notification,
    MannerMode,
    VoiceDial,

    # Multimedia keys
    ChannelDown,
    ChannelUp,
    MediaFastForward,
    MediaPause,
    MediaPlay,
    MediaPlayPause,
    MediaRecord,
    MediaRewind,
    MediaStop,
    MediaTrackNext,
    MediaTrackPrevious,

    # Audio control keys
    AudioBalanceLeft,
    AudioBalanceRight,
    AudioBassDown,
    AudioBassBoostDown,
    AudioBassBoostToggle,
    AudioBassBoostUp,
    AudioBassUp,
    AudioFaderFront,
    AudioFaderRear,
    AudioSurroundModeNext,
    AudioTrebleDown,
    AudioTrebleUp,
    AudioVolumeDown,
    AUdioVolumeMute,
    AudioVolumeUp,
    MicrophoneToggle,
    MicrophoneVolumeDown,
    MicrophoneVolumeMute,
    MicrophoneVolumeUp,

    # TV control keys
    TV,
    TV3DMode,
    TVAntennaCable,
    TVAudioDescription,
    TVAudioDescriptionMixDown,
    TVAudioDescriptionMixUp,
    TVContentsMenu,
    TVDataService,
    TVInput,
    TVInputComponent1,
    TVInputComponent2,
    TVInputComposite1,
    TVInputComposite2,
    TVInputHDMI1,
    TVInputHDMI2,
    TVInputHDMI3,
    TVInputHDMI4,
    TVInputVGA1,
    TVMediaContext,
    TVNetwork,
    TVNumberEntry,
    TVPower,
    TVRadioService,
    TVSatellite,
    TVSatelliteBS,
    TVSatelliteCS,
    TVSatelliteToggle,
    TVTerrestrialAnalog,
    TVTerrestrialDigital,
    TVTimer,

    # Media controller keys
    AVRInput,
    AVRPower,
    ColorF0Red,
    ColorF1Green,
    ColorF2Yellow,
    ColorF3Blue,
    ColorF4Grey,
    ColorF5Brown,
    ClosedCaptionToggle,
    Dimmer,
    DisplaySwap,
    DVR,
    Exit,
    FavoriteClear0,
    FavoriteClear1,
    FavoriteClear2,
    FavoriteClear3,
    FavoriteRecall0,
    FavoriteRecall1,
    FavoriteRecall2,
    FavoriteRecall3,
    FavoriteStore0,
    FavoriteStore1,
    FavoriteStore2,
    FavoriteStore3,
    Guide,
    GuideNextDay,
    GuidePreviousDay,
    Info,
    InstantReplay,
    Link,
    ListProgram,
    LiveContent,
    Lock,
    MediaApps,
    MediaAudioTrack,
    MediaLast,
    MediaSkipBackward,
    MediaSkipForward,
    MediaStepBackward,
    MediaStepForward,
    MediaTopMenu,
    NavigateIn,
    NavigateNext,
    NavigateOut,
    NavigatePrevious,
    NextFavoriteChannel,
    NextUserProfile,
    OnDemand,
    Pairing,
    PinPDown,
    PinPMove,
    PinPUp,
    PlaySpeedDown,
    PlaySpeedReset,
    PlaySpeedUp,
    RandomToggle,
    RcLowBattery,
    RecordSpeedNext,
    RfBypass,
    ScanChannelsToggle,
    ScreenModeNext,
    Settings,
    SplitScreenToggle,
    STBInput,
    STBPower,
    Subtitle,
    Teletext,
    VideoModeNext,
    Wink,
    ZoomToggle,

    # Speech recognition keys
    SpeechCorrectionList,
    SpeechInputToggle,

    # Document keys
    Close,
    New,
    Open,
    Print,
    Save,
    SpellCheck,
    MailForward,
    MailReply,
    MailSend,

    # Application selector keys
    LaunchCalculator,
    LaunchCalendar,
    LaunchContacts,
    LaunchMail,
    LaunchMediaPlayer,
    LaunchMusicPlayer,
    LaunchMyComputer,
    LaunchPhone,
    LaunchScreenSaver,
    LaunchSpreadsheet,
    LaunchWebBrowser,
    LaunchWebCam,
    LaunchWordProcessor,
    LaunchApplication1,
    LaunchApplication2,
    LaunchApplication3,
    LaunchApplication4,
    LaunchApplication5,
    LaunchApplication6,
    LaunchApplication7,
    LaunchApplication8,
    LaunchApplication9,
    LaunchApplication10,
    LaunchApplication11,
    LaunchApplication12,
    LaunchApplication13,
    LaunchApplication14,
    LaunchApplication15,
    LaunchApplication16,

    # Browser control keys
    BrowserBack,
    BrowserFavorites,
    BrowserForward,
    BrowserHome,
    BrowserRefresh,
    BrowserSearch,
    BrowserStop,

    # Numeric keypad keys
    Key11,
    Key12,
    Separator

  MouseButtons* = enum
    NoButton = 0,
    PrimaryButton = 1,
    SecondaryButton = 2,
    AuxilaryButton = 4,
    FourthButton = 8,
    FifthButton = 16

  MouseEvent* = ref MouseEventObj ## see `docs<https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent>`_
  MouseEventObj {.importc.} = object of UIEvent
    altKey*, ctrlKey*, metaKey*, shiftKey*: bool
    button*: int
    buttons*: int
    clientX*, clientY*: int
    movementX*, movementY*: int
    offsetX*, offsetY*: int
    pageX*, pageY*: int
    relatedTarget*: EventTarget
    #region*: cstring
    screenX*, screenY*: int
    x*, y*: int

  WheelEvent* = ref WheelEventObj ## see `docs<https://developer.mozilla.org/en-US/docs/Web/API/WheelEvent>`
  WheelEventObj {.importc.} = object of MouseEvent
    deltaX*: float64
    deltaY*: float64
    deltaZ*: float64
    deltaMode*: uint32

  DataTransferItemKind* {.pure.} = enum
    File = "file",
    String = "string"

  DataTransferItem* = ref DataTransferItemObj ## see `docs<https://developer.mozilla.org/en-US/docs/Web/API/DataTransferItem>`_
  DataTransferItemObj {.importc.} = object of RootObj
    kind*: cstring
    `type`*: cstring

  DataTransfer* = ref DataTransferObj ## see `docs<https://developer.mozilla.org/en-US/docs/Web/API/DataTransfer>`_
  DataTransferObj {.importc.} = object of RootObj
    dropEffect*: cstring
    effectAllowed*: cstring
    files*: seq[Element]
    items*: seq[DataTransferItem]
    types*: seq[cstring]

  DataTransferDropEffect* {.pure.} = enum
    None = "none",
    Copy = "copy",
    Link = "link",
    Move = "move"

  DataTransferEffectAllowed* {.pure.} = enum
    None = "none",
    Copy = "copy",
    CopyLink = "copyLink",
    CopyMove = "copyMove",
    Link = "link",
    LinkMove = "linkMove",
    Move = "move",
    All = "all",
    Uninitialized = "uninitialized"

  DragEventTypes* = enum
    Drag = "drag",
    DragEnd = "dragend",
    DragEnter = "dragenter",
    DragExit = "dragexit",
    DragLeave = "dragleave",
    DragOver = "dragover",
    DragStart = "dragstart",
    Drop = "drop"

  DragEvent* {.importc.} = object of MouseEvent
    ## see `docs<https://developer.mozilla.org/en-US/docs/Web/API/DragEvent>`_
    dataTransfer*: DataTransfer

  ClipboardEvent* {.importc.} = object of Event
    ## see `docs<https://developer.mozilla.org/en-US/docs/Web/API/ClipboardEvent>`_
    clipboardData*: DataTransfer

  TouchList* {.importc.} = ref object of RootObj
    length*: int

  Touch* = ref TouchObj
  TouchObj {.importc.} = object of RootObj
    identifier*: int
    screenX*, screenY*, clientX*, clientY*, pageX*, pageY*: int
    target*: Element
    radiusX*, radiusY*: int
    rotationAngle*: int
    force*: float

  TouchEvent* = ref TouchEventObj
  TouchEventObj {.importc.} = object of UIEvent
    changedTouches*, targetTouches*, touches*: seq[Touch]

  Location* = ref LocationObj
  LocationObj {.importc.} = object of RootObj
    hash*: cstring
    host*: cstring
    hostname*: cstring
    href*: cstring
    pathname*: cstring
    port*: cstring
    protocol*: cstring
    search*: cstring
    origin*: cstring

  History* = ref HistoryObj
  HistoryObj {.importc.} = object of RootObj
    length*: int

  Navigator* = ref NavigatorObj
  NavigatorObj {.importc.} = object of RootObj
    appCodeName*: cstring
    appName*: cstring
    appVersion*: cstring
    cookieEnabled*: bool
    language*: cstring
    platform*: cstring
    userAgent*: cstring
    mimeTypes*: seq[ref MimeType]

  Plugin* {.importc.} = object of RootObj
    description*: cstring
    filename*: cstring
    name*: cstring

  MimeType* {.importc.} = object of RootObj
    description*: cstring
    enabledPlugin*: ref Plugin
    suffixes*: seq[cstring]
    `type`*: cstring

  LocationBar* {.importc.} = object of RootObj
    visible*: bool
  MenuBar* = LocationBar
  PersonalBar* = LocationBar
  ScrollBars* = LocationBar
  ToolBar* = LocationBar
  StatusBar* = LocationBar

  Screen = ref ScreenObj
  ScreenObj {.importc.} = object of RootObj
    availHeight*: int
    availWidth*: int
    colorDepth*: int
    height*: int
    pixelDepth*: int
    width*: int

  TimeOut* {.importc.} = ref object of RootObj
  Interval* {.importc.} = object of RootObj

  AddEventListenerOptions* = object
    capture*: bool
    once*: bool
    passive*: bool

  FontFaceSetReady* {.importc.} = ref object
    ## see: `docs<https://developer.mozilla.org/en-US/docs/Web/API/FontFaceSet/ready>`_
    then*: proc(cb: proc())

  FontFaceSet* {.importc.} = ref object
    ## see: `docs<https://developer.mozilla.org/en-US/docs/Web/API/FontFaceSet>`_
    ready*: FontFaceSetReady
    onloadingdone*: proc(event: Event)

since (1, 3):
  type
    DomParser* = ref object
      ## DOM Parser object (defined on browser only, may not be on NodeJS).
      ## * https://developer.mozilla.org/en-US/docs/Web/API/DOMParser
      ##
      ## .. code-block:: nim
      ##   let prsr = newDomParser()
      ##   discard prsr.parseFromString("<html><marquee>Hello World</marquee></html>".cstring, "text/html".cstring)

    DomException* = ref DOMExceptionObj
      ## The DOMException interface represents an abnormal event (called an exception)
      ## which occurs as a result of calling a method or accessing a property of a web API.
      ## Each exception has a name, which is a short "CamelCase" style string identifying
      ## the error or abnormal condition.
      ## https://developer.mozilla.org/en-US/docs/Web/API/DOMException

    DOMExceptionObj {.importc.} = object

    FileReader* = ref FileReaderObj
      ## The FileReader object lets web applications asynchronously read the contents of files
      ## (or raw data buffers) stored on the user's computer, using File or Blob objects to specify
      ## the file or data to read.
      ## https://developer.mozilla.org/en-US/docs/Web/API/FileReader

    FileReaderObj {.importc.} = object of EventTargetObj

    FileReaderState* = distinct range[0'u16..2'u16]

  const
    fileReaderEmpty* = 0.FileReaderState
    fileReaderLoading* = 1.FileReaderState
    fileReaderDone* = 2.FileReaderState

proc id*(n: Node): cstring {.importcpp: "#.id", nodecl.}
proc `id=`*(n: Node; x: cstring) {.importcpp: "#.id = #", nodecl.}
proc class*(n: Node): cstring {.importcpp: "#.className", nodecl.}
proc `class=`*(n: Node; v: cstring) {.importcpp: "#.className = #", nodecl.}

proc value*(n: Node): cstring {.importcpp: "#.value", nodecl.}
proc `value=`*(n: Node; v: cstring) {.importcpp: "#.value = #", nodecl.}

proc `disabled=`*(n: Node; v: bool) {.importcpp: "#.disabled = #", nodecl.}

when defined(nodejs):
  # we provide a dummy DOM for nodejs for testing purposes
  proc len*(x: Node): int = x.childNodes.len
  proc `[]`*(x: Node; idx: int): Element =
    assert idx >= 0 and idx < x.childNodes.len
    result = cast[Element](x.childNodes[idx])

  var document* = Document(nodeType: DocumentNode)
  document.ownerDocument = document

  proc getElem(x: Element; id: cstring): Element =
    if x.id == id: return x
    for i in 0..<x.len:
      result = getElem(x[i], id)
      if result != nil: return result

  proc getElementById*(doc: Document; id: cstring): Element =
    getElem(doc.body, id)
  proc getElementById*(id: cstring): Element = document.getElementById(id)

  proc appendChild*(parent, n: Node) =
    n.parentNode = parent
    n.ownerDocument = parent.ownerDocument
    parent.childNodes.add n

  proc replaceChild*(parent, newNode, oldNode: Node) =
    newNode.parentNode = parent
    oldNode.parentNode = nil
    var i = 0
    while i < parent.len:
      if Node(parent[i]) == oldNode:
        parent.childNodes[i] = newNode
        return
      inc i
    doAssert false, "old node not in node list"

  proc removeChild*(parent, child: Node) =
    child.parentNode = nil
    var i = 0
    while i < parent.len:
      if Node(parent[i]) == child:
        parent.childNodes.delete(i)
        return
      inc i
    doAssert false, "old node not in node list"

  proc insertBefore*(parent, newNode, before: Node) =
    appendChild(parent, newNode)
    var i = 0
    while i < parent.len-1:
      if Node(parent[i]) == before:
        for j in countdown(parent.len-1, i-1):
          parent.childNodes[j] = parent.childNodes[j-1]
        parent.childNodes[i-1] = newNode
        return
      inc i
    #doAssert false, "before not in node list"

  proc createElement*(d: Document, identifier: cstring): Element =
    new(result)
    result.nodeName = identifier
    result.nodeType = NodeType.ElementNode

  proc createTextNode*(d: Document, identifier: cstring): Node =
    new(result)
    result.nodeName = "#text"
    result.nodeValue = identifier
    result.nodeType = NodeType.TextNode

  proc createComment*(d: Document, data: cstring): Node =
    new(result)
    result.nodeName = "#comment"
    result.nodeValue = data
    result.nodeType = NodeType.CommentNode

else:
  proc len*(x: Node): int {.importcpp: "#.childNodes.length".}
  proc `[]`*(x: Node; idx: int): Element {.importcpp: "#.childNodes[#]".}
  proc getElementById*(id: cstring): Element {.importc: "document.getElementById", nodecl.}
  proc appendChild*(n, child: Node) {.importcpp.}
  proc removeChild*(n, child: Node) {.importcpp.}
  proc remove*(child: Node) {.importcpp.}
  proc replaceChild*(n, newNode, oldNode: Node) {.importcpp.}
  proc insertBefore*(n, newNode, before: Node) {.importcpp.}
  proc getElementById*(d: Document, id: cstring): Element {.importcpp.}
  proc createElement*(d: Document, identifier: cstring): Element {.importcpp.}
  proc createTextNode*(d: Document, identifier: cstring): Node {.importcpp.}
  proc createComment*(d: Document, data: cstring): Node {.importcpp.}

proc setTimeout*(action: proc(); ms: int): Timeout {.importc, nodecl.}
proc clearTimeout*(t: Timeout) {.importc, nodecl.}

{.push importcpp.}

# EventTarget "methods"
proc addEventListener*(et: EventTarget, ev: cstring, cb: proc(ev: Event), useCapture: bool = false)
proc addEventListener*(et: EventTarget, ev: cstring, cb: proc(ev: Event), options: AddEventListenerOptions)
proc dispatchEvent*(et: EventTarget, ev: Event)
proc removeEventListener*(et: EventTarget; ev: cstring; cb: proc(ev: Event))
# Window "methods"
proc alert*(w: Window, msg: cstring)
proc back*(w: Window)
proc blur*(w: Window)
proc clearInterval*(w: Window, interval: ref Interval)
proc clearTimeout*(w: Window, timeout: ref TimeOut)
proc close*(w: Window)
proc confirm*(w: Window, msg: cstring): bool
proc disableExternalCapture*(w: Window)
proc enableExternalCapture*(w: Window)
proc find*(w: Window, text: cstring, caseSensitive = false,
           backwards = false)
proc focus*(w: Window)
proc forward*(w: Window)
proc getComputedStyle*(w: Window, e: Node, pe:Node = nil): Style
proc handleEvent*(w: Window, e: Event)
proc home*(w: Window)
proc moveBy*(w: Window, x, y: int)
proc moveTo*(w: Window, x, y: int)
proc open*(w: Window, uri, windowname: cstring,
           properties: cstring = nil): Window
proc print*(w: Window)
proc prompt*(w: Window, text, default: cstring): cstring
proc resizeBy*(w: Window, x, y: int)
proc resizeTo*(w: Window, x, y: int)
proc routeEvent*(w: Window, event: Event)
proc scrollBy*(w: Window, x, y: int)
proc scrollTo*(w: Window, x, y: int)
proc setInterval*(w: Window, code: cstring, pause: int): ref Interval
proc setInterval*(w: Window, function: proc (), pause: int): ref Interval
proc setTimeout*(w: Window, code: cstring, pause: int): ref TimeOut
proc setTimeout*(w: Window, function: proc (), pause: int): ref Interval
proc stop*(w: Window)
proc requestAnimationFrame*(w: Window, function: proc (time: float)): int
proc cancelAnimationFrame*(w: Window, id: int)

# Node "methods"
proc appendData*(n: Node, data: cstring)
proc cloneNode*(n: Node, copyContent: bool): Node
proc deleteData*(n: Node, start, len: int)
proc focus*(e: Node)
proc getAttribute*(n: Node, attr: cstring): cstring
proc getAttributeNode*(n: Node, attr: cstring): Node
proc hasAttribute*(n: Node, attr: cstring): bool
proc hasChildNodes*(n: Node): bool
proc insertData*(n: Node, position: int, data: cstring)
proc removeAttribute*(n: Node, attr: cstring)
proc removeAttributeNode*(n, attr: Node)
proc replaceData*(n: Node, start, len: int, text: cstring)
proc scrollIntoView*(n: Node)
proc setAttribute*(n: Node, name, value: cstring)
proc setAttributeNode*(n: Node, attr: Node)
proc querySelector*(n: Node, selectors: cstring): Element
proc querySelectorAll*(n: Node, selectors: cstring): seq[Element]

# Document "methods"
proc createAttribute*(d: Document, identifier: cstring): Node
proc getElementsByName*(d: Document, name: cstring): seq[Element]
proc getElementsByTagName*(d: Document, name: cstring): seq[Element]
proc getElementsByClassName*(d: Document, name: cstring): seq[Element]
proc insertNode*(range: Range, node: Node)
proc getSelection*(d: Document): Selection
proc handleEvent*(d: Document, event: Event)
proc open*(d: Document)
proc routeEvent*(d: Document, event: Event)
proc write*(d: Document, text: cstring)
proc writeln*(d: Document, text: cstring)
proc querySelector*(d: Document, selectors: cstring): Element
proc querySelectorAll*(d: Document, selectors: cstring): seq[Element]

# Element "methods"
proc blur*(e: Element)
proc click*(e: Element)
proc focus*(e: Element)
proc handleEvent*(e: Element, event: Event)
proc select*(e: Element)
proc getElementsByTagName*(e: Element, name: cstring): seq[Element]
proc getElementsByClassName*(e: Element, name: cstring): seq[Element]

# FormElement "methods"
proc reset*(f: FormElement)
proc submit*(f: FormElement)
proc checkValidity*(e: FormElement): bool
proc reportValidity*(e: FormElement): bool

# EmbedElement "methods"
proc play*(e: EmbedElement)
proc stop*(e: EmbedElement)

# Location "methods"
proc reload*(loc: Location)
proc replace*(loc: Location, s: cstring)

# History "methods"
proc back*(h: History)
proc forward*(h: History)
proc go*(h: History, pagesToJump: int)
proc pushState*[T](h: History, stateObject: T, title, url: cstring)

# Navigator "methods"
proc javaEnabled*(h: Navigator): bool

# ClassList "methods"
proc add*(c: ClassList, class: cstring)
proc remove*(c: ClassList, class: cstring)
proc contains*(c: ClassList, class: cstring): bool
proc toggle*(c: ClassList, class: cstring)

# Style "methods"
proc getPropertyValue*(s: Style, property: cstring): cstring
proc removeProperty*(s: Style, property: cstring)
proc setProperty*(s: Style, property, value: cstring, priority = "")
proc getPropertyPriority*(s: Style, property: cstring): cstring

# Event "methods"
proc preventDefault*(ev: Event)
proc stopImmediatePropagation*(ev: Event)
proc stopPropagation*(ev: Event)

# KeyboardEvent "methods"
proc getModifierState*(ev: KeyboardEvent, keyArg: cstring): bool

# MouseEvent "methods"
proc getModifierState*(ev: MouseEvent, keyArg: cstring): bool

# TouchEvent "methods"
proc identifiedTouch*(list: TouchList): Touch
proc item*(list: TouchList, i: int): Touch

# DataTransfer "methods"
proc clearData*(dt: DataTransfer, format: cstring)
proc getData*(dt: DataTransfer, format: cstring): cstring
proc setData*(dt: DataTransfer, format: cstring, data: cstring)
proc setDragImage*(dt: DataTransfer, img: Element, xOffset: int64, yOffset: int64)

# DataTransferItem "methods"
proc getAsFile*(dti: DataTransferItem): File

# InputElement "methods"
proc setSelectionRange*(e: InputElement, selectionStart: int, selectionEnd: int, selectionDirection: cstring = "none")
proc setRangeText*(e: InputElement, replacement: cstring, startindex: int = 0, endindex: int = 0, selectionMode: cstring = "preserve")
proc setCustomValidity*(e: InputElement, error: cstring)
proc checkValidity*(e: InputElement): bool

# Blob "methods"
proc slice*(e: Blob, startindex: int = 0, endindex: int = e.size, contentType: cstring = "")

# Performance "methods"
proc now*(p: Performance): float

# Selection "methods"
proc removeAllRanges*(s: Selection)
proc deleteFromDocument*(s: Selection)
proc getRangeAt*(s: Selection, index: int): Range
proc collapse*(s: Selection)
converter toString*(s: Selection): cstring
proc `$`*(s: Selection): string = $(s.toString())

# LocalStorage "methods"
proc getItem*(ls: LocalStorage, key: cstring): cstring
proc setItem*(ls: LocalStorage, key, value: cstring)
proc hasItem*(ls: LocalStorage, key: cstring): bool
proc clear*(ls: LocalStorage)
proc removeItem*(ls: LocalStorage, key: cstring)

{.pop.}

proc setAttr*(n: Node; key, val: cstring) {.importcpp: "#.setAttribute(@)".}

var
  window* {.importc, nodecl.}: Window
  navigator* {.importc, nodecl.}: Navigator
  screen* {.importc, nodecl.}: Screen

when not defined(nodejs):
  var document* {.importc, nodecl.}: Document

proc decodeURI*(uri: cstring): cstring {.importc, nodecl.}
proc encodeURI*(uri: cstring): cstring {.importc, nodecl.}

proc escape*(uri: cstring): cstring {.importc, nodecl.}
proc unescape*(uri: cstring): cstring {.importc, nodecl.}

proc decodeURIComponent*(uri: cstring): cstring {.importc, nodecl.}
proc encodeURIComponent*(uri: cstring): cstring {.importc, nodecl.}
proc isFinite*(x: BiggestFloat): bool {.importc, nodecl.}
proc isNaN*(x: BiggestFloat): bool {.importc, nodecl.}

proc newEvent*(name: cstring): Event {.importcpp: "new Event(@)", constructor.}

proc getElementsByClass*(n: Node; name: cstring): seq[Node] {.
  importcpp: "#.getElementsByClassName(#)", nodecl.}


type
  BoundingRect* {.importc.} = object
    top*, bottom*, left*, right*, x*, y*, width*, height*: float

proc getBoundingClientRect*(e: Node): BoundingRect {.
  importcpp: "getBoundingClientRect", nodecl.}
proc clientHeight*(): int {.
  importcpp: "(window.innerHeight || document.documentElement.clientHeight)@", nodecl.}
proc clientWidth*(): int {.
  importcpp: "(window.innerWidth || document.documentElement.clientWidth)@", nodecl.}

proc inViewport*(el: Node): bool =
  let rect = el.getBoundingClientRect()
  result = rect.top >= 0 and rect.left >= 0 and
           rect.bottom <= clientHeight().float and
           rect.right <= clientWidth().float

proc scrollTop*(e: Node): int {.importcpp: "#.scrollTop", nodecl.}
proc `scrollTop=`*(e: Node, value: int) {.importcpp: "#.scrollTop = #", nodecl.}
proc scrollLeft*(e: Node): int {.importcpp: "#.scrollLeft", nodecl.}
proc scrollHeight*(e: Node): int {.importcpp: "#.scrollHeight", nodecl.}
proc scrollWidth*(e: Node): int {.importcpp: "#.scrollWidth", nodecl.}
proc offsetHeight*(e: Node): int {.importcpp: "#.offsetHeight", nodecl.}
proc offsetWidth*(e: Node): int {.importcpp: "#.offsetWidth", nodecl.}
proc offsetTop*(e: Node): int {.importcpp: "#.offsetTop", nodecl.}
proc offsetLeft*(e: Node): int {.importcpp: "#.offsetLeft", nodecl.}

since (1, 3):
  func newDomParser*(): DOMParser {.importcpp: "new DOMParser()".}
    ## DOM Parser constructor.
  func parseFromString*(this: DOMParser; str: cstring; mimeType: cstring): Document {.importcpp.}
    ## Parse from string to `Document`.

  proc newDomException*(): DomException {.importcpp: "new DomException()", constructor.}
    ## DOM Exception constructor
  proc message*(ex: DomException): cstring {.importcpp: "#.message", nodecl.}
    ## https://developer.mozilla.org/en-US/docs/Web/API/DOMException/message
  proc name*(ex: DomException): cstring  {.importcpp: "#.name", nodecl.}
    ## https://developer.mozilla.org/en-US/docs/Web/API/DOMException/name

  proc newFileReader*(): FileReader {.importcpp: "new FileReader()", constructor.}
    ## File Reader constructor
  proc error*(f: FileReader): DOMException {.importcpp: "#.error", nodecl.}
    ## https://developer.mozilla.org/en-US/docs/Web/API/FileReader/error
  proc readyState*(f: FileReader): FileReaderState {.importcpp: "#.readyState", nodecl.}
    ## https://developer.mozilla.org/en-US/docs/Web/API/FileReader/readyState
  proc resultAsString*(f: FileReader): cstring {.importcpp: "#.result", nodecl.}
    ## https://developer.mozilla.org/en-US/docs/Web/API/FileReader/result
  proc abort*(f: FileReader) {.importcpp: "#.abort()".}
    ## https://developer.mozilla.org/en-US/docs/Web/API/FileReader/abort
  proc readAsBinaryString*(f: FileReader, b: Blob) {.importcpp: "#.readAsBinaryString(#)".}
    ## https://developer.mozilla.org/en-US/docs/Web/API/FileReader/readAsBinaryString
  proc readAsDataURL*(f: FileReader, b: Blob) {.importcpp: "#.readAsDataURL(#)".}
    ## https://developer.mozilla.org/en-US/docs/Web/API/FileReader/readAsDataURL
  proc readAsText*(f: FileReader, b: Blob, encoding = cstring"UTF-8") {.importcpp: "#.readAsText(#, #)".}
    ## https://developer.mozilla.org/en-US/docs/Web/API/FileReader/readAsText
