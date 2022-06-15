import Document, { Html, Head, Main, NextScript } from "next/document";
import { ServerStyleSheets, ThemeProvider } from "@material-ui/core/styles";

class SunspotDocument extends Document {
  static async getInitialProps(ctx) {
    const sheets = new ServerStyleSheets();
    const originalRenderPage = ctx.renderPage;

    ctx.renderPage = () =>
      originalRenderPage({
        enhanceApp: (App) => (props) => sheets.collect(<App {...props} />),
        enhanceComponent: (Component) => Component,
      });

    const initialProps = await Document.getInitialProps(ctx);
    const css = sheets.toString();

    return { ...initialProps, jssServerSide: css };
  }

  render() {
    return (
      <Html>
        <Head>
          <style id="jss-server-side">{this.props.jssServerSide}</style>

        </Head>
        <body>
          <Main />
          <NextScript />
        </body>
      </Html>
    );
  }
}

export default SunspotDocument;
