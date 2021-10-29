module Mutation_CreateAlertRule = %graphql(`
  mutation CreateAlertRuleInput($input: CreateAlertRuleInput!) {
    alertRule: createAlertRule(input: $input) {
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
let make = (~isOpen, ~onClose, ~accountAddress=?) => {
  let (validationError, setValidationError) = React.useState(_ => None)
  let (createAlertRuleMutation, createAlertRuleMutationResult) = Mutation_CreateAlertRule.use()

  let (value, setValue) = React.useState(() => {
    CreateAlertModal.collection: None,
    rules: Belt.Map.String.empty,
  })

  let handleExited = () => {
    setValue(_ => {rules: Belt.Map.String.empty, collection: None})
    setValidationError(_ => None)
  }
  let handleValidate = () => {
    let collectionValid = Js.Option.isSome(value.collection)
    let rulesValid =
      value.rules
      ->Belt.Map.String.valuesToArray
      ->Belt.Array.every(rule =>
        rule
        ->CreateAlertRule.Price.value
        ->Belt.Option.flatMap(Belt.Float.fromString)
        ->Belt.Option.map(value => value >= 0.0)
        ->Belt.Option.getWithDefault(false)
      )

    let result = if !collectionValid {
      Some("collection is required.")
    } else if !rulesValid {
      Some("price rule value must be a positive number.")
    } else {
      None
    }

    setValidationError(_ => result)
    result
  }

  let handleCreate = () => {
    let _ = switch (handleValidate(), value.collection, accountAddress) {
    | (None, Some(collection), Some(accountAddress)) =>
      let subscriptionP =
        Services.PushNotification.getSubscription() |> Js.Promise.then_(subscription => {
          switch subscription {
          | Some(subscription) => Js.Promise.resolve(subscription)
          | None => Services.PushNotification.subscribe()
          }
        })

      subscriptionP |> Js.Promise.then_(pushSubscription => {
        open Mutation_CreateAlertRule

        let eventFilters =
          value.rules
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
          id: Externals.UUID.make(),
          accountAddress: accountAddress,
          collectionSlug: CreateAlertModal.CollectionOption.slugGet(collection),
          contractAddress: CreateAlertModal.CollectionOption.contractAddressGet(collection),
          eventFilters: eventFilters,
          destination: destination,
        }

        createAlertRuleMutation({
          input: input,
        }) |> Js.Promise.then_(_result => {
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

  <CreateAlertModal
    isOpen
    onClose
    onExited={handleExited}
    value={value}
    onChange={newValue => setValue(_ => newValue)}
    error={validationError}
    isActioning={isCreating}
    onAction={handleCreate}
    actionLabel="create"
  />
}
