open QueryRenderers_Alerts_GraphQL

type updateAlertModalState =
  | UpdateAlertModalOpen(AlertModal.Value.t)
  | UpdateAlertModalClosing(AlertModal.Value.t)
  | UpdateAlertModalClosed

@react.component
let make = () => {
  let {signIn, authentication}: Contexts.Auth.t = React.useContext(Contexts.Auth.context)
  let alertRulesQuery = Query_AlertRulesAndOAuthIntegrationsByAccountAddress.AlertRulesAndOAuthIntegrationsByAccountAddress.use(
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

  let alertRuleItems = switch alertRulesQuery {
  | {data: Some({alertRules: Some({items: Some(items)})})} =>
    items->Belt.Array.keepMap(item => item)
  | _ => []
  }
  let discordIntegrationOptions = switch alertRulesQuery {
  | {data: Some({discordIntegrations: Some({items: Some(discordItems)})})} =>
    discordItems
    ->Belt.Array.keepMap(item =>
      item->Belt.Option.map(item =>
        item.channels->Belt.Array.map(channel => {
          AlertRule_Destination.Types.Option.DiscordAlertDestinationOption({
            clientId: item.clientId->Belt.Option.getWithDefault(Config.discord1ClientId),
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
  let slackIntegrationOptions = switch alertRulesQuery {
  | {data: Some({slackIntegrations: Some({items: Some(slackItems)})})} =>
    slackItems->Belt.Array.keepMap(item =>
      item->Belt.Option.map(item => AlertRule_Destination.Types.Option.SlackAlertDestinationOption({
        teamName: item.teamName,
        channelName: item.channelName,
        channelId: item.channelId,
        incomingWebhookUrl: item.incomingWebhookUrl,
      }))
    )
  | _ => []
  }
  let twitterIntegrationOptions = switch alertRulesQuery {
  | {data: Some({twitterIntegrations: Some({items: Some(twitterItems)})})} =>
    twitterItems->Belt.Array.keepMap(item =>
      item->Belt.Option.flatMap(item =>
        item.user->Belt.Option.map(
          user => AlertRule_Destination.Types.Option.TwitterAlertDestinationOption({
            userId: user.id,
            username: user.username,
            profileImageUrl: user.profileImageUrl,
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
    )
  | _ => []
  }

  let integrationOptions = Belt.Array.concatMany([
    discordIntegrationOptions,
    slackIntegrationOptions,
    twitterIntegrationOptions,
  ])

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

      let disabledInfo = switch (item.disabled, item.disabledReason) {
      | (Some(true), Some(#DESTINATION_RATE_LIMIT_EXCEEDED)) =>
        Some("alert has been ratelimited and will automatically re-enable after a period of time.")
      | (Some(true), Some(#DESTINATION_MISSING_ACCESS)) =>
        Some(
          "unable to connect to the destination. try reconnecting or adjusting permissions and re-enable.",
        )
      | (Some(true), Some(#SNOOZED)) => Some("alert has been disabled.")
      | _ => None
      }

      let destination = switch item.destination {
      | #WebPushAlertDestination(_) =>
        Some({
          AlertsTable_Types.primary: "push notification",
          secondary: Some("this device"),
          iconUrl: None,
        })
      | #DiscordAlertDestination({guildId, channelId}) =>
        discordIntegrationOptions
        ->Belt.Array.getBy(opt =>
          switch opt {
          | AlertRule_Destination.Types.Option.DiscordAlertDestinationOption({
              guildId: optGuildId,
              channelId: optChannelId,
            }) if optGuildId === guildId && optChannelId === channelId => true
          | _ => false
          }
        )
        ->Belt.Option.flatMap(opt =>
          switch opt {
          | AlertRule_Destination.Types.Option.DiscordAlertDestinationOption(o) => Some(o)
          | _ => None
          }
        )
        ->Belt.Option.map(({
          AlertRule_Destination.Types.Option.channelName: channelName,
          guildName,
          guildIconUrl,
        }) => {
          AlertsTable_Types.primary: `#${channelName} (${guildName})`,
          secondary: Some("discord"),
          iconUrl: guildIconUrl->Belt.Option.getWithDefault("/discord-icon.svg")->Js.Option.some,
        })
      | #TwitterAlertDestination({userId}) =>
        twitterIntegrationOptions
        ->Belt.Array.getBy(opt =>
          switch opt {
          | AlertRule_Destination.Types.Option.TwitterAlertDestinationOption({userId: optUserId})
            if userId === optUserId => true
          | _ => false
          }
        )
        ->Belt.Option.flatMap(opt =>
          switch opt {
          | AlertRule_Destination.Types.Option.TwitterAlertDestinationOption(o) => Some(o)
          | _ => None
          }
        )
        ->Belt.Option.map(({
          AlertRule_Destination.Types.Option.username: username,
          profileImageUrl,
        }) => {
          AlertsTable_Types.primary: `@${username}`,
          secondary: Some("twitter"),
          iconUrl: Some(profileImageUrl),
        })
      | #SlackAlertDestination({channelId}) =>
        slackIntegrationOptions
        ->Belt.Array.getBy(opt =>
          switch opt {
          | AlertRule_Destination.Types.Option.SlackAlertDestinationOption({
              channelId: optChannelId,
            }) if optChannelId === channelId => true
          | _ => false
          }
        )
        ->Belt.Option.flatMap(opt =>
          switch opt {
          | AlertRule_Destination.Types.Option.SlackAlertDestinationOption(o) => Some(o)
          | _ => None
          }
        )
        ->Belt.Option.map(({
          AlertRule_Destination.Types.Option.teamName: teamName,
          channelName,
        }) => {
          AlertsTable_Types.primary: `${channelName} (${teamName})`,
          secondary: Some("slack"),
          iconUrl: Some("/slack-icon.svg"),
        })
      | _ => None
      }

      {
        AlertsTable.id: item.id,
        collectionName: item.collection.name,
        collectionSlug: item.collection.slug,
        collectionImageUrl: item.collection.imageUrl,
        eventType: eventType,
        externalUrl: externalUrl,
        rules: rules,
        disabledInfo: disabledInfo,
        destination: destination,
      }
    })

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
      | #WebPushAlertDestination({template}) =>
        Some(
          AlertRule_Destination.Types.Value.WebPushAlertDestination({
            template: template->Belt.Option.map(template => {
              AlertRule_Destination.Types.WebPushTemplate.title: template.title,
              body: template.body,
              isThumbnailImageSize: template.isThumbnailImageSize,
            }),
          }),
        )
      | #DiscordAlertDestination({guildId, channelId, template, clientId}) =>
        Some(
          AlertRule_Destination.Types.Value.DiscordAlertDestination({
            clientId: clientId->Belt.Option.getWithDefault(Config.discord1ClientId),
            guildId: guildId,
            channelId: channelId,
            template: template->Belt.Option.map(template => {
              AlertRule_Destination.Types.DiscordTemplate.title: template.title,
              description: template.description,
              displayProperties: template.displayProperties->Belt.Option.getWithDefault(false),
              isThumbnailImageSize: template.isThumbnailImageSize->Belt.Option.getWithDefault(
                false,
              ),
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
      | #TwitterAlertDestination({userId, accessToken, template}) =>
        Some(
          AlertRule_Destination.Types.Value.TwitterAlertDestination({
            userId: userId,
            template: template->Belt.Option.map(template => {
              AlertRule_Destination.Types.TwitterTemplate.text: template.text,
            }),
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

      let disabled = switch (item.disabled, item.disabledReason) {
      | (Some(true), Some(#DESTINATION_MISSING_ACCESS)) =>
        Some(AlertModal.Value.DestinationMissingAccess)
      | (Some(true), Some(#DESTINATION_RATE_LIMIT_EXCEEDED)) =>
        Some(AlertModal.Value.DestinationRateLimitExceeded(item.disabledExpiresAt))
      | (Some(true), Some(#SNOOZED)) => Some(AlertModal.Value.Snoozed)
      | _ => None
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
        ~disabled,
      )

      setUpdateAlertModal(_ => UpdateAlertModalOpen(alertModalValue))
    })

  let isLoading = switch (alertRulesQuery, authentication) {
  | ({loading: true}, _)
  | ({called: false}, _)
  | (_, InProgress_JWTRefresh(_)) => true
  | _ if !Config.isBrowser() => true
  | _ => false
  }

  <>
    <AlertsHeader
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
