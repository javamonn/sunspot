import { MAX_EXPIRATION_MONTHS, OrderSide } from "./constants.mjs";

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/utils/utils.ts#L1058-L1066
export const getMaxOrderExpirationTimestamp = () => {
  const maxExpirationDate = new Date();

  maxExpirationDate.setDate(
    maxExpirationDate.getDate() + MAX_EXPIRATION_MONTHS
  );

  return Math.round(maxExpirationDate.getTime() / 1000);
};

export function assignOrdersToSides(order, matchingOrder) {
  const isSellOrder = order.side == OrderSide.Sell;

  let buy;
  let sell;
  if (!isSellOrder) {
    buy = order;
    sell = {
      ...matchingOrder,
      v: buy.v,
      r: buy.r,
      s: buy.s,
    };
  } else {
    sell = order;
    buy = {
      ...matchingOrder,
      v: sell.v,
      r: sell.r,
      s: sell.s,
    };
  }

  return { buy, sell };
}

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/utils/utils.ts#L997-L999
export function delay(ms) {
  return new Promise((res) => setTimeout(res, ms));
}
