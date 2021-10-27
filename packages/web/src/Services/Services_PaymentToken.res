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
        
