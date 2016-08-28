defmodule ExACN.PDU.FlagsTest do
  use ExUnit.Case

  alias ExACN.PDU.Flags

  test "Decoding no flags" do
    assert Flags.decode_flags(<< 0::size(4)>>) == %Flags{length: false, vector: false, header: false, data: false}
  end

  test "Decoding with a length flag" do
    assert Flags.decode_flags(<< 8::size(4)>>) == %Flags{length: true, vector: false, header: false, data: false}
  end

  test "Decoding with a vector flag" do
    assert Flags.decode_flags(<< 4::size(4)>>) == %Flags{length: false, vector: true, header: false, data: false}
  end

  test "Decoding with a header flag" do
    assert Flags.decode_flags(<< 2::size(4)>>) == %Flags{length: false, vector: false, header: true, data: false}
  end

  test "Decoding with a data flag" do
    assert Flags.decode_flags(<< 1::size(4)>>) == %Flags{length: false, vector: false, header: false, data: true}
  end

  test "Decoding with multiple flag" do
    assert Flags.decode_flags(<< 11::size(4)>>) == %Flags{length: true, vector: false, header: true, data: true}
  end

  test "Decoding with extra trailing data" do
    assert Flags.decode_flags(<< 179, 23, 54, 169, 54, 200 >>) == %Flags{length: true, vector: false, header: true, data: true}
  end

  test "Encode with no flags" do
    assert Flags.encode_flags(%Flags{length: false, vector: false, header: false, data: false}) == << 0::size(4) >>
  end

  test "Encode with a length flag" do
    assert Flags.encode_flags(%Flags{length: true, vector: false, header: false, data: false}) == << 8::size(4) >>
  end

  test "Encode with a vector flag" do
    assert Flags.encode_flags(%Flags{length: false, vector: true, header: false, data: false}) == << 4::size(4) >>
  end

  test "Encode with a header flag" do
    assert Flags.encode_flags(%Flags{length: false, vector: false, header: true, data: false}) == << 2::size(4) >>
  end

  test "Encode with a data flag" do
    assert Flags.encode_flags(%Flags{length: false, vector: false, header: false, data: true}) == << 1::size(4) >>
  end

  test "Encode with multiple flags" do
    assert Flags.encode_flags(%Flags{length: true, vector: false, header: true, data: true}) == << 11::size(4) >>
  end
end
