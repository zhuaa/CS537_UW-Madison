typedef struct _VectorData VectorData;
typedef int (*VectorCompare) (const void*, const void*);
typedef void (*VectorClean) (void*);

typedef struct _Vector {
    VectorData *data;
    bool (*push_back) (struct _Vector*, void*);
    bool (*insert) (struct _Vector*, unsigned, void*);
    bool (*pop_back) (struct _Vector*);
    bool (*remove) (struct _Vector*, unsigned);
    bool (*set) (struct _Vector*, unsigned, void*);
    bool (*get) (struct _Vector*, unsigned, void**);
    bool (*resize) (struct _Vector*, unsigned);
    unsigned (*size) (struct _Vector*);
    unsigned (*capacity) (struct _Vector*);
    void (*sort) (struct _Vector*, VectorCompare);
    void (*first) (struct _Vector*, bool);
    bool (*next) (struct _Vector*, void**);
    bool (*reverse_next) (struct _Vector*, void**);
    void (*set_clean) (struct _Vector*, VectorClean);
} Vector;

Vector* VectorInit(unsigned cap);
void VectorDeinit(Vector* obj);
bool VectorPushBack(Vector* self, void* element);
bool VectorInsert(Vector* self, unsigned idx, void* element);
bool VectorPopBack(Vector* self);
bool VectorRemove(Vector* self, unsigned idx);
bool VectorSet(Vector* self, unsigned idx, void* element);
bool VectorGet(Vector* self, unsigned idx, void** p_element);
bool VectorResize(Vector* self, unsigned capacity);
unsigned VectorSize(Vector* self);
unsigned VectorCapacity(Vector* self);
void VectorSort(Vector* self, VectorCompare func);
void VectorFirst(Vector* self, bool is_reverse);
bool VectorNext(Vector* self, void** p_element);
bool VectorReverseNext(Vector* self, void** p_element);
void VectorSetClean(Vector* self, VectorClean func);

struct _VectorData {
    unsigned size_;
    unsigned capacity_;
    unsigned iter_;
    void** elements_;
    VectorClean func_clean_;
};

/*===========================================================================*
 *                  Definition for internal operations                       *
 *===========================================================================*/
#define likely(x)       __builtin_expect(!!(x), 1)
#define unlikely(x)     __builtin_expect(!!(x), 0)

bool _VectorReisze(VectorData* data, unsigned capacity);


/*===========================================================================*
 *               Implementation for the exported operations                  *
 *===========================================================================*/
Vector* VectorInit(unsigned capacity)
{
    Vector* obj = (Vector*)malloc(sizeof(Vector));
    if (unlikely(!obj))
        return NULL;

    VectorData* data = (VectorData*)malloc(sizeof(VectorData));
    if (unlikely(!data)) {
        free(obj);
        return NULL;
    }

    void** elements = (void**)malloc(sizeof(void*) * capacity);
    if (unlikely(!elements)) {
        free(data);
        free(obj);
        return NULL;
    }

    data->size_ = 0;
    data->capacity_ = capacity;
    data->elements_ = elements;
    data->func_clean_ = NULL;

    obj->data = data;
    obj->push_back = VectorPushBack;
    obj->insert = VectorInsert;
    obj->pop_back = VectorPopBack;
    obj->remove = VectorRemove;
    obj->set = VectorSet;
    obj->get = VectorGet;
    obj->resize = VectorResize;
    obj->size = VectorSize;
    obj->capacity = VectorCapacity;
    obj->sort = VectorSort;
    obj->first = VectorFirst;
    obj->next = VectorNext;
    obj->reverse_next = VectorReverseNext;
    obj->set_clean = VectorSetClean;

    return obj;
}

void VectorDeinit(Vector *obj)
{
    if (unlikely(!obj))
        return;

    VectorData* data = obj->data;
    VectorClean func_clean = data->func_clean_;
    void** elements = data->elements_;
    unsigned size = data->size_;

    unsigned i;
    for (i = 0 ; i < size ; ++i) {
        if (func_clean)
            func_clean(elements[i]);
    }

    free(elements);
    free(data);
    free(obj);
    return;
}

bool VectorPushBack(Vector* self, void* element)
{
    VectorData* data = self->data;
    unsigned size = data->size_;
    unsigned capacity = data->capacity_;

    /* If the internal array is full, extend it to double capacity. */
    if (size == capacity) {
        bool rtn = _VectorReisze(data, capacity << 1);
        if (rtn == false)
            return false;
    }

    data->elements_[size] = element;
    data->size_++;
    return true;
}

bool VectorInsert(Vector* self, unsigned idx, void* element)
{
    VectorData* data = self->data;
    unsigned size = data->size_;
    unsigned capacity = data->capacity_;

    if (unlikely(idx > size))
        return false;

    /* If the internal array is full, extend it to double capacity. */
    if (size == capacity) {
        bool rtn = _VectorReisze(data, capacity << 1);
        if (rtn == false)
            return false;
    }

    /* Shift the trailing elements if necessary. */
    void** elements = data->elements_;
    unsigned num_shift = size - idx;
    if (likely(num_shift > 0))
        memmove(elements + idx + 1, elements + idx, sizeof(void*) * num_shift);

    elements[idx] = element;
    data->size_ = size + 1;
    return true;
}

bool VectorPopBack(Vector* self)
{
    VectorData* data = self->data;
    unsigned size = data->size_;
    if (unlikely(size == 0))
        return false;

    --size;
    data->size_ = size;
    void* element = data->elements_[size];
    VectorClean func_clean = data->func_clean_;
    if (func_clean)
        func_clean(element);

    return true;
}

bool VectorRemove(Vector* self, unsigned idx)
{
    VectorData* data = self->data;
    unsigned size = data->size_;
    if (unlikely(idx >= size))
        return false;

    void** elements = data->elements_;
    VectorClean func_clean = data->func_clean_;
    if (func_clean)
        func_clean(elements[idx]);

    /* Shift the trailing items if necessary. */
    unsigned num_shift = size - idx - 1;
    if (likely(num_shift > 0))
        memmove(elements + idx, elements + idx + 1, sizeof(void*) * num_shift);

    data->size_ = size - 1;
    return true;
}

bool VectorSet(Vector* self, unsigned idx, void* element)
{
    VectorData* data = self->data;
    if (unlikely(idx >= data->size_))
        return false;

    void** elements = data->elements_;
    VectorClean func_clean = data->func_clean_;
    if (func_clean)
        func_clean(elements[idx]);
    elements[idx] = element;
    return true;
}

bool VectorGet(Vector* self, unsigned idx, void** p_element)
{
    VectorData* data = self->data;
    if (unlikely(idx >= data->size_))
        return false;

    *p_element = data->elements_[idx];
    return true;
}

bool VectorResize(Vector* self, unsigned capacity)
{
    return _VectorReisze(self->data, capacity);
}

unsigned VectorSize(Vector* self)
{
    return self->data->size_;
}

unsigned VectorCapacity(Vector* self)
{
    return self->data->capacity_;
}

void VectorSort(Vector* self, VectorCompare func)
{
    VectorData* data = self->data;
    qsort(data->elements_, data->size_, sizeof(void*), func);
}

void VectorFirst(Vector* self, bool is_reverse)
{
    self->data->iter_ = (is_reverse == false)? 0 : (self->data->size_ - 1);
}

bool VectorNext(Vector* self, void** p_element)
{
    VectorData* data = self->data;
    unsigned iter = data->iter_;
    if (unlikely(iter >= data->size_))
        return false;

    *p_element = data->elements_[iter];
    data->iter_ = iter + 1;
    return true;
}

bool VectorReverseNext(Vector* self, void** p_element)
{
    VectorData* data = self->data;
    unsigned iter = data->iter_;
    if (unlikely(iter == UINT_MAX))
        return false;

    *p_element = data->elements_[iter];
    data->iter_ = iter - 1;
    return true;
}

void VectorSetClean(Vector* self, VectorClean func)
{
    self->data->func_clean_ = func;
}

/*===========================================================================*
 *               Implementation for internal operations                      *
 *===========================================================================*/
bool _VectorReisze(VectorData* data, unsigned capacity)
{
    void** elements = data->elements_;
    unsigned old_size = data->size_;

    /* Remove the trailing items if the given element number is smaller than the
       old element count. */
    if (unlikely(capacity < old_size)) {
        VectorClean func_clean = data->func_clean_;
        unsigned idx = capacity;
        while (idx < old_size) {
            if (func_clean)
                func_clean(elements[idx]);
            ++idx;
        }
        data->size_ = capacity;
    }

    if (unlikely(capacity == old_size))
        return true;

    void** new_elements = (void**)realloc(elements, sizeof(void*) * capacity);
    if (new_elements) {
        data->elements_  = new_elements;
        data->capacity_ = capacity;
    }

    return (new_elements)? true : false;
}

int CompareWord(const void* lhs, const void* rhs)
{
    char* word_lhs = *((char**)lhs);
    char* word_rhs = *((char**)rhs);
    return strcmp(word_lhs, word_rhs);
}
///////////////////////////////////////////////////////////    End of Vector
