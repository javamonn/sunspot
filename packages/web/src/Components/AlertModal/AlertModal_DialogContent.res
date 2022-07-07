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
  ) = Query_OpenSeaCollectionAggregateAttributes.useLazy(
    ~fetchPolicy=ApolloClient__React_Hooks_UseLazyQuery.WatchQueryFetchPolicy.NoCache,
    (),
  )
  let (
    isCreateTwitterIntegrationDialogOpen,
    setIsCreateTwitterIntegrationDialogOpen,
  ) = React.useState(_ => false)

  let _ = React.useEffect1(() => {
    value
    ->AlertModal_Value.collection
    ->Belt.Option.forEach(collection => {
      let _ = executeCollectionAggregateAttributesQuery({
        slug: collection->CollectionOption.slugGet,
      })
    })
    None
  }, [value->AlertModal_Value.collection])

  let handleDestinationChange = destination =>
    onChange(value => {
      ...value,
      AlertModal_Value.destination: Some(destination),
    })
  let handleEventTypeChange = eventType =>
    onChange(value => {
      ...value,
      AlertModal_Value.eventType: eventType,
    })
  let handleCollectionChange = collection => {
    onChange(value => {
      ...value,
      AlertModal_Value.collection: collection,
    })
  }

  let handleConnectDiscord = () => Externals.Webapi.Window.open_(Config.discordOAuthUrl)
  let handleConnectSlack = () => Externals.Webapi.Window.open_(Config.slackOAuthUrl)
  // let handleConnectTwitter = () => Externals.Webapi.Window.open_(Config.twitterOAuthUrl)
  let handleConnectTwitter = () => setIsCreateTwitterIntegrationDialogOpen(_ => true)
  let handleOnCloseCreateTwitterIntegrationDialog = (
    twitterIntegration: option<CreateTwitterIntegrationDialog.TwitterIntegration.t>,
  ) => {
    let _ = switch twitterIntegration {
    | Some({user: Some(user), userAuthenticationToken: Some(userAuthenticationToken)}) =>
      onChange(value => {
        ...value,
        destination: Some(
          AlertRule_Destination.Types.Value.TwitterAlertDestination({
            userId: user.id,
            userAuthenticationToken: Some({
              apiKey: userAuthenticationToken.apiKey,
              apiSecret: userAuthenticationToken.apiSecret,
              userAccessToken: userAuthenticationToken.userAccessToken,
              userAccessSecret: userAuthenticationToken.userAccessSecret,
            }),
            accessToken: None,
            template: None,
          }),
        ),
      })
    | _ => ()
    }
    setIsCreateTwitterIntegrationDialogOpen(_ => false)
  }
  let (isLoadingCollectionAggregateAttributes, collectionAggregateAttributes) = React.useMemo1(() =>
    switch collectionAggregateAttributesResult {
    | Executed({data: Some({collection: Some({attributes})})}) =>
      let collectionAggregateAttributes = attributes->Belt.Array.map(aggreggateAttribute => {
        let values = aggreggateAttribute.values->Belt.Array.keepMap(value =>
          switch value {
          | #OpenSeaCollectionAttributeNumberValue({numberValue}) =>
            Some(AlertRule_Properties.NumberValue({value: numberValue}))
          | #OpenSeaCollectionAttributeStringValue({stringValue}) =>
            Some(AlertRule_Properties.StringValue({value: stringValue}))
          | #FutureAddedValue(_) => None
          }
        )

        let isNumberTrait = values->Js.Array2.every(value =>
          switch value {
          | NumberValue(_) => true
          | _ => false
          }
        )

        {
          AlertRule_Properties.Option.traitType: aggreggateAttribute.traitType,
          count: aggreggateAttribute.count,
          values: isNumberTrait
            ? Belt.Array.concat([AlertRule_Properties.StringValue({value: "any value"})], values)
            : values,
        }
      })
      (false, collectionAggregateAttributes)
    | Executed({loading: true}) => (true, [])
    | _ => (false, [])
    }
  , [collectionAggregateAttributesResult])

  let handleToggleQuickbuyEnabled = () =>
    onChange(value => {
      ...value,
      quickbuy: !value.quickbuy,
    })

  <>
    {validationError
    ->Belt.Option.map(error =>
      <MaterialUi_Lab.Alert
        severity=#Error classes={MaterialUi_Lab.Alert.Classes.make(~root=Cn.make(["mb-6"]), ())}>
        {React.string(error)}
      </MaterialUi_Lab.Alert>
    )
    ->Belt.Option.getWithDefault(React.null)}
    <AlertRule_CollectionAutocomplete onChange={handleCollectionChange} value={value.collection} />
    <AlertRule_EventType
      value={value->AlertModal_Value.eventType} onChange={handleEventTypeChange}
    />
    <AlertRule_Destination
      value={value->AlertModal_Value.destination}
      onChange={handleDestinationChange}
      destinationOptions={destinationOptions}
      disabled=?{destinationDisabled}
      onConnectDiscord={handleConnectDiscord}
      onConnectSlack={handleConnectSlack}
      onConnectTwitter={handleConnectTwitter}
    />
    {switch value.eventType {
    | #LISTING =>
      <AlertRule_Quickbuy
        value={value->AlertModal_Value.quickbuy} onChange={handleToggleQuickbuyEnabled}
      />
    | _ => React.null
    }}
    <AlertRule_Accordion
      className={Cn.make(["mt-8"])}
      summaryIcon={<Externals_MaterialUi_Icons.TextFields
        style={ReactDOM.Style.make(~opacity="0.42", ())}
      />}
      summaryTitle={React.string("template")}
      summaryDescription={React.string("customize alert text and formatting")}
      renderDetails={(~expanded) =>
        <AlertRule_Destination_TemplateAccordion
          onChange={handleDestinationChange}
          value=?{value->AlertModal_Value.destination}
          eventType={value->AlertModal_Value.eventType}
          accordionExpanded={expanded}
        />}
    />
    <MaterialUi.Divider
      classes={MaterialUi.Divider.Classes.make(~root=Cn.make(["mb-8", "mt-8"]), ())}
    />
    {switch value.eventType {
    | #LISTING
    | #SALE =>
      <AlertModal_AlertRules_Event
        value={value}
        onChange={onChange}
        collectionAggregateAttributes
        isLoadingCollectionAggregateAttributes
      />
    | #SALE_VOLUME_CHANGE =>
      <AlertModal_AlertRules_SaleVolumeChange
        value={AlertModal_Value.saleVolumeChangeRule(value)}
        onChange={newSaleVolumeChangeRule =>
          onChange(value => {
            ...value,
            AlertModal_Value.saleVolumeChangeRule: Some(newSaleVolumeChangeRule),
          })}
      />
    | #FLOOR_PRICE_CHANGE =>
      <AlertModal_AlertRules_FloorPriceChange value={value} onChange={onChange} />
    }}
    <CreateTwitterIntegrationDialog
      isOpen={isCreateTwitterIntegrationDialogOpen}
      onClose={handleOnCloseCreateTwitterIntegrationDialog}
    />
  </>
}
