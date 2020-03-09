import algorithm, math, sequtils, strformat, strutils, tables, times

var prevTime: float64 = epochTime()
var prefDump*: bool = true
var indent = ""
var timeStack = newSeq[float64]()
var perfBuffer = newSeq[string]()

proc perfMark*(what: string) =
  ## Prints out [time-since-last-action] what.
  if prefDump:
    let time = epochTime()
    let delta = time - prevTime
    perfBuffer.add fmt"[{delta:>8.6f}] {indent}{what}"

proc perfBegin*(what: string) =
  ## Prints out [time-since-last-action] what.
  if prefDump:
    let time = epochTime()
    let delta = time - prevTime
    perfBuffer.add fmt"[{delta:>8.6f}] {indent}{what} ["
    indent.add(" ")
    prevTime = epochTime()
    timeStack.add(prevTime)

proc perfEnd*(what: string = "") =
  ## Prints out [time-since-last-action] what.
  if prefDump:
    let time = epochTime()
    let delta = time - timeStack.pop()
    indent = indent[0 .. ^2]
    perfBuffer.add fmt"({delta:>8.6f}) {indent}] {what}"
    prevTime = epochTime()

template perf*(what: string, body: untyped) =
  ## Measures perf with a body block.
  perfBegin what
  body
  perfEnd what

proc perfDump*() =
  for line in perfBuffer:
    echo line
  perfBuffer.setLen(0)
  indent.setLen(0)

type TimeSeries* = ref object
  ## Time series help you time stuff over multiple frames.
  max: int
  at: int
  data: seq[float]

proc newTimeSeries*(max = 1000): TimeSeries =
  ## Time series help you time stuff over multiple frames.
  new(result)
  result.max = max
  result.at = 0
  result.data = newSeq[float](result.max)

proc addTime*(timeSeries: var TimeSeries) =
  ## Add current time to time series.
  if timeSeries.at >= timeSeries.max:
    timeSeries.at = 0
  timeSeries.data[timeSeries.at] = epochTime()
  inc timeSeries.at

proc num*(timeSeries: TimeSeries, inLastSeconds: float64 = 1.0): int =
  ## Get number of things in last N seconds.
  ## Example: get number of frames in the last second - fps.
  var startTime = epochTime()
  for f in timeSeries.data:
    if startTime - inLastSeconds < f:
      inc result

proc avg*(timeSeries: TimeSeries, inLastSeconds: float64 = 1.0): float64 =
  ## Average out last N seconds.
  ## Example: 1/fps or avarage frame time.
  return inLastSeconds / float64(timeSeries.num(inLastSeconds))

template timeIt*(name: string, inner: untyped) =
  ## Quick template to time an operation.
  let start = epochTime()
  inner
  echo name, ": ", epochTime() - start, "s"

proc byteFmt*(bytes: int): string =
  ## Formats computer sizes in B, KB, MB, GB etc...
  if bytes < 0:
    result.add "-"
  let
    sizes = @["B", "KB", "MB", "GB", "TB"]
    bytes = abs(bytes)
  if bytes < 1024:
    result.add $bytes & "B"
  else:
    var i = floor(log(float bytes, 10) / log(float 1024, 10))
    var scaled = float(bytes) / pow(float 1024, i)
    result.add &"{scaled:0.2f}{sizes[int i]}"

assert byteFmt(12) == "12B"
assert byteFmt(1000) == "1000B"
assert byteFmt(1024) == "1.00KB"
assert byteFmt(1200) == "1.17KB"
assert byteFmt(1200_000) == "1.14MB"
assert byteFmt(1200_000_000) == "1.12GB"
assert byteFmt(-12) == "-12B"
assert byteFmt(-1000) == "-1000B"

type CountSize = object
  name: string
  count: int
  sizes: int
  diffCount: int
  diffSizes: int
  dead: bool
var prevDump = newTable[string, CountSize]()
proc dumpHeapDiff*(top = 10): string =
  ## Takes a diff of the heap and prints out top 10 memory growers.
  # Example output:
  # HEAP total:276.95MB occupied:115.34MB free:148.76MB
  # [Heap] #    171765(      -964)    68.97MB( -137.28KB) string
  # [Heap] #         1(         0)    40.00MB(        0B) seq[SelectorKey[asyncdispatch.AsyncData]]
  # [Heap] #      2889(      -107)     1.58MB(   -5.90KB) seq[string]
  # [Heap] #      2872(         0)   493.62KB(        0B) LyticTable
  # [Heap] #      2616(         0)   306.56KB(        0B) Field
  # [Heap] #         1(         0)   285.25KB(        0B) seq[DstChange]
  # [Heap] #         1(         0)   256.03KB(        0B) OrderedKeyValuePairSeq[system.string, lytic.LyticTable]
  # [Heap] #         1(         0)   128.03KB(        0B) OrderedKeyValuePairSeq[system.string, lytic.Field]
  # [Heap] #         2(       -12)     8.00KB(  -48.00KB) AsyncSocket
  # [Heap] #        33(      -270)     2.32KB(  -18.98KB) Future[system.void]
  # [Heap] #         6(       -22)     5.25KB(  -14.00KB) KeyValuePairSeq[system.string, seq[string]]

  when defined(nimTypeNames):
    result.add &"HEAP total:{byteFmt(getTotalMem())}"
    result.add &" occupied:{byteFmt(getOccupiedMem())}"
    result.add &" free:{byteFmt(getFreeMem())}\n"
    for v in prevDump.mvalues:
      v.dead = true
    for it in dumpHeapInstances():
      let name = $it.name
      if name notin prevDump:
        prevDump[name] = CountSize(
          name: name,
          count: it.count,
          sizes: it.sizes,
          diffCount: it.count,
          diffSizes: it.sizes
        )
      else:
        var prev = prevDump[name]
        prev.diffCount = it.count - prev.count
        prev.diffSizes = it.sizes - prev.sizes
        prev.count = it.count
        prev.sizes = it.sizes
        prev.dead = false
        prevDump[name] = prev
    for it in prevDump.mvalues:
      if it.dead:
        it.diffCount = -it.count
        it.diffSizes = -it.sizes
        it.count = 0
        it.sizes = 0
    # sort
    var arr = toSeq(prevDump.values())
    arr.sort proc(a, b: CountSize): int =
      abs(b.sizes) + abs(b.diffSizes) - abs(a.sizes) - abs(a.diffSizes)
    for it in arr[0 .. min(len(arr)-1, top)]:
      result.add &"[Heap] #{it.count:>10}({it.diffCount:>10})"
      result.add &" {byteFmt(it.sizes):>10}({byteFmt(it.diffSizes):>10})"
      result.add &" {it.name}\n"
  else:
    return "dumpHeapDiff disabled"
