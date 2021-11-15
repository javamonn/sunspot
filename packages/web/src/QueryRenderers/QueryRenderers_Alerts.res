open QueryRenderers_Alerts_GraphQL

type updateAlertModalState =
  | UpdateAlertModalOpen(AlertModal.Value.t)
  | UpdateAlertModalClosed

@react.component
let make = () => {
  let {eth}: Contexts.Eth.t = React.useContext(Contexts.Eth.context)
  let {signIn, authentication}: Contexts.Auth.t = React.useContext(Contexts.Auth.context)
  let query = Query_AlertRulesByAccountAddress.AlertRulesByAccountAddress.use(
    ~skip=switch authentication {
    | Authenticated(_) => false
    | _ => true
    },
    switch authentication {
    | Authenticated({jwt: {accountAddress}}) => makeVariables(~accountAddress)
    | _ => makeVariables(~accountAddress="")
    },
  )
  let (createAlertModalIsOpen, setCreateAlertModalIsOpen) = React.useState(_ => false)
  let (updateAlertModal, setUpdateAlertModal) = React.useState(_ => UpdateAlertModalClosed)

  let queryItems = switch query {
  | {data: Some({alertRules: Some({items: Some(items)})})} =>
    items->Belt.Array.keepMap(item => item)
  | _ => []
  }

  let tableRows =
    queryItems
    ->Externals.Lodash.sortBy(item =>
      -.(
        item.updatedAt
        ->Js.Json.decodeString
        ->Belt.Option.map(s => s->Js.Date.fromString->Js.Date.valueOf)
        ->Belt.Option.getWithDefault(0.0)
      )
    )
    ->Belt.Array.map(item => {
      AlertsTable.id: item.id,
      collectionName: item.collection.name,
      collectionSlug: item.collection.slug,
      collectionImageUrl: item.collection.imageUrl,
      event: "list",
      rules: item.eventFilters
      ->Belt.Array.keepMap(eventFilter =>
        switch eventFilter {
        | #AlertPriceThresholdEventFilter(eventFilter) =>
          let modifier = switch eventFilter.direction {
          | #ALERT_ABOVE => ">"
          | #ALERT_BELOW => "<"
          | #FutureAddedValue(v) => v
          }
          let formattedPrice =
            Services.PaymentToken.parsePrice(eventFilter.value, eventFilter.paymentToken.decimals)
            ->Belt.Option.map(Belt.Float.toString)
            ->Belt.Option.getExn

          Some([AlertsTable.PriceRule({modifier: modifier, price: formattedPrice})])
        | #AlertAttributesEventFilter({attributes}) =>
          attributes
          ->Belt.Array.keepMap(attribute =>
            switch attribute {
            | #OpenSeaAssetNumberAttribute({traitType, numberValue}) =>
              Some(
                AlertsTable.PropertyRule({
                  traitType: traitType,
                  displayValue: Belt.Float.toString(numberValue),
                }),
              )
            | #OpenSeaAssetStringAttribute({traitType, stringValue}) =>
              Some(AlertsTable.PropertyRule({traitType: traitType, displayValue: stringValue}))
            | #FutureAddedValue(_) => None
            }
          )
          ->Js.Option.some
        | #FutureAddedValue(_) => None
        }
      )
      ->Belt.Array.concatMany,
    })

  let handleConnectWalletClicked = _ => {
    let _ = signIn()
  }
  let handleRowClick = row =>
    queryItems
    ->Belt.Array.getBy(item => AlertsTable.id(row) == item.id)
    ->Belt.Option.forEach(item => {
      let priceRule =
        item.eventFilters
        ->Belt.Array.getBy(eventFilter =>
          switch eventFilter {
          | #AlertPriceThresholdEventFilter(_) => true
          | _ => false
          }
        )
        ->Belt.Option.flatMap(eventFilter =>
          switch eventFilter {
          | #AlertPriceThresholdEventFilter(eventFilter) =>
            CreateAlertRule_Price.makeRule(
              ~modifier=switch eventFilter.direction {
              | #ALERT_ABOVE => ">"
              | #ALERT_BELOW => "<"
              | #FutureAddedValue(v) => v
              },
              ~value=Services.PaymentToken.parsePrice(
                eventFilter.value,
                eventFilter.paymentToken.decimals,
              )->Belt.Option.map(Belt.Float.toString),
            )->Js.Option.some
          | _ => None
          }
        )

      let propertiesRule =
        item.eventFilters
        ->Belt.Array.getBy(eventFilter =>
          switch eventFilter {
          | #AlertAttributesEventFilter(_) => true
          | _ => false
          }
        )
        ->Belt.Option.flatMap(eventFilter =>
          switch eventFilter {
          | #AlertAttributesEventFilter(eventFilter) =>
            eventFilter.attributes
            ->Belt.Array.keepMap(attribute =>
              switch attribute {
              | #OpenSeaAssetNumberAttribute({traitType, numberValue}) =>
                Some({
                  CreateAlertRule_Properties.Value.value: CreateAlertRule_Properties.NumberValue({
                    value: numberValue,
                  }),
                  traitType: traitType,
                })
              | #OpenSeaAssetStringAttribute({traitType, stringValue}) =>
                Some({
                  CreateAlertRule_Properties.Value.value: CreateAlertRule_Properties.StringValue({
                    value: stringValue,
                  }),
                  traitType: traitType,
                })
              | _ => None
              }
            )
            ->Js.Option.some
          | _ => None
          }
        )

      let alertModalValue = AlertModal.Value.make(
        ~collection=Some(
          AlertModal.CollectionOption.make(
            ~name=item.collection.name,
            ~slug=item.collection.slug,
            ~imageUrl=item.collection.imageUrl,
            ~contractAddress=item.collection.contractAddress,
          ),
        ),
        ~priceRule,
        ~propertiesRule,
        ~id=item.id,
      )

      setUpdateAlertModal(_ => UpdateAlertModalOpen(alertModalValue))
    })

  let isUnsupportedBrowser = Config.isBrowser() && !Services.PushNotification.isSupported()
  let isLoading = switch (eth, query) {
  | (_, {loading: true})
  | (_, {called: false})
  | (Unknown, _) => true
  | _ if !Config.isBrowser() => true
  | _ => false
  }

  <>
    <AlertsHeader
      eth
      onConnectWalletClicked={handleConnectWalletClicked}
      onWalletButtonClicked={handleConnectWalletClicked}
      onCreateAlertClicked={_ => setCreateAlertModalIsOpen(_ => true)}
      authenticationChallengeRequired={switch authentication {
      | AuthenticationChallengeRequired => true
      | _ => false
      }}
      isUnsupportedBrowser={isUnsupportedBrowser}
    />
    <Containers.CreateAlertModal
      isOpen={createAlertModalIsOpen}
      onClose={_ => setCreateAlertModalIsOpen(_ => false)}
      accountAddress=?{switch authentication {
      | Authenticated({jwt: {accountAddress}}) => Some(accountAddress)
      | _ => None
      }}
    />
    <Containers.UpdateAlertModal
      isOpen={switch updateAlertModal {
      | UpdateAlertModalOpen(_) => true
      | _ => false
      }}
      value=?{switch updateAlertModal {
      | UpdateAlertModalOpen(v) => Some(v)
      | _ => None
      }}
      onClose={_ => setUpdateAlertModal(_ => UpdateAlertModalClosed)}
      accountAddress=?{switch authentication {
      | Authenticated({jwt: {accountAddress}}) => Some(accountAddress)
      | _ => None
      }}
    />
    <AlertsTable
      isLoading={isLoading}
      rows={isUnsupportedBrowser ? [] : tableRows}
      onRowClick={handleRowClick}
      isUnsupportedBrowser={isUnsupportedBrowser}
    />
  </>
}
