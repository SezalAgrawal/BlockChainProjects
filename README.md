# Transaction Wallet

This is a transaction wallet where people can transfer ether and buy products. It consists of three types of user: admin, consumer, merchant. To join this wallet, user(consumer/merchant) must request admin to create an account. Admin can approve/ reject users. Once approved by admin, an user becomes a part of this wallet and can update his details and transfer ether among his peers who are also approved users. To start this transaction, an user must transfer money from his account to this wallet. He can later withdraw this money. An user can also delete his account, after making sure that there are no pending transactions left.

There is another functionality where a merchant can display a set of products. Only approved consumers will be allowed to buy those. The contract would make sure that both seller and buyer remains true to their agreement. The merchant can update and delete the products. The seller buys the product and only after he/she confirms the purchase, the purchase-sell procedure gets completed.
