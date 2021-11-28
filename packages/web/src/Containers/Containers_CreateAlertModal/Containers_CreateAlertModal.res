module AlertRule = QueryRenderers_Alerts_GraphQL.Query_AlertRulesByAccountAddress.AlertRule
module Mutation_CreateAlertRule = %graphql(`
  mutation CreateAlertRuleInput($input: AlertRuleInput!) {
    alertRule: createAlertRule(input: $input) {
      ...AlertRule
    }
  }
`)

let getCreateAlertRuleInput = (~value, ~accountAddress) => {
  open Mutation_CreateAlertRule

  let destination = switch AlertModal.Value.destination(value) {
  | AlertRule_Destination.Value.WebPushAlertDestination =>
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
      })
    })
  | AlertRule_Destination.Value.DiscordAlertDestination({channelId, guildId}) =>
    Js.Promise.resolve({
      discordAlertDestination: Some({
        guildId: guildId,
        channelId: channelId,
      }),
      webPushAlertDestination: None,
    })
  }
  let priceEventFilter =
    value
    ->AlertModal.Value.priceRule
    ->Belt.Option.flatMap(rule => {
      let direction = switch CreateAlertRule_Price.modifier(rule) {
      | ">" => Some(#ALERT_ABOVE)
      | "<" => Some(#ALERT_BELOW)
      | _ => None
      }
      let value =
        rule
        ->CreateAlertRule_Price.value
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
        switch a->CreateAlertRule_Properties.Value.value {
        | StringValue({value}) => {
            openSeaAssetStringAttribute: Some({
              value: value,
              traitType: a->CreateAlertRule_Properties.Value.traitType,
            }),
            openSeaAssetNumberAttribute: None,
          }
        | NumberValue({value}) => {
            openSeaAssetNumberAttribute: Some({
              value: value,
              traitType: a->CreateAlertRule_Properties.Value.traitType,
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
        eventType: Some(#LISTING),
      }
      ->Js.Option.some
      ->Js.Promise.resolve
    })
  )
  ->Belt.Option.getWithDefault(Js.Promise.resolve(None))
}

@react.component
let make = (~isOpen, ~onClose, ~accountAddress, ~discordDestinationOptions) => {
  let (createAlertRuleMutation, createAlertRuleMutationResult) = Mutation_CreateAlertRule.use()
  let (value, setValue) = React.useState(() => AlertModal.Value.empty())

  let handleExited = () => {
    setValue(_ => AlertModal.Value.empty())
  }

  let handleCreate = () => {
    let _ = getCreateAlertRuleInput(
      ~value,
      ~accountAddress,
    ) |> Js.Promise.then_(createAlertRuleInput =>
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
  }

  let isCreating = switch createAlertRuleMutationResult {
  | {loading: true} => true
  | _ => false
  }

  <AlertModal
    isOpen
    onClose
    onExited={handleExited}
    value={value}
    discordDestinationOptions={discordDestinationOptions}
    onChange={newValue => setValue(_ => newValue)}
    isActioning={isCreating}
    onAction={handleCreate}
    actionLabel="create"
    title="create alert"
  />
}
