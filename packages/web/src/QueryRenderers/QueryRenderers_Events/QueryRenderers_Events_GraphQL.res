module EventsListItem_AlertRuleSatisfiedEvent = EventsListItem_GraphQL.Fragment_EventsListItem_AlertRuleSatisfiedEvent

module Events_AlertRuleSatisfiedEvent = %graphql(`
  fragment Events_AlertRuleSatisfiedEvent on AlertRuleSatisfiedEvent {
    id
    alertRule {
      quickbuy
    }

    ...EventsListItem_AlertRuleSatisfiedEvent
  }
`)

module Query_ListAlertRuleSatisfiedEvents = %graphql(`
  query ListAlertRuleSatisfiedEvent($accountAddress: String!, $limit: Int!, $sortDirection: ModelSortDirection!, $nextToken: String) {
    alertRuleSatisfiedEvents: listAlertRuleSatisfiedEvents(accountAddress: $accountAddress, limit: $limit, nextToken: $nextToken, sortDirection: $sortDirection) {
      items {
        ...Events_AlertRuleSatisfiedEvent
      }
      nextToken
    }
  }
`)

let makeVariables = (~accountAddress, ~limit=50, ~nextToken=?, ()) => {
  Query_ListAlertRuleSatisfiedEvents.limit: limit,
  accountAddress: accountAddress,
  sortDirection: #DESC,
  nextToken: nextToken,
}

module Subscription_OnCreateAlertRuleSatisfiedEvent = %graphql(`
  subscription OnCreateAlertRuleSatisfiedEvent($accountAddress: String!) {
    onCreateAlertRuleSatisfiedEvent(accountAddress: $accountAddress) {
      ...Events_AlertRuleSatisfiedEvent
    }
  }
`)
