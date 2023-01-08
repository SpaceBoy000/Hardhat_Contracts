// SPDX-License-Identifier: Apache2.0

pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Erc721NftProxy is Initializable, ERC1967UpgradeUpgradeable {
    mapping(bytes4 => uint32) _sizes;

    function initialize(address implementation) public virtual initializer {
        ERC1967UpgradeUpgradeable.__ERC1967Upgrade_init();
        _upgradeTo(implementation);
    }

    function getImplementation() public returns (address) {
        return _getImplementation();
    }

    function upgradeTo(address newImplementation) public {
        _upgradeTo(newImplementation);
    }

}