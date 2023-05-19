# Aptos

## Example

```elixir
import Web3AptosEx.Aptos

alias Web3AptosEx.Aptos

{:ok, rpc} = Aptos.RPC.connect()

{:ok, account} = Aptos.Account.from_private_key(your_private_key)
{:ok, account} = Aptos.load_account(rpc, account)

# Call function
f = ~a"0x1::coin::transfer<CoinType>(address,u64)"

payload = Aptos.call_function(f, ["0x1::aptos_coin::AptosCoin"], [to, 100])

Aptos.submit_txn(rpc, account, payload)
```