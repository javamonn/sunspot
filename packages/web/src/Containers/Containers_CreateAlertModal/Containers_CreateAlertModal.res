module AlertRule = QueryRenderers_Alerts_GraphQL.Query_AlertRulesByAccountAddress.AlertRule
module Mutation_CreateAlertRule = %graphql(`
  mutation CreateAlertRuleInput($input: CreateAlertRuleInput!) {
    alertRule: createAlertRule(input: $input) {
      ...AlertRule
    }
  }
`)

@react.component
let make = (~isOpen, ~onClose, ~accountAddress=?) => {
  let (createAlertRuleMutation, createAlertRuleMutationResult) = Mutation_CreateAlertRule.use()
  let (value, setValue) = React.useState(() => AlertModal.Value.empty())

  let handleExited = () => {
    setValue(_ => AlertModal.Value.empty())
  }

  let handleCreate = () => {
    let _ = switch (value->AlertModal.Value.collection, accountAddress) {
    | (Some(collection), Some(accountAddress)) =>
      Services.PushNotification.getSubscription()
      |> Js.Promise.then_(subscription => {
        switch subscription {
        | Some(subscription) => Js.Promise.resolve(subscription)
        | None => Services.PushNotification.subscribe()
        }
      })
      |> Js.Promise.then_(pushSubscription => {
        open Mutation_CreateAlertRule

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

        let destination = {
          open Externals.ServiceWorkerGlobalScope.PushSubscription
          let s = getSerialized(pushSubscription)

          {
            webPushAlertDestination: Some({
              endpoint: s->endpoint,
              keys: {
                p256dh: s->keys->p256dh,
                auth: s->keys->auth,
              },
            }),
            discordAlertDestination: None,
          }
        }
        let input = {
          id: AlertModal.Value.id(value),
          accountAddress: accountAddress,
          collectionSlug: AlertModal.CollectionOption.slugGet(collection),
          contractAddress: AlertModal.CollectionOption.contractAddressGet(collection),
          eventFilters: [priceEventFilter, propertiesRule]->Belt.Array.keepMap(i => i),
          destination: destination,
        }

        createAlertRuleMutation(
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
            input: input,
          },
        ) |> Js.Promise.then_(_result => {
          onClose()
          Js.Promise.resolve()
        })
      })
    | _ => Js.Promise.resolve()
    }
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
    onChange={newValue => setValue(_ => newValue)}
    isActioning={isCreating}
    onAction={handleCreate}
    actionLabel="create"
    title="create alert"
  />
}
