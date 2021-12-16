@react.component
let default = () => {
  let router: Externals.Next.Router.router = Externals.Next.Router.useRouter()
  let code = Js.Dict.get(router.query, "code")
  let handleCreated = () => {
    Externals.Next.Router.replace(router, "/alerts")
  }
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
      "max-w-6xl",
      "mx-auto",
    ])}>
    {React.null}
  </main>
}
