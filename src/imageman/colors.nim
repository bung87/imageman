import math, random

type
  Size = static int
  ColorComponent* = uint8 | float32
  ColorAny*[S: Size, C: ColorComponent] = array[S, C]
  ColorU*[S: Size] = array[S, uint8]
  ColorF*[S: Size] = array[S, float32]
  ColorA*[C: ColorComponent] = array[4, C]
  ColorRGBU* = array[3, uint8]
  ColorRGBAU* = array[4, uint8]
  ColorRGBF* = array[3, float32]
  ColorRGBAF* = array[4, float32]
  ColorRGBUAny* = ColorRGBU | ColorRGBAU
  ColorRGBFAny* = ColorRGBF | ColorRGBAF
  ColorRGBAny* = ColorRGBUAny | ColorRGBFAny
  Color* = ColorRGBAny

template r*(c: Color): untyped = c[0]
template g*(c: Color): untyped = c[1]
template b*(c: Color): untyped = c[2]
template a*(c: ColorA): untyped = c[3]
template `r=`*(c: var Color, i: untyped) = c[0] = i
template `g=`*(c: var Color, i: untyped) = c[1] = i
template `b=`*(c: var Color, i: untyped) = c[2] = i
template `a=`*(c: var ColorA, i: untyped) = c[3] = i

template maxValue*(t: typedesc[Color]): untyped =
  when T is float32:
    1.0
  elif T is uint8:
    255

template componentType*(t: typedesc[Color]): untyped =
  when T is ColorRGBFAny:
    float32
  else:
    uint8

template maxComponentValue*(t: typedesc[Color]): untyped =
  when T is ColorRGBFAny:
    1.0'f32
  else:
    255'u8

template precise*[T: ColorComponent](t: T): float32 =
  when T is uint8:
    t.float32
  else:
    t

func toLinear*(c: uint8): float32 =
  c.float32 / 255

func toUint8*(c: float32): uint8 =
  uint8(c * 255)

func toRGB*(c: ColorRGBAU): ColorRGBU =
  copyMem addr result, unsafeAddr c, sizeof ColorRGBU

func toRGBA*(c: ColorRGBU): ColorRGBAU =
  copyMem addr result, unsafeAddr c, sizeof ColorRGBU
  result.a = 255

func toRGBF*(c: ColorRGBAF): ColorRGBF =
  copyMem addr result, unsafeAddr c, sizeof ColorRGBF

func toRGBAF*(c: ColorRGBF): ColorRGBAF =
  copyMem addr result, unsafeAddr c, sizeof ColorRGBF
  result.a = 1.0

func toRGBF*(c: ColorRGBAny): ColorRGBF =
  [c.r.toLinear, c.g.toLinear, c.b.toLinear]

func toRGB*(c: ColorRGBFAny): ColorRGBU =
  [c.r.toUint8, c.g.toUint8, c.b.toUint8]

func toRGBAF*(c: ColorRGBAU): ColorRGBAF =
  [c.r.toLinear, c.g.toLinear, c.b.toLinear, c.a.toLinear]

func toRGBAF*(c: ColorRGBU): ColorRGBAF =
  [c.r.toLinear, c.g.toLinear, c.b.toLinear, 1.0]

func toRGBA*(c: ColorRGBAF): ColorRGBAU =
  [c.r.toUint8, c.g.toUint8, c.b.toUint8, c.a.toUint8]

func blendColorValue*[T: ColorComponent](a, b: T, t: float32): T {.inline.} =
  T sqrt((1.0 - t) * a.precise * a.precise + t * b.precise * b.precise)

func `+`*[S, C](a, b: ColorAny[S, C]): ColorAny[S, C] =
  when S >= 3:
    result.r = blendColorValue(a.r, b.r, 0.3)
    result.g = blendColorValue(a.g, b.g, 0.3)
    result.b = blendColorValue(a.b, b.b, 0.3)
  elif S == 4:
    result.a = a.a

func `$`*(c: ColorRGBAF): string =
  "(r: " & $c.r & ", g: " & $c.g & ", b: " & $c.b & ", a: " & $c.a & ")"

func `$`*(c: ColorRGBAU): string =
  "(r: " & $c.r & ", g: " & $c.g & ", b: " & $c.b & ", a: " & $c.a & ")"

func `$`*(c: ColorRGBU): string =
  "(r: " & $c.r & ", g: " & $c.g & ", b: " & $c.b & ")"

func `~=`*(a, b: ColorRGBAF, e = 0.01'f32): bool =
  abs(a.r - b.r) < e and abs(a.g - b.g) < e and abs(a.b - b.b) < e

proc rand*[T: Color]: T =
  when T is ColorRGBU:
    [uint8 rand(255), uint8 rand(255), uint8 rand(255)]
  elif T is ColorRGBAU:
    [uint8 rand(255), uint8 rand(255), uint8 rand(255), uint rand(255)]
  elif T is ColorRGBF:
    [rand(1.0), rand(1.0), rand(1.0)]
  elif T is ColorRGBAF:
    [rand(1.0), rand(1.0), rand(1.0), uint rand(1.0)]

func rand*[T: Color](r: var Rand): T =
  when T is ColorRGBU:
    [uint8 r.rand(255), uint8 r.rand(255), uint8 r.rand(255)]
  elif T is ColorRGBAU:
    [uint8 r.rand(255), uint8 r.rand(255), uint8 r.rand(255), uint r.rand(255)]
  elif T is ColorRGBF:
    [r.rand(1.0), r.rand(1.0), r.rand(1.0)]
  elif T is ColorRGBAF:
    [r.rand(1.0), r.rand(1.0), r.rand(1.0), r.rand(1.0)]

func isGreyscale*(c: Color): bool =
  c.r == c.g and c.r == c.b

func interpolate*[T: Color](a, b: T, x: float32, L = 1.0): T =
  result.r = (T.componentType) (a.r.precise + x * (b.r.precise - a.r.precise) / L)
  result.g = (T.componentType) (a.g.precise + x * (b.g.precise - a.g.precise) / L)
  result.b = (T.componentType) (a.b.precise + x * (b.b.precise - a.b.precise) / L)
  when T is ColorA:
    result.a = (T.componentType) (a.a.precise + x * (b.a.precise - a.a.precise) / L)
