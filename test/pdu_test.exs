defmodule PDUTest do
  use ExUnit.Case
  import ExACN.PDU

  doctest ExACN.PDU

  @encoded_1 << 0, 10, 12, 43, 95, 55, 84, 10, 99, 6 >>
  @decoded_1 %ExACN.PDU{vector: << 12, 43 >>, header: << 95, 55, 84 >>, data: << 10, 99, 6 >>}

  @encoded_2 << 64, 9, 45, 93, 77, 12, 54, 0, 90 >>
  @decoded_2 %ExACN.PDU{vector: << 12, 43 >>, header: << 45, 93, 77 >>, data: << 12, 54, 0, 90 >>}

  @encoded_3 << 32, 8, 34, 93, 64, 23, 84, 12 >>
  @decoded_3 %ExACN.PDU{vector: << 34, 93 >>, header: << 45, 93, 77 >>, data: << 64, 23, 84, 12 >>}

  @encoded_4 << 16, 7, 65, 22, 76, 19, 40 >>
  @decoded_4 %ExACN.PDU{vector: << 65, 22 >>, header: << 76, 19, 40 >>, data: << 64, 23, 84, 12 >>}

  @encoded_5 << 48, 4, 81, 26 >>
  @decoded_5 %ExACN.PDU{vector: << 81, 26 >>, header: << 76, 19, 40 >>, data: << 64, 23, 84, 12 >>}

  defp encoded_long do
    << 1, 27, 54, 34, 65, 34, 64 >> <> String.duplicate("a", 276)
  end
  defp decoded_long do
    %ExACN.PDU{vector: << 54, 34 >>, header: << 65, 34, 64 >>, data: String.duplicate("a", 276)}
  end

  @vlong_length 792363

  defp vlong_data do
    String.duplicate("a", @vlong_length - 8)
  end
  defp encoded_vlong do
    << 128 + 12, 23, 43, 54, 99, 12, 0, 33 >> <> vlong_data()
  end
  defp decoded_vlong do
    %ExACN.PDU{vector: << 54, 99 >>, header: << 12, 0, 33 >>, data: vlong_data()}
  end

  test "Encode a simple PDU without a previous packet" do
    assert pack_single(@decoded_1, nil) == @encoded_1
  end

  test "Encode a simple PDU with a previous packet with a common vector" do
    assert pack_single(@decoded_2, @decoded_1) == @encoded_2
  end

  test "Encode a simple PDU with a previous packet with a common header" do
    assert pack_single(@decoded_3, @decoded_2) == @encoded_3
  end

  test "Encode a simple PDU with a previous packet with common data" do
    assert pack_single(@decoded_4, @decoded_3) == @encoded_4
  end

  test "Encode a simple PDU with a previous packet with common data and header" do
    assert pack_single(@decoded_5, @decoded_4) == @encoded_5
  end

  test "Encode a long PDU" do
    assert pack_single(decoded_long(), nil) == encoded_long()
  end

  test "Encode a very long PDU" do
    assert pack_single(decoded_vlong(), nil) == encoded_vlong()
  end

  test "Decode a simple PDU without a previous packet" do
    assert unpack_single(@encoded_1, nil, 2, 3) == {:ok, @decoded_1, <<>>}
  end

  test "Decode a simple PDU with a previous packet with a common vector" do
    assert unpack_single(@encoded_2, @decoded_1, 2, 3) == {:ok, @decoded_2, <<>>}
  end

  test "Decode a simple PDU with a previous packet with a common header" do
    assert unpack_single(@encoded_3, @decoded_2, 2, 3) == {:ok, @decoded_3, <<>>}
  end

  test "Decode a simple PDU with a previous packet with common data" do
    assert unpack_single(@encoded_4, @decoded_3, 2, 3) == {:ok, @decoded_4, <<>>}
  end

  test "Decode a simple PDU with a previous packet with common header and data" do
    assert unpack_single(@encoded_5, @decoded_4, 2, 3) == {:ok, @decoded_5, <<>>}
  end

  test "Decode a long PDU" do
    assert unpack_single(encoded_long(), nil, 2, 3) == {:ok, decoded_long(), <<>>}
  end

  test "Decode a very long PDU" do
    assert unpack_single(encoded_vlong(), nil, 2, 3) == {:ok, decoded_vlong(), <<>>}
  end

  test "Decode a sequence of PDUs" do
    encoded_seq = @encoded_1 <> @encoded_2 <> @encoded_3 <> @encoded_4 <> @encoded_5 <> encoded_long()
    decoded_seq = [@decoded_1, @decoded_2, @decoded_3, @decoded_4, @decoded_5, decoded_long()]
    assert unpack(encoded_seq, 2, 3) == decoded_seq
  end

  test "Encode a sequence of PDUs" do
    encoded_seq = @encoded_1 <> @encoded_2 <> @encoded_3 <> @encoded_4 <> @encoded_5 <> encoded_long()
    decoded_seq = [@decoded_1, @decoded_2, @decoded_3, @decoded_4, @decoded_5, decoded_long()]
    assert pack(decoded_seq) == encoded_seq
  end

end
