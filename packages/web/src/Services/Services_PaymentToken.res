@deriving(accessors)
type t = {
  id: int,
  decimals: int,
  name: string,
  symbol: string,
}

let ethPaymentToken = {
  id: 1,
  decimals: 18,
  name: "Ether",
  symbol: "ETH",
}

let formatPrice = (price, paymentToken) =>
  switch price->Js.String2.split(".") {
  | ["", decimal] => Externals.Std.String.padEnd(decimal, paymentToken.decimals, "0")
  | [whole, decimal] => whole ++ Externals.Std.String.padEnd(decimal, paymentToken.decimals, "0")
  | [whole] => whole ++ Js.String2.repeat("0", paymentToken.decimals)
  | _ => Js.String2.repeat("0", paymentToken.decimals)
  }

let parsePrice = (price, decimals) => {
  let paddedPrice = Externals.Std.String.padStart(
    price,
    Js.Math.max_int(decimals - Js.String2.length(price), 0),
    "0",
  )
  let decimalIdx = Js.String2.length(paddedPrice) - decimals

  Belt.Float.fromString(
    Js.String2.substring(paddedPrice, ~from=0, ~to_=decimalIdx) ++
    "." ++
    Js.String2.substringToEnd(paddedPrice, ~from=decimalIdx),
  )
}
