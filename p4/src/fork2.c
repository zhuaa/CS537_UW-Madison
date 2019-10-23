#include "types.h"
#include "stat.h"
#include "user.h"

int
main(int argc, char **argv)
{
   if(argc != 2){
     printf(2, "usage: fork2 pri\n");
     exit();
   }
   int result = fork2(atoi(argv[1]));
   printf(2, "*****fork2 result: %d\n", result);
   return result;
   exit();
}
