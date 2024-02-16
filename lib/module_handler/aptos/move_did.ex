defmodule Web3AptosEx.ModuleHandler.Aptos.MoveDID do
  @moduledoc """
    0x61b96051f553d767d7e6dfcc04b04c28d793c8af3d07d3a43b4e2f8f4ca04c9f::move_did
  """
  import Web3AptosEx.Aptos
  alias Web3AptosEx.Aptos

  @basic_path "0x61b96051f553d767d7e6dfcc04b04c28d793c8af3d07d3a43b4e2f8f4ca04c9f"
  @resource %{
    addr_aggregator: "#{@basic_path}::addr_aggregator::AddrAggregator", 
    addr_info: "#{@basic_path}::addr_info::AddrInfo",
    service_aggregator: "#{@basic_path}::service_aggregator::ServiceAggregator", 
    service:  "#{@basic_path}::service_aggregator::Service",
  }

  # +--------+
  # | Events |
  # +--------+

  def get_all(client, addr) do
    addrs = get_addr_aggregator(client, addr)
    services = get_service_aggregator(client, addr)
    %{addr_aggregator: addrs, service_aggregator: services}
  end

  def get_addr_aggregator(client, addr) do
    {:ok, %{data: result}} = Aptos.get_resource(client, addr, @resource.addr_aggregator)
    addr_details = Enum.map(result.addrs, fn item ->
        {:ok, detail} = 
            Aptos.get_table_item(
            client, 
            result.addr_infos_map.handle, 
            "0x1::string::String",
            @resource.addr_info,
            item)
        detail
    end)
    Map.put(result, :addr_details, addr_details)
  end

  def get_service_aggregator(client, addr) do
    {:ok, %{data: result}} = Aptos.get_resource(client, addr, @resource.service_aggregator)
    service_details = Enum.map(result.names, fn item ->
        {:ok, detail} = 
            Aptos.get_table_item(
            client, 
            result.services_map.handle, 
            "0x1::string::String",
            @resource.service,
            item)
        detail
    end)
    Map.put(result, :service_details, service_details)
  end
  # +-------+
  # | Funcs |
  # +-------+
  @doc """
    const ADDR_AGGREGATOR_TYPE_HUMAN: u64 = 0;
    const ADDR_AGGREGATOR_TYPE_ORG: u64 = 1;
    const ADDR_AGGREGATOR_TYPE_ROBOT: u64 = 2;
  """
  def init(client, acct, type, description, options \\ []) do
    {:ok, f} = ~a"#{@basic_path}::init::init(u64, string)"
    payload = Aptos.call_function(f, [], [type, description])
    Aptos.submit_txn_with_auto_acct_updating(client, acct, payload, options)
  end

  @doc """
    public entry fun add_service(
            acct: &signer,
            name: String,
            description: String,
            url: String,
            verification_url: String,
            spec_fields: String,
            expired_at: u64
        )
  """
  def add_service(
    client, 
    acct, 
    name, 
    description, 
    url,
    verification_url, 
    spec_fields, 
    expired_at,
    options \\ []
    ) do

        {:ok, f} =
        ~a"#{@basic_path}::service_aggregator::add_service(string, string, string, string, string, u64)"
  
      payload =
        Aptos.call_function(f, [], [
            name, 
            description, 
            url,
            verification_url, 
            spec_fields, 
            expired_at
        ])
  
      Aptos.submit_txn_with_auto_acct_updating(client, acct, payload, options) 
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
  def add_addr(
        client,
        acct,
        addr_type,
        addr,
        pubkey,
        chains,
        description,
        spec_fields,
        expired_at,
        options \\ []
      ) do
    {:ok, f} =
      ~a"#{@basic_path}::addr_aggregator::add_addr(u64, string, string, vector<string>, string, string, u64)"

    payload =
      Aptos.call_function(f, [], [
        addr_type,
        addr,
        pubkey,
        chains,
        description,
        spec_fields,
        expired_at
      ])

    Aptos.submit_txn_with_auto_acct_updating(client, acct, payload, options)
  end
end
