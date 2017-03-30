cdef extern from 'acsmx2.h':
    ctypedef struct ACSM_STRUCT2:
        pass

    ACSM_STRUCT2 * acsmNew2(void (*userfree)(void *p),
                            void (*optiontreefree)(void **),
                            void (*neg_list_free)(void **))

    int acsmAddPattern2(ACSM_STRUCT2 *, unsigned char *, int, int, int, int, int, void * _id, int iid)

    int acsmCompile2(ACSM_STRUCT2 *,
                     int (*build_tree)(void * id, void **existing_tree),
                     int (*neg_list_func)(void *id, void **list))

    int acsmSearch2(ACSM_STRUCT2 * acsm,unsigned char * T, int n,
                    int (*Match)(void * id, void *tree, int index, void *data, void *neg_list),
                    void * data, int* current_state)

    # 匹配所有单词，例如:
    #   patterns: 'he' 'she'
    #   T: 'she'
    #   匹配结果: 'he', 'she'
    int acsmSearchAll2 ( ACSM_STRUCT2 * acsm,unsigned char * T, int n,
                      int (*Match)(void * id, void *tree, int index, void *data, void *neg_list),
                      void * data, int* current_state );

    void acsmFree2(ACSM_STRUCT2 * acsm)
    int acsmPatternCount2(ACSM_STRUCT2 * acsm)
    void acsmCompressStates(ACSM_STRUCT2 *, int)
