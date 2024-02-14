defmodule Web3AptosEx.ModuleHandler.Aptos.Coin.APT do
  @moduledoc """
    0x1::coin
  """
  # alias Web3AptosEx.Aptos
  alias Web3AptosEx.Aptos.RPC
  import Web3AptosEx.Aptos
  alias Web3AptosEx.Aptos

  @resources %{
    coin_store: "0x1::coin"
  }

  def get_coin_store(client, acct) do
    with {:ok, result} <- RPC.get_resource(
      client,
      acct,
      "#{@resources.coin_store}::CoinStore<0x1::aptos_coin::AptosCoin>") do
      result.data
    end
  end

    def transfer(client, acct, to, amount) do
    {:ok, f} = ~a"0x1::aptos_account::transfer(address, u64)"
    payload = Aptos.call_function(f, [], [to, amount])
    Aptos.submit_txn(client, acct, payload)
  end
  

  # def transfer(client, acct, to, amount) do
  #   {:ok, f} = ~a"0x1::coin::transfer<CoinType>(address, u64)"
  #   payload = Aptos.call_function(f, ["0x1::aptos_coin::AptosCoin"], [to, amount])
  #   Aptos.submit_txn(client, acct, payload)
  # end
  
end
