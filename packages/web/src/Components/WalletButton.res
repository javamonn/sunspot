@react.component
let make = (~address, ~provider, ~onClick) => {
  let formattedAddress =
    Js.String2.slice(address, ~from=0, ~to_=6) ++
    "..." ++
    Js.String2.sliceToEnd(address, ~from=Js.String2.length(address) - 4)

  <div className={Cn.make(["border-b", "border-solid", "border-black"])}>
    <MaterialUi.Button
      variant=#Text
      onClick={onClick}
      classes={MaterialUi.Button.Classes.make(~label=Cn.make(["py-1"]), ())}>
      <span
        className={Cn.make([
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
  </div>
}
