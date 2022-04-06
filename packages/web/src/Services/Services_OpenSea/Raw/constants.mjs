// https://github.com/ProjectOpenSea/wyvern-schemas/blob/b829f3e93b0332f280f547875b31a9a3c7ae092a/dist/types.js#L7-L11
export const Network = {
  MAIN: "main",
  RINKEBY: "rinkeby",
};

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/types.ts#L151-L159
export const WyvernSchemaName = {
  ERC721: "ERC721",
  ERC1155: "ERC1155",
  ERC20: "ERC20",
};

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/utils/utils.ts#L1049-L1052
export const MerkleValidatorByNetwork = {
  [Network.MAIN]: "0xbaf2127b49fc93cbca6269fade0f7f31df4c88a7",
  [Network.RINKEBY]: "0x45b594792a5cdc008d0de1c1d69faa3d16b3ddc1",
};

// https://github.com/ProjectOpenSea/wyvern-js/blob/80fec352a4307a4ff3e27a5a47aa8642288a71f1/src/types.ts#L148-L155
export const FunctionInputKind = {
  Replaceable: "replaceable",
  Asset: "asset",
  Owner: "owner",
  Index: "index",
  Count: "count",
  Data: "data",
};

// https://github.com/ProjectOpenSea/wyvern-schemas/blob/b829f3e93b0332f280f547875b31a9a3c7ae092a/src/types.ts#L37-L42
export const StateMutability = {
  Pure: "pure",
  View: "view",
  Payable: "payable",
  Nonpayable: "nonpayable",
};

// https://github.com/ProjectOpenSea/wyvern-schemas/blob/b829f3e93b0332f280f547875b31a9a3c7ae092a/src/types.ts#L44-L49
export const FunctionOutputKind = {
  Owner: "owner",
  Asset: "asset",
  Count: "count",
  Other: "other",
};

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/types.ts#L111-L117
export const OrderSide = {
  Buy: 0,
  Sell: 1,
};

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/constants.ts#L54
export const MAX_EXPIRATION_MONTHS = 6;

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/constants.ts#L55
export const ORDER_MATCHING_LATENCY_SECONDS = 60 * 60 * 24 * 7;

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/constants.ts#L53
export const MIN_EXPIRATION_MINUTES = 15;

// https://github.com/ProjectOpenSea/wyvern-js/blob/80fec352a4307a4ff3e27a5a47aa8642288a71f1/src/utils/constants.ts#L14
export const MAX_DIGITS_IN_UNSIGNED_256_INT = 78;

// https://github.com/ProjectOpenSea/wyvern-js/blob/80fec352a4307a4ff3e27a5a47aa8642288a71f1/src/utils/constants.ts#L10
export const NULL_ADDRESS = "0x0000000000000000000000000000000000000000";

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/constants.ts#L5
export const NULL_BLOCK_HASH = "0x0000000000000000000000000000000000000000000000000000000000000000";

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/constants.ts#L3
export const DEFAULT_GAS_INCREASE_FACTOR = 1.01;

// https://github.com/ProjectOpenSea/wyvern-js/blob/80fec352a4307a4ff3e27a5a47aa8642288a71f1/src/types.ts#L28-L32
export const SaleKind = {
  FixedPrice: 0,
  EnglishAuction: 1,
  DutchAuction: 2,
};

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/constants.ts#L9
export const INVERSE_BASIS_POINT = 10000;
