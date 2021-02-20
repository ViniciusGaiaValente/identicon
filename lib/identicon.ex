defmodule Identicon do
  @moduledoc """

    Identicon module contains helper functions to build unique and reproduceble avatars.
    Identicons are 250px by 250px, composed by 25 squares os 50px by 50px.
    Each square may or may not be colored with a random color.
    The first 2 columns of an identicon are mirrored with the 2 last ones.
    The same string always generate the same identicon.
    Identicons are saved at /image directory as .png.

  """

  @doc """

    Recives a string as input and generates a unique identicon based on it.

  """
  def generate_identicon(input) do
    %Identicon.Image{ input: input }
    |> hash_input()
    |> build_color()
    |> build_grid()
    |> build_pixel_map()
    # |> render_image()
    # |> save_image(input)
  end

  @doc """

    Returns true if the input number is even and false if its odd

  # Examples

      iex> Identicon.is_even(1)
      false
      iex> Identicon.is_even(2)
      true

  """
  def is_even(number) do
    rem(number, 2) === 0
  end

  @doc """

    Get the md5 hash of the inputed string as an list of hexadecimals

  # Examples

      iex> Identicon.hash_input(%Identicon.Image{ input: "banana" })
      %Identicon.Image{
        color: nil,
        grid: nil,
        hex: [114, 179, 2, 191, 41, 122, 34, 138, 117, 115, 1,
        35, 239, 239, 124, 65],
        input: "banana",
        pixel_map: nil
      }

  """
  def hash_input(%Identicon.Image{input: input} = image) do
    %Identicon.Image{ image | hex: :crypto.hash(:md5, input) |> :binary.bin_to_list() }
  end

  @doc """

    Builds an RGB color based on the first three elements from the 'hex:' list

  # Examples

      iex> Identicon.build_color(%Identicon.Image{ hex: [114, 179, 2, 191, 41, 122, 34, 138, 117, 115, 1, 35, 239, 239, 124, 65] })
      %Identicon.Image{
        color: {114, 179, 2},
        grid: nil,
        hex: [114, 179, 2, 191, 41, 122, 34, 138, 117, 115, 1,
        35, 239, 239, 124, 65],
        pixel_map: nil
      }

  """
  def build_color(%Identicon.Image{hex: [r, g, b | _tail]} = image) do
    %Identicon.Image{image | color: {r, g, b}}
  end

  @doc """

    Return a list of indexes representing which of the 25 possible squares should be filled at the final identicon.

  # Examples

      iex> Identicon.build_grid(%Identicon.Image{ hex: [114, 179, 2, 191, 41, 122, 34, 138, 117, 115, 1, 35, 239, 239, 124, 65] })
      %Identicon.Image{
        color: nil,
        grid: [0, 2, 4, 7, 10, 11, 13, 14, 22],
        hex: [114, 179, 2, 191, 41, 122, 34, 138, 117, 115, 1,
        35, 239, 239, 124, 65],
        pixel_map: nil
      }

  """
  def build_grid(%Identicon.Image{hex: bytes} = image) do
    grid = bytes
      |> Enum.chunk_every(3, 3, :discard)
      |> Enum.map(fn x -> mirror_list(x) end)
      |> List.flatten()
      |> Enum.with_index()
      |> Enum.filter(fn {value, _index} -> is_even(value) end)
      |> Enum.map(fn {_value, index} -> index end)
      |> Enum.to_list()

    %Identicon.Image{image | grid: grid}
  end

  @doc """

    Gets all the elemts on a list except for the last one and add them at the end of the list in reverse order

  # Examples

      iex> Identicon.mirror_list([ 1, 2, 3 ])
      [ 1, 2, 3, 2, 1 ]
      iex> Identicon.mirror_list([ 0, 7, 4, 1 ])
      [ 0, 7, 4, 1, 4, 7, 0 ]

  """
  def mirror_list(list) do
    [ _ | tail ] = Enum.reverse(list)
      Enum.concat(list, tail)
  end

  @doc """

    Build a pixel map based on the provided grid, each element is a map that represents the 'bottom_right' and 'top_left' points of a square.
    The provided grid sould be a list of integers representing the indexes of the squares that should be drawed

  # Examples

      iex> Identicon.build_pixel_map(%Identicon.Image{ grid: [0, 2, 4, 7, 10, 11, 13, 14, 22] })
      %Identicon.Image{
        color: nil,
        grid: [0, 2, 4, 7, 10, 11, 13, 14, 22],
        hex: nil,
        input: nil,
        pixel_map: [
          %{bottom_right: {50, 50}, top_left: {0, 0}},
          %{bottom_right: {150, 50}, top_left: {100, 0}},
          %{bottom_right: {250, 50}, top_left: {200, 0}},
          %{bottom_right: {150, 100}, top_left: {100, 50}},
          %{bottom_right: {50, 150}, top_left: {0, 100}},
          %{bottom_right: {100, 150}, top_left: {50, 100}},
          %{bottom_right: {200, 150}, top_left: {150, 100}},
          %{bottom_right: {250, 150}, top_left: {200, 100}},
          %{bottom_right: {150, 250}, top_left: {100, 200}}
        ]
      }


  """
  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map =
      Enum.map grid, (fn x ->
        get_drwaing_points(x)
      end)

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  @doc """

    Based on a number returns the top left and the bottom right corners of a square that should be drawed.
    This function are backed by 2 premisses, the returned square is a 50px by 50px square and it will be placed at a 250px by 250px square.

  """
  def get_drwaing_points(index) do
    horizontal = rem(index, 5) * 50
    vertical = div(index, 5) * 50
    %{
      top_left: { horizontal, vertical },
      bottom_right: { horizontal + 50, vertical + 50 }
    }
  end

  @doc """

    For each element on 'pixel_map', 'render_image' draw squares based on the 'top_left' and 'bottom_right' corners.
    There is 25 possible 50px by 50px squares to be builded (indexes 0 to 24) resulting on a 250px by 250px, only the indexes present in the grid should be filled, all the other ones remain blank.
    The 'color' field should define witch RGB color will be used to fill the squares on the 'pixel_map'.

  """
  def render_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.each(pixel_map, fn %{top_left: top_left, bottom_right: bottom_right} ->
      :egd.filledRectangle(image, top_left, bottom_right, fill)
    end)

    :egd.render(image)
  end

  @doc """

    Saves the imputed image as a .png file on /images folder at the project root folder.

  """
  def save_image(image, filename) do
    File.write("images/#{filename}.png", image)
  end

end
