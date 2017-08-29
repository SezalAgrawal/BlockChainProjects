pragma solidity ^0.4.11;
/// @title A simple application to transfer money like TransactionWallet
contract TransactionWallet {
    // Making address of the ADMIN private
    address admin;
    // This represents a single user
    struct User{
        bytes32 name; // name of the user
        bytes32 email; // email address of the user
        uint256 createdAt; // when the rquest was made
        uint userType; // userType = 1 for Consumer and userType = 2 for Merchant
        uint status; // 1 = awaitingApproval, 2 = Approved, 3 = Rejected
        // Did not start with 0 because query on this field might result in ambiguity
        uint amount; // amount in the wallet
      }
    // This declares a state variable that stores a 'User' struct for each possible address.
    mapping(address => User) public users;
    // Using this index to keep track of all the addresses and use it to easily iterate over mapping.
    address[] public usersIndex;
    // Constructor to assign the admin
    function TransactionWallet() {
        admin = msg.sender;
    }
     // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    modifier onlyApprovedUser() {
        require (users[msg.sender].status == 2);
        _;
    }
    // Event that will be fired on changes
    event Deposit(address sender, address receiver, uint amount);
    event SendMessage(string message);
    event GetRecords(address[] UsersIndex);
    event GetUser(bytes32 name, bytes32 email, uint256 createdAt, uint userType, uint status, uint amount);
    event SendAddress(address userAddress, uint status);

    // User requests to add his/her account by sending in the details
    function requestToCreateAccount(bytes32 name, bytes32 email, uint userType){
       // User must not be present in the existing list of users
       require(users[msg.sender].status == 0);
       require(userType == 1 || userType == 2);
       // Add the user in users list with status set to 1, i.e, awaitingApproval
       users[msg.sender].name = name;
       users[msg.sender].email = email;
       users[msg.sender].createdAt = now;
       users[msg.sender].userType = userType;
       users[msg.sender].status = 1;
       users[msg.sender].amount = 0;
       // Add address in usersIndex array
       usersIndex.push(msg.sender);
       SendMessage("Request sent successfully");
    }
    // Returns the list of all the users
    function getAllAccounts() onlyAdmin constant returns (address[] usersList) {
       GetRecords(usersIndex);
       return usersIndex;
    }
    // For ADMIN or the respective user, to fetch the account details
    // Used internal as 'User' struct which is user-defined, is not allowed
    // as return type for external functions
    function fetchDetailsOfUser(address user) constant internal returns (User fetchedUser){
       require(msg.sender == admin || msg.sender == user);
       GetUser(users[user].name, users[user].email, users[user].createdAt, users[user].userType, users[user].status, users[user].amount);
       return users[user];
    }

    // ADMIN approves or rejects add-account requests from users
    // ADMIN supplies the list of addresses along with their status
    // It assumes that ADMIN sends this list after verification
    function addAccount(address[] userAddress, uint[] status) onlyAdmin {

        require(userAddress.length == status.length);
        // For each of the users, where state = 1, i.e, awaitingApproval
        // and state = 3 i.e rejected
        // verify and approve/reject
        for (uint i = 0; i < userAddress.length; i++) {
            // To make sure that status of approved users does not change
            require (users[userAddress[i]].status != 2);
            users[userAddress[i]].status = status[i];
            SendAddress(userAddress[i], status[i]);
        }
    }
      // User can check the status of their application
    function checkStatusOfAccountApplication(address userAddress) returns (string message) {
        // Customized message for all the use cases
        if (users[userAddress].status == 1) {
            message = "To be approved by ADMIN, may take time.";
        } else if (users[userAddress].status == 2) {
            message = "Approved.";
        } else if (users[userAddress].status == 3) {
            message = "Rejected, Please contact ADMIN.";
        } else {
            message = "The give user is not present. Please create an account.";
        }
        SendMessage(message);
        return message;
    }
    // Allow only the approved users to update
    function modifyAccountDetails(bytes32 name, bytes32 email) onlyApprovedUser {
        users[msg.sender].name = name;
        users[msg.sender].email = email;
        SendMessage("Account details modified successfully");
    }
    // Transfer amount from address to wallet
    function transferToWallet() onlyApprovedUser payable {
        require (msg.value > 0);
        users[msg.sender].amount += msg.value;
        Deposit(msg.sender, this, msg.value);
    }
    // Transfer amount from one wallet to other
    function transferToFroWallet(address receiver, uint amount) onlyApprovedUser {
        // Receiver should not be the sender.
        require(msg.sender != receiver);
        // Receiver must also be an approved user
        require (users[receiver].status == 2);
        // Make sure that sender has enough money to do the transfer
        amount *= 1 ether;
        require (amount <= users[msg.sender].amount && amount > 0);
        users[msg.sender].amount -= amount;
        users[receiver].amount += amount;
        Deposit(msg.sender, receiver, amount);
    }
    // Transfer amount from wallet to address
    function transferFromWallet(uint amount) onlyApprovedUser {
        // Make sure there is enough balance in the wallet
        amount *= 1 ether;
        require (users[msg.sender].amount >= amount  && amount > 0);
        // Update the changed amount
        users[msg.sender].amount -= amount;
        msg.sender.transfer(amount);
        Deposit(this, msg.sender, amount);
    }

    // Delete account
    function deleteAccount() onlyApprovedUser {
      uint amount = users[msg.sender].amount;
      // Delete the user from users mapping
      delete (users[msg.sender]);
      // Delete the user from usersIndex array
      uint addressIndex;
      for (uint i = 0; i < usersIndex.length; i++) {
        if(usersIndex[i] == msg.sender) {
          addressIndex = i;
          break;
        }
      }
      usersIndex[addressIndex] = usersIndex[usersIndex.length-1];
      delete(usersIndex[usersIndex.length-1]);
      usersIndex.length--;

      // Prevent unnecessary transfer
      require(amount > 0);
      msg.sender.transfer(amount);
    }
}
