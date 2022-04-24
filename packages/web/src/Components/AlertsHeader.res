@react.component
let make = (
  ~authentication: Contexts.Auth.authentication,
  ~isLoading,
  ~accountSubscription,
  ~onConnectWalletClicked,
  ~onWalletButtonClicked,
  ~onCreateAlertClicked,
) => {
  let {state: {connecting}} = Externals.Wagmi.UseContext.use()
  let {openDialog: openAccountSubscriptionDialog} = React.useContext(
    Contexts_AccountSubscriptionDialog_Context.context,
  )
  let ({data: account}: Externals.Wagmi.UseAccount.result, _) = Externals.Wagmi.UseAccount.use()

  let handleUpgradeAccess = _ => {
    let _ = openAccountSubscriptionDialog(None)
  }

  <header className={Cn.make(["flex", "flex-row", "justify-between", "items-center", "sm:px-4"])}>
    <h1 className={Cn.make(["font-mono", "text-darkPrimary", "font-bold", "leading-none"])}>
      <Externals.Next.Link href="/"> {React.string("sunspot")} </Externals.Next.Link>
      <span className={Cn.make(["sm:hidden"])}> {React.string(" / alerts")} </span>
    </h1>
    <div className={Cn.make(["flex", "flex-row", "justify-center", "items-center"])}>
      <MaterialUi.Button
        onClick={_ => {
          Services.Logger.log("create alert", "display modal")
          onCreateAlertClicked()
        }}
        startIcon={<Externals.MaterialUi_Icons.Add />}
        variant=#Contained
        color=#Primary
        classes={MaterialUi.Button.Classes.make(
          ~root=Cn.make(["mr-8", "sm:hidden"]),
          ~label=Cn.make(["normal-case"]),
          (),
        )}>
        {React.string("create alert")}
      </MaterialUi.Button>
      {switch account {
      | _ if connecting => <LoadingButton />
      | Some({address}) => <>
          {switch accountSubscription {
          | None if !isLoading =>
            <MaterialUi.Button
              variant=#Outlined
              onClick={handleUpgradeAccess}
              classes={MaterialUi.Button.Classes.make(
                ~root=Cn.make(["mr-8", "sm:mr-2"]),
                ~label=Cn.make(["lowercase"]),
                (),
              )}>
              {React.string("upgrade")}
              <span className={Cn.make(["sm:hidden", "whitespace-pre"])}>
                {React.string(" account")}
              </span>
            </MaterialUi.Button>
          | _ => React.null
          }}
          <WalletButton
            authentication={authentication}
            address={address}
            accountSubscription={accountSubscription}
            onWalletButtonClicked={onWalletButtonClicked}
          />
        </>
      | None => <ConnectWalletButton onClick={onConnectWalletClicked} />
      }}
      <AboutPopover iconButtonClassName={Cn.make(["sm:hidden"])} />
    </div>
  </header>
}
