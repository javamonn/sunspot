import { BigNumber } from "ethers";
import {
  WyvernSchemaName,
  MerkleValidatorByNetwork,
  OrderSide,
  MAX_EXPIRATION_MONTHS,
  MIN_EXPIRATION_MINUTES,
  ORDER_MATCHING_LATENCY_SECONDS,
  DEFAULT_GAS_INCREASE_FACTOR,
  NULL_ADDRESS,
  NULL_BLOCK_HASH,
  INVERSE_BASIS_POINT,
  SaleKind,
} from "./constants.mjs";
import { schemas } from "./wyvern-schemas.mjs";
import {
  getMaxOrderExpirationTimestamp,
  assignOrdersToSides,
  delay,
} from "./seaport-utils.mjs";
import {
  requireOrdersCanMatch,
  requireOrderCalldataCanMatch,
} from "./seaport-debugging.mjs";
import { encodeBuy, encodeSell } from "./schema-utils.mjs";
import { generatePseudoRandomSalt } from "./wyvern-protocol.mjs";
import { isValidAddress } from "ethereumjs-util";
import { ethers } from "ethers";

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/utils/utils.ts#L1006-L1020
function validateAndFormatWalletAddress(address) {
  if (!address) {
    throw new Error("No wallet address found");
  }
  if (!ethers.utils.isAddress(address)) {
    throw new Error("Invalid wallet address");
  }
  if (address == NULL_ADDRESS) {
    throw new Error("Wallet cannot be the null address");
  }
  return address.toLowerCase();
}

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/seaport.ts#L4351-L4367
function getSchema(schemaName) {
  const schemaName_ = schemaName || WyvernSchemaName.ERC721;
  const schema = schemas.filter((s) => s.name == schemaName_)[0];

  if (!schema) {
    throw new Error(
      `Trading for this asset (${schemaName_}) is not yet supported. Please contact us or check back later!`
    );
  }
  return schema;
}

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/seaport.ts#L3860-L3942
function getTimeParameters({
  expirationTimestamp = getMaxOrderExpirationTimestamp(),
  listingTimestamp,
  waitingForBestCounterOrder = false,
  isMatchingOrder = false,
}) {
  const maxExpirationDate = new Date();

  maxExpirationDate.setMonth(
    maxExpirationDate.getMonth() + MAX_EXPIRATION_MONTHS
  );

  const maxExpirationTimeStamp = Math.round(maxExpirationDate.getTime() / 1000);

  const minListingTimestamp = Math.round(Date.now() / 1000);

  if (!isMatchingOrder && expirationTimestamp === 0) {
    throw new Error("Expiration time cannot be 0");
  }
  if (listingTimestamp && listingTimestamp < minListingTimestamp) {
    throw new Error("Listing time cannot be in the past.");
  }
  if (listingTimestamp && listingTimestamp >= expirationTimestamp) {
    throw new Error("Listing time must be before the expiration time.");
  }

  if (waitingForBestCounterOrder && listingTimestamp) {
    throw new Error(`Cannot schedule an English auction for the future.`);
  }
  if (parseInt(expirationTimestamp.toString()) != expirationTimestamp) {
    throw new Error(`Expiration timestamp must be a whole number of seconds`);
  }
  if (expirationTimestamp > maxExpirationTimeStamp) {
    throw new Error("Expiration time must not exceed six months from now");
  }

  if (waitingForBestCounterOrder) {
    listingTimestamp = expirationTimestamp;
    // Expire one week from now, to ensure server can match it
    // Later, this will expire closer to the listingTime
    expirationTimestamp = expirationTimestamp + ORDER_MATCHING_LATENCY_SECONDS;

    // The minimum expiration time has to be at least fifteen minutes from now
    const minEnglishAuctionListingTimestamp =
      minListingTimestamp + MIN_EXPIRATION_MINUTES * 60;

    if (
      !isMatchingOrder &&
      listingTimestamp < minEnglishAuctionListingTimestamp
    ) {
      throw new Error(
        `Expiration time must be at least ${MIN_EXPIRATION_MINUTES} minutes from now`
      );
    }
  } else {
    // Small offset to account for latency
    listingTimestamp = listingTimestamp || Math.round(Date.now() / 1000 - 100);

    // The minimum expiration time has to be at least fifteen minutes from now
    const minExpirationTimestamp =
      listingTimestamp + MIN_EXPIRATION_MINUTES * 60;

    if (!isMatchingOrder && expirationTimestamp < minExpirationTimestamp) {
      throw new Error(
        `Expiration time must be at least ${MIN_EXPIRATION_MINUTES} minutes from the listing date`
      );
    }
  }

  return {
    listingTime: BigNumber.from(listingTimestamp),
    expirationTime: BigNumber.from(expirationTimestamp),
  };
}

function getMetadata(order, referrerAddress) {
  const referrer = referrerAddress || order.metadata.referrerAddress;
  if (referrer && isValidAddress(referrer)) {
    return referrer;
  }
  return undefined;
}

const correctGasAmount = (estimation) => {
  return Math.ceil(estimation * DEFAULT_GAS_INCREASE_FACTOR);
};

const getCurrentPrice = ({ wyvernExchangeContract, order }) =>
  wyvernExchangeContract.calculateCurrentPrice_(
    [
      order.exchange,
      order.maker,
      order.taker,
      order.feeRecipient,
      order.target,
      order.staticTarget,
      order.paymentToken,
    ],
    [
      order.makerRelayerFee,
      order.takerRelayerFee,
      order.makerProtocolFee,
      order.takerProtocolFee,
      order.basePrice,
      order.extra,
      order.listingTime,
      order.expirationTime,
      order.salt,
    ],
    order.feeMethod,
    order.side,
    order.saleKind,
    order.howToCall,
    order.calldata,
    order.replacementPattern,
    order.staticExtradata
  );

export function estimateCurrentPrice(
  order,
  secondsToBacktrack = 30,
  shouldRoundUp = true
) {
  let { basePrice, listingTime, expirationTime, extra } = order;
  const { side, takerRelayerFee, saleKind } = order;

  const now = BigNumber.from(Math.round(Date.now() / 1000)).sub(
    secondsToBacktrack
  );
  basePrice = BigNumber.from(basePrice);
  listingTime = BigNumber.from(listingTime);
  expirationTime = BigNumber.from(expirationTime);
  extra = BigNumber.from(extra);

  let exactPrice = basePrice;

  if (saleKind === 0) {
    // Do nothing, price is correct
  } else if (saleKind === 1) {
    const diff = extra
      .mul(now.sub(listingTime))
      .div(expirationTime.sub(listingTime));

    exactPrice =
      side == 1
        ? /* Sell-side - start price: basePrice. End price: basePrice - extra. */
          basePrice.sub(diff)
        : /* Buy-side - start price: basePrice. End price: basePrice + extra. */
          basePrice.add(diff);
  }

  // Add taker fee only for buyers
  if (side === 1 && !order.waitingForBestCounterOrder) {
    // Buyer fee increases sale price
    exactPrice = exactPrice.mul(+takerRelayerFee / 10000 + 1);
  }

  return exactPrice;
}

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/seaport.ts#L4244-L4255
async function getRequiredAmountForTakingSellOrder({
  wyvernExchangeContract,
  sell,
}) {
  const currentPrice = await getCurrentPrice({
    wyvernExchangeContract,
    order: sell,
  });
  const estimatedPrice = estimateCurrentPrice(sell);

  const maxPrice = currentPrice.gt(estimatedPrice)
    ? currentPrice
    : estimatedPrice;

  // TODO Why is this not always a big number?
  sell.takerRelayerFee = BigNumber.from(sell.takerRelayerFee);
  const feePercentage = sell.takerRelayerFee.div(INVERSE_BASIS_POINT);
  const fee = feePercentage.mul(maxPrice);
  return fee.add(maxPrice);
}

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/seaport.ts#L3133-L3246
export function makeMatchingOrder({
  order,
  accountAddress,
  recipientAddress,
  networkName,
}) {
  accountAddress = validateAndFormatWalletAddress(accountAddress);
  recipientAddress = validateAndFormatWalletAddress(recipientAddress);

  const computeOrderParams = () => {
    const shouldValidate =
      order.target === MerkleValidatorByNetwork[networkName];

    if ("asset" in order.metadata) {
      const schema = getSchema(order.metadata.schema);
      return order.side == OrderSide.Buy
        ? encodeSell(
            schema,
            order.metadata.asset,
            recipientAddress,
            shouldValidate ? order.target : undefined
          )
        : encodeBuy(
            schema,
            order.metadata.asset,
            recipientAddress,
            shouldValidate ? order.target : undefined
          );
    } else if ("bundle" in order.metadata) {
      throw new Error("Bundles not supported");
    } else {
      throw new Error("Invalid order metadata");
    }
  };

  const { target, calldata, replacementPattern } = computeOrderParams();
  const times = getTimeParameters({
    expirationTimestamp: 0,
    isMatchingOrder: true,
  });
  // Compat for matching buy orders that have fee recipient still on them
  const feeRecipient =
    order.feeRecipient == NULL_ADDRESS ? OPENSEA_FEE_RECIPIENT : NULL_ADDRESS;

  const matchingOrder = {
    exchange: order.exchange,
    maker: accountAddress,
    taker: order.maker,
    quantity: order.quantity,
    makerRelayerFee: order.makerRelayerFee,
    takerRelayerFee: order.takerRelayerFee,
    makerProtocolFee: order.makerProtocolFee,
    takerProtocolFee: order.takerProtocolFee,
    makerReferrerFee: order.makerReferrerFee,
    waitingForBestCounterOrder: false,
    feeMethod: order.feeMethod,
    feeRecipient,
    side: (order.side + 1) % 2,
    saleKind: SaleKind.FixedPrice,
    target,
    howToCall: order.howToCall,
    calldata,
    replacementPattern,
    staticTarget: NULL_ADDRESS,
    staticExtradata: "0x",
    paymentToken: order.paymentToken,
    basePrice: order.basePrice,
    extra: BigNumber.from(0),
    listingTime: times.listingTime,
    expirationTime: times.expirationTime,
    salt: generatePseudoRandomSalt(),
    metadata: order.metadata,
  };

  return matchingOrder;
}

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/seaport.ts#L3621-L3708
async function buyOrderValidationAndApprovals({
  order,
  wyvernExchangeContract,
}) {
  const tokenAddress = order.paymentToken;

  if (tokenAddress != NULL_ADDRESS) {
    throw new Error("ERC20 is not supported.");
  }

  // Check order formation
  const buyValid = await wyvernExchangeContract.validateOrderParameters_(
    [
      order.exchange,
      order.maker,
      order.taker,
      order.feeRecipient,
      order.target,
      order.staticTarget,
      order.paymentToken,
    ],
    [
      order.makerRelayerFee,
      order.takerRelayerFee,
      order.makerProtocolFee,
      order.takerProtocolFee,
      order.basePrice,
      order.extra,
      order.listingTime,
      order.expirationTime,
      order.salt,
    ],
    order.feeMethod,
    order.side,
    order.saleKind,
    order.howToCall,
    order.calldata,
    order.replacementPattern,
    order.staticExtradata
  );
  if (!buyValid) {
    console.error(order);
    throw new Error(
      `Failed to validate buy order parameters. Make sure you're on the right network!`
    );
  }
}

const validateOrder = ({ order, wyvernExchangeContract }) =>
  wyvernExchangeContract.validateOrder_(
    [
      order.exchange,
      order.maker,
      order.taker,
      order.feeRecipient,
      order.target,
      order.staticTarget,
      order.paymentToken,
    ],
    [
      order.makerRelayerFee,
      order.takerRelayerFee,
      order.makerProtocolFee,
      order.takerProtocolFee,
      order.basePrice,
      order.extra,
      order.listingTime,
      order.expirationTime,
      order.salt,
    ],
    order.feeMethod,
    order.side,
    order.saleKind,
    order.howToCall,
    order.calldata,
    order.replacementPattern,
    order.staticExtradata,
    order.v || 0,
    order.r || NULL_BLOCK_HASH,
    order.s || NULL_BLOCK_HASH
  );

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/seaport.ts#L3258-L3328
async function validateMatch(
  {
    buy,
    sell,
    accountAddress,
    shouldValidateBuy = false,
    shouldValidateSell = false,
    wyvernExchangeContract,
  },
  retries = 1
) {
  try {
    if (shouldValidateBuy) {
      const buyValid = await validateOrder({
        order: buy,
        wyvernExchangeContract,
      });
      console.log(`Buy order is valid: ${buyValid}`);

      if (!buyValid) {
        throw new Error(
          "Invalid buy order. It may have recently been removed. Please refresh the page and try again!"
        );
      }
    }

    if (shouldValidateSell) {
      const sellValid = await validateOrder({
        order: sell,
        wyvernExchangeContract,
      });
      console.log(`Sell order is valid: ${sellValid}`);

      if (!sellValid) {
        throw new Error(
          "Invalid sell order. It may have recently been removed. Please refresh the page and try again!"
        );
      }
    }

    const canMatch = await requireOrdersCanMatch({
      buy,
      sell,
      wyvernExchangeContract,
    });
    console.log(`Orders matching: ${canMatch}`);

    const calldataCanMatch = await requireOrderCalldataCanMatch({
      buy,
      sell,
      wyvernExchangeContract,
    });
    console.log(`Order calldata matching: ${calldataCanMatch}`);

    return true;
  } catch (error) {
    if (retries <= 0) {
      throw new Error(
        `Error matching this listing: ${
          error instanceof Error ? error.message : ""
        }. Please contact the maker or try again later!`
      );
    }
    await delay(500);
    return await validateMatch(
      {
        buy,
        sell,
        accountAddress,
        shouldValidateBuy,
        shouldValidateSell,
        wyvernExchangeContract,
      },
      retries - 1
    );
  }
}

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/seaport.ts#L4052-L4242
async function atomicMatch({
  wyvernExchangeContract,
  buy,
  sell,
  accountAddress,
  metadata = NULL_BLOCK_HASH,
}) {
  let value;
  let shouldValidateBuy = true;
  let shouldValidateSell = true;

  // Only check buy, but shouldn't matter as they should always be equal
  if (buy.maker.toLowerCase() == accountAddress.toLowerCase()) {
    // USER IS THE BUYER, only validate the sell order
    await buyOrderValidationAndApprovals({
      order: buy,
      wyvernExchangeContract,
    });
    shouldValidateBuy = false;

    // If using ETH to pay, set the value of the transaction to the current price
    if (buy.paymentToken == NULL_ADDRESS) {
      value = await getRequiredAmountForTakingSellOrder({
        sell,
        wyvernExchangeContract,
      });
    }
  } else {
    throw new Error("Unsupported atomicMatch scenario.");
  }

  await validateMatch({
    buy,
    sell,
    accountAddress,
    shouldValidateBuy,
    shouldValidateSell,
    wyvernExchangeContract,
  });

  let txHash;
  const txnData = { from: accountAddress, value };
  const args = [
    [
      buy.exchange,
      buy.maker,
      buy.taker,
      buy.feeRecipient,
      buy.target,
      buy.staticTarget,
      buy.paymentToken,
      sell.exchange,
      sell.maker,
      sell.taker,
      sell.feeRecipient,
      sell.target,
      sell.staticTarget,
      sell.paymentToken,
    ],
    [
      buy.makerRelayerFee,
      buy.takerRelayerFee,
      buy.makerProtocolFee,
      buy.takerProtocolFee,
      buy.basePrice,
      buy.extra,
      buy.listingTime,
      buy.expirationTime,
      buy.salt,
      sell.makerRelayerFee,
      sell.takerRelayerFee,
      sell.makerProtocolFee,
      sell.takerProtocolFee,
      sell.basePrice,
      sell.extra,
      sell.listingTime,
      sell.expirationTime,
      sell.salt,
    ],
    [
      buy.feeMethod,
      buy.side,
      buy.saleKind,
      buy.howToCall,
      sell.feeMethod,
      sell.side,
      sell.saleKind,
      sell.howToCall,
    ],
    buy.calldata,
    sell.calldata,
    buy.replacementPattern,
    sell.replacementPattern,
    buy.staticExtradata,
    sell.staticExtradata,
    [buy.v || 0, sell.v || 0],
    [
      buy.r || NULL_BLOCK_HASH,
      buy.s || NULL_BLOCK_HASH,
      sell.r || NULL_BLOCK_HASH,
      sell.s || NULL_BLOCK_HASH,
      metadata,
    ],
  ];

  // Estimate gas first
  try {
    // Typescript splat doesn't typecheck
    const gasEstimate = await wyvernExchangeContract.estimateGas.atomicMatch_(
      args[0],
      args[1],
      args[2],
      args[3],
      args[4],
      args[5],
      args[6],
      args[7],
      args[8],
      args[9],
      args[10],
      txnData
    );

    txnData.gasLimit = correctGasAmount(gasEstimate);
  } catch (error) {
    console.error(`Failed atomic match with args: `, args, error);
    throw new Error(
      `Oops, the Ethereum network rejected this transaction :( The OpenSea devs have been alerted, but this problem is typically due an item being locked or untransferrable. The exact error was "${
        error instanceof Error
          ? error.message.substr(0, MAX_ERROR_LENGTH)
          : "unknown"
      }..."`
    );
  }

  // Then do the transaction
  try {
    console.log(`Fulfilling order with gas set to ${txnData.gas}`);
    txHash = wyvernExchangeContract.atomicMatch_(
      args[0],
      args[1],
      args[2],
      args[3],
      args[4],
      args[5],
      args[6],
      args[7],
      args[8],
      args[9],
      args[10],
      txnData
    );
  } catch (error) {
    console.error(error);

    throw new Error(
      `Failed to authorize transaction: "${
        error instanceof Error && error.message ? error.message : "user denied"
      }..."`
    );
  }
  return txHash;
}

export function fulfillOrder({
  order,
  accountAddress,
  recipientAddress,
  referrerAddress,
  wyvernExchangeContract,
  networkName,
}) {
  const matchingOrder = makeMatchingOrder({
    order,
    accountAddress,
    recipientAddress: recipientAddress || accountAddress,
    networkName,
  });

  const { buy, sell } = assignOrdersToSides(order, matchingOrder);
  const metadata = getMetadata(order, referrerAddress);

  return atomicMatch({
    buy,
    sell,
    accountAddress,
    metadata,
    wyvernExchangeContract,
    networkName,
  });
}
