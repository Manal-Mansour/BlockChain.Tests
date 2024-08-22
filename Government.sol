// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.7;

import "./Shared.sol";
import "./RealEstate.sol";
import "./EWill.sol";

contract Government {
    address public administrator;

    constructor(
        address _realEstatePublicityManagerAddress,
        address _judicialAuthorityManager
    ) {
        realEstatePublicityManager = _realEstatePublicityManagerAddress;
        judicialAuthorityManager = _judicialAuthorityManager;
        administrator = msg.sender;
    }

    // ----------------------------------------------------------------------
    // ----------------------- Real Estate ----------------------------------
    // ----------------------------------------------------------------------

    address public realEstatePublicityManager;

    mapping(string => address[]) public idToRealEstateMap;

    modifier realEstatePublicityRestricted() {
        require(msg.sender == realEstatePublicityManager);
        _;
    }

    function createRealEstate(string memory id, Shared.PropertyInfo memory info)
        public
        returns (address)
    {
        address newRealEstate = address(new RealEstate(id, info, msg.sender));
        idToRealEstateMap[id].push(newRealEstate);
        return newRealEstate;
    }

    function approveRealEstate(address realEstateAddress)
        public
        realEstatePublicityRestricted
    {
        RealEstate realEstate = RealEstate(realEstateAddress);
        realEstate.approve();
    }

    function rejectRealEstate(string memory id, address realEstateAddress)
        public
        realEstatePublicityRestricted
    {
        RealEstate realEstate = RealEstate(realEstateAddress);
        realEstate.reject(id);
        Shared.removeAddressFromArray(idToRealEstateMap[id], realEstateAddress);
    }

    function informOwnershipChange(
        string memory old_owner_id,
        string memory new_owner_id
    ) public {
        require(
            Shared.addressExistsInArray(
                idToRealEstateMap[old_owner_id],
                msg.sender
            )
        );

        Shared.removeAddressFromArray(
            idToRealEstateMap[old_owner_id],
            msg.sender
        );
        idToRealEstateMap[new_owner_id].push(msg.sender);
    }

    // ----------------------------------------------------------------
    // ----------------------- EWill ----------------------------------
    // ----------------------------------------------------------------

    address public judicialAuthorityManager;

    mapping(string => address) public idToEwillMap;

    modifier judicialAuthorityRestricted() {
        require(msg.sender == judicialAuthorityManager);
        _;
    }

    function createEWill(string memory id) public returns (address) {
        require(idToEwillMap[id] == address(0));

        address newEwill = address(new EWill(id, msg.sender));
        idToEwillMap[id] = newEwill;
        return newEwill;
    }

    function approveEWill(address eWillAddress)
        public
        judicialAuthorityRestricted
    {
        EWill eWill = EWill(eWillAddress);
        eWill.approve();
    }

    function rejectEWill(string memory id) public judicialAuthorityRestricted {
        EWill eWill = EWill(idToEwillMap[id]);
        eWill.reject();
        idToEwillMap[id] = address(0);
    }

    function executeWill(string memory id) public judicialAuthorityRestricted {
        require(idToEwillMap[id] != address(0));

        EWill eWill = EWill(idToEwillMap[id]);

        Shared.WillRealEstateEntry[] memory realEstateWillEntries = eWill
            .markAsDead();

        for (uint256 i = 0; i < realEstateWillEntries.length; i++) {
            Shared.WillRealEstateEntry memory willEntry = realEstateWillEntries[
                i
            ];
            if (
                Shared.addressExistsInArray(
                    idToRealEstateMap[id],
                    willEntry.realEstateAddress
                ) // Make sure the real estate address is already under the testator ownership
            ) {
                RealEstate realEstate = RealEstate(willEntry.realEstateAddress);
                realEstate.executeEWill(willEntry.to, willEntry.toId);
            }
        }

        idToEwillMap[id] = address(0);
    }
}
