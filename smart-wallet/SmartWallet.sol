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

    constructor() {
        owner = payable(msg.sender); // first to use the contract is defined as the owner
    }

    function setAllowance(address _for, uint _amount) public {
        require(msg.sender == owner, "Only the contract owner can access this operation.");
        allowance[msg.sender] = _amount;

        if(_amount > 0) {
            isAllowedToSend[_for] = true;
        } else {
          isAllowedToSend[_for] = false;  
        }
    }

    function transfer(address payable _to, uint _amount, bytes memory _payload) public returns(bytes memory) {

        if(msg.sender != owner) {
            require(allowance[msg.sender] >= _amount, "You are trying to send more than you are allowed to.");
            require(isAllowedToSend[msg.sender], "Not allowed to send anything from this smart contract");

            allowance[msg.sender] -= _amount;
        }

        (bool success, bytes memory data) = _to.call{value: _amount}(_payload);
        require(success, "Call was not successful");
        return data;
    }

    receive() external payable {} // receives ETH, can only be accessed only outside of this contract


}