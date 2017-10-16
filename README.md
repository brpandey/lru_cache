# LRU Cache

## Description

Implements a Cache with basic operations get and put, while discarding the 
Least Recently Used (LRU) entry when full

Keeps track of key-value access for each entry using a map dedicated 
to tracking timestamps and Erlang general balanced tree as a priority queue

Cache operations for n elements are O(n*log(n))

For 0(n) performance, a doubly-linked list should be used to keep track of the lru, 
as doubly-linked list removals are O(1) and appends to tail are O(1)

The Elixir/Erlang solution for doubly-linked list performance can be found here:

https://ferd.ca/yet-another-article-on-zippers.html

Another optimization is to use an increasing counter instead of a timestamp and 
having to read the clock. Hence upon every access increments the cache counter


Thanks!

Bibek Pandey