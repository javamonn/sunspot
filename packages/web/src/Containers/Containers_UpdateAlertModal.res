module AlertRule = QueryRenderers_Alerts_GraphQL.Query_AlertRulesByAccountAddress.AlertRule
module Mutation_UpdateAlertRule = %graphql(`
  mutation UpdateAlertRuleInput($input: UpdateAlertRuleInput!) {
    alertRule: updateAlertRule(input: $input) {
      ...AlertRule
    }
  }
`)

module Mutation_DeleteAlertRule = %graphql(`
  mutation DeleteAlertRule($input: DeleteAlertRuleInput!) {
    alertRule: deleteAlertRule(input: $input) {
      id
    }
  }
`)

@react.component
let make = (~isOpen, ~value=?, ~onClose, ~accountAddress) => {
  let (updateAlertRuleMutation, updateAlertRuleMutationResult) = Mutation_UpdateAlertRule.use()
  let (deleteAlertRuleMutation, deleteAlertRuleMutationResult) = Mutation_DeleteAlertRule.use()
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
        Some(newCollection),
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

        let priceEventFilter =
          newValue
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
          newValue
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
          alertRule: {
            id: AlertModal.Value.id(newValue),
            accountAddress: accountAddress,
            collectionSlug: AlertModal.CollectionOption.slugGet(newCollection),
            contractAddress: AlertModal.CollectionOption.contractAddressGet(newCollection),
            eventFilters: [priceEventFilter, propertiesRule]->Belt.Array.keepMap(i => i),
            destination: destination,
          },
          key: {
            contractAddress: AlertModal.CollectionOption.contractAddressGet(existingCollection),
            id: AlertModal.Value.id(existingValue),
          },
        }

        updateAlertRuleMutation(
          ~update=({writeFragment}, {data}) => {
            data
            ->Belt.Option.flatMap(({alertRule}) => alertRule)
            ->Belt.Option.forEach(alertRule => {
              let _ = writeFragment(
                ~fragment=module(
                  QueryRenderers_Alerts_GraphQL.Query_AlertRulesByAccountAddress.AlertRule
                ),
                ~data=alertRule,
                ~id=alertRule.id,
              )
            })
          },
          {
            input: input,
          },
        )
      })
      |> Js.Promise.then_(_result => {
        onClose()
        Js.Promise.resolve()
      })
    | _ => Js.Promise.resolve()
    }
  }

  let handleDelete = _ =>
    switch (value, value->Belt.Option.flatMap(AlertModal.Value.collection), accountAddress) {
    | (Some(value), Some(collection), Some(accountAddress)) =>
      let _ =
        deleteAlertRuleMutation(
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
                items
                ->Belt.Array.keep(item =>
                  switch item {
                  | Some(item) => item.id != alertRule.id
                  | None => false
                  }
                )
                ->Js.Option.some
              | _ => None
              }

              newItems->Belt.Option.forEach(newItems => {
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
            })
          },
          {
            input: {
              contractAddress: collection->AlertModal.CollectionOption.contractAddressGet,
              id: value->AlertModal.Value.id,
            },
          },
        )
        |> Js.Promise.then_(_ => {
          onClose()
          Js.Promise.resolve()
        })
        |> Js.Promise.catch(err => {
          Services.Logger.promiseError(
            "Containers_UpdateAlertModal",
            "Unable to delete AlertRule.",
            err,
          )
          Js.Promise.resolve()
        })
    | _ => ()
    }

  let isActioning = switch (updateAlertRuleMutationResult, deleteAlertRuleMutationResult) {
  | ({loading: true}, _) => true
  | (_, {loading: true}) => true
  | _ => false
  }

  <AlertModal
    isOpen
    onClose
    value={newValue->Belt.Option.getWithDefault(AlertModal.Value.empty())}
    onChange={newValue => setNewValue(_ => Some(newValue))}
    isActioning={isActioning}
    onAction={handleUpdate}
    actionLabel="update"
    title="update alert"
    renderOverflowActionMenuItems={(~onClick) =>
      <MaterialUi.MenuItem
        onClick={_ => {
          onClick()
          handleDelete()
        }}>
        <MaterialUi.ListItemIcon> <Externals.MaterialUi_Icons.Delete /> </MaterialUi.ListItemIcon>
        <MaterialUi.ListItemText> {React.string("delete")} </MaterialUi.ListItemText>
      </MaterialUi.MenuItem>}
  />
}
