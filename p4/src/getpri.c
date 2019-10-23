#include "types.h"
#include "stat.h"
#include "user.h"

int
main(int argc, char **argv)
{
   if(argc != 2){
     printf(2, "usage: getpri pid\n");
     exit();
   }
   int result = getpri(atoi(argv[1]));
   printf(2, "*****getpri result: %d\n", result);
   return result;
   exit();
}
