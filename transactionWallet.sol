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
    mapping(address => Order[]) orders; // List of products sold by Merchant or bought by Consumer

    enum State { Created, Locked, Inactive }

    // This represents a single item of the given product
    struct Item{
        address buyer; // stores the address of the consumer who makes the purchase
        uint amount; // the discounted amount for which the purchase was made
        State state;  // state of the item
      }

    // This represents a single product up for sell/purchase Eg: apple
    struct Product{
        bytes32 productName; // name of the product
        address merchantAddress; // address of the merchant who has kept the product for sale
        uint actualPrice; // the actual price of the product
        uint discountPercent; // to calculate the discounted price
        uint quantity; // the qty of the product open for sale
        uint countOfItems; // to maintain a count of the items which are under sell/purchase
        // Eg: 10 units of apples, where each unit is recongnized as an item
        mapping(uint => Item) itemList; // list of all the items under the given product
      }

    // This represents a single order the consumer has placed
    struct Order{
        uint productID;
        uint itemID;
      }

    // This  declares a state variable that stores a 'Product' for each possible productID
    mapping(uint => Product) public productDetails;

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
    modifier onlyMerchant() {
      require (users[msg.sender].userType == 2);
      _;
    }
    modifier onlyConsumer() {
      require (users[msg.sender].userType == 1);
      _;
    }
    // Event that will be fired on changes
    event Deposit(address sender, address receiver, uint amount);
    event SendMessage(string message);
    event GetRecords(address[] UsersIndex);
    event GetUser(bytes32 name, bytes32 email, uint256 createdAt, uint userType, uint status, uint amount);
    event SendAddress(address userAddress, uint status);
    event Aborted(uint productID);
    event PurchaseConfirmed(uint productID, uint quantity);
    event ItemReceived(uint productID, uint itemID);

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

    function fetchOrdersOfUser(address user) constant internal returns (Order[] order){
       require(msg.sender == admin || msg.sender == user);
       return orders[user];
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
      // Check if the user has no pending bills to give/receive
      for(uint i=0; i<orders[msg.sender].length; i++)
        require(productDetails[orders[msg.sender][i].productID].itemList[orders[msg.sender][i].itemID].state == State.Inactive);

      uint amount = users[msg.sender].amount;
      // Delete the user from users mapping
      delete (users[msg.sender]);
      // Delete the user from usersIndex array
      uint addressIndex;
      for (i = 0; i < usersIndex.length; i++) {
        if(usersIndex[i] == msg.sender) {
          addressIndex = i;
          break;
        }
      }
      usersIndex[addressIndex] = usersIndex[usersIndex.length-1];
      delete(usersIndex[usersIndex.length-1]);
      usersIndex.length--;
      SendMessage("User has been deleted");
      // Prevent unnecessary transfer
      require(amount > 0);
      msg.sender.transfer(amount);
    }

    // Add a product to display in the wallet for the consumers to buy
    function addProduct(uint productID, bytes32 productName, uint actualPrice, uint discountPercent, uint quantity)
      onlyApprovedUser onlyMerchant {
      // Check if the product does not already exist
      var product = productDetails[productID];
      require(product.actualPrice == 0);
      // Actual Price should not be 0 as this is the base condition for checking the exitence of the product
      require(actualPrice != 0);
      // Check if the seller has enough money in the wallet to pay for the product, so to hold his side of the bargain
      require(users[msg.sender].amount >= ((2*actualPrice*quantity)* 1 ether));

      // Add the product
      product.productName = productName;
      product.merchantAddress = msg.sender;
      product.actualPrice = actualPrice* 1 ether;
      product.discountPercent = discountPercent;
      product.quantity = quantity;

      // Update the wallet
      users[msg.sender].amount -= (2*actualPrice*quantity)* 1 ether;
      SendMessage("Product is added");

    }

    // Update the product
    function updateProduct(uint productID, bytes32 productName, uint actualPrice, uint discountPercent, uint quantity)
      onlyApprovedUser onlyMerchant {
      // Check if the product exists and the updater is the authorized person
      var product = productDetails[productID];
      require((product.actualPrice != 0) && (product.merchantAddress == msg.sender));
      // Transfer money from/to wallet depending on the change in actualPrice/quantity
      uint newAmount = 2*actualPrice*quantity* 1 ether;
      uint oldAmount = 2*product.actualPrice*product.quantity;
      uint difference = newAmount - oldAmount;
      if(newAmount > oldAmount)
        require(difference <= users[msg.sender].amount);

      // Update the product
      product.productName = productName;
      product.actualPrice = actualPrice* 1 ether;
      product.discountPercent = discountPercent;
      product.quantity = quantity;

      // Update the wallet
      if(difference > 0)
        users[msg.sender].amount -= difference;
      else if (difference < 0)
        users[msg.sender].amount += difference;

      SendMessage("Product is updated");
      }

      // Delete a product
      function deleteProduct(uint productID) onlyApprovedUser onlyMerchant {
        // Check if the product exists and the deleter is the authorized person
        var product = productDetails[productID];
        require((product.actualPrice != 0) && (product.merchantAddress == msg.sender));
        // Check if there are no items
        require(product.countOfItems == 0);
        // Save the amount
        uint amount = 2*product.actualPrice*product.quantity;
        // Delete the product from the list
        delete (productDetails[productID]);
        // Update the wallet
        users[msg.sender].amount += amount;
        Aborted(productID);
      }

      // Buy a product and specify the quantity
      function buyProduct(uint productID, uint quantity) onlyApprovedUser onlyConsumer {
        require(quantity > 0);
        // Check if the product exists and quantity is sufficient
        var product = productDetails[productID];
        require((product.actualPrice != 0) && (product.quantity >= quantity));
        // Check if the consumer has sufficient ethers in wallet to make the purchase
        uint discountAmount = ((100 - product.discountPercent)*product.actualPrice) / 100;
        require(users[msg.sender].amount >= 2*discountAmount*quantity);
        // Update the itemList and orderList
        uint itemID;
        for(uint i=1; i<=quantity; i++) {
          itemID = product.countOfItems;
          product.itemList[itemID] = Item({buyer: msg.sender, amount: discountAmount, state: State.Locked});
          orders[msg.sender].push(Order({productID: productID, itemID: itemID}));
          orders[product.merchantAddress].push(Order({productID: productID, itemID: itemID}));
          product.countOfItems++;
        }
        product.quantity -= quantity;
        // Update the wallet
        users[msg.sender].amount -= 2*discountAmount*quantity;
        PurchaseConfirmed(productID, quantity);
      }

      // The consumer confirms on receiving the product by giving productID and itemID
      function confirmReceived(uint productID, uint itemID) onlyApprovedUser onlyConsumer {
        var item = productDetails[productID].itemList[itemID];
        // Check if the product exists and is bought by the same person
        require((item.state == State.Locked) && (item.buyer == msg.sender));

        ItemReceived(productID, itemID);
        // Update the status of the item
        item.state = State.Inactive;
        // Update the wallet of both seller and buyer
        users[msg.sender].amount += item.amount;
        users[productDetails[productID].merchantAddress].amount += 2*productDetails[productID].actualPrice;
  }

}
