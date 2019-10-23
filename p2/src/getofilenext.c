#include "types.h"
#include "stat.h"
#include "user.h"

int
main(int argc, char **argv)
{
  if(argc != 2){
    printf(2, "usage: getofilenext pid\n");
    exit();
  }

  int result = getofilenext(atoi(argv[1]));
  printf(2, "**getofilenext: %d\n", result);
  return result;
  exit();
}
