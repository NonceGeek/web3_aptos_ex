defmodule Web3AptosEx.ModuleHandler.Aptos.Coin do
  @moduledoc """
    0x1::coin
  """
  alias Web3AptosEx.Aptos.RPC
  import Web3AptosEx.Aptos
  alias Web3AptosEx.Aptos

  @resources %{
    coin_store: "0x1::coin"
  }

  def get_coin_store(client, acct, coin_resource) do
    with {:ok, result} <- RPC.get_resource(
      client,
      acct,
      "#{@resources.coin_store}::CoinStore<#{coin_resource}>") do
      result.data
    end
  end
  
  def transfer(client, acct, to, amount, coin_resource, options \\ []) do
    {:ok, f} = ~a"0x1::coin::transfer<CoinType>(address, u64)"
    payload = Aptos.call_function(f, ["#{coin_resource}"], [to, amount])
    Aptos.submit_txn_with_auto_acct_updating(client, acct, payload, options)
  end

  def register(client, acct, coin_resource, options \\ []) do
    {:ok, f} = ~a"0x1::managed_coin::register<CoinType>()"
    payload = Aptos.call_function(f, ["#{coin_resource}"], [])
    Aptos.submit_txn_with_auto_acct_updating(client, acct, payload,, options)
  end
  
end
