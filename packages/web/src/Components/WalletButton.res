@react.component
let make = (~address, ~provider, ~onClick, ~authenticationChallengeRequired=false) => {
  let formattedAddress =
    Js.String2.slice(address, ~from=0, ~to_=6) ++
    "..." ++
    Js.String2.sliceToEnd(address, ~from=Js.String2.length(address) - 4)

  let content =
    <div className={Cn.make(["border-b", "border-solid", "border-black"])}>
      <MaterialUi.Button
        variant=#Text
        onClick={onClick}
        classes={MaterialUi.Button.Classes.make(~label=Cn.make(["py-1"]), ())}>
        <span
          className={Cn.make([
            "block",
            "font-bold",
            "text-darkPrimary",
            "mr-2",
            "leading-none",
            "normal-case",
          ])}>
          {React.string(formattedAddress)}
        </span>
        {authenticationChallengeRequired
          ? <Externals.MaterialUi_Icons.Error
              style={ReactDOM.Style.make(~color="#f44336", ())} className={Cn.make(["w-5", "h-5"])}
            />
          : <Externals.Davatar address={address} size={16} provider={provider} />}
      </MaterialUi.Button>
    </div>

  if authenticationChallengeRequired {
    <MaterialUi.Tooltip title={React.string("Authentication challenge required.")}>
      {content}
    </MaterialUi.Tooltip>
  } else {
    content
  }
}
