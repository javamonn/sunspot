import "styles/main.css";
import "@fontsource/ibm-plex-mono";

// Note:
// Just renaming $$default to ResApp alone
// doesn't help FastRefresh to detect the
// React component, since an alias isn't attached
// to the original React component function name.
import ResApp from "src/App.bs.js";

if (globalThis.navigator && "serviceWorker" in globalThis.navigator) {
  globalThis.addEventListener("load", () => {
    globalThis.navigator.serviceWorker.register("/service-worker.js");
  });
}

// Note:
// We need to wrap the make call with
// a Fast-Refresh conform function name,
// (in this case, uppercased first letter)
//
// If you don't do this, your Fast-Refresh will
// not work!
export default function App(props) {
  return <ResApp {...props} />;
}
