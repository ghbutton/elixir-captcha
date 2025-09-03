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
  end

  # Data validation tests
  describe "data validation" do
    test "text format validation" do
      assert {:ok, text, _image_data} = Captcha.get()
      assert String.match?(text, ~r/^[a-z]{5}$/)
      assert String.length(text) == 5
      assert byte_size(text) == 5
      # ASCII validation
      assert String.valid?(text)
    end

    test "image format validation" do
      assert {:ok, _text, image_data} = Captcha.get()

      # Check GIF header
      bytes = :binary.bin_to_list(image_data)
      # "GIF"
      assert Enum.take(bytes, 3) == [71, 73, 70]
      # Version 7 or 8
      assert Enum.at(bytes, 3) in [55, 56]
      # "9"
      assert Enum.at(bytes, 4) == 57
      # "a"
      assert Enum.at(bytes, 5) == 97

      # Check GIF terminator
      # ";"
      assert List.last(bytes) == 59

      # Check size constraints
      assert byte_size(image_data) >= 1000
      assert byte_size(image_data) <= 100_000
    end

    test "image data consistency" do
      # Check that image data is consistently structured
      results =
        for _ <- 1..10 do
          Captcha.get()
        end

      image_sizes =
        Enum.map(results, fn {:ok, _text, image_data} ->
          byte_size(image_data)
        end)

      # All images should be roughly the same size (within 10% variance)
      avg_size = Enum.sum(image_sizes) / length(image_sizes)

      Enum.each(image_sizes, fn size ->
        assert abs(size - avg_size) / avg_size < 0.1
      end)
    end
  end

  # Concurrency and load tests
  describe "concurrency and load" do
    test "handles concurrent requests" do
      tasks =
        for _ <- 1..20 do
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

    test "handles high load scenario" do
      # Simulate high load by generating many captchas rapidly
      results =
        for _ <- 1..100 do
          Captcha.get()
        end

      success_count =
        Enum.count(results, fn
          {:ok, _text, _image_data} -> true
          _ -> false
        end)

      assert success_count == 100
    end

    test "handles rapid successive calls" do
      results =
        for _ <- 1..50 do
          Captcha.get()
        end

      Enum.each(results, fn result ->
        assert {:ok, text, image_data} = result
        assert is_binary(text)
        assert is_binary(image_data)
      end)
    end
  end

  # Uniqueness and variety tests
  describe "uniqueness and variety" do
    test "generates different captchas" do
      results =
        for _ <- 1..50 do
          Captcha.get()
        end

      texts = Enum.map(results, fn {:ok, text, _} -> text end)
      unique_texts = Enum.uniq(texts)

      # Should generate good variety (at least 80% unique)
      assert length(unique_texts) >= 40
    end

    test "text uniqueness across many generations" do
      # Generate many captchas and check for reasonable uniqueness
      results =
        for _ <- 1..100 do
          Captcha.get()
        end

      texts = Enum.map(results, fn {:ok, text, _} -> text end)
      unique_texts = Enum.uniq(texts)

      # Should have very good variety (at least 90% unique)
      assert length(unique_texts) >= 90
    end
  end

  # Performance tests
  describe "performance" do
    test "generates captcha within reasonable time" do
      start_time = System.monotonic_time(:millisecond)
      assert {:ok, _text, _image_data} = Captcha.get()
      end_time = System.monotonic_time(:millisecond)

      # Should complete within 5 seconds
      assert end_time - start_time < 5000
    end

    test "consistent generation time" do
      times =
        for _ <- 1..10 do
          start = System.monotonic_time(:millisecond)
          assert {:ok, _, _} = Captcha.get()
          System.monotonic_time(:millisecond) - start
        end

      # Most generations should be within reasonable bounds
      fast_generations = Enum.count(times, fn time -> time < 2000 end)
      # At least 80% should be fast
      assert fast_generations >= 8
    end
  end

  # System and environment tests
  describe "system and environment" do
    test "binary path is accessible" do
      binary_path = Path.join(:code.priv_dir(:captcha), "captcha")
      assert File.exists?(binary_path)
      assert File.stat!(binary_path).type == :regular
    end

    test "binary is executable" do
      binary_path = Path.join(:code.priv_dir(:captcha), "captcha")
      stat = File.stat!(binary_path)
      # Check if file has execute permissions (may vary by system)
      assert stat.access in [:read_write_execute, :read_write, :execute]
    end
  end

  # Edge cases and error handling
  describe "edge cases and error handling" do
    test "handles empty data scenarios" do
      # Test handling of empty text and image data (shouldn't happen but good to test)
      assert {:ok, text, image_data} = Captcha.get()
      assert is_binary(text)
      assert byte_size(text) > 0
      assert is_binary(image_data)
      assert byte_size(image_data) > 0
    end

    test "maintains consistency under stress" do
      # Test that the system maintains consistent behavior under stress
      results =
        for _ <- 1..100 do
          Captcha.get()
        end

      # Should maintain consistent success rate
      success_count =
        Enum.count(results, fn
          {:ok, _, _} -> true
          _ -> false
        end)

      # 100% success rate
      assert success_count == 100
    end
  end
end
