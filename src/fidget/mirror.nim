

var
  mainFrame*: string
  windowSizeFixed*: bool

proc use*(url: string) =
  discard

template onClick*(id: string, body: untyped) =
  discard

template onChange*(id: string, body: untyped) =
  discard

proc bindOneWay*(id: string, value: var string) =
  discard

proc bindOneWay*(id: string, value: var int) =
  discard

template bindOneWay*(id: string, body: untyped) =
  discard

template bindTwoWay*(id: string, body: untyped) =
  discard

proc startFidget*() =
  discard
