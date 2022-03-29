type network
type client
// WyvernSchemaName: https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/types.ts#L151-L159
type wyvernSchemaName = [
  | #ERC20
  | #ERC721
  | #ERC721v3
  | #ERC1155
]

// WyvernAsset: https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/types.ts#L191
type wyvernAsset = {
  id: string,
  address: string,
  quantity: option<string>,
}

// WyvernBundle: https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/types.ts#L194
type wyvernBundle = {
  assets: array<wyvernAsset>,
  schemas: array<wyvernSchemaName>,
  name: option<string>,
  description: option<string>,
  @as("external_link") externalLink: option<string>,
}

// ExchangeMetadata: https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/types.ts#L566-L568
type exchangeMetadata = {
  // ExchangeMetadataForAsset
  asset: option<wyvernAsset>,
  schema: option<wyvernSchemaName>,
  // ExchangeMetadataForBundle
  bundle: option<wyvernBundle>,
  referrerAddress: option<string>,
}

type openSeaAccount = {
  address: string,
  config: string,
  profileImgUrl: string,
  user: option<int>,
}

// OpenSeaFungibleToken: https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/types.ts#L475-L479
type openSeaFungibleToken = {
  name: string,
  symbol: string,
  decimals: int,
  address: string,
  imageUrl: string,
  ethPrice: string,
  usdPrice: string,
}

type order = {
  // Order: https://github.com/ProjectOpenSea/wyvern-js/blob/80fec352a4307a4ff3e27a5a47aa8642288a71f1/src/types.ts#L111-L135
  exchange: string,
  maker: string,
  taker: string,
  makerRelayerFee: Externals_BigNumber.t,
  takerRelayerFee: Externals_BigNumber.t,
  makerProtocolFee: Externals_BigNumber.t,
  takerProtocolFee: Externals_BigNumber.t,
  quantity: Externals_BigNumber.t,
  feeRecipient: string,
  feeMethod: int,
  side: int,
  saleKind: int,
  target: string,
  howToCall: int,
  calldata: string,
  replacementPattern: string,
  staticTarget: string,
  staticExtradata: string,
  paymentToken: string,
  basePrice: Externals_BigNumber.t,
  extra: Externals_BigNumber.t,
  listingTime: Externals_BigNumber.t,
  expirationTime: Externals_BigNumber.t,
  salt: Externals_BigNumber.t,
  // ECSignature: https://github.com/ProjectOpenSea/wyvern-js/blob/80fec352a4307a4ff3e27a5a47aa8642288a71f1/src/types.ts#L55-L59
  v: int,
  r: string,
  s: string,
  // UnhashedOrder: https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/types.ts#L570-L583
  makerReferrerFee: Externals_BigNumber.t,
  waitingForBestCounterOrder: bool,
  englishAuctionReservePrice: option<Externals_BigNumber.t>,
  metadata: exchangeMetadata,
  // UnsignedOrder: https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/types.ts#L585
  hash: option<string>,
  // Order: https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/types.ts#L593
  createdTime: Externals_BigNumber.t,
  currentPrice: Externals_BigNumber.t,
  currentBounty: Externals_BigNumber.t,
  makerAccount: openSeaAccount,
  takerAccount: openSeaAccount,
  feeRecipientAccount: openSeaAccount,
  paymentTokenContract: openSeaFungibleToken,
  cancelledOrFinalized: bool,
  markedInvalid: bool,
  nonce: option<float>,
}

@scope("Network") @module("opensea-js") external mainNetwork: network = "Main"

@deriving(abstract)
type clientParams = {
  networkName: network,
  @optional apiKey: string,
}
@new @module("opensea-js")
external makeClient: (Externals_Ethereum.t, clientParams) => client = "OpenSeaPort"

@deriving(abstract)
type orderParams = {
  order: order,
  accountAddress: string,
  @optional recipientAddress: string,
  referrerAddress: string,
}

@send external fulfillOrder: (client, orderParams) => Js.Promise.t<string> = "fulfillOrder"

type transactionInfo = {transactionHash: string}
@send
external addListener: (
  client,
  @string
  [
    | #TransactionCreated(transactionInfo => unit)
    | #TransactionConfirmed(transactionInfo => unit)
    | #TransactionDenied(transactionInfo => unit)
    | #TransactionFailed(transactionInfo => unit)
  ],
) => unit = "addListener"

@send external removeAllListeners: client => unit = "removeAllListeners"

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/utils/utils.ts#L821-L863
let estimateCurrentPrice = %raw(`
(() => {
  const BigNumber = require('bignumber.js')

  return function estimateCurrentPrice(
    order,
    secondsToBacktrack = 30,
    shouldRoundUp = true
  ) {
    let { basePrice, listingTime, expirationTime, extra } = order;
    const { side, takerRelayerFee, saleKind } = order;

    const now = new BigNumber(Math.round(Date.now() / 1000)).minus(
      secondsToBacktrack
    );
    basePrice = new BigNumber(basePrice);
    listingTime = new BigNumber(listingTime);
    expirationTime = new BigNumber(expirationTime);
    extra = new BigNumber(extra);

    let exactPrice = basePrice;

    if (saleKind === 0) {
      // Do nothing, price is correct
    } else if (saleKind === 1) {
      const diff = extra
        .times(now.minus(listingTime))
        .dividedBy(expirationTime.minus(listingTime));

      exactPrice =
        side == 1 
          ? /* Sell-side - start price: basePrice. End price: basePrice - extra. */
            basePrice.minus(diff)
          : /* Buy-side - start price: basePrice. End price: basePrice + extra. */
            basePrice.plus(diff);
    }

    // Add taker fee only for buyers
    if (side === 1 && !order.waitingForBestCounterOrder) {
      // Buyer fee increases sale price
      exactPrice = exactPrice.times(+takerRelayerFee / 10000 + 1);
    }

    return shouldRoundUp
      ? exactPrice.integerValue(BigNumber.ROUND_CEIL)
      : exactPrice;
  }
  })()
`)
