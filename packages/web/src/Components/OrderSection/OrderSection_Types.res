type executionState =
  | Buy
  | ClientPending
  | WalletConfirmPending
  | TransactionCreated({transactionHash: string})
  | TransactionConfirmed({transactionHash: string})
  | TransactionFailed({transactionHash: string})
  | InvalidOrder(option<string>)

