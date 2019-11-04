#include "types.h"
#include "stat.h"
#include "user.h"
#include "param.h"


int
main(int argc, char **argv)
{
  int numframes = 200;
  int frames[numframes];
  int pids[numframes];
  
  for(int i=0; i<numframes; i++){
	  frames[i] = -1;
	  pids[i] = -1;
  }
  
  int result = dump_physmem(frames, pids, numframes);
  if(result == 0){
	  printf(2, "succeed\n");
	  for(int i=0; i<numframes; i++){
	    printf(2, "frames[%d]: %d\n", i,  frames[i]);
	    printf(2, "pids[%d]: %d\n", i, pids[i]);
	  }
  }
  else{
	  printf(2, "fail\n");
  }
  exit();
}
