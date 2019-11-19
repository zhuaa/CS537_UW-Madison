#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <stdint.h>
#include <limits.h>
#include <pthread.h>
#include "mapreduce.h"
#include "vector.h"
#include "hashmap.h"

#define MAX 4294967296

pthread_mutex_t mutex_1 = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t mutex_2 = PTHREAD_MUTEX_INITIALIZER;

HashMap* map;
HashMap* key2index;

// mapper structure
typedef struct _MapperContainer {
    Mapper mapper;
    Vector* input_files;
} MapperContainer;

// reducer structure
typedef struct _ReducerPartition{
    int partition_num;
    Vector* keys;
} ReducerPartition;

typedef struct _ReducerContainer {
    Reducer reducer;
    Vector* partitions; // vector of partitions, one reducer may have multiple partitions.
} ReducerContainer;

// ******************************************************
// MR_Emit function. Need mutex for add elements into map
// ******************************************************
void MR_Emit(char *key, char *value)
{
    pthread_mutex_lock(&mutex_1);
    Vector* vector;
    if(map->contain(map, (void*)key) == false){
        vector = VectorInit(32);
        map->put(map, (void*)strdup(key), (void*)vector);
    } 
    else{
        vector = map->get(map, (void*)key);
    }
    vector->push_back(vector, (void*)value);
    pthread_mutex_unlock(&mutex_1);
}

// ********************************************************
// get_next function. Need mutex for access elements in map
// ********************************************************
char* get_next(char *key, int partition_number)
{
    Vector* vector = map->get(map, (void*)key);
    int elementIndex = (int)(intptr_t)key2index->get(key2index, (void*)key);
    void* element;
    if(elementIndex < vector->size(vector)){
        vector->get(vector, elementIndex, &element);
        pthread_mutex_lock(&mutex_2);
        key2index->put(key2index, (void*)strdup(key), (void*)(intptr_t)++elementIndex);// update
        pthread_mutex_unlock(&mutex_2);
        return (char*)element;
    } 
    else{
        return NULL;
    }
}

// mapper function
void* mapperThread(void* mapperContainer)
{
    Mapper mapper = ((MapperContainer*)mapperContainer)->mapper;
    Vector* input_files = ((MapperContainer*)mapperContainer)->input_files;
    void* element;
    for(int i=0; i<input_files->size(input_files); i++){
        input_files->get(input_files, i, &element);
        mapper((char*)element);
    }
    return 0;
}

// reducer function
void* reducerThread(void* reducerContainer)
{
    Reducer reducer = ((ReducerContainer*)reducerContainer)->reducer;
    Vector* partitions = ((ReducerContainer*)reducerContainer)->partitions;

    void* element;
    // loop for partions, and then loop for keys
    for(int j=0; j<partitions->size(partitions); j++){
        void* p;
        partitions->get(partitions, j, &p);
        Vector* keys = ((ReducerPartition*)p)->keys;
        for(int i=0; i<keys->size(keys); i++){
            keys->get(keys, i, &element);// get key
            int partition_number = ((ReducerPartition*)p)->partition_num;
            reducer((char*)element, get_next, partition_number);
        }
    }
    return 0;
}

// **********************
// Default Hash Partition
// **********************
unsigned long MR_DefaultHashPartition(char *key, int num_partitions) {
    unsigned long hash = 5381;
    int c;
    while ((c = *key++) != '\0')
        hash = hash * 33 + c;
    return hash % num_partitions;
}

// ****************
// Sorted Partition
// ****************
unsigned long MR_SortedPartition(char *key, int num_partitions){
    char* ptr;
    unsigned long value = strtoul(key, &ptr, 10);
    unsigned long partition_num = value / (unsigned long)(MAX / num_partitions);
    return partition_num;
}

// ****************
// MR_Run function.
// ****************
void MR_Run(int argc, char *argv[],
	    Mapper mapper, int num_mappers,
	    Reducer reducer, int num_reducers,
	    Partitioner partition, int num_partitions)
{	
    // initialize map and key2index
    map = HashMapInit();
    HashMapSetHash(map, HashKey);
    HashMapSetCompare(map, CompareKey);
    HashMapSetCleanKey(map, CleanObject);
    HashMapSetCleanValue(map, CleanVector);

    key2index = HashMapInit();
    HashMapSetHash(key2index, HashKey);
    HashMapSetCompare(key2index, CompareKey);
    HashMapSetCleanKey(key2index, CleanObject);

    //*************
    // mapper start
    //*************
    Vector* mapperinput_files = VectorInit(32);
    VectorSetClean(mapperinput_files, CleanVector);
    Vector* input_files;
    for(int i=0; i<num_mappers; i++){
        input_files = VectorInit(32);
        mapperinput_files->push_back(mapperinput_files, input_files);
    }
    // get input files
    void* element;
    for(int i=1; i<argc; i++){
        mapperinput_files->get(mapperinput_files, (i-1)%num_mappers, &element);
        ((Vector*)element)->push_back((Vector*)element, (void*)argv[i]);
    }
    // construct mapperContainers
    Vector* mapperContainers = VectorInit(32);
    VectorSetClean(mapperContainers, CleanObject);
    for(int i=0; i<num_mappers; i++){
        MapperContainer* mapperContainer = (MapperContainer*)malloc(sizeof(MapperContainer));
        mapperContainer->mapper = mapper;
        mapperinput_files->get(mapperinput_files, i, &element);
        mapperContainer->input_files = (Vector*)element;
        mapperContainers->push_back(mapperContainers, (void*)mapperContainer);
    }

    // mapper threads
    pthread_t mapperthreads[num_mappers];
    for(int i=0; i<num_mappers; i++){
        mapperContainers->get(mapperContainers, i, &element);
        pthread_create(&mapperthreads[i], NULL, mapperThread, (void*)element);
    }
    for(int i=0; i<num_mappers; i++){
        pthread_join(mapperthreads[i], NULL);
    }

    // destroctor
    VectorDeinit(mapperinput_files);
    VectorDeinit(mapperContainers);
    
    //*********************************
    // mapper end, prepare for reducers
    //*********************************
    Vector* sorted_keys = VectorInit(32);
    void* key;
    map->first(map);
    Pair* ptr_pair;
    while((ptr_pair = map->next(map)) != NULL){
        key = ptr_pair->key;
        Vector* vector = (Vector*)ptr_pair->value;

        sorted_keys->push_back(sorted_keys, (void*)key);
        key2index->put(key2index, (void*)strdup(key), (void*)(intptr_t)0);
        vector->sort(vector, CompareWord);
    }
    sorted_keys->sort(sorted_keys, CompareWord);

    // one partition -> one vector of keys
    Vector* partitionkeys = VectorInit(32);
    VectorSetClean(partitionkeys, CleanVector);
    Vector* keys;
    for(int i=0; i<num_partitions; i++){
        keys = VectorInit(32);
        partitionkeys->push_back(partitionkeys, (void*)keys);
    }

    // asign sorted_keys to partition
    for(int i=0; i<sorted_keys->size(sorted_keys); i++){
        sorted_keys->get(sorted_keys, i, &key); // get key
        int partition_number = partition((char*)key, num_partitions);
	partitionkeys->get(partitionkeys, partition_number, &element);
        ((Vector*)element)->push_back((Vector*)element, (void*)key);
    }

    // construct reducerContainers
    Vector* reducerContainers = VectorInit(32);
    VectorSetClean(reducerContainers, CleanObject);
    for(int i=0; i<num_reducers; i++){
        ReducerContainer* reducerContainer = (ReducerContainer*)malloc(sizeof(ReducerContainer));
        reducerContainer->reducer = reducer;
        // get partitions for reducer
        Vector* partitions = VectorInit(32);
        for(int j=0; j<num_partitions; j++){
            if(j%num_reducers == i){
                ReducerPartition* reducerpartition = (ReducerPartition*)malloc(sizeof(ReducerPartition));
                reducerpartition->partition_num = j;
                partitionkeys->get(partitionkeys, j, &element);
                reducerpartition->keys = (Vector*)element;
                partitions->push_back(partitions, (void*)reducerpartition);
            }
        }
        reducerContainer->partitions = partitions;
        reducerContainers->push_back(reducerContainers, (void*)reducerContainer);
    }
    
    // reducer threads
    pthread_t reducerthreads[num_reducers];
    for(int i=0; i<num_reducers; i++){
        reducerContainers->get(reducerContainers, i, &element);
        pthread_create(&reducerthreads[i], NULL, reducerThread, (void*)element);
    }
    for(int i=0; i<num_reducers; i++){
        pthread_join(reducerthreads[i], NULL);
    }

    // destroctor
    HashMapDeinit(map);
    HashMapDeinit(key2index);
    VectorDeinit(sorted_keys);
    VectorDeinit(partitionkeys);
    VectorDeinit(reducerContainers);
}