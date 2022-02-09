@react.component
let make = () => {
  let (_, sendTransaction) = Externals.Wagmi.UseTransaction.use()
  let {authentication}: Contexts.Auth.t = React.useContext(Contexts.Auth.context)
  let {openSnackbar}: Contexts.Snackbar.t = React.useContext(Contexts.Snackbar.context)

  let handleClickDiscord = () => Externals.Webapi.Window.open_(Config.discordGuildInviteUrl)
  let handleClickTwitter = () => Externals.Webapi.Window.open_(Config.twitterUrl)
  let handleClickGithub = () => Externals.Webapi.Window.open_(Config.githubUrl)
  let handleClickDonate = () => {
    open Externals.Wagmi.UseTransaction
    switch authentication {
    | Contexts.Auth.Unauthenticated_ConnectRequired =>
      openSnackbar(
        ~type_=Contexts.Snackbar.TypeError,
        ~message=React.string("connect your wallet to donate."),
        ~duration=8000,
        (),
      )
    | _ =>
      let _ =
        sendTransaction({
          request: {
            to_: Config.donationsAddress,
            value: Externals.Ethers.BigNumber.makeFromString("50000000000000000"), // .05
          },
        })
        |> Js.Promise.then_(result => {
          let _ = switch result.data {
          | Some(_) =>
            openSnackbar(
              ~type_=Contexts.Snackbar.TypeSuccess,
              ~message=React.string("thank you for your support."),
              ~duration=4000,
              (),
            )
          | None => ()
          }
          Js.Promise.resolve()
        })
        |> Js.Promise.catch(err => {
          Services.Logger.promiseError("AlertsFooter", "handleClickDonate error", err)
          Js.Promise.resolve()
        })
    }
  }

  <footer
    className={Cn.make([
      "flex",
      "flex-row",
      "justify-between",
      "py-4",
      "border-t",
      "border-solid",
      "border-darkBorder",
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
    <div>
      <MaterialUi.Button
        onClick={_ => handleClickDonate()}
        variant=#Outlined
        size=#Small
        classes={MaterialUi.Button.Classes.make(
          ~root=Cn.make(["border-solid", "border-darkBorder", "p-2"]),
          ~label=Cn.make([
            "lowercase",
            "text-xs",
            "text-left",
            "flex",
            "flex-col",
            "items-start",
            "leading-snug",
          ]),
          (),
        )}>
        <span className={Cn.make(["block", "font-bold"])}>
          {React.string("sunspot is user supported.")}
        </span>
        <span className={Cn.make(["block"])}>
          {React.string("please consider donating to support development.")}
        </span>
      </MaterialUi.Button>
    </div>
  </footer>
}
