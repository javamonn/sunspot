let isIpfsUri = uri => {
  switch try {
    uri->Externals.Webapi.URL.make->Js.Option.some
  } catch {
  | _ => None
  } {
  | Some(url) if Externals.Webapi.URL.protocol(url) === "ipfs:" => true
  | Some(url) =>
    let protocol = Externals.Webapi.URL.protocol(url)
    let hostname = Externals.Webapi.URL.hostname(url)
    (protocol === "http:" || protocol === "https:") &&
      (hostname === "ipfs.io" ||
      hostname === "gateway.pinata.cloud" ||
      Js.String2.endsWith(hostname, ".mypinata.cloud"))
  | None => true
  }
}

let getNormalizedCidPath = uri => {
  let normalizePath = p =>
    if Js.String2.startsWith(p, "/ipfs/") {
      p
    } else if Js.String2.startsWith(p, "/") {
      `/ipfs${p}`
    } else {
      `/ipfs/${p}`
    }

  switch try {
    uri->Externals.Webapi.URL.make->Js.Option.some
  } catch {
  | _ => None
  } {
  | Some(url) if Externals.Webapi.URL.protocol(url) === "ipfs:" =>
    normalizePath(Js.String2.sliceToEnd(~from=Js.String2.length("ipfs://"), uri))
  | Some(url) => url->Externals.Webapi.URL.pathname->normalizePath
  | None if uri->Js.String2.startsWith("/ipfs/") => uri
  | None if uri->Js.String2.startsWith("/") => `/ipfs${uri}`
  | None => uri
  }
}

