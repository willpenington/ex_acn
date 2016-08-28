defmodule ExACN.PDU do
  defstruct vector: <<>>, header: <<>>, data: <<>>
  @moduledoc """
  Packet Data Unit encoding

  Common functions for processing the PDU format used across the ACN
  specification
  """

  alias ExACN.PDU.Flags

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


  @doc ~S"""
  Encode a single PDU into binary.

  The flags for vector, header and data will be set based on the previous packet
  """
  @spec pack_single(t, t | nil) :: binary()
  def pack_single(pdu, previous \\ nil) do

    body = build_body(pdu, previous)
    body_length = byte_size(body)

    vector_flag = previous != nil && pdu.vector == previous.vector
    header_flag = previous != nil && pdu.header == previous.header
    data_flag = previous != nil && pdu.data == previous.data
    length_flag = body_length > round(:math.pow(2, 12)) - 3 # less one for binary encoding and two for the preamble

    flags = %Flags{length: length_flag, vector: vector_flag, header: header_flag, data: data_flag}

    encoded_length_bits = Flags.length_bits(flags)
    encoded_length = body_length + Flags.preamble_bytes(flags)
 
    << Flags.encode_flags(flags)::bits, encoded_length::size(encoded_length_bits), body::bytes>>
  end

  @doc ~S"""
  Pack a series of PDUs into a binary
  """
  @spec pack([t], t) :: binary()
  def pack(pdu_sequence, prev_pdu \\ nil) do
    {data, _} = Enum.reduce(pdu_sequence, {<<>>, prev_pdu}, fn(pdu, {data, prev}) -> {data <> pack_single(pdu, prev), pdu} end)
    data
  end

  @spec unpack_body(binary(), Flags.t, t, integer(), integer() | (binary() -> integer())) :: t
  defp unpack_body(data, flags, nil, vec_length, header_length) do
    unpack_body(data, flags, %ExACN.PDU{}, vec_length, header_length)
  end

  defp unpack_body(data, flags = %Flags{vector: false}, prev, vec_length, header_length) do
    << vector::binary-size(vec_length), tail::binary >> = data
    unpack_body(tail, %{flags | vector: true}, %{prev | vector: vector}, vec_length, header_length)
  end

  defp unpack_body(data, flags = %Flags{header: false}, prev, _, header_length) do
    header_length_actual = header_length.(data)
    << header::binary-size(header_length_actual), tail::binary >> = data

    unpack_body(tail, %{flags | header: true}, %{prev | header: header}, nil, nil)
  end

  defp unpack_body(data, flags = %Flags{data: false}, prev, _, _) do
    unpack_body(<<>>, %{flags | data: true}, %{prev | data: data}, nil, nil)
  end

  defp unpack_body(_, _, prev, _, _) do
    prev
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
    # Extract flags
    flags = Flags.decode_flags(encoded)

    # Calculate the length
    length_bits_encoded = Flags.length_bits(flags)
    << _::bits-size(4), length::size(length_bits_encoded), _::binary >> = encoded
    preamble_bytes_encoded = Flags.preamble_bytes(flags)
    body_bytes = length - preamble_bytes_encoded

    # Extract the body
    << _::bytes-size(preamble_bytes_encoded), body::binary-size(body_bytes), tail::binary >> = encoded

    # Unpack the body
    pdu = unpack_body(body, flags, previous, vec_length, header_length)

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
