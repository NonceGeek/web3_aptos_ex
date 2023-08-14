defmodule Web3AptosEx.Aptos.SmartContractParser do
    import NimbleParsec
    import NimbleJson.Parser.Helper


    @doc """
    TODO: Parse the Move Smart Contract.
    """

    text = ascii_string([not: ?}], min: 1)

    defparsecp(
        :object,
        ignore(string("{"))
        |> ignore(white_space())
        |> concat(text)
        |> ignore(white_space())
        |> ignore(string("}"))
        |> unwrap_and_tag(:object)
      )

    # defparsec :parse, parsec(:node) |> eos()
    defparsec(
        :parse,
        parsec(:object)
        # choice([parsec(:object), parsec(:list)])
    )

    tag = ascii_string([?a..?z, ?A..?Z], min: 1)



    opening_tag = ignore(string("<")) |> concat(tag) |> ignore(string(">"))
    closing_tag = ignore(string("</")) |> concat(tag) |> ignore(string(">"))

    defcombinatorp :node,
                    opening_tag
                    |> repeat(lookahead_not(string("</")) |> choice([parsec(:node), text]))
                    |> wrap()
                    |> concat(closing_tag)
                    |> post_traverse(:match_and_emit_tag)

    defp match_and_emit_tag(_rest, [tag, [tag, text]], context, _line, _offset),
    do: {[{String.to_atom(tag), [], text}], context}

    defp match_and_emit_tag(_rest, [tag, [tag | nodes]], context, _line, _offset),
    do: {[{String.to_atom(tag), [], nodes}], context}

    defp match_and_emit_tag(_rest, [opening, [closing | _]], _context, _line, _offset),
    do: {:error, "closing tag #{inspect(closing)} did not match opening tag #{inspect(opening)}"}

    @doc """
        module hello_blockchain::message {
    use std::error;
    use std::signer;
    use std::string;
    use aptos_framework::account;
    use aptos_framework::event;

//:!:>resource
    struct MessageHolder has key {
        message: string::String,
        message_change_events: event::EventHandle<MessageChangeEvent>,
    }
//<:!:resource

    struct MessageChangeEvent has drop, store {
        from_message: string::String,
        to_message: string::String,
    }

    /// There is no message present
    const ENO_MESSAGE: u64 = 0;

    #[view]
    public fun get_message(addr: address): string::String acquires MessageHolder {
        assert!(exists<MessageHolder>(addr), error::not_found(ENO_MESSAGE));
        borrow_global<MessageHolder>(addr).message
    }

    public entry fun set_message(account: signer, message: string::String)
    acquires MessageHolder {
        let account_addr = signer::address_of(&account);
        if (!exists<MessageHolder>(account_addr)) {
            move_to(&account, MessageHolder {
                message,
                message_change_events: account::new_event_handle<MessageChangeEvent>(&account),
            })
        } else {
            let old_message_holder = borrow_global_mut<MessageHolder>(account_addr);
            let from_message = old_message_holder.message;
            event::emit_event(&mut old_message_holder.message_change_events, MessageChangeEvent {
                from_message,
                to_message: copy message,
            });
            old_message_holder.message = message;
        }
    }

    #[test(account = @0x1)]
    public entry fun sender_can_set_message(account: signer) acquires MessageHolder {
        let addr = signer::address_of(&account);
        aptos_framework::account::create_account_for_test(addr);
        set_message(account,  string::utf8(b"Hello, Blockchain"));

        assert!(
          get_message(addr) == string::utf8(b"Hello, Blockchain"),
          ENO_MESSAGE
        );
    }
}
    """
    def parse_code(contract_code) do
        {:ok, tokens, _} = :smart_move_leex.string(String.to_charlist(contract_code))
        :smart_move_yecc.parse(tokens)
    end
    def parse_struct(contract_code) do
        do_parse(:struct, contract_code)
    end
    def parse_event(contract_code) do
         do_parse(:event, contract_code)
    end
    def parse_fun(contract_code) do
        do_parse(:function, contract_code)
    end
    defp do_parse(name, conttrace_code) do
        {:ok, l} = parse_code(conttrace_code)
        l |> Enum.filter(&(match(name,&1)))
          |> Enum.map(&(add_new_line(:erlang.element(2, &1))))
    end
    defp match(name,{name, _}) do
         true
    end
    defp match(_, _) do
         false
    end
    defp add_new_line(lines) do
        :erlang.list_to_binary(lines |> Enum.map(&(&1++'\n')))
    end
end
