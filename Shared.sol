// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.7;

library Shared {
    struct PropertyInfo {
        string description; // Includes a description for the borders, area, floor, ... etc
        string unit_no;
        string building_no;
        string street;
        string city;
        string state;
        string zip;
    }

    function removeAddressFromArray(address[] storage _array, address _element)
        public
    {
        for (uint256 i; i < _array.length; i++) {
            if (_array[i] == _element) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
        }
    }

    function addressExistsInArray(address[] storage _array, address _element)
        public
        view
        returns (bool)
    {
        for (uint256 i; i < _array.length; i++) {
            if (_array[i] == _element) {
                return true;
            }
        }
        return false;
    }

    struct WillRealEstateEntry {
        address realEstateAddress;
        address to;
        string toId;
    }
    struct WillMoneyEntry {
        address to;
        uint256 priority;
        uint256 value;
    }

    function sortWillMoneyEntriesByPriority(WillMoneyEntry[] storage items)
        public
    {
        for (uint256 i = 1; i < items.length; i++)
            for (uint256 j = 0; j < i; j++)
                if (items[i].priority < items[j].priority) {
                    WillMoneyEntry memory temp = items[i];
                    items[i] = items[j];
                    items[j] = temp;
                }
    }
}
