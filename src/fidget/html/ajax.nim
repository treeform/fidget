import ../dom2

type ProgressEvent* = object of Event
  size*: int
  loaded*: int

type XmlHttpRequestUpload* = object of EventTarget

type ReadyState* = enum
  rsUNSENT = 0
  rsOPENED = 1
  rsHEADERS_RECEIVED = 2
  rsLOADING = 3
  rsDONE = 4

type XMLHttpRequest* {.importc.} = ref object
  onreadystatechange*: proc(e: Event)
  readyState*: ReadyState
  response*: cstring
  responseText*: cstring
  responseType*: cstring
  responseURL*: cstring
  responseXML*: Document
  status*: int
  statusText*: cstring
  timeout*: int
  ontimeout*: proc(e: Event)
  withCredentials*: bool
  upload*: XmlHttpRequestUpload

proc newXMLHttpRequest*(): XMLHttpRequest {.importcpp: "new XMLHttpRequest()".}
proc abort*(r: XMLHttpRequest){.importcpp.}
proc getAllResponseHeaders*(r: XMLHttpRequest): cstring {.importcpp.}
proc getResponseHeader*(r: XMLHttpRequest, name: cstring): cstring{.importcpp.}
proc open*(r: XMLHttpRequest, `method`: cstring, url: cstring, async: bool = true,
    user: cstring = nil, password: cstring = nil){.importcpp.}
proc overrideMimeType*(r: XMLHttpRequest, mime: cstring){.importcpp.}
proc send*(r: XMLHttpRequest){.importcpp.}
proc send*(r: XMLHttpRequest, data: cstring|Document){.importcpp.}
proc setRequestHeader*(r: XMLHttpRequest, header, value: cstring){.importcpp.}
