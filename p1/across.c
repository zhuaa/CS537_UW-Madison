#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv){
    //check command input
    if(argc <= 3 || argc >= 6){
        printf("across: invalid number of arguments\n");
        exit(1);
    }
    //get substring
    char *substr = argv[1];
    //get position
    int pos = atoi(argv[2]);
    //get length of string
    int len = atoi(argv[3]);
    if(pos + strlen(substr) > len){
        printf("across: invalid position\n");
        exit(1);
    }
    //get pointer of file
    FILE *fp = fopen("/usr/share/dict/words", "r");
    if(argc == 5){
        fp = fopen(argv[4], "r");
    }
    //check file existing
    if(fp == NULL){
        printf("across: cannot open file\n");
        exit(1);
    }
    //check valid lines
    char buffer[256];
    while(fgets(buffer, sizeof(buffer), fp) != NULL){
        //check if string contain uppercase or non-alpha characters
        int valid = 1, i = 0;
        while(i<strlen(buffer)-1){
            if(!((buffer[i] >= 'a' && buffer[i] <='z') || (buffer[i]>='0' && buffer[i]<='9'))){
                valid = 0;
                break;
            }
            i++;
        }
        if(valid == 0){
            continue;
        }
        if(strlen(buffer) - 1 == len && strncmp(substr, buffer + pos, strlen(substr))==0){
            printf("%s", buffer);
        }
    }
    exit(0);
}
