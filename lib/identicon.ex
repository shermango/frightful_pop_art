defmodule Identicon do
  @moduledoc """
    A module for converting a username string into a identicon picture
  """
  def main(input) do
    input
    |> hash_input
    |> pick_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> draw_image
    |> save_image(input)
  end

  @doc """
    Hashes the given string input, via md5, then converts binary output into a Image struct
    assigning hex key to produced list

  ## Examples

      iex> Identicon.hash_input("banana")
      %Identicon.Image{
        hex: [114, 179, 2, 191, 41, 122, 34, 138, 117, 115, 1, 35, 239, 239, 124, 65]
      }
  """
  def hash_input(input) do
    hex = :crypto.hash(:md5, input)
    |> :binary.bin_to_list

    %Identicon.Image{hex: hex}
  end

  @doc """
    Receives an Image struct and pulls out the R,G,B value based on the first 3
    indexs of the Image.hex list

  ## Examples

      iex> struct = Identicon.hash_input("asdf")
      iex> Identicon.pick_color(struct)
      %Identicon.Image{
        color: {145, 46, 200},
        hex: [145, 46, 200, 3, 178, 206, 73, 228, 165, 65, 6, 141, 73, 90, 181, 112]
      }
  """
  def pick_color(%Identicon.Image{hex: [r, g, b | _ ]} = image) do

    %Identicon.Image{image | color: {r, g, b}}
  end

  def build_grid(%Identicon.Image{hex: hex} = image) do
    grid 
    = hex
    |> Enum.chunk(3)
    |> Enum.map(&mirror_row/1)
    |> List.flatten
    |> Enum.with_index

    %Identicon.Image{image | grid: grid}
  end

  def mirror_row(row) do
    [first, second | _] = row

    row ++ [second, first]
  end

  def filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    grid = Enum.filter grid, fn({code, _}) ->
      rem(code, 2) == 0
    end

    %Identicon.Image{image | grid: grid}
  end

  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map = Enum.map grid, fn({_, index}) -> 
      # calculations are based on a 250px x 250px grid
      horizontal = rem(index, 5) * 50
      vertical = div(index, 5) * 50

      top_left = {horizontal, vertical}
      bottom_right = {horizontal + 50, vertical + 50}

      {top_left, bottom_right}
    end

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  def draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.each pixel_map, fn({start, stop}) -> 
      :egd.filledRectangle(image, start, stop, fill)
    end

    :egd.render(image)
  end

  def save_image(image, input) do
    File.write("#{input}.png", image)
  end
end
