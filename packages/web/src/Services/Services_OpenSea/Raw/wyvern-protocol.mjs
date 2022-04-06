import { BigNumber, utils } from "ethers";

// https://github.com/ProjectOpenSea/wyvern-js/blob/80fec352a4307a4ff3e27a5a47aa8642288a71f1/src/wyvernProtocol.ts#L114-L125
export function generatePseudoRandomSalt() {
  return BigNumber.from(utils.randomBytes(32))
}
