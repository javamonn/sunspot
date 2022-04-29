module FixedSizeList = {
  @react.component @module("react-window")
  external make: (
    ~height: float,
    ~itemCount: int,
    ~itemSize: float,
    ~width: float,
    ~itemData: 'a,
    ~onItemsRenderered: {
      "overscanStartIndex": int,
      "overscanStopIndex": int,
      "visibleStartIndex": int,
      "visibleStopIndex": int,
    } => unit,
    ~children: {"data": array<'a>, "index": int, "style": ReactDOM.style} => React.element,
    ~ref: React.Ref.t<'a>,
  ) => React.element = "FixedSizeList"
}
