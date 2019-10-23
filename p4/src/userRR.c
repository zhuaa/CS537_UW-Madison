#include "types.h"
#include "stat.h"
#include "user.h"
#include "param.h"

int main(int argc, char **argv){
        if(argc != 5){
		printf(2, "userRR <user-level-timeslice> <iterations> <job> <jobcount>");
                exit();
        }
	int count = atoi(argv[4]);
	int timeslice = atoi(argv[1]);
	int iteration = atoi(argv[2]);
	char* job = argv[3];

        int children[NPROC];
	int index = 0;
	for(int i=0; i<count; i++){
	    int child = fork2(PRIORITY_ZERO);
	    children[index++] = child;
	    if(child == 0) {
	      char *args[1];
              args[0] = "loop";
              exec(job, args);
	      exit();
	    }
	    else{
	      continue;
	    }
        }
	for(int i=0; i<iteration; i++){
	  for(int j=0; j<count; j++){
	    setpri(children[j], PRIORITY_ONE);
	    sleep(timeslice);
	    setpri(children[j], PRIORITY_ZERO);
	  }
	}
        exit();
}
