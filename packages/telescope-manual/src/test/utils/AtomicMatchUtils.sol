// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

library AtomicMatchUtils {
    function wyvernExchangeData(bytes4 selector)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodeWithSelector(
                selector,
                [
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0)
                ],
                [
                    uint256(0),
                    uint256(0),
                    uint256(0),
                    uint256(0),
                    uint256(0),
                    uint256(0),
                    uint256(0),
                    uint256(0),
                    uint256(0),
                    uint256(0),
                    uint256(0),
                    uint256(0),
                    uint256(0),
                    uint256(0),
                    uint256(0),
                    uint256(0),
                    uint256(0),
                    uint256(0)
                ],
                [0, 0, 0, 0, 0, 0, 0, 0],
                "",
                "",
                "",
                "",
                "",
                "",
                [0, 0],
                [
                    bytes32(""),
                    bytes32(""),
                    bytes32(""),
                    bytes32(""),
                    bytes32("")
                ]
            );
    }
}
