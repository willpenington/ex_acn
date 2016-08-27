defmodule ExACN.PDU do
  defstruct vector: <<>>, header: <<>>, data: <<>>
  @moduledoc """
  Packet Data Unit encoding

  Common functions for processing the PDU format used across the ACN
  specification
  """

  @type t :: %ExACN.PDU{vector: binary(), header: binary(), data: binary()}

  @spec build_body(t, t) :: binary()
  defp build_body(pdu, nil) do
    pdu.vector <> pdu.header <> pdu.data
  end

  defp build_body(pdu, previous) do
    [:vector, :header, :data]
    |> Enum.map(fn field -> {Map.get(pdu, field), Map.get(previous, field)} end)
    |> Enum.filter(fn {current, previous} -> current != previous end)
    |> Enum.map(fn {current, _} -> current end)
    |> Enum.join
  end

  @spec length_bits(1 | 2) :: integer()
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

  @doc ~S"""
  Encode a single PDU into binary.

  The flags for vector, header and data will be set based on the previous packet
  """
  @spec pack_single(t, t | nil) :: binary()
  def pack_single(pdu, previous \\ nil) do
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

  @doc ~S"""
  Pack a series of PDUs into a binary
  """
  @spec pack([t], t) :: binary()
  def pack(pdu_sequence, prev_pdu \\ nil) do
    {data, _} = Enum.reduce(pdu_sequence, {<<>>, prev_pdu}, fn(pdu, {data, prev}) -> {data <> pack_single(pdu, prev), pdu} end)
    data
  end

  defp extract_vector(body, 1, _, _, previous) do
    {previous.vector, body}
  end

  defp extract_vector(body, 0, length, vec_length, _) do
    header_and_data_length = length - vec_length
    << vector::binary-size(vec_length), header_and_data::binary-size(header_and_data_length) >> = body
    {vector, header_and_data}
  end

  defp extract_header_and_data(header_and_data, _, header_length, 0, 0) do
    header_size = header_length.(header_and_data)
    << header::binary-size(header_size), data::binary >> = header_and_data
    {header, data}
  end

  defp extract_header_and_data(header_and_data, previous, _, 0, 1) do
    {header_and_data, previous.data}
  end

  defp extract_header_and_data(header_and_data, previous, _, 1, 0) do
    {previous.header, header_and_data}
  end

  defp extract_header_and_data(_, previous, _, 1, 1) do
    {previous.header, previous.data}
  end

  @doc ~S"""
  Decode a single PDU from the start of the start a binary

  The previous PDU is required to get the correct value if the vector, header or data flags
  are set. The vector length is a fixed integer 
  """
  @spec unpack_single(binary(), t | nil, integer(), integer() | (binary() -> integer())) :: {:ok, t, binary()}
  def unpack_single(encoded, previous, vec_length, header_length) when is_integer(header_length) do
    unpack_single(encoded, previous, vec_length, fn _ -> header_length end)
  end

  def unpack_single(encoded, previous, vec_length, header_length) do
    <<length_flag::size(1), vector_flag::size(1), header_flag::size(1), data_flag::size(1), _::bits >> = encoded
    length_bits_encoded = length_bits(length_flag)
    << _::bits-size(4), length::size(length_bits_encoded), _::binary >> = encoded
    preamble_bytes_encoded = preamble_bytes(length_flag)
    body_bytes = length - preamble_bytes_encoded
    << _::bytes-size(preamble_bytes_encoded), body::binary-size(body_bytes), tail::binary >> = encoded

    {vector, header_and_data} = extract_vector(body, vector_flag, body_bytes, vec_length, previous)


    {header, data} = extract_header_and_data(header_and_data, previous, header_length, header_flag, data_flag)

    pdu = %ExACN.PDU{vector: vector, header: header, data: data}

    {:ok, pdu, tail}
  end

  @doc """
  Unpack a binary into a set of PDUs


  """
  @spec unpack(binary(), integer(), (binary() -> integer())) :: [t]
  def unpack(<<>>, _, _) do
    []
  end

  def unpack(encoded, vec_length, header_length) do
    unpack(encoded, vec_length, header_length, [], nil)
  end

  defp unpack(encoded, vec_length, header_length, acc, prev) do
    {:ok, pdu, tail} = unpack_single(encoded, prev, vec_length, header_length)
    seq = [pdu | acc]
    case tail do
      <<>> -> Enum.reverse(seq)
      _ -> unpack(tail, vec_length, header_length, seq, pdu)
    end
  end
end
