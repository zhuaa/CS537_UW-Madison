#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <ctype.h>
#define IN_SIZE 515
#define MAX_BG 32
char prompt[6] = "mysh> ";
char error[20] = "An error occurred.\n";
char* words[512];
char* command[1000];
int is_batch = 0;

struct JOB{
	int jid;
	int pid;
	char command[512];
} bg_jobs[MAX_BG];

int JID = -1;
int bg_job_count = 0;

int split_line(char* line, char** words){
	int count = 0;
	char* input = strdup(line);
	while(1){
		while(isspace(*input)){
			input++;
		}
		if(*input == '\0'){
			return count;
		}
		words[count++] = input;
		while(!isspace(*input) && *input != '\0'){
			input++;
		}
		if(*input == '\0'){
			return count;
		}
		*input = '\0';
		input++;
	}
}

//delete space at the start and end of string
char * strim(char *str)
{
	char *end,*sp,*ep;
	int len;
	sp = str;
	end = str + strlen(str) - 1;
	ep = end;
 
	while(sp<=end && isspace(*sp))
		sp++;
	while(ep>=sp && isspace(*ep))
		ep--;
	len = (ep < sp) ? 0:(ep-sp)+1;
	sp[len] = '\0';
	return sp;
}

void print_error(){
	write(STDERR_FILENO, error, strlen(error));
}

void print_prompt(){
	write(STDOUT_FILENO, prompt, strlen(prompt));
}

int main(int argc, char** argv){
	//initiate
	for(int i=0; i< MAX_BG; i++){
		bg_jobs[i].jid = -1;
		bg_jobs[i].pid = -1;
	}
	int fd_stdout;
	pid_t child;
	int status;
	char input[IN_SIZE];
	FILE *input_file = NULL;
	//*****************
	//check mysh argc**
	//*****************
	if(argc == 1){
		//not batch
		input_file = stdin;
	}
	else if(argc == 2){
		//batch
		is_batch = 1;
		input_file = fopen(argv[1], "r");
		if(input_file == NULL){
			char error_info[50];
			sprintf(error_info, "Error: Cannot open file %s\n", argv[1]);
			write(STDERR_FILENO, error_info, strlen(error_info));
			exit(1);
		}
	}
	else{
		//too many input arguments
		write(STDERR_FILENO, "Usage: mysh [batchFile]\n", strlen("Usage: mysh [batchFile]\n"));
		exit(1);
	}
	if(!is_batch) print_prompt();
	//read and run input lines
	while(fgets(input, IN_SIZE, input_file)){
		//******************
		//check input line**
		//******************
		if(is_batch){
			write(STDOUT_FILENO, input, strlen(input));
		}
		// if input too large
		if(strlen(input) > 512){
			write(STDERR_FILENO, "too long command line(max: 512)\n", strlen("too long command line(max: 512)\n"));
			if(!is_batch) print_prompt();
			continue;
		}
		int words_count = split_line(input, words);
		// allow empty input
		if(words_count == 0 || (words_count == 1 && strcmp(words[0], "&")==0)){
			if(!is_batch) print_prompt();
			continue;
		}

		//*****************
		//check command****
		//*****************
		int is_background = 0;
		int is_built_in = 0;
		// check for background
		if(strcmp(words[words_count-1], "&") == 0 || input[strlen(input)-2] == '&'){
			is_background = 1;
			//delete "&"
			strtok(input, "&");
			strcpy(input, strim(input));
			if(strcmp(words[words_count-1], "&") == 0){
				//words[words_count-1] = NULL;
				words_count--;
			}
			else{
				words[words_count-1][strlen(words[words_count-1]) - 1] = '\0';
			}
		}
		// check for redirection
		char* tmp = strdup(input);
		char* pre_token = strtok(tmp, ">");
		char* post_token = NULL;
		if(strlen(pre_token) != strlen(input)){
			post_token = strtok(NULL, ">");
			//is_redir = 1;
			//multiple redirections
			if(strtok(NULL, ">")){
				print_error();
				if(!is_batch) print_prompt();
				continue;
			}
			//check redirection files number
			char* tmp_words[50];
			int count = split_line(post_token, tmp_words);
			if(count < 1){
				//no files
				print_error();
				if(!is_batch) print_prompt();
				continue;
			}
			else if(count > 2){
				//too many files
				print_error();
				if(!is_batch) print_prompt();
				continue;
			}
			else if(count == 2 && strcmp(tmp_words[count-1], "&")!=0){
				//too many files
				print_error();
				if(!is_batch) print_prompt();
				continue;
			}
			else if(count == 1 && strcmp(tmp_words[count-1], "&")==0){
				//no files
				print_error();
				if(!is_batch) print_prompt();
				continue;
			}
			//implement redirection
			fd_stdout = dup(1);
			int fd = open(words[words_count-1], O_CREAT|O_RDWR|O_TRUNC, S_IRUSR|S_IWUSR);
			if(fd < 0){
				print_error();
				if(!is_batch) print_prompt();
				continue;
			}
			else if(dup2(fd, 1) < 0){
				print_error();
				if(!is_batch) print_prompt();
				continue;
			}
			words_count -= 2; 
		}
		
		//******************
		//exe***************
		//******************
		words[words_count] = NULL;
		//build-in commands		
		//exit
		if(strcmp("exit", words[0])==0 && words_count == 1){
			is_built_in = 1;
			exit(0);
		}
		//jobs: list all running jobs
		if(strcmp("jobs", words[0])==0 && words_count == 1){
			is_built_in = 1;
			for(int i=0; i<MAX_BG; i++){
				int flag = -1;
				if(bg_jobs[i].pid != -1) flag = (int)waitpid(bg_jobs[i].pid, &status, WNOHANG);
				if(flag == 0){  
					// still running background jobs
					char str[1100];
					sprintf(str, "%d : %s\n", bg_jobs[i].jid, bg_jobs[i].command);
					write(STDOUT_FILENO, str, strlen(str)); 
				}
			}
			if(!is_batch) print_prompt();
			dup2(fd_stdout, 1);
			continue;	
		}
		//wait job_id
		if(strcmp("wait", words[0])==0){
			is_built_in = 1;
			if(words_count != 2){
				print_error();
				if(!is_batch) print_prompt();
				dup2(fd_stdout, 1);
				continue;
			}
			else{
				int jid = atoi(words[1]);
				int wait_bg_job = 0;
				for(int i=0; i<MAX_BG; i++){
					if(jid == bg_jobs[i].jid){
						wait_bg_job = 1;
					}
				}
				if(wait_bg_job == 0){
					char error_info[50];
					sprintf(error_info, "Invalid JID %d\n", jid);
					write(STDERR_FILENO, error_info, strlen(error_info));
				}
				//background job
				else{
					int pid = bg_jobs[jid].pid;
					while(waitpid(pid, NULL, 0)){
						if(errno == ECHILD) break;
					}
					char str[50];
					sprintf(str, "JID %d terminated\n", jid);
					write(STDOUT_FILENO, str, strlen(str));
				}
				if(!is_batch) print_prompt();
				dup2(fd_stdout, 1);
				continue;
			}
		}
		// Non build-in commands
		if(!is_built_in){
			JID++;
			child = fork();
			if(child == 0){	
				execvp(words[0], words);
				char error_info[50];
				sprintf(error_info, "%s: Command not found\n", words[0]);
				write(STDERR_FILENO, error_info, strlen(error_info));
				exit(0);
			}
			else if(child == (pid_t)(-1)){
				print_error();
			}
			else{
				if(is_background){
					bg_jobs[bg_job_count].jid = JID;
					bg_jobs[bg_job_count].pid = child;
					strcpy(bg_jobs[bg_job_count].command, input);
					bg_job_count++;
				}
				if(!is_background){
					waitpid(child, &status, 0);
				}
			}
		}
		dup2(fd_stdout, 1); //redirect back
		if(!is_batch) print_prompt();
	}
	return 0;
}
