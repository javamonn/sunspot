@react.component
let make = (~address, ~onClick, ~authentication: Contexts.Auth.authentication) => {
  let {state: {connecting}} = Externals.Wagmi.UseContext.use()
  let content = switch authentication {
  | InProgress_PromptConnectWallet
  | InProgress_PromptAuthenticationChallenge(_)
  | InProgress_AuthenticationChallenge(_)
  | InProgress_JWTRefresh(_) =>
    <LoadingButton />
  | _ if connecting => <LoadingButton />
  | _ =>
    <MaterialUi.Button
      variant=#Outlined
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
        {
          let formattedAddress =
            Js.String2.slice(address, ~from=0, ~to_=6) ++
            "..." ++
            Js.String2.sliceToEnd(address, ~from=Js.String2.length(address) - 4)
          React.string(formattedAddress)
        }
      </span>
      {switch authentication {
      | Unauthenticated_AuthenticationChallengeRequired(_) =>
        <Externals.MaterialUi_Icons.Error
          className={Cn.make(["w-5", "h-5", "ml-2", "text-red-400"])}
        />
      | Authenticated(_) =>
        <Externals.Davatar.Jazzicon address={address} size={16} />
      | _ => React.null
      }}
    </MaterialUi.Button>
  }

  switch authentication {
  | Unauthenticated_AuthenticationChallengeRequired(_) =>
    <MaterialUi.Tooltip title={React.string("authentication challenge required.")}>
      {content}
    </MaterialUi.Tooltip>
  | _ => content
  }
}
