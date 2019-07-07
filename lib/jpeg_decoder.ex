use Bitwise
defmodule JpegDecoder do
  @moduledoc """
  Documentation for JpegDecoder.
  """

  @doc """
  Hello world.
  ## Examples

  iex> JpegDecoder.hello()
  :world

  """
  def main(arg \\ "huff_simple0.jpg") do
    int_list =
      File.read!(arg)

    try do
      <<0xFF, 0xD8, jfif::binary>> = int_list

      <<
        0xFF,
        0xE0,
        seg_size::size(16),
        0x4A,
        0x46,
        0x49,
        0x46,
        0x00,
        jfif_version1,
        jfif_version2,
        density_units,
        x_density::size(16),
        y_density::size(16),
        x_thumbnail,
        y_thumbnail, other::binary
      >> = jfif

      IO.puts("Length: The number of following date bytes is #{seg_size - 2}")

      IO.puts("JFIF version: #{jfif_version1}.0#{jfif_version2}")

      IO.puts(
        "Density units: #{
          case density_units do
            0 -> "No units; width:height pixel aspect ratio = Ydensity:Xdensity"
            1 -> "Pixels per inch (2.54 cm)"
            2 -> "Pixels per centimeter"
          end
        }"
      )

      IO.puts("Xdensity: #{x_density}")
      IO.puts("Ydensity: #{y_density}")

      IO.puts("Xthumbnail: #{x_thumbnail}")
      IO.puts("Xthumbnail: #{y_thumbnail}")

      thumbnail_data =  Enum.slice(other, 0, x_thumbnail * y_thumbnail * 3)
      IO.puts("Thumbnail data: #{thumbnail_data}")


      other
      |> other_app_seg
      |> dqt
      |> sof0
      |> dht
      |> sos
      |> data_with_ends

    rescue
      MatchError -> "Not a jpeg file"
    end
  end

  def data_with_ends(image_data) do
    without_end = trunc (((bit_size image_data) / 8) - 2)
    <<scan_data::binary-size(without_end), 0xff, 0xd9>> = image_data
    scan_data
    |> decode_scan
  end

  def decode_scan(data) do
    data
    |> :binary.bin_to_list
    |> filter_zero_after_ff
  end

  def filter_zero_after_ff([0xff, 0x00| data]) do
    [0xff| filter_zero_after_ff(data)]
  end

  def filter_zero_after_ff([a|data]) do
    [a|filter_zero_after_ff(data)]
  end

  def filter_zero_after_ff([]) do
    []
  end

  def sos(<<0xff, 0xda, seg_size::size(16), number_of_components_in_scan, other::binary>>) do

    t = (2 * number_of_components_in_scan)
    <<_::binary-size(t), ignorable_bytes::size(24), new_other::binary>> = other
    new_other
  end


  def sof0(<<0xff, 0xc0, seg_size::size(16), data_precision, image_height::size(16), image_width::size(16), number_of_components, other::binary>>) do
    slice_len = seg_size - 2
    IO.puts("The size of start of frame is #{slice_len}")

    IO.puts("Data precision: #{data_precision}")

    IO.puts("Number of Components: " <> case number_of_components do
      1 -> "grey scaled"
      3 -> "color YcbCr or YIQ"
      4 -> "color CMYK"
    end)

    each_component_size = number_of_components * 3

    <<each_component::binary-size(each_component_size), new_other::binary>> = other
    decode_each_component(each_component)
    new_other
  end

  def decode_each_component(<<component_id, sampling_factors_vertical::size(4),sampling_factors_horizontal::size(4), quantization_table_num ,others::binary>>) do
    IO.puts("Component Id: " <> case component_id do
      1 -> "Y"
      2 -> "Cb"
      3 -> "Cr"
      4 -> "I"
      5 -> "Q"
    end)
    IO.puts("Sampling Factors Vertical: #{sampling_factors_vertical}")
    IO.puts("Sampling Factors Horizontal: #{sampling_factors_horizontal}")
    IO.puts("Quantization Table Num: #{quantization_table_num}")
    decode_each_component(others)
  end

  def decode_each_component(<<>>) do

  end

  def dht(<<0xff, 0xc4, seg_size::size(16), other::binary>>) do
    slice_len = seg_size - 2
    IO.puts("The size of start of Define Huffman Table is #{slice_len}")
    IO.puts("Length of Huffman table: #{seg_size}")
    parse_huffman(other, slice_len)
  end


  def parse_huffman(<<table_class::size(4), type_of_ht::size(4), number_of_symbols::binary-size(16), other::binary>>, count) when count != 0 do

    <<num1, num2, num3, num4, num5, num6, num7, num8, num9, num10, num11, num12, num13, num14, num15, num16>> = number_of_symbols
    total_symbols = num1+ num2+ num3+ num4+ num5+ num6+ num7+ num8+ num9+ num10+ num11+ num12+ num13+ num14+ num15+ num16
    <<num1_sym::binary-size(num1),num2_sym::binary-size(num2), num3_sym::binary-size(num3),num4_sym::binary-size(num4),num5_sym::binary-size(num5),num6_sym::binary-size(num6),num7_sym::binary-size(num7),num8_sym::binary-size(num8),num9_sym::binary-size(num9),num10_sym::binary-size(num10),num11_sym::binary-size(num11),num12_sym::binary-size(num12),num13_sym::binary-size(num13),num14_sym::binary-size(num14),num15_sym::binary-size(num15),num16_sym::binary-size(num16), t_other::binary>> = other
    IO.puts("Table Class: #{case table_class do
      0 -> "DC Table"
      1 -> "AC Table"
    end}")
    IO.puts("Type of HT: #{type_of_ht}")

    num_arr = Enum.to_list(1..16)
    num_sym_arr = [num1_sym, num2_sym,num3_sym,num4_sym,num5_sym,num6_sym,num7_sym,num8_sym,num9_sym,num10_sym,num11_sym,num12_sym,num13_sym,num14_sym, num15_sym, num16_sym]
    zipped_huff = List.zip [num_arr, num_sym_arr]

    huff_map = parse_huff(0, zipped_huff)
    IO.inspect huff_map

    parse_huffman(t_other, count - total_symbols - 17)
  end

  def parse_huffman(end_of_huff, 0) do
    end_of_huff
  end

  def parse_huff(pre, [{0, _}|other]) do
    parse_huff(pre, other)
  end

  def parse_huff(pre, [{len, nums}|others]) do
    new_pre = if pre != 0 do
       pre + 1
    else
      pre
    end
    pre_str = Integer.to_string(new_pre, 2)

    {new_pre_num, huff_tuple} = get_values(pre_str, len, nums)

    [huff_tuple |  parse_huff(new_pre_num - 1, others)]
  end

  def parse_huff(_, []) do
    []
  end

  def get_values(pre_str, len, nums) do
    len_diff = len - (String.length pre_str)
    new_pre_str = pre_str <> adding_zeros(len_diff)

    new_pre_int = new_pre_str |> String.to_integer(2)
    Enum.reduce(:binary.bin_to_list(nums), {new_pre_int, []}, (fn x, {num, acc_tuples} -> {num+1, [{num, x}|acc_tuples]} end))
  end

  def adding_zeros(num) when num > 0 do
    "0" <> adding_zeros(num - 1)
  end

  def adding_zeros(0) do
    ""
  end

  def dqt(<<0xff, 0xdb, seg_size::size(16), other::binary>>) do
    slice_len = seg_size - 2

    IO.puts("The size of dqt table is #{slice_len}")

    t = 8 * slice_len
    <<old::size(t), new_other::binary>> = other
    new_other
  end

  def other_app_seg(t) do
    other_app_seg_size = parse_other_app_seg(t) * 8
    <<old::size(other_app_seg_size ), other::binary>> = t
    other
  end

  def parse_other_app_seg(<<0xff, seg_mark, seg_size::size(16), other::binary>>) when seg_mark >= 0xe1 and seg_mark <= 0xef do
    slice_len = seg_size - 2

    IO.puts("The length of FF #{Integer.to_string(seg_mark, 16)} is #{slice_len}")

    t = 8 * slice_len
    <<old::size(t), new_other::binary>> = other
    4 + slice_len + parse_other_app_seg(new_other)
  end

  def parse_other_app_seg(_)  do
    0
  end
end
