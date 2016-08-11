defmodule ExACN.PDU do
  defstruct vector: <<>>, header: <<>>, data: <<>>

  defp build_body(pdu, previous) do
    [:vector, :header, :data]
    |> Enum.map(fn field -> {Map.get(pdu, field), Map.get(previous, field)})
    |> Enum.filter(fn {current, previous} -> current == previous end)
    |> Enum.map(fn {current, previous} -> current end)
    |> Enum.join
  end

  defp length_bits(length_flag) do
    case length_flag do
      true -> 20
      false -> 12
    end
  end

  defp preamble_bytes(length_flag) do
    case length_flag do
      true -> 3
      false -> 2
    end
  end

  def pack(pdu, previous) do
    vector_flag = pdu.vector == previous.vector
    header_flag = pdu.header == previous.header
    data_flag = pdu.data == previous.data

    body = build_body(pdu, previous)

    length = byte_size(body)
    length_flag = length > 2^12 - 3 # less one for binary encoding and two for the preamble

    flags = << length_flag :: size(1), vector_flag :: size(1), header_flag :: size(1), data_flag :: size(1) >>

    flags <> << length + preamble_bytes(length_flag) :: size(length_bits(length_flag)), body >>
  end

  def unpack(encoded, previous, header_length, vec_length) when is_integer(vec_length) do
    unpack(encoded, previous, header_length, fn _ -> vec_length end)
  end

  def unpack(encoded, previous, header_length, vec_length) do
    <<length_flag::size(1), vector_flag::size(1), header_flag::size(1), data_flag::size(1), _::bits >> = encoded
    << _::size(4), length::size(length_bits(length_flag)), body::binary-size(length), _::binary >> = encoded
    << header::binary-size(header_length), vec_and_data::binary-size(length - header_length), tail::binary >> = body

    vector_size = vec_length.(vec_and_data)
    << vector::binary-size(vector_size), data::binary >> = vec_and_data

    pdu = %ExACN.PDU{vector: vector, header: header, data: data}
    {:ok, pdu, tail}
  end
end
