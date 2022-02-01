open QueryRenderers_Alerts_GraphQL

type updateAlertModalState =
  | UpdateAlertModalOpen(AlertModal.Value.t)
  | UpdateAlertModalClosing(AlertModal.Value.t)
  | UpdateAlertModalClosed

@react.component
let make = () => {
  let {eth}: Contexts.Eth.t = React.useContext(Contexts.Eth.context)
  let {signIn, authentication}: Contexts.Auth.t = React.useContext(Contexts.Auth.context)
  let alertRulesQuery = Query_AlertRulesByAccountAddress.AlertRulesByAccountAddress.use(
    ~skip=switch authentication {
    | Authenticated(_) => false
    | _ => true
    },
    switch authentication {
    | Authenticated({jwt: {accountAddress}}) => makeVariables(~accountAddress)
    | _ => makeVariables(~accountAddress="")
    },
  )
  let oauthIntegrationsQuery = Query_OAuthIntegrationsByAccountAddress.use(
    ~skip=switch authentication {
    | Authenticated(_) => false
    | _ => true
    },
    switch authentication {
    | Authenticated({jwt: {accountAddress}}) => {
        discordIntegrationsInput: {accountAddress: accountAddress},
        slackIntegrationsInput: {accountAddress: accountAddress},
        twitterIntegrationsInput: {accountAddress: accountAddress},
      }
    | _ => {
        discordIntegrationsInput: {accountAddress: ""},
        slackIntegrationsInput: {accountAddress: ""},
        twitterIntegrationsInput: {accountAddress: ""},
      }
    },
  )
  let (createAlertModalIsOpen, setCreateAlertModalIsOpen) = React.useState(_ => false)
  let (updateAlertModal, setUpdateAlertModal) = React.useState(_ => UpdateAlertModalClosed)

  let alertRuleItems = switch alertRulesQuery {
  | {data: Some({alertRules: Some({items: Some(items)})})} =>
    items->Belt.Array.keepMap(item => item)
  | _ => []
  }
  let tableRows =
    alertRuleItems
    ->Externals.Lodash.sortBy(item =>
      -.(
        item.updatedAt
        ->Js.Json.decodeString
        ->Belt.Option.map(s => s->Js.Date.fromString->Js.Date.valueOf)
        ->Belt.Option.getWithDefault(0.0)
      )
    )
    ->Belt.Array.map(item => {
      let rules =
        item.eventFilters
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
        ->Belt.Array.concatMany
      let eventType = switch item.eventType {
      | #LISTING => "listing"
      | #SALE => "sale"
      | #FutureAddedValue(v) => Js.String2.toLowerCase(v)
      }
      let externalUrl = Services.OpenSea.makeAssetsUrl(
        ~collectionSlug=item.collection.slug,
        ~eventType=item.eventType,
        ~priceFilter=?item.eventFilters
        ->Belt.Array.getBy(eventFilter =>
          switch eventFilter {
          | #AlertPriceThresholdEventFilter(_) => true
          | _ => false
          }
        )
        ->Belt.Option.flatMap(eventFilter =>
          switch eventFilter {
          | #AlertPriceThresholdEventFilter(eventFilter) =>
            Services.PaymentToken.parsePrice(
              eventFilter.value,
              eventFilter.paymentToken.decimals,
            )->Belt.Option.flatMap(price =>
              switch eventFilter.direction {
              | #ALERT_ABOVE => Some(Services.OpenSea.Min(price))
              | #ALERT_BELOW => Some(Services.OpenSea.Max(price))
              | #FutureAddedValue(_) => None
              }
            )
          | _ => None
          }
        ),
        ~traitsFilter=item.eventFilters
        ->Belt.Array.map(eventFilter =>
          switch eventFilter {
          | #AlertAttributesEventFilter({attributes}) =>
            attributes->Belt.Array.keepMap(attribute =>
              switch attribute {
              | #OpenSeaAssetNumberAttribute({traitType, numberValue}) =>
                Some(Services.OpenSea.NumberTrait({name: traitType, value: numberValue}))
              | #OpenSeaAssetStringAttribute({traitType, stringValue}) =>
                Some(Services.OpenSea.StringTrait({name: traitType, value: stringValue}))
              | #FutureAddedValue(_) => None
              }
            )
          | _ => []
          }
        )
        ->Belt.Array.concatMany,
        (),
      )

      {
        AlertsTable.id: item.id,
        collectionName: item.collection.name,
        collectionSlug: item.collection.slug,
        collectionImageUrl: item.collection.imageUrl,
        eventType: eventType,
        externalUrl: externalUrl,
        rules: rules,
      }
    })

  let integrationOptions = {
    let discordIntegrationOptions = switch oauthIntegrationsQuery {
    | {data: Some({discordIntegrations: Some({items: Some(discordItems)})})} =>
      discordItems
      ->Belt.Array.keepMap(item =>
        item->Belt.Option.map(item =>
          item.channels->Belt.Array.map(channel => {
            AlertRule_Destination.Types.Option.DiscordAlertDestinationOption({
              channelId: channel.id,
              channelName: channel.name,
              guildId: item.guildId,
              guildName: item.name,
              guildIconUrl: item.iconUrl,
            })
          })
        )
      )
      ->Belt.Array.concatMany
    | _ => []
    }
    let slackIntegrationOptions = switch oauthIntegrationsQuery {
    | {data: Some({slackIntegrations: Some({items: Some(slackItems)})})} =>
      slackItems->Belt.Array.keepMap(item =>
        item->Belt.Option.map(
          item => AlertRule_Destination.Types.Option.SlackAlertDestinationOption({
            teamName: item.teamName,
            channelName: item.channelName,
            channelId: item.channelId,
            incomingWebhookUrl: item.incomingWebhookUrl,
          }),
        )
      )
    | _ => []
    }
    let twitterIntegrationOptions = switch oauthIntegrationsQuery {
    | {data: Some({twitterIntegrations: Some({items: Some(twitterItems)})})} =>
      twitterItems->Belt.Array.keepMap(item =>
        item->Belt.Option.map(
          item => AlertRule_Destination.Types.Option.TwitterAlertDestinationOption({
            userId: item.user.id,
            username: item.user.username,
            profileImageUrl: item.user.profileImageUrl,
            accessToken: {
              accessToken: item.accessToken.accessToken,
              refreshToken: item.accessToken.refreshToken,
              scope: item.accessToken.scope,
              expiresAt: item.accessToken.expiresAt,
              tokenType: item.accessToken.tokenType,
            },
          }),
        )
      )
    | _ => []
    }
    Belt.Array.concatMany([
      discordIntegrationOptions,
      slackIntegrationOptions,
      twitterIntegrationOptions,
    ])
  }

  let handleConnectWalletClicked = _ => {
    let _ = signIn()
  }
  let handleRowClick = row =>
    alertRuleItems
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
            AlertRule_Price.makeRule(
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
                  AlertRule_Properties.Value.value: AlertRule_Properties.NumberValue({
                    value: numberValue,
                  }),
                  traitType: traitType,
                })
              | #OpenSeaAssetStringAttribute({traitType, stringValue}) =>
                Some({
                  AlertRule_Properties.Value.value: AlertRule_Properties.StringValue({
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

      let destination = switch item.destination {
      | #WebPushAlertDestination(_) =>
        Some(AlertRule_Destination.Types.Value.WebPushAlertDestination)
      | #DiscordAlertDestination({guildId, channelId, template}) =>
        Some(
          AlertRule_Destination.Types.Value.DiscordAlertDestination({
            guildId: guildId,
            channelId: channelId,
            template: template->Belt.Option.map(template => {
              AlertRule_Destination.Types.DiscordTemplate.title: template.title,
              description: template.description,
              fields: template.fields->Belt.Option.map(fields =>
                fields->Belt.Array.map(field => {
                  AlertRule_Destination.Types.DiscordTemplate.name: field.name,
                  value: field.value,
                  inline: field.inline,
                })
              ),
            }),
          }),
        )
      | #SlackAlertDestination({channelId, incomingWebhookUrl}) =>
        Some(
          AlertRule_Destination.Types.Value.SlackAlertDestination({
            channelId: channelId,
            incomingWebhookUrl: incomingWebhookUrl,
          }),
        )
      | #TwitterAlertDestination({userId, accessToken}) =>
        Some(
          AlertRule_Destination.Types.Value.TwitterAlertDestination({
            userId: userId,
            accessToken: {
              accessToken: accessToken.accessToken,
              refreshToken: accessToken.refreshToken,
              tokenType: accessToken.tokenType,
              scope: accessToken.scope,
              expiresAt: accessToken.expiresAt,
            },
          }),
        )
      | #FutureAddedValue(_) => None
      }
      let eventType = switch item.eventType {
      | #LISTING => #listing
      | #SALE => #sale
      | _ => #listing
      }

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
        ~destination,
        ~id=item.id,
        ~eventType,
      )

      setUpdateAlertModal(_ => UpdateAlertModalOpen(alertModalValue))
    })

  let isLoading = switch (eth, alertRulesQuery, authentication) {
  | (_, {loading: true}, _)
  | (_, {called: false}, _)
  | (Unknown, _, _)
  | (_, _, RefreshRequired(_)) => true
  | _ if !Config.isBrowser() => true
  | _ => false
  }

  <>
    <AlertsHeader
      eth
      authentication
      onConnectWalletClicked={handleConnectWalletClicked}
      onWalletButtonClicked={handleConnectWalletClicked}
      onCreateAlertClicked={_ => setCreateAlertModalIsOpen(_ => true)}
    />
    <AlertsTable isLoading={isLoading} rows={tableRows} onRowClick={handleRowClick} />
    <Containers.CreateAlertModal
      isOpen={createAlertModalIsOpen}
      onClose={_ => setCreateAlertModalIsOpen(_ => false)}
      destinationOptions={integrationOptions}
    />
    {switch authentication {
    | Authenticated({jwt: {accountAddress}}) => <>
        <Containers.UpdateAlertModal
          isOpen={switch updateAlertModal {
          | UpdateAlertModalOpen(_) => true
          | _ => false
          }}
          value=?{switch updateAlertModal {
          | UpdateAlertModalOpen(v) | UpdateAlertModalClosing(v) => Some(v)
          | _ => None
          }}
          onExited={_ => setUpdateAlertModal(_ => UpdateAlertModalClosed)}
          onClose={_ =>
            setUpdateAlertModal(alertModalValue =>
              switch alertModalValue {
              | UpdateAlertModalOpen(v) => UpdateAlertModalClosing(v)
              | _ => alertModalValue
              }
            )}
          destinationOptions={integrationOptions}
          accountAddress={accountAddress}
        />
      </>
    | _ => React.null
    }}
  </>
}
