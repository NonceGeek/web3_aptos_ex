defmodule Web3AptosEx.ModuleHandler.Aptos.Inscriptions do
  @moduledoc """
    0x1fc2f33ab6b624e3e632ba861b755fd8e61d2c2e6cf8292e415880b4c198224d
  """
  alias Web3AptosEx.Aptos.RPC
  import Web3AptosEx.Aptos
  alias Web3AptosEx.Aptos

  @resources %{
    apts: "0x1fc2f33ab6b624e3e632ba861b755fd8e61d2c2e6cf8292e415880b4c198224d::apts"
  }

  def batch_mint(client, acct, token_name, times) do
    Enum.map(1..times, fn idx ->
        IO.puts("--process: #{idx}--")
      mint(client, acct, token_name)

    end)
  end

  def mint(client, acct, token_name) do
    {:ok, f} = ~a"#{@resources.apts}::mint(string)"
    payload = Aptos.call_function(f, [], [token_name])
    Aptos.submit_txn_with_auto_acct_updating(client, acct, payload)
  end
end