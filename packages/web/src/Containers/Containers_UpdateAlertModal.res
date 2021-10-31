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

  let handleUpdate = () =>
    switch (
      newValue->Belt.Option.flatMap(AlertModal.Value.collection),
      accountAddress
    ) {
      | (Some(collection), Some(accountAddress)) => ()
      | _ => ()
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
  />
}
