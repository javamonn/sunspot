@react.component
let make = (~eth: Contexts.Eth.state, ~onConnectWalletClicked) =>
  <header className={Cn.make(["flex", "flex-row", "justify-between", "items-center"])}>
    <h1 className={Cn.make(["font-mono", "text-lightPrimary", "font-bold"])}>
      {React.string("sunspot")}
    </h1>
    {switch eth {
    | Connected({address, provider}) => <WalletButton address provider />
    | _ => <ConnectWalletButton onClick={onConnectWalletClicked} />
    }}
  </header>
