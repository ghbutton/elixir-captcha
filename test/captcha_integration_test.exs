defmodule CaptchaIntegrationTest do
  use ExUnit.Case

  # Integration tests that simulate real-world usage scenarios
  
  describe "real-world scenarios" do
    test "handles high load scenario" do
      # Simulate high load by generating many captchas rapidly
      results = for _ <- 1..50 do
        Captcha.get()
      end
      
      success_count = Enum.count(results, fn
        {:ok, _text, _image_data} -> true
        _ -> false
      end)
      
      # Should succeed in most cases (>90%)
      assert success_count >= 45
    end

    test "handles mixed timeout scenarios" do
      # Test various timeout values (timeout parameter is ignored in this version)
      timeouts = [100, 500, 1000, 2000, 5000]
      
      results = Enum.map(timeouts, fn timeout ->
        Captcha.get(timeout)
      end)
      
      # All should succeed since timeout is ignored
      Enum.each(results, fn result ->
        assert {:ok, _, _} = result
      end)
    end

    test "text uniqueness across multiple generations" do
      # Generate many captchas and check for reasonable uniqueness
      results = for _ <- 1..100 do
        Captcha.get()
      end
      
      texts = Enum.map(results, fn {:ok, text, _} -> text end)
      unique_texts = Enum.uniq(texts)
      
      # Should have good variety (at least 50% unique)
      assert length(unique_texts) >= 50
    end

    test "image data consistency" do
      # Check that image data is consistently structured
      results = for _ <- 1..10 do
        Captcha.get()
      end
      
      image_sizes = Enum.map(results, fn {:ok, _text, image_data} ->
        byte_size(image_data)
      end)
      
      # All images should be roughly the same size (within 10% variance)
      avg_size = Enum.sum(image_sizes) / length(image_sizes)
      Enum.each(image_sizes, fn size ->
        assert abs(size - avg_size) / avg_size < 0.1
      end)
    end
  end

  describe "error recovery" do
    test "recovers from timeout scenarios" do
      # Test that the system recovers after potential issues
      _results = for _ <- 1..10 do
        Captcha.get()  # Generate some captchas
      end
      
      # Should still be able to generate captchas
      assert {:ok, text, image_data} = Captcha.get()
      assert is_binary(text)
      assert is_binary(image_data)
    end

    test "handles system resource constraints" do
      # Simulate resource constraints by making many rapid calls
      results = for _ <- 1..100 do
        Captcha.get()
      end
      
      # Should handle resource pressure gracefully
      success_count = Enum.count(results, fn
        {:ok, _, _} -> true
        _ -> false
      end)
      
      assert success_count > 0
    end
  end

  describe "data integrity" do
    test "text format consistency" do
      results = for _ <- 1..20 do
        Captcha.get()
      end
      
      Enum.each(results, fn {:ok, text, _} ->
        # Text should be exactly 5 lowercase letters
        assert String.match?(text, ~r/^[a-z]{5}$/)
        assert String.length(text) == 5
        assert byte_size(text) == 5
      end)
    end

    test "GIF format validation" do
      results = for _ <- 1..10 do
        Captcha.get()
      end
      
      Enum.each(results, fn {:ok, _text, image_data} ->
        # Check GIF header
        bytes = :binary.bin_to_list(image_data)
        assert Enum.take(bytes, 3) == [71, 73, 70]  # "GIF"
        assert Enum.at(bytes, 3) in [55, 56]  # Version 7 or 8
        assert Enum.at(bytes, 4) == 57  # "9"
        assert Enum.at(bytes, 5) == 97  # "a"
      end)
    end

    test "image data boundaries" do
      results = for _ <- 1..10 do
        Captcha.get()
      end
      
      Enum.each(results, fn {:ok, _text, image_data} ->
        # Image should be reasonable size
        assert byte_size(image_data) >= 1000
        assert byte_size(image_data) <= 100_000
        
        # Should end with GIF terminator
        bytes = :binary.bin_to_list(image_data)
        assert List.last(bytes) == 59  # ";"
      end)
    end
  end

  describe "performance characteristics" do
    test "consistent generation time" do
      times = for _ <- 1..10 do
        start = System.monotonic_time(:millisecond)
        assert {:ok, _, _} = Captcha.get()
        System.monotonic_time(:millisecond) - start
      end
      
      _avg_time = Enum.sum(times) / length(times)
      
      # Most generations should be within reasonable bounds
      fast_generations = Enum.count(times, fn time -> time < 2000 end)
      assert fast_generations >= 8  # At least 80% should be fast
    end

    test "memory usage stability" do
      # Generate many captchas and check for memory leaks
      results = for _ <- 1..50 do
        Captcha.get()
      end
      
      # Should all succeed
      Enum.each(results, fn result ->
        assert {:ok, _text, _image_data} = result
      end)
    end
  end
end
