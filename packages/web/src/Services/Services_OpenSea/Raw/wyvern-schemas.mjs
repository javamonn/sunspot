import { AbiType } from "ethereum-types";
import { StateMutability, FunctionInputKind } from "./constants.mjs";

export const ERC721Schema = {
  version: 2,
  deploymentBlock: 0, // Not indexed (for now; need asset-specific indexing strategy)
  name: "ERC721",
  description: "Items conforming to the ERC721 spec, using transferFrom.",
  thumbnail: "https://opensea.io/static/images/opensea-icon.png",
  website: "http://erc721.org/",
  fields: [
    { name: "ID", type: "uint256", description: "Asset Token ID" },
    { name: "Address", type: "address", description: "Asset Contract Address" },
  ],
  assetFromFields: (fields) => ({
    id: fields.ID,
    address: fields.Address,
  }),
  assetToFields: (asset) => ({
    ID: asset.id,
    Address: asset.address,
  }),
  formatter: async (asset) => {
    return {
      title: "ERC721 Asset: Token ID " + asset.id + " at " + asset.address,
      description: "",
      url: "",
      thumbnail: "",
      properties: [],
    };
  },
  functions: {
    transfer: (asset) => ({
      type: AbiType.Function,
      name: "transferFrom",
      payable: false,
      constant: false,
      stateMutability: StateMutability.Nonpayable,
      target: asset.address,
      inputs: [
        { kind: FunctionInputKind.Owner, name: "_from", type: "address" },
        { kind: FunctionInputKind.Replaceable, name: "_to", type: "address" },
        {
          kind: FunctionInputKind.Asset,
          name: "_tokenId",
          type: "uint256",
          value: asset.id,
        },
      ],
      outputs: [],
    }),
    checkAndTransfer: (asset, validatorAddress, merkle) => ({
      type: AbiType.Function,
      name: "matchERC721UsingCriteria",
      payable: false,
      constant: false,
      stateMutability: StateMutability.Nonpayable,
      target: validatorAddress,
      inputs: [
        { kind: FunctionInputKind.Owner, name: "from", type: "address" },
        { kind: FunctionInputKind.Replaceable, name: "to", type: "address" },
        {
          kind: FunctionInputKind.Asset,
          name: "token",
          type: "address",
          value: asset.address,
        },
        {
          kind: FunctionInputKind.Asset,
          name: "tokenId",
          type: "uint256",
          value: asset.id,
        },
        {
          kind: FunctionInputKind.Data,
          name: "root",
          type: "bytes32",
          value: merkle ? merkle.root : "",
        },
        {
          kind: FunctionInputKind.Data,
          name: "proof",
          type: "bytes32[]",
          value: merkle ? merkle.proof : "[]",
        },
      ],
      outputs: [],
    }),
    ownerOf: (asset) => ({
      type: AbiType.Function,
      name: "ownerOf",
      payable: false,
      constant: true,
      stateMutability: StateMutability.View,
      target: asset.address,
      inputs: [
        {
          kind: FunctionInputKind.Asset,
          name: "_tokenId",
          type: "uint256",
          value: asset.id,
        },
      ],
      outputs: [
        { kind: FunctionOutputKind.Owner, name: "owner", type: "address" },
      ],
    }),
    assetsOfOwnerByIndex: [],
  },
  events: {
    transfer: [],
  },
  hash: (asset) => asset.address + "-" + asset.id,
};

// https://github.com/ProjectOpenSea/wyvern-schemas/blob/b829f3e93b0332f280f547875b31a9a3c7ae092a/src/schemas/ERC1155/index.ts#L16-L149
export const ERC1155Schema = {
  version: 1,
  deploymentBlock: 0, // Not indexed (for now; need asset-specific indexing strategy)
  name: "ERC1155",
  description: "Items conforming to the ERC1155 spec, using transferFrom.",
  thumbnail: "https://opensea.io/static/images/opensea-icon.png",
  website: "https://github.com/ethereum/eips/issues/1155",
  fields: [
    { name: "ID", type: "uint256", description: "Asset Token ID" },
    { name: "Address", type: "address", description: "Asset Contract Address" },
    { name: "Quantity", type: "uint256", description: "Quantity to transfer" },
  ],
  assetFromFields: (fields) => ({
    id: fields.ID,
    address: fields.Address,
    quantity: fields.Quantity,
  }),
  assetToFields: (asset) => ({
    ID: asset.id,
    Address: asset.address,
    Quantity: asset.quantity,
  }),
  formatter: async (asset) => {
    return {
      title: "ERC1155 Asset: Token ID " + asset.id + " at " + asset.address,
      description: "Trading " + asset.quantity.toString(),
      url: "",
      thumbnail: "",
      properties: [],
    };
  },
  functions: {
    transfer: (asset) => ({
      type: AbiType.Function,
      name: "safeTransferFrom",
      payable: false,
      constant: false,
      stateMutability: StateMutability.Nonpayable,
      target: asset.address,
      inputs: [
        { kind: FunctionInputKind.Owner, name: "_from", type: "address" },
        { kind: FunctionInputKind.Replaceable, name: "_to", type: "address" },
        {
          kind: FunctionInputKind.Asset,
          name: "_id",
          type: "uint256",
          value: asset.id,
        },
        {
          kind: FunctionInputKind.Count,
          name: "_value",
          type: "uint256",
          value: asset.quantity,
        },
        {
          kind: FunctionInputKind.Data,
          name: "_data",
          type: "bytes",
          value: "",
        },
      ],
      outputs: [],
    }),
    checkAndTransfer: (asset, validatorAddress, merkle) => ({
      type: AbiType.Function,
      name: "matchERC1155UsingCriteria",
      payable: false,
      constant: false,
      stateMutability: StateMutability.Nonpayable,
      target: validatorAddress,
      inputs: [
        { kind: FunctionInputKind.Owner, name: "from", type: "address" },
        { kind: FunctionInputKind.Replaceable, name: "to", type: "address" },
        {
          kind: FunctionInputKind.Asset,
          name: "token",
          type: "address",
          value: asset.address,
        },
        {
          kind: FunctionInputKind.Asset,
          name: "tokenId",
          type: "uint256",
          value: asset.id,
        },
        {
          kind: FunctionInputKind.Count,
          name: "amount",
          type: "uint256",
          value: asset.quantity,
        },
        {
          kind: FunctionInputKind.Data,
          name: "root",
          type: "bytes32",
          value: merkle ? merkle.root : "",
        },
        {
          kind: FunctionInputKind.Data,
          name: "proof",
          type: "bytes32[]",
          value: merkle ? merkle.proof : "[]",
        },
      ],
      outputs: [],
    }),
    countOf: (asset) => ({
      type: AbiType.Function,
      name: "balanceOf",
      payable: false,
      constant: true,
      stateMutability: StateMutability.View,
      target: asset.address,
      inputs: [
        { kind: FunctionInputKind.Owner, name: "_owner", type: "address" },
        {
          kind: FunctionInputKind.Asset,
          name: "_id",
          type: "uint256",
          value: asset.id,
        },
      ],
      outputs: [
        { kind: FunctionOutputKind.Count, name: "balance", type: "uint" },
      ],
      assetFromOutputs: (outputs) => outputs.balance,
    }),
    assetsOfOwnerByIndex: [],
  },
  events: {
    transfer: [],
  },
  hash: (asset) => asset.address + "-" + asset.id,
};

export const schemas = [ERC721Schema, ERC1155Schema];
