#include "types.h"
#include "stat.h"
#include "user.h"

int
main(int argc, char **argv)
{
  if(argc != 2){
    printf(2, "usage: getofilecnt pid\n");
    exit();
  }

  int result = getofilecnt(atoi(argv[1]));
  printf(2, "**getofilecnt: %d\n", result);
  return result;
  exit();
}
