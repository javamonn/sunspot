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
  let router: Externals.Next.Router.router = Externals.Next.Router.useRouter()
  let {openDialog: openAccountSubscriptionDialog} = React.useContext(
    Contexts_AccountSubscriptionDialog_Context.context,
  )
  let ({data: account}: Externals.Wagmi.UseAccount.result, _) = Externals.Wagmi.UseAccount.use()

  let handleUpgradeAccess = _ => {
    let _ = openAccountSubscriptionDialog(None)
  }

  let makeToggleButtonClasses = selected =>
    MaterialUi_Lab.ToggleButton.Classes.make(
      ~root=Cn.make(["px-8", "text-sm", "leading-none", "py-2"]),
      ~label=Cn.make([
        "lowercase",
        "font-bold",
        selected ? "text-darkPrimary" : "text-darkSecondary",
      ]),
      ~selected=Cn.make(["bg-darkBorder"]),
      (),
    )

  <header
    className={Cn.make(["flex", "flex-row", "justify-between", "items-center", "sm:px-4", "mt-4"])}>
    <div className={Cn.make(["flex", "flex-row", "items-center"])}>
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
      <MaterialUi_Lab.ToggleButtonGroup
        size=#Small
        exclusive={true}
        orientation=#Horizontal
        classes={MaterialUi_Lab.ToggleButtonGroup.Classes.make(~root=Cn.make(["ml-10"]), ())}>
        <MaterialUi_Lab.ToggleButton
          value={MaterialUi_Types.Any("left")}
          selected={router.pathname === "/alerts"}
          size=#Small
          style={ReactDOM.Style.make(~height="36px", ())}
          classes={makeToggleButtonClasses(router.pathname === "/alerts")}>
          {React.string("alerts")}
        </MaterialUi_Lab.ToggleButton>
        <MaterialUi_Lab.ToggleButton
          selected={router.pathname === "/events"}
          value={MaterialUi_Types.Any("right")}
          size=#Small
          classes={makeToggleButtonClasses(router.pathname === "/events")}>
          {React.string("events")}
        </MaterialUi_Lab.ToggleButton>
      </MaterialUi_Lab.ToggleButtonGroup>
    </div>
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
  </header>
}
