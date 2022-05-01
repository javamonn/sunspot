@react.component
let default = () => {
  <section
    className={Cn.make([
      "sm:px-0",
      "sm:pt-2",
      "font-mono",
      "flex",
      "flex-col",
      "overflow-y-auto",
      "bg-white",
    ])}>
    <QueryRenderers_Alerts />
  </section>
}
