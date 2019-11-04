// Physical memory allocator, intended to allocate
// memory for user processes, kernel stacks, page table pages,
// and pipe buffers. Allocates 4096-byte pages.

#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "spinlock.h"
#include "proc.h"

void freerange(void *vstart, void *vend);
extern char end[]; // first address after kernel loaded from ELF file
                   // defined by the kernel linker script in kernel.ld

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  int use_lock;
  struct run *freelist;
} kmem;

// Initialization happens in two phases.
// 1. main() calls kinit1() while still using entrypgdir to place just
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
  initlock(&kmem.lock, "kmem");
  kmem.use_lock = 0;
  freerange(vstart, vend);
}

void
kinit2(void *vstart, void *vend)
{
  freerange(vstart, vend);
  kmem.use_lock = 1;
}

void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
    kfree(p);
}
// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{

  FRAMES[V2P(v)>>12] = -1;
  struct run *r;
  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);

  if(kmem.use_lock)
    acquire(&kmem.lock);
  r = (struct run*)v;
  r->next = kmem.freelist;
  kmem.freelist = r;
  if(kmem.use_lock)
    release(&kmem.lock);
}


// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
  struct run *r;

  if(kmem.use_lock)
    acquire(&kmem.lock);
  r = kmem.freelist;
  if(r)
    kmem.freelist = r->next;
  if(kmem.use_lock)
    release(&kmem.lock);
  return (char*)r;
}


// new functions with pid
char*
kalloc2(int pid)
{
  struct run *r, *tmp, *pre;

  if(kmem.use_lock)
    acquire(&kmem.lock);
  r = kmem.freelist;
  tmp = r;
  pre = tmp;
  int pre_pid=0;
  int next_pid = 0;
  while(tmp){
	pre_pid = FRAMES[(V2P((char*)tmp)>>12)-1];
	next_pid = FRAMES[(V2P((char*)tmp)>>12)+1];
	if((pid==-2)||((pre_pid == pid || pre_pid == -1||pre_pid==-2)&&(next_pid == pid || next_pid == -1||next_pid==-2))){
	  break;
	}
	else{
	  pre = tmp;
	  tmp=tmp->next;
	}
  }

  if(tmp == r)
    kmem.freelist = r->next;
  else{
    pre->next = tmp->next;
  }
  if(kmem.use_lock)
    release(&kmem.lock);
  FRAMES[V2P((char*)tmp)>>12] = pid;
  log_frames[log_index]=V2P((char*)tmp)>>12;
  log_pids[log_index]=pid;
  log_index++;
  return (char*)tmp;
  
}
