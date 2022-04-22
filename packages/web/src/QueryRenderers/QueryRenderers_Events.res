@react.component
let make = () => {
  let {signIn, authentication}: Contexts.Auth.t = React.useContext(Contexts.Auth.context)
  let {isQuickbuyTxPending}: Contexts_Buy_Context.t = React.useContext(Contexts_Buy_Context.context)
  let eventsQueryUnsubscribe = React.useRef(None)

  let eventsQuery = QueryRenderers_Events_GraphQL.Query_ListAlertRuleSatisfiedEvents.use(
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
    switch authentication {
    | Authenticated({jwt: {accountAddress}}) if eventsQuery.data->Js.Option.isSome =>
      eventsQueryUnsubscribe.current = Some(
        eventsQuery.subscribeToMore(
          ~subscription=module(
            QueryRenderers_Events_GraphQL.Subscription_OnCreateAlertRuleSatisfiedEvent
          ),
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
        eventsQueryUnsubscribe.current->Belt.Option.forEach(cb => cb())
        eventsQueryUnsubscribe.current = None
      },
    )
  }, [eventsQuery.data->Js.Option.isSome])

  <span>
    {eventsQuery.data->Js.Json.stringifyAny->Belt.Option.getWithDefault("")->React.string}
  </span>
}
