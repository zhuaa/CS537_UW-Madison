#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv){
    // check command input
    if(argc != 3){
        printf("my-diff: invalid number of arguments\n");
        exit(1);
    }
    // open and check files
    FILE *fp1 = fopen(argv[1], "r");
    if(fp1 == NULL){
        printf("my-diff: cannot open file\n");
        exit(1);
    }
    FILE *fp2 = fopen(argv[2], "r");
    if(fp2 == NULL){
        printf("my-diff: cannot open file\n");
        exit(1);
    }
    // compare lines in two files
    char *buffer1 = NULL;
    char *buffer2 = NULL;
    size_t line_buf_size = 0;
    int i = 1, line_index_output = 1; 
    int line_size1 = 0, line_size2 = 0;
    while((line_size1 = getline(&buffer1, &line_buf_size, fp1)) && (line_size2 = getline(&buffer2, &line_buf_size, fp2)) && line_size1 != -1 && line_size2 != -1){
        // lines are not same
        if(strncmp(buffer1, buffer2, strlen(buffer1)) != 0){
            if(line_index_output == 1){
                printf("%d\n", i);
                line_index_output = 0;
            }
            printf("< %s", buffer1);
            printf("> %s", buffer2);
        }
        // lines are same, reset line_index_output
        else{
            line_index_output = 1;
        }
        i++;
    }
    // deal with the left lines in one file
    // first file is longer
    if(line_size1 != -1){
	if(line_index_output == 1){
            printf("%d\n", i);
            line_index_output = 0;
        }
	printf("< %s", buffer1);
	while(getline(&buffer1, &line_buf_size, fp1) != -1){
            printf("< %s", buffer1);
    	}
    }
    //second file is longer
    else if(line_size2 != -1){
	if(line_index_output == 1){
            printf("%d\n", i);
            line_index_output = 0;
        }
        printf("> %s", buffer2);
        while(getline(&buffer2, &line_buf_size, fp2) != -1){
            printf("> %s", buffer2);
        }
    }
    exit(0);
}
