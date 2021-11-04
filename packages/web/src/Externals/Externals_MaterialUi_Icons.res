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

module Error = {
  @react.component @module("@material-ui/icons/Error")
  external make: (
    ~color: string=?,
    ~className: string=?,
    ~fontSize: string=?,
    ~style: ReactDOM.Style.t=?,
  ) => React.element = "default"
}

module MoreVert = {
  @react.component @module("@material-ui/icons/MoreVert")
  external make: (
    ~color: string=?,
    ~className: string=?,
    ~fontSize: string=?,
    ~style: ReactDOM.Style.t=?,
  ) => React.element = "default"
}

module Delete = {
  @react.component @module("@material-ui/icons/Delete")
  external make: (
    ~color: string=?,
    ~className: string=?,
    ~fontSize: string=?,
    ~style: ReactDOM.Style.t=?,
  ) => React.element = "default"
}

module HelpOutline = {
  @react.component @module("@material-ui/icons/HelpOutline")
  external make: (
    ~color: string=?,
    ~className: string=?,
    ~fontSize: string=?,
    ~style: ReactDOM.Style.t=?,
  ) => React.element = "default"
}
