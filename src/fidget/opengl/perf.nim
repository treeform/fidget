import math, std/monotimes, strformat, strutils, times

when defined(nimTypeNames):
  import tables

type
  EntryKind = enum
    Begin, End, Mark

  PerfEntry* = object
    tag: string
    ticks: int64
    kind: EntryKind

  TimeSeries* = ref object
    ## Helps you time stuff over multiple frames.
    at: Natural
    data: seq[float64]

var
  perfEnabled* = true
  defaultBuffer: seq[PerfEntry]

proc getTicks*(): int64 =
  getMonoTime().ticks

proc addEntry(tag: string, kind: EntryKind, buffer: var seq[PerfEntry]) =
  var entry = PerfEntry()
  entry.tag = tag
  entry.ticks = getTicks()
  entry.kind = kind

  buffer.add(entry)

template perfMark*(tag: string, buffer: var seq[PerfEntry] = defaultBuffer) =
  if perfEnabled:
    addEntry(tag, Mark, buffer)

template perf*(tag: string, buffer: var seq[PerfEntry], body: untyped) =
  ## Logs the performance of the body block.
  if perfEnabled:
    addEntry(tag, Begin, buffer)
    body
    addEntry(tag, End, buffer)
  else:
    body

template perf*(tag: string, body: untyped) =
  ## Logs the performance of the body block.
  if perfEnabled:
    perf(tag, defaultBuffer, body)
  else:
    body

template timeIt*(tag: string, body: untyped) =
  ## Quick template to time an operation.
  var buffer: seq[PerfEntry]
  perf tag, buffer, body

  if len(buffer) > 0:
    let
      start = buffer[0].ticks
      finish = buffer[^1].ticks
      # Convert from nanoseconds to floating point seconds
      delta = float64(finish - start) / 1000000000.0
    echo tag, ": ", delta, "s"
  else:
    echo tag, " not timed, perf disabled"

func `$`*(buffer: seq[PerfEntry]): string =
  if len(buffer) == 0:
    return

  var
    lines: seq[string]
    indent = ""
    prevTicks = buffer[0].ticks

  for i, entry in buffer:
    # Convert from nanoseconds to floating point seconds
    let delta = float64(entry.ticks - prevTicks) / 1000000000.0
    prevTicks = entry.ticks

    case entry.kind:
      of Begin:
        lines.add(&"{delta:>8.6f} {indent}{entry.tag} [")
        indent.add("  ")
      of End:
        indent = indent[0 .. ^3]
        lines.add(&"{delta:>8.6f} {indent}]")
      of Mark:
        lines.add(&"{delta:>8.6f}{indent} {entry.tag}")

  result = lines.join("\n")

proc perfDump*(buffer: seq[PerfEntry] = defaultBuffer) =
  if perfEnabled:
    echo $defaultBuffer
    defaultBuffer.setLen(0)

func newTimeSeries*(max: Natural = 1000): TimeSeries =
  result = TimeSeries()
  result.data = newSeq[float64](max)

proc addTime*(timeSeries: var TimeSeries) =
  ## Add current time to time series.
  if timeSeries.at >= len(timeSeries.data):
    timeSeries.at = 0
  timeSeries.data[timeSeries.at] = epochTime()
  inc timeSeries.at

proc num*(timeSeries: TimeSeries, inLastSeconds: float32 = 1.0): int =
  ## Get number of things in last N seconds.
  ## Example: get number of frames in the last second - fps.
  var startTime = epochTime()
  for f in timeSeries.data:
    if startTime - inLastSeconds < f:
      inc result

proc avg*(timeSeries: TimeSeries, inLastSeconds: float32 = 1.0): float32 =
  ## Average over last N seconds.
  ## Example: 1/fps or average frame time.
  return inLastSeconds / float32(timeSeries.num(inLastSeconds))

func byteFmt*(bytes: int): string =
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

when defined(nimTypeNames):
  import sequtils, algorithm
  type CountSize = object
    name: string
    count: int
    sizes: int
    diffCount: int
    diffSizes: int
    dead: bool
  var prevDump = newTable[string, CountSize]()
  func dumpHeapDiff*(top = 10): string =
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
    arr.sort func(a, b: CountSize): int =
      abs(b.sizes) + abs(b.diffSizes) - abs(a.sizes) - abs(a.diffSizes)
    for it in arr[0 .. min(len(arr)-1, top)]:
      result.add &"[Heap] #{it.count:>10}({it.diffCount:>10})"
      result.add &" {byteFmt(it.sizes):>10}({byteFmt(it.diffSizes):>10})"
      result.add &" {it.name}\n"
else:
  func dumpHeapDiff*(top = 10): string =
    return "dumpHeapDiff disabled"
