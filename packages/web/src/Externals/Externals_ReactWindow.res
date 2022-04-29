module FixedSizeList = {
  @react.component @module("react-window")
  external make: (
    ~height: float,
    ~itemCount: float,
    ~itemSize: float,
    ~width: float,
    ~itemData: 'a,
    ~children: {"data": array<'a>, "index": int, "style": ReactDOM.style} => React.element,
  ) => React.element = "FixedSizeList"
}
