defmodule Web3AptosEx.ModuleHandler.Aptos.MoveDID do
  @moduledoc """
    0x61b96051f553d767d7e6dfcc04b04c28d793c8af3d07d3a43b4e2f8f4ca04c9f::move_did
  """
  import Web3AptosEx.Aptos
  alias Web3AptosEx.Aptos

  @basic_path "0x61b96051f553d767d7e6dfcc04b04c28d793c8af3d07d3a43b4e2f8f4ca04c9f"
  
  @doc """
    const ADDR_AGGREGATOR_TYPE_HUMAN: u64 = 0;
    const ADDR_AGGREGATOR_TYPE_ORG: u64 = 1;
    const ADDR_AGGREGATOR_TYPE_ROBOT: u64 = 2;
  """
  def init(client, acct, type, description) do
    {:ok, f} = ~a"#{@basic_path}::init::init(u64, string)"
    payload = Aptos.call_function(f, [], [type, description])
    Aptos.submit_txn_with_auto_acct_updating(client, acct, payload)
  end

  @doc """
    
    public entry fun add_addr(
        acct: &signer,
        addr_type: u64,
        addr: String,
        pubkey: String,
        chains: vector<String>,
        description: String,
        spec_fields: String,
        expired_at: u64
    ) acquires AddrAggregator {
        let send_addr = signer::address_of(acct);
        let addr_aggr = borrow_global_mut<AddrAggregator>(send_addr);

        do_add_addr(addr_aggr, send_addr, addr_type, addr, pubkey, chains, description, spec_fields, expired_at);
    }

    const ADDR_TYPE_ETH: u64 = 0;
    const ADDR_TYPE_APTOS: u64 = 1;
  """
  def add_addr(client, acct, addr_type, addr, pubkey, chains, description, spec_fields, expired_at) do
    {:ok, f} = ~a"#{@basic_path}::addr_aggregator::add_addr(u64, string, string, vector<string>, string, string, u64)"
    payload = Aptos.call_function(f, [], [addr_type, addr, pubkey, chains, description, spec_fields, expired_at])
    Aptos.submit_txn_with_auto_acct_updating(client, acct, payload)
  end
end
