Header "%% Copyright (C)"
"%% @private"
"%% @Author Cam".


Nonterminals
  root elements element result struct_res struct_ress others comment_res function_res function_ress brace_block rbrace_res.
Terminals
   module script use const friend lbrace_line lbrace_begin lbrace rbrace rbrace_semicolon struct_begin struct other comment comment_start comment_end annotation function fun_begin.

Rootsymbol root.

root -> elements: '$1'.
elements -> element: ['$1'].
elements -> element elements: ['$1' | '$2'].
element -> result: parse_result('$1').
result -> other: {other, [value_of('$1')]}.
result -> rbrace: {module_end, [value_of('$1')]}.
result -> module: {module, [value_of('$1')]}.
result -> script: {script, [value_of('$1')]}.
result -> use: {use, [value_of('$1')]}.
result -> friend: {friend, [value_of('$1')]}.
result -> const: {const, [value_of('$1')]}.
result -> comment: {comment, [value_of('$1')]}.
result -> comment_res: '$1'.
comment_res -> comment_start others comment_end: add(comment, '$1', '$2', '$3').
result -> function_ress: '$1'.
function_ress -> function_res: '$1'.
function_ress -> annotation function_res: add(function, '$1', '$2').
function_res -> function: {function, [value_of('$1')]}.
function_res -> fun_begin others rbrace: add(function, '$1', '$2', '$3').
function_res -> fun_begin others: add(function, '$1', '$2').
result -> struct_ress: '$1'.
struct_ress -> struct_res: '$1'.
struct_ress -> annotation struct_res: add(struct, '$1', '$2').
struct_res -> struct: add(struct, '$1').
struct_res -> lbrace others rbrace_res: add(struct, '$1' ,'$2', '$3').
struct_res -> struct_begin others rbrace_res: add(struct, '$1', '$2', '$3').
others -> lbrace_line: [value_of('$1')].
others ->  other: [value_of('$1')].
others -> other others: add('$1', '$2').
others -> lbrace_begin others rbrace_res: add('$1', '$2') ++ [value_of('$3')].
others -> brace_block: '$1'.
others -> brace_block others: add('$1', '$2').
brace_block -> lbrace_line others rbrace_res: add('$1', '$2') ++ [value_of('$3')].
rbrace_res -> rbrace: '$1'.
rbrace_res -> rbrace_semicolon: '$1'.
Erlang code.

value_of({_,_, V}) -> V;
value_of(V) -> V.

add(struct, A) ->
 Va=  value_of(A),
 {struct, [Va]};

add(A, B) ->
 Va=  value_of(A),
 [Va | B].

add(Name, A, {Name, B}) ->
 Va =  value_of(A),
 {Name, [Va| B]};

add(Name, A, B) ->
 Va =  value_of(A),
 {Name, [Va| B]}.

add(Name, A,  Others, C) ->
 Va=  value_of(A),
 Vc = value_of(C),
 {Name,  [Va | Others] ++ [Vc]}.

parse_result({struct, ["struct" ++ _ = StructLine |_ ] = Values}) ->
  struct_to_event(StructLine, Values);
parse_result({struct, [_, "struct" ++ _ = StructLine |_ ] = Values}) ->
  struct_to_event(StructLine, Values);
parse_result({Name, Values}) ->
  {Name, Values}.

struct_to_event(StructLine, Values) ->
  [_, Name | _] = binary:split(erlang:list_to_binary(StructLine), <<" ">>),
  case re:run(Name, "Event", []) of
      {match, _} ->
         {event, Values};
       _->
        {struct, Values}
  end.