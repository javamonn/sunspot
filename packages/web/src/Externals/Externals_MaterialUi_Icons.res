module Add = {
  @react.component @module("@material-ui/icons/Add")
  external make: (~color: string=?, ~className: string=?, ~fontSize: string=?) => React.element =
    "default"
}

module Close = {
  @react.component @module("@material-ui/icons/Close")
  external make: (~color: string=?, ~className: string=?, ~fontSize: string=?) => React.element =
    "default"
}
