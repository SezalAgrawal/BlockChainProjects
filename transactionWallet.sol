pragma solidity ^0.4.11;

/// @title A simple application to transfer money like TransactionWallet
contract TransactionWallet {
    // Making address of the ADMIN private
    address admin;

    // This represents a single user
    struct User{
      bytes32 name; // name of the user
      bytes32 email; // email address of the user
      uint createdAt; // when the rquest was made
      uint userType; // userType = 1 for Consumer and userType = 2 for Merchant
      uint status; // 1 = awaitingApproval, 2 = Approved, 3 = Rejected
                   // Did not start with 0 because query on this field might result in ambiguity
      }

    // This declares a state variable that
    // stores a 'User' struct for each possible address.
     mapping(address => User) public users;

     // This is needed as there is no easy way to iterate over the mappings
     address[] public usersIndex;

     // Constructor to assign the admin
     function TransactionWallet() {
       admin = msg.sender;
     }

     modifier onlyAdmin() {
       require(msg.sender == admin);
       _;
     }


     // User requests to add his/her account by sending in the details
     function requestToCreateAccount(bytes32 name, bytes32 email, uint createdAt, uint userType){
       // User must not be present in the existing list of users
       require(users[msg.sender].status == 0);

       // Add the user in users list with status set to 1 i.e awaitingApproval
       users[msg.sender].name = name;
       users[msg.sender].email = email;
       users[msg.sender].createdAt = createdAt;
       users[msg.sender].userType = userType;
       users[msg.sender].status = 1;

       // Add address in usersIndex array
       usersIndex.push(msg.sender);
     }

     // Returns the list of all the users
     function getAllAccounts() constant
      onlyAdmin returns (address[] usersList) {
       return usersIndex;
     }

     // For ADMIN or the respective user, to fetch the account details
     // Used internal as 'User' struct which is user-defined, is not allowed
     // as return type for external functions
     function fetchDetailsOfUser(address user) constant internal
      returns (User fetchedUser){
       require(msg.sender == admin || msg.sender == user);
       return users[user];
     }
     // ADMIN approves or rejects add-account requests from users
     // ADMIN supplies the list of addresses along with their status
     // It assumes that ADMIN sends this list after verification
      function addAccount(address[] userAddress, uint[] status)
          onlyAdmin {
          require(userAddress.length == status.length);

          // For each of the users, where state = 1 i.e awaitingApproval
          // and state = 3 i.e rejected
          // verify and approve/reject
          for (uint i = 0; i < userAddress.length; i++) {
            // To make sure that status of approved users does not change
            require (users[userAddress[i]].status != 2);
            users[userAddress[i]].status = status[i];
          }

      }

      // User can check the status of their application
      function checkStatusOfAccountApplication(address userAddress)
       returns (string message) {
          // Customized message for all the use cases
          if (users[userAddress].status == 1)
            message = "To be approved by ADMIN, may take time.";
          else if (users[userAddress].status == 2)
            message = "Approved.";
          else if (users[userAddress].status == 3)
              message = "Rejected, Please contact ADMIN.";
          else message = "The give user is not present. Please create an account.";

          return message;
      }



}
