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
  def hello do
    File.read!("huff_simple0.jpg")
  end
end
