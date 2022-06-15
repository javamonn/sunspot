@react.component
let make = (~children) =>
  <main
    style={ReactDOM.Style.make(~maxWidth="100rem", ())}
    className={Cn.make(["flex", "flex-col", "flex-1", "mx-auto", "w-full"])}>
    {children}
    <AlertsFooter className={Cn.make(["sm:hidden"])} />
  </main>
