@react.component
let make = () => {
  let (eth, setEth) = React.useState(() => Contexts.Eth.Types.Unknown)

  let _ = React.useEffect0(() => {
    let _ = Externals.Metamask.detectEthereumProvider() |> Js.Promise.then_(provider => {
      let _ = switch Js.Nullable.toOption(provider) {
      | None => setEth(_ => Web3Unavailable)
      | Some(provider) =>
        let web3 = Externals.Web3.make(provider)

        let _ =
          web3
          |> Externals.Web3.getAccounts
          |> Js.Promise.then_(accounts => {
            let _ = switch Belt.Array.get(accounts, 0) {
            | Some(address) =>
              setEth(_ => Connected({provider: provider, address: address, web3: web3}))
            | None => setEth(_ => NotConnected({web3: web3, provider: provider}))
            }
            Js.Promise.resolve()
          })
      }

      Js.Promise.resolve()
    })

    let ethListeners = [
      #accountsChanged(
        addresses => {
          switch (Belt.Array.get(addresses, 0), eth) {
          | (Some(address), Connected(eth)) => setEth(_ => Connected({...eth, address: address}))
          | (None, Connected({provider, web3})) =>
            setEth(_ => NotConnected({provider: provider, web3: web3}))
          | _ => ()
          }
        },
      ),
    ]

    switch Externals.Ethereum.inst->Js.Nullable.toOption {
    | Some(eth) =>
      ethListeners->Belt.Array.forEach(listener => Externals.Ethereum.on(eth, listener))
    | None => ()
    }

    Some(
      () => {
        switch Externals.Ethereum.inst->Js.Nullable.toOption {
        | Some(eth) =>
          ethListeners->Belt.Array.forEach(listener =>
            Externals.Ethereum.removeListener(eth, listener)
          )
        | None => ()
        }
      },
    )
  })

  let handleConnectWalletClicked = _ =>
    switch eth {
    | NotConnected({provider, web3}) =>
      let _ =
        provider
        |> Externals.Ethereum.requestAccounts
        |> Js.Promise.then_(addresses => {
          addresses
          ->Externals.Ethereum.result
          ->Belt.Array.get(0)
          ->Belt.Option.map(address =>
            Externals.Web3.personalSign(
              web3,
              "Sign in",
              address,
            ) |> Js.Promise.then_(signedMessage => {
              Js.log2("signedMessage", signedMessage)
              Js.Promise.resolve()
            })
          )
          ->Belt.Option.getWithDefault(Js.Promise.resolve())
        })
    | _ => ()
    }

  <AlertsHeader eth onConnectWalletClicked={handleConnectWalletClicked} />
}
