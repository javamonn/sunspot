@react.component
let make = () => {
  let {signIn, authentication}: Contexts.Auth.t = React.useContext(Contexts.Auth.context)
  let {openSnackbar}: Contexts_Snackbar.t = React.useContext(Contexts_Snackbar.context)
  let {isQuickbuyTxPending}: Contexts_Buy_Context.t = React.useContext(Contexts_Buy_Context.context)

  let {
    data,
    subscribeToMore,
    fetchMore,
    loading,
    called,
  } = QueryRenderers_Events_GraphQL.Query_ListAlertRuleSatisfiedEvents.use(
    ~fetchPolicy=ApolloClient__React_Hooks_UseQuery.WatchQueryFetchPolicy.NetworkOnly,
    ~nextFetchPolicy=ApolloClient__React_Hooks_UseQuery.WatchQueryFetchPolicy.CacheFirst,
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
    switch (authentication, data) {
    | (
        Authenticated({jwt: {accountAddress}}),
        Some({alertRuleSatisfiedEvents: Some({nextToken: Some(nextToken)})}),
      ) =>
      Js.log("fetchMore")
      fetchMore(
        ~variables=QueryRenderers_Events_GraphQL.makeVariables(
          ~accountAddress,
          ~limit=endIdx - startIdx,
          ~nextToken,
          (),
        ),
        ~updateQuery=(previous, {fetchMoreResult}) => {
          let updated = {
            QueryRenderers_Events_GraphQL.Query_ListAlertRuleSatisfiedEvents.alertRuleSatisfiedEvents: Some({
              __typename: "ModelAlertRuleSatisfiedEventConnection",
              nextToken: fetchMoreResult
              ->Belt.Option.flatMap(r => r.alertRuleSatisfiedEvents)
              ->Belt.Option.flatMap(r => r.nextToken),
              items: Belt.Array.concat(
                previous.alertRuleSatisfiedEvents
                ->Belt.Option.flatMap(a => a.items)
                ->Belt.Option.getWithDefault([]),
                fetchMoreResult
                ->Belt.Option.flatMap(r => r.alertRuleSatisfiedEvents)
                ->Belt.Option.flatMap(r => r.items)
                ->Belt.Option.getWithDefault([]),
              )->Js.Option.some,
            }),
          }

          Js.log4("updateQuery", previous, fetchMoreResult, updated)

          updated
        },
        (),
      ) |> Js.Promise.then_(result => {
        switch result {
        | Error(e) =>
          Services.Logger.apolloError("QueryRenderers_Events fetchMore", "error", e)
          openSnackbar(
            ~type_=Contexts_Snackbar.TypeError,
            ~duration=8000,
            ~message=React.string("an error occurred while loading more events."),
            (),
          )
        | Ok(_) => ()
        }
        Js.Promise.resolve()
      })
    | _ => Js.Promise.resolve()
    }
  }

  let items = switch data {
  | Some({alertRuleSatisfiedEvents: Some({items: Some(items)})}) =>
    items->Belt.Array.keepMap(i => i)
  | _ => []
  }
  let hasMoreItems = switch data {
  | Some({alertRuleSatisfiedEvents: Some({nextToken})}) => Js.Option.isSome(nextToken)
  | _ => loading || !called
  }

  <EventsList items={items} hasMoreItems={hasMoreItems} onLoadMoreItems={handleLoadMoreItems} />
}
