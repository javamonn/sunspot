@react.component
let make = (~className=?) => {
  let {openSnackbar}: Contexts_Snackbar.t = React.useContext(Contexts_Snackbar.context)

  let handleClickDiscord = () => Externals.Webapi.Window.open_(Config.discordGuildInviteUrl)
  let handleClickTwitter = () => Externals.Webapi.Window.open_(Config.twitterUrl)
  let handleClickGithub = () => Externals.Webapi.Window.open_(Config.githubUrl)

  <footer
    className={Cn.make([
      "flex",
      "flex-row",
      "sm:flex-col",
      "sm:pb-24",
      "justify-between",
      "py-2",
      "sm:px-4",
      "border-t",
      "border-solid",
      "border-darkBorder",
      className->Belt.Option.getWithDefault(""),
    ])}>
    <div className={Cn.make(["flex", "flex-row", "items-center", "justify-center"])}>
      <MaterialUi.IconButton onClick={_ => handleClickDiscord()}>
        <img src="/discord-icon.svg" className={Cn.make(["w-5", "h-5", "opacity-50"])} />
      </MaterialUi.IconButton>
      <MaterialUi.IconButton
        onClick={_ => handleClickTwitter()}
        classes={MaterialUi.IconButton.Classes.make(~root=Cn.make(["ml-2"]), ())}>
        <img src="/twitter-icon.svg" className={Cn.make(["w-5", "h-5", "opacity-50"])} />
      </MaterialUi.IconButton>
      <MaterialUi.IconButton
        onClick={_ => handleClickGithub()}
        classes={MaterialUi.IconButton.Classes.make(~root=Cn.make(["ml-2"]), ())}>
        <img src="/github-icon.svg" className={Cn.make(["w-5", "h-5", "opacity-50"])} />
      </MaterialUi.IconButton>
    </div>
    <InfoBetaEventsFeed />
  </footer>
}
