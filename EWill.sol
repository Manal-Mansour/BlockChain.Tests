// SPDX-License-Identifier: UNLICENCED  version added
updated from task1
pragma solidity ^0.8.7;

import "./Shared.sol";

contract EWill {
    address public government_address;
    address public testator_address;
    string public testator_id;

    Shared.WillMoneyEntry[] public willMoneyEntries;
    Shared.WillRealEstateEntry[] public willRealEstateEntries;

    enum ApplicationState {
        PENDING,
        APPROVED
    }

    ApplicationState public state;

    modifier testatorRestricted() {
        require(msg.sender == testator_address);
        require(state == ApplicationState.APPROVED);
        _;
    }

    modifier governmentRestricted() {
        require(msg.sender == government_address);
        _;
    }

    constructor(string memory _testator_id, address _testator_address) {
        government_address = msg.sender;
        state = ApplicationState.PENDING;
        testator_address = _testator_address;
        testator_id = _testator_id;
    }

    // EWill specific
    function addWillMoneyEntry(
        address beneficiaryAddress,
        uint256 value,
        uint256 priority
    ) public testatorRestricted {
        Shared.WillMoneyEntry memory entry = Shared.WillMoneyEntry({
            to: beneficiaryAddress,
            value: value,
            priority: priority
        });

        willMoneyEntries.push(entry);
    }

    function addWillRealEstateEntry(
        address beneficiaryAddress,
        string memory beneficiaryId,
        address realEstateAddress
    ) public testatorRestricted {
        Shared.WillRealEstateEntry memory entry = Shared.WillRealEstateEntry({
            to: beneficiaryAddress,
            toId: beneficiaryId,
            realEstateAddress: realEstateAddress
        });

        willRealEstateEntries.push(entry);
    }

    // For daily uses
    function deposit() public payable {
        require(msg.value > 0);
    }

    function withdraw(uint256 value) public testatorRestricted {
        payable(testator_address).transfer(value);
    }

    // One time by government
    function approve() public governmentRestricted {
        // Can be executed only by government for ONLY the first time
        require(state == ApplicationState.PENDING);
        state = ApplicationState.APPROVED;
    }

    function reject() public governmentRestricted {
        // Can be executed only by government for ONLY the first time
        require(state == ApplicationState.PENDING);
        selfdestruct(payable(government_address));
    }

    function markAsDead()
        public
        governmentRestricted
        returns (Shared.WillRealEstateEntry[] memory)
    {
        Shared.sortWillMoneyEntriesByPriority(willMoneyEntries);

        for (uint256 i = 0; i < willMoneyEntries.length; i++) {
            payable(willMoneyEntries[i].to).transfer(willMoneyEntries[i].value);
        }

        selfdestruct(payable(government_address));
        return willRealEstateEntries;
    }
}
