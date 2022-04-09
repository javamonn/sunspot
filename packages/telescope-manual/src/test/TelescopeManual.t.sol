// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import {Test} from "./utils/Test.sol";

import "./utils/WyvernExchangeRevertMock.sol";
import "./utils/WyvernExchangeMock.sol";
import "./utils/AtomicMatchUtils.sol";

import "../TelescopeManual.sol";

contract TelescopeManualTest is Test {
    function setUp() public override {}

    function makeSignature(uint248 pkey, bytes32 digest)
        internal
        returns (bytes memory)
    {
        (uint8 v, bytes32 r, bytes32 s) = cheats.sign(pkey, digest);
        return abi.encodePacked(r, s, v);
    }

    function makeTelescopeWithWyvernExchangeMock(address payable feeArbiter)
        internal
        returns (TelescopeManual)
    {
        WyvernExchangeMock wyvernExchangeMock = new WyvernExchangeMock();
        return
            new TelescopeManual(
                feeArbiter,
                payable(address(wyvernExchangeMock))
            );
    }

    function makeTelescopeWithWyvernExchangeRevertMock(
        address payable feeArbiter
    ) internal returns (TelescopeManual) {
        WyvernExchangeRevertMock wyvernExchangeRevertMock = new WyvernExchangeRevertMock();
        return
            new TelescopeManual(
                feeArbiter,
                payable(address(wyvernExchangeRevertMock))
            );
    }

    function testAtomicMatch(address user, uint248 feeArbiterPkey) public {
        cheats.assume(user != address(0));
        cheats.assume(feeArbiterPkey != 0);

        TelescopeManual telescope = makeTelescopeWithWyvernExchangeMock(
            payable(cheats.addr(feeArbiterPkey))
        );
        bytes memory wyvernExchangeData = AtomicMatchUtils.wyvernExchangeData(
            WyvernExchangeMock.atomicMatch_.selector
        );

        cheats.startPrank(user);
        cheats.expectCall(telescope.wyvernExchange(), wyvernExchangeData);
        cheats.expectCall(telescope.feeArbiter(), "");

        telescope.atomicMatch(
            0,
            0,
            wyvernExchangeData,
            makeSignature(
                feeArbiterPkey,
                telescope.atomicMatchHash(0, 0, wyvernExchangeData)
            )
        );

        cheats.stopPrank();
    }

    function testAtomicMatchSendsCorrectValue(
        address user,
        uint248 feeArbiterPkey,
        uint96 feeValue,
        uint96 wyvernExchangeValue
    ) public {
        cheats.assume(user != address(0));
        cheats.assume(feeArbiterPkey != 0);

        TelescopeManual telescope = makeTelescopeWithWyvernExchangeMock(
            payable(cheats.addr(feeArbiterPkey))
        );
        uint256 value = uint256(feeValue) + wyvernExchangeValue;
        bytes memory wyvernExchangeData = AtomicMatchUtils.wyvernExchangeData(
            WyvernExchangeMock.atomicMatch_.selector
        );

        cheats.deal(user, value);
        cheats.startPrank(user);

        telescope.atomicMatch{value: value}(
            feeValue,
            wyvernExchangeValue,
            wyvernExchangeData,
            makeSignature(
                feeArbiterPkey,
                telescope.atomicMatchHash(
                    feeValue,
                    wyvernExchangeValue,
                    wyvernExchangeData
                )
            )
        );

        assertEq(telescope.feeArbiter().balance, feeValue);
        assertEq(telescope.wyvernExchange().balance, wyvernExchangeValue);

        cheats.stopPrank();
    }

    function testFailWhenWyvernExchangeReverts(
        address user,
        uint248 feeArbiterPkey,
        uint96 feeValue,
        uint96 wyvernExchangeValue
    ) public {
        cheats.assume(user != address(0));
        cheats.assume(feeArbiterPkey != 0);

        TelescopeManual telescope = makeTelescopeWithWyvernExchangeRevertMock(
            payable(cheats.addr(feeArbiterPkey))
        );
        uint256 value = uint256(feeValue) + wyvernExchangeValue;
        cheats.startPrank(user);
        cheats.deal(user, value);
        bytes memory wyvernExchangeData = AtomicMatchUtils.wyvernExchangeData(
            WyvernExchangeRevertMock.atomicMatch_.selector
        );

        telescope.atomicMatch{value: value}(
            feeValue,
            wyvernExchangeValue,
            wyvernExchangeData,
            makeSignature(
                feeArbiterPkey,
                telescope.atomicMatchHash(
                    feeValue,
                    wyvernExchangeValue,
                    wyvernExchangeData
                )
            )
        );

        cheats.stopPrank();
    }

    function testCannotAtomicMatchWhenInvalidValueTooMuch(
        uint248 feeArbiterPkey,
        address user,
        uint256 value,
        uint96 feeValue,
        uint96 wyvernExchangeValue
    ) public {
        cheats.assume(user != address(0));
        cheats.assume(feeArbiterPkey != 0);
        cheats.assume(value > uint256(feeValue) + wyvernExchangeValue);

        cheats.deal(user, value);

        TelescopeManual telescope = makeTelescopeWithWyvernExchangeMock(
            payable(cheats.addr(feeArbiterPkey))
        );
        bytes memory wyvernExchangeData = AtomicMatchUtils.wyvernExchangeData(
            WyvernExchangeMock.atomicMatch_.selector
        );
        bytes memory signature = makeSignature(
            feeArbiterPkey,
            telescope.atomicMatchHash(
                feeValue,
                wyvernExchangeValue,
                wyvernExchangeData
            )
        );

        cheats.startPrank(user);
        cheats.expectRevert(TelescopeManual.InvalidValue.selector);
        telescope.atomicMatch{value: value}(
            feeValue,
            wyvernExchangeValue,
            wyvernExchangeData,
            signature
        );

        cheats.stopPrank();
    }

    function testCannotAtomicMatchWhenInvalidValueNotEnough(
        uint248 feeArbiterPkey,
        address user,
        uint256 value,
        uint96 feeValue,
        uint96 wyvernExchangeValue
    ) public {
        cheats.assume(user != address(0));
        cheats.assume(feeArbiterPkey != 0);
        cheats.assume(value < uint256(feeValue) + wyvernExchangeValue);

        cheats.deal(user, value);

        TelescopeManual telescope = makeTelescopeWithWyvernExchangeMock(
            payable(cheats.addr(feeArbiterPkey))
        );
        bytes memory wyvernExchangeData = AtomicMatchUtils.wyvernExchangeData(
            WyvernExchangeMock.atomicMatch_.selector
        );
        bytes memory signature = makeSignature(
            feeArbiterPkey,
            telescope.atomicMatchHash(
                feeValue,
                wyvernExchangeValue,
                wyvernExchangeData
            )
        );

        cheats.startPrank(user);
        cheats.expectRevert(TelescopeManual.InvalidValue.selector);
        telescope.atomicMatch{value: value}(
            feeValue,
            wyvernExchangeValue,
            wyvernExchangeData,
            signature
        );

        cheats.stopPrank();
    }

    function testSetEnabled(uint248 feeArbiterPkey, bool enabled) public {
        cheats.assume(feeArbiterPkey != 0);

        TelescopeManual telescope = makeTelescopeWithWyvernExchangeMock(
            payable(cheats.addr(feeArbiterPkey))
        );

        telescope.setEnabled(enabled);

        assertTrue(telescope.enabled() == enabled);
    }

    function testSetFeeArbiter(
        uint248 feeArbiterPkey,
        address payable feeArbiter
    ) public {
        cheats.assume(feeArbiterPkey != 0);

        TelescopeManual telescope = makeTelescopeWithWyvernExchangeMock(
            payable(cheats.addr(feeArbiterPkey))
        );

        telescope.setFeeArbiter(feeArbiter);
        assertEq(telescope.feeArbiter(), feeArbiter);
    }

    function testCannotAtomicMatchWhenInvalidSignatureSpoofedFeeArbiter(
        address user,
        uint248 feeArbiterPkey,
        uint248 spoofedFeeArbiterPkey,
        uint96 feeValue,
        uint96 wyvernExchangeValue
    ) public {
      cheats.assume(user != address(0));
      cheats.assume(feeArbiterPkey != 0);
      cheats.assume(spoofedFeeArbiterPkey != 0);
      cheats.assume(feeArbiterPkey != spoofedFeeArbiterPkey);

      TelescopeManual telescope = makeTelescopeWithWyvernExchangeMock(
          payable(cheats.addr(feeArbiterPkey))
      );
      uint256 value = uint256(feeValue) + wyvernExchangeValue;
      bytes memory wyvernExchangeData = AtomicMatchUtils.wyvernExchangeData(
          WyvernExchangeMock.atomicMatch_.selector
      );
      bytes memory spoofedSignature = makeSignature(
          spoofedFeeArbiterPkey,
          telescope.atomicMatchHash(
              feeValue,
              wyvernExchangeValue,
              wyvernExchangeData
          )
      );

      cheats.deal(user, value);
      cheats.startPrank(user);
      cheats.expectRevert(TelescopeManual.InvalidSignature.selector);
      telescope.atomicMatch{value: value}(
          feeValue,
          wyvernExchangeValue,
          wyvernExchangeData,
          spoofedSignature
      );
      
      cheats.stopPrank();
    }


    function testCannotAtomicMatchWhenNotEnabled(
        uint248 feeArbiterPkey,
        address user
    ) public {
        cheats.assume(user != address(0));
        cheats.assume(feeArbiterPkey != 0);

        TelescopeManual telescope = makeTelescopeWithWyvernExchangeMock(
            payable(cheats.addr(feeArbiterPkey))
        );
        telescope.setEnabled(false);

        bytes memory wyvernExchangeData = AtomicMatchUtils.wyvernExchangeData(
            WyvernExchangeMock.atomicMatch_.selector
        );
        bytes memory signature = makeSignature(
            feeArbiterPkey,
            telescope.atomicMatchHash(0, 0, wyvernExchangeData)
        );

        cheats.startPrank(user);
        cheats.expectRevert(TelescopeManual.Disabled.selector);
        telescope.atomicMatch(0, 0, wyvernExchangeData, signature);

        cheats.stopPrank();
    }

    function testCannotSetEnabledWhenNotOwner(
        address user,
        uint248 feeArbiterPkey,
        bool enabled
    ) public {
        cheats.assume(user != address(0) && user != owner);
        cheats.assume(feeArbiterPkey != 0);

        TelescopeManual telescope = makeTelescopeWithWyvernExchangeMock(
            payable(cheats.addr(feeArbiterPkey))
        );

        cheats.expectRevert(bytes("Ownable: caller is not the owner"));
        cheats.startPrank(user);
        telescope.setEnabled(enabled);

        cheats.stopPrank();
    }

    function testCannotSetFeeArbiterWhenNotOwner(
        address user,
        address payable feeArbiterToSet,
        uint248 feeArbiterPkey
    ) public {
        cheats.assume(user != address(0) && user != owner);
        cheats.assume(feeArbiterPkey != 0);
        cheats.assume(cheats.addr(feeArbiterPkey) != feeArbiterToSet);

        TelescopeManual telescope = makeTelescopeWithWyvernExchangeMock(
            payable(cheats.addr(feeArbiterPkey))
        );

        cheats.startPrank(user);
        cheats.expectRevert(bytes("Ownable: caller is not the owner"));

        telescope.setFeeArbiter(feeArbiterToSet);

        cheats.stopPrank();
    }
}
