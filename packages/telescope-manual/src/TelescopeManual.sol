// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";


contract TelescopeManual is Ownable, ReentrancyGuard {
  string public name = "sunspot.gg telescope (manual)";

  address public feeArbiter;
  address public wyvernExchange = address(0x7Be8076f4EA4A4AD08075C2508e481d6C946D12b);
  bool public enabled;

  error Disabled();

  modifier isEnabled() {
    if (!enabled) {
      revert Disabled();
    }
    _;
  }

  constructor(address _feeArbiter) {
    feeArbiter = _feeArbiter;
    enabled = true;
  }

  function atomicMatch(
    // bytes32 proof,
    // uint256 feeValue,
    // bytes32 wyvernExchangeSellOrderHash,
    uint256 wyvernExchangeValue,
    bytes memory wyvernExchangeData
  ) external payable nonReentrant isEnabled {
    // check proof (caller-fee-wyvernExchangeSellOrderHash)
    // check value = feeValue + wyvernExchangeValue

    // execute trade
    wyvernExchange.call{ value: wyvernExchangeValue }(wyvernExchangeData);
  }

  function setFeeArbiter(address _feeArbiter) external onlyOwner {
    feeArbiter = _feeArbiter;
  }

  function setEnabled(bool _enabled) external onlyOwner {
    enabled = _enabled;
  }
}
