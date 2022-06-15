@react.component @module("react-image-lightbox")
external make: (
  ~mainSrc: string,
  ~onCloseRequest: unit => unit,
  ~reactModalStyle: Js.t<'a>=?,
  ~toolbarButtons: array<React.element>=?,
  ~imagePadding: int=?,
) => React.element = "default"
