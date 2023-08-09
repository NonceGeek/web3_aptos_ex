defmodule NimbleJson.Parser.Helper do
  import NimbleParsec

  def white_space(min \\ 0) do
    choice([string(" "), string("\\n"), string("\\t"), string("\\r")]) |> times(min: min)
  end

  def quoted_string(min \\ 0) do
    ignore(string("\""))
    |> ascii_string([?a..?z, ?A..?Z, ?0..?9], min: min)
    |> ignore(string("\""))
  end

  def list_separated_by(comb, sep, min \\ 0) do
    sep_comb =
      ignore(sep)
      |> concat(comb)

    times(comb, sep_comb, min: min)
    |> optional()
  end
end