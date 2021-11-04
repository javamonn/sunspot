@react.component
let make = (
  ~eth: Contexts.Eth.state,
  ~onConnectWalletClicked,
  ~onWalletButtonClicked,
  ~onCreateAlertClicked,
  ~authenticationChallengeRequired,
  ~isUnsupportedBrowser,
) => {
  let createAlertButtonDisabled = switch eth {
  | Connected(_) if authenticationChallengeRequired => true
  | Connected(_) if !isUnsupportedBrowser => false
  | _ => true
  }
  let createAlertButton =
    <MaterialUi.Button
      disabled={createAlertButtonDisabled}
      onClick={_ => createAlertButtonDisabled ? () : onCreateAlertClicked()}
      startIcon={<Externals.MaterialUi_Icons.Add />}
      variant=#Contained
      color=#Primary
      classes={MaterialUi.Button.Classes.make(
        ~root=Cn.make(["mr-8"]),
        ~label=Cn.make(["normal-case"]),
        (),
      )}>
      {React.string("create")}
    </MaterialUi.Button>

  <header className={Cn.make(["flex", "flex-row", "justify-between", "items-center"])}>
    <h1 className={Cn.make(["font-mono", "text-darkPrimary", "font-bold", "leading-none"])}>
      {React.string("sunspot / alerts")}
    </h1>
    <div className={Cn.make(["flex", "flex-row", "justify-center", "items-center"])}>
      {createAlertButtonDisabled
        ? <MaterialUi.Tooltip
            title={isUnsupportedBrowser
              ? React.string("switch to a supported browser to create alerts.")
              : React.string("connect a wallet to create alerts.")}>
            <div> createAlertButton </div>
          </MaterialUi.Tooltip>
        : createAlertButton}
      {switch eth {
      | Connected({address, provider}) =>
        <WalletButton
          address
          provider
          onClick={onWalletButtonClicked}
          authenticationChallengeRequired={authenticationChallengeRequired}
        />
      | _ => <ConnectWalletButton onClick={onConnectWalletClicked} />
      }}
      <AboutPopover />
    </div>
  </header>
}
