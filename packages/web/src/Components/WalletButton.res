@react.component
let make = (~address, ~provider) => {
  let handleClick = _ => {
    Js.log("WalletButton clicked")
  }

  let formattedAddress =
    Js.String2.slice(address, ~from=0, ~to_=6) ++
    "..." ++
    Js.String2.sliceToEnd(address, ~from=Js.String2.length(address) - 4)

  <MaterialUi.Button
    variant=#Contained
    color=#Primary
    onClick={handleClick}
    classes={MaterialUi.Button.Classes.make(~label=Cn.make(["py-2"]), ())}>
    <span
      className={Cn.make([
        "font-mono",
        "font-bold",
        "text-darkPrimary",
        "mr-2",
        "leading-none",
        "normal-case",
      ])}>
      {React.string(formattedAddress)}
    </span>
    <Externals.Davatar address={address} size={16} provider={provider} />
  </MaterialUi.Button>
}
