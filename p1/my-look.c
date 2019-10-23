#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv){
    //check command input
    if(argc <= 1 || argc >= 4){
        printf("my-look: invalid number of arguments\n");
        exit(1);
    }
    //get prefix word
    char *prefix = argv[1];
    //get pointer of file
    FILE *fp = fopen("/usr/share/dict/words", "r");
    if(argc == 3){
        fp = fopen(argv[2], "r");
    }
    //check file existing
    if(fp == NULL){
        printf("my-look: cannot open file\n");
        exit(1);
    }
    //compare every line with prefix word
    char buffer[256];
    while(fgets(buffer, sizeof(buffer), fp) != NULL){
        if(strncasecmp(prefix, buffer, strlen(prefix)) == 0){
            printf("%s", buffer);
        }
    }
    exit(0);
}
