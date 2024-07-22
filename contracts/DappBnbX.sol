// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >= 0.7.0 < 0.9.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract DappBanX is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _totalApartments;

    struct ApartmentStruct {
        uint id;
        string name;
        string description;
        string location;
        string images;
        uint rooms;
        uint price;
        address owner;
        bool booked;
        bool deleted;
        uint timestamp;
    }

    struct BookingStruct {
        uint id;
        uint aid; //apartment id
        address tenant;
        uint date;
        uint price;
        bool checked;
        bool cancelled;
    }

    struct ReviewStruct {
        uint id;
        uint aid; //apartment id
        string reviewText;
        uint timestamp;
        address owner;
    }

    uint public securityFee;
    uint public taxPercent;

    

}