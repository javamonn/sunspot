@react.component
let make = () => {
  let {signIn, authentication}: Contexts_Auth.t = React.useContext(Contexts_Auth.context)
  let {openSnackbar}: Contexts_Snackbar.t = React.useContext(Contexts_Snackbar.context)
  let {
    isQuickbuyTxPending,
    isOpen: isOpenSeaEventDialogOpen,
  }: Contexts_OpenSeaEventDialog_Context.t = React.useContext(
    Contexts_OpenSeaEventDialog_Context.context,
  )
  let router = Externals.Next.Router.useRouter()

  let eventsQueryQueue = React.useRef(None)
  let (isEventsFeedPaused, setIsEventsFeedPaused) = React.useState(_ => false)
  let (lightboxSrc, setLightboxSrc) = React.useState(_ => None)

  let {
    data,
    subscribeToMore,
    fetchMore,
    loading,
    called,
    client,
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

  let handleOpenOpenSeaEventDialog = (~id, ~contractAddress, ~tokenId, ~quickbuy) => {
    let query =
      [
        Some(("openSeaEventId", id->Obj.magic->Belt.Float.toString)),
        Some(("openSeaEventContractAddress", contractAddress)),
        Some(("openSeaEventTokenId", tokenId)),
        quickbuy ? Some(("openSeaEventQuickbuy", "true")) : None,
      ]
      ->Belt.Array.keepMap(param =>
        param->Belt.Option.map(((key, value)) => `${key}=${Js.Global.encodeURIComponent(value)}`)
      )
      ->Belt.Array.joinWith("&", i => i)

    Externals.Next.Router.replaceWithParams(
      router,
      `${router.pathname}?${query}`,
      None,
      {shallow: true},
    )
  }

  let handleQuickbuyIfEnabled = (
    alertRuleSatisfiedEvent: option<QueryRenderers_Events_GraphQL.Events_AlertRuleSatisfiedEvent.t>,
  ) => false

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
          ): QueryRenderers_Events_GraphQL.Query_ListAlertRuleSatisfiedEvents.t =>
            switch eventsQueryQueue.current {
            | Some(backlogItems) =>
              eventsQueryQueue.current = Some(
                Belt.Array.concat([onCreateAlertRuleSatisfiedEvent], backlogItems),
              )
              previous
            | None =>
              let _ = handleQuickbuyIfEnabled(onCreateAlertRuleSatisfiedEvent)

              {
                alertRuleSatisfiedEvents: Some({
                  __typename: "ModelAlertRuleSatisfiedEventConnection",
                  nextToken: previous.alertRuleSatisfiedEvents->Belt.Option.flatMap(a =>
                    a.nextToken
                  ),
                  items: Belt.Array.concat(
                    onCreateAlertRuleSatisfiedEvent
                    ->Belt.Option.map(e => [e])
                    ->Belt.Option.getWithDefault([]),
                    previous.alertRuleSatisfiedEvents
                    ->Belt.Option.map(alertRuleSatisfiedEvents => alertRuleSatisfiedEvents.items)
                    ->Belt.Option.getWithDefault([]),
                  ),
                }),
              }
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

  let handleLoadMoreItems = () => {
    switch (authentication, data) {
    | (
        Authenticated({jwt: {accountAddress}}),
        Some({alertRuleSatisfiedEvents: Some({nextToken: Some(nextToken)})}),
      ) =>
      fetchMore(
        ~variables=QueryRenderers_Events_GraphQL.makeVariables(~accountAddress, ~nextToken, ()),
        ~updateQuery=(previous, {fetchMoreResult}) => {
          QueryRenderers_Events_GraphQL.Query_ListAlertRuleSatisfiedEvents.alertRuleSatisfiedEvents: Some({
            __typename: "ModelAlertRuleSatisfiedEventConnection",
            nextToken: fetchMoreResult
            ->Belt.Option.flatMap(r => r.alertRuleSatisfiedEvents)
            ->Belt.Option.flatMap(r => r.nextToken),
            items: Belt.Array.concat(
              previous.alertRuleSatisfiedEvents
              ->Belt.Option.map(a => a.items)
              ->Belt.Option.getWithDefault([]),
              fetchMoreResult
              ->Belt.Option.flatMap(r => r.alertRuleSatisfiedEvents)
              ->Belt.Option.map(r => r.items)
              ->Belt.Option.getWithDefault([]),
            ),
          }),
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

  let handleEventsQueryPausedChanged = isPaused => {
    let _ = switch (eventsQueryQueue.current, data, authentication) {
    | (None, Some(_), _) if isPaused && called =>
      eventsQueryQueue.current = Some([])
      setIsEventsFeedPaused(_ => true)
    | (Some(backlogItems), Some(_), Authenticated({jwt: {accountAddress}}))
      if !isPaused && !isOpenSeaEventDialogOpen && !Js.Option.isSome(lightboxSrc) =>
      let variables = QueryRenderers_Events_GraphQL.makeVariables(~accountAddress, ())
      let existingData = switch client.readQuery(
        ~query=module(QueryRenderers_Events_GraphQL.Query_ListAlertRuleSatisfiedEvents),
        variables,
      ) {
      | Some(
          Ok({
            alertRuleSatisfiedEvents: Some(data),
          }): ApolloClient__React_Types.ApolloClient.Types.parseResult<
            QueryRenderers_Events_GraphQL.Query_ListAlertRuleSatisfiedEvents.t,
          >,
        ) =>
        Some(data)
      | _ => None
      }

      existingData->Belt.Option.forEach(existingData => {
        let newData = {
          ...existingData,
          items: Belt.Array.concat(backlogItems->Belt.Array.keepMap(i => i), existingData.items),
        }

        client.writeQuery(
          ~query=module(QueryRenderers_Events_GraphQL.Query_ListAlertRuleSatisfiedEvents),
          ~data={
            alertRuleSatisfiedEvents: Some(newData),
          },
          variables,
        )

        let _ = backlogItems->Belt.Array.getBy(handleQuickbuyIfEnabled)
      })

      setIsEventsFeedPaused(_ => false)
      eventsQueryQueue.current = None
    | _ => ()
    }
  }

  let handleAssetMediaClick = src => setLightboxSrc(_ => Some(src))

  let _ = React.useEffect2(() => {
    if isOpenSeaEventDialogOpen || Js.Option.isSome(lightboxSrc) {
      handleEventsQueryPausedChanged(true)
    }

    if Config.isBreakpointMd() && !isOpenSeaEventDialogOpen && !Js.Option.isSome(lightboxSrc) {
      handleEventsQueryPausedChanged(false)
    }

    None
  }, (isOpenSeaEventDialogOpen, Js.Option.isSome(lightboxSrc)))

  let items = switch data {
  | Some({alertRuleSatisfiedEvents: Some({items})}) =>
    items->Belt.Array.keepMap(item =>
      switch item {
      | {
          eventsListItem_AlertRuleSatisfiedEvent:
            {context: Some(#AlertRuleSatisfiedEvent_SaleContext(_))} as event,
        } =>
        Some(event)
      | {
          eventsListItem_AlertRuleSatisfiedEvent:
            {context: Some(#AlertRuleSatisfiedEvent_OpenSeaEventListingContext(_))} as event,
        } =>
        Some(event)
      | {
          eventsListItem_AlertRuleSatisfiedEvent:
            {context: Some(#AlertRuleSatisfiedEvent_MacroRelativeChangeContext(_))} as event,
        } =>
        Some(event)
      | _ => None
      }
    )
  | _ => []
  }
  let hasMoreItems = switch data {
  | Some({alertRuleSatisfiedEvents: Some({nextToken})}) => Js.Option.isSome(nextToken)
  | _ => loading || !called
  }

  <>
    {lightboxSrc
    ->Belt.Option.map(src =>
      <Externals.ReactImageLightbox
        mainSrc={src}
        onCloseRequest={() => setLightboxSrc(_ => None)}
        imagePadding={30}
        reactModalStyle={{
          "overlay": {
            "zIndex": "1500",
          },
        }}
      />
    )
    ->Belt.Option.getWithDefault(React.null)}
    <EventsList
      items={items}
      hasMoreItems={hasMoreItems}
      onLoadMoreItems={handleLoadMoreItems}
      onEventsQueryPausedChanged={handleEventsQueryPausedChanged}
      onOpenOpenSeaEventDialog={handleOpenOpenSeaEventDialog}
      onAssetMediaClick={handleAssetMediaClick}
    />
    <MaterialUi.Snackbar
      anchorOrigin={MaterialUi.Snackbar.AnchorOrigin.make(
        ~horizontal=MaterialUi.Snackbar.Horizontal.center,
        ~vertical=MaterialUi.Snackbar.Vertical.bottom,
        (),
      )}
      _open={isEventsFeedPaused && !isOpenSeaEventDialogOpen && !Js.Option.isSome(lightboxSrc)}>
      <MaterialUi_Lab.Alert
        color=#Warning
        severity=#Warning
        classes={MaterialUi_Lab.Alert.Classes.make(
          ~root=Cn.make(["flex", "flex-row", "items-center", "sm:flex-1"]),
          ~message=Cn.make(["block", "sm:w-auto", "sm:max-w-full"]),
          (),
        )}>
        {React.string("feed paused on hover")}
      </MaterialUi_Lab.Alert>
    </MaterialUi.Snackbar>
  </>
}
