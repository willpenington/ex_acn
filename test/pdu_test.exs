defmodule PDUTest do
  use ExUnit.Case
  import ExACN.PDU

  doctest ExACN.PDU

  @encoded_1 << 0, 10, 12, 43, 95, 55, 84, 10, 99, 6 >>
  @decoded_1 %ExACN.PDU{vector: << 12, 43 >>, header: << 95, 55, 84 >>, data: << 10, 99, 6 >>}

  test "encode a simple PDU without a previous" do
    assert pack(@decoded_1, nil) == @encoded_1
  end
end
