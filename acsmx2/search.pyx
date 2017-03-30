from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free
from libc.string cimport memcpy, memset, strlen

cimport _acsmx2


ctypedef struct MatchedWords:
    size_t size
    unsigned char *data


cdef MatchedWords* new_matched_words(size_t size):
    cdef MatchedWords * matched_words = <MatchedWords *>PyMem_Malloc(sizeof(MatchedWords))
    matched_words.size = size
    matched_words.data = <unsigned char *>PyMem_Malloc(size * sizeof(unsigned char))
    if not matched_words.data:
        raise MemoryError()
    return matched_words


cdef void reset_matched_words(MatchedWords* matched_words):
    memset(matched_words.data, 0, matched_words.size * sizeof(unsigned char))


cdef void free_matched_words(MatchedWords* matched_words):
    if matched_words and matched_words.data:
        PyMem_Free(matched_words.data)
        PyMem_Free(matched_words)


cdef int match_found(void * _id, void *tree, int index, void *matched_words, void *neg_list):
    """callback when one word is found

    :param _id: _id of acsmAddPattern2, which actually stores pattern here.
    :param tree: not used
    :param index: iid of acsmAddPattern2
    :param matched_words: used to store matched words
    :param neg_list: not used

    """
    cdef unsigned char* word = <unsigned char*>_id
    cdef MatchedWords * _matched_words = <MatchedWords *>matched_words
    cdef unsigned char* _data = _matched_words.data
    cdef size_t length = strlen(<char *>_data)
    cdef size_t word_length = strlen(<char *> word)
    cdef size_t offset = length

    # data = '<found_word_1>\n<found_word_2>' + '\n' + '<new_found_word>' + '\0\0...'
    if offset == 0:
        if word_length < _matched_words.size:
            memcpy(_data + offset, word, word_length)
    elif offset + word_length + 1 < _matched_words.size:
        _data[offset] = b'\n'
        offset += 1
        memcpy(_data + offset, word, word_length)

    # if return value > 0, the search will stop when one match is found
    return 0


cdef class Matcher:

    cdef _acsmx2.ACSM_STRUCT2 *acsm
    cdef MatchedWords* matched_words

    def __cinit__(self, size=1024):
        """
        :param size: max size of the string which stores matched words, seperated by `\n`

        """
        self.acsm = _acsmx2.acsmNew2(PyMem_Free, NULL, NULL)
        if not self.acsm:
            raise MemoryError()
        self.matched_words = new_matched_words(size)
        _acsmx2.acsmCompressStates(self.acsm, 1)

    def pattern_count(self):
        return _acsmx2.acsmPatternCount2(self.acsm)

    def add_pattern(self, bytes pattern, int iid):
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

    def search(self, bytes text):
        cdef size_t length = len(text)
        cdef unsigned char* _text = text
        cdef int start_state = 0

        reset_matched_words(self.matched_words)
        count = _acsmx2.acsmSearch2(
            self.acsm, _text, length, match_found,
            <void *>self.matched_words, &start_state)
        return count, <bytes>self.matched_words.data

    def search_all(self, bytes text):
        cdef size_t length = len(text)
        cdef unsigned char* _text = text
        cdef int start_state = 0

        reset_matched_words(self.matched_words)
        count = _acsmx2.acsmSearchAll2(
            self.acsm, _text, length, match_found,
            <void *>self.matched_words, &start_state)
        return count, <bytes>self.matched_words.data

    def __dealloc__(self):
        if self.acsm:
            _acsmx2.acsmFree2(self.acsm)
            self.acsm = NULL
        if self.matched_words:
            free_matched_words(self.matched_words)
            self.matched_words = NULL

