defmodule LRU.Cache.Test do
  use ExUnit.Case, async: true

  # test values

  @max_size 3

  @key1 "apple"
  @value1 "32391"

  @key2 "banana"
  @value2 "93827"

  @key3 "cottage cheese"
  @value3 64839

  @key4 :dill_pickle
  @value4 "167"

  describe "general cache operations not full and proper lru updates" do
    test "incorrect size" do
      assert catch_error(LRU.Cache.new(-2)) == :function_clause
    end

    test "nil key" do
      cache = LRU.Cache.new(2)

      assert catch_error(LRU.Cache.put(cache, nil, 3)) == :function_clause
    end

    test "correct insert and retrieval" do
      cache = LRU.Cache.new(@max_size)

      assert 0 = cache.size

      {@value1, _c} =
        cache
        |> LRU.Cache.put(@key1, @value1)
        |> LRU.Cache.get(@key1)
    end

    test "insert same key same value, correct retrieval" do
      {@value1, _cache} =
        LRU.Cache.new(@max_size)
        |> LRU.Cache.put(@key1, @value1)
        |> LRU.Cache.put(@key1, @value1)
        |> LRU.Cache.get(@key1)
    end

    test "insert same key different value, correct retrieval" do
      cache = LRU.Cache.new(@max_size)
      assert {0, nil} = cache.lru

      cache = cache |> LRU.Cache.put(@key1, @value1)
      assert {1, {{0, "apple"}, "apple", nil, nil}} = cache.lru

      # After we do the first access of key1, the lru should have a non-zero
      # access time for key1

      {@value1, cache} = LRU.Cache.get(cache, @key1)

      assert {1, {{time, "apple"}, "apple", nil, nil}} = cache.lru
      assert time > 0

      # Once we insert the updated value for key1, the lru value should
      # revert back to 0

      cache = LRU.Cache.put(cache, @key1, @value2)

      assert {1, {{0, "apple"}, "apple", nil, nil}} = cache.lru

      # Upon first access of the new value the lru should have a non-zero
      # access time for key1

      {@value2, cache} = LRU.Cache.get(cache, @key1)

      assert {1, {{time, "apple"}, "apple", nil, nil}} = cache.lru
      assert time > 0
    end
  end

  describe "correct lru cache operations when full" do
    test "second to last element inserted is not accessed" do
      # 121234 (key 3 is lru, with max_size of 3)

      cache =
        LRU.Cache.new(@max_size)
        |> LRU.Cache.put(@key1, @value1)
        |> LRU.Cache.put(@key2, @value2)

      {@value1, cache} = LRU.Cache.get(cache, @key1)
      {@value2, cache} = LRU.Cache.get(cache, @key2)

      cache =
        cache
        |> LRU.Cache.put(@key3, @value3)
        |> LRU.Cache.put(@key4, @value4)

      # key 3 has been removed
      assert Map.equal?(
               %{@key1 => @value1, @key2 => @value2, @key4 => @value4},
               cache.value_by_key
             )

      assert {nil, _cache} = LRU.Cache.get(cache, @key3)
    end

    test "beginning element inserted is not accessed" do
      # 123234 (key 1 is lru, with max_size of 3)

      cache =
        LRU.Cache.new(@max_size)
        |> LRU.Cache.put(@key1, @value1)
        |> LRU.Cache.put(@key2, @value2)
        |> LRU.Cache.put(@key3, @value3)

      {@value2, cache} = LRU.Cache.get(cache, @key2)
      {@value3, cache} = LRU.Cache.get(cache, @key3)

      cache = LRU.Cache.put(cache, @key4, @value4)

      # key 1 has been removed
      assert Map.equal?(
               %{@key2 => @value2, @key3 => @value3, @key4 => @value4},
               cache.value_by_key
             )

      assert {nil, _cache} = LRU.Cache.get(cache, @key1)
    end

    test "middle element inserted is not accessed" do
      # 123314 (key 2 is lru, with max_size of 3)

      cache =
        LRU.Cache.new(@max_size)
        |> LRU.Cache.put(@key1, @value1)
        |> LRU.Cache.put(@key2, @value2)
        |> LRU.Cache.put(@key3, @value3)

      {@value3, cache} = LRU.Cache.get(cache, @key3)
      {@value1, cache} = LRU.Cache.get(cache, @key1)

      cache = LRU.Cache.put(cache, @key4, @value4)

      # key 2 has been removed
      assert Map.equal?(
               %{@key1 => @value1, @key3 => @value3, @key4 => @value4},
               cache.value_by_key
             )

      assert {nil, _cache} = LRU.Cache.get(cache, @key2)
    end

    test "middle element inserted is not accessed and last element inserted has same key, no discard" do
      # 123312 (key 2 is lru, with max_size of 3, no lru discard)

      cache =
        LRU.Cache.new(@max_size)
        |> LRU.Cache.put(@key1, @value1)
        |> LRU.Cache.put(@key2, @value2)
        |> LRU.Cache.put(@key3, @value3)

      {@value3, cache} = LRU.Cache.get(cache, @key3)
      {@value1, cache} = LRU.Cache.get(cache, @key1)

      cache = LRU.Cache.put(cache, @key2, @value4)

      # key 2 is still accessible but with new value
      assert Map.equal?(
               %{@key1 => @value1, @key2 => @value4, @key3 => @value3},
               cache.value_by_key
             )

      assert {@value4, _cache} = LRU.Cache.get(cache, @key2)
    end
  end
end
