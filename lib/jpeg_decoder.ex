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
    <<real_data::binary-size(without_end), 0xff, 0xd9>> = image_data
    real_data
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

  def dht(<<0xff, 0xc4, seg_size::size(16), ht_information, number_of_symbols::size(128), other::binary>>) do
    slice_len = seg_size - 2
    IO.puts("The size of start of Define Huffman Table is #{slice_len}")

    IO.puts("Length: #{ht_information}")
    IO.puts("HT information: #{ht_information}")
    IO.puts("Number of Symbols: #{number_of_symbols}")

    t = (slice_len - 17) * 8
    <<old::size(t), new_other::binary>> = other
    new_other
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
