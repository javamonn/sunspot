// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

contract WyvernExchangeMock {
    function atomicMatch_(
        address[14] memory _addrs,
        uint256[18] memory _uints,
        uint8[8] memory _feeMethodsSidesKindsHowToCalls,
        bytes memory _calldataBuy,
        bytes memory _calldataSell,
        bytes memory _replacementPatternBuy,
        bytes memory _replacementPatternSell,
        bytes memory _staticExtradataBuy,
        bytes memory _staticExtradataSell,
        uint8[2] memory _vs,
        bytes32[5] memory _rssMetadata
    ) public payable {
        (_addrs);
        (_uints);
        (_feeMethodsSidesKindsHowToCalls);
        (_calldataBuy);
        (_calldataSell);
        (_replacementPatternBuy);
        (_replacementPatternSell);
        (_staticExtradataBuy);
        (_staticExtradataSell);
        (_vs);
        (_rssMetadata);
    }
}
