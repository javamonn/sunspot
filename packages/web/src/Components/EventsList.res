type rect = {width: float, height: float}
type listSize = {
  rect: rect,
  itemSize: float,
}

module Empty = {
  @react.component
  let make = () => {
    let {openCreateAlertModal}: Contexts_AlertCreateAndUpdateDialog_Context.t = React.useContext(
      Contexts_AlertCreateAndUpdateDialog_Context.context,
    )

    <div
      className={Cn.make([
        "flex",
        "flex-col",
        "items-center",
        "justify-start",
        "flex-1",
        "mt-12",
        "sm:mt-0",
      ])}>
      <MaterialUi.Button
        onClick={_ => openCreateAlertModal()}
        variant=#Outlined
        classes={MaterialUi.Button.Classes.make(
          ~label=Cn.make(["lowercase", "py-2", "px-2", "text-darkSecondary"]),
          (),
        )}>
        {React.string("create an alert to get started.")}
      </MaterialUi.Button>
      <h2 className={Cn.make(["text-sm", "mt-8", "text-darkSecondary"])}>
        {React.string(
          "sales, listing, floor price, and sales volume change events that satisfy your alerts will appear here.",
        )}
      </h2>
    </div>
  }
}

module Item = {
  @react.component
  let make = (~data, ~index, ~style) =>
    <EventsListItem
      onAssetMediaClick={data["onAssetMediaClick"]}
      onBuy={data["onBuy"]}
      alertRuleSatisfiedEvent={data["alertRuleSatisfiedEvents"]->Belt.Array.get(index)}
      now={data["now"]}
      style={style}
    />
}

@react.component
let make = (
  ~items,
  ~hasMoreItems,
  ~onLoadMoreItems,
  ~onEventsQueryPausedChanged,
  ~onBuy,
  ~onAssetMediaClick,
) => {
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
        let remUnit = Externals.Raw.getRemUnit()

        let itemSize =
          width > 500.0 /* * xs breakpoint * */
            ? 8.0 *. remUnit +. 1.0 *. remUnit
            : 6.0 *. remUnit +. 1.0 *. remUnit
        Some({
          rect: {width: width, height: height},
          itemSize: itemSize,
        })
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

  <div
    className={Cn.make(["flex", "flex-1"])}
    onMouseEnter={_ => onEventsQueryPausedChanged(true)}
    onMouseLeave={_ => onEventsQueryPausedChanged(false)}>
    <div
      ref={measurementElem->ReactDOM.Ref.domRef}
      className={Cn.make(["absolute", "inset-0", "overflow-y-scroll"])}
    />
    {listSize
    ->Belt.Option.map(({rect: {width, height}, itemSize}) => {
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
        loadMoreItems={(_, _) => onLoadMoreItems()}>
        {props =>
          Belt.Array.length(items) === 0 && !hasMoreItems
            ? <Empty />
            : <Externals.ReactWindow.FixedSizeList
                height={height}
                width={width}
                itemSize={itemSize}
                itemKey={handleItemKey}
                itemCount={itemCount}
                itemData={{
                  "alertRuleSatisfiedEvents": items,
                  "onAssetMediaClick": onAssetMediaClick,
                  "onBuy": onBuy,
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
  </div>
}
