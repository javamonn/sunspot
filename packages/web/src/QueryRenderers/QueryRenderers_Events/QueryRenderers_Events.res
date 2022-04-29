@react.component
let make = () => {
  let {signIn, authentication}: Contexts.Auth.t = React.useContext(Contexts.Auth.context)
  let {isQuickbuyTxPending}: Contexts_Buy_Context.t = React.useContext(Contexts_Buy_Context.context)

  let {
    data,
    subscribeToMore,
    fetchMore,
  } = QueryRenderers_Events_GraphQL.Query_ListAlertRuleSatisfiedEvents.use(
    ~skip=switch authentication {
    | Authenticated(_) if !isQuickbuyTxPending => false
    | _ => true
    },
    switch authentication {
    | Authenticated({jwt: {accountAddress}}) =>
      QueryRenderers_Events_GraphQL.makeVariables(~accountAddress, ())
    | _ => QueryRenderers_Events_GraphQL.makeVariables(~accountAddress="", ())
    },
  )

  let _ = React.useEffect1(() => {
    let eventsQueryUnsubscribe = ref(None)
    switch authentication {
    | Authenticated({jwt: {accountAddress}}) if data->Js.Option.isSome =>
      eventsQueryUnsubscribe.contents = Some(
        subscribeToMore(
          ~subscription=module(
            QueryRenderers_Events_GraphQL.Subscription_OnCreateAlertRuleSatisfiedEvent
          ),
          ~updateQuery=(
            previous,
            {subscriptionData: {data: {onCreateAlertRuleSatisfiedEvent}}},
          ): QueryRenderers_Events_GraphQL.Query_ListAlertRuleSatisfiedEvents.t => {
            alertRuleSatisfiedEvents: Some({
              __typename: "ModelAlertRuleSatisfiedEventConnection",
              nextToken: previous.alertRuleSatisfiedEvents->Belt.Option.flatMap(a => a.nextToken),
              items: Some(
                Belt.Array.concat(
                  [onCreateAlertRuleSatisfiedEvent],
                  previous.alertRuleSatisfiedEvents
                  ->Belt.Option.flatMap(alertRuleSatisfiedEvents => alertRuleSatisfiedEvents.items)
                  ->Belt.Option.getWithDefault([]),
                ),
              ),
            }),
          },
          ~onError=error => {
            Services.Logger.logWithData(
              "QueryRenderers_Events",
              "subscribeToMore error",
              [
                (
                  "error",
                  error->Js.Json.stringifyAny->Belt.Option.getWithDefault("")->Js.Json.string,
                ),
              ]
              ->Js.Dict.fromArray
              ->Js.Json.object_,
            )
          },
          {accountAddress: accountAddress},
        ),
      )
    | _ => ()
    }

    Some(
      () => {
        eventsQueryUnsubscribe.contents->Belt.Option.forEach(cb => cb())
        eventsQueryUnsubscribe.contents = None
      },
    )
  }, [data->Js.Option.isSome])

  let handleLoadMoreItems = (startIdx, endIdx) => {
    fetchMore(

    )
  }

  let items = switch data {
  | Some({alertRuleSatisfiedEvents: Some({items: Some(items)})}) =>
    items->Belt.Array.keepMap(i => i)
  | _ => []
  }
  let hasMoreItems = switch data {
  | Some({alertRuleSatisfiedEvents: Some({nextToken})}) => Js.Option.isSome(nextToken)
  | _ => false
  }

  <EventsList items={items} hasMoreItems={hasMoreItems} onLoadMoreItems={handleLoadMoreItems} />
}
