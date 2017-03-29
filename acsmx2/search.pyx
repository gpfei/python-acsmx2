from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free
from libc.string cimport memcpy, memset, strlen

cimport _acsmx2


cdef int match_found(void * _id, void *tree, int index, void *data, void *neg_list):
    """找到匹配时的回调函数

    :param: _id 即匹配的词组
            tree 暂时没用
            index 是 addPattern 时传入的 iid
            data 是所有回调会共用的内容，这里用于保存匹配的词组
            neg_list 暂时没用
    """
    cdef unsigned char* word = <unsigned char*>_id
    cdef unsigned char* _data = <unsigned char*>data
    cdef size_t length = strlen(<char *>_data)
    cdef size_t word_length = strlen(<char *> word)
    cdef size_t offset = length

    # data = '<found_word_1>\n<found_word_2>' + '\n' + '<new_found_word>' + '\0\0...'
    if offset + word_length + 1 <= _acsmx2.MAX_MATCHED_LENGTH:
        if offset > 0:
            _data[offset] = b'\n'
            offset += 1
        memcpy(_data + offset, word, word_length)

    # if return value > 0, the search will stop when one match is found
    return 0


cdef class Matcher:

    cdef _acsmx2.ACSM_STRUCT2 *acsm
    cdef unsigned char matched_words[_acsmx2.MAX_MATCHED_LENGTH + 1]

    def __cinit__(self):
        self.acsm = _acsmx2.acsmNew2(PyMem_Free, NULL, NULL)
        if not self.acsm:
            raise MemoryError()
        # 压缩状态
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

        memset(self.matched_words, 0, _acsmx2.MAX_MATCHED_LENGTH * sizeof(unsigned char))
        count = _acsmx2.acsmSearch2(
            self.acsm, _text, length, match_found,
            <void *>self.matched_words, &start_state)
        return count, <bytes>self.matched_words

    def search_all(self, bytes text):
        cdef size_t length = len(text)
        cdef unsigned char* _text = text
        cdef int start_state = 0

        memset(self.matched_words, 0, _acsmx2.MAX_MATCHED_LENGTH * sizeof(unsigned char))
        count = _acsmx2.acsmSearchAll2(
            self.acsm, _text, length, match_found,
            <void *>self.matched_words, &start_state)
        return count, <bytes>self.matched_words

    def __dealloc__(self):
        if self.acsm:
            _acsmx2.acsmFree2(self.acsm)

