@react.component
let default = () => {
  let router: Externals.Next.Router.router = Externals.Next.Router.useRouter()
  let code = Js.Dict.get(router.query, "code")

  /**
  let redirectUri = Config.isBrowser()
    ? Externals.Webapi.Location.origin ++ router.pathname
    : router.pathname
  **/
  let redirectUri = "https://sunspot.gg/integrations/slack/install"


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
    <Containers.OAuthIntegration
      onCreated={handleCreated}
      params={Containers.OAuthIntegration.Slack({
        code: code->Belt.Option.getWithDefault(""),
        redirectUri: redirectUri,
      })}
    />
  </main>
}
