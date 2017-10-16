defmodule LRU.Cache do
  @moduledoc """
  Implements a Cache with basic operations get and put,
  while discarding the Least Recently Used (LRU) entry when full

  Keeps track of key-value access for each entry using
  a map dedicated to tracking timestamps and 
  erlang general balanced tree as a priority queue

  Cache operations for n elements are O(n*log(n))

  For 0(n) performance, a doubly-linked list should be
  used to keep track of the lru, as doubly-linked list
  removals are O(1) and appends to tail are O(1)

  The Elixir/Erlang solution for doubly-linked list 
  performance can be found here:

  https://ferd.ca/yet-another-article-on-zippers.html

  Another optimization is to use an increasing counter
  instead of a timestamp and having to read the clock. Hence
  upon every access increments the cache counter
  """

  # gb_trees (Ologn) used as lru priority queue

  defstruct max_size: 0, size: 0, value_by_key: Map.new, 
  timestamp_by_key: Map.new, lru: :gb_trees.empty()
  
  # The unaccessed timestamp is simply 0 instead of a 
  # millisecond time

  @unaccessed_timestamp 0  


  @doc "Create a new cache given maximum number of entries"
  def new(size) do
    %LRU.Cache{max_size: size}
  end


  @doc "Get cache value given corresponding key"
  def get(%LRU.Cache{} = cache, key) do
    
    # Check if key found
    case Map.has_key?(cache.value_by_key, key) do
      false -> # return nil - consistent with Map API
        {nil, cache}

      true ->
        # Retrieve value and update timestamp data
        value = Map.get(cache.value_by_key, key)

        # Get current timestamp
        current = :os.system_time(:millisecond)

        cache = update_timestamp(cache, key, current)

        {value, cache}
    end
  end


  @doc """
  Put key-value pair into cache.  
  If key already exists, update only if value is different
  """
  def put(%LRU.Cache{} = cache, key, value) do
    # Insert key-value pair -- checking if key already found

    case Map.has_key?(cache.value_by_key, key) do
      false -> 

        # Make sure we have enough room for cache entry
        # If we are at max capacity, discard the LRU entry
        cache = cond do
          cache.max_size == cache.size -> lru_discard(cache)
          true -> cache 
        end

        
        # Proceed with cache insertion
        values = Map.put(cache.value_by_key, key, value)
        
        # Seed timestamp data structure and lru data structure with 
        # @unaccessed_timestamp value
        timestamps = Map.put(cache.timestamp_by_key, key, @unaccessed_timestamp)
        lru = :gb_trees.insert({@unaccessed_timestamp, key}, key, cache.lru)

        # Update persistent structure
        %LRU.Cache{cache | size: cache.size + 1, lru: lru, 
                   value_by_key: values, timestamp_by_key: timestamps}
      
      true ->
        # We have key, just need to determine if value is new or pre-existing
        # Size doesn't change

        prior_value = Map.get(cache.value_by_key, key) 
        
        cond do
          value != prior_value ->  # Pre-existing key has new value

            # Proceed with cache insertion
            values = Map.put(cache.value_by_key, key, value)

            # Update persistent structure
            cache = %LRU.Cache{cache | value_by_key: values}

            # Overwrite key timestamp data to unaccessed yet
            update_timestamp(cache, key, @unaccessed_timestamp)
            
          # Pre-existing key has same value -- doesn't change anything
          true ->  cache 
        end

    end

  end


  ###################
  # Helper Functions
  ###################


  # Update the access recordkeeping structures for the corresponding key
  defp update_timestamp(%LRU.Cache{} = cache, key, current_timestamp)
  when is_integer(current_timestamp) do
    
    # Update the timestamp value for key and return the previous time stamp
    # Later, use previous timestamp value to index into lru data structure

    # Should be O(1)

    {prev, timestamps} = Map.get_and_update(cache.timestamp_by_key, key, fn t -> 
      {t, current_timestamp} # prev value, new value
    end)
    
    # Update cache struct with updated timestamps structure
    cache = Kernel.put_in(cache.timestamp_by_key, timestamps)
    
    # Update the lru data structure
    # 0) Ensure the key is there
    # 1) First delete old timestamp and key
    # 2) Insert new timestamp and key
    
    # Complexity should be 3*log(N) where N entries or O(log(N))
    
    prev_lru_key = {prev, key}
    new_lru_key = {current_timestamp, key}

    case :gb_trees.lookup(prev_lru_key, cache.lru) do

      {:value, _lru_value} -> # If key-value has been accessed before or initially seeded
        lru = :gb_trees.delete(prev_lru_key, cache.lru)
        lru = :gb_trees.insert(new_lru_key, key, lru)
        
        # Update cache struct with updated lru
        Kernel.put_in(cache.lru, lru)
      
      :none -> cache
    end

  end
  

  # Discard least recently used cache entry
  defp lru_discard(%LRU.Cache{} = cache) do

    # Fetch key-value pair with lowest timestamp and remove from lru
    # Should be O(log(n))
    {_smallest_k_tuple, discard_key, lru} = :gb_trees.take_smallest(cache.lru)

    # Remove discard_key from values and timestamp data structure - O(1)
    values = Map.delete(cache.value_by_key, discard_key)
    timestamps = Map.delete(cache.timestamp_by_key, discard_key)

    # Reflect smaller cache size
    size = cache.size - 1

    %LRU.Cache{cache | size: size, lru: lru, 
               value_by_key: values, timestamp_by_key: timestamps}

  end

end
