@react.component
let default = () =>
  <main
    className={Cn.make([
      "px-8",
      "font-mono",
      "py-8",
      "flex",
      "flex-col",
      "flex-1",
      "overflow-y-auto",
      "bg-white",
      "mx-auto",
    ])}
    style={ReactDOM.Style.make(~maxWidth="100rem", ())}>
    <QueryRenderers_Alerts />
  </main>
