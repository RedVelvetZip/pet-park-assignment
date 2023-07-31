// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "lib/forge-std/src/Test.sol";
import "../src/PetPark.sol";


contract PetParkTest is Test, PetPark {
    PetPark petPark;
    
    address testOwnerAccount;

    address testPrimaryAccount;
    address testSecondaryAccount;

    function setUp() public {
        petPark = new PetPark();

        testOwnerAccount = msg.sender;
        testPrimaryAccount = address(0xABCD);
        testSecondaryAccount = address(0xABDC);
    }

    function testOwnerCanAddAnimal() public {
        petPark.add(AnimalType.Fish, 5);
    }

    // 1. Test that any non-owner account cannot add animals using the add function
    function testCannotAddAnimalWhenNonOwner() public {
        vm.expectRevert("Not owner");
        petPark.add(AnimalType.Fish, 5);
        bool result = address(petPark).call(abi.encodeWithSignature("add(uint256,uint256)", 1, 5));
        assertEq(result, "Non-owner can add animals");
    }

    function testCannotAddInvalidAnimal() public {
        vm.expectRevert("Invalid animal");
        petPark.add(AnimalType.None, 5);
    }

    function testExpectEmitAddEvent() public {
        vm.expectEmit(false, false, false, true);

        emit Added(AnimalType.Fish, 5);
        petPark.add(AnimalType.Fish, 5);
    }

    // 2. Test that the borrow function fails when called with an age equal to 0
    function testCannotBorrowWhenAgeZero() public {
        petPark.borrow(AnimalType.Fish, 0, 0);
        uint256 borrowedCount = petPark.genderAndAgeHash(msg.sender);
        assertEq(borrowedCount, 0, "Borrow function allowed with age 0");
    }

    function testCannotBorrowUnavailableAnimal() public {
        vm.expectRevert("Selected animal not available");

        petPark.borrow(AnimalType.Fish, 24, 0);
    }

    function testCannotBorrowInvalidAnimal() public {
        vm.expectRevert("Invalid animal type");

        petPark.borrow(AnimalType.None, 24, 0);
    }

    function testCannotBorrowCatForMen() public {
        petPark.add(AnimalType.Cat, 5);

        vm.expectRevert("Invalid animal for men");
        petPark.borrow(AnimalType.Cat, 24, 0);
    }

    function testCannotBorrowRabbitForMen() public {
        petPark.add(AnimalType.Rabbit, 5);

        vm.expectRevert("Invalid animal for men");
        petPark.borrow(AnimalType.Rabbit, 24, 0);
    }

    function testCannotBorrowParrotForMen() public {
        petPark.add(AnimalType.Parrot, 5);

        vm.expectRevert("Invalid animal for men");
        petPark.borrow(AnimalType.Parrot, 24, 0);
    }

    function testCannotBorrowForWomenUnder40() public {
        petPark.add(AnimalType.Cat, 5);

        vm.expectRevert("Invalid animal for women under 40");
        petPark.borrow(AnimalType.Cat, 24, 1);
    }

    function testCannotBorrowTwiceAtSameTime() public {
        petPark.add(AnimalType.Fish, 5);
        petPark.add(AnimalType.Cat, 5);

        vm.prank(testPrimaryAccount);
        petPark.borrow(AnimalType.Fish, 24, 0);

		vm.expectRevert("Already adopted a pet");
        vm.prank(testPrimaryAccount);
        petPark.borrow(AnimalType.Fish, 24, 0);

        vm.expectRevert("Already adopted a pet");
        vm.prank(testPrimaryAccount);
        petPark.borrow(AnimalType.Cat, 24, 0);
    }

    function testCannotBorrowWhenAddressDetailsAreDifferent() public {
        petPark.add(AnimalType.Fish, 5);

        vm.prank(testPrimaryAccount);
        petPark.borrow(AnimalType.Fish, 24, 0);

		vm.expectRevert("Invalid Age");
        vm.prank(testPrimaryAccount);
        petPark.borrow(AnimalType.Fish, 23, 0);

		vm.expectRevert("Invalid Gender");
        vm.prank(testPrimaryAccount);
        petPark.borrow(AnimalType.Fish, 24, 1);
    }

    function testExpectEmitOnBorrow() public {
        petPark.add(AnimalType.Fish, 5);
        vm.expectEmit(false, false, false, true);

        emit Borrowed(AnimalType.Fish);
        petPark.borrow(AnimalType.Fish, 24, 0);
    }

    // 3. Test that the count of animal decreases correctly when the borrow function is called
    function testBorrowCountDecrement() public {
        uint256 initialCount = petPark.getAnimalCount(1);
        petPark.borrow(AnimalType.Fish, 30, 1);
        uint256 countAfterBorrow = petPark.getAnimalCount(1);
        assertEq(countAfterBorrow, initialCount - 1, "Count of animals not decremented correctly after borrow");
    }

    function testCannotGiveBack() public {
        vm.expectRevert("No borrowed pets");
        petPark.giveBackAnimal();
    }

    function testPetCountIncrement() public {
        petPark.add(AnimalType.Fish, 5);

        petPark.borrow(AnimalType.Fish, 24, 0);
        uint reducedPetCount = petPark.animalCounts(AnimalType.Fish);

        petPark.giveBackAnimal();
        uint currentPetCount = petPark.animalCounts(AnimalType.Fish);

		assertEq(reducedPetCount, currentPetCount - 1);
    }
}