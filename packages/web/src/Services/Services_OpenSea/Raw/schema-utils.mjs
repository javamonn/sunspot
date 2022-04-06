import * as ethABI from "ethereumjs-abi";
import { FunctionInputKind } from "./constants.mjs";

// https://github.com/ProjectOpenSea/wyvern-js/blob/80fec352a4307a4ff3e27a5a47aa8642288a71f1/src/wyvernProtocol.ts#L370-L392
const generateDefaultValue = (type) => {
  switch (type) {
    case "address":
    case "bytes20":
      /* Null address is sometimes checked in transfer calls. */
      // But we need to use 0x000 because bitwise XOR won't work if there's a 0 in the actual address, since it will be replaced as 1 OR 0 = 1
      return "0x0000000000000000000000000000000000000000";
    case "bytes32":
      return "0x0000000000000000000000000000000000000000000000000000000000000000";
    case "bool":
      return false;
    case "int":
    case "uint":
    case "uint8":
    case "uint16":
    case "uint32":
    case "uint64":
    case "uint256":
      return 0;
    default:
      throw new Error("Default value not yet implemented for type: " + type);
  }
};

// https://github.com/ProjectOpenSea/wyvern-js/blob/80fec352a4307a4ff3e27a5a47aa8642288a71f1/src/wyvernProtocol.ts#L204-L253
const encodeReplacementPattern = (
  abi,
  replaceKind = FunctionInputKind.Replaceable,
  encodeToBytes = true
) => {
  const output = [];
  const data = [];
  const dynamicOffset = abi.inputs.reduce((len, { type }) => {
    const match = type.match(/\[(.+)\]$/);
    return len + (match ? parseInt(match[1], 10) * 32 : 32);
  }, 0);
  abi.inputs
    .map(({ kind, type, value }) => ({
      bitmask: kind === replaceKind ? 255 : 0,
      type: ethABI.elementaryName(type),
      value: value !== undefined ? value : generateDefaultValue(type),
    }))
    .reduce((offset, { bitmask, type, value }) => {
      // The 0xff bytes in the mask select the replacement bytes. All other bytes are 0x00.
      const cur = Buffer.alloc(ethABI.encodeSingle(type, value).length).fill(
        bitmask
      );
      if (ethABI.isDynamic(type)) {
        if (bitmask) {
          throw new Error(
            "Replacement is not supported for dynamic parameters."
          );
        }
        output.push(
          Buffer.alloc(ethABI.encodeSingle("uint256", dynamicOffset).length)
        );
        data.push(cur);
        return offset + cur.length;
      }
      output.push(cur);
      return offset;
    }, dynamicOffset);
  // 4 initial bytes of 0x00 for the method hash.
  const methodIdMask = Buffer.alloc(4);
  const mask = Buffer.concat([
    methodIdMask,
    Buffer.concat(output.concat(data)),
  ]);
  return encodeToBytes
    ? `0x${mask.toString("hex")}`
    : mask.map((b) => (b ? 1 : 0)).join("");
};

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/utils/schema.ts#L36-L48
const encodeCall = (abi, parameters) => {
  const inputTypes = abi.inputs.map((i) => i.type);
  return (
    "0x" +
    Buffer.concat([
      ethABI.methodID(abi.name, inputTypes),
      ethABI.rawEncode(inputTypes, parameters),
    ]).toString("hex")
  );
};

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/utils/schema.ts#L199-L212
const encodeDefaultCall = (abi, address) => {
  const parameters = abi.inputs.map((input) => {
    switch (input.kind) {
      case FunctionInputKind.Replaceable:
        return generateDefaultValue(input.type);
      case FunctionInputKind.Owner:
        return address;
      case FunctionInputKind.Asset:
      default:
        return input.value;
    }
  });
  return encodeCall(abi, parameters);
};

// https://github.com/ProjectOpenSea/opensea-js/blob/ee89fd790da620cb07e92499a878b8b8fbfff639/src/utils/schema.ts#L50-L65
export const encodeSell = (schema, asset, address, validatorAddress) => {
  const transfer =
    validatorAddress && schema.functions.checkAndTransfer
      ? schema.functions.checkAndTransfer(asset, validatorAddress)
      : schema.functions.transfer(asset);
  return {
    target: transfer.target,
    calldata: encodeDefaultCall(transfer, address),
    replacementPattern: encodeReplacementPattern(transfer),
  };
};

export const encodeBuy = (schema, asset, address, validatorAddress) => {
  const transfer =
    validatorAddress && schema.functions.checkAndTransfer
      ? schema.functions.checkAndTransfer(asset, validatorAddress)
      : schema.functions.transfer(asset);
  const replaceables = transfer.inputs.filter(
    (i) => i.kind === FunctionInputKind.Replaceable
  );
  const ownerInputs = transfer.inputs.filter(
    (i) => i.kind === FunctionInputKind.Owner
  );

  // Validate
  if (replaceables.length !== 1) {
    throw new Error(
      "Only 1 input can match transfer destination, but instead " +
        replaceables.length +
        " did"
    );
  }

  // Compute calldata
  const parameters = transfer.inputs.map((input) => {
    switch (input.kind) {
      case FunctionInputKind.Replaceable:
        return address;
      case FunctionInputKind.Owner:
        return generateDefaultValue(input.type);
      default:
        try {
          return input.value.toString();
        } catch (e) {
          console.error(schema);
          console.error(asset);
          throw e;
        }
    }
  });
  const calldata = encodeCall(transfer, parameters);

  // Compute replacement pattern
  let replacementPattern = "0x";
  if (ownerInputs.length > 0) {
    replacementPattern = encodeReplacementPattern(
      transfer,
      FunctionInputKind.Owner
    );
  }

  return {
    target: transfer.target,
    calldata,
    replacementPattern,
  };
};
