// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

// Specifications:
// 1 owner
// funds received by fallback function
// money spend on EOA and Contracts
// give allowance to other people
// new owner with 3 of 5 guardians votes


contract SmartWallet {

    // Ethereum address that can receive Ether
    address payable owner;

    mapping(address => uint) public allowance;
    mapping(address => bool) public isAllowedToSend;

    mapping(address => bool) public guardians;
    address payable nextOwner;
    mapping(address => mapping(address => bool)) guardianAlreadyVoted;
    uint guardiansResetCount;
    uint public constant guardianConfirmationsForReset = 3;


    constructor() {
        owner = payable(msg.sender); // first to use the contract is defined as the owner
    }
    

    function setGuardian(address _guardian, bool _isGuardian) public {
        onlyOwnerOperation();
        guardians[_guardian] = _isGuardian;
    }

    function proposeNewOwner(address payable _newOwner) public {
        require(guardians[msg.sender], "You are not a guardian.");
        require(guardianAlreadyVoted[_newOwner][msg.sender] == false, "You already voted.");
        if(_newOwner != nextOwner) {
            nextOwner = _newOwner;
            guardiansResetCount = 0;
        }

        guardiansResetCount++;

        if(guardiansResetCount >= guardianConfirmationsForReset) {
            owner = nextOwner;
            nextOwner = payable(address(0));
        }
    }

    function setAllowance(address _for, uint _amount) public {
        onlyOwnerOperation();
        allowance[msg.sender] = _amount;

        if(_amount > 0) {
            isAllowedToSend[_for] = true;
        } else {
          isAllowedToSend[_for] = false;  
        }
    }

    // Transfer ETH
    function transfer(
        address payable _to, 
        uint _amount, 
        bytes memory _payload
    ) public returns(bytes memory) {

        if(msg.sender != owner) {
            allowanceRequires(_amount);
            allowance[msg.sender] -= _amount;
        }

        (bool success, bytes memory data) = _to.call{value: _amount}(_payload);
        require(success, "Call was not successful");
        
        return data;
    }
    
    function onlyOwnerOperation() private view {
        require(msg.sender == owner, "Only the guardian owner can access this operation.");
    }

    function allowanceRequires(uint _amount) private view {
       require(allowance[msg.sender] >= _amount, "You are trying to send more than you are allowed to.");
        require(isAllowedToSend[msg.sender], "Not allowed to send anything from this smart contract"); 
    }

    receive() external payable {} // receives ETH, can only be accessed only outside of this contract


}