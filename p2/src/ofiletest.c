#include "types.h"
#include "stat.h"
#include "user.h"
#include "fcntl.h"

// strcat()
char* strcat(char* destination, const char* source)
{
	// make ptr point to the end of destination string
	char* ptr = destination + strlen(destination);
	// Appends characters of source to the destination string
	while (*source != '\0')
		*ptr++ = *source++;
	// null terminate destination string
	*ptr = '\0';
	// destination is returned by standard strcat()
	return destination;
}

// inline function to swap two numbers
inline void swap(char *x, char *y) {
	char t = *x; *x = *y; *y = t;
}

// reverse buffer[i..j]
char* reverse(char *buffer, int i, int j)
{
	while (i < j)
		swap(&buffer[i++], &buffer[j--]);
	return buffer;
}

// itoa()
char* itoa(int value, char* buffer, int base)
{
	// invalid input
	if (base < 2 || base > 32)
		return buffer;
	// consider absolute value of number
	int n = value;
	int i = 0;
	while (n)
	{
		int r = n % base;
		if (r >= 10) 
			buffer[i++] = 65 + (r - 10);
		else
			buffer[i++] = 48 + r;
		n = n / base;
	}
	// if number is 0
	if (i == 0)
		buffer[i++] = '0';
	// If base is 10 and value is negative, the resulting string 
	// is preceded with a minus sign (-)
	// With any other base, value is always considered unsigned
	if (value < 0 && base == 10)
		buffer[i++] = '-';
	buffer[i] = '\0'; // null terminate string
	// reverse the string and return it
	return reverse(buffer, 0, i - 1);
}

int
main(int argc, char **argv)
{
  if(argc < 2){
    printf(2, "usage: filetest N ...\n");
    exit();
  }
  int open_file_number = atoi(argv[1]);
  //printf(2, "**open_file_number: %d\n", open_file_number);
  
  // open files
  for(int i = 0; i < open_file_number; i++)
  {
    char *file_name;
    char snum[5];
    itoa(i, snum, 10);
    char *pre = "ofile";
    file_name = malloc(strlen(pre)+strlen(snum)+1);
    strcat(file_name, pre);
    strcat(file_name, snum);
    //printf(2, "**file_name: %s\n", file_name);
    open(file_name, O_CREATE);
    //printf(2, "**fd: %d\n", fd);
  }
  //printf(2, "**open file end.\n");
  
  // close files
  for(int i = 2; i < argc; i++)
  {
    char *file_name;
    char *pre = "ofile";
    file_name = malloc(strlen(pre)+strlen(argv[i])+1);
    strcat(file_name,  pre);
    strcat(file_name, argv[i]);
    //printf(2, "**file_name: %s\n", file_name);
    int fd = 3 + atoi(argv[i]);
    //printf(2, "**fd: %d\n", fd);
    close(fd);
  }
  //printf(2, "**close file end.\n");
  
  // system call
  int pid = getpid();
  //printf(2, "**getpid: %d\n", pid);
  int open_file_cnt = getofilecnt(pid);
  //printf(2, "**getofilecnt: %d\n", open_file_cnt);
  int next_fd = getofilenext(pid);
  //printf(2, "**getofilenext: %d\n", next_fd);
  
  printf(1, "%d %d\n", open_file_cnt, next_fd);
  exit();
}

