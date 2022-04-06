import abi from "./wyvern-exchange-abi.json";
import { ethers } from "ethers";
const address = "0x7f268357a8c2552623316e2562d90e642bb538e5";

export const make = ({ web3 }) => new ethers.Contract(address, abi, web3);
