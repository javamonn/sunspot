module Fragment_OrderSection_Header_OpenSeaEvent = %graphql(`
  fragment OrderSection_Header_OpenSeaEvent on OpenSeaEvent {
    paymentToken {
      id
      imageUrl
      decimals
    }
    startingPrice
  }
`)

module Fragment_OrderSection_Header_Account = %graphql(`
  fragment OrderSection_Header_Account on Account {
    address
    quickbuyFee
    subscription {
      accountAddress
      type_: type  
    }
  }
`)

@react.component
let make = (
  ~onClickBuy,
  ~executionState,
  ~quickbuy,
  ~openSeaEvent: Fragment_OrderSection_Header_OpenSeaEvent.t,
  ~account: option<Fragment_OrderSection_Header_Account.t>,
) => {
  let {openDialog: openAccountSubscriptionDialog} = React.useContext(
    Contexts_AccountSubscriptionDialog_Context.context,
  )

  let displayFee = {
    let feeBasisPoint = switch (
      account
      ->Belt.Option.flatMap(account => account.quickbuyFee)
      ->Belt.Option.flatMap(Belt.Float.fromString),
      account
      ->Belt.Option.flatMap(account => account.subscription)
      ->Belt.Option.flatMap(({type_}) =>
        switch type_ {
        | #OBSERVATORY => Some(0.0)
        | #TELESCOPE => Some(100.0)
        | #FutureAddedValue(_) => None
        }
      ),
    ) {
    | (Some(f1), Some(f2)) => Js.Math.min_float(f1, f2)
    | (Some(f), _) | (_, Some(f)) => f
    | _ => Config.defaultQuickbuyFee->Belt.Float.fromString->Belt.Option.getExn
    }

    if feeBasisPoint != 0.0 {
      Some(`(+ ${Belt.Float.toString(feeBasisPoint /. 100.0)}% sunspot fee)`)
    } else {
      None
    }
  }

  let handleDisplayAccountSubscriptionDialog = _ => {
    let _ = openAccountSubscriptionDialog(
      Some(React.string("upgrade account to reduce quickbuy fee.")),
    )
  }

  <div
    className={Cn.make([
      "border",
      "border-solid",
      "border-darkDisabled",
      "rounded",
      "p-6",
      "mb-8",
      "flex",
      "flex-row",
      "sm:flex-col",
      "sm:p-4",
      "sm:space-y-4",
    ])}>
    <div className={Cn.make(["flex", "flex-row", "flex-1"])}>
      <div className={Cn.make(["flex", "flex-row", "justify-space", "leading-none"])}>
        <div className={Cn.make(["flex", "items-center", "justify-center", "mr-1"])}>
          <img
            style={ReactDOM.Style.make(~marginTop="6px", ~opacity="60%", ())}
            src={openSeaEvent.paymentToken
            ->Belt.Option.flatMap(p => p.imageUrl)
            ->Belt.Option.getWithDefault(
              Services.PaymentToken.ethPaymentToken.imageUrl->Belt.Option.getExn,
            )}
            className={Cn.make(["h-5", "mr-1"])}
          />
        </div>
        <div className={Cn.make(["flex", "justify-center", "items-center"])}>
          <div className={Cn.make(["flex", "flex-row", "items-end", "font-mono"])}>
            <span className={Cn.make(["font-bold", "text-4xl", "block", "mr-3", "leading-none"])}>
              {openSeaEvent.startingPrice
              ->Belt.Option.flatMap(startingPrice =>
                Services.PaymentToken.parseTokenPrice(
                  startingPrice,
                  openSeaEvent.paymentToken
                  ->Belt.Option.map(p => p.decimals)
                  ->Belt.Option.getWithDefault(Services.PaymentToken.ethPaymentToken.decimals),
                )
              )
              ->Belt.Option.map(Belt.Float.toString)
              ->Belt.Option.getWithDefault("N/A")
              ->React.string}
            </span>
            {displayFee
            ->Belt.Option.map(displayFee =>
              <MaterialUi.Tooltip title={React.string("upgrade account to reduce quickbuy fee.")}>
                <MaterialUi.Button
                  onClick={handleDisplayAccountSubscriptionDialog}
                  variant=#Text
                  size=#Small
                  classes={MaterialUi.Button.Classes.make(
                    ~label=Cn.make([
                      "flex",
                      "flex-row",
                      "font-mono",
                      "text-sm",
                      "text-darkSecondary",
                      "leading-none",
                      "lowercase",
                    ]),
                    (),
                  )}>
                  {React.string(displayFee)}
                </MaterialUi.Button>
              </MaterialUi.Tooltip>
            )
            ->Belt.Option.getWithDefault(React.null)}
          </div>
        </div>
      </div>
    </div>
    <div className={Cn.make(["flex-1"])}>
      <OrderSection_HeaderButton executionState={executionState} onClickBuy={onClickBuy} />
      {!quickbuy
        ? <QuickbuyPrompt className={Cn.make(["hidden", "sm:flex", "sm:mt-4"])} />
        : React.null}
    </div>
  </div>
}
