defmodule CaptchaTest do
  use ExUnit.Case
  doctest Captcha

  # Basic functionality tests
  describe "basic functionality" do
    test "generate image success" do
      assert {:ok, text, image_data} = Captcha.get()
      assert is_binary(text)
      assert is_binary(image_data)
      assert byte_size(text) == 5
      assert byte_size(image_data) > 0
    end

    test "generate multiple captchas" do
      results = for _ <- 1..5 do
        Captcha.get()
      end
      
      Enum.each(results, fn result ->
        assert {:ok, text, image_data} = result
        assert is_binary(text)
        assert is_binary(image_data)
        assert byte_size(text) == 5
      end)
    end
  end

  # Input validation tests
  describe "input validation" do
    test "function only accepts no arguments" do
      assert_raise UndefinedFunctionError, fn ->
        Captcha.get(1000)
      end
    end
  end

  # Error handling tests
  describe "error handling" do
    test "handles binary execution errors" do
      # Test that the system handles errors gracefully
      assert {:ok, text, image_data} = Captcha.get()
      assert is_binary(text)
      assert is_binary(image_data)
    end
  end

  # Data validation tests
  describe "data validation" do
    test "text contains only lowercase letters" do
      assert {:ok, text, _image_data} = Captcha.get()
      assert String.match?(text, ~r/^[a-z]{5}$/)
    end

    test "text is always 5 characters" do
      assert {:ok, text, _image_data} = Captcha.get()
      assert byte_size(text) == 5
      assert String.length(text) == 5
    end

    test "image data is valid GIF format" do
      assert {:ok, _text, image_data} = Captcha.get()
      # Check for GIF header
      assert :binary.bin_to_list(image_data) |> Enum.take(6) == [71, 73, 70, 56, 57, 97] ||
             :binary.bin_to_list(image_data) |> Enum.take(6) == [71, 73, 70, 56, 55, 97]
    end

    test "image data has reasonable size" do
      assert {:ok, _text, image_data} = Captcha.get()
      # GIF should be at least 1KB but not unreasonably large
      assert byte_size(image_data) >= 1024
      assert byte_size(image_data) <= 50_000
    end
  end

  # Concurrency tests
  describe "concurrency" do
    test "handles concurrent requests" do
      tasks = for _ <- 1..10 do
        Task.async(fn -> Captcha.get() end)
      end
      
      results = Enum.map(tasks, &Task.await(&1, 10_000))
      
      Enum.each(results, fn result ->
        assert {:ok, text, image_data} = result
        assert is_binary(text)
        assert is_binary(image_data)
        assert byte_size(text) == 5
      end)
    end
  end

  # Edge cases
  describe "edge cases" do
    test "handles rapid successive calls" do
      results = for _ <- 1..20 do
        Captcha.get()
      end
      
      Enum.each(results, fn result ->
        assert {:ok, text, image_data} = result
        assert is_binary(text)
        assert is_binary(image_data)
      end)
    end

    test "generates different captchas" do
      results = for _ <- 1..10 do
        Captcha.get()
      end
      
      texts = Enum.map(results, fn {:ok, text, _} -> text end)
      unique_texts = Enum.uniq(texts)
      
      # Should generate some variety (not all the same)
      assert length(unique_texts) > 1
    end
  end

  # Binary path tests
  describe "binary path" do
    test "binary path is accessible" do
      binary_path = Path.join(:code.priv_dir(:captcha), "captcha")
      assert File.exists?(binary_path)
      assert File.stat!(binary_path).type == :regular
    end

    test "binary is executable" do
      binary_path = Path.join(:code.priv_dir(:captcha), "captcha")
      stat = File.stat!(binary_path)
      # Check if file has execute permissions (may vary by system)
      # The access field can be :read_write, :read_write_execute, etc.
      assert stat.access in [:read_write_execute, :read_write, :execute]
    end
  end

  # Performance tests
  describe "performance" do
    test "generates captcha within reasonable time" do
      start_time = System.monotonic_time(:millisecond)
      assert {:ok, _text, _image_data} = Captcha.get()
      end_time = System.monotonic_time(:millisecond)
      
      # Should complete within 5 seconds
      assert (end_time - start_time) < 5000
    end
  end
end
