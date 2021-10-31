@react.component
let make = (
  ~eth: Contexts.Eth.state,
  ~onConnectWalletClicked,
  ~onWalletButtonClicked,
  ~onCreateAlertClicked,
  ~authenticationChallengeRequired,
) =>
  <header className={Cn.make(["flex", "flex-row", "justify-between", "items-center"])}>
    <h1 className={Cn.make(["font-mono", "text-darkPrimary", "font-bold"])}>
      {React.string("sunspot / alerts")}
    </h1>
    <div className={Cn.make(["flex", "flex-row"])}>
      <MaterialUi.Button
        onClick={_ => onCreateAlertClicked()}
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
    </div>
  </header>
