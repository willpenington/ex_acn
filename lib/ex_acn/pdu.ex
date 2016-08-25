defmodule ExACN.PDU do
  defstruct vector: <<>>, header: <<>>, data: <<>>

  defp build_body(pdu, nil) do
    pdu.vector <> pdu.header <> pdu.data
  end

  defp build_body(pdu, previous) do
    [:vector, :header, :data]
    |> Enum.map(fn field -> {Map.get(pdu, field), Map.get(previous, field)} end)
    |> Enum.filter(fn {current, previous} -> current == previous end)
    |> Enum.map(fn {current, previous} -> current end)
    |> Enum.join
  end

  defp length_bits(length_flag) do
    case length_flag do
      1 -> 20
      0 -> 12
    end
  end

  defp preamble_bytes(length_flag) do
    case length_flag do
      1 -> 3
      0 -> 2
    end
  end

  def pack(pdu, previous) do
    vector_flag = if previous != nil && pdu.vector == previous.vector, do: 1, else: 0
    header_flag = if previous != nil && pdu.header == previous.header, do: 1, else: 0
    data_flag = if previous != nil && pdu.data == previous.data, do: 1, else: 0

    body = build_body(pdu, previous)

    length = byte_size(body)
    length_flag = if length > round(:math.pow(2, 12)) - 3, do: 1, else: 0 # less one for binary encoding and two for the preamble

    flags = << length_flag :: size(1), vector_flag :: size(1), header_flag :: size(1), data_flag :: size(1) >>

    encoded_length_bits = length_bits(length_flag)
    encoded_length = length + preamble_bytes(length_flag)

    << flags::bits, encoded_length::size(encoded_length_bits), body::bytes>>
  end

  def unpack(encoded, previous, header_length, vec_length) when is_integer(vec_length) do
    unpack(encoded, previous, header_length, fn _ -> vec_length end)
  end

  def unpack(encoded, previous, header_length, vec_length) do
    <<length_flag::size(1), vector_flag::size(1), header_flag::size(1), data_flag::size(1), _::bits >> = encoded
    length_bits_encoded = length_bits(length_flag)
    << _::size(4), length::size(length_bits_encoded), body::binary-size(length), _::binary >> = encoded
    vec_and_data_length = length - header_length
    << header::binary-size(header_length), vec_and_data::binary-size(vec_and_data_length), tail::binary >> = body

    vector_size = vec_length.(vec_and_data)
    << vector::binary-size(vector_size), data::binary >> = vec_and_data

    pdu = %ExACN.PDU{vector: vector, header: header, data: data}
    {:ok, pdu, tail}
  end
end
