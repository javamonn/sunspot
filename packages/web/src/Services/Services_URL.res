let etherscanTransaction = transactionHash => `https://etherscan.io/tx/${transactionHash}`
let etherscanAddress = address => `https://etherscan.io/address/${address}`

let resolveMedia = (~uri, ~cloudfrontEnabled=true, ()) => {
  let host = cloudfrontEnabled
    ? "https://dpldouen3w8e7.cloudfront.net"
    : "https://vmv917c3ik.execute-api.us-east-1.amazonaws.com"

  `${host}/production/resolve-media?uri=${Js.Global.encodeURIComponent(uri)}`
}

let collectionUrl = slug => `https://opensea.io/collection/${slug}`
