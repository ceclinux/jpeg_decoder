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

    t = (2 * number_of_components_in_scan) * 8
    <<old::size(t), ignorable_bytes::size(24), new_other::binary>> = other
    new_other
  end


  def sof0(<<0xff, 0xc0, seg_size::size(16), data_precision, image_height::size(16), image_width::size(16), number_of_components, other::binary>>) do
    slice_len = seg_size - 2
    IO.puts("The size of start of frame is #{slice_len}")

    IO.puts("Data precision: #{data_precision}")

    t = number_of_components * 3 * 8
    <<old::size(t), new_other::binary>> = other
    new_other
  end

  def dht(<<0xff, 0xc4, seg_size::size(16), num_of_ht::size(4), type_of_ht::size(1), 0::size(3), number_of_symbols::binary-size(16), other::binary>>) do
    slice_len = seg_size - 2
    IO.puts("The size of start of Define Huffman Table is #{slice_len}")

    IO.puts("Length of Huffman table: #{seg_size}")
    IO.puts("Number of HT: #{num_of_ht}")
    IO.puts("Type of HT: #{type_of_ht}")
    <<num1, num2, num3, num4, num5, num6, num7, num8, num9, num10, num11, num12, num13, num14, num15, num16>> = number_of_symbols
    total =  num1+ num2+ num3+ num4+ num5+ num6+ num7+ num8+ num9+ num10+ num11+ num12+ num13+ num14+ num15+ num16
    # num1 = num1 * 8
    # num2 = num2 * 8
    # num3 = num3 * 8
    # num4 = num4 * 8
    # num5 = num5 * 8
    # num6 = num6 * 8
    # num7 = num7 * 8
    # num8 = num8 * 8
    # num9 = num9 * 8
    # num10 = num10 * 8
    # num11 = num11 * 8
    # num12 = num12 * 8
    # num13 = num13 * 8
    # num14 = num14 * 8
    # num15 = num15 * 8
    # num16 = num16 * 8

    <<num1_sym::binary-size(num1),num2_sym::binary-size(num2), num3_sym::binary-size(num3),num4_sym::binary-size(num4),num5_sym::binary-size(num5),num6_sym::binary-size(num6),num7_sym::binary-size(num7),num8_sym::binary-size(num8),num9_sym::binary-size(num9),num10_sym::binary-size(num10),num11_sym::binary-size(num11),num12_sym::binary-size(num12),num13_sym::binary-size(num13),num14_sym::binary-size(num14),num15_sym::binary-size(num15),num16_sym::binary-size(num16), t_other::binary>> = other
    IO.puts num1
    IO.puts num2
    IO.puts num3
    IO.puts num4
    IO.puts num5
    IO.puts num6
    IO.puts num7
    IO.puts num8
    IO.puts num9
    IO.puts num10
    IO.puts num11
    IO.puts num12
    IO.puts num13
    IO.puts num14
    IO.puts num15
    IO.puts num16
    IO.inspect num3_sym

    t = (slice_len - 17) * 8
    <<old::size(t), new_other::binary>> = other
    t_other
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
