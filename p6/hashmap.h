/** The key value pair for associative data structures. */
typedef struct _Pair {
    void* key;
    void* value;
} Pair;

unsigned HashMurMur32(void* key, size_t size);
unsigned HashJenkins(void* key, size_t size);
unsigned HashDjb2(char* key);

unsigned HashMurMur32(void* key, size_t size)
{
    if (!key || size == 0)
        return 0;

    const unsigned c1 = 0xcc9e2d51;
    const unsigned c2 = 0x1b873593;
    const unsigned r1 = 15;
    const unsigned r2 = 13;
    const unsigned m = 5;
    const unsigned n = 0xe6546b64;

    unsigned hash = 0xdeadbeef;

    const int nblocks = size / 4;
    const unsigned *blocks = (const unsigned*)key;
    int i;
    for (i = 0; i < nblocks; i++) {
        unsigned k = blocks[i];
        k *= c1;
        k = (k << r1) | (k >> (32 - r1));
        k *= c2;

        hash ^= k;
        hash = ((hash << r2) | (hash >> (32 - r2))) * m + n;
    }

    const uint8_t *tail = (const uint8_t*) (key + nblocks * 4);
    unsigned k1 = 0;

    switch (size & 3) {
        case 3:
            k1 ^= tail[2] << 16;
        case 2:
            k1 ^= tail[1] << 8;
        case 1:
            k1 ^= tail[0];

            k1 *= c1;
            k1 = (k1 << r1) | (k1 >> (32 - r1));
            k1 *= c2;
            hash ^= k1;
    }

    hash ^= size;
    hash ^= (hash >> 16);
    hash *= 0x85ebca6b;
    hash ^= (hash >> 13);
    hash *= 0xc2b2ae35;
    hash ^= (hash >> 16);

    return hash;
}

unsigned HashDjb2(char* key)
{
    unsigned hash = 5381;
    int c;

    while ((c = *key++))
        hash = ((hash << 5) + hash) + c; /* hash * 33 + c */
    return hash;
}

typedef struct _HashMapData HashMapData;
typedef unsigned (*HashMapHash) (void*);
typedef int (*HashMapCompare) (void*, void*);
typedef void (*HashMapCleanKey) (void*);
typedef void (*HashMapCleanValue) (void*);
typedef struct _HashMap {
    HashMapData *data;
    bool (*put) (struct _HashMap*, void*, void*);
    void* (*get) (struct _HashMap*, void*);
    bool (*contain) (struct _HashMap*, void*);
    bool (*remove) (struct _HashMap*, void*);
    unsigned (*size) (struct _HashMap*);
    void (*first) (struct _HashMap*);
    Pair* (*next) (struct _HashMap*);
    void (*set_hash) (struct _HashMap*, HashMapHash);
    void (*set_compare) (struct _HashMap*, HashMapCompare);
    void (*set_clean_key) (struct _HashMap*, HashMapCleanKey);
    void (*set_clean_value) (struct _HashMap*, HashMapCleanValue);
} HashMap;

HashMap* HashMapInit();
void HashMapDeinit(HashMap* obj);
bool HashMapPut(HashMap* self, void* key, void* value);
void* HashMapGet(HashMap* self, void* key);
bool HashMapContain(HashMap* self, void* key);
bool HashMapRemove(HashMap* self, void* key);
unsigned HashMapSize(HashMap* self);
void HashMapFirst(HashMap* self);
Pair* HashMapNext(HashMap* self);
void HashMapSetHash(HashMap* self, HashMapHash func);
void HashMapSetCompare(HashMap* self, HashMapCompare func);
void HashMapSetCleanKey(HashMap* self, HashMapCleanKey func);
void HashMapSetCleanValue(HashMap* self, HashMapCleanValue func);

/*===========================================================================*
 *                        The container private data                         *
 *===========================================================================*/
static const unsigned magic_primes[] = {
    769, 1543, 3079, 6151, 12289, 24593, 49157, 98317, 196613, 393241, 786433,
    1572869, 3145739, 6291469, 12582917, 25165843, 50331653, 100663319,
    201326611, 402653189, 805306457, 1610612741,
};
static const int num_prime = sizeof(magic_primes) / sizeof(unsigned);
static const double load_factor = 0.75;


typedef struct _SlotNode {
    Pair pair_;
    struct _SlotNode* next_;
} SlotNode;

struct _HashMapData {
    int size_;
    int idx_prime_;
    unsigned num_slot_;
    unsigned curr_limit_;
    unsigned iter_slot_;
    SlotNode** arr_slot_;
    SlotNode* iter_node_;
    HashMapHash func_hash_;
    HashMapCompare func_cmp_;
    HashMapCleanKey func_clean_key_;
    HashMapCleanValue func_clean_val_;
};

unsigned _HashMapHash(void* key);
int _HashMapCompare(void* lhs, void* rhs);
void _HashMapReHash(HashMapData* data);

HashMap* HashMapInit()
{
    HashMap* obj = (HashMap*)malloc(sizeof(HashMap));
    if (unlikely(!obj))
        return NULL;

    HashMapData* data = (HashMapData*)malloc(sizeof(HashMapData));
    if (unlikely(!data)) {
        free(obj);
        return NULL;
    }

    SlotNode** arr_slot = (SlotNode**)malloc(sizeof(SlotNode*) * magic_primes[0]);
    if (unlikely(!arr_slot)) {
        free(data);
        free(obj);
        return NULL;
    }
    unsigned i;
    for (i = 0 ; i < magic_primes[0] ; ++i)
        arr_slot[i] = NULL;

    data->size_ = 0;
    data->idx_prime_ = 0;
    data->num_slot_ = magic_primes[0];
    data->curr_limit_ = (unsigned)((double)magic_primes[0] * load_factor);
    data->arr_slot_ = arr_slot;
    data->func_hash_ = _HashMapHash;
    data->func_cmp_ = _HashMapCompare;
    data->func_clean_key_ = NULL;
    data->func_clean_val_ = NULL;

    obj->data = data;
    obj->put = HashMapPut;
    obj->get = HashMapGet;
    obj->contain = HashMapContain;
    obj->remove = HashMapRemove;
    obj->size = HashMapSize;
    obj->first = HashMapFirst;
    obj->next = HashMapNext;
    obj->set_hash = HashMapSetHash;
    obj->set_compare = HashMapSetCompare;
    obj->set_clean_key = HashMapSetCleanKey;
    obj->set_clean_value = HashMapSetCleanValue;

    return obj;
}

void HashMapDeinit(HashMap* obj)
{
    if (unlikely(!obj))
        return;

    HashMapData* data = obj->data;
    SlotNode** arr_slot = data->arr_slot_;
    HashMapCleanKey func_clean_key = data->func_clean_key_;
    HashMapCleanValue func_clean_val = data->func_clean_val_;

    unsigned num_slot = data->num_slot_;
    unsigned i;
    for (i = 0 ; i < num_slot ; ++i) {
        SlotNode* pred;
        SlotNode* curr = arr_slot[i];
        while (curr) {
            pred = curr;
            curr = curr->next_;
            if (func_clean_key)
                func_clean_key(pred->pair_.key);
            if (func_clean_val)
                func_clean_val(pred->pair_.value);
            free(pred);
        }
    }

    free(arr_slot);
    free(data);
    free(obj);
    return;
}

bool HashMapPut(HashMap* self, void* key, void* value)
{
    /* Check the loading factor for rehashing. */
    HashMapData* data = self->data;
    if (data->size_ >= data->curr_limit_)
        _HashMapReHash(data);

    /* Calculate the slot index. */
    unsigned hash = data->func_hash_(key);
    hash = hash % data->num_slot_;

    /* Check if the pair conflicts with a certain one stored in the map. If yes,
       replace that one. */
    HashMapCompare func_cmp = data->func_cmp_;
    SlotNode** arr_slot = data->arr_slot_;
    SlotNode* curr = arr_slot[hash];
    while (curr) {
        if (func_cmp(key, curr->pair_.key) == 0) {
            if (data->func_clean_key_)
                data->func_clean_key_(curr->pair_.key);
            if (data->func_clean_val_)
                data->func_clean_val_(curr->pair_.value);
            curr->pair_.key = key;
            curr->pair_.value = value;
            return true;
        }
        curr = curr->next_;
    }

    /* Insert the new pair into the slot list. */
    SlotNode* node = (SlotNode*)malloc(sizeof(SlotNode));
    if (unlikely(!node))
        return false;

    node->pair_.key = key;
    node->pair_.value = value;
    if (!(arr_slot[hash])) {
        node->next_ = NULL;
        arr_slot[hash] = node;
    } else {
        node->next_ = arr_slot[hash];
        arr_slot[hash] = node;
    }
    ++(data->size_);

    return true;
}

void* HashMapGet(HashMap* self, void* key)
{
    HashMapData* data = self->data;

    /* Calculate the slot index. */
    unsigned hash = data->func_hash_(key);
    hash = hash % data->num_slot_;

    /* Search the slot list to check if there is a pair having the same key
       with the designated one. */
    HashMapCompare func_cmp = data->func_cmp_;
    SlotNode* curr = data->arr_slot_[hash];
    while (curr) {
        if (func_cmp(key, curr->pair_.key) == 0)
            return curr->pair_.value;
        curr = curr->next_;
    }

    return NULL;
}

bool HashMapContain(HashMap* self, void* key)
{
    HashMapData* data = self->data;

    /* Calculate the slot index. */
    unsigned hash = data->func_hash_(key);
    hash = hash % data->num_slot_;

    /* Search the slot list to check if there is a pair having the same key
       with the designated one. */
    HashMapCompare func_cmp = data->func_cmp_;
    SlotNode* curr = data->arr_slot_[hash];
    while (curr) {
        if (func_cmp(key, curr->pair_.key) == 0)
            return true;
        curr = curr->next_;
    }

    return false;
}

bool HashMapRemove(HashMap* self, void* key)
{
    HashMapData* data = self->data;

    /* Calculate the slot index. */
    unsigned hash = data->func_hash_(key);
    hash = hash % data->num_slot_;

    /* Search the slot list for the deletion target. */
    HashMapCompare func_cmp = data->func_cmp_;
    SlotNode* pred = NULL;
    SlotNode** arr_slot = data->arr_slot_;
    SlotNode* curr = arr_slot[hash];
    while (curr) {
        if (func_cmp(key, curr->pair_.key) == 0) {
            if (data->func_clean_key_)
                data->func_clean_key_(curr->pair_.key);
            if (data->func_clean_val_)
                data->func_clean_val_(curr->pair_.value);

            if (!pred)
                arr_slot[hash] = curr->next_;
            else
                pred->next_ = curr->next_;

            free(curr);
            --(data->size_);
            return true;
        }
        pred = curr;
        curr = curr->next_;
    }

    return false;
}

unsigned HashMapSize(HashMap* self)
{
    return self->data->size_;
}

void HashMapFirst(HashMap* self)
{
    HashMapData* data = self->data;
    data->iter_slot_ = 0;
    data->iter_node_ = data->arr_slot_[0];
    return;
}

Pair* HashMapNext(HashMap* self)
{
    HashMapData* data = self->data;

    SlotNode** arr_slot = data->arr_slot_;
    while (data->iter_slot_ < data->num_slot_) {
        if (data->iter_node_) {
            Pair* ptr_pair = &(data->iter_node_->pair_);
            data->iter_node_ = data->iter_node_->next_;
            return ptr_pair;
        }
        ++(data->iter_slot_);
        if (data->iter_slot_ == data->num_slot_)
            break;
        data->iter_node_ = arr_slot[data->iter_slot_];
    }
    return NULL;
}

void HashMapSetHash(HashMap* self, HashMapHash func)
{
    self->data->func_hash_ = func;
}

void HashMapSetCompare(HashMap* self, HashMapCompare func)
{
    self->data->func_cmp_ = func;
}

void HashMapSetCleanKey(HashMap* self, HashMapCleanKey func)
{
    self->data->func_clean_key_ = func;
}

void HashMapSetCleanValue(HashMap* self, HashMapCleanValue func)
{
    self->data->func_clean_val_ = func;
}


/*===========================================================================*
 *               Implementation for internal operations                      *
 *===========================================================================*/
unsigned _HashMapHash(void* key)
{
    return (unsigned)(intptr_t)key;
}

int _HashMapCompare(void* lhs, void* rhs)
{
    if ((intptr_t)lhs == (intptr_t)rhs)
        return 0;
    return ((intptr_t)lhs > (intptr_t)rhs)? 1 : (-1);
}

void _HashMapReHash(HashMapData* data)
{
    unsigned num_slot_new;

    /* Consume the next prime for slot array extension. */
    if (likely(data->idx_prime_ < (num_prime - 1))) {
        ++(data->idx_prime_);
        num_slot_new = magic_primes[data->idx_prime_];
    }
    /* If the prime list is completely consumed, we simply extend the slot array
       with treble capacity.*/
    else {
        data->idx_prime_ = num_prime;
        num_slot_new = data->num_slot_ * 3;
    }

    /* Try to allocate the new slot array. The rehashing should be canceled due
       to insufficient memory space.  */
    SlotNode** arr_slot_new = (SlotNode**)malloc(sizeof(SlotNode*) * num_slot_new);
    if (unlikely(!arr_slot_new)) {
        if (data->idx_prime_ < num_prime)
            --(data->idx_prime_);
        return;
    }

    unsigned i;
    for (i = 0 ; i < num_slot_new ; ++i)
        arr_slot_new[i] = NULL;

    HashMapHash func_hash = data->func_hash_;
    SlotNode** arr_slot = data->arr_slot_;
    unsigned num_slot = data->num_slot_;
    for (i = 0 ; i < num_slot ; ++i) {
        SlotNode* pred;
        SlotNode* curr = arr_slot[i];
        while (curr) {
            pred = curr;
            curr = curr->next_;
            /* Migrate each key value pair to the new slot. */
            unsigned hash = func_hash(pred->pair_.key);
            hash = hash % num_slot_new;
            if (!arr_slot_new[hash]) {
                pred->next_ = NULL;
                arr_slot_new[hash] = pred;
            } else {
                pred->next_ = arr_slot_new[hash];
                arr_slot_new[hash] = pred;
            }
        }
    }

    free(arr_slot);
    data->arr_slot_ = arr_slot_new;
    data->num_slot_ = num_slot_new;
    data->curr_limit_ = (unsigned)((double)num_slot_new * load_factor);
    return;
}

unsigned HashKey(void* key)
{
    return HashDjb2((char*)key);
}

int CompareKey(void* lhs, void* rhs)
{
    return strcmp((char*)lhs, (char*)rhs);
}

void CleanObject(void* obj)
{
    free(obj);
}

void CleanVector(void* vector)
{
    VectorDeinit((Vector*)vector);
}
///////////////////////////////////////////////////////////    End of HashMap
