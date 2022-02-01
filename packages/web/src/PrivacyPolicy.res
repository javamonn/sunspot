let html: string = %raw("require('../static/privacy-policy.md').default");

@react.component
let default = () => <>
  <Externals.Next.Head>
    <title>{React.string("sunspot / privacy policy")}</title>
    <meta
      name="description"
      content="what data we collect and why"
    />
  </Externals.Next.Head>
  <header className={Cn.make(["mt-12", "flex", "flex-col", "px-6", "sm:px-12"])} />
  <main
    className={Cn.make(["px-6", "sm:px-12", "py-24"])}
    style={ReactDOM.Style.make(~maxWidth="750px", ())}>
    <Markdown html />
  </main>
</>
