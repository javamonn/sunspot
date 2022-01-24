open AlertModal_Types

module Query_OpenSeaCollectionAggregateAttributes = %graphql(`
  query OpenSeaCollectionAggregateAttributes($slug: String!) {
    collection: getOpenSeaCollection(slug: $slug) {
      contractAddress
      slug
      attributes {
        traitType
        count
        values {
          ... on OpenSeaCollectionAttributeNumberValue {
            numberValue: value
          }
          ... on OpenSeaCollectionAttributeStringValue {
            stringValue: value
          }
        }
      }
    }
  }
`)

module Value = {
  @deriving(accessors)
  type t = {
    id: string,
    eventType: AlertRule_EventType.t,
    collection: option<CollectionOption.t>,
    priceRule: option<CreateAlertRule_Price.t>,
    propertiesRule: option<CreateAlertRule_Properties.Value.t>,
    destination: option<AlertRule_Destination.Value.t>,
  }

  let make = (~id, ~collection, ~priceRule, ~propertiesRule, ~destination, ~eventType) => {
    id: id,
    collection: collection,
    eventType: eventType,
    priceRule: priceRule,
    propertiesRule: propertiesRule,
    destination: destination,
  }

  let empty = () => {
    id: Externals.UUID.make(),
    collection: None,
    priceRule: None,
    propertiesRule: None,
    eventType: #listing,
    destination: Config.isBrowser() && Services.PushNotification.isSupported()
      ? Some(AlertRule_Destination.Value.WebPushAlertDestination)
      : None,
  }
}

@react.component
let make = (
  ~value,
  ~onChange,
  ~validationError,
  ~isExited,
  ~destinationOptions,
  ~destinationDisabled=?,
) => {
  let (
    executeCollectionAggregateAttributesQuery,
    collectionAggregateAttributesResult,
  ) = Query_OpenSeaCollectionAggregateAttributes.useLazy()

  let _ = React.useEffect1(() => {
    value
    ->Value.collection
    ->Belt.Option.forEach(collection => {
      let _ = executeCollectionAggregateAttributesQuery({
        slug: collection->CollectionOption.slugGet,
      })
    })
    None
  }, [value->Value.collection])

  let handlePriceRuleChange = priceRule =>
    onChange({
      ...value,
      Value.priceRule: priceRule,
    })
  let handlePropertiesRuleChange = propertiesRule =>
    onChange({
      ...value,
      Value.propertiesRule: propertiesRule,
    })
  let handleDestinationChange = destination =>
    onChange({
      ...value,
      Value.destination: Some(destination),
    })
  let handleEventTypeChange = eventType =>
    onChange({
      ...value,
      Value.eventType: eventType,
    })
  let handleConnectDiscord = () => Externals.Webapi.Window.open_(Config.discordOAuthUrl)
  let handleConnectSlack = () => Externals.Webapi.Window.open_(Config.slackOAuthUrl)
  let handleConnectTwitter = () => Externals.Webapi.Window.open_(Config.twitterOAuthUrl)

  let (
    isLoadingCollectionAggregateAttributes,
    collectionAggregateAttributes,
  ) = switch collectionAggregateAttributesResult {
  | Executed({data: Some({collection: Some({attributes})})}) =>
    let collectionAggregateAttributes = attributes->Belt.Array.map(aggreggateAttribute => {
      CreateAlertRule_Properties.Option.traitType: aggreggateAttribute.traitType,
      count: aggreggateAttribute.count,
      values: aggreggateAttribute.values->Belt.Array.keepMap(value =>
        switch value {
        | #OpenSeaCollectionAttributeNumberValue({numberValue}) =>
          Some(CreateAlertRule_Properties.NumberValue({value: numberValue}))
        | #OpenSeaCollectionAttributeStringValue({stringValue}) =>
          Some(CreateAlertRule_Properties.StringValue({value: stringValue}))
        | #FutureAddedValue(_) => None
        }
      ),
    })
    (false, collectionAggregateAttributes)
  | Executed({loading: true}) => (true, [])
  | _ => (false, [])
  }

  <>
    {validationError
    ->Belt.Option.map(error =>
      <MaterialUi_Lab.Alert
        severity=#Error classes={MaterialUi_Lab.Alert.Classes.make(~root=Cn.make(["mb-6"]), ())}>
        {React.string(error)}
      </MaterialUi_Lab.Alert>
    )
    ->Belt.Option.getWithDefault(React.null)}
    <AlertRule_CollectionAutocomplete
      onChange={collection =>
        onChange({
          ...value,
          collection: collection,
        })}
      value={value.collection}
    />
    <AlertRule_EventType value={value->Value.eventType} onChange={handleEventTypeChange} />
    <AlertRule_Destination
      value={value->Value.destination}
      onChange={handleDestinationChange}
      destinationOptions={destinationOptions}
      disabled=?{destinationDisabled}
      onConnectDiscord={handleConnectDiscord}
      onConnectSlack={handleConnectSlack}
      onConnectTwitter={handleConnectTwitter}
    />
    <CreateAlertRule_Accordion
      className={Cn.make(["mt-8"])}
      summaryIcon={<MaterialUi.Typography
        variant=#H5
        color=#Secondary
        classes={MaterialUi.Typography.Classes.make(~h5=Cn.make(["leading-none"]), ())}>
        {React.string(`Ξ`)}
      </MaterialUi.Typography>}
      summaryTitle={React.string("price rule")}
      summaryDescription={React.string("filter events by price threshold")}
      details={<CreateAlertRule_Price
        value=?{value->Value.priceRule} onChange={handlePriceRuleChange}
      />}
    />
    <CreateAlertRule_Accordion
      className={Cn.make(["mt-8"])}
      summaryIcon={<Externals_MaterialUi_Icons.LabelOutlined
        style={ReactDOM.Style.make(~opacity="0.42", ())}
      />}
      summaryTitle={React.string("properties rule")}
      summaryDescription={React.string("filter events by asset properties")}
      details={<CreateAlertRule_Properties
        value=?{value->Value.propertiesRule}
        onChange={handlePropertiesRuleChange}
        options=collectionAggregateAttributes
        isOptionsLoading={isLoadingCollectionAggregateAttributes}
        isCollectionSelected={value->Value.collection->Js.Option.isSome}
        isOpenstore={value
        ->Value.collection
        ->Belt.Option.map(collection =>
          collection->CollectionOption.contractAddressGet->Js.String2.toLowerCase ==
            Config.openstoreContractAddress
        )
        ->Belt.Option.getWithDefault(false)}
      />}
    />
  </>
}
