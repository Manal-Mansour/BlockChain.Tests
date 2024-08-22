// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.7;

import "./Shared.sol";
import "./Government.sol";

contract RealEstate {
    Shared.PropertyInfo public info;
    address public government_address;
    address public owner_address;
    string public owner_id;
    enum ApplicationState {
        PENDING,
        APPROVED
    }
    ApplicationState public state;

    enum TransactionMethod {
        SELL,
        INHERITANCE
    }
    struct Transaction {
        address from;
        string from_id;
        address to;
        string to_id;
        uint256 date;
        TransactionMethod method;
    }

    enum SellingOfferState {
        OPEN,
        CLOSED
    }
    struct SellingOffer {
        SellingOfferState state;
        uint256 value;
    }
    SellingOffer public offer;

    Transaction[] public history;

    modifier ownerRestricted() {
        require(msg.sender == owner_address);
        require(state == ApplicationState.APPROVED);
        _;
    }

    modifier governmentRestricted() {
        require(msg.sender == government_address);
        _;
    }

    constructor(
        string memory id,
        Shared.PropertyInfo memory propertyInfo,
        address creator
    ) {
        government_address = msg.sender;
        state = ApplicationState.PENDING;
        owner_address = creator;
        owner_id = id;
        info = propertyInfo;
    }

    function approve() public governmentRestricted {
        // Can be executed only by government for ONLY the first time
        require(state == ApplicationState.PENDING);
        state = ApplicationState.APPROVED;
    }

    function reject(string memory id) public governmentRestricted {
        // Can be executed only by government for ONLY the first time
        require(state == ApplicationState.PENDING);
        require(
            keccak256(abi.encodePacked(id)) ==
                keccak256(abi.encodePacked(owner_id))
        );

        selfdestruct(payable(government_address));
    }

    function buy(string memory newOwnerId) public payable {
        require(offer.state == SellingOfferState.OPEN);
        require(msg.value == offer.value);

        offer.state = SellingOfferState.CLOSED;
        offer.value = 0;

        // send value to the current owner
        payable(owner_address).transfer(msg.value);

        Transaction memory newTransaction = Transaction({
            from: owner_address,
            from_id: owner_id,
            to: msg.sender,
            to_id: newOwnerId,
            method: TransactionMethod.SELL,
            date: block.timestamp
        });

        Government gov = Government(government_address);
        gov.informOwnershipChange(owner_id, newOwnerId);

        owner_address = msg.sender;
        owner_id = newOwnerId;
        history.push(newTransaction);
    }

    function executeEWill(address benefeciaryAddress, string memory newOwnerId)
        public
        governmentRestricted
    {
        Transaction memory newTransaction = Transaction({
            from: owner_address,
            from_id: owner_id,
            to: benefeciaryAddress,
            to_id: newOwnerId,
            method: TransactionMethod.INHERITANCE,
            date: block.timestamp
        });

        Government gov = Government(government_address);
        gov.informOwnershipChange(owner_id, newOwnerId);

        owner_address = benefeciaryAddress;
        owner_id = newOwnerId;
        history.push(newTransaction);
    }

    function getOwnershipSequence() public view returns (string memory) {
        string memory result = "";
        for (uint256 i = 0; i < history.length; i++) {
            // If it is the first transaction, put from address as well
            if (i == 0) {
                result = history[i].from_id;
            }
            result = string(abi.encodePacked(result, " -> ", history[i].to_id));
        }
        return result;
    }

    function offerTheProperty(uint256 value) public ownerRestricted {
        offer.state = SellingOfferState.OPEN;
        offer.value = value;
    }

    function unofferTheProperty() public ownerRestricted {
        offer.state = SellingOfferState.CLOSED;
        offer.value = 0;
    }
}
