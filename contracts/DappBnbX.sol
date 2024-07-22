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

    uint public securityFee; //  how much percentage we need to charge the user when he wants a refund
    uint public taxPercent; //amount for tax

    mapping(uint => ApartmentStruct) apartments;
    mapping(uint => BookingStruct[]) bookingsOf;
    mapping(uint => ReviewStruct[]) reviewsOf;
    mapping(uint => bool) apartmentExist;
    mapping(uint => uint[]) bookedDates;
    mapping(uint => mapping(uint => bool)) isDateBooked;
    mapping(address => mapping(uint => bool)) hasBooked;

    constructor(uint _taxPercent, uint _securityFee) {
        taxPercent = _taxPercent;
        securityFee = _securityFee;
    }

    function createApartment
    (string memory name, 
    string memory description, 
    string memory location, 
    string memory images, 
    uint rooms, 
    uint price) public{
        //modifier to check if the parameters are valid
        require(bytes(name).length > 0, 'Name cannot be empty');
        require(bytes(description).length > 0, 'Description cannot be empty');
        require(bytes(location).length > 0, 'Location cannot be empty');
        require(bytes(images).length > 0, 'Images cannot be empty');
        require(rooms > 0, 'Roomes cannot be zero(0)');
        require(price > 0, 'Price cannot be zero(0)');

        //increase the total number of apartments on the system by one
        _totalApartments.increment();

        //create an instance of apartment struct
        ApartmentStruct memory apartment;

        apartment.id = _totalApartments.current(); //this will return the current value of the _totalApartments counter
        apartment.name = name;
        apartment.description = description;
        apartment.location = location;
        apartment.images = images;
        apartment.rooms = rooms;
        apartment.price = price;
        apartment.owner = msg.sender;
        apartment.timestamp = currentTime();

        //to check if the apartment Exist
        //               id          &  value
        apartmentExist[apartment.id] = true;
        apartments[apartment.id] = apartment;
    }

    function updateApartment
    (string memory name, 
    string memory description, 
    string memory location, 
    string memory images, 
    uint rooms, 
    uint id, 
    uint price) public{
        //modifier to check if the parameters are valid
        require(apartmentExist[id], 'Apartment not found');
        require(msg.sender == apartments[id].owner, 'Unauthorized personnel, owner only allowed');
        require(bytes(name).length > 0, 'Name cannot be empty');
        require(bytes(description).length > 0, 'Description cannot be empty');
        require(bytes(location).length > 0, 'Location cannot be empty');
        require(bytes(images).length > 0, 'Images cannot be empty');
        require(rooms > 0, 'Roomes cannot be zero(0)');
        require(price > 0, 'Price cannot be zero(0)');

        //create an instance of apartment struct
        ApartmentStruct memory apartment = apartments[id];
        apartment.name = name;
        apartment.description = description;
        apartment.location = location;
        apartment.images = images;
        apartment.rooms = rooms;
        apartment.price = price;

        //to update the modified apartment
        apartments[apartment.id] = apartment;
    }

    function deleteApartment(uint id) public{
        //modifier to check if the parameters are valid
        require(apartmentExist[id], 'Apartment not found');
        require(msg.sender == apartments[id].owner, 'Unauthorized entity!');
        
        //setting the apartmentExist to be false
        apartmentExist[id] = false;
        //to delete the apartment using the id
        apartments[id].deleted = true;
    }

    //function to retrieve a single apartment using the id
    function getApartment(uint id) public view returns (ApartmentStruct memory) {
        return apartments[id];
    }

    function getApartments() public view returns (ApartmentStruct[] memory Apartments) { 
        uint256 available;
        for(uint i = 1; i <= _totalApartments.current(); i++) {
            if(!apartments[i].deleted) available++;
        }

        Apartments = new ApartmentStruct[](available);

        uint256 index;
        for(uint i =1; i<= _totalApartments.current(); i++) {
            if(!apartments[i].deleted) {
                Apartments[index] = apartments[i];
                index++;
            }
        }
    }

    function bookApartment(uint aid, uint[] memory dates) public payable {
        //get the totalPrice of the apartment multiply by the number of dates
        uint totalPrice = apartments[aid].price * dates.length;
        //get the totalPrice for securityFee e.g (5000 * 5) / 100
        uint totalSecurityFee = (totalPrice * securityFee) / 100;
        //check if the said apartment Exist
        require(apartmentExist[aid], 'Apartment not found!');
        require(msg.value >= (totalPrice + totalSecurityFee), 'Insufficient fund supplied!');
        require(datesCleared(aid, dates), 'One or more dates not available!');
    }

    function datesCleared(uint aid, uint [] memory dates) internal view returns (bool) {
        bool dateNotUsed = true;
        
        for(uint i=0; i < dates.length; i++) {
            for(uint j =0; j < bookedDates[aid].length; j++) { 
                if(dates[i] == bookedDates[aid][j]) {
                    dateNotUsed = false;
                }
            }
        }
    }





    //This function is to convert solidity timestamp (10 digits) into the standard timestamp of 13 digits
    function currentTime() internal view returns (uint256) {
        //block.timestamp will produce 10 digits of timestamp
        return (block.timestamp * 1000) + 1000; 
    }

}