defmodule IdenticonTest do
  use ExUnit.Case
  doctest Identicon

  test "'hash_input' always produce the same list of hexadecimals for the same input string" do
    assert Identicon.hash_input(%Identicon.Image{ input: "banana" })
             ===
           Identicon.hash_input(%Identicon.Image{ input: "banana" })
  end

end
