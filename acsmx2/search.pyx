from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free
from libc.string cimport memcpy, memset, strlen
from libc.stdio cimport snprintf

cimport _acsmx2


ctypedef struct MatchedWords:
    size_t capacity
    size_t length
    unsigned char *data


cdef MatchedWords* new_matched_words(size_t capacity):
    cdef MatchedWords * matched_words = <MatchedWords *>PyMem_Malloc(sizeof(MatchedWords))
    matched_words.capacity = capacity
    matched_words.length = 0
    matched_words.data = <unsigned char *>PyMem_Malloc(capacity * sizeof(unsigned char))
    if not matched_words.data:
        raise MemoryError()
    return matched_words


cdef void reset_matched_words(MatchedWords* matched_words):
    matched_words.length = 0
    memset(matched_words.data, 0, matched_words.capacity * sizeof(unsigned char))


cdef void free_matched_words(MatchedWords* matched_words):
    if matched_words and matched_words.data:
        PyMem_Free(matched_words.data)
        PyMem_Free(matched_words)


cdef int match_found(void * _id, void *tree, int index, void *matched_words, void *neg_list):
    """callback when one word is found

    :param _id: _id of acsmAddPattern2, which actually stores pattern here.
    :param tree: not used
    :param index: position of matched words
    :param matched_words: used to store matched words
    :param neg_list: not used

    """
    cdef char* word = <char*>_id
    cdef MatchedWords * _matched_words = <MatchedWords *>matched_words
    cdef char* _data = <char *>_matched_words.data
    cdef size_t offset = _matched_words.length
    cdef char* _new_data = _data + offset
    cdef size_t word_length = strlen(word)
    cdef size_t min_number_size = 2  # size of string which stores number
    cdef size_t max_number_size = 12  # size of string which stores number
    cdef size_t new_size = 0

    # data = '<found_word_1>:index\n<found_word_2>:index' + '\n' + '<new_found_word>:index' + '\0\0...'
    if offset == 0:
        if word_length + min_number_size < _matched_words.capacity:
            new_size = min(word_length + max_number_size, _matched_words.capacity - offset)
            new_size = snprintf(_new_data, new_size, "%s:%d", word, index)
    elif offset + word_length + min_number_size + 1 < _matched_words.capacity:
        new_size = min(word_length + max_number_size + 1, _matched_words.capacity - offset)
        new_size = snprintf(_new_data, new_size, "\n%s:%d", word, index)

    if new_size > 0 and offset + new_size < _matched_words.capacity:
        _matched_words.length += new_size
    else:
        # ignore this match
        memset(_new_data, 0, (_matched_words.capacity - offset) * sizeof(char))

    # if return value > 0, the search will stop when one match is found
    return 0


cdef class MatchedWord:
    cdef public int index
    cdef public bytes word

    def __cinit__(self, int index, bytes word):
        self.index = index
        self.word = word

    def __richcmp__(self, MatchedWord other, int op):
        if op == 2:  # ==
            return self.index == other.index and self.word == other.word
        elif op == 3:  # !=
            return self.index != other.index or self.word != other.word
        else:
            raise TypeError('not supported operation between MatchedWord and MatchedWord')


cdef class Matcher:

    cdef _acsmx2.ACSM_STRUCT2 *acsm
    cdef MatchedWords* matched_words
    cdef int current_iid

    def __cinit__(self, capacity=1024):
        """
        :param capacity: max capacity of the string which stores matched words, seperated by `\n`

        """
        self.acsm = _acsmx2.acsmNew2(PyMem_Free, NULL, NULL)
        if not self.acsm:
            raise MemoryError()
        self.matched_words = new_matched_words(capacity)
        self.current_iid = 0
        _acsmx2.acsmCompressStates(self.acsm, 1)

    def pattern_count(self):
        return _acsmx2.acsmPatternCount2(self.acsm)

    def add_pattern(self, bytes pattern, int iid=0):
        if iid == 0:
            iid = self.current_iid
            self.current_iid += 1
        else:
            self.current_iid = iid

        cdef size_t length = len(pattern)
        cdef unsigned char* _pattern = <unsigned char*>PyMem_Malloc((length + 1) * sizeof(unsigned char))
        if not _pattern:
            raise MemoryError()
        memcpy(_pattern, <unsigned char *>pattern, length)
        _pattern[length] = '\0'
        _acsmx2.acsmAddPattern2(
            self.acsm, _pattern, length, 1, 0, 0, 0, <void *>_pattern, iid)

    def compile(self):
        _acsmx2.acsmCompile2(self.acsm, NULL, NULL)

    cdef _search(self, bytes text, bint full_search):
        cdef size_t length = len(text)
        cdef unsigned char* _text = text
        cdef int start_state = 0
        cdef int count
        cdef bytes _index
        cdef bytes word
        cdef list result = []

        reset_matched_words(self.matched_words)
        if full_search:
            count = _acsmx2.acsmSearchAll2(
                self.acsm, _text, length, match_found,
                <void *>self.matched_words, &start_state)
        else:
            count = _acsmx2.acsmSearch2(
                self.acsm, _text, length, match_found,
                <void *>self.matched_words, &start_state)
        for matched in self.matched_words.data[:self.matched_words.length].split(b'\n'):
            if not matched:
                continue
            word, _index = matched.rsplit(b':', 1)
            result.append(MatchedWord(int(_index), word))
        return count, result

    def search(self, bytes text):
        return self._search(text, False)

    def search_all(self, bytes text):
        return self._search(text, True)

    def __dealloc__(self):
        if self.acsm:
            _acsmx2.acsmFree2(self.acsm)
            self.acsm = NULL
        if self.matched_words:
            free_matched_words(self.matched_words)
            self.matched_words = NULL

