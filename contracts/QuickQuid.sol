// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract QuickQuid is Initializable, ERC20CappedUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 public constant TOTAL_SUPPLY = 100000000 * 10**18;

    function initialize() public initializer {
        address communityWallet = 0x72e2Af2F235ea4e7CFcD62756c27230E98f69591;
        address teamWallet = 0x7cA545E1780D036989120cf603A75521e077CcAF;
        address reserveWallet = 0x6B5b7847e81476e51a5Ca0A462F4541551a7dC4f;

        __ERC20_init("QuickQuid", "QQD");
        __ERC20Capped_init(TOTAL_SUPPLY);
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        _mint(communityWallet, TOTAL_SUPPLY*40/100);
        _mint(teamWallet, TOTAL_SUPPLY*15/100);
        _mint(reserveWallet, TOTAL_SUPPLY*10/100);
    }

    function mint (address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
}
