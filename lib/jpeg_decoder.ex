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
      # |> :binary.bin_to_list()

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
      |> parse_other_app_seg
      |> dqt
      |> sof1

    rescue
      MatchError -> "Not a jpeg file"
    end
  end

  def sof1(<<0xff, 0xc0, seg_size::size(16), data_precision, image_height_1, image_width, other::binary>>) do
    slice_len = seg_size - 2
    IO.puts("The size of start of frame is #{slice_len}")

    IO.puts("Data precision: #{data_precision}")

  end

  def dqt(<<0xff, 0xdb, seg_size::size(16), other::binary>>) do
    slice_len = seg_size - 2

    IO.puts("The size of dqt table is #{slice_len}")

    Enum.slice(other, slice_len..-1)
  end

  def parse_other_app_seg(<<0xff, seg_mark, seg_size::size(16), other::binary>>) when seg_mark >= 0xe1 and seg_mark <= 0xef do
    IO.puts("here")
    slice_len = seg_size - 2

    IO.puts("The length of FF #{Integer.to_string(seg_mark, 16)} is #{slice_len}")

    t = 8 * slice_len
    <<old::size(t), new_other::binary>> = other
    4 + slice_len + parse_other_app_seg(new_other)
  end

  def parse_other_app_seg(t)  do
    0
  end
end
