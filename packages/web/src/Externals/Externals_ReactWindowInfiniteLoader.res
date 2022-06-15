module InfiniteLoader = {
  @react.component @module("react-window-infinite-loader")
  external make: (
    ~itemCount: int,
    ~isItemLoaded: int => bool,
    ~threshold: int,
    ~loadMoreItems: (int, int) => Js.Promise.t<unit>,
    ~minimumBatchSize: int,
    ~children: {
      "onItemsRendered": {
        "overscanStartIndex": int,
        "overscanStopIndex": int,
        "visibleStartIndex": int,
        "visibleStopIndex": int,
      } => unit,
      "ref": React.Ref.t<'a>,
    } => React.element,
  ) => React.element = "default"
}
