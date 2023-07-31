//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract PetPark {
    address public owner;
    mapping(uint256 => uint256) public animalCounts;
    mapping(address => bool) public hasBorrowed;
    mapping(address => uint256) public genderAndAgeHash;

    event Added(uint256 animalType, uint256 animalCount);
    event Borrowed(uint256 animalType);
    event Adopted(uint256 animalType, uint256 animalCount);
    event Returned(uint256 animalType);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function add(uint256 animalType, uint256 animalCount) public onlyOwner {
        animalCounts[animalType] += animalCount;
        emit Added(animalType, animalCount);
    }

    function borrow(uint256 animalType, uint256 age, uint256 gender) public {
        require(!hasBorrowed[msg.sender], "Invalid: Can borrow only one animal at a time");
        uint256 genderAndAgeHashValue = uint256(keccak256(abi.encodePacked(age, gender)));
        genderAndAgeHash[msg.sender] = genderAndAgeHashValue;

        if (gender == 0) { // male
            require(animalType == 1 || animalType == 3, "Invalid: Men can only borrow Dog and Fish");
        } else if (gender == 1) { // female
            require(animalType != 2 || (age >= 40), "Invalid: women aged under 40 are not allowed to borrow a Cat");
        }

        hasBorrowed[msg.sender] = true;
        emit Borrowed(animalType);
    }

    function adopt(uint256 animalType, uint256 animalCount) public {
        require(animalCounts[animalType] >= animalCount, "None available");
        animalCounts[animalType] -= animalCount;
        emit Adopted(animalType, animalCount);
    }

    function giveBackAnimal(uint256 animalType) public {
        require(hasBorrowed[msg.sender], "No animal currently borrowed");
        hasBorrowed[msg.sender] = false;
        emit Returned(animalType);
    }

    function getAnimalCount(uint256 animalType) public view returns (uint256) {
        return animalCounts[animalType];
    }

}