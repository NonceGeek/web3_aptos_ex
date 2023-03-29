Mox.defmock(Web3AptosEx.HTTP.Mox, for: Web3AptosEx.HTTP)
Application.put_env(:web3_aptos_ex, :http, Web3AptosEx.HTTP.Mox)

ExUnit.start()
