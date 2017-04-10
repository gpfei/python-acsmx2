# python-acsmx2
A Python wrapper of acsm2 from [Snort](https://github.com/jasonish/snort)

##### Warnings
- Not thread-safe.

#### Requirements
- Python 3.5 + (Earlier versions have not been tested.)
- Cython


#### Example

```python

>>> from acsmx2 import Matcher
>>> m = Matcher(1000) # 1000 is size of the string which stores matched words
>>> m.add_pattern(b'hello', 1)
>>> m.add_pattern(b'world', 2)
>>> m.compile()
>>> count, words = m.search(b'this is hello-world-example')
>>> count
2
>>> words.decode('utf8').split('\n')
['hello', 'world']

```

##### Notes
- params of `add_pattern` and `search` must be type of `bytes`.
