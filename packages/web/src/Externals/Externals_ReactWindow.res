module FixedSizeList = {
  @react.component @module("react-window")
  external make: (
    ~height: float,
    ~itemCount: int,
    ~itemSize: float,
    ~width: float,
    ~itemData: 'a,
    ~itemKey: (int, 'a) => string,
    ~onItemsRendered: {
      "overscanStartIndex": int,
      "overscanStopIndex": int,
      "visibleStartIndex": int,
      "visibleStopIndex": int,
    } => unit,
    ~children: {"data": 'a, "index": int, "style": ReactDOM.style} => React.element,
    ~ref: React.Ref.t<'a>,
  ) => React.element = "FixedSizeList"
}
