import strformat, strutils, times

var prevTime: float64
var prefDump*: bool = true
var indent = ""
var timeStack = newSeq[float64]()

var perfBuffer = newSeq[string]()

proc perfMark*(what: string) =
  ## Prints out [time-since-last-aciton] what
  if prefDump:
    let time = epochTime()
    let delta = time - prevTime
    perfBuffer.add fmt"[{delta:>8.6f}] {indent}{what}"
    prevTime = epochTime()

proc perfBegin*(what: string) =
  ## Prints out [time-since-last-aciton] what
  if prefDump:
    let time = epochTime()
    let delta = time - prevTime
    perfBuffer.add fmt"[{delta:>8.6f}] {indent}{what} ["
    indent.add(" ")
    prevTime = epochTime()
    timeStack.add(prevTime)

proc perfEnd*(what: string = "") =
  ## Prints out [time-since-last-aciton] what
  if prefDump:
    let time = epochTime()
    let delta = time - timeStack.pop()
    indent = indent[0..^2]
    perfBuffer.add fmt"({delta:>8.6f}) {indent}] {what}"
    prevTime = epochTime()

proc perfDump*() =
  for line in perfBuffer:
    echo line
  perfBuffer.setLen(0)
  indent.setLen(0)

type TimeSeries* = ref object
  ## Time series help you time stuff over multiple frames
  max: int
  at: int
  data: seq[float]


proc newTimeSeries*(max=1000): TimeSeries =
  ## Time series help you time stuff over multiple frames
  new(result)
  result.max = max
  result.at = 0
  result.data = newSeq[float](result.max)


proc addTime*(timeSeries: var TimeSeries) =
  ## add current time to time series
  if timeSeries.at >= timeSeries.max:
    timeSeries.at = 0
  timeSeries.data[timeSeries.at] = epochTime()
  inc timeSeries.at


proc num*(timeSeries: TimeSeries, inLastSeconds: float64 = 1.0): int =
  ## Get number of things in last N seconds
  ## Example: get number of frames in the last second - fps
  var startTime = epochTime()
  for f in timeSeries.data:
    if startTime - inLastSeconds < f:
      inc result


proc avg*(timeSeries: TimeSeries, inLastSeconds: float64 = 1.0): float64 =
  ## Avarage out last N seconds
  ## Example: 1/fps or avarage frame time
  return inLastSeconds / float64(timeSeries.num(inLastSeconds))


template timeIt*(name: string, inner: untyped) =
  ## quick template to time an operation
  let start = epochTime()
  inner
  echo name, ": ", epochTime() - start, "s"