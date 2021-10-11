@react.component
let default = () => {
  <>
    <Externals.Next.Head>
      <title> {React.string("sunspot")} </title> <meta name="description" content="nft tooling" />
    </Externals.Next.Head>
    <main
      className={Cn.make([
        "px-8",
        "font-mono",
        "py-8",
        "flex",
        "flex-col",
        "justify-between",
        "content-between",
        "flex-1",
        "overflow-y-auto",
        "bg-primary",
      ])}>
      <QueryRenderers_Alerts />
    </main>
  </>
}
