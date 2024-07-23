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
    mapping(uint => BookingStruct[]) bookingsOf; //one apartment can have many bookings
    mapping(uint => ReviewStruct[]) reviewsOf;
    mapping(uint => bool) apartmentExist;
    mapping(uint => uint[]) bookedDates; //one apartment can have many booked dates
    mapping(uint => mapping(uint => bool)) isDateBooked; //one apartment, for a particular date can be booked
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

        //for each of the dates, we are going to call the booking function
        for(uint i=0; i < dates.length; i++) {
            //created an instance of booking struct
            BookingStruct memory booking;
            booking.id = bookingsOf[aid].length;
            booking.aid = aid;
            booking.tenant = msg.sender;
            booking.date = dates[i];
            booking.price = apartments[aid].price;
            bookingsOf[aid].push(booking);// an apartment can have many bookings(days)
            bookedDates[aid].push(dates[i]); //an apartment can have many booked dates
            isDateBooked[aid][dates[i]] = true;
            // hasBooked[msg.sender][dates[i]] = true;
        }
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

    function checkInApartment(uint aid, uint bookingId) public nonReentrant() {
        //To get a singluar bookingstruct for an apartmemt 
        BookingStruct memory booking  = bookingsOf[aid][bookingId];
        //the caller of this method must be a tenant
        require(msg.sender == booking.tenant, "Unauthorized Entity");
        //to check if the booking has already been checked in for that specific date
        require(!booking.checked, 'Apartment already checked on this date!');

        //bookingstruct for that partial apartment is chekced in
        bookingsOf[aid][bookingId].checked = true;
        //this person booked this particular date
        hasBooked[msg.sender][aid] = true;
        //calculating the amount of money for tax and security fee
        uint tax = (booking.price * taxPercent) / 100;
        uint fee = (booking.price * securityFee) / 100;

        payTo(apartments[aid].owner, (booking.price - tax));
        payTo(owner(), tax); //owner() refers to the person that deployed/owned this contract
        payTo(msg.sender, fee);
    }

    //TODO
    function claimFunds(uint aid, uint bookingId) public nonReentrant() {
        require(msg.sender == apartments[aid].owner, 'Unauthorized entity');
        require(!bookingsOf[aid][bookingId].checked, 'Apartment already checked-in on this date!');

        uint price = bookingsOf[aid][bookingId].price;
        uint fee = (price * taxPercent) / 100;

        payTo(apartments[aid].owner, (price - fee));
        payTo(owner(), fee);
        payTo(msg.sender, securityFee);
    }

    function refundBooking(uint aid, uint bookingId) public nonReentrant {
        BookingStruct memory booking = bookingsOf[aid][bookingId];
        require(!booking.checked, 'Apartment already checked in on this date!');
        //this is to checked if the date was booked for that particular apartment
        require(isDateBooked[aid][booking.date], 'Did not book on this date!');

        if (msg.sender != owner()) {
        require(msg.sender == booking.tenant, 'Unauthorized tenant!');
        require(booking.date > currentTime(), 'Can no longer refund, booking date started');
        }

        bookingsOf[aid][bookingId].cancelled = true;
        isDateBooked[aid][booking.date] = false;
        //not clear
        uint lastIndex = bookedDates[aid].length - 1;
        uint lastBookingId = bookedDates[aid][lastIndex];
        bookedDates[aid][bookingId] = lastBookingId; //not clear
        bookedDates[aid].pop();

        uint fee = (booking.price * securityFee) / 100;
        uint collateral = fee / 2;

        payTo(apartments[aid].owner, collateral);
        payTo(owner(), collateral);
        payTo(msg.sender, booking.price);
    }

    function getUnavailableDates(uint aid) public view returns (uint[] memory) {
        return bookedDates[aid];
    }

    function getBookings(uint aid) public view returns (BookingStruct[] memory) {
        return bookingsOf[aid];
    }

    function getBooking(uint aid, uint bookingId) public view returns (BookingStruct memory) {
        return bookingsOf[aid][bookingId];
    }


    function payTo(address to, uint256 amount) internal {
        (bool success, ) = payable(to).call{ value: amount }('');
        require(success);
    }

     function addReview(uint aid, string memory reviewText) public {
        require(apartmentExist[aid], 'Appartment not available');
        require(hasBooked[msg.sender][aid], 'Book first before review');
        require(bytes(reviewText).length > 0, 'Review text cannot be empty');

        ReviewStruct memory review;

        review.aid = aid;
        review.id = reviewsOf[aid].length;
        review.reviewText = reviewText;
        review.timestamp = currentTime();
        review.owner = msg.sender;

        reviewsOf[aid].push(review);
    }

    function getReviews(uint aid) public view returns (ReviewStruct[] memory) {
        return reviewsOf[aid];
    }

    function getQualifiedReviewers(uint aid) public view returns (address[] memory Tenants) {
        uint256 available;
        for (uint i = 0; i < bookingsOf[aid].length; i++) {
        if (bookingsOf[aid][i].checked) available++;
        }

        Tenants = new address[](available);

        uint256 index;
        for (uint i = 0; i < bookingsOf[aid].length; i++) {
        if (bookingsOf[aid][i].checked) {
            Tenants[index++] = bookingsOf[aid][i].tenant;
        }
        }
    }
    function tenantBooked(uint appartmentId) public view returns (bool) {
        return hasBooked[msg.sender][appartmentId];
    }

    //This function is to convert solidity timestamp (10 digits) into the standard timestamp of 13 digits
    function currentTime() internal view returns (uint256) {
        //block.timestamp will produce 10 digits of timestamp
        return (block.timestamp * 1000) + 1000; 
    }

}