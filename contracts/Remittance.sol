pragma solidity ^0.4.6;

contract Remittance {
    address owner;
    
    struct WithdrawalStruct {
        address withdrawer;
        string password;
        uint deadline;
    }
    
    mapping(address => uint) balances;
    mapping(address => WithdrawalStruct) withdrawalInfos;
    
    function Remittance() {
        owner = msg.sender;
    }
    
    function kill() public {
        if (msg.sender != owner) revert();
        
        selfdestruct(owner);
    }    
    
    function deposit(address withdrawer, uint deadline, string pw) public payable returns(bool success) {
        // Don't allow multiple balances
        if (balances[msg.sender] > 0) revert();
        
        // Check for empty withdrawer
        if (withdrawer == 0) revert();

        WithdrawalStruct memory withdrawalInfo;
        withdrawalInfo.withdrawer = withdrawer;
        withdrawalInfo.password = pw;
        withdrawalInfo.deadline = block.number + deadline;

        withdrawalInfos[msg.sender] = withdrawalInfo;
        balances[msg.sender] += msg.value;
        return true;
    }
    
    function refund() public returns(bool success) {
        WithdrawalStruct withdrawalInfo = withdrawalInfos[msg.sender];
    
        if(withdrawalInfo.withdrawer == 0) revert();
        if(withdrawalInfo.withdrawer != msg.sender) revert();

        // Deadline has not past yet
        if(withdrawalInfo.deadline >= block.number) revert();
        
        uint balance = balances[msg.sender];

        withdrawalInfo.withdrawer.transfer(balance);
        
        withdrawalInfos[msg.sender] = emptyWithdrawalInfo();
        
        return true;
    }
    
    function emptyWithdrawalInfo() private constant returns(WithdrawalStruct wd) {
        WithdrawalStruct w;
        w.withdrawer = 0;
        w.deadline = 0;
        w.password = "";
        
        return w;
    }
    
    function withdraw(address from, string pw) public returns(bool success) {
        WithdrawalStruct withdrawalInfo = withdrawalInfos[from];
        
        if (msg.sender != withdrawalInfo.withdrawer) revert();
        if (!bytesEqual(bytes(withdrawalInfo.password), bytes(pw))) revert();
        if (withdrawalInfo.deadline < block.number) revert();

        uint balance = balances[from];
        
        if (balance > 0) {
            msg.sender.transfer(balance);
        }
        
        withdrawalInfos[from] = emptyWithdrawalInfo();
        
        return true;
    }

    function getBalance() public returns(uint balance) {
      return balances[msg.sender];
    }
    
    function bytesEqual(bytes a, bytes b) public constant returns(bool equal) {
        for (uint i = 0; i < a.length; i ++) {
			if (a[i] != b[i]) {
				return false;
			}
        }
		return true;
    }
}
