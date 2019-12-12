#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <limits.h>
#include <string.h>

#define stat xv6_stat
#define dirent xv6_dirent
#include "types.h"
#include "fs.h"
#include "stat.h"
#undef stat
#undef dirent

const char* USAGE_ERR = "Usage: fscheck <file_system_image>";
const char* IMG_NOT_FOUND_ERR = "image not found.";

const char* ERR_BAD_INODE = "ERROR: bad inode.";
const char* ERR_BAD_INODE_SIZE = "ERROR: bad size in inode.";

const char* ERR_ROOT = "ERROR: root directory does not exist.";
const char* ERR_BAD_DIR_FORMAT = "ERROR: current directory mismatch.";

const char* ERR_USED_ADDR_BM_ZERO = "ERROR: bitmap marks data free but data block used by inode.";
const char* ERR_UNUSED_ADDR_BM_ONE = "ERROR: bitmap marks data block in use but not used.";

const char* ERR_USED_INODE_NOT_IN_DIR = "ERROR: inode marked in use but not found in a directory.";
const char* ERR_UNUSED_INODE_IN_DIR = "ERROR: inode marked free but referred to in directory.";


void raise_error(const char* err_msg)
{
    fprintf(stderr, "%s\n", err_msg);
    exit(1);
}

void* get_block_address(uint block_index, void* imgPtr) {
    return ((char*)imgPtr + block_index * BSIZE);
}

// ToDo: modify
char* itoa_base2(uint value, char* buffer)
{ 
    int base = 2;
	uint n = value;

	int i = 0;
	while (n) {
		int r = n % base;
		if (r>=10) buffer[i++] = 65 + (r-10);
		else buffer[i++] = 48 + r;
		n = n / base;
	}

	if (i == 0) buffer[i++] = '0';
	if (value < 0 && base == 10) buffer[i++] = '-';

	while (i < 32)
		buffer[i++] = '0';

	buffer[i] = '\0'; // null terminate string

	// reverse the string and return it
	return buffer;
}

int main(int argc, char* argv[])
{
    int fd;
    if (argc == 2){
        fd = open(argv[1], O_RDONLY);
    } else {
        raise_error(USAGE_ERR);   
    }
    if (fd < 0){
        raise_error(IMG_NOT_FOUND_ERR);
    }

    struct stat sbuf;
    fstat(fd, &sbuf);    

    // mmap
    void* img_ptr = mmap(NULL, sbuf.st_size,PROT_READ, MAP_PRIVATE, fd, 0);
    if (img_ptr ==(void*) -1){
        exit(1);
    }

    // | unused | super | inodes
    struct superblock *sb = (struct superblock*)((char*)img_ptr + BSIZE);

    struct dinode* inodes = (struct dinode*) ((char*)img_ptr + 32*BSIZE);
    uint block_addr;
    struct xv6_dirent* directories;
    uint* indirect_addrs;
    
    int block_used_amounts[sb->size];
    for (int i = 0; i < sb->size; i++)  block_used_amounts[i] = 0;

    if (inodes[1].type != T_DIR)
        raise_error(ERR_ROOT);
    

    // A. Enumerate Inodes
    for (int it_inode = 1; it_inode < sb->ninodes; it_inode++){
        // legal type: 0, T_FILE, T_DIR, T_DEV
       
	if (inodes[it_inode].type == 0)
            continue;
        if (!(inodes[it_inode].type == T_FILE || inodes[it_inode].type == T_DIR || T_DEV ==inodes[it_inode].type)){
            raise_error(ERR_BAD_INODE);
        }
        
	int databloacks = 0;
	for(int i=0; i<12; i++){
	  int addr = inodes[it_inode].addrs[i];
	  if(addr != 0 ) databloacks++;
	}
	if(inodes[it_inode].addrs[12] != 0){
          int n = *((int*)((char*)img_ptr + inodes[it_inode].addrs[12]*BSIZE));
	  for(int i=0; i<n; i++){
	    int tmp = *((int*)((char*)img_ptr + inodes[it_inode].addrs[12]*BSIZE + i*4));
	    if(tmp == 0) break;
	    databloacks++;
	  }
	}
	
	if(databloacks * 512 - inodes[it_inode].size >= 512){
            raise_error(ERR_BAD_INODE_SIZE);
	}

        // check T_DIR related
        if (inodes[it_inode].type == T_DIR){
            block_addr = inodes[it_inode].addrs[0];
            directories = (struct xv6_dirent*)((char*)img_ptr + block_addr*BSIZE);
	    if (directories[0].inum != it_inode){
                raise_error(ERR_BAD_DIR_FORMAT);
	    }
            if (it_inode == 1 && (directories[0].inum != 1 || directories[1].inum != 1))
                raise_error(ERR_ROOT);
        }
        // Enumerate Direct Addr
        for (int it_addr = 0; it_addr < NDIRECT; it_addr++){
            block_addr = inodes[it_inode].addrs[it_addr];
            if (block_addr == 0)
                continue;
            block_used_amounts[block_addr]++;
        }
        // Indirect Addr
        if (inodes[it_inode].addrs[NDIRECT] == 0) // check if the final block be in use
            continue;
        block_used_amounts[inodes[it_inode].addrs[NDIRECT]]++;

        indirect_addrs = (uint*)((char*)img_ptr + BSIZE*inodes[it_inode].addrs[NDIRECT]);
        int it_indirect_addr = 0;
        while (it_indirect_addr < BSIZE/sizeof(uint) &&\
                indirect_addrs[it_indirect_addr] != 0 ){
            block_used_amounts[indirect_addrs[it_indirect_addr]]++;
            it_indirect_addr++;
        }
    }
    
    // bitmap
    char* bitmap = (char*)malloc(sizeof(char) * 1024);
    uint* bitptr = (uint*) ((char*)img_ptr + 58 * BSIZE);
    for (int i=0; i<32; i++){
        char buffer[4];
        strcat(bitmap, itoa_base2(bitptr[i], buffer));
    }

    for (int it_addr = 59; it_addr < sb->size; it_addr++){
        if (block_used_amounts[it_addr] == 1 && bitmap[it_addr] == '0')
            raise_error(ERR_USED_ADDR_BM_ZERO);
        if (block_used_amounts[it_addr] == 0 && bitmap[it_addr] == '1')
            raise_error(ERR_UNUSED_ADDR_BM_ONE);
    }
    free(bitmap);
    

    // check inode used by directory
    int inode_used_amounts[sb->ninodes];
    for (int i = 0; i < sb->ninodes; i++)  inode_used_amounts[i] = 0;
    
    for (int it_inode = 1; it_inode < sb->ninodes; it_inode++){
        if (inodes[it_inode].type != T_DIR)
            continue;
        // Enumerate Direct Addr
        for (int it_addr = 0; it_addr < NDIRECT; it_addr++){
            block_addr = inodes[it_inode].addrs[it_addr];
            if (block_addr == 0)
                continue;
            directories = (struct xv6_dirent*) ((char*)img_ptr + block_addr*BSIZE);
            for (int it_directory = 0; it_directory < BSIZE/sizeof(struct xv6_dirent); it_directory++){
                if (directories[it_directory].inum > 0)
                    inode_used_amounts[directories[it_directory].inum]++;
            }
        }
        // Indirect Addr
        indirect_addrs = (uint*)((char*)img_ptr + BSIZE*inodes[it_inode].addrs[NDIRECT]);
        for (int it_indirect_addr = 0; it_indirect_addr < BSIZE/sizeof(uint); it_indirect_addr++){
            if (indirect_addrs[it_indirect_addr] == 0)
                continue;
            directories = (struct xv6_dirent*) ((char*)img_ptr + indirect_addrs[it_indirect_addr]*BSIZE);
            for (int it_directory = 0; it_directory < BSIZE/sizeof(struct xv6_dirent); it_directory++){
                if (directories[it_directory].inum > 0)
                    inode_used_amounts[directories[it_directory].inum]++;
            }
        }
    }
    inode_used_amounts[1] = 1;

    for (int it_inode = 1; it_inode < sb->ninodes; it_inode++){
        if (inodes[it_inode].type != 0 && inode_used_amounts[it_inode] == 0)
            raise_error(ERR_USED_INODE_NOT_IN_DIR);
        if (inodes[it_inode].type == 0 && inode_used_amounts[it_inode] != 0)
            raise_error(ERR_UNUSED_INODE_IN_DIR);
    }
    
    exit(0);
}
