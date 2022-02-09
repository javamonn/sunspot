@react.component
let make = (
  ~provider,
  ~address,
  ~onClick,
  ~authentication: Contexts.Auth.authentication,
) => {
  let content =
    <div className={Cn.make(["border-b", "border-solid", "border-black"])}>
      <MaterialUi.Button
        variant=#Text
        onClick={onClick}
        classes={MaterialUi.Button.Classes.make(~label=Cn.make(["py-1"]), ())}>
        {switch (authentication) {
        | InProgress =>
          <div style={ReactDOM.Style.make(~width="80px", ())} className={Cn.make(["px-3"])}>
            <MaterialUi.LinearProgress color={#Secondary} variant={#Indeterminate} />
          </div>
        | _ =>
          <span
            className={Cn.make([
              "block",
              "font-bold",
              "text-darkPrimary",
              "mr-2",
              "leading-none",
              "normal-case",
            ])}>
            {
              let formattedAddress =
                Js.String2.slice(address, ~from=0, ~to_=6) ++
                "..." ++
                Js.String2.sliceToEnd(address, ~from=Js.String2.length(address) - 4)
              React.string(formattedAddress)
            }
          </span>
        }}
        {switch authentication {
        | AuthenticationChallengeRequired =>
          <Externals.MaterialUi_Icons.Error
            style={ReactDOM.Style.make(~color="#f44336", ())}
            className={Cn.make(["w-5", "h-5", "ml-2"])}
          />
        | Authenticated(_) =>
          <Externals.Davatar address={address} size={16} provider={provider} />
        | _ => React.null
        }}
      </MaterialUi.Button>
    </div>

  switch authentication {
  | AuthenticationChallengeRequired =>
    <MaterialUi.Tooltip title={React.string("authentication challenge required.")}>
      {content}
    </MaterialUi.Tooltip>
  | _ => content
  }
}
