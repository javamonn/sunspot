exception AlertDestinationRequired
module AlertRule = QueryRenderers_Alerts_GraphQL.Query_AlertRulesByAccountAddress.AlertRule
module Mutation_CreateAlertRule = %graphql(`
  mutation CreateAlertRuleInput($input: CreateAlertRuleInput!) {
    alertRule: createAlertRule(input: $input) {
      ...AlertRule
    }
  }
`)

let getCreateAlertRuleInput = (~value, ~accountAddress) => {
  open Mutation_CreateAlertRule

  let destination = switch AlertModal.Value.destination(value) {
  | Some(AlertRule_Destination.Types.Value.WebPushAlertDestination) =>
    Services.PushNotification.getSubscription()
    |> Js.Promise.then_(subscription => {
      switch subscription {
      | Some(subscription) => Js.Promise.resolve(subscription)
      | None => Services.PushNotification.subscribe()
      }
    })
    |> Js.Promise.then_(pushSubscription => {
      open Externals.ServiceWorkerGlobalScope.PushSubscription
      let s = getSerialized(pushSubscription)

      Js.Promise.resolve({
        webPushAlertDestination: Some({
          endpoint: s->endpoint,
          keys: {
            p256dh: s->keys->p256dh,
            auth: s->keys->auth,
          },
        }),
        discordAlertDestination: None,
        slackAlertDestination: None,
        twitterAlertDestination: None,
      })
    })
  | Some(AlertRule_Destination.Types.Value.DiscordAlertDestination({
      channelId,
      guildId,
      template,
    })) =>
    Js.Promise.resolve({
      discordAlertDestination: Some({
        guildId: guildId,
        channelId: channelId,
        template: template->Belt.Option.map(template => {
          title: template->AlertRule_Destination.Types.DiscordTemplate.title,
          description: template->AlertRule_Destination.Types.DiscordTemplate.description,
          fields: template
          ->AlertRule_Destination.Types.DiscordTemplate.fields
          ->Belt.Option.map(fields =>
            fields->Belt.Array.map(field => {
              name: field->AlertRule_Destination_Types.DiscordTemplate.name,
              value: field->AlertRule_Destination_Types.DiscordTemplate.value,
              inline: field->AlertRule_Destination_Types.DiscordTemplate.inline,
            })
          ),
        }),
      }),
      webPushAlertDestination: None,
      slackAlertDestination: None,
      twitterAlertDestination: None,
    })
  | Some(AlertRule_Destination.Types.Value.SlackAlertDestination({
      channelId,
      incomingWebhookUrl,
    })) =>
    Js.Promise.resolve({
      discordAlertDestination: None,
      webPushAlertDestination: None,
      twitterAlertDestination: None,
      slackAlertDestination: Some({
        channelId: channelId,
        incomingWebhookUrl: incomingWebhookUrl,
      }),
    })
  | Some(AlertRule_Destination.Types.Value.TwitterAlertDestination({userId, accessToken})) =>
    Js.Promise.resolve({
      discordAlertDestination: None,
      webPushAlertDestination: None,
      slackAlertDestination: None,
      twitterAlertDestination: Some({
        userId: userId,
        accessToken: {
          accessToken: accessToken.accessToken,
          refreshToken: accessToken.refreshToken,
          tokenType: accessToken.tokenType,
          scope: accessToken.scope,
          expiresAt: accessToken.expiresAt,
        },
      }),
    })
  | None => Js.Promise.reject(AlertDestinationRequired)
  }
  let priceEventFilter =
    value
    ->AlertModal.Value.priceRule
    ->Belt.Option.flatMap(rule => {
      let direction = switch AlertRule_Price.modifier(rule) {
      | ">" => Some(#ALERT_ABOVE)
      | "<" => Some(#ALERT_BELOW)
      | _ => None
      }
      let value =
        rule
        ->AlertRule_Price.value
        ->Belt.Option.map(value =>
          value->Services.PaymentToken.formatPrice(Services.PaymentToken.ethPaymentToken)
        )

      switch (direction, value) {
      | (Some(direction), Some(value)) =>
        Some({
          alertPriceThresholdEventFilter: Some({
            direction: direction,
            value: value,
            paymentToken: {
              id: Services.PaymentToken.id(Services.PaymentToken.ethPaymentToken),
              decimals: Services.PaymentToken.decimals(Services.PaymentToken.ethPaymentToken),
              name: Services.PaymentToken.name(Services.PaymentToken.ethPaymentToken),
              symbol: Services.PaymentToken.symbol(Services.PaymentToken.ethPaymentToken),
            },
          }),
          alertAttributesEventFilter: None,
        })
      | _ => None
      }
    })
  let propertiesRule =
    value
    ->AlertModal.Value.propertiesRule
    ->Belt.Option.map(rule => {
      let attributeInputs = rule->Belt.Array.map(a =>
        switch a->AlertRule_Properties.Value.value {
        | StringValue({value}) => {
            openSeaAssetStringAttribute: Some({
              value: value,
              traitType: a->AlertRule_Properties.Value.traitType,
            }),
            openSeaAssetNumberAttribute: None,
          }
        | NumberValue({value}) => {
            openSeaAssetNumberAttribute: Some({
              value: value,
              traitType: a->AlertRule_Properties.Value.traitType,
            }),
            openSeaAssetStringAttribute: None,
          }
        }
      )

      {
        alertAttributesEventFilter: Some({
          attributes: attributeInputs,
        }),
        alertPriceThresholdEventFilter: None,
      }
    })

  value
  ->AlertModal.Value.collection
  ->Belt.Option.map(collection =>
    destination |> Js.Promise.then_(destination => {
      {
        id: AlertModal.Value.id(value),
        accountAddress: accountAddress,
        collectionSlug: AlertModal.CollectionOption.slugGet(collection),
        contractAddress: AlertModal.CollectionOption.contractAddressGet(collection),
        eventFilters: [priceEventFilter, propertiesRule]->Belt.Array.keepMap(i => i),
        destination: destination,
        eventType: switch value->AlertModal.Value.eventType {
        | #listing => #LISTING
        | #sale => #SALE
        },
      }
      ->Js.Option.some
      ->Js.Promise.resolve
    })
  )
  ->Belt.Option.getWithDefault(Js.Promise.resolve(None))
}

@react.component
let make = (~isOpen, ~onClose, ~destinationOptions) => {
  let (createAlertRuleMutation, createAlertRuleMutationResult) = Mutation_CreateAlertRule.use()
  let (value, setValue) = React.useState(() => AlertModal.Value.empty())
  let {signIn, authentication}: Contexts.Auth.t = React.useContext(Contexts.Auth.context)

  let handleExited = () => {
    setValue(_ => AlertModal.Value.empty())
  }

  let handleCreate = (~accountAddress) =>
    getCreateAlertRuleInput(~value, ~accountAddress) |> Js.Promise.then_(createAlertRuleInput =>
      createAlertRuleInput
      ->Belt.Option.forEach(createAlertRuleInput => {
        let _ = createAlertRuleMutation(
          ~update=({writeQuery, readQuery}, {data}) => {
            data
            ->Belt.Option.flatMap(({alertRule}) => alertRule)
            ->Belt.Option.forEach(alertRule => {
              let newItems = switch readQuery(
                ~query=module(
                  QueryRenderers_Alerts_GraphQL.Query_AlertRulesByAccountAddress.AlertRulesByAccountAddress
                ),
                QueryRenderers_Alerts_GraphQL.makeVariables(~accountAddress),
              ) {
              | Some(Ok({alertRules: Some({items: Some(items)})})) =>
                Belt.Array.concat([Some(alertRule)], items)
              | _ => [Some(alertRule)]
              }

              let _ = writeQuery(
                ~query=module(
                  QueryRenderers_Alerts_GraphQL.Query_AlertRulesByAccountAddress.AlertRulesByAccountAddress
                ),
                ~data={
                  alertRules: Some({
                    __typename: "ModelAlertRuleConnection",
                    nextToken: None,
                    items: Some(newItems),
                  }),
                },
                QueryRenderers_Alerts_GraphQL.makeVariables(~accountAddress),
              )
            })
          },
          {
            input: createAlertRuleInput,
          },
        ) |> Js.Promise.then_(_result => {
          onClose()
          Js.Promise.resolve()
        })
      })
      ->Js.Promise.resolve
    )

  let handleSignIn = () => {
    signIn()
    |> Js.Promise.then_(authentication => {
      let _ = switch authentication {
      | Contexts.Auth.Authenticated({jwt: {accountAddress}}) =>
        let _ = handleCreate(~accountAddress)
      | _ => ()
      }
      Js.Promise.resolve()
    })
    |> Js.Promise.catch(err => {
      Services.Logger.promiseError("Containers_CreateAlertModal", "handleSignIn err", err)
      Js.Promise.resolve()
    })
  }

  let handleAction = () =>
    switch authentication {
    | Authenticated({jwt: {accountAddress}}) => handleCreate(~accountAddress)
    | _ => handleSignIn()
    }

  let openSeaAssetsUrl = value->AlertModal.Utils.makeOpenSeaAssetsUrlForValue
  let contractEtherscanUrl =
    value.collection->Belt.Option.map(collection =>
      `https://etherscan.io/address/${collection->AlertModal.CollectionOption.contractAddressGet}`
    )

  let handleRenderOverflowActionMenuItems = if (
    Js.Option.isNone(openSeaAssetsUrl) && Js.Option.isNone(contractEtherscanUrl)
  ) {
    None
  } else {
    Some(
      (~onClick) => <>
        {Js.Option.isSome(openSeaAssetsUrl)
          ? <MaterialUi.MenuItem
              onClick={_ => {
                onClick()
                openSeaAssetsUrl->Belt.Option.forEach(Externals.Webapi.Window.open_)
              }}>
              <MaterialUi.ListItemIcon>
                <img className={Cn.make(["w-6", "h-6", "opacity-50"])} src="/opensea-icon.svg" />
              </MaterialUi.ListItemIcon>
              <MaterialUi.ListItemText> {React.string("view opensea")} </MaterialUi.ListItemText>
            </MaterialUi.MenuItem>
          : React.null}
        {Js.Option.isSome(contractEtherscanUrl)
          ? <MaterialUi.MenuItem
              onClick={_ => {
                onClick()
                contractEtherscanUrl->Belt.Option.forEach(Externals.Webapi.Window.open_)
              }}>
              <MaterialUi.ListItemIcon>
                <img className={Cn.make(["w-6", "h-6", "opacity-50"])} src="/etherscan-icon.svg" />
              </MaterialUi.ListItemIcon>
              <MaterialUi.ListItemText>
                {React.string("view contract etherscan")}
              </MaterialUi.ListItemText>
            </MaterialUi.MenuItem>
          : React.null}
      </>,
    )
  }

  <AlertModal
    isOpen
    onClose
    onExited={handleExited}
    value={value}
    destinationOptions={destinationOptions}
    onChange={setterFn => setValue(value => value->setterFn)}
    onAction={handleAction}
    actionLabel="create"
    title="create alert"
    renderOverflowActionMenuItems=?{handleRenderOverflowActionMenuItems}
  />
}
