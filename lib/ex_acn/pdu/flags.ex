defmodule ExACN.PDU.Flags do
  defstruct length: false, vector: false, header: false, data: false
  @moduledoc """
  Functions for processing flags at the beginning of PDUs.

  These flags are encoded in the first four bits of the PDU and indicate if it
  shares common data with the previous packet or requires a longer field to
  store the length.
  """

  @typedoc """
  Named PDU flags
  """
  @type t :: %ExACN.PDU.Flags{length: boolean(), vector: boolean(), header: boolean(), data: boolean()}

  # Converts an integer 1 or 0 to a boolean value
  @spec int_to_bool(integer()) :: boolean()
  defp int_to_bool(1), do: true
  defp int_to_bool(0), do: false

  # Converts a boolean value into an integer 1 or 0 for encoding
  @spec bool_to_int(boolean()) :: integer()
  defp bool_to_int(true), do: 1
  defp bool_to_int(false), do: 0

  @doc """
  Read flags from the beginning of a binary or bit string

  Only the first four bits are checked and the rest is ignored. It will fail if the
  bitstring is less than 4 bits long.
  """
  @spec decode_flags(binary() | bitstring()) :: t
  def decode_flags(data) do
    << length_int::size(1), vector_int::size(1), header_int::size(1), data_int::size(1), _::bits >> = data
    length_flag = int_to_bool(length_int)
    vector_flag = int_to_bool(vector_int)
    header_flag = int_to_bool(header_int)
    data_flag = int_to_bool(data_int)

    %ExACN.PDU.Flags{length: length_flag, vector: vector_flag, header: header_flag, data: data_flag}
  end

  @doc """
  Encodes the flags as bitstring.

  The resulting bitstring will be four bits long
  """
  @spec encode_flags(t) :: bitstring()
  def encode_flags(flags) do
    length_int = bool_to_int(flags.length)
    vector_int = bool_to_int(flags.vector)
    header_int = bool_to_int(flags.header)
    data_int = bool_to_int(flags.data)
    << length_int::size(1), vector_int::size(1), header_int::size(1), data_int::size(1) >>
  end

  @doc """
  Calculate the number of bits required to encode the length value for a PDU with the given
  flags.
  """
  @spec length_bits(t) :: integer()
  def length_bits(%ExACN.PDU.Flags{length: true}), do: 20
  def length_bits(%ExACN.PDU.Flags{length: false}),  do: 12

  @doc """
  Calculate the number of bytes required to encode the preamble (flags and length) for a PDU
  with the given flags.
  """
  @spec preamble_bytes(t) :: integer()
  def preamble_bytes(%ExACN.PDU.Flags{length: true}), do: 3
  def preamble_bytes(%ExACN.PDU.Flags{length: false}), do: 2

end
