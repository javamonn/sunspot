@react.component
let make = (
  ~address,
  ~authentication: Contexts_Auth.authentication,
  ~accountSubscription: option<
    Query_AccountSubscription.GraphQL.AccountSubscription.t,
  >,
  ~onWalletButtonClicked,
) => {
  let {state: {connecting}} = Externals.Wagmi.UseContext.use()
  let (_, disconnect) = Externals.Wagmi.UseAccount.use()
  let {openDialog: openAccountSubscriptionDialog} = React.useContext(
    Contexts_AccountSubscriptionDialog_Context.context,
  )

  let (menuAnchor, setMenuAnchor) = React.useState(_ => None)

  let handleWalletButtonClick = ev =>
    switch authentication {
    | Authenticated(_) =>
      let newMenuAnchor = ev->ReactEvent.Mouse.target->Js.Option.some
      setMenuAnchor(_ => newMenuAnchor)
    | _ => onWalletButtonClicked()
    }

  let handleMenuClose = (_, _) => {
    setMenuAnchor(_ => None)
  }
  let handleUpgradeAccountClick = _ => {
    let _ = openAccountSubscriptionDialog(None)
    setMenuAnchor(_ => None)
  }
  let handleDisconnect = _ => {
    disconnect()
    setMenuAnchor(_ => None)
  }

  let content = switch authentication {
  | InProgress_PromptConnectWallet
  | InProgress_PromptAuthenticationChallenge(_)
  | InProgress_AuthenticationChallenge(_)
  | InProgress_JWTRefresh(_) =>
    <LoadingButton />
  | _ if connecting => <LoadingButton />
  | _ => <>
      <MaterialUi.Button
        variant=#Outlined
        onClick={handleWalletButtonClick}
        classes={MaterialUi.Button.Classes.make(~label=Cn.make(["py-1"]), ())}>
        <span
          className={Cn.make([
            "block",
            "font-bold",
            "text-darkPrimary",
            "mt-1",
            "mr-2",
            "leading-none",
            "normal-case",
          ])}>
          {React.string(Js.String2.slice(address, ~from=0, ~to_=6))}
          <span className={Cn.make(["sm:hidden"])}>
            {React.string(
              "..." ++ Js.String2.sliceToEnd(address, ~from=Js.String2.length(address) - 4),
            )}
          </span>
        </span>
        {switch authentication {
        | Unauthenticated_AuthenticationChallengeRequired(_) =>
          <Externals.MaterialUi_Icons.Error
            className={Cn.make(["w-5", "h-5", "ml-2", "text-red-400"])}
          />
        | Authenticated(_) => <Externals.Davatar.Jazzicon address={address} size={16} />
        | _ => React.null
        }}
      </MaterialUi.Button>
      <MaterialUi.Menu
        anchorEl=?{menuAnchor->Belt.Option.map(e => MaterialUi_Types.Any(e))}
        _open={Js.Option.isSome(menuAnchor)}
        onClose={handleMenuClose}>
        <MaterialUi.MenuItem onClick={handleUpgradeAccountClick}>
          {
            let (primary, secondary) = switch accountSubscription {
            | Some({type_: #TELESCOPE, ttl}) =>
              let displayTTL = Externals.DateFns.formatDistanceStrict(
                ttl->Js.Json.decodeNumber->Belt.Option.getExn *. 1000.0,
                Js.Date.now(),
                Externals.DateFns.formatDistanceStrictOptions(
                  ~unit_="day",
                  ~roundingMethod="ceil",
                  (),
                ),
              )

              ("account status", `telescope · ${displayTTL} remaining`)
            | Some({type_: #OBSERVATORY, ttl}) =>
              let displayTTL = Externals.DateFns.formatDistanceStrict(
                ttl->Js.Json.decodeNumber->Belt.Option.getExn *. 1000.0,
                Js.Date.now(),
                Externals.DateFns.formatDistanceStrictOptions(
                  ~unit_="day",
                  ~roundingMethod="ceil",
                  (),
                ),
              )

              ("account status", `observatory · ${displayTTL} remaining`)
            | _ => ("upgrade account", "upgrade account to access premium features")
            }

            <MaterialUi.ListItemText
              primary={React.string(primary)} secondary={React.string(secondary)}
            />
          }
        </MaterialUi.MenuItem>
        <MaterialUi.MenuItem onClick={handleDisconnect}>
          <MaterialUi.ListItemText primary={React.string("log out")} />
        </MaterialUi.MenuItem>
      </MaterialUi.Menu>
    </>
  }

  switch authentication {
  | Unauthenticated_AuthenticationChallengeRequired(_) =>
    <MaterialUi.Tooltip title={React.string("authentication challenge required.")}>
      {content}
    </MaterialUi.Tooltip>
  | _ => content
  }
}
