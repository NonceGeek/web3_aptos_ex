defmodule Web3AptosEx.Aptos do
  @moduledoc false

  import Web3AptosEx.Aptos.Helpers
  alias Web3AptosEx.Aptos.{RPC, Account, Parser}
  alias Web3AptosEx.Crypto
  alias Web3AptosEx.ModuleHandler.Aptos.Coin

  @doc """
    `~a"0x1::coin::transfer<CoinType>(address,u64)"`
  """

  defmacro sigil_a({:<<>>, line, pieces}, []) do
    quote do
      unquote({:<<>>, line, unescape_tokens(pieces)})
      |> Parser.parse_function()
    end
  end

  defp unescape_tokens(tokens) do
    :lists.map(
      fn token ->
        case is_binary(token) do
          true -> :elixir_interpolation.unescape_string(token)
          false -> token
        end
      end,
      tokens
    )
  end

  defdelegate connect, to: RPC
  defdelegate connect(endpoint), to: RPC
  def generate_keys() do
    priv = Crypto.generate_priv()
    Account.from_private_key(priv)
  end

  def generate_keys(priv), do: Account.from_private_key(priv)
  def get_balance(client, account), do: Coin.get_coin_store(client, account)

  def get_faucet(%{endpoint: endpoint}, account, amount \\ 100000000) do
    cond do
      String.contains?(endpoint, "testnet") ->
        {:ok, client_f} = RPC.connect(:faucet, :testnet)
        RPC.get_faucet(client_f, account, amount)

      String.contains?(endpoint, "devnet") ->
        {:ok, client_f} = RPC.connect(:faucet, :devnet)
        RPC.get_faucet(client_f, account, amount)

      true ->
        # TODO: supported local network.
        raise "Network not supported"
    end
  end

  # usefull APIs
  def load_account(client, account) do
    with {:ok, loaded_account} <- RPC.get_account(client, account),
         %{authentication_key: auth_key, sequence_number: seq_num} <- loaded_account do
      {:ok, auth_key} = normalize_key(auth_key)
      sequence_number = String.to_integer(seq_num)

      case account do
        %{auth_key: ^auth_key} ->
          {:ok, %{account | sequence_number: sequence_number}}

        %{auth_key: nil} ->
          {:ok, %{account | auth_key: auth_key, sequence_number: sequence_number}}

        _ ->
          {:error, :auth_key_not_match}
      end
    else
      _ -> {:error, :load_failed}
    end
  end

  def submit_txn_with_auto_acct_updating(client, acct, payload, options \\ []) do
    {:ok, acct_ol} = load_account(client, acct)
    submit_txn(client, acct_ol, payload, options)
  end

  # +----------------------+
  # | buidl and submit txn |
  # +----------------------+

  def submit_txn(client, acct, payload, options \\ []) do
    raw_txn =
      Web3AptosEx.Aptos.Transaction.make_raw_txn(acct, client.chain_id, payload, options)

    signed_txn = Web3AptosEx.Aptos.Transaction.sign_ed25519(raw_txn, acct.signing_key)
    Web3AptosEx.Aptos.RPC.submit_bcs_transaction(client, signed_txn)
  end

  @doc """
    if there is no type_args
  """
  def call_func(client, acct, contract_addr, module_name, func_name, args, arg_types) do
    call_func(
      client,
      acct,
      contract_addr,
      module_name,
      func_name,
      args,
      arg_types,
      [])
  end

  @doc """
    if there is type_args, such as:
    > f = ~a"0x1::coin::transfer<CoinType>(address,u64)"f
    > payload = Aptos.call_function(f, ["0x1::aptos_coin::AptosCoin"], [account.address, 100])
  """
  def call_func(client,
    acct,
    contract_addr,
    module_name,
    func_name,
    args,
    arg_types,
    type_args) do
    {:ok, f} = gen_func(contract_addr, module_name, func_name, arg_types)
    payload = call_function(f, type_args, args)
    {:ok, %{hash: hash} = tx} = submit_txn_with_auto_acct_updating(client, acct, payload)
    Process.sleep(2000)  # 用 2 秒等待交易成功
    res = check_tx_res_by_hash(client, hash)
    %{res: res, tx: tx}
  end

  def call_function(func, type_args, args) do
    encoded_args =
      func.params
      |> Web3AptosEx.Aptos.Types.strip_signers()
      |> Web3AptosEx.Aptos.Types.encode(args)

    Web3AptosEx.Aptos.Transaction.script_function(
      func.address,
      func.module,
      func.name,
      type_args,
      encoded_args
    )
  end

  # +--------+
  # | Events |
  # +--------+

  defdelegate get_events(client, address, event_handle, field, query \\ [limit: 10]), to: RPC
  defdelegate build_event_path(client, address, event_handle, field), to: RPC

  # +-----------+
  # | Resources |
  # +-----------+

  defdelegate get_resources(client, address, query \\ []), to: RPC
  defdelegate get_resource(client, address, resource_type), to: RPC
  defdelegate build_resource_path(client, address, resource_type), to: RPC

  defdelegate get_table_item(client, table_handle, key_type, value_type, key), to: RPC

  # +-----+
  # | Txs |
  # +-----+

  defdelegate get_tx_by_hash(client, hash), to: RPC
  defdelegate check_tx_res_by_hash(client, hash, times \\ 3), to: RPC

end
