#include "types.h"
#include "stat.h"
#include "user.h"

int 
main(int argc, char **argv)
{
   if(argc != 3){
     printf(2, "usage: setpri pid pri\n");
     exit();
   }
   int result = setpri(atoi(argv[1]), atoi(argv[2]));
   printf(2, "*****setpri result: %d\n", result);
   return result;
   exit();
}
