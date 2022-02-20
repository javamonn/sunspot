@react.component
let default = () =>
  <main
    className={Cn.make([
      "px-8",
      "pt-4",
      "sm:px-0",
      "sm:pt-2",
      "font-mono",
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
