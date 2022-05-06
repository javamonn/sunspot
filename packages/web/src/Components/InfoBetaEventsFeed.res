@react.component
let make = (~className=?) => {
  let router: Externals.Next.Router.router = Externals.Next.Router.useRouter()

  router.asPath === "/events"
    ? <div
        className={Cn.make([
          "p-2",
          "border",
          "border-solid",
          "border-darkBorder",
          "rounded",
          "flex",
          "flex-row",
          "items-center",
          "font-mono",
          "mr-2",
          className->Belt.Option.getWithDefault(""),
        ])}>
        <Externals.MaterialUi_Icons.Info
          className={Cn.make(["w-4", "h-4", "mr-2", "opacity-50"])}
        />
        <span className={Cn.make(["text-xs", "text-darkSecondary", "leading-none"])}>
          {React.string("events feed is in ")}
          <span className={Cn.make(["font-bold"])}> {React.string("beta")} </span>
          {React.string(", only listing and sale events are currently visible.")}
        </span>
      </div>
    : React.null
}
