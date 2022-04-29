type rect = {width: float, height: float}
let itemSize = 100.0

module Item = {
  @react.component
  let make = (~data, ~index, ~style) =>
    switch data->Belt.Array.get(index) {
    | Some(item) =>
      <div style={style}>
        {item->Js.Json.stringifyAny->Belt.Option.getWithDefault("")->React.string}
      </div>
    | None => <div style={style}> {React.string("loading...")} </div>
    }
}

@react.component
let make = (~items, ~hasMoreItems, ~onLoadMoreItems) => {
  let measurementElem = React.useRef(Js.Nullable.null)
  let (listSize, setListSize) = React.useState(_ => None)
  let (windowSize, setWindowSize) = React.useState(_ => {width: 0.0, height: 0.0})

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

    Some(
      () => {
        Externals.Webapi.EventTarget.removeEventListener(
          Externals.Webapi.Window.inst->Externals.Webapi.EventTarget.unsafeAsEventTarget,
          "resize",
          onResize,
        )
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

  let handleIsItemLoaded = idx => items->Belt.Array.get(idx)->Js.Option.isSome

  <>
    <div ref={measurementElem->ReactDOM.Ref.domRef} className={Cn.make(["absolute", "inset-0"])} />
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
            itemCount={itemCount}
            itemData={items}
            onItemsRendered={props["onItemsRendered"]}
            ref={props["ref"]}>
            {Item.make}
          </Externals.ReactWindow.FixedSizeList>}
      </Externals.ReactWindowInfiniteLoader.InfiniteLoader>
    })
    ->Belt.Option.getWithDefault(React.null)}
  </>
}
