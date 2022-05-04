let etherscanTransaction = transactionHash => `https://etherscan.io/tx/${transactionHash}`
let etherscanAddress = address => `https://etherscan.io/address/${address}`

let resolveMedia = (~uri, ~fallbackUri=?, ~cloudfrontEnabled=true, ()) => {
  let host = cloudfrontEnabled
    ? "https://dpldouen3w8e7.cloudfront.net"
    : "https://vmv917c3ik.execute-api.us-east-1.amazonaws.com"

  let query =
    [Some(("uri", uri)), fallbackUri->Belt.Option.map(fallbackUri => ("fallbackUri", fallbackUri))]
    ->Belt.Array.keepMap(param =>
      param->Belt.Option.map(((key, value)) => `${key}=${Js.Global.encodeURIComponent(value)}`)
    )
    ->Belt.Array.joinWith("&", i => i)

  `${host}/production/resolve-media?${query}`
}

let collectionUrl = slug => `https//opensea.io/collection/${slug}`
