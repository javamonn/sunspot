let percent = (~includeSymbol=true, p) => {
  let formatted = Js.Float.toFixedWithPrecision(~digits=2, p *. 100.0)
  let display = formatted->Js.Float.fromString->Js.Float.toString

  `${display}${includeSymbol ? "%" : ""}`
}

let address = address => {
  let head = Js.String2.slice(address, ~from=0, ~to_=6)
  let tail = Js.String2.sliceToEnd(address, ~from=Js.String2.length(address) - 4)

  `${head}...${tail}`
}
