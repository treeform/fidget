## Convert to and from json with nulls and missing fields

import json, strutils, tables

proc notNil(x: SomeInteger|SomeFloat|string|bool|object|seq|enum): bool =
  true

proc notNil(x: ref object|cstring): bool =
  x != nil

proc toJson*(x: SomeInteger|SomeFloat|string|bool): JsonNode =
  %x

proc toJson*(x: cstring): JsonNode =
  %($x)

proc toJson*[T](x: openArray[T]): JsonNode =
  result = newJArray()
  for value in x:
    result.add(value.toJson())

proc toJson*(x: enum): JsonNode =
  %($x)

proc toJson*(x: object): JsonNode =
  result = newJObject()
  for name, value in x.fieldPairs:
    if notNil(value):
      result[name] = value.toJson()

proc toJson*(x: ref object): JsonNode =
  result = newJObject()
  if not x.isNil:
    for name, value in x[].fieldPairs:
      if notNil(value):
        result[name] = value.toJson()

proc toJson*(x: JsonNode): JsonNode =
  x

proc notNilAndValid(root: JsonNode, kind: JsonNodeKind): bool =
  (not root.isNil) and (root.kind == kind)

proc fromJson*(root: JsonNode, x: var SomeInteger) =
  if root.notNilAndValid(JInt):
    x = type(x)(root.getInt())
  if root.notNilAndValid(JFloat):
    x = type(x)(root.getFloat())

proc fromJson*(root: JsonNode, x: var SomeFloat) =
  if root.notNilAndValid(JFloat):
    x = type(x)(root.getFloat())
  if root.notNilAndValid(JInt):
    # In JS you can get integers that are way too big!
    # Prase it as a float string, as we need a float anyways.
    x = type(x)(parseFloat($root))

proc fromJson*(root: JsonNode, x: var string) =
  if root.notNilAndValid(JString):
    x = root.getStr()

proc fromJson*(root: JsonNode, x: var bool) =
  if root.notNilAndValid(JBool):
    x = root.getBool()

proc fromJson*[T: enum](root: JsonNode, x: var T) =
  if root.notNilAndValid(JString):
    x = parseEnum[T](root.str)

proc fromJson*[T](root: JsonNode, x: var seq[T]) =
  if root.notNilAndValid(JArray):
    x.newSeq(root.len)
    for i, value in x.mpairs:
      root[i].fromJson(value)

proc fromJson*[T](root: JsonNode, x: var Table[string, T]) =
  if root.notNilAndValid(JObject):
    x = initTable[string, T]()
    for key, value in root:
      var typedValue = new(T)
      value.fromJson(typedValue)
      x[key] = typedValue

proc fromJson*(root: JsonNode, x: var object) =
  if root.notNilAndValid(JObject):
    for name, value in x.fieldPairs:
      root.getOrDefault(name).fromJson(value)

proc fromJson*(root: JsonNode, x: var ref object) =
  if root.notNilAndValid(JObject):
    x = type(x)()
    for name, value in x[].fieldPairs:
      root.getOrDefault(name).fromJson(value)

proc fromJson*(root: JsonNode, x: var JsonNode) =
  x = root

template fromJson*[T](json: JsonNode, _: typedesc[T]): T =
  var result: T
  json.fromJson(result)
  result

when isMainModule:
  # test basics
  echo "hello world".toJson.fromJson(string)
  echo 1234.toJson.fromJson(int)
  echo 123.456.toJson.fromJson(float)
  echo true.toJson.fromJson(bool)
  echo @[1,2,3].toJson.fromJson(seq[int])

  when not defined(js):
    # test supported integer sizes
    echo (123.uint8).toJson.fromJson(uint8)
    echo (-123.int8).toJson.fromJson(int8)
    echo (1234.uint16).toJson.fromJson(uint16)
    echo (-1234.int16).toJson.fromJson(int16)
    echo (12356.uint32).toJson.fromJson(uint32)
    echo (-12356.int32).toJson.fromJson(int32)

  # test float sizes
  echo (float32 123.678).toJson.fromJson(float32)
  echo (float64 123.678).toJson.fromJson(float64)
  echo parseJson("1").fromJson(float32)
  echo parseJson("123").fromJson(float32)
  echo parseJson("123.678901234567890").fromJson(float32)
  echo parseJson("1").fromJson(float64)
  echo parseJson("123").fromJson(float64)
  echo parseJson("123.678901234567890").fromJson(float64)

  # test enums
  type Enumer = enum
    Left
    Right
    Top
    Bottom

  let e = Top
  echo e.toJson()
  echo e.toJson().fromJson(Enumer)
  echo parseJson(""" "Top" """).fromJson(Enumer)
  echo parseJson(""" "top" """).fromJson(Enumer)
  echo parseJson(""" "TOP" """).fromJson(Enumer)

  # test regular objects
  type Foo = object
    id: int
    name: string
    time: float
    active: bool

  let foo = Foo(id: 32, name: "yes", time: 16.77, active: true)
  echo foo.toJson()
  echo parseJson("""
    {"id":32,"name":"yes","time":16.77,"active":true}
  """).fromJson(Foo)

  echo parseJson("""{"id":32,"name":"yes","active":true}""").fromJson(Foo)
  echo parseJson("""{}""").fromJson(Foo)

  # int works in case of float, and float in case of int
  echo parseJson("""{"id":32.0,"time":1677}""").fromJson(Foo)

  echo @[1,2,3].toJson()
  echo parseJson("""[1,2,3]""").fromJson(seq[int])

  type Bar = object
    id: int
    arr: seq[int]
    foo: Foo

  var bar = Bar()
  echo bar.toJson()
  echo parseJson("""
    {
      "id": 123,
      "arr": [
        1,
        2,
        3
      ],
      "foo": {
        "id": 1,
        "name": "hi",
        "time": 12,
        "active": true
      }
    }
  """).fromJson(Bar)

  echo parseJson("""
    {
    }
  """).fromJson(Bar)

  echo parseJson("""
    {
      "extra": 123
    }
  """).fromJson(Bar)


  type
    Foo2 = ref object
      id: int
    Bar2 = object
      id: int
      foo: Foo2

  var foo2: Foo2
  echo foo2.toJson()

  var bar2 = Bar2()
  echo bar2.toJson()

  bar2.id = 2
  bar2.foo = Foo2(id:4)
  echo bar2.toJson()

  echo parseJson("""
    {
    }
  """).fromJson(Bar2)

  echo parseJson("""
    {
      "id": 123
    }
  """).fromJson(Bar2)

  bar2 = parseJson("""
    {
      "id": 123,
      "foo": {"id": 456}
    }
  """).fromJson(Bar2)
  echo bar2.foo.id

  echo parseJson("""
    {
      "random": 123,
      "json": {"id": 456}
    }
  """).toJson()

  type
    Foo3 = ref object
      data: JsonNode

  var foo3 = parseJson("""
    {
      "data": {"id": 456}
    }
  """).fromJson(Foo3)
  echo foo3.data
