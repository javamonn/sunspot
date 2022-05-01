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
      "px-4",
      "mt-4"
    ])}>
    <QueryRenderers_Events />
  </section>
}
