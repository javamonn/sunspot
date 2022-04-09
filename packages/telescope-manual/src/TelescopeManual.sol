// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract TelescopeManual is Ownable, ReentrancyGuard {
    string public name = "sunspot.gg telescope (manual)";

    address payable public feeArbiter;
    address payable public wyvernExchange;
    bool public enabled;

    error Disabled();
    error InvalidValue();
    error InvalidSignature();

    modifier isEnabled() {
        if (!enabled) {
            revert Disabled();
        }
        _;
    }

    modifier hasCorrectValue(
        uint256 value,
        uint256 feeValue,
        uint256 wyvernExchangeValue
    ) {
        if (value != feeValue + wyvernExchangeValue) {
            revert InvalidValue();
        }
        _;
    }

    modifier hasFeeArbiterSignature(bytes32 hash, bytes memory signature) {
        (address signingAddress, ) = ECDSA.tryRecover(hash, signature);
        if (signingAddress != feeArbiter) {
            revert InvalidSignature();
        }

        _;
    }

    constructor(address payable _feeArbiter, address payable _wyvernExchange) {
        feeArbiter = _feeArbiter;
        wyvernExchange = _wyvernExchange;
        enabled = true;
    }

    function atomicMatchHash(
        uint256 feeValue,
        uint256 wyvernExchangeValue,
        bytes memory wyvernExchangeData
    ) public returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    feeValue,
                    wyvernExchangeValue,
                    wyvernExchangeData
                )
            );
    }

    function checkedCall(
        address payable addr,
        uint256 value,
        bytes memory data
    ) internal {
        (bool success, bytes memory returnData) = addr.call{value: value}(data);
        if (!success) {
            if (returnData.length == 0) revert();
            assembly {
                // forward error from call
                revert(add(32, returnData), mload(returnData))
            }
        }
    }

    function atomicMatch(
        uint256 feeValue,
        uint256 wyvernExchangeValue,
        bytes memory wyvernExchangeData,
        bytes memory signature
    )
        external
        payable
        nonReentrant
        isEnabled
        hasCorrectValue(msg.value, feeValue, wyvernExchangeValue)
        hasFeeArbiterSignature(
            atomicMatchHash(feeValue, wyvernExchangeValue, wyvernExchangeData),
            signature
        )
    {
        // execute trade
        checkedCall(wyvernExchange, wyvernExchangeValue, wyvernExchangeData);

        // transfer fee to feeArbiter
        checkedCall(feeArbiter, feeValue, "");
    }

    function setFeeArbiter(address payable _feeArbiter) external onlyOwner {
        feeArbiter = _feeArbiter;
    }

    function setEnabled(bool _enabled) external onlyOwner {
        enabled = _enabled;
    }
}
