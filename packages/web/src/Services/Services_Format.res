let percent = p => {
  let formatted = Js.Float.toFixedWithPrecision(~digits=2, p *. 100.0)
  let display = formatted->Js.Float.fromString->Js.Float.toString

  `${display}%`
}
