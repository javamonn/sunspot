@react.component
let default = () => {
  <main
    className={Cn.make([
      "font-mono",
      "flex",
      "flex-col",
      "flex-1",
      "overflow-y-hidden",
      "overflow-x-hidden",
      "bg-white",
      "mx-auto",
      "relative",
    ])}
    style={ReactDOM.Style.make(~maxWidth="100rem", ())}>
    <QueryRenderers_Events />
  </main>
}
