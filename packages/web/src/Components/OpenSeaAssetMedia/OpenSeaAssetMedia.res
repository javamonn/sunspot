module Fragment_OpenSeaAssetMedia_OpenSeaAsset = %graphql(`
  fragment OpenSeaAssetMedia_OpenSeaAsset on OpenSeaAsset {
    imageUrl
    imagePreviewUrl
    imageThumbnailUrl
    animationUrl
  }
`)

@react.component
let make = (~openSeaAsset: Fragment_OpenSeaAssetMedia_OpenSeaAsset.t, ~className=?, ~onClick) =>
  switch openSeaAsset {
  | {imageUrl: Some(uri)}
  | {imagePreviewUrl: Some(uri)}
  | {imageThumbnailUrl: Some(uri)} =>
    let uris =
      [
        openSeaAsset.imageUrl,
        openSeaAsset.imagePreviewUrl,
        openSeaAsset.imageThumbnailUrl,
      ]->Belt.Array.keepMap(i => i)
    let fallbackUri = uris->Belt.Array.getBy(candidate => candidate !== uri)
    let imageSrc = Services.URL.resolveMedia(~uri, ~fallbackUri?, ())
    <img
      className={Cn.make([
        "rounded",
        "cursor-pointer",
        "object-contain",
        "bg-gray-200",
        className->Belt.Option.getWithDefault(""),
      ])}
      src={imageSrc}
      onClick={ev => {
        let _ = ev->ReactEvent.Mouse.stopPropagation
        onClick(imageSrc)
      }}
    />
  | {animationUrl: Some(animationUrl)} =>
    <video
      controls={true}
      muted={true}
      autoPlay={true}
      className={Cn.make(["rounded", className->Belt.Option.getWithDefault("")])}
      src={Services.Ipfs.isIpfsUri(animationUrl)
        ? `https://ipfs.io${Services.Ipfs.getNormalizedCidPath(animationUrl)}`
        : animationUrl}
    />
  | _ => <div className={Cn.make(["rounded", "bg-gray-100"])} />
  }
