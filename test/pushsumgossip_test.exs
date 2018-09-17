defmodule PUSHSUMGOSSIPTest do
  use ExUnit.Case
  doctest PUSHSUMGOSSIP

  test "greets the world" do
    IO.inspect(PUSHSUMGOSSIP.start([1,2,3]), limit: :infinity)
    #assert PUSHSUMGOSSIP.hello() == :world
  end
end
