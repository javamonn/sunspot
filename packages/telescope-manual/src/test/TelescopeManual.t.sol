// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import {Test} from "./utils/Test.sol";
import {atomicMatchSig} from "./fixtures/WyvernExchangeFixtures.sol";
import "./utils/WyvernExchangeRevertMock.sol";
import "../TelescopeManual.sol";

contract TelescopeManualTest is Test {
    TelescopeManual telescope;

    function setUp() public override {
        telescope = new TelescopeManual(address(1), address(2));
    }

    function atomicMatchData() internal pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                atomicMatchSig,
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

    function testAtomicMatch() public {
        bytes memory data = atomicMatchData();
        cheats.expectCall(telescope.wyvernExchange(), data);

        telescope.atomicMatch(0, 0, data);
    }

    function testFailWhenWyvernExchangeReverts() public {
        WyvernExchangeRevertMock wyvernExchangeMock = new WyvernExchangeRevertMock();
        TelescopeManual telescopeWithMock = new TelescopeManual(
            address(2),
            address(wyvernExchangeMock)
        );

        telescopeWithMock.atomicMatch(0, 0, atomicMatchData());
    }

    function testSetEnabled() public {
        telescope.setEnabled(false);
        assertTrue(telescope.enabled() == false);
    }

    function testSetFeeArbiter() public {
        telescope.setFeeArbiter(address(3));
        assertEq(telescope.feeArbiter(), address(3));
    }

    function testCannotAtomicMatchWhenNotEnabled() public {
        telescope.setEnabled(false);
        cheats.expectRevert(TelescopeManual.Disabled.selector);

        telescope.atomicMatch(0, 0, atomicMatchData());
    }

    function testCannotSetEnabledWhenNotOwner() public {
        cheats.startPrank(address(4));
        cheats.expectRevert(bytes("Ownable: caller is not the owner"));

        telescope.setEnabled(false);

        cheats.stopPrank();
    }

    function testCannotSetFeeArbiterWhenNotOwner() public {
        cheats.startPrank(address(4));
        cheats.expectRevert(bytes("Ownable: caller is not the owner"));

        telescope.setFeeArbiter(address(4));

        cheats.stopPrank();
    }
}
