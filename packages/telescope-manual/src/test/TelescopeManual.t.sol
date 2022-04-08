// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import { Test } from "./utils/Test.sol";
import { atomicMatchData } from "./fixtures/WyvernExchangeFixtures.sol";
import "../TelescopeManual.sol";

contract TelescopeManualTest is Test {
  TelescopeManual telescope;

  function setUp() public override {
    telescope = new TelescopeManual(address(0xBEEF));
  }

  function testAtomicMatch() public {
    cheats.expectCall(telescope.wyvernExchange(), atomicMatchData);

    telescope.atomicMatch(0 wei, atomicMatchData);
  }

  function testSetEnabled() public {
    telescope.setEnabled(false);
    assertTrue(telescope.enabled() == false);
  }

  function testSetFeeArbiter() public {
    telescope.setFeeArbiter(address(0xABE));
    assertEq(telescope.feeArbiter(), address(0xABE));
  }

  function testCannotAtomicMatchWhenNotEnabled() public {
    telescope.setEnabled(false);
    cheats.expectRevert(TelescopeManual.Disabled.selector);

    telescope.atomicMatch(0 wei, atomicMatchData);
  }

  function testCannotSetEnabledWhenNotOwner() public {
    cheats.startPrank(address(0xBAD));
    cheats.expectRevert(bytes("Ownable: caller is not the owner"));

    telescope.setEnabled(false);

    cheats.stopPrank();
  }

  function testCannotSetFeeArbiterWhenNotOwner() public {
    cheats.startPrank(address(0xBAD));
    cheats.expectRevert(bytes("Ownable: caller is not the owner"));

    telescope.setFeeArbiter(address(0xABE));

    cheats.stopPrank();
  }
}
