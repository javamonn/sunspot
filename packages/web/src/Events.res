@react.component
let default = () => {
  <section
    className={Cn.make([
      "font-mono",
      "flex",
      "flex-col",
      "flex-1",
      "overflow-y-hidden",
      "overflow-x-hidden",
      "bg-white",
      "mt-4",
      "relative"
    ])}>
    <QueryRenderers_Events />
  </section>
}
