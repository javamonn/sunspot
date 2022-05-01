@react.component
let make = (~children) =>
  <main
    style={ReactDOM.Style.make(~maxWidth="100rem", ())}
    className={Cn.make(["flex", "flex-col", "flex-1", "mx-auto"])}>
    {children}
  </main>
