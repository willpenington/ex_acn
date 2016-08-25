defmodule PDUTest do
  use ExUnit.Case
  import ExACN.PDU

  doctest ExACN.PDU

  @encoded_1 << 0, 10, 12, 43, 95, 55, 84, 10, 99, 6 >>
  @decoded_1 %ExACN.PDU{vector: << 12, 43 >>, header: << 95, 55, 84 >>, data: << 10, 99, 6 >>}

  @encoded_2 << 64, 9, 45, 93, 77, 12, 54, 32, 90 >>
  @decoded_2 %ExACN.PDU{vector: << 12, 43 >>, header: << 45, 93, 77>>, data: << 12, 54, 32, 90 >>}

  test "Encode a simple PDU without a previous packet" do
    assert pack(@decoded_1, nil) == @encoded_1
  end

  test "Encode a simple PDU with a previous packet" do
    assert pack(@decoded_2, @decoded_1) == @encoded_2
  end
end
