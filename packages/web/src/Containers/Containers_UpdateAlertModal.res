module Mutation_UpdateAlertRule = %graphql(`
  mutation UpdateAlertRuleInput($input: UpdateAlertRuleInput!) {
    alertRule: updateAlertRule(input: $input) {
      id 
      contractAddress
      accountAddress
      collectionSlug
      destination {
        ... on WebPushAlertDestination {
          endpoint
        }
        ...on DiscordAlertDestination {
          endpoint
        }
      }
      eventFilters {
        ... on AlertPriceThresholdEventFilter {
          value
          direction
          paymentToken {
            id
          }
        }
        ... on AlertAttributesEventFilter {
          attributes {
            ... on OpenSeaAssetNumberAttribute {
              traitType
              numberValue: value
            }
            ... on OpenSeaAssetStringAttribute {
              traitType
              stringValue: value
            }
          }
        }
      }
    }
  }
`)

@react.component
let make = (~isOpen, ~value=?, ~onClose, ~accountAddress) => {
  let (updateAlertRuleMutation, updateAlertRuleMutationResult) = Mutation_UpdateAlertRule.use()
  let (newValue, setNewValue) = React.useState(_ => value)
  let _ = React.useEffect1(_ => {
    setNewValue(_ => value)
    None
  }, [value])

  let handleUpdate = () => {
    let _ = switch (
      newValue,
      newValue->Belt.Option.flatMap(AlertModal.Value.collection),
      value,
      value->Belt.Option.flatMap(AlertModal.Value.collection),
      accountAddress,
    ) {
    | (
        Some(newValue),
        Some(collection),
        Some(existingValue),
        Some(existingCollection),
        Some(accountAddress),
      ) =>
      Services.PushNotification.getSubscription()
      |> Js.Promise.then_(subscription => {
        switch subscription {
        | Some(subscription) => Js.Promise.resolve(subscription)
        | None => Services.PushNotification.subscribe()
        }
      })
      |> Js.Promise.then_(pushSubscription => {
        open Mutation_UpdateAlertRule

        let eventFilters =
          newValue
          ->AlertModal.Value.rules
          ->Belt.Map.String.valuesToArray
          ->Belt.Array.keepMap(rule => {
            let direction = switch CreateAlertRule.Price.modifier(rule) {
            | ">" => Some(#ALERT_ABOVE)
            | "<" => Some(#ALERT_BELOW)
            | _ => None
            }
            let value =
              rule
              ->CreateAlertRule.Price.value
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
          alertRule: {
            id: AlertModal.Value.id(newValue),
            accountAddress: accountAddress,
            collectionSlug: AlertModal.CollectionOption.slugGet(collection),
            contractAddress: AlertModal.CollectionOption.contractAddressGet(collection),
            eventFilters: eventFilters,
            destination: destination,
          },
          key: {
            contractAddress: AlertModal.CollectionOption.contractAddressGet(existingCollection),
            id: AlertModal.Value.id(existingValue),
          },
        }

        updateAlertRuleMutation({
          input: input,
        }) |> Js.Promise.then_(_result => {
          onClose()
          Js.Promise.resolve()
        })
      })
    | _ => Js.Promise.resolve()
    }
  }

  let isUpdating = switch updateAlertRuleMutationResult {
  | {loading: true} => true
  | _ => false
  }

  <AlertModal
    isOpen
    onClose
    value={newValue->Belt.Option.getWithDefault(AlertModal.Value.empty())}
    onChange={newValue => setNewValue(_ => Some(newValue))}
    isActioning={isUpdating}
    onAction={handleUpdate}
    actionLabel="update"
    title="update alert"
  />
}
