defmodule LruCacheTest do
  use ExUnit.Case
  doctest LruCache

  test "greets the world" do
    assert LruCache.hello() == :world
  end
end
