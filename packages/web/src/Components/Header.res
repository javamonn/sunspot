@react.component
let make = (
  ~authentication: Contexts_Auth.authentication,
  ~isLoadingAccountSubscription,
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

  <header
    className={Cn.make([
      "flex",
      "flex-row",
      "justify-between",
      "items-center",
      "md:flex-col",
      "md:items-stretch",
      "sm:px-4",
      "mt-4",
      "px-4",
    ])}>
    <div className={Cn.make(["flex", "flex-1", "items-center"])}>
      <div className={Cn.make(["flex", "flex-row", "items-center", "flex-1"])}>
        <h1
          className={Cn.make([
            "font-mono",
            "text-darkPrimary",
            "font-bold",
            "italic",
            "text-lg",
            "leading-none",
          ])}>
          <Externals.Next.Link href="/"> {React.string("sunspot")} </Externals.Next.Link>
        </h1>
        <HeaderToggleButton className={Cn.make(["md:hidden", "ml-10"])} />
      </div>
      <div className={Cn.make(["flex", "flex-row", "justify-center", "items-center"])}>
        <MaterialUi.Button
          onClick={_ => {
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
            | None if !isLoadingAccountSubscription =>
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
    </div>
    <HeaderToggleButton
      className={Cn.make(["hidden", "md:flex", "mt-4"])} buttonClassName={Cn.make(["flex-1"])}
    />
  </header>
}
