// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

contract TelescopeManual is Ownable, ReentrancyGuard {
    string public name = "sunspot.gg telescope (manual)";

    address public feeArbiter;
    address public wyvernExchange;
    bool public enabled;

    error Disabled();

    modifier isEnabled() {
        if (!enabled) {
            revert Disabled();
        }
        _;
    }

    constructor(address _feeArbiter, address _wyvernExchange) {
        feeArbiter = _feeArbiter;
        wyvernExchange = _wyvernExchange;
        enabled = true;
    }

    function atomicMatch(
        // bytes32 proof,
        // bytes32 wyvernExchangeSellOrderHash,
        uint256 feeValue,
        uint256 wyvernExchangeValue,
        bytes memory wyvernExchangeData
    ) external payable nonReentrant isEnabled {
        // check proof (caller-fee-wyvernExchangeSellOrderHash)
        // check value = feeValue + wyvernExchangeValue

        // transfer fee to feeArbiter

        // execute trade
        (bool success, bytes memory returnData) = wyvernExchange.call{
            value: wyvernExchangeValue
        }(wyvernExchangeData);

        // check and forward error if set
        if (!success) {
            if (returnData.length == 0) revert();
            assembly {
                revert(add(32, returnData), mload(returnData))
            }
        }
    }

    function setFeeArbiter(address _feeArbiter) external onlyOwner {
        feeArbiter = _feeArbiter;
    }

    function setEnabled(bool _enabled) external onlyOwner {
        enabled = _enabled;
    }
}
