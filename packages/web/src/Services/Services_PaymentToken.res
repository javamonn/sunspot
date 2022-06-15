@deriving(accessors)
type t = {
  id: int,
  decimals: int,
  name: string,
  symbol: string,
  usdPrice: option<string>,
  imageUrl: option<string>,
}

let ethPaymentToken = {
  id: 1,
  decimals: 18,
  name: "Ether",
  symbol: "ETH",
  usdPrice: None,
  imageUrl: Some("https://openseauserdata.com/files/6f8e2979d428180222796ff4a33ab929.svg"),
}

let formatPrice = (tokenPrice, paymentToken) =>
  switch tokenPrice->Js.String2.split(".") {
  | ["", decimal] => Externals.Std.String.padEnd(decimal, paymentToken.decimals, "0")
  | [whole, decimal] => whole ++ Externals.Std.String.padEnd(decimal, paymentToken.decimals, "0")
  | [whole] => whole ++ Js.String2.repeat("0", paymentToken.decimals)
  | _ => Js.String2.repeat("0", paymentToken.decimals)
  }

let parseTokenPrice = (price, decimals) => {
  let paddedPrice = Externals.Std.String.padStart(price, decimals, "0")
  let decimalIdx = Js.String2.length(paddedPrice) - decimals

  Belt.Float.fromString(
    Js.String2.substring(paddedPrice, ~from=0, ~to_=decimalIdx) ++
    "." ++
    Js.String2.substringToEnd(paddedPrice, ~from=decimalIdx),
  )
}

let parseUsdPrice = (tokenPrice, ~paymentToken) => {
  parseTokenPrice(tokenPrice, paymentToken.decimals)->Belt.Option.flatMap(parsedTokenPrice =>
    paymentToken.usdPrice
    ->Belt.Option.flatMap(Belt.Float.fromString)
    ->Belt.Option.map(tokenUSDPrice => tokenUSDPrice *. parsedTokenPrice)
  )
}

let formatUsdPrice = usdPrice => `$${Js.Float.toFixedWithPrecision(usdPrice, ~digits=2)}`
