@react.component
let default = () => {
  let router: Externals.Next.Router.router = Externals.Next.Router.useRouter()
  let code = Js.Dict.get(router.query, "code")
  let guildId = Js.Dict.get(router.query, "guild_id")
  let permissions =
    router.query->Js.Dict.get("permissions")->Belt.Option.flatMap(Belt.Int.fromString)
  let redirectUri = Config.isBrowser()
    ? Externals.Webapi.Location.origin ++ router.pathname
    : router.pathname

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
    <Containers.DiscordOnboaring
      code={code->Belt.Option.getWithDefault("")}
      guildId={guildId->Belt.Option.getWithDefault("")}
      permissions={permissions->Belt.Option.getWithDefault(0)}
      redirectUri={redirectUri}
      onCreated={handleCreated}
    />
  </main>
}
