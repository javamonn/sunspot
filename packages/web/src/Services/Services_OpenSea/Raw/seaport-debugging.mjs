import { OrderSide, NULL_ADDRESS } from "./constants.mjs";

const canSettleOrder = (listingTime, expirationTime) => {
  const now = Math.round(Date.now() / 1000);
  return listingTime < now && (expirationTime === 0 || now < expirationTime);
};

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/debugging.ts#L40-L169
export async function requireOrdersCanMatch({
  buy,
  sell,
  wyvernExchangeContract,
}) {
  const result = await wyvernExchangeContract.ordersCanMatch_(
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
    sell.staticExtradata
  );

  if (result) {
    return;
  }

  if (!(+buy.side == +OrderSide.Buy && +sell.side == +OrderSide.Sell)) {
    throw new Error("Must be opposite-side");
  }

  if (!(buy.feeMethod == sell.feeMethod)) {
    throw new Error("Must use same fee method");
  }

  if (!(buy.paymentToken == sell.paymentToken)) {
    throw new Error("Must use same payment token");
  }

  if (!(sell.taker == NULL_ADDRESS || sell.taker == buy.maker)) {
    throw new Error("Sell taker must be null or matching buy maker");
  }

  if (!(buy.taker == NULL_ADDRESS || buy.taker == sell.maker)) {
    throw new Error("Buy taker must be null or matching sell maker");
  }

  if (
    !(
      (sell.feeRecipient == NULL_ADDRESS && buy.feeRecipient != NULL_ADDRESS) ||
      (sell.feeRecipient != NULL_ADDRESS && buy.feeRecipient == NULL_ADDRESS)
    )
  ) {
    throw new Error("One order must be maker and the other must be taker");
  }

  if (!(buy.target == sell.target)) {
    throw new Error("Must match target");
  }

  if (!(buy.howToCall == sell.howToCall)) {
    throw new Error("Must match howToCall");
  }

  if (!canSettleOrder(+buy.listingTime, +buy.expirationTime)) {
    throw new Error(`Buy-side order is set in the future or expired`);
  }

  if (!(+sell.listingTime, +sell.expirationTime)) {
    throw new Error(`Sell-side order is set in the future or expired`);
  }

  // Handle default, which is likely now() being diff than local time
  throw new Error(
    "Error creating your order. Check that your system clock is set to the current date and time before you try again."
  );
}

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/debugging.ts#L176-L192
export async function requireOrderCalldataCanMatch({
  buy,
  sell,
  wyvernExchangeContract,
}) {
  const result = await wyvernExchangeContract.orderCalldataCanMatch(
    buy.calldata,
    buy.replacementPattern,
    sell.calldata,
    sell.replacementPattern
  );
  if (result) {
    return;
  }
  throw new Error("Unable to match offer data with auction data.");
}
