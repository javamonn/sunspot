@react.component
let make = (~isOpen, ~onClose) => {
  let (
    {data, loading: isConnecting}: Externals.Wagmi.UseConnect.result,
    connect,
  ) = Externals.Wagmi.UseConnect.use()

  let handleConnect = connector => {
    let _ = connect(
      connector,
    ) |> Js.Promise.then_((result: Externals.Wagmi.UseConnect.connectResult) => {
      let _ = switch result {
      | {data: Some(_)} => onClose(true)
      | {error: Some(err)} =>
        Services.Logger.jsExn(~tag="ConnectWalletModal", ~message="handleConnect error", err)
        onClose(false)
      | _ => onClose(false)
      }
      Js.Promise.resolve()
    })
  }

  <MaterialUi.Dialog _open={isOpen} onClose={(_, _) => onClose(false)}>
    <MaterialUi.DialogTitle> {React.string("connect wallet")} </MaterialUi.DialogTitle>
    <MaterialUi.DialogContent
      classes={MaterialUi.DialogContent.Classes.make(
        ~root=Cn.make(["flex", "flex-row", "items-center"]),
        (),
      )}>
      {data
      ->Belt.Option.map(Externals.Wagmi.UseConnect.connectors)
      ->Belt.Option.getWithDefault([])
      ->Belt.Array.map(connector => {
        let iconSrc =
          connector->Externals.Wagmi.Connector.name === "MetaMask"
            ? "/metamask-icon.svg"
            : "/walletconnect-icon.svg"

        <MaterialUi.Button
          key={connector->Externals.Wagmi.Connector.id}
          variant=#Text
          onClick={_ => handleConnect(connector)}
          disabled={!Externals.Wagmi.Connector.ready(connector) || isConnecting->Belt.Option.getWithDefault(false)}
          classes={MaterialUi.Button.Classes.make(
            ~root=Cn.make(["w-64", "h-64"]),
            ~label=Cn.make(["flex", "flex-col", "items-center", "justify-between", "flex-1"]),
            (),
          )}>
          <MaterialUi.Avatar
            classes={MaterialUi.Avatar.Classes.make(
              ~root=Cn.make(["bg-gray-200", "w-28", "h-28", "p-4", "mb-6"]),
              (),
            )}>
            <img src={iconSrc} />
          </MaterialUi.Avatar>
          <MaterialUi.Typography
            variant=#H6
            classes={MaterialUi.Typography.Classes.make(
              ~h6=Cn.make(["leading-none", "lowercase"]),
              (),
            )}>
            {connector->Externals.Wagmi.Connector.name->React.string}
          </MaterialUi.Typography>
        </MaterialUi.Button>
      })}
    </MaterialUi.DialogContent>
  </MaterialUi.Dialog>
}
