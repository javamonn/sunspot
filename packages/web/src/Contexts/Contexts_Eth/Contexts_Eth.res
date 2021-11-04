type connected = {provider: Externals.Ethereum.t, address: string, web3: Externals.Web3.t}
type notConnected = {provider: Externals.Ethereum.t, web3: Externals.Web3.t}

type state =
  | Unknown
  | NotConnected(notConnected)
  | Connected(connected)
  | Web3Unavailable

type t = {eth: state}
let context = React.createContext({
  eth: Unknown,
})

module ContextProvider = {
  include React.Context
  let makeProps = (~value, ~children, ()) =>
    {
      "value": value,
      "children": children,
    }

  let make = React.Context.provider(context)
}

@react.component
let make = (~children) => {
  let (eth, setEth) = React.useState(() => Unknown)

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
              setEth(_ => Connected({
                provider: provider,
                address: Externals.Web3.toChecksumAddress(web3, address),
                web3: web3,
              }))
            | None => setEth(_ => NotConnected({web3: web3, provider: provider}))
            }
            Js.Promise.resolve()
          })
      }

      Js.Promise.resolve()
    })

    None
  })

  let _ = React.useEffect1(() => {
    let ethListeners = [
      #accountsChanged(
        addresses => {
          Services_Logger.logWithData(
            "Contexts_Eth",
            "accountsChanged",
            Js.Json.object_(
              Js.Dict.fromArray([
                ("addresses", addresses->Belt.Array.map(Js.Json.string)->Js.Json.array),
              ]),
            ),
          )
          switch (Belt.Array.get(addresses, 0), eth) {
          | (Some(address), Connected(eth)) =>
            setEth(_ => Connected({
              ...eth,
              address: Externals.Web3.toChecksumAddress(eth.web3, address),
            }))
          | (Some(address), NotConnected({provider, web3})) =>
            setEth(_ => Connected({
              provider: provider,
              web3: web3,
              address: Externals.Web3.toChecksumAddress(web3, address),
            }))
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
  }, [eth])

  let _ = React.useEffect1(() => {
    Services.Logger.logWithData(
      "Contexts_Eth",
      "context changed",
      Js.Json.object_(
        Js.Dict.fromArray([
          (
            "state",
            Js.Json.string(
              switch eth {
              | Unknown => "Unknown"
              | NotConnected(_) => "NotConnected"
              | Connected(_) => "Connected"
              | Web3Unavailable => "Web3Unavailable"
              },
            ),
          ),
        ]),
      ),
    )
    None
  }, [eth])

  <ContextProvider value={eth: eth}> {children} </ContextProvider>
}
