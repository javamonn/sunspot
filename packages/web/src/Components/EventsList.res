type rect = {width: float, height: float}
let itemSize = Config.isBrowser()
  ? {
      let remUnit = Externals.Raw.getRemUnit()

      8.0 *. remUnit +. 1.0 *. remUnit
    }
  : 128.0 +. 16.0

module Item = {
  @react.component
  let make = (~data, ~index, ~style) =>
    <EventsListItem
      onAssetMediaClick={data["onAssetMediaClick"]}
      onClick={data["onClick"]}
      alertRuleSatisfiedEvent={data["alertRuleSatisfiedEvents"]->Belt.Array.get(index)}
      now={data["now"]}
      style={style}
    />
}

@react.component
let make = (~items, ~hasMoreItems, ~onLoadMoreItems) => {
  let router: Externals.Next.Router.router = Externals.Next.Router.useRouter()
  let measurementElem = React.useRef(Js.Nullable.null)
  let (listSize, setListSize) = React.useState(_ => None)
  let (windowSize, setWindowSize) = React.useState(_ => {width: 0.0, height: 0.0})
  let (now, setNow) = React.useState(_ => Js.Date.now())

  let _ = React.useEffect0(() => {
    let debouncedSetWindowSize = Externals.Lodash.Throttle1.make(
      (. windowSize) => setWindowSize(_ => windowSize),
      250,
    )
    let onResize = _ => {
      debouncedSetWindowSize(. {
        width: Externals.Webapi.Window.inst->Externals.Webapi.Window.innerWidth,
        height: Externals.Webapi.Window.inst->Externals.Webapi.Window.innerHeight,
      })
    }
    Externals.Webapi.EventTarget.addEventListener(
      Externals.Webapi.Window.inst->Externals.Webapi.EventTarget.unsafeAsEventTarget,
      "resize",
      onResize,
    )

    let nowInterval = Js.Global.setInterval(() => {
      setNow(_ => Js.Date.now())
    }, 1000)

    Some(
      () => {
        let _ = Externals.Webapi.EventTarget.removeEventListener(
          Externals.Webapi.Window.inst->Externals.Webapi.EventTarget.unsafeAsEventTarget,
          "resize",
          onResize,
        )
        let _ = Js.Global.clearInterval(nowInterval)
      },
    )
  })
  let _ = React.useLayoutEffect1(() => {
    measurementElem.current
    ->Js.Nullable.toOption
    ->Belt.Option.forEach(elem => {
      setListSize(_ => {
        let {
          Externals.Webapi.Element.width: width,
          height,
        } = Externals.Webapi.Element.getBoundingClientRect(elem)

        Some({width: width, height: height})
      })
    })

    None
  }, [windowSize])

  let handleItemKey = (idx, data) =>
    data["alertRuleSatisfiedEvents"]
    ->Belt.Array.get(idx)
    ->Belt.Option.map((
      alertRuleSatisfiedEvent: EventsListItem_GraphQL.Fragment_EventsListItem_AlertRuleSatisfiedEvent.t,
    ) => alertRuleSatisfiedEvent.id)
    ->Belt.Option.getWithDefault(Belt.Int.toString(idx))

  let handleIsItemLoaded = idx => items->Belt.Array.get(idx)->Js.Option.isSome
  let handleAssetMediaClick = src => {
    Js.log2("handleAssetMediaClick", src)
  }

  let handleClick = (
    ~quickbuy,
    ~alertRuleSatisfiedEvent: EventsListItem_GraphQL.Fragment_EventsListItem_AlertRuleSatisfiedEvent.t,
  ) =>
    switch alertRuleSatisfiedEvent {
    | {
        context: #AlertRuleSatisfiedEvent_ListingContext({
          openSeaOrder: {id, asset: Some({collection: Some({slug})})},
        }),
      } =>
      let query =
        [
          Some(("orderId", id->Obj.magic->Belt.Float.toString)),
          Some(("orderCollectionSlug", slug)),
          quickbuy ? Some(("orderQuickbuy", "true")) : None,
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
    | _ => ()
    }

  <>
    <div
      ref={measurementElem->ReactDOM.Ref.domRef}
      className={Cn.make(["absolute", "inset-0", "overflow-y-scroll"])}
    />
    {listSize
    ->Belt.Option.map(({width, height}) => {
      let windowItemCount = Js.Math.ceil_int(height /. itemSize)
      let itemCount = {
        let windowBuffer = 6
        let windowBufferItemCount = windowItemCount * windowBuffer
        let realizedItemCount = items->Belt.Array.length

        hasMoreItems ? realizedItemCount + windowBufferItemCount : realizedItemCount
      }

      <Externals.ReactWindowInfiniteLoader.InfiniteLoader
        itemCount={itemCount}
        isItemLoaded={handleIsItemLoaded}
        threshold={15}
        minimumBatchSize={20}
        loadMoreItems={onLoadMoreItems}>
        {props =>
          <Externals.ReactWindow.FixedSizeList
            height={height}
            width={width}
            itemSize={itemSize}
            itemKey={handleItemKey}
            itemCount={itemCount}
            itemData={{
              "alertRuleSatisfiedEvents": items,
              "onAssetMediaClick": handleAssetMediaClick,
              "onClick": handleClick,
              "now": now,
            }}
            onItemsRendered={props["onItemsRendered"]}
            ref={props["ref"]}
            className={Cn.make([])}>
            {Item.make}
          </Externals.ReactWindow.FixedSizeList>}
      </Externals.ReactWindowInfiniteLoader.InfiniteLoader>
    })
    ->Belt.Option.getWithDefault(React.null)}
  </>
}
