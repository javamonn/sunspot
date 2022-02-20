@react.component
let default = () =>
  <main
    style={ReactDOM.Style.make(~maxWidth="725px", ())}
    className={Cn.make([
      "px-12",
      "py-12",
      "sm:px-6",
      "sm:py-6",
      "font-mono",
      "flex",
      "flex-col",
      "flex-1",
      "overflow-y-auto",
      "bg-white",
    ])}>
    <section className={Cn.make(["mb-20"])}>
      <p className={Cn.make(["mb-4"])}>
        <b> {React.string("sunspot")} </b>
        {React.string(
          " alerts you in real-time when ethereum nfts are listed and sold on opensea.",
        )}
      </p>
      <ul className={Cn.make(["list-inside", "list-disc", "space-y-1"])}>
        <li>
          <Externals.Next.Link href="/alerts">
            <a className={Cn.make(["underline", "font-bold"])}> {React.string("launch app")} </a>
          </Externals.Next.Link>
        </li>
        <li>
          {React.string("install bot (")}
          <a className={Cn.make(["underline"])} href={Config.discordOAuthUrl} target="_blank">
            {React.string("discord")}
          </a>
          {React.string(", ")}
          <a className={Cn.make(["underline"])} href={Config.twitterOAuthUrl} target="_blank">
            {React.string("twitter")}
          </a>
          {React.string(", ")}
          <a className={Cn.make(["underline"])} href={Config.slackOAuthUrl} target="_blank">
            {React.string("slack")}
          </a>
          {React.string(")")}
        </li>
      </ul>
    </section>
    <section className={Cn.make(["mb-12"])}>
      <p className={Cn.make(["mb-2", "font-bold"])}> {React.string("use cases:")} </p>
      <ul className={Cn.make(["list-disc", "list-inside", "space-y-1"])}>
        <li> {React.string("snipe mispriced assets at time of listing")} </li>
        <li> {React.string("monitor collection average price and volume activity")} </li>
        <li> {React.string("create discord and twitter sales bots for your project")} </li>
        <li> {React.string("get notified when your active listing is undercut")} </li>
      </ul>
    </section>
    <section className={Cn.make(["mb-12"])}>
      <p className={Cn.make(["mb-2", "font-bold"])}> {React.string("features:")} </p>
      <ul className={Cn.make(["list-disc", "list-inside", "space-y-1"])}>
        <li> {React.string("real time event ingestion and alert dispatch pipeline")} </li>
        <li> {React.string("create alert rules with price threshold and traits")} </li>
        <li> {React.string("alerts delivered via browser push notification or discord bot")} </li>
        <li> {React.string("free to use and open source")} </li>
      </ul>
    </section>
    <section className={Cn.make(["mb-10"])}>
      <p className={Cn.make(["mb-2", "font-bold"])}> {React.string("etc:")} </p>
      <ul className={Cn.make(["list-disc", "list-inside", "space-y-1"])}>
        <li>
          <a className={Cn.make(["underline"])} href={Config.discordGuildInviteUrl} target="_blank">
            {React.string("discord")}
          </a>
        </li>
        <li>
          <a className={Cn.make(["underline"])} href={Config.twitterUrl} target="_blank">
            {React.string("twitter")}
          </a>
        </li>
        <li>
          <a href={Config.githubUrl} className={Cn.make(["underline"])} target="_blank">
            {React.string("github")}
          </a>
        </li>
      </ul>
    </section>
  </main>
