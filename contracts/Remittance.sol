pragma solidity ^0.4.6;

contract Remittance {
    address owner;
    
    struct WithdrawalStruct {
        uint amount;
        uint deadline;
        address sender;
    }
    
    mapping(bytes32 => WithdrawalStruct) withdrawalInfos;
    
    function Remittance() {
        owner = msg.sender;
    }
    
    function kill() public {
        if (msg.sender != owner) revert();
        
        selfdestruct(owner);
    }    
    
    function deposit(address withdrawer, bytes32 pw, uint deadline) public payable returns(bool success) {
        // Check for empty withdrawer
        if (withdrawer == 0) revert();
        
        // Don't send to self
        if (withdrawer == msg.sender) revert();
        
        bytes32 hash = keccak256(withdrawer, pw);
        
        // Don't overwrite if this withdrawer + pw hash exists already
        if (withdrawalInfos[hash].amount > 0) revert();      

        WithdrawalStruct memory withdrawalInfo;
        withdrawalInfo.deadline = block.number + deadline;
        withdrawalInfo.amount = msg.value;
        withdrawalInfo.sender = msg.sender;

        withdrawalInfos[hash] = withdrawalInfo;

        return true;
    }
    
    function refund(address destination, bytes32 pw) public returns(bool success) {
        bytes32 hash = keccak256(destination, pw);
        
        WithdrawalStruct withdrawalInfo = withdrawalInfos[hash];
    
        if(withdrawalInfo.amount == 0) revert();
        if(withdrawalInfo.sender != msg.sender) revert();

        // Deadline has not past yet
        if(withdrawalInfo.deadline >= block.number) revert();
        
        uint balance = withdrawalInfo.amount;

        withdrawalInfo.amount = 0;
        withdrawalInfo.deadline = 0;
        withdrawalInfos[hash] = withdrawalInfo;

        msg.sender.transfer(balance);
        
        return true;
    }

    
    function withdraw(bytes32 pw) public returns(bool success) {
        bytes32 hash = keccak256(msg.sender, pw);
        WithdrawalStruct withdrawalInfo = withdrawalInfos[hash];
        
        if (withdrawalInfo.deadline < block.number) revert();

        uint amount = withdrawalInfo.amount;

        if (amount > 0) {
            withdrawalInfo.amount = 0;
            withdrawalInfo.deadline = 0;
            withdrawalInfos[hash] = withdrawalInfo;

            msg.sender.transfer(amount);
        }

        return true;
    }
}
