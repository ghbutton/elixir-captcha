defmodule Captcha do
  @moduledoc """
  Improved captcha generation library that works reliably in both development and production environments.

  This version uses System.cmd instead of Port.open to avoid issues with process management,
  working directory, and environment variables that can cause problems in production deployments.
  """

    @doc """
  Generates a captcha image and returns the text and image data.
  
  Returns:
  - `{:ok, text, image_data}` - Success with 5-character text and GIF image data
  - `{:error, reason}` - If generation fails
  
  ## Examples
  
      iex> {:ok, text, image_data} = Captcha.get()
      iex> is_binary(text)
      true
      iex> byte_size(text)
      5
      iex> is_binary(image_data)
      true
  """
  def get() do
    generate_captcha()
  end

  # Private function that handles the actual captcha generation
  defp generate_captcha() do
    # Clear any leftover messages from previous calls to prevent stale data
    receive do _ -> :ok after 0 -> :ok end

    # Use System.cmd to execute the binary
    case System.cmd(get_binary_path(), []) do
      {data, 0} when byte_size(data) >= 5 ->
        # Successfully got data, parse it
        parse_captcha_data(data)
      {_data, exit_code} ->
        {:error, "Binary exited with code #{exit_code}"}
    end
  end

  # Parse the captcha data: first 5 bytes are text, rest is image
  defp parse_captcha_data(data) do
    case find_gif_header(data) do
      {:ok, text, img} ->
        {:ok, text, img}
      :error ->
        # Fallback: assume first 5 bytes are text
        if byte_size(data) >= 5 do
          <<text::bytes-size(5), img::binary>> = data
          {:ok, text, img}
        else
          {:error, "Insufficient data received"}
        end
    end
  end

  # Find the GIF header in the data and extract text and image properly
  defp find_gif_header(data) do
    # Look for "GIF89" or "GIF87" header
    case :binary.match(data, "GIF8") do
      {pos, _} when pos >= 5 ->
        # Found GIF header, extract text and image
        text = binary_part(data, 0, pos)
        img = binary_part(data, pos, byte_size(data) - pos)
        {:ok, text, img}
      _ ->
        # No GIF header found, use fallback parsing
        :error
    end
  end

  # Get the path to the captcha binary
  defp get_binary_path() do
    Path.join(:code.priv_dir(:captcha), "captcha")
  end
end
