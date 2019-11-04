
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4                   	.byte 0xe4

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 80 10 00       	mov    $0x108000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc c0 a5 10 80       	mov    $0x8010a5c0,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 9e 2a 10 80       	mov    $0x80102a9e,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <bget>:
// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf*
bget(uint dev, uint blockno)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	57                   	push   %edi
80100038:	56                   	push   %esi
80100039:	53                   	push   %ebx
8010003a:	83 ec 18             	sub    $0x18,%esp
8010003d:	89 c6                	mov    %eax,%esi
8010003f:	89 d7                	mov    %edx,%edi
  struct buf *b;

  acquire(&bcache.lock);
80100041:	68 c0 a5 10 80       	push   $0x8010a5c0
80100046:	e8 38 3c 00 00       	call   80103c83 <acquire>

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
8010004b:	8b 1d 10 ed 10 80    	mov    0x8010ed10,%ebx
80100051:	83 c4 10             	add    $0x10,%esp
80100054:	eb 03                	jmp    80100059 <bget+0x25>
80100056:	8b 5b 54             	mov    0x54(%ebx),%ebx
80100059:	81 fb bc ec 10 80    	cmp    $0x8010ecbc,%ebx
8010005f:	74 30                	je     80100091 <bget+0x5d>
    if(b->dev == dev && b->blockno == blockno){
80100061:	39 73 04             	cmp    %esi,0x4(%ebx)
80100064:	75 f0                	jne    80100056 <bget+0x22>
80100066:	39 7b 08             	cmp    %edi,0x8(%ebx)
80100069:	75 eb                	jne    80100056 <bget+0x22>
      b->refcnt++;
8010006b:	8b 43 4c             	mov    0x4c(%ebx),%eax
8010006e:	83 c0 01             	add    $0x1,%eax
80100071:	89 43 4c             	mov    %eax,0x4c(%ebx)
      release(&bcache.lock);
80100074:	83 ec 0c             	sub    $0xc,%esp
80100077:	68 c0 a5 10 80       	push   $0x8010a5c0
8010007c:	e8 67 3c 00 00       	call   80103ce8 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 e3 39 00 00       	call   80103a6f <acquiresleep>
      return b;
8010008c:	83 c4 10             	add    $0x10,%esp
8010008f:	eb 4c                	jmp    801000dd <bget+0xa9>
  }

  // Not cached; recycle an unused buffer.
  // Even if refcnt==0, B_DIRTY indicates a buffer is in use
  // because log.c has modified it but not yet committed it.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100091:	8b 1d 0c ed 10 80    	mov    0x8010ed0c,%ebx
80100097:	eb 03                	jmp    8010009c <bget+0x68>
80100099:	8b 5b 50             	mov    0x50(%ebx),%ebx
8010009c:	81 fb bc ec 10 80    	cmp    $0x8010ecbc,%ebx
801000a2:	74 43                	je     801000e7 <bget+0xb3>
    if(b->refcnt == 0 && (b->flags & B_DIRTY) == 0) {
801000a4:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801000a8:	75 ef                	jne    80100099 <bget+0x65>
801000aa:	f6 03 04             	testb  $0x4,(%ebx)
801000ad:	75 ea                	jne    80100099 <bget+0x65>
      b->dev = dev;
801000af:	89 73 04             	mov    %esi,0x4(%ebx)
      b->blockno = blockno;
801000b2:	89 7b 08             	mov    %edi,0x8(%ebx)
      b->flags = 0;
801000b5:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
      b->refcnt = 1;
801000bb:	c7 43 4c 01 00 00 00 	movl   $0x1,0x4c(%ebx)
      release(&bcache.lock);
801000c2:	83 ec 0c             	sub    $0xc,%esp
801000c5:	68 c0 a5 10 80       	push   $0x8010a5c0
801000ca:	e8 19 3c 00 00       	call   80103ce8 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 95 39 00 00       	call   80103a6f <acquiresleep>
      return b;
801000da:	83 c4 10             	add    $0x10,%esp
    }
  }
  panic("bget: no buffers");
}
801000dd:	89 d8                	mov    %ebx,%eax
801000df:	8d 65 f4             	lea    -0xc(%ebp),%esp
801000e2:	5b                   	pop    %ebx
801000e3:	5e                   	pop    %esi
801000e4:	5f                   	pop    %edi
801000e5:	5d                   	pop    %ebp
801000e6:	c3                   	ret    
  panic("bget: no buffers");
801000e7:	83 ec 0c             	sub    $0xc,%esp
801000ea:	68 80 65 10 80       	push   $0x80106580
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 91 65 10 80       	push   $0x80106591
80100100:	68 c0 a5 10 80       	push   $0x8010a5c0
80100105:	e8 3d 3a 00 00       	call   80103b47 <initlock>
  bcache.head.prev = &bcache.head;
8010010a:	c7 05 0c ed 10 80 bc 	movl   $0x8010ecbc,0x8010ed0c
80100111:	ec 10 80 
  bcache.head.next = &bcache.head;
80100114:	c7 05 10 ed 10 80 bc 	movl   $0x8010ecbc,0x8010ed10
8010011b:	ec 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010011e:	83 c4 10             	add    $0x10,%esp
80100121:	bb f4 a5 10 80       	mov    $0x8010a5f4,%ebx
80100126:	eb 37                	jmp    8010015f <binit+0x6b>
    b->next = bcache.head.next;
80100128:	a1 10 ed 10 80       	mov    0x8010ed10,%eax
8010012d:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
80100130:	c7 43 50 bc ec 10 80 	movl   $0x8010ecbc,0x50(%ebx)
    initsleeplock(&b->lock, "buffer");
80100137:	83 ec 08             	sub    $0x8,%esp
8010013a:	68 98 65 10 80       	push   $0x80106598
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 f4 38 00 00       	call   80103a3c <initsleeplock>
    bcache.head.next->prev = b;
80100148:	a1 10 ed 10 80       	mov    0x8010ed10,%eax
8010014d:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
80100150:	89 1d 10 ed 10 80    	mov    %ebx,0x8010ed10
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100156:	81 c3 5c 02 00 00    	add    $0x25c,%ebx
8010015c:	83 c4 10             	add    $0x10,%esp
8010015f:	81 fb bc ec 10 80    	cmp    $0x8010ecbc,%ebx
80100165:	72 c1                	jb     80100128 <binit+0x34>
}
80100167:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010016a:	c9                   	leave  
8010016b:	c3                   	ret    

8010016c <bread>:

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
8010016c:	55                   	push   %ebp
8010016d:	89 e5                	mov    %esp,%ebp
8010016f:	53                   	push   %ebx
80100170:	83 ec 04             	sub    $0x4,%esp
  struct buf *b;

  b = bget(dev, blockno);
80100173:	8b 55 0c             	mov    0xc(%ebp),%edx
80100176:	8b 45 08             	mov    0x8(%ebp),%eax
80100179:	e8 b6 fe ff ff       	call   80100034 <bget>
8010017e:	89 c3                	mov    %eax,%ebx
  if((b->flags & B_VALID) == 0) {
80100180:	f6 00 02             	testb  $0x2,(%eax)
80100183:	74 07                	je     8010018c <bread+0x20>
    iderw(b);
  }
  return b;
}
80100185:	89 d8                	mov    %ebx,%eax
80100187:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010018a:	c9                   	leave  
8010018b:	c3                   	ret    
    iderw(b);
8010018c:	83 ec 0c             	sub    $0xc,%esp
8010018f:	50                   	push   %eax
80100190:	e8 77 1c 00 00       	call   80101e0c <iderw>
80100195:	83 c4 10             	add    $0x10,%esp
  return b;
80100198:	eb eb                	jmp    80100185 <bread+0x19>

8010019a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
8010019a:	55                   	push   %ebp
8010019b:	89 e5                	mov    %esp,%ebp
8010019d:	53                   	push   %ebx
8010019e:	83 ec 10             	sub    $0x10,%esp
801001a1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holdingsleep(&b->lock))
801001a4:	8d 43 0c             	lea    0xc(%ebx),%eax
801001a7:	50                   	push   %eax
801001a8:	e8 4c 39 00 00       	call   80103af9 <holdingsleep>
801001ad:	83 c4 10             	add    $0x10,%esp
801001b0:	85 c0                	test   %eax,%eax
801001b2:	74 14                	je     801001c8 <bwrite+0x2e>
    panic("bwrite");
  b->flags |= B_DIRTY;
801001b4:	83 0b 04             	orl    $0x4,(%ebx)
  iderw(b);
801001b7:	83 ec 0c             	sub    $0xc,%esp
801001ba:	53                   	push   %ebx
801001bb:	e8 4c 1c 00 00       	call   80101e0c <iderw>
}
801001c0:	83 c4 10             	add    $0x10,%esp
801001c3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801001c6:	c9                   	leave  
801001c7:	c3                   	ret    
    panic("bwrite");
801001c8:	83 ec 0c             	sub    $0xc,%esp
801001cb:	68 9f 65 10 80       	push   $0x8010659f
801001d0:	e8 73 01 00 00       	call   80100348 <panic>

801001d5 <brelse>:

// Release a locked buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
801001d5:	55                   	push   %ebp
801001d6:	89 e5                	mov    %esp,%ebp
801001d8:	56                   	push   %esi
801001d9:	53                   	push   %ebx
801001da:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holdingsleep(&b->lock))
801001dd:	8d 73 0c             	lea    0xc(%ebx),%esi
801001e0:	83 ec 0c             	sub    $0xc,%esp
801001e3:	56                   	push   %esi
801001e4:	e8 10 39 00 00       	call   80103af9 <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 c5 38 00 00       	call   80103abe <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 c0 a5 10 80 	movl   $0x8010a5c0,(%esp)
80100200:	e8 7e 3a 00 00       	call   80103c83 <acquire>
  b->refcnt--;
80100205:	8b 43 4c             	mov    0x4c(%ebx),%eax
80100208:	83 e8 01             	sub    $0x1,%eax
8010020b:	89 43 4c             	mov    %eax,0x4c(%ebx)
  if (b->refcnt == 0) {
8010020e:	83 c4 10             	add    $0x10,%esp
80100211:	85 c0                	test   %eax,%eax
80100213:	75 2f                	jne    80100244 <brelse+0x6f>
    // no one is waiting for it.
    b->next->prev = b->prev;
80100215:	8b 43 54             	mov    0x54(%ebx),%eax
80100218:	8b 53 50             	mov    0x50(%ebx),%edx
8010021b:	89 50 50             	mov    %edx,0x50(%eax)
    b->prev->next = b->next;
8010021e:	8b 43 50             	mov    0x50(%ebx),%eax
80100221:	8b 53 54             	mov    0x54(%ebx),%edx
80100224:	89 50 54             	mov    %edx,0x54(%eax)
    b->next = bcache.head.next;
80100227:	a1 10 ed 10 80       	mov    0x8010ed10,%eax
8010022c:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
8010022f:	c7 43 50 bc ec 10 80 	movl   $0x8010ecbc,0x50(%ebx)
    bcache.head.next->prev = b;
80100236:	a1 10 ed 10 80       	mov    0x8010ed10,%eax
8010023b:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
8010023e:	89 1d 10 ed 10 80    	mov    %ebx,0x8010ed10
  }
  
  release(&bcache.lock);
80100244:	83 ec 0c             	sub    $0xc,%esp
80100247:	68 c0 a5 10 80       	push   $0x8010a5c0
8010024c:	e8 97 3a 00 00       	call   80103ce8 <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 a6 65 10 80       	push   $0x801065a6
80100263:	e8 e0 00 00 00       	call   80100348 <panic>

80100268 <consoleread>:
  }
}

int
consoleread(struct inode *ip, char *dst, int n)
{
80100268:	55                   	push   %ebp
80100269:	89 e5                	mov    %esp,%ebp
8010026b:	57                   	push   %edi
8010026c:	56                   	push   %esi
8010026d:	53                   	push   %ebx
8010026e:	83 ec 28             	sub    $0x28,%esp
80100271:	8b 7d 08             	mov    0x8(%ebp),%edi
80100274:	8b 75 0c             	mov    0xc(%ebp),%esi
80100277:	8b 5d 10             	mov    0x10(%ebp),%ebx
  uint target;
  int c;

  iunlock(ip);
8010027a:	57                   	push   %edi
8010027b:	e8 c3 13 00 00       	call   80101643 <iunlock>
  target = n;
80100280:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  acquire(&cons.lock);
80100283:	c7 04 24 20 95 10 80 	movl   $0x80109520,(%esp)
8010028a:	e8 f4 39 00 00       	call   80103c83 <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 20 99 14 80       	mov    0x80149920,%eax
8010029f:	3b 05 24 99 14 80    	cmp    0x80149924,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 84 2f 00 00       	call   80103230 <myproc>
801002ac:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801002b0:	75 17                	jne    801002c9 <consoleread+0x61>
        release(&cons.lock);
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
801002b2:	83 ec 08             	sub    $0x8,%esp
801002b5:	68 20 95 10 80       	push   $0x80109520
801002ba:	68 20 99 14 80       	push   $0x80149920
801002bf:	e8 2c 34 00 00       	call   801036f0 <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 95 10 80       	push   $0x80109520
801002d1:	e8 12 3a 00 00       	call   80103ce8 <release>
        ilock(ip);
801002d6:	89 3c 24             	mov    %edi,(%esp)
801002d9:	e8 a3 12 00 00       	call   80101581 <ilock>
        return -1;
801002de:	83 c4 10             	add    $0x10,%esp
801002e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  release(&cons.lock);
  ilock(ip);

  return target - n;
}
801002e6:	8d 65 f4             	lea    -0xc(%ebp),%esp
801002e9:	5b                   	pop    %ebx
801002ea:	5e                   	pop    %esi
801002eb:	5f                   	pop    %edi
801002ec:	5d                   	pop    %ebp
801002ed:	c3                   	ret    
    c = input.buf[input.r++ % INPUT_BUF];
801002ee:	8d 50 01             	lea    0x1(%eax),%edx
801002f1:	89 15 20 99 14 80    	mov    %edx,0x80149920
801002f7:	89 c2                	mov    %eax,%edx
801002f9:	83 e2 7f             	and    $0x7f,%edx
801002fc:	0f b6 8a a0 98 14 80 	movzbl -0x7feb6760(%edx),%ecx
80100303:	0f be d1             	movsbl %cl,%edx
    if(c == C('D')){  // EOF
80100306:	83 fa 04             	cmp    $0x4,%edx
80100309:	74 14                	je     8010031f <consoleread+0xb7>
    *dst++ = c;
8010030b:	8d 46 01             	lea    0x1(%esi),%eax
8010030e:	88 0e                	mov    %cl,(%esi)
    --n;
80100310:	83 eb 01             	sub    $0x1,%ebx
    if(c == '\n')
80100313:	83 fa 0a             	cmp    $0xa,%edx
80100316:	74 11                	je     80100329 <consoleread+0xc1>
    *dst++ = c;
80100318:	89 c6                	mov    %eax,%esi
8010031a:	e9 73 ff ff ff       	jmp    80100292 <consoleread+0x2a>
      if(n < target){
8010031f:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
80100322:	73 05                	jae    80100329 <consoleread+0xc1>
        input.r--;
80100324:	a3 20 99 14 80       	mov    %eax,0x80149920
  release(&cons.lock);
80100329:	83 ec 0c             	sub    $0xc,%esp
8010032c:	68 20 95 10 80       	push   $0x80109520
80100331:	e8 b2 39 00 00       	call   80103ce8 <release>
  ilock(ip);
80100336:	89 3c 24             	mov    %edi,(%esp)
80100339:	e8 43 12 00 00       	call   80101581 <ilock>
  return target - n;
8010033e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100341:	29 d8                	sub    %ebx,%eax
80100343:	83 c4 10             	add    $0x10,%esp
80100346:	eb 9e                	jmp    801002e6 <consoleread+0x7e>

80100348 <panic>:
{
80100348:	55                   	push   %ebp
80100349:	89 e5                	mov    %esp,%ebp
8010034b:	53                   	push   %ebx
8010034c:	83 ec 34             	sub    $0x34,%esp
}

static inline void
cli(void)
{
  asm volatile("cli");
8010034f:	fa                   	cli    
  cons.locking = 0;
80100350:	c7 05 54 95 10 80 00 	movl   $0x0,0x80109554
80100357:	00 00 00 
  cprintf("lapicid %d: panic: ", lapicid());
8010035a:	e8 59 20 00 00       	call   801023b8 <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 ad 65 10 80       	push   $0x801065ad
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 1b 6f 10 80 	movl   $0x80106f1b,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 ce 37 00 00       	call   80103b62 <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 c1 65 10 80       	push   $0x801065c1
801003aa:	e8 5c 02 00 00       	call   8010060b <cprintf>
  for(i=0; i<10; i++)
801003af:	83 c3 01             	add    $0x1,%ebx
801003b2:	83 c4 10             	add    $0x10,%esp
801003b5:	83 fb 09             	cmp    $0x9,%ebx
801003b8:	7e e4                	jle    8010039e <panic+0x56>
  panicked = 1; // freeze other CPU
801003ba:	c7 05 58 95 10 80 01 	movl   $0x1,0x80109558
801003c1:	00 00 00 
801003c4:	eb fe                	jmp    801003c4 <panic+0x7c>

801003c6 <cgaputc>:
{
801003c6:	55                   	push   %ebp
801003c7:	89 e5                	mov    %esp,%ebp
801003c9:	57                   	push   %edi
801003ca:	56                   	push   %esi
801003cb:	53                   	push   %ebx
801003cc:	83 ec 0c             	sub    $0xc,%esp
801003cf:	89 c6                	mov    %eax,%esi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801003d1:	b9 d4 03 00 00       	mov    $0x3d4,%ecx
801003d6:	b8 0e 00 00 00       	mov    $0xe,%eax
801003db:	89 ca                	mov    %ecx,%edx
801003dd:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801003de:	bb d5 03 00 00       	mov    $0x3d5,%ebx
801003e3:	89 da                	mov    %ebx,%edx
801003e5:	ec                   	in     (%dx),%al
  pos = inb(CRTPORT+1) << 8;
801003e6:	0f b6 f8             	movzbl %al,%edi
801003e9:	c1 e7 08             	shl    $0x8,%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801003ec:	b8 0f 00 00 00       	mov    $0xf,%eax
801003f1:	89 ca                	mov    %ecx,%edx
801003f3:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801003f4:	89 da                	mov    %ebx,%edx
801003f6:	ec                   	in     (%dx),%al
  pos |= inb(CRTPORT+1);
801003f7:	0f b6 c8             	movzbl %al,%ecx
801003fa:	09 f9                	or     %edi,%ecx
  if(c == '\n')
801003fc:	83 fe 0a             	cmp    $0xa,%esi
801003ff:	74 6a                	je     8010046b <cgaputc+0xa5>
  else if(c == BACKSPACE){
80100401:	81 fe 00 01 00 00    	cmp    $0x100,%esi
80100407:	0f 84 81 00 00 00    	je     8010048e <cgaputc+0xc8>
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010040d:	89 f0                	mov    %esi,%eax
8010040f:	0f b6 f0             	movzbl %al,%esi
80100412:	8d 59 01             	lea    0x1(%ecx),%ebx
80100415:	66 81 ce 00 07       	or     $0x700,%si
8010041a:	66 89 b4 09 00 80 0b 	mov    %si,-0x7ff48000(%ecx,%ecx,1)
80100421:	80 
  if(pos < 0 || pos > 25*80)
80100422:	81 fb d0 07 00 00    	cmp    $0x7d0,%ebx
80100428:	77 71                	ja     8010049b <cgaputc+0xd5>
  if((pos/80) >= 24){  // Scroll up.
8010042a:	81 fb 7f 07 00 00    	cmp    $0x77f,%ebx
80100430:	7f 76                	jg     801004a8 <cgaputc+0xe2>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80100432:	be d4 03 00 00       	mov    $0x3d4,%esi
80100437:	b8 0e 00 00 00       	mov    $0xe,%eax
8010043c:	89 f2                	mov    %esi,%edx
8010043e:	ee                   	out    %al,(%dx)
  outb(CRTPORT+1, pos>>8);
8010043f:	89 d8                	mov    %ebx,%eax
80100441:	c1 f8 08             	sar    $0x8,%eax
80100444:	b9 d5 03 00 00       	mov    $0x3d5,%ecx
80100449:	89 ca                	mov    %ecx,%edx
8010044b:	ee                   	out    %al,(%dx)
8010044c:	b8 0f 00 00 00       	mov    $0xf,%eax
80100451:	89 f2                	mov    %esi,%edx
80100453:	ee                   	out    %al,(%dx)
80100454:	89 d8                	mov    %ebx,%eax
80100456:	89 ca                	mov    %ecx,%edx
80100458:	ee                   	out    %al,(%dx)
  crt[pos] = ' ' | 0x0700;
80100459:	66 c7 84 1b 00 80 0b 	movw   $0x720,-0x7ff48000(%ebx,%ebx,1)
80100460:	80 20 07 
}
80100463:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100466:	5b                   	pop    %ebx
80100467:	5e                   	pop    %esi
80100468:	5f                   	pop    %edi
80100469:	5d                   	pop    %ebp
8010046a:	c3                   	ret    
    pos += 80 - pos%80;
8010046b:	ba 67 66 66 66       	mov    $0x66666667,%edx
80100470:	89 c8                	mov    %ecx,%eax
80100472:	f7 ea                	imul   %edx
80100474:	c1 fa 05             	sar    $0x5,%edx
80100477:	8d 14 92             	lea    (%edx,%edx,4),%edx
8010047a:	89 d0                	mov    %edx,%eax
8010047c:	c1 e0 04             	shl    $0x4,%eax
8010047f:	89 ca                	mov    %ecx,%edx
80100481:	29 c2                	sub    %eax,%edx
80100483:	bb 50 00 00 00       	mov    $0x50,%ebx
80100488:	29 d3                	sub    %edx,%ebx
8010048a:	01 cb                	add    %ecx,%ebx
8010048c:	eb 94                	jmp    80100422 <cgaputc+0x5c>
    if(pos > 0) --pos;
8010048e:	85 c9                	test   %ecx,%ecx
80100490:	7e 05                	jle    80100497 <cgaputc+0xd1>
80100492:	8d 59 ff             	lea    -0x1(%ecx),%ebx
80100495:	eb 8b                	jmp    80100422 <cgaputc+0x5c>
  pos |= inb(CRTPORT+1);
80100497:	89 cb                	mov    %ecx,%ebx
80100499:	eb 87                	jmp    80100422 <cgaputc+0x5c>
    panic("pos under/overflow");
8010049b:	83 ec 0c             	sub    $0xc,%esp
8010049e:	68 c5 65 10 80       	push   $0x801065c5
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 eb 38 00 00       	call   80103daa <memmove>
    pos -= 80;
801004bf:	83 eb 50             	sub    $0x50,%ebx
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801004c2:	b8 80 07 00 00       	mov    $0x780,%eax
801004c7:	29 d8                	sub    %ebx,%eax
801004c9:	8d 94 1b 00 80 0b 80 	lea    -0x7ff48000(%ebx,%ebx,1),%edx
801004d0:	83 c4 0c             	add    $0xc,%esp
801004d3:	01 c0                	add    %eax,%eax
801004d5:	50                   	push   %eax
801004d6:	6a 00                	push   $0x0
801004d8:	52                   	push   %edx
801004d9:	e8 51 38 00 00       	call   80103d2f <memset>
801004de:	83 c4 10             	add    $0x10,%esp
801004e1:	e9 4c ff ff ff       	jmp    80100432 <cgaputc+0x6c>

801004e6 <consputc>:
  if(panicked){
801004e6:	83 3d 58 95 10 80 00 	cmpl   $0x0,0x80109558
801004ed:	74 03                	je     801004f2 <consputc+0xc>
  asm volatile("cli");
801004ef:	fa                   	cli    
801004f0:	eb fe                	jmp    801004f0 <consputc+0xa>
{
801004f2:	55                   	push   %ebp
801004f3:	89 e5                	mov    %esp,%ebp
801004f5:	53                   	push   %ebx
801004f6:	83 ec 04             	sub    $0x4,%esp
801004f9:	89 c3                	mov    %eax,%ebx
  if(c == BACKSPACE){
801004fb:	3d 00 01 00 00       	cmp    $0x100,%eax
80100500:	74 18                	je     8010051a <consputc+0x34>
    uartputc(c);
80100502:	83 ec 0c             	sub    $0xc,%esp
80100505:	50                   	push   %eax
80100506:	e8 5e 4c 00 00       	call   80105169 <uartputc>
8010050b:	83 c4 10             	add    $0x10,%esp
  cgaputc(c);
8010050e:	89 d8                	mov    %ebx,%eax
80100510:	e8 b1 fe ff ff       	call   801003c6 <cgaputc>
}
80100515:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100518:	c9                   	leave  
80100519:	c3                   	ret    
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010051a:	83 ec 0c             	sub    $0xc,%esp
8010051d:	6a 08                	push   $0x8
8010051f:	e8 45 4c 00 00       	call   80105169 <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 39 4c 00 00       	call   80105169 <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 2d 4c 00 00       	call   80105169 <uartputc>
8010053c:	83 c4 10             	add    $0x10,%esp
8010053f:	eb cd                	jmp    8010050e <consputc+0x28>

80100541 <printint>:
{
80100541:	55                   	push   %ebp
80100542:	89 e5                	mov    %esp,%ebp
80100544:	57                   	push   %edi
80100545:	56                   	push   %esi
80100546:	53                   	push   %ebx
80100547:	83 ec 1c             	sub    $0x1c,%esp
8010054a:	89 d7                	mov    %edx,%edi
  if(sign && (sign = xx < 0))
8010054c:	85 c9                	test   %ecx,%ecx
8010054e:	74 09                	je     80100559 <printint+0x18>
80100550:	89 c1                	mov    %eax,%ecx
80100552:	c1 e9 1f             	shr    $0x1f,%ecx
80100555:	85 c0                	test   %eax,%eax
80100557:	78 09                	js     80100562 <printint+0x21>
    x = xx;
80100559:	89 c2                	mov    %eax,%edx
  i = 0;
8010055b:	be 00 00 00 00       	mov    $0x0,%esi
80100560:	eb 08                	jmp    8010056a <printint+0x29>
    x = -xx;
80100562:	f7 d8                	neg    %eax
80100564:	89 c2                	mov    %eax,%edx
80100566:	eb f3                	jmp    8010055b <printint+0x1a>
    buf[i++] = digits[x % base];
80100568:	89 de                	mov    %ebx,%esi
8010056a:	89 d0                	mov    %edx,%eax
8010056c:	ba 00 00 00 00       	mov    $0x0,%edx
80100571:	f7 f7                	div    %edi
80100573:	8d 5e 01             	lea    0x1(%esi),%ebx
80100576:	0f b6 92 f0 65 10 80 	movzbl -0x7fef9a10(%edx),%edx
8010057d:	88 54 35 d8          	mov    %dl,-0x28(%ebp,%esi,1)
  }while((x /= base) != 0);
80100581:	89 c2                	mov    %eax,%edx
80100583:	85 c0                	test   %eax,%eax
80100585:	75 e1                	jne    80100568 <printint+0x27>
  if(sign)
80100587:	85 c9                	test   %ecx,%ecx
80100589:	74 14                	je     8010059f <printint+0x5e>
    buf[i++] = '-';
8010058b:	c6 44 1d d8 2d       	movb   $0x2d,-0x28(%ebp,%ebx,1)
80100590:	8d 5e 02             	lea    0x2(%esi),%ebx
80100593:	eb 0a                	jmp    8010059f <printint+0x5e>
    consputc(buf[i]);
80100595:	0f be 44 1d d8       	movsbl -0x28(%ebp,%ebx,1),%eax
8010059a:	e8 47 ff ff ff       	call   801004e6 <consputc>
  while(--i >= 0)
8010059f:	83 eb 01             	sub    $0x1,%ebx
801005a2:	79 f1                	jns    80100595 <printint+0x54>
}
801005a4:	83 c4 1c             	add    $0x1c,%esp
801005a7:	5b                   	pop    %ebx
801005a8:	5e                   	pop    %esi
801005a9:	5f                   	pop    %edi
801005aa:	5d                   	pop    %ebp
801005ab:	c3                   	ret    

801005ac <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
801005ac:	55                   	push   %ebp
801005ad:	89 e5                	mov    %esp,%ebp
801005af:	57                   	push   %edi
801005b0:	56                   	push   %esi
801005b1:	53                   	push   %ebx
801005b2:	83 ec 18             	sub    $0x18,%esp
801005b5:	8b 7d 0c             	mov    0xc(%ebp),%edi
801005b8:	8b 75 10             	mov    0x10(%ebp),%esi
  int i;

  iunlock(ip);
801005bb:	ff 75 08             	pushl  0x8(%ebp)
801005be:	e8 80 10 00 00       	call   80101643 <iunlock>
  acquire(&cons.lock);
801005c3:	c7 04 24 20 95 10 80 	movl   $0x80109520,(%esp)
801005ca:	e8 b4 36 00 00       	call   80103c83 <acquire>
  for(i = 0; i < n; i++)
801005cf:	83 c4 10             	add    $0x10,%esp
801005d2:	bb 00 00 00 00       	mov    $0x0,%ebx
801005d7:	eb 0c                	jmp    801005e5 <consolewrite+0x39>
    consputc(buf[i] & 0xff);
801005d9:	0f b6 04 1f          	movzbl (%edi,%ebx,1),%eax
801005dd:	e8 04 ff ff ff       	call   801004e6 <consputc>
  for(i = 0; i < n; i++)
801005e2:	83 c3 01             	add    $0x1,%ebx
801005e5:	39 f3                	cmp    %esi,%ebx
801005e7:	7c f0                	jl     801005d9 <consolewrite+0x2d>
  release(&cons.lock);
801005e9:	83 ec 0c             	sub    $0xc,%esp
801005ec:	68 20 95 10 80       	push   $0x80109520
801005f1:	e8 f2 36 00 00       	call   80103ce8 <release>
  ilock(ip);
801005f6:	83 c4 04             	add    $0x4,%esp
801005f9:	ff 75 08             	pushl  0x8(%ebp)
801005fc:	e8 80 0f 00 00       	call   80101581 <ilock>

  return n;
}
80100601:	89 f0                	mov    %esi,%eax
80100603:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100606:	5b                   	pop    %ebx
80100607:	5e                   	pop    %esi
80100608:	5f                   	pop    %edi
80100609:	5d                   	pop    %ebp
8010060a:	c3                   	ret    

8010060b <cprintf>:
{
8010060b:	55                   	push   %ebp
8010060c:	89 e5                	mov    %esp,%ebp
8010060e:	57                   	push   %edi
8010060f:	56                   	push   %esi
80100610:	53                   	push   %ebx
80100611:	83 ec 1c             	sub    $0x1c,%esp
  locking = cons.locking;
80100614:	a1 54 95 10 80       	mov    0x80109554,%eax
80100619:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  if(locking)
8010061c:	85 c0                	test   %eax,%eax
8010061e:	75 10                	jne    80100630 <cprintf+0x25>
  if (fmt == 0)
80100620:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80100624:	74 1c                	je     80100642 <cprintf+0x37>
  argp = (uint*)(void*)(&fmt + 1);
80100626:	8d 7d 0c             	lea    0xc(%ebp),%edi
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100629:	bb 00 00 00 00       	mov    $0x0,%ebx
8010062e:	eb 27                	jmp    80100657 <cprintf+0x4c>
    acquire(&cons.lock);
80100630:	83 ec 0c             	sub    $0xc,%esp
80100633:	68 20 95 10 80       	push   $0x80109520
80100638:	e8 46 36 00 00       	call   80103c83 <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 df 65 10 80       	push   $0x801065df
8010064a:	e8 f9 fc ff ff       	call   80100348 <panic>
      consputc(c);
8010064f:	e8 92 fe ff ff       	call   801004e6 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100654:	83 c3 01             	add    $0x1,%ebx
80100657:	8b 55 08             	mov    0x8(%ebp),%edx
8010065a:	0f b6 04 1a          	movzbl (%edx,%ebx,1),%eax
8010065e:	85 c0                	test   %eax,%eax
80100660:	0f 84 b8 00 00 00    	je     8010071e <cprintf+0x113>
    if(c != '%'){
80100666:	83 f8 25             	cmp    $0x25,%eax
80100669:	75 e4                	jne    8010064f <cprintf+0x44>
    c = fmt[++i] & 0xff;
8010066b:	83 c3 01             	add    $0x1,%ebx
8010066e:	0f b6 34 1a          	movzbl (%edx,%ebx,1),%esi
    if(c == 0)
80100672:	85 f6                	test   %esi,%esi
80100674:	0f 84 a4 00 00 00    	je     8010071e <cprintf+0x113>
    switch(c){
8010067a:	83 fe 70             	cmp    $0x70,%esi
8010067d:	74 48                	je     801006c7 <cprintf+0xbc>
8010067f:	83 fe 70             	cmp    $0x70,%esi
80100682:	7f 26                	jg     801006aa <cprintf+0x9f>
80100684:	83 fe 25             	cmp    $0x25,%esi
80100687:	0f 84 82 00 00 00    	je     8010070f <cprintf+0x104>
8010068d:	83 fe 64             	cmp    $0x64,%esi
80100690:	75 22                	jne    801006b4 <cprintf+0xa9>
      printint(*argp++, 10, 1);
80100692:	8d 77 04             	lea    0x4(%edi),%esi
80100695:	8b 07                	mov    (%edi),%eax
80100697:	b9 01 00 00 00       	mov    $0x1,%ecx
8010069c:	ba 0a 00 00 00       	mov    $0xa,%edx
801006a1:	e8 9b fe ff ff       	call   80100541 <printint>
801006a6:	89 f7                	mov    %esi,%edi
      break;
801006a8:	eb aa                	jmp    80100654 <cprintf+0x49>
    switch(c){
801006aa:	83 fe 73             	cmp    $0x73,%esi
801006ad:	74 33                	je     801006e2 <cprintf+0xd7>
801006af:	83 fe 78             	cmp    $0x78,%esi
801006b2:	74 13                	je     801006c7 <cprintf+0xbc>
      consputc('%');
801006b4:	b8 25 00 00 00       	mov    $0x25,%eax
801006b9:	e8 28 fe ff ff       	call   801004e6 <consputc>
      consputc(c);
801006be:	89 f0                	mov    %esi,%eax
801006c0:	e8 21 fe ff ff       	call   801004e6 <consputc>
      break;
801006c5:	eb 8d                	jmp    80100654 <cprintf+0x49>
      printint(*argp++, 16, 0);
801006c7:	8d 77 04             	lea    0x4(%edi),%esi
801006ca:	8b 07                	mov    (%edi),%eax
801006cc:	b9 00 00 00 00       	mov    $0x0,%ecx
801006d1:	ba 10 00 00 00       	mov    $0x10,%edx
801006d6:	e8 66 fe ff ff       	call   80100541 <printint>
801006db:	89 f7                	mov    %esi,%edi
      break;
801006dd:	e9 72 ff ff ff       	jmp    80100654 <cprintf+0x49>
      if((s = (char*)*argp++) == 0)
801006e2:	8d 47 04             	lea    0x4(%edi),%eax
801006e5:	89 45 e0             	mov    %eax,-0x20(%ebp)
801006e8:	8b 37                	mov    (%edi),%esi
801006ea:	85 f6                	test   %esi,%esi
801006ec:	75 12                	jne    80100700 <cprintf+0xf5>
        s = "(null)";
801006ee:	be d8 65 10 80       	mov    $0x801065d8,%esi
801006f3:	eb 0b                	jmp    80100700 <cprintf+0xf5>
        consputc(*s);
801006f5:	0f be c0             	movsbl %al,%eax
801006f8:	e8 e9 fd ff ff       	call   801004e6 <consputc>
      for(; *s; s++)
801006fd:	83 c6 01             	add    $0x1,%esi
80100700:	0f b6 06             	movzbl (%esi),%eax
80100703:	84 c0                	test   %al,%al
80100705:	75 ee                	jne    801006f5 <cprintf+0xea>
      if((s = (char*)*argp++) == 0)
80100707:	8b 7d e0             	mov    -0x20(%ebp),%edi
8010070a:	e9 45 ff ff ff       	jmp    80100654 <cprintf+0x49>
      consputc('%');
8010070f:	b8 25 00 00 00       	mov    $0x25,%eax
80100714:	e8 cd fd ff ff       	call   801004e6 <consputc>
      break;
80100719:	e9 36 ff ff ff       	jmp    80100654 <cprintf+0x49>
  if(locking)
8010071e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100722:	75 08                	jne    8010072c <cprintf+0x121>
}
80100724:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100727:	5b                   	pop    %ebx
80100728:	5e                   	pop    %esi
80100729:	5f                   	pop    %edi
8010072a:	5d                   	pop    %ebp
8010072b:	c3                   	ret    
    release(&cons.lock);
8010072c:	83 ec 0c             	sub    $0xc,%esp
8010072f:	68 20 95 10 80       	push   $0x80109520
80100734:	e8 af 35 00 00       	call   80103ce8 <release>
80100739:	83 c4 10             	add    $0x10,%esp
}
8010073c:	eb e6                	jmp    80100724 <cprintf+0x119>

8010073e <consoleintr>:
{
8010073e:	55                   	push   %ebp
8010073f:	89 e5                	mov    %esp,%ebp
80100741:	57                   	push   %edi
80100742:	56                   	push   %esi
80100743:	53                   	push   %ebx
80100744:	83 ec 18             	sub    $0x18,%esp
80100747:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&cons.lock);
8010074a:	68 20 95 10 80       	push   $0x80109520
8010074f:	e8 2f 35 00 00       	call   80103c83 <acquire>
  while((c = getc()) >= 0){
80100754:	83 c4 10             	add    $0x10,%esp
  int c, doprocdump = 0;
80100757:	be 00 00 00 00       	mov    $0x0,%esi
  while((c = getc()) >= 0){
8010075c:	e9 c5 00 00 00       	jmp    80100826 <consoleintr+0xe8>
    switch(c){
80100761:	83 ff 08             	cmp    $0x8,%edi
80100764:	0f 84 e0 00 00 00    	je     8010084a <consoleintr+0x10c>
      if(c != 0 && input.e-input.r < INPUT_BUF){
8010076a:	85 ff                	test   %edi,%edi
8010076c:	0f 84 b4 00 00 00    	je     80100826 <consoleintr+0xe8>
80100772:	a1 28 99 14 80       	mov    0x80149928,%eax
80100777:	89 c2                	mov    %eax,%edx
80100779:	2b 15 20 99 14 80    	sub    0x80149920,%edx
8010077f:	83 fa 7f             	cmp    $0x7f,%edx
80100782:	0f 87 9e 00 00 00    	ja     80100826 <consoleintr+0xe8>
        c = (c == '\r') ? '\n' : c;
80100788:	83 ff 0d             	cmp    $0xd,%edi
8010078b:	0f 84 86 00 00 00    	je     80100817 <consoleintr+0xd9>
        input.buf[input.e++ % INPUT_BUF] = c;
80100791:	8d 50 01             	lea    0x1(%eax),%edx
80100794:	89 15 28 99 14 80    	mov    %edx,0x80149928
8010079a:	83 e0 7f             	and    $0x7f,%eax
8010079d:	89 f9                	mov    %edi,%ecx
8010079f:	88 88 a0 98 14 80    	mov    %cl,-0x7feb6760(%eax)
        consputc(c);
801007a5:	89 f8                	mov    %edi,%eax
801007a7:	e8 3a fd ff ff       	call   801004e6 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801007ac:	83 ff 0a             	cmp    $0xa,%edi
801007af:	0f 94 c2             	sete   %dl
801007b2:	83 ff 04             	cmp    $0x4,%edi
801007b5:	0f 94 c0             	sete   %al
801007b8:	08 c2                	or     %al,%dl
801007ba:	75 10                	jne    801007cc <consoleintr+0x8e>
801007bc:	a1 20 99 14 80       	mov    0x80149920,%eax
801007c1:	83 e8 80             	sub    $0xffffff80,%eax
801007c4:	39 05 28 99 14 80    	cmp    %eax,0x80149928
801007ca:	75 5a                	jne    80100826 <consoleintr+0xe8>
          input.w = input.e;
801007cc:	a1 28 99 14 80       	mov    0x80149928,%eax
801007d1:	a3 24 99 14 80       	mov    %eax,0x80149924
          wakeup(&input.r);
801007d6:	83 ec 0c             	sub    $0xc,%esp
801007d9:	68 20 99 14 80       	push   $0x80149920
801007de:	e8 72 30 00 00       	call   80103855 <wakeup>
801007e3:	83 c4 10             	add    $0x10,%esp
801007e6:	eb 3e                	jmp    80100826 <consoleintr+0xe8>
        input.e--;
801007e8:	a3 28 99 14 80       	mov    %eax,0x80149928
        consputc(BACKSPACE);
801007ed:	b8 00 01 00 00       	mov    $0x100,%eax
801007f2:	e8 ef fc ff ff       	call   801004e6 <consputc>
      while(input.e != input.w &&
801007f7:	a1 28 99 14 80       	mov    0x80149928,%eax
801007fc:	3b 05 24 99 14 80    	cmp    0x80149924,%eax
80100802:	74 22                	je     80100826 <consoleintr+0xe8>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100804:	83 e8 01             	sub    $0x1,%eax
80100807:	89 c2                	mov    %eax,%edx
80100809:	83 e2 7f             	and    $0x7f,%edx
      while(input.e != input.w &&
8010080c:	80 ba a0 98 14 80 0a 	cmpb   $0xa,-0x7feb6760(%edx)
80100813:	75 d3                	jne    801007e8 <consoleintr+0xaa>
80100815:	eb 0f                	jmp    80100826 <consoleintr+0xe8>
        c = (c == '\r') ? '\n' : c;
80100817:	bf 0a 00 00 00       	mov    $0xa,%edi
8010081c:	e9 70 ff ff ff       	jmp    80100791 <consoleintr+0x53>
      doprocdump = 1;
80100821:	be 01 00 00 00       	mov    $0x1,%esi
  while((c = getc()) >= 0){
80100826:	ff d3                	call   *%ebx
80100828:	89 c7                	mov    %eax,%edi
8010082a:	85 c0                	test   %eax,%eax
8010082c:	78 3d                	js     8010086b <consoleintr+0x12d>
    switch(c){
8010082e:	83 ff 10             	cmp    $0x10,%edi
80100831:	74 ee                	je     80100821 <consoleintr+0xe3>
80100833:	83 ff 10             	cmp    $0x10,%edi
80100836:	0f 8e 25 ff ff ff    	jle    80100761 <consoleintr+0x23>
8010083c:	83 ff 15             	cmp    $0x15,%edi
8010083f:	74 b6                	je     801007f7 <consoleintr+0xb9>
80100841:	83 ff 7f             	cmp    $0x7f,%edi
80100844:	0f 85 20 ff ff ff    	jne    8010076a <consoleintr+0x2c>
      if(input.e != input.w){
8010084a:	a1 28 99 14 80       	mov    0x80149928,%eax
8010084f:	3b 05 24 99 14 80    	cmp    0x80149924,%eax
80100855:	74 cf                	je     80100826 <consoleintr+0xe8>
        input.e--;
80100857:	83 e8 01             	sub    $0x1,%eax
8010085a:	a3 28 99 14 80       	mov    %eax,0x80149928
        consputc(BACKSPACE);
8010085f:	b8 00 01 00 00       	mov    $0x100,%eax
80100864:	e8 7d fc ff ff       	call   801004e6 <consputc>
80100869:	eb bb                	jmp    80100826 <consoleintr+0xe8>
  release(&cons.lock);
8010086b:	83 ec 0c             	sub    $0xc,%esp
8010086e:	68 20 95 10 80       	push   $0x80109520
80100873:	e8 70 34 00 00       	call   80103ce8 <release>
  if(doprocdump) {
80100878:	83 c4 10             	add    $0x10,%esp
8010087b:	85 f6                	test   %esi,%esi
8010087d:	75 08                	jne    80100887 <consoleintr+0x149>
}
8010087f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100882:	5b                   	pop    %ebx
80100883:	5e                   	pop    %esi
80100884:	5f                   	pop    %edi
80100885:	5d                   	pop    %ebp
80100886:	c3                   	ret    
    procdump();  // now call procdump() wo. cons.lock held
80100887:	e8 fe 30 00 00       	call   8010398a <procdump>
}
8010088c:	eb f1                	jmp    8010087f <consoleintr+0x141>

8010088e <consoleinit>:

void
consoleinit(void)
{
8010088e:	55                   	push   %ebp
8010088f:	89 e5                	mov    %esp,%ebp
80100891:	83 ec 10             	sub    $0x10,%esp
  initlock(&cons.lock, "console");
80100894:	68 e8 65 10 80       	push   $0x801065e8
80100899:	68 20 95 10 80       	push   $0x80109520
8010089e:	e8 a4 32 00 00       	call   80103b47 <initlock>

  devsw[CONSOLE].write = consolewrite;
801008a3:	c7 05 ec a2 16 80 ac 	movl   $0x801005ac,0x8016a2ec
801008aa:	05 10 80 
  devsw[CONSOLE].read = consoleread;
801008ad:	c7 05 e8 a2 16 80 68 	movl   $0x80100268,0x8016a2e8
801008b4:	02 10 80 
  cons.locking = 1;
801008b7:	c7 05 54 95 10 80 01 	movl   $0x1,0x80109554
801008be:	00 00 00 

  ioapicenable(IRQ_KBD, 0);
801008c1:	83 c4 08             	add    $0x8,%esp
801008c4:	6a 00                	push   $0x0
801008c6:	6a 01                	push   $0x1
801008c8:	e8 b1 16 00 00       	call   80101f7e <ioapicenable>
}
801008cd:	83 c4 10             	add    $0x10,%esp
801008d0:	c9                   	leave  
801008d1:	c3                   	ret    

801008d2 <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
801008d2:	55                   	push   %ebp
801008d3:	89 e5                	mov    %esp,%ebp
801008d5:	57                   	push   %edi
801008d6:	56                   	push   %esi
801008d7:	53                   	push   %ebx
801008d8:	81 ec 0c 01 00 00    	sub    $0x10c,%esp
  uint argc, sz, sp, ustack[3+MAXARG+1];
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;
  struct proc *curproc = myproc();
801008de:	e8 4d 29 00 00       	call   80103230 <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 fa 1e 00 00       	call   801027e8 <begin_op>

  if((ip = namei(path)) == 0){
801008ee:	83 ec 0c             	sub    $0xc,%esp
801008f1:	ff 75 08             	pushl  0x8(%ebp)
801008f4:	e8 e8 12 00 00       	call   80101be1 <namei>
801008f9:	83 c4 10             	add    $0x10,%esp
801008fc:	85 c0                	test   %eax,%eax
801008fe:	74 4a                	je     8010094a <exec+0x78>
80100900:	89 c3                	mov    %eax,%ebx
    end_op();
    cprintf("exec: fail\n");
    return -1;
  }
  ilock(ip);
80100902:	83 ec 0c             	sub    $0xc,%esp
80100905:	50                   	push   %eax
80100906:	e8 76 0c 00 00       	call   80101581 <ilock>
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) != sizeof(elf))
8010090b:	6a 34                	push   $0x34
8010090d:	6a 00                	push   $0x0
8010090f:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
80100915:	50                   	push   %eax
80100916:	53                   	push   %ebx
80100917:	e8 57 0e 00 00       	call   80101773 <readi>
8010091c:	83 c4 20             	add    $0x20,%esp
8010091f:	83 f8 34             	cmp    $0x34,%eax
80100922:	74 42                	je     80100966 <exec+0x94>
  return 0;

 bad:
  if(pgdir)
    freevm(pgdir);
  if(ip){
80100924:	85 db                	test   %ebx,%ebx
80100926:	0f 84 dd 02 00 00    	je     80100c09 <exec+0x337>
    iunlockput(ip);
8010092c:	83 ec 0c             	sub    $0xc,%esp
8010092f:	53                   	push   %ebx
80100930:	e8 f3 0d 00 00       	call   80101728 <iunlockput>
    end_op();
80100935:	e8 28 1f 00 00       	call   80102862 <end_op>
8010093a:	83 c4 10             	add    $0x10,%esp
  }
  return -1;
8010093d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100942:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100945:	5b                   	pop    %ebx
80100946:	5e                   	pop    %esi
80100947:	5f                   	pop    %edi
80100948:	5d                   	pop    %ebp
80100949:	c3                   	ret    
    end_op();
8010094a:	e8 13 1f 00 00       	call   80102862 <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 01 66 10 80       	push   $0x80106601
80100957:	e8 af fc ff ff       	call   8010060b <cprintf>
    return -1;
8010095c:	83 c4 10             	add    $0x10,%esp
8010095f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100964:	eb dc                	jmp    80100942 <exec+0x70>
  if(elf.magic != ELF_MAGIC)
80100966:	81 bd 24 ff ff ff 7f 	cmpl   $0x464c457f,-0xdc(%ebp)
8010096d:	45 4c 46 
80100970:	75 b2                	jne    80100924 <exec+0x52>
  if((pgdir = setupkvm()) == 0)
80100972:	e8 b2 59 00 00       	call   80106329 <setupkvm>
80100977:	89 85 ec fe ff ff    	mov    %eax,-0x114(%ebp)
8010097d:	85 c0                	test   %eax,%eax
8010097f:	0f 84 06 01 00 00    	je     80100a8b <exec+0x1b9>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100985:	8b 85 40 ff ff ff    	mov    -0xc0(%ebp),%eax
  sz = 0;
8010098b:	bf 00 00 00 00       	mov    $0x0,%edi
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100990:	be 00 00 00 00       	mov    $0x0,%esi
80100995:	eb 0c                	jmp    801009a3 <exec+0xd1>
80100997:	83 c6 01             	add    $0x1,%esi
8010099a:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
801009a0:	83 c0 20             	add    $0x20,%eax
801009a3:	0f b7 95 50 ff ff ff 	movzwl -0xb0(%ebp),%edx
801009aa:	39 f2                	cmp    %esi,%edx
801009ac:	0f 8e 98 00 00 00    	jle    80100a4a <exec+0x178>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
801009b2:	89 85 f0 fe ff ff    	mov    %eax,-0x110(%ebp)
801009b8:	6a 20                	push   $0x20
801009ba:	50                   	push   %eax
801009bb:	8d 85 04 ff ff ff    	lea    -0xfc(%ebp),%eax
801009c1:	50                   	push   %eax
801009c2:	53                   	push   %ebx
801009c3:	e8 ab 0d 00 00       	call   80101773 <readi>
801009c8:	83 c4 10             	add    $0x10,%esp
801009cb:	83 f8 20             	cmp    $0x20,%eax
801009ce:	0f 85 b7 00 00 00    	jne    80100a8b <exec+0x1b9>
    if(ph.type != ELF_PROG_LOAD)
801009d4:	83 bd 04 ff ff ff 01 	cmpl   $0x1,-0xfc(%ebp)
801009db:	75 ba                	jne    80100997 <exec+0xc5>
    if(ph.memsz < ph.filesz)
801009dd:	8b 85 18 ff ff ff    	mov    -0xe8(%ebp),%eax
801009e3:	3b 85 14 ff ff ff    	cmp    -0xec(%ebp),%eax
801009e9:	0f 82 9c 00 00 00    	jb     80100a8b <exec+0x1b9>
    if(ph.vaddr + ph.memsz < ph.vaddr)
801009ef:	03 85 0c ff ff ff    	add    -0xf4(%ebp),%eax
801009f5:	0f 82 90 00 00 00    	jb     80100a8b <exec+0x1b9>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
801009fb:	83 ec 04             	sub    $0x4,%esp
801009fe:	50                   	push   %eax
801009ff:	57                   	push   %edi
80100a00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a06:	e8 c4 57 00 00       	call   801061cf <allocuvm>
80100a0b:	89 c7                	mov    %eax,%edi
80100a0d:	83 c4 10             	add    $0x10,%esp
80100a10:	85 c0                	test   %eax,%eax
80100a12:	74 77                	je     80100a8b <exec+0x1b9>
    if(ph.vaddr % PGSIZE != 0)
80100a14:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100a1a:	a9 ff 0f 00 00       	test   $0xfff,%eax
80100a1f:	75 6a                	jne    80100a8b <exec+0x1b9>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100a21:	83 ec 0c             	sub    $0xc,%esp
80100a24:	ff b5 14 ff ff ff    	pushl  -0xec(%ebp)
80100a2a:	ff b5 08 ff ff ff    	pushl  -0xf8(%ebp)
80100a30:	53                   	push   %ebx
80100a31:	50                   	push   %eax
80100a32:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a38:	e8 60 56 00 00       	call   8010609d <loaduvm>
80100a3d:	83 c4 20             	add    $0x20,%esp
80100a40:	85 c0                	test   %eax,%eax
80100a42:	0f 89 4f ff ff ff    	jns    80100997 <exec+0xc5>
 bad:
80100a48:	eb 41                	jmp    80100a8b <exec+0x1b9>
  iunlockput(ip);
80100a4a:	83 ec 0c             	sub    $0xc,%esp
80100a4d:	53                   	push   %ebx
80100a4e:	e8 d5 0c 00 00       	call   80101728 <iunlockput>
  end_op();
80100a53:	e8 0a 1e 00 00       	call   80102862 <end_op>
  sz = PGROUNDUP(sz);
80100a58:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100a63:	83 c4 0c             	add    $0xc,%esp
80100a66:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a6c:	52                   	push   %edx
80100a6d:	50                   	push   %eax
80100a6e:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a74:	e8 56 57 00 00       	call   801061cf <allocuvm>
80100a79:	89 85 f0 fe ff ff    	mov    %eax,-0x110(%ebp)
80100a7f:	83 c4 10             	add    $0x10,%esp
80100a82:	85 c0                	test   %eax,%eax
80100a84:	75 24                	jne    80100aaa <exec+0x1d8>
  ip = 0;
80100a86:	bb 00 00 00 00       	mov    $0x0,%ebx
  if(pgdir)
80100a8b:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100a91:	85 c0                	test   %eax,%eax
80100a93:	0f 84 8b fe ff ff    	je     80100924 <exec+0x52>
    freevm(pgdir);
80100a99:	83 ec 0c             	sub    $0xc,%esp
80100a9c:	50                   	push   %eax
80100a9d:	e8 17 58 00 00       	call   801062b9 <freevm>
80100aa2:	83 c4 10             	add    $0x10,%esp
80100aa5:	e9 7a fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aaa:	89 c7                	mov    %eax,%edi
80100aac:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100ab2:	83 ec 08             	sub    $0x8,%esp
80100ab5:	50                   	push   %eax
80100ab6:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100abc:	e8 ed 58 00 00       	call   801063ae <clearpteu>
  for(argc = 0; argv[argc]; argc++) {
80100ac1:	83 c4 10             	add    $0x10,%esp
80100ac4:	bb 00 00 00 00       	mov    $0x0,%ebx
80100ac9:	8b 45 0c             	mov    0xc(%ebp),%eax
80100acc:	8d 34 98             	lea    (%eax,%ebx,4),%esi
80100acf:	8b 06                	mov    (%esi),%eax
80100ad1:	85 c0                	test   %eax,%eax
80100ad3:	74 4d                	je     80100b22 <exec+0x250>
    if(argc >= MAXARG)
80100ad5:	83 fb 1f             	cmp    $0x1f,%ebx
80100ad8:	0f 87 0d 01 00 00    	ja     80100beb <exec+0x319>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100ade:	83 ec 0c             	sub    $0xc,%esp
80100ae1:	50                   	push   %eax
80100ae2:	e8 ea 33 00 00       	call   80103ed1 <strlen>
80100ae7:	29 c7                	sub    %eax,%edi
80100ae9:	83 ef 01             	sub    $0x1,%edi
80100aec:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100aef:	83 c4 04             	add    $0x4,%esp
80100af2:	ff 36                	pushl  (%esi)
80100af4:	e8 d8 33 00 00       	call   80103ed1 <strlen>
80100af9:	83 c0 01             	add    $0x1,%eax
80100afc:	50                   	push   %eax
80100afd:	ff 36                	pushl  (%esi)
80100aff:	57                   	push   %edi
80100b00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b06:	e8 f1 59 00 00       	call   801064fc <copyout>
80100b0b:	83 c4 20             	add    $0x20,%esp
80100b0e:	85 c0                	test   %eax,%eax
80100b10:	0f 88 df 00 00 00    	js     80100bf5 <exec+0x323>
    ustack[3+argc] = sp;
80100b16:	89 bc 9d 64 ff ff ff 	mov    %edi,-0x9c(%ebp,%ebx,4)
  for(argc = 0; argv[argc]; argc++) {
80100b1d:	83 c3 01             	add    $0x1,%ebx
80100b20:	eb a7                	jmp    80100ac9 <exec+0x1f7>
  ustack[3+argc] = 0;
80100b22:	c7 84 9d 64 ff ff ff 	movl   $0x0,-0x9c(%ebp,%ebx,4)
80100b29:	00 00 00 00 
  ustack[0] = 0xffffffff;  // fake return PC
80100b2d:	c7 85 58 ff ff ff ff 	movl   $0xffffffff,-0xa8(%ebp)
80100b34:	ff ff ff 
  ustack[1] = argc;
80100b37:	89 9d 5c ff ff ff    	mov    %ebx,-0xa4(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100b3d:	8d 04 9d 04 00 00 00 	lea    0x4(,%ebx,4),%eax
80100b44:	89 f9                	mov    %edi,%ecx
80100b46:	29 c1                	sub    %eax,%ecx
80100b48:	89 8d 60 ff ff ff    	mov    %ecx,-0xa0(%ebp)
  sp -= (3+argc+1) * 4;
80100b4e:	8d 04 9d 10 00 00 00 	lea    0x10(,%ebx,4),%eax
80100b55:	29 c7                	sub    %eax,%edi
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100b57:	50                   	push   %eax
80100b58:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
80100b5e:	50                   	push   %eax
80100b5f:	57                   	push   %edi
80100b60:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b66:	e8 91 59 00 00       	call   801064fc <copyout>
80100b6b:	83 c4 10             	add    $0x10,%esp
80100b6e:	85 c0                	test   %eax,%eax
80100b70:	0f 88 89 00 00 00    	js     80100bff <exec+0x32d>
  for(last=s=path; *s; s++)
80100b76:	8b 55 08             	mov    0x8(%ebp),%edx
80100b79:	89 d0                	mov    %edx,%eax
80100b7b:	eb 03                	jmp    80100b80 <exec+0x2ae>
80100b7d:	83 c0 01             	add    $0x1,%eax
80100b80:	0f b6 08             	movzbl (%eax),%ecx
80100b83:	84 c9                	test   %cl,%cl
80100b85:	74 0a                	je     80100b91 <exec+0x2bf>
    if(*s == '/')
80100b87:	80 f9 2f             	cmp    $0x2f,%cl
80100b8a:	75 f1                	jne    80100b7d <exec+0x2ab>
      last = s+1;
80100b8c:	8d 50 01             	lea    0x1(%eax),%edx
80100b8f:	eb ec                	jmp    80100b7d <exec+0x2ab>
  safestrcpy(curproc->name, last, sizeof(curproc->name));
80100b91:	8b b5 f4 fe ff ff    	mov    -0x10c(%ebp),%esi
80100b97:	89 f0                	mov    %esi,%eax
80100b99:	83 c0 6c             	add    $0x6c,%eax
80100b9c:	83 ec 04             	sub    $0x4,%esp
80100b9f:	6a 10                	push   $0x10
80100ba1:	52                   	push   %edx
80100ba2:	50                   	push   %eax
80100ba3:	e8 ee 32 00 00       	call   80103e96 <safestrcpy>
  oldpgdir = curproc->pgdir;
80100ba8:	8b 5e 04             	mov    0x4(%esi),%ebx
  curproc->pgdir = pgdir;
80100bab:	8b 8d ec fe ff ff    	mov    -0x114(%ebp),%ecx
80100bb1:	89 4e 04             	mov    %ecx,0x4(%esi)
  curproc->sz = sz;
80100bb4:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
80100bba:	89 0e                	mov    %ecx,(%esi)
  curproc->tf->eip = elf.entry;  // main
80100bbc:	8b 46 18             	mov    0x18(%esi),%eax
80100bbf:	8b 95 3c ff ff ff    	mov    -0xc4(%ebp),%edx
80100bc5:	89 50 38             	mov    %edx,0x38(%eax)
  curproc->tf->esp = sp;
80100bc8:	8b 46 18             	mov    0x18(%esi),%eax
80100bcb:	89 78 44             	mov    %edi,0x44(%eax)
  switchuvm(curproc);
80100bce:	89 34 24             	mov    %esi,(%esp)
80100bd1:	e8 46 53 00 00       	call   80105f1c <switchuvm>
  freevm(oldpgdir);
80100bd6:	89 1c 24             	mov    %ebx,(%esp)
80100bd9:	e8 db 56 00 00       	call   801062b9 <freevm>
  return 0;
80100bde:	83 c4 10             	add    $0x10,%esp
80100be1:	b8 00 00 00 00       	mov    $0x0,%eax
80100be6:	e9 57 fd ff ff       	jmp    80100942 <exec+0x70>
  ip = 0;
80100beb:	bb 00 00 00 00       	mov    $0x0,%ebx
80100bf0:	e9 96 fe ff ff       	jmp    80100a8b <exec+0x1b9>
80100bf5:	bb 00 00 00 00       	mov    $0x0,%ebx
80100bfa:	e9 8c fe ff ff       	jmp    80100a8b <exec+0x1b9>
80100bff:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c04:	e9 82 fe ff ff       	jmp    80100a8b <exec+0x1b9>
  return -1;
80100c09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100c0e:	e9 2f fd ff ff       	jmp    80100942 <exec+0x70>

80100c13 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100c13:	55                   	push   %ebp
80100c14:	89 e5                	mov    %esp,%ebp
80100c16:	83 ec 10             	sub    $0x10,%esp
  initlock(&ftable.lock, "ftable");
80100c19:	68 0d 66 10 80       	push   $0x8010660d
80100c1e:	68 40 99 16 80       	push   $0x80169940
80100c23:	e8 1f 2f 00 00       	call   80103b47 <initlock>
}
80100c28:	83 c4 10             	add    $0x10,%esp
80100c2b:	c9                   	leave  
80100c2c:	c3                   	ret    

80100c2d <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100c2d:	55                   	push   %ebp
80100c2e:	89 e5                	mov    %esp,%ebp
80100c30:	53                   	push   %ebx
80100c31:	83 ec 10             	sub    $0x10,%esp
  struct file *f;

  acquire(&ftable.lock);
80100c34:	68 40 99 16 80       	push   $0x80169940
80100c39:	e8 45 30 00 00       	call   80103c83 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c3e:	83 c4 10             	add    $0x10,%esp
80100c41:	bb 74 99 16 80       	mov    $0x80169974,%ebx
80100c46:	81 fb d4 a2 16 80    	cmp    $0x8016a2d4,%ebx
80100c4c:	73 29                	jae    80100c77 <filealloc+0x4a>
    if(f->ref == 0){
80100c4e:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80100c52:	74 05                	je     80100c59 <filealloc+0x2c>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c54:	83 c3 18             	add    $0x18,%ebx
80100c57:	eb ed                	jmp    80100c46 <filealloc+0x19>
      f->ref = 1;
80100c59:	c7 43 04 01 00 00 00 	movl   $0x1,0x4(%ebx)
      release(&ftable.lock);
80100c60:	83 ec 0c             	sub    $0xc,%esp
80100c63:	68 40 99 16 80       	push   $0x80169940
80100c68:	e8 7b 30 00 00       	call   80103ce8 <release>
      return f;
80100c6d:	83 c4 10             	add    $0x10,%esp
    }
  }
  release(&ftable.lock);
  return 0;
}
80100c70:	89 d8                	mov    %ebx,%eax
80100c72:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100c75:	c9                   	leave  
80100c76:	c3                   	ret    
  release(&ftable.lock);
80100c77:	83 ec 0c             	sub    $0xc,%esp
80100c7a:	68 40 99 16 80       	push   $0x80169940
80100c7f:	e8 64 30 00 00       	call   80103ce8 <release>
  return 0;
80100c84:	83 c4 10             	add    $0x10,%esp
80100c87:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c8c:	eb e2                	jmp    80100c70 <filealloc+0x43>

80100c8e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100c8e:	55                   	push   %ebp
80100c8f:	89 e5                	mov    %esp,%ebp
80100c91:	53                   	push   %ebx
80100c92:	83 ec 10             	sub    $0x10,%esp
80100c95:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&ftable.lock);
80100c98:	68 40 99 16 80       	push   $0x80169940
80100c9d:	e8 e1 2f 00 00       	call   80103c83 <acquire>
  if(f->ref < 1)
80100ca2:	8b 43 04             	mov    0x4(%ebx),%eax
80100ca5:	83 c4 10             	add    $0x10,%esp
80100ca8:	85 c0                	test   %eax,%eax
80100caa:	7e 1a                	jle    80100cc6 <filedup+0x38>
    panic("filedup");
  f->ref++;
80100cac:	83 c0 01             	add    $0x1,%eax
80100caf:	89 43 04             	mov    %eax,0x4(%ebx)
  release(&ftable.lock);
80100cb2:	83 ec 0c             	sub    $0xc,%esp
80100cb5:	68 40 99 16 80       	push   $0x80169940
80100cba:	e8 29 30 00 00       	call   80103ce8 <release>
  return f;
}
80100cbf:	89 d8                	mov    %ebx,%eax
80100cc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cc4:	c9                   	leave  
80100cc5:	c3                   	ret    
    panic("filedup");
80100cc6:	83 ec 0c             	sub    $0xc,%esp
80100cc9:	68 14 66 10 80       	push   $0x80106614
80100cce:	e8 75 f6 ff ff       	call   80100348 <panic>

80100cd3 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100cd3:	55                   	push   %ebp
80100cd4:	89 e5                	mov    %esp,%ebp
80100cd6:	53                   	push   %ebx
80100cd7:	83 ec 30             	sub    $0x30,%esp
80100cda:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct file ff;

  acquire(&ftable.lock);
80100cdd:	68 40 99 16 80       	push   $0x80169940
80100ce2:	e8 9c 2f 00 00       	call   80103c83 <acquire>
  if(f->ref < 1)
80100ce7:	8b 43 04             	mov    0x4(%ebx),%eax
80100cea:	83 c4 10             	add    $0x10,%esp
80100ced:	85 c0                	test   %eax,%eax
80100cef:	7e 1f                	jle    80100d10 <fileclose+0x3d>
    panic("fileclose");
  if(--f->ref > 0){
80100cf1:	83 e8 01             	sub    $0x1,%eax
80100cf4:	89 43 04             	mov    %eax,0x4(%ebx)
80100cf7:	85 c0                	test   %eax,%eax
80100cf9:	7e 22                	jle    80100d1d <fileclose+0x4a>
    release(&ftable.lock);
80100cfb:	83 ec 0c             	sub    $0xc,%esp
80100cfe:	68 40 99 16 80       	push   $0x80169940
80100d03:	e8 e0 2f 00 00       	call   80103ce8 <release>
    return;
80100d08:	83 c4 10             	add    $0x10,%esp
  else if(ff.type == FD_INODE){
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
80100d0b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100d0e:	c9                   	leave  
80100d0f:	c3                   	ret    
    panic("fileclose");
80100d10:	83 ec 0c             	sub    $0xc,%esp
80100d13:	68 1c 66 10 80       	push   $0x8010661c
80100d18:	e8 2b f6 ff ff       	call   80100348 <panic>
  ff = *f;
80100d1d:	8b 03                	mov    (%ebx),%eax
80100d1f:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100d22:	8b 43 08             	mov    0x8(%ebx),%eax
80100d25:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100d28:	8b 43 0c             	mov    0xc(%ebx),%eax
80100d2b:	89 45 ec             	mov    %eax,-0x14(%ebp)
80100d2e:	8b 43 10             	mov    0x10(%ebx),%eax
80100d31:	89 45 f0             	mov    %eax,-0x10(%ebp)
  f->ref = 0;
80100d34:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
  f->type = FD_NONE;
80100d3b:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  release(&ftable.lock);
80100d41:	83 ec 0c             	sub    $0xc,%esp
80100d44:	68 40 99 16 80       	push   $0x80169940
80100d49:	e8 9a 2f 00 00       	call   80103ce8 <release>
  if(ff.type == FD_PIPE)
80100d4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d51:	83 c4 10             	add    $0x10,%esp
80100d54:	83 f8 01             	cmp    $0x1,%eax
80100d57:	74 1f                	je     80100d78 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d59:	83 f8 02             	cmp    $0x2,%eax
80100d5c:	75 ad                	jne    80100d0b <fileclose+0x38>
    begin_op();
80100d5e:	e8 85 1a 00 00       	call   801027e8 <begin_op>
    iput(ff.ip);
80100d63:	83 ec 0c             	sub    $0xc,%esp
80100d66:	ff 75 f0             	pushl  -0x10(%ebp)
80100d69:	e8 1a 09 00 00       	call   80101688 <iput>
    end_op();
80100d6e:	e8 ef 1a 00 00       	call   80102862 <end_op>
80100d73:	83 c4 10             	add    $0x10,%esp
80100d76:	eb 93                	jmp    80100d0b <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d78:	83 ec 08             	sub    $0x8,%esp
80100d7b:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d7f:	50                   	push   %eax
80100d80:	ff 75 ec             	pushl  -0x14(%ebp)
80100d83:	e8 d4 20 00 00       	call   80102e5c <pipeclose>
80100d88:	83 c4 10             	add    $0x10,%esp
80100d8b:	e9 7b ff ff ff       	jmp    80100d0b <fileclose+0x38>

80100d90 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
80100d90:	55                   	push   %ebp
80100d91:	89 e5                	mov    %esp,%ebp
80100d93:	53                   	push   %ebx
80100d94:	83 ec 04             	sub    $0x4,%esp
80100d97:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(f->type == FD_INODE){
80100d9a:	83 3b 02             	cmpl   $0x2,(%ebx)
80100d9d:	75 31                	jne    80100dd0 <filestat+0x40>
    ilock(f->ip);
80100d9f:	83 ec 0c             	sub    $0xc,%esp
80100da2:	ff 73 10             	pushl  0x10(%ebx)
80100da5:	e8 d7 07 00 00       	call   80101581 <ilock>
    stati(f->ip, st);
80100daa:	83 c4 08             	add    $0x8,%esp
80100dad:	ff 75 0c             	pushl  0xc(%ebp)
80100db0:	ff 73 10             	pushl  0x10(%ebx)
80100db3:	e8 90 09 00 00       	call   80101748 <stati>
    iunlock(f->ip);
80100db8:	83 c4 04             	add    $0x4,%esp
80100dbb:	ff 73 10             	pushl  0x10(%ebx)
80100dbe:	e8 80 08 00 00       	call   80101643 <iunlock>
    return 0;
80100dc3:	83 c4 10             	add    $0x10,%esp
80100dc6:	b8 00 00 00 00       	mov    $0x0,%eax
  }
  return -1;
}
80100dcb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100dce:	c9                   	leave  
80100dcf:	c3                   	ret    
  return -1;
80100dd0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100dd5:	eb f4                	jmp    80100dcb <filestat+0x3b>

80100dd7 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
80100dd7:	55                   	push   %ebp
80100dd8:	89 e5                	mov    %esp,%ebp
80100dda:	56                   	push   %esi
80100ddb:	53                   	push   %ebx
80100ddc:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;

  if(f->readable == 0)
80100ddf:	80 7b 08 00          	cmpb   $0x0,0x8(%ebx)
80100de3:	74 70                	je     80100e55 <fileread+0x7e>
    return -1;
  if(f->type == FD_PIPE)
80100de5:	8b 03                	mov    (%ebx),%eax
80100de7:	83 f8 01             	cmp    $0x1,%eax
80100dea:	74 44                	je     80100e30 <fileread+0x59>
    return piperead(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100dec:	83 f8 02             	cmp    $0x2,%eax
80100def:	75 57                	jne    80100e48 <fileread+0x71>
    ilock(f->ip);
80100df1:	83 ec 0c             	sub    $0xc,%esp
80100df4:	ff 73 10             	pushl  0x10(%ebx)
80100df7:	e8 85 07 00 00       	call   80101581 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
80100dfc:	ff 75 10             	pushl  0x10(%ebp)
80100dff:	ff 73 14             	pushl  0x14(%ebx)
80100e02:	ff 75 0c             	pushl  0xc(%ebp)
80100e05:	ff 73 10             	pushl  0x10(%ebx)
80100e08:	e8 66 09 00 00       	call   80101773 <readi>
80100e0d:	89 c6                	mov    %eax,%esi
80100e0f:	83 c4 20             	add    $0x20,%esp
80100e12:	85 c0                	test   %eax,%eax
80100e14:	7e 03                	jle    80100e19 <fileread+0x42>
      f->off += r;
80100e16:	01 43 14             	add    %eax,0x14(%ebx)
    iunlock(f->ip);
80100e19:	83 ec 0c             	sub    $0xc,%esp
80100e1c:	ff 73 10             	pushl  0x10(%ebx)
80100e1f:	e8 1f 08 00 00       	call   80101643 <iunlock>
    return r;
80100e24:	83 c4 10             	add    $0x10,%esp
  }
  panic("fileread");
}
80100e27:	89 f0                	mov    %esi,%eax
80100e29:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100e2c:	5b                   	pop    %ebx
80100e2d:	5e                   	pop    %esi
80100e2e:	5d                   	pop    %ebp
80100e2f:	c3                   	ret    
    return piperead(f->pipe, addr, n);
80100e30:	83 ec 04             	sub    $0x4,%esp
80100e33:	ff 75 10             	pushl  0x10(%ebp)
80100e36:	ff 75 0c             	pushl  0xc(%ebp)
80100e39:	ff 73 0c             	pushl  0xc(%ebx)
80100e3c:	e8 73 21 00 00       	call   80102fb4 <piperead>
80100e41:	89 c6                	mov    %eax,%esi
80100e43:	83 c4 10             	add    $0x10,%esp
80100e46:	eb df                	jmp    80100e27 <fileread+0x50>
  panic("fileread");
80100e48:	83 ec 0c             	sub    $0xc,%esp
80100e4b:	68 26 66 10 80       	push   $0x80106626
80100e50:	e8 f3 f4 ff ff       	call   80100348 <panic>
    return -1;
80100e55:	be ff ff ff ff       	mov    $0xffffffff,%esi
80100e5a:	eb cb                	jmp    80100e27 <fileread+0x50>

80100e5c <filewrite>:

// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
80100e5c:	55                   	push   %ebp
80100e5d:	89 e5                	mov    %esp,%ebp
80100e5f:	57                   	push   %edi
80100e60:	56                   	push   %esi
80100e61:	53                   	push   %ebx
80100e62:	83 ec 1c             	sub    $0x1c,%esp
80100e65:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;

  if(f->writable == 0)
80100e68:	80 7b 09 00          	cmpb   $0x0,0x9(%ebx)
80100e6c:	0f 84 c5 00 00 00    	je     80100f37 <filewrite+0xdb>
    return -1;
  if(f->type == FD_PIPE)
80100e72:	8b 03                	mov    (%ebx),%eax
80100e74:	83 f8 01             	cmp    $0x1,%eax
80100e77:	74 10                	je     80100e89 <filewrite+0x2d>
    return pipewrite(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100e79:	83 f8 02             	cmp    $0x2,%eax
80100e7c:	0f 85 a8 00 00 00    	jne    80100f2a <filewrite+0xce>
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * 512;
    int i = 0;
80100e82:	bf 00 00 00 00       	mov    $0x0,%edi
80100e87:	eb 67                	jmp    80100ef0 <filewrite+0x94>
    return pipewrite(f->pipe, addr, n);
80100e89:	83 ec 04             	sub    $0x4,%esp
80100e8c:	ff 75 10             	pushl  0x10(%ebp)
80100e8f:	ff 75 0c             	pushl  0xc(%ebp)
80100e92:	ff 73 0c             	pushl  0xc(%ebx)
80100e95:	e8 4e 20 00 00       	call   80102ee8 <pipewrite>
80100e9a:	83 c4 10             	add    $0x10,%esp
80100e9d:	e9 80 00 00 00       	jmp    80100f22 <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100ea2:	e8 41 19 00 00       	call   801027e8 <begin_op>
      ilock(f->ip);
80100ea7:	83 ec 0c             	sub    $0xc,%esp
80100eaa:	ff 73 10             	pushl  0x10(%ebx)
80100ead:	e8 cf 06 00 00       	call   80101581 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80100eb2:	89 f8                	mov    %edi,%eax
80100eb4:	03 45 0c             	add    0xc(%ebp),%eax
80100eb7:	ff 75 e4             	pushl  -0x1c(%ebp)
80100eba:	ff 73 14             	pushl  0x14(%ebx)
80100ebd:	50                   	push   %eax
80100ebe:	ff 73 10             	pushl  0x10(%ebx)
80100ec1:	e8 aa 09 00 00       	call   80101870 <writei>
80100ec6:	89 c6                	mov    %eax,%esi
80100ec8:	83 c4 20             	add    $0x20,%esp
80100ecb:	85 c0                	test   %eax,%eax
80100ecd:	7e 03                	jle    80100ed2 <filewrite+0x76>
        f->off += r;
80100ecf:	01 43 14             	add    %eax,0x14(%ebx)
      iunlock(f->ip);
80100ed2:	83 ec 0c             	sub    $0xc,%esp
80100ed5:	ff 73 10             	pushl  0x10(%ebx)
80100ed8:	e8 66 07 00 00       	call   80101643 <iunlock>
      end_op();
80100edd:	e8 80 19 00 00       	call   80102862 <end_op>

      if(r < 0)
80100ee2:	83 c4 10             	add    $0x10,%esp
80100ee5:	85 f6                	test   %esi,%esi
80100ee7:	78 31                	js     80100f1a <filewrite+0xbe>
        break;
      if(r != n1)
80100ee9:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
80100eec:	75 1f                	jne    80100f0d <filewrite+0xb1>
        panic("short filewrite");
      i += r;
80100eee:	01 f7                	add    %esi,%edi
    while(i < n){
80100ef0:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100ef3:	7d 25                	jge    80100f1a <filewrite+0xbe>
      int n1 = n - i;
80100ef5:	8b 45 10             	mov    0x10(%ebp),%eax
80100ef8:	29 f8                	sub    %edi,%eax
80100efa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      if(n1 > max)
80100efd:	3d 00 06 00 00       	cmp    $0x600,%eax
80100f02:	7e 9e                	jle    80100ea2 <filewrite+0x46>
        n1 = max;
80100f04:	c7 45 e4 00 06 00 00 	movl   $0x600,-0x1c(%ebp)
80100f0b:	eb 95                	jmp    80100ea2 <filewrite+0x46>
        panic("short filewrite");
80100f0d:	83 ec 0c             	sub    $0xc,%esp
80100f10:	68 2f 66 10 80       	push   $0x8010662f
80100f15:	e8 2e f4 ff ff       	call   80100348 <panic>
    }
    return i == n ? n : -1;
80100f1a:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100f1d:	75 1f                	jne    80100f3e <filewrite+0xe2>
80100f1f:	8b 45 10             	mov    0x10(%ebp),%eax
  }
  panic("filewrite");
}
80100f22:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100f25:	5b                   	pop    %ebx
80100f26:	5e                   	pop    %esi
80100f27:	5f                   	pop    %edi
80100f28:	5d                   	pop    %ebp
80100f29:	c3                   	ret    
  panic("filewrite");
80100f2a:	83 ec 0c             	sub    $0xc,%esp
80100f2d:	68 35 66 10 80       	push   $0x80106635
80100f32:	e8 11 f4 ff ff       	call   80100348 <panic>
    return -1;
80100f37:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100f3c:	eb e4                	jmp    80100f22 <filewrite+0xc6>
    return i == n ? n : -1;
80100f3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100f43:	eb dd                	jmp    80100f22 <filewrite+0xc6>

80100f45 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80100f45:	55                   	push   %ebp
80100f46:	89 e5                	mov    %esp,%ebp
80100f48:	57                   	push   %edi
80100f49:	56                   	push   %esi
80100f4a:	53                   	push   %ebx
80100f4b:	83 ec 0c             	sub    $0xc,%esp
80100f4e:	89 d7                	mov    %edx,%edi
  char *s;
  int len;

  while(*path == '/')
80100f50:	eb 03                	jmp    80100f55 <skipelem+0x10>
    path++;
80100f52:	83 c0 01             	add    $0x1,%eax
  while(*path == '/')
80100f55:	0f b6 10             	movzbl (%eax),%edx
80100f58:	80 fa 2f             	cmp    $0x2f,%dl
80100f5b:	74 f5                	je     80100f52 <skipelem+0xd>
  if(*path == 0)
80100f5d:	84 d2                	test   %dl,%dl
80100f5f:	74 59                	je     80100fba <skipelem+0x75>
80100f61:	89 c3                	mov    %eax,%ebx
80100f63:	eb 03                	jmp    80100f68 <skipelem+0x23>
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
    path++;
80100f65:	83 c3 01             	add    $0x1,%ebx
  while(*path != '/' && *path != 0)
80100f68:	0f b6 13             	movzbl (%ebx),%edx
80100f6b:	80 fa 2f             	cmp    $0x2f,%dl
80100f6e:	0f 95 c1             	setne  %cl
80100f71:	84 d2                	test   %dl,%dl
80100f73:	0f 95 c2             	setne  %dl
80100f76:	84 d1                	test   %dl,%cl
80100f78:	75 eb                	jne    80100f65 <skipelem+0x20>
  len = path - s;
80100f7a:	89 de                	mov    %ebx,%esi
80100f7c:	29 c6                	sub    %eax,%esi
  if(len >= DIRSIZ)
80100f7e:	83 fe 0d             	cmp    $0xd,%esi
80100f81:	7e 11                	jle    80100f94 <skipelem+0x4f>
    memmove(name, s, DIRSIZ);
80100f83:	83 ec 04             	sub    $0x4,%esp
80100f86:	6a 0e                	push   $0xe
80100f88:	50                   	push   %eax
80100f89:	57                   	push   %edi
80100f8a:	e8 1b 2e 00 00       	call   80103daa <memmove>
80100f8f:	83 c4 10             	add    $0x10,%esp
80100f92:	eb 17                	jmp    80100fab <skipelem+0x66>
  else {
    memmove(name, s, len);
80100f94:	83 ec 04             	sub    $0x4,%esp
80100f97:	56                   	push   %esi
80100f98:	50                   	push   %eax
80100f99:	57                   	push   %edi
80100f9a:	e8 0b 2e 00 00       	call   80103daa <memmove>
    name[len] = 0;
80100f9f:	c6 04 37 00          	movb   $0x0,(%edi,%esi,1)
80100fa3:	83 c4 10             	add    $0x10,%esp
80100fa6:	eb 03                	jmp    80100fab <skipelem+0x66>
  }
  while(*path == '/')
    path++;
80100fa8:	83 c3 01             	add    $0x1,%ebx
  while(*path == '/')
80100fab:	80 3b 2f             	cmpb   $0x2f,(%ebx)
80100fae:	74 f8                	je     80100fa8 <skipelem+0x63>
  return path;
}
80100fb0:	89 d8                	mov    %ebx,%eax
80100fb2:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100fb5:	5b                   	pop    %ebx
80100fb6:	5e                   	pop    %esi
80100fb7:	5f                   	pop    %edi
80100fb8:	5d                   	pop    %ebp
80100fb9:	c3                   	ret    
    return 0;
80100fba:	bb 00 00 00 00       	mov    $0x0,%ebx
80100fbf:	eb ef                	jmp    80100fb0 <skipelem+0x6b>

80100fc1 <bzero>:
{
80100fc1:	55                   	push   %ebp
80100fc2:	89 e5                	mov    %esp,%ebp
80100fc4:	53                   	push   %ebx
80100fc5:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, bno);
80100fc8:	52                   	push   %edx
80100fc9:	50                   	push   %eax
80100fca:	e8 9d f1 ff ff       	call   8010016c <bread>
80100fcf:	89 c3                	mov    %eax,%ebx
  memset(bp->data, 0, BSIZE);
80100fd1:	8d 40 5c             	lea    0x5c(%eax),%eax
80100fd4:	83 c4 0c             	add    $0xc,%esp
80100fd7:	68 00 02 00 00       	push   $0x200
80100fdc:	6a 00                	push   $0x0
80100fde:	50                   	push   %eax
80100fdf:	e8 4b 2d 00 00       	call   80103d2f <memset>
  log_write(bp);
80100fe4:	89 1c 24             	mov    %ebx,(%esp)
80100fe7:	e8 25 19 00 00       	call   80102911 <log_write>
  brelse(bp);
80100fec:	89 1c 24             	mov    %ebx,(%esp)
80100fef:	e8 e1 f1 ff ff       	call   801001d5 <brelse>
}
80100ff4:	83 c4 10             	add    $0x10,%esp
80100ff7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100ffa:	c9                   	leave  
80100ffb:	c3                   	ret    

80100ffc <balloc>:
{
80100ffc:	55                   	push   %ebp
80100ffd:	89 e5                	mov    %esp,%ebp
80100fff:	57                   	push   %edi
80101000:	56                   	push   %esi
80101001:	53                   	push   %ebx
80101002:	83 ec 1c             	sub    $0x1c,%esp
80101005:	89 45 d8             	mov    %eax,-0x28(%ebp)
  for(b = 0; b < sb.size; b += BPB){
80101008:	be 00 00 00 00       	mov    $0x0,%esi
8010100d:	eb 14                	jmp    80101023 <balloc+0x27>
    brelse(bp);
8010100f:	83 ec 0c             	sub    $0xc,%esp
80101012:	ff 75 e4             	pushl  -0x1c(%ebp)
80101015:	e8 bb f1 ff ff       	call   801001d5 <brelse>
  for(b = 0; b < sb.size; b += BPB){
8010101a:	81 c6 00 10 00 00    	add    $0x1000,%esi
80101020:	83 c4 10             	add    $0x10,%esp
80101023:	39 35 40 a3 16 80    	cmp    %esi,0x8016a340
80101029:	76 75                	jbe    801010a0 <balloc+0xa4>
    bp = bread(dev, BBLOCK(b, sb));
8010102b:	8d 86 ff 0f 00 00    	lea    0xfff(%esi),%eax
80101031:	85 f6                	test   %esi,%esi
80101033:	0f 49 c6             	cmovns %esi,%eax
80101036:	c1 f8 0c             	sar    $0xc,%eax
80101039:	03 05 58 a3 16 80    	add    0x8016a358,%eax
8010103f:	83 ec 08             	sub    $0x8,%esp
80101042:	50                   	push   %eax
80101043:	ff 75 d8             	pushl  -0x28(%ebp)
80101046:	e8 21 f1 ff ff       	call   8010016c <bread>
8010104b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010104e:	83 c4 10             	add    $0x10,%esp
80101051:	b8 00 00 00 00       	mov    $0x0,%eax
80101056:	3d ff 0f 00 00       	cmp    $0xfff,%eax
8010105b:	7f b2                	jg     8010100f <balloc+0x13>
8010105d:	8d 1c 06             	lea    (%esi,%eax,1),%ebx
80101060:	89 5d e0             	mov    %ebx,-0x20(%ebp)
80101063:	3b 1d 40 a3 16 80    	cmp    0x8016a340,%ebx
80101069:	73 a4                	jae    8010100f <balloc+0x13>
      m = 1 << (bi % 8);
8010106b:	99                   	cltd   
8010106c:	c1 ea 1d             	shr    $0x1d,%edx
8010106f:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
80101072:	83 e1 07             	and    $0x7,%ecx
80101075:	29 d1                	sub    %edx,%ecx
80101077:	ba 01 00 00 00       	mov    $0x1,%edx
8010107c:	d3 e2                	shl    %cl,%edx
      if((bp->data[bi/8] & m) == 0){  // Is block free?
8010107e:	8d 48 07             	lea    0x7(%eax),%ecx
80101081:	85 c0                	test   %eax,%eax
80101083:	0f 49 c8             	cmovns %eax,%ecx
80101086:	c1 f9 03             	sar    $0x3,%ecx
80101089:	89 4d dc             	mov    %ecx,-0x24(%ebp)
8010108c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
8010108f:	0f b6 4c 0f 5c       	movzbl 0x5c(%edi,%ecx,1),%ecx
80101094:	0f b6 f9             	movzbl %cl,%edi
80101097:	85 d7                	test   %edx,%edi
80101099:	74 12                	je     801010ad <balloc+0xb1>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010109b:	83 c0 01             	add    $0x1,%eax
8010109e:	eb b6                	jmp    80101056 <balloc+0x5a>
  panic("balloc: out of blocks");
801010a0:	83 ec 0c             	sub    $0xc,%esp
801010a3:	68 3f 66 10 80       	push   $0x8010663f
801010a8:	e8 9b f2 ff ff       	call   80100348 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
801010ad:	09 ca                	or     %ecx,%edx
801010af:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801010b2:	8b 75 dc             	mov    -0x24(%ebp),%esi
801010b5:	88 54 30 5c          	mov    %dl,0x5c(%eax,%esi,1)
        log_write(bp);
801010b9:	83 ec 0c             	sub    $0xc,%esp
801010bc:	89 c6                	mov    %eax,%esi
801010be:	50                   	push   %eax
801010bf:	e8 4d 18 00 00       	call   80102911 <log_write>
        brelse(bp);
801010c4:	89 34 24             	mov    %esi,(%esp)
801010c7:	e8 09 f1 ff ff       	call   801001d5 <brelse>
        bzero(dev, b + bi);
801010cc:	89 da                	mov    %ebx,%edx
801010ce:	8b 45 d8             	mov    -0x28(%ebp),%eax
801010d1:	e8 eb fe ff ff       	call   80100fc1 <bzero>
}
801010d6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801010d9:	8d 65 f4             	lea    -0xc(%ebp),%esp
801010dc:	5b                   	pop    %ebx
801010dd:	5e                   	pop    %esi
801010de:	5f                   	pop    %edi
801010df:	5d                   	pop    %ebp
801010e0:	c3                   	ret    

801010e1 <bmap>:
{
801010e1:	55                   	push   %ebp
801010e2:	89 e5                	mov    %esp,%ebp
801010e4:	57                   	push   %edi
801010e5:	56                   	push   %esi
801010e6:	53                   	push   %ebx
801010e7:	83 ec 1c             	sub    $0x1c,%esp
801010ea:	89 c6                	mov    %eax,%esi
801010ec:	89 d7                	mov    %edx,%edi
  if(bn < NDIRECT){
801010ee:	83 fa 0b             	cmp    $0xb,%edx
801010f1:	77 17                	ja     8010110a <bmap+0x29>
    if((addr = ip->addrs[bn]) == 0)
801010f3:	8b 5c 90 5c          	mov    0x5c(%eax,%edx,4),%ebx
801010f7:	85 db                	test   %ebx,%ebx
801010f9:	75 4a                	jne    80101145 <bmap+0x64>
      ip->addrs[bn] = addr = balloc(ip->dev);
801010fb:	8b 00                	mov    (%eax),%eax
801010fd:	e8 fa fe ff ff       	call   80100ffc <balloc>
80101102:	89 c3                	mov    %eax,%ebx
80101104:	89 44 be 5c          	mov    %eax,0x5c(%esi,%edi,4)
80101108:	eb 3b                	jmp    80101145 <bmap+0x64>
  bn -= NDIRECT;
8010110a:	8d 5a f4             	lea    -0xc(%edx),%ebx
  if(bn < NINDIRECT){
8010110d:	83 fb 7f             	cmp    $0x7f,%ebx
80101110:	77 68                	ja     8010117a <bmap+0x99>
    if((addr = ip->addrs[NDIRECT]) == 0)
80101112:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80101118:	85 c0                	test   %eax,%eax
8010111a:	74 33                	je     8010114f <bmap+0x6e>
    bp = bread(ip->dev, addr);
8010111c:	83 ec 08             	sub    $0x8,%esp
8010111f:	50                   	push   %eax
80101120:	ff 36                	pushl  (%esi)
80101122:	e8 45 f0 ff ff       	call   8010016c <bread>
80101127:	89 c7                	mov    %eax,%edi
    if((addr = a[bn]) == 0){
80101129:	8d 44 98 5c          	lea    0x5c(%eax,%ebx,4),%eax
8010112d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80101130:	8b 18                	mov    (%eax),%ebx
80101132:	83 c4 10             	add    $0x10,%esp
80101135:	85 db                	test   %ebx,%ebx
80101137:	74 25                	je     8010115e <bmap+0x7d>
    brelse(bp);
80101139:	83 ec 0c             	sub    $0xc,%esp
8010113c:	57                   	push   %edi
8010113d:	e8 93 f0 ff ff       	call   801001d5 <brelse>
    return addr;
80101142:	83 c4 10             	add    $0x10,%esp
}
80101145:	89 d8                	mov    %ebx,%eax
80101147:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010114a:	5b                   	pop    %ebx
8010114b:	5e                   	pop    %esi
8010114c:	5f                   	pop    %edi
8010114d:	5d                   	pop    %ebp
8010114e:	c3                   	ret    
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
8010114f:	8b 06                	mov    (%esi),%eax
80101151:	e8 a6 fe ff ff       	call   80100ffc <balloc>
80101156:	89 86 8c 00 00 00    	mov    %eax,0x8c(%esi)
8010115c:	eb be                	jmp    8010111c <bmap+0x3b>
      a[bn] = addr = balloc(ip->dev);
8010115e:	8b 06                	mov    (%esi),%eax
80101160:	e8 97 fe ff ff       	call   80100ffc <balloc>
80101165:	89 c3                	mov    %eax,%ebx
80101167:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010116a:	89 18                	mov    %ebx,(%eax)
      log_write(bp);
8010116c:	83 ec 0c             	sub    $0xc,%esp
8010116f:	57                   	push   %edi
80101170:	e8 9c 17 00 00       	call   80102911 <log_write>
80101175:	83 c4 10             	add    $0x10,%esp
80101178:	eb bf                	jmp    80101139 <bmap+0x58>
  panic("bmap: out of range");
8010117a:	83 ec 0c             	sub    $0xc,%esp
8010117d:	68 55 66 10 80       	push   $0x80106655
80101182:	e8 c1 f1 ff ff       	call   80100348 <panic>

80101187 <iget>:
{
80101187:	55                   	push   %ebp
80101188:	89 e5                	mov    %esp,%ebp
8010118a:	57                   	push   %edi
8010118b:	56                   	push   %esi
8010118c:	53                   	push   %ebx
8010118d:	83 ec 28             	sub    $0x28,%esp
80101190:	89 c7                	mov    %eax,%edi
80101192:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  acquire(&icache.lock);
80101195:	68 60 a3 16 80       	push   $0x8016a360
8010119a:	e8 e4 2a 00 00       	call   80103c83 <acquire>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010119f:	83 c4 10             	add    $0x10,%esp
  empty = 0;
801011a2:	be 00 00 00 00       	mov    $0x0,%esi
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011a7:	bb 94 a3 16 80       	mov    $0x8016a394,%ebx
801011ac:	eb 0a                	jmp    801011b8 <iget+0x31>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801011ae:	85 f6                	test   %esi,%esi
801011b0:	74 3b                	je     801011ed <iget+0x66>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011b2:	81 c3 90 00 00 00    	add    $0x90,%ebx
801011b8:	81 fb b4 bf 16 80    	cmp    $0x8016bfb4,%ebx
801011be:	73 35                	jae    801011f5 <iget+0x6e>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
801011c0:	8b 43 08             	mov    0x8(%ebx),%eax
801011c3:	85 c0                	test   %eax,%eax
801011c5:	7e e7                	jle    801011ae <iget+0x27>
801011c7:	39 3b                	cmp    %edi,(%ebx)
801011c9:	75 e3                	jne    801011ae <iget+0x27>
801011cb:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801011ce:	39 4b 04             	cmp    %ecx,0x4(%ebx)
801011d1:	75 db                	jne    801011ae <iget+0x27>
      ip->ref++;
801011d3:	83 c0 01             	add    $0x1,%eax
801011d6:	89 43 08             	mov    %eax,0x8(%ebx)
      release(&icache.lock);
801011d9:	83 ec 0c             	sub    $0xc,%esp
801011dc:	68 60 a3 16 80       	push   $0x8016a360
801011e1:	e8 02 2b 00 00       	call   80103ce8 <release>
      return ip;
801011e6:	83 c4 10             	add    $0x10,%esp
801011e9:	89 de                	mov    %ebx,%esi
801011eb:	eb 32                	jmp    8010121f <iget+0x98>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801011ed:	85 c0                	test   %eax,%eax
801011ef:	75 c1                	jne    801011b2 <iget+0x2b>
      empty = ip;
801011f1:	89 de                	mov    %ebx,%esi
801011f3:	eb bd                	jmp    801011b2 <iget+0x2b>
  if(empty == 0)
801011f5:	85 f6                	test   %esi,%esi
801011f7:	74 30                	je     80101229 <iget+0xa2>
  ip->dev = dev;
801011f9:	89 3e                	mov    %edi,(%esi)
  ip->inum = inum;
801011fb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801011fe:	89 46 04             	mov    %eax,0x4(%esi)
  ip->ref = 1;
80101201:	c7 46 08 01 00 00 00 	movl   $0x1,0x8(%esi)
  ip->valid = 0;
80101208:	c7 46 4c 00 00 00 00 	movl   $0x0,0x4c(%esi)
  release(&icache.lock);
8010120f:	83 ec 0c             	sub    $0xc,%esp
80101212:	68 60 a3 16 80       	push   $0x8016a360
80101217:	e8 cc 2a 00 00       	call   80103ce8 <release>
  return ip;
8010121c:	83 c4 10             	add    $0x10,%esp
}
8010121f:	89 f0                	mov    %esi,%eax
80101221:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101224:	5b                   	pop    %ebx
80101225:	5e                   	pop    %esi
80101226:	5f                   	pop    %edi
80101227:	5d                   	pop    %ebp
80101228:	c3                   	ret    
    panic("iget: no inodes");
80101229:	83 ec 0c             	sub    $0xc,%esp
8010122c:	68 68 66 10 80       	push   $0x80106668
80101231:	e8 12 f1 ff ff       	call   80100348 <panic>

80101236 <readsb>:
{
80101236:	55                   	push   %ebp
80101237:	89 e5                	mov    %esp,%ebp
80101239:	53                   	push   %ebx
8010123a:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, 1);
8010123d:	6a 01                	push   $0x1
8010123f:	ff 75 08             	pushl  0x8(%ebp)
80101242:	e8 25 ef ff ff       	call   8010016c <bread>
80101247:	89 c3                	mov    %eax,%ebx
  memmove(sb, bp->data, sizeof(*sb));
80101249:	8d 40 5c             	lea    0x5c(%eax),%eax
8010124c:	83 c4 0c             	add    $0xc,%esp
8010124f:	6a 1c                	push   $0x1c
80101251:	50                   	push   %eax
80101252:	ff 75 0c             	pushl  0xc(%ebp)
80101255:	e8 50 2b 00 00       	call   80103daa <memmove>
  brelse(bp);
8010125a:	89 1c 24             	mov    %ebx,(%esp)
8010125d:	e8 73 ef ff ff       	call   801001d5 <brelse>
}
80101262:	83 c4 10             	add    $0x10,%esp
80101265:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101268:	c9                   	leave  
80101269:	c3                   	ret    

8010126a <bfree>:
{
8010126a:	55                   	push   %ebp
8010126b:	89 e5                	mov    %esp,%ebp
8010126d:	56                   	push   %esi
8010126e:	53                   	push   %ebx
8010126f:	89 c6                	mov    %eax,%esi
80101271:	89 d3                	mov    %edx,%ebx
  readsb(dev, &sb);
80101273:	83 ec 08             	sub    $0x8,%esp
80101276:	68 40 a3 16 80       	push   $0x8016a340
8010127b:	50                   	push   %eax
8010127c:	e8 b5 ff ff ff       	call   80101236 <readsb>
  bp = bread(dev, BBLOCK(b, sb));
80101281:	89 d8                	mov    %ebx,%eax
80101283:	c1 e8 0c             	shr    $0xc,%eax
80101286:	03 05 58 a3 16 80    	add    0x8016a358,%eax
8010128c:	83 c4 08             	add    $0x8,%esp
8010128f:	50                   	push   %eax
80101290:	56                   	push   %esi
80101291:	e8 d6 ee ff ff       	call   8010016c <bread>
80101296:	89 c6                	mov    %eax,%esi
  m = 1 << (bi % 8);
80101298:	89 d9                	mov    %ebx,%ecx
8010129a:	83 e1 07             	and    $0x7,%ecx
8010129d:	b8 01 00 00 00       	mov    $0x1,%eax
801012a2:	d3 e0                	shl    %cl,%eax
  if((bp->data[bi/8] & m) == 0)
801012a4:	83 c4 10             	add    $0x10,%esp
801012a7:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
801012ad:	c1 fb 03             	sar    $0x3,%ebx
801012b0:	0f b6 54 1e 5c       	movzbl 0x5c(%esi,%ebx,1),%edx
801012b5:	0f b6 ca             	movzbl %dl,%ecx
801012b8:	85 c1                	test   %eax,%ecx
801012ba:	74 23                	je     801012df <bfree+0x75>
  bp->data[bi/8] &= ~m;
801012bc:	f7 d0                	not    %eax
801012be:	21 d0                	and    %edx,%eax
801012c0:	88 44 1e 5c          	mov    %al,0x5c(%esi,%ebx,1)
  log_write(bp);
801012c4:	83 ec 0c             	sub    $0xc,%esp
801012c7:	56                   	push   %esi
801012c8:	e8 44 16 00 00       	call   80102911 <log_write>
  brelse(bp);
801012cd:	89 34 24             	mov    %esi,(%esp)
801012d0:	e8 00 ef ff ff       	call   801001d5 <brelse>
}
801012d5:	83 c4 10             	add    $0x10,%esp
801012d8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801012db:	5b                   	pop    %ebx
801012dc:	5e                   	pop    %esi
801012dd:	5d                   	pop    %ebp
801012de:	c3                   	ret    
    panic("freeing free block");
801012df:	83 ec 0c             	sub    $0xc,%esp
801012e2:	68 78 66 10 80       	push   $0x80106678
801012e7:	e8 5c f0 ff ff       	call   80100348 <panic>

801012ec <iinit>:
{
801012ec:	55                   	push   %ebp
801012ed:	89 e5                	mov    %esp,%ebp
801012ef:	53                   	push   %ebx
801012f0:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012f3:	68 8b 66 10 80       	push   $0x8010668b
801012f8:	68 60 a3 16 80       	push   $0x8016a360
801012fd:	e8 45 28 00 00       	call   80103b47 <initlock>
  for(i = 0; i < NINODE; i++) {
80101302:	83 c4 10             	add    $0x10,%esp
80101305:	bb 00 00 00 00       	mov    $0x0,%ebx
8010130a:	eb 21                	jmp    8010132d <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
8010130c:	83 ec 08             	sub    $0x8,%esp
8010130f:	68 92 66 10 80       	push   $0x80106692
80101314:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101317:	89 d0                	mov    %edx,%eax
80101319:	c1 e0 04             	shl    $0x4,%eax
8010131c:	05 a0 a3 16 80       	add    $0x8016a3a0,%eax
80101321:	50                   	push   %eax
80101322:	e8 15 27 00 00       	call   80103a3c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
80101327:	83 c3 01             	add    $0x1,%ebx
8010132a:	83 c4 10             	add    $0x10,%esp
8010132d:	83 fb 31             	cmp    $0x31,%ebx
80101330:	7e da                	jle    8010130c <iinit+0x20>
  readsb(dev, &sb);
80101332:	83 ec 08             	sub    $0x8,%esp
80101335:	68 40 a3 16 80       	push   $0x8016a340
8010133a:	ff 75 08             	pushl  0x8(%ebp)
8010133d:	e8 f4 fe ff ff       	call   80101236 <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d\
80101342:	ff 35 58 a3 16 80    	pushl  0x8016a358
80101348:	ff 35 54 a3 16 80    	pushl  0x8016a354
8010134e:	ff 35 50 a3 16 80    	pushl  0x8016a350
80101354:	ff 35 4c a3 16 80    	pushl  0x8016a34c
8010135a:	ff 35 48 a3 16 80    	pushl  0x8016a348
80101360:	ff 35 44 a3 16 80    	pushl  0x8016a344
80101366:	ff 35 40 a3 16 80    	pushl  0x8016a340
8010136c:	68 f8 66 10 80       	push   $0x801066f8
80101371:	e8 95 f2 ff ff       	call   8010060b <cprintf>
}
80101376:	83 c4 30             	add    $0x30,%esp
80101379:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010137c:	c9                   	leave  
8010137d:	c3                   	ret    

8010137e <ialloc>:
{
8010137e:	55                   	push   %ebp
8010137f:	89 e5                	mov    %esp,%ebp
80101381:	57                   	push   %edi
80101382:	56                   	push   %esi
80101383:	53                   	push   %ebx
80101384:	83 ec 1c             	sub    $0x1c,%esp
80101387:	8b 45 0c             	mov    0xc(%ebp),%eax
8010138a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  for(inum = 1; inum < sb.ninodes; inum++){
8010138d:	bb 01 00 00 00       	mov    $0x1,%ebx
80101392:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
80101395:	39 1d 48 a3 16 80    	cmp    %ebx,0x8016a348
8010139b:	76 3f                	jbe    801013dc <ialloc+0x5e>
    bp = bread(dev, IBLOCK(inum, sb));
8010139d:	89 d8                	mov    %ebx,%eax
8010139f:	c1 e8 03             	shr    $0x3,%eax
801013a2:	03 05 54 a3 16 80    	add    0x8016a354,%eax
801013a8:	83 ec 08             	sub    $0x8,%esp
801013ab:	50                   	push   %eax
801013ac:	ff 75 08             	pushl  0x8(%ebp)
801013af:	e8 b8 ed ff ff       	call   8010016c <bread>
801013b4:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + inum%IPB;
801013b6:	89 d8                	mov    %ebx,%eax
801013b8:	83 e0 07             	and    $0x7,%eax
801013bb:	c1 e0 06             	shl    $0x6,%eax
801013be:	8d 7c 06 5c          	lea    0x5c(%esi,%eax,1),%edi
    if(dip->type == 0){  // a free inode
801013c2:	83 c4 10             	add    $0x10,%esp
801013c5:	66 83 3f 00          	cmpw   $0x0,(%edi)
801013c9:	74 1e                	je     801013e9 <ialloc+0x6b>
    brelse(bp);
801013cb:	83 ec 0c             	sub    $0xc,%esp
801013ce:	56                   	push   %esi
801013cf:	e8 01 ee ff ff       	call   801001d5 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
801013d4:	83 c3 01             	add    $0x1,%ebx
801013d7:	83 c4 10             	add    $0x10,%esp
801013da:	eb b6                	jmp    80101392 <ialloc+0x14>
  panic("ialloc: no inodes");
801013dc:	83 ec 0c             	sub    $0xc,%esp
801013df:	68 98 66 10 80       	push   $0x80106698
801013e4:	e8 5f ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013e9:	83 ec 04             	sub    $0x4,%esp
801013ec:	6a 40                	push   $0x40
801013ee:	6a 00                	push   $0x0
801013f0:	57                   	push   %edi
801013f1:	e8 39 29 00 00       	call   80103d2f <memset>
      dip->type = type;
801013f6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801013fa:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
801013fd:	89 34 24             	mov    %esi,(%esp)
80101400:	e8 0c 15 00 00       	call   80102911 <log_write>
      brelse(bp);
80101405:	89 34 24             	mov    %esi,(%esp)
80101408:	e8 c8 ed ff ff       	call   801001d5 <brelse>
      return iget(dev, inum);
8010140d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101410:	8b 45 08             	mov    0x8(%ebp),%eax
80101413:	e8 6f fd ff ff       	call   80101187 <iget>
}
80101418:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010141b:	5b                   	pop    %ebx
8010141c:	5e                   	pop    %esi
8010141d:	5f                   	pop    %edi
8010141e:	5d                   	pop    %ebp
8010141f:	c3                   	ret    

80101420 <iupdate>:
{
80101420:	55                   	push   %ebp
80101421:	89 e5                	mov    %esp,%ebp
80101423:	56                   	push   %esi
80101424:	53                   	push   %ebx
80101425:	8b 5d 08             	mov    0x8(%ebp),%ebx
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101428:	8b 43 04             	mov    0x4(%ebx),%eax
8010142b:	c1 e8 03             	shr    $0x3,%eax
8010142e:	03 05 54 a3 16 80    	add    0x8016a354,%eax
80101434:	83 ec 08             	sub    $0x8,%esp
80101437:	50                   	push   %eax
80101438:	ff 33                	pushl  (%ebx)
8010143a:	e8 2d ed ff ff       	call   8010016c <bread>
8010143f:	89 c6                	mov    %eax,%esi
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80101441:	8b 43 04             	mov    0x4(%ebx),%eax
80101444:	83 e0 07             	and    $0x7,%eax
80101447:	c1 e0 06             	shl    $0x6,%eax
8010144a:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
  dip->type = ip->type;
8010144e:	0f b7 53 50          	movzwl 0x50(%ebx),%edx
80101452:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101455:	0f b7 53 52          	movzwl 0x52(%ebx),%edx
80101459:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
8010145d:	0f b7 53 54          	movzwl 0x54(%ebx),%edx
80101461:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101465:	0f b7 53 56          	movzwl 0x56(%ebx),%edx
80101469:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
8010146d:	8b 53 58             	mov    0x58(%ebx),%edx
80101470:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
80101473:	83 c3 5c             	add    $0x5c,%ebx
80101476:	83 c0 0c             	add    $0xc,%eax
80101479:	83 c4 0c             	add    $0xc,%esp
8010147c:	6a 34                	push   $0x34
8010147e:	53                   	push   %ebx
8010147f:	50                   	push   %eax
80101480:	e8 25 29 00 00       	call   80103daa <memmove>
  log_write(bp);
80101485:	89 34 24             	mov    %esi,(%esp)
80101488:	e8 84 14 00 00       	call   80102911 <log_write>
  brelse(bp);
8010148d:	89 34 24             	mov    %esi,(%esp)
80101490:	e8 40 ed ff ff       	call   801001d5 <brelse>
}
80101495:	83 c4 10             	add    $0x10,%esp
80101498:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010149b:	5b                   	pop    %ebx
8010149c:	5e                   	pop    %esi
8010149d:	5d                   	pop    %ebp
8010149e:	c3                   	ret    

8010149f <itrunc>:
{
8010149f:	55                   	push   %ebp
801014a0:	89 e5                	mov    %esp,%ebp
801014a2:	57                   	push   %edi
801014a3:	56                   	push   %esi
801014a4:	53                   	push   %ebx
801014a5:	83 ec 1c             	sub    $0x1c,%esp
801014a8:	89 c6                	mov    %eax,%esi
  for(i = 0; i < NDIRECT; i++){
801014aa:	bb 00 00 00 00       	mov    $0x0,%ebx
801014af:	eb 03                	jmp    801014b4 <itrunc+0x15>
801014b1:	83 c3 01             	add    $0x1,%ebx
801014b4:	83 fb 0b             	cmp    $0xb,%ebx
801014b7:	7f 19                	jg     801014d2 <itrunc+0x33>
    if(ip->addrs[i]){
801014b9:	8b 54 9e 5c          	mov    0x5c(%esi,%ebx,4),%edx
801014bd:	85 d2                	test   %edx,%edx
801014bf:	74 f0                	je     801014b1 <itrunc+0x12>
      bfree(ip->dev, ip->addrs[i]);
801014c1:	8b 06                	mov    (%esi),%eax
801014c3:	e8 a2 fd ff ff       	call   8010126a <bfree>
      ip->addrs[i] = 0;
801014c8:	c7 44 9e 5c 00 00 00 	movl   $0x0,0x5c(%esi,%ebx,4)
801014cf:	00 
801014d0:	eb df                	jmp    801014b1 <itrunc+0x12>
  if(ip->addrs[NDIRECT]){
801014d2:	8b 86 8c 00 00 00    	mov    0x8c(%esi),%eax
801014d8:	85 c0                	test   %eax,%eax
801014da:	75 1b                	jne    801014f7 <itrunc+0x58>
  ip->size = 0;
801014dc:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)
  iupdate(ip);
801014e3:	83 ec 0c             	sub    $0xc,%esp
801014e6:	56                   	push   %esi
801014e7:	e8 34 ff ff ff       	call   80101420 <iupdate>
}
801014ec:	83 c4 10             	add    $0x10,%esp
801014ef:	8d 65 f4             	lea    -0xc(%ebp),%esp
801014f2:	5b                   	pop    %ebx
801014f3:	5e                   	pop    %esi
801014f4:	5f                   	pop    %edi
801014f5:	5d                   	pop    %ebp
801014f6:	c3                   	ret    
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
801014f7:	83 ec 08             	sub    $0x8,%esp
801014fa:	50                   	push   %eax
801014fb:	ff 36                	pushl  (%esi)
801014fd:	e8 6a ec ff ff       	call   8010016c <bread>
80101502:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    a = (uint*)bp->data;
80101505:	8d 78 5c             	lea    0x5c(%eax),%edi
    for(j = 0; j < NINDIRECT; j++){
80101508:	83 c4 10             	add    $0x10,%esp
8010150b:	bb 00 00 00 00       	mov    $0x0,%ebx
80101510:	eb 03                	jmp    80101515 <itrunc+0x76>
80101512:	83 c3 01             	add    $0x1,%ebx
80101515:	83 fb 7f             	cmp    $0x7f,%ebx
80101518:	77 10                	ja     8010152a <itrunc+0x8b>
      if(a[j])
8010151a:	8b 14 9f             	mov    (%edi,%ebx,4),%edx
8010151d:	85 d2                	test   %edx,%edx
8010151f:	74 f1                	je     80101512 <itrunc+0x73>
        bfree(ip->dev, a[j]);
80101521:	8b 06                	mov    (%esi),%eax
80101523:	e8 42 fd ff ff       	call   8010126a <bfree>
80101528:	eb e8                	jmp    80101512 <itrunc+0x73>
    brelse(bp);
8010152a:	83 ec 0c             	sub    $0xc,%esp
8010152d:	ff 75 e4             	pushl  -0x1c(%ebp)
80101530:	e8 a0 ec ff ff       	call   801001d5 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101535:	8b 06                	mov    (%esi),%eax
80101537:	8b 96 8c 00 00 00    	mov    0x8c(%esi),%edx
8010153d:	e8 28 fd ff ff       	call   8010126a <bfree>
    ip->addrs[NDIRECT] = 0;
80101542:	c7 86 8c 00 00 00 00 	movl   $0x0,0x8c(%esi)
80101549:	00 00 00 
8010154c:	83 c4 10             	add    $0x10,%esp
8010154f:	eb 8b                	jmp    801014dc <itrunc+0x3d>

80101551 <idup>:
{
80101551:	55                   	push   %ebp
80101552:	89 e5                	mov    %esp,%ebp
80101554:	53                   	push   %ebx
80101555:	83 ec 10             	sub    $0x10,%esp
80101558:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&icache.lock);
8010155b:	68 60 a3 16 80       	push   $0x8016a360
80101560:	e8 1e 27 00 00       	call   80103c83 <acquire>
  ip->ref++;
80101565:	8b 43 08             	mov    0x8(%ebx),%eax
80101568:	83 c0 01             	add    $0x1,%eax
8010156b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010156e:	c7 04 24 60 a3 16 80 	movl   $0x8016a360,(%esp)
80101575:	e8 6e 27 00 00       	call   80103ce8 <release>
}
8010157a:	89 d8                	mov    %ebx,%eax
8010157c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010157f:	c9                   	leave  
80101580:	c3                   	ret    

80101581 <ilock>:
{
80101581:	55                   	push   %ebp
80101582:	89 e5                	mov    %esp,%ebp
80101584:	56                   	push   %esi
80101585:	53                   	push   %ebx
80101586:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || ip->ref < 1)
80101589:	85 db                	test   %ebx,%ebx
8010158b:	74 22                	je     801015af <ilock+0x2e>
8010158d:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101591:	7e 1c                	jle    801015af <ilock+0x2e>
  acquiresleep(&ip->lock);
80101593:	83 ec 0c             	sub    $0xc,%esp
80101596:	8d 43 0c             	lea    0xc(%ebx),%eax
80101599:	50                   	push   %eax
8010159a:	e8 d0 24 00 00       	call   80103a6f <acquiresleep>
  if(ip->valid == 0){
8010159f:	83 c4 10             	add    $0x10,%esp
801015a2:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801015a6:	74 14                	je     801015bc <ilock+0x3b>
}
801015a8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801015ab:	5b                   	pop    %ebx
801015ac:	5e                   	pop    %esi
801015ad:	5d                   	pop    %ebp
801015ae:	c3                   	ret    
    panic("ilock");
801015af:	83 ec 0c             	sub    $0xc,%esp
801015b2:	68 aa 66 10 80       	push   $0x801066aa
801015b7:	e8 8c ed ff ff       	call   80100348 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
801015bc:	8b 43 04             	mov    0x4(%ebx),%eax
801015bf:	c1 e8 03             	shr    $0x3,%eax
801015c2:	03 05 54 a3 16 80    	add    0x8016a354,%eax
801015c8:	83 ec 08             	sub    $0x8,%esp
801015cb:	50                   	push   %eax
801015cc:	ff 33                	pushl  (%ebx)
801015ce:	e8 99 eb ff ff       	call   8010016c <bread>
801015d3:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + ip->inum%IPB;
801015d5:	8b 43 04             	mov    0x4(%ebx),%eax
801015d8:	83 e0 07             	and    $0x7,%eax
801015db:	c1 e0 06             	shl    $0x6,%eax
801015de:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
    ip->type = dip->type;
801015e2:	0f b7 10             	movzwl (%eax),%edx
801015e5:	66 89 53 50          	mov    %dx,0x50(%ebx)
    ip->major = dip->major;
801015e9:	0f b7 50 02          	movzwl 0x2(%eax),%edx
801015ed:	66 89 53 52          	mov    %dx,0x52(%ebx)
    ip->minor = dip->minor;
801015f1:	0f b7 50 04          	movzwl 0x4(%eax),%edx
801015f5:	66 89 53 54          	mov    %dx,0x54(%ebx)
    ip->nlink = dip->nlink;
801015f9:	0f b7 50 06          	movzwl 0x6(%eax),%edx
801015fd:	66 89 53 56          	mov    %dx,0x56(%ebx)
    ip->size = dip->size;
80101601:	8b 50 08             	mov    0x8(%eax),%edx
80101604:	89 53 58             	mov    %edx,0x58(%ebx)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101607:	83 c0 0c             	add    $0xc,%eax
8010160a:	8d 53 5c             	lea    0x5c(%ebx),%edx
8010160d:	83 c4 0c             	add    $0xc,%esp
80101610:	6a 34                	push   $0x34
80101612:	50                   	push   %eax
80101613:	52                   	push   %edx
80101614:	e8 91 27 00 00       	call   80103daa <memmove>
    brelse(bp);
80101619:	89 34 24             	mov    %esi,(%esp)
8010161c:	e8 b4 eb ff ff       	call   801001d5 <brelse>
    ip->valid = 1;
80101621:	c7 43 4c 01 00 00 00 	movl   $0x1,0x4c(%ebx)
    if(ip->type == 0)
80101628:	83 c4 10             	add    $0x10,%esp
8010162b:	66 83 7b 50 00       	cmpw   $0x0,0x50(%ebx)
80101630:	0f 85 72 ff ff ff    	jne    801015a8 <ilock+0x27>
      panic("ilock: no type");
80101636:	83 ec 0c             	sub    $0xc,%esp
80101639:	68 b0 66 10 80       	push   $0x801066b0
8010163e:	e8 05 ed ff ff       	call   80100348 <panic>

80101643 <iunlock>:
{
80101643:	55                   	push   %ebp
80101644:	89 e5                	mov    %esp,%ebp
80101646:	56                   	push   %esi
80101647:	53                   	push   %ebx
80101648:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
8010164b:	85 db                	test   %ebx,%ebx
8010164d:	74 2c                	je     8010167b <iunlock+0x38>
8010164f:	8d 73 0c             	lea    0xc(%ebx),%esi
80101652:	83 ec 0c             	sub    $0xc,%esp
80101655:	56                   	push   %esi
80101656:	e8 9e 24 00 00       	call   80103af9 <holdingsleep>
8010165b:	83 c4 10             	add    $0x10,%esp
8010165e:	85 c0                	test   %eax,%eax
80101660:	74 19                	je     8010167b <iunlock+0x38>
80101662:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101666:	7e 13                	jle    8010167b <iunlock+0x38>
  releasesleep(&ip->lock);
80101668:	83 ec 0c             	sub    $0xc,%esp
8010166b:	56                   	push   %esi
8010166c:	e8 4d 24 00 00       	call   80103abe <releasesleep>
}
80101671:	83 c4 10             	add    $0x10,%esp
80101674:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101677:	5b                   	pop    %ebx
80101678:	5e                   	pop    %esi
80101679:	5d                   	pop    %ebp
8010167a:	c3                   	ret    
    panic("iunlock");
8010167b:	83 ec 0c             	sub    $0xc,%esp
8010167e:	68 bf 66 10 80       	push   $0x801066bf
80101683:	e8 c0 ec ff ff       	call   80100348 <panic>

80101688 <iput>:
{
80101688:	55                   	push   %ebp
80101689:	89 e5                	mov    %esp,%ebp
8010168b:	57                   	push   %edi
8010168c:	56                   	push   %esi
8010168d:	53                   	push   %ebx
8010168e:	83 ec 18             	sub    $0x18,%esp
80101691:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquiresleep(&ip->lock);
80101694:	8d 73 0c             	lea    0xc(%ebx),%esi
80101697:	56                   	push   %esi
80101698:	e8 d2 23 00 00       	call   80103a6f <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010169d:	83 c4 10             	add    $0x10,%esp
801016a0:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016a4:	74 07                	je     801016ad <iput+0x25>
801016a6:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016ab:	74 35                	je     801016e2 <iput+0x5a>
  releasesleep(&ip->lock);
801016ad:	83 ec 0c             	sub    $0xc,%esp
801016b0:	56                   	push   %esi
801016b1:	e8 08 24 00 00       	call   80103abe <releasesleep>
  acquire(&icache.lock);
801016b6:	c7 04 24 60 a3 16 80 	movl   $0x8016a360,(%esp)
801016bd:	e8 c1 25 00 00       	call   80103c83 <acquire>
  ip->ref--;
801016c2:	8b 43 08             	mov    0x8(%ebx),%eax
801016c5:	83 e8 01             	sub    $0x1,%eax
801016c8:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016cb:	c7 04 24 60 a3 16 80 	movl   $0x8016a360,(%esp)
801016d2:	e8 11 26 00 00       	call   80103ce8 <release>
}
801016d7:	83 c4 10             	add    $0x10,%esp
801016da:	8d 65 f4             	lea    -0xc(%ebp),%esp
801016dd:	5b                   	pop    %ebx
801016de:	5e                   	pop    %esi
801016df:	5f                   	pop    %edi
801016e0:	5d                   	pop    %ebp
801016e1:	c3                   	ret    
    acquire(&icache.lock);
801016e2:	83 ec 0c             	sub    $0xc,%esp
801016e5:	68 60 a3 16 80       	push   $0x8016a360
801016ea:	e8 94 25 00 00       	call   80103c83 <acquire>
    int r = ip->ref;
801016ef:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016f2:	c7 04 24 60 a3 16 80 	movl   $0x8016a360,(%esp)
801016f9:	e8 ea 25 00 00       	call   80103ce8 <release>
    if(r == 1){
801016fe:	83 c4 10             	add    $0x10,%esp
80101701:	83 ff 01             	cmp    $0x1,%edi
80101704:	75 a7                	jne    801016ad <iput+0x25>
      itrunc(ip);
80101706:	89 d8                	mov    %ebx,%eax
80101708:	e8 92 fd ff ff       	call   8010149f <itrunc>
      ip->type = 0;
8010170d:	66 c7 43 50 00 00    	movw   $0x0,0x50(%ebx)
      iupdate(ip);
80101713:	83 ec 0c             	sub    $0xc,%esp
80101716:	53                   	push   %ebx
80101717:	e8 04 fd ff ff       	call   80101420 <iupdate>
      ip->valid = 0;
8010171c:	c7 43 4c 00 00 00 00 	movl   $0x0,0x4c(%ebx)
80101723:	83 c4 10             	add    $0x10,%esp
80101726:	eb 85                	jmp    801016ad <iput+0x25>

80101728 <iunlockput>:
{
80101728:	55                   	push   %ebp
80101729:	89 e5                	mov    %esp,%ebp
8010172b:	53                   	push   %ebx
8010172c:	83 ec 10             	sub    $0x10,%esp
8010172f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  iunlock(ip);
80101732:	53                   	push   %ebx
80101733:	e8 0b ff ff ff       	call   80101643 <iunlock>
  iput(ip);
80101738:	89 1c 24             	mov    %ebx,(%esp)
8010173b:	e8 48 ff ff ff       	call   80101688 <iput>
}
80101740:	83 c4 10             	add    $0x10,%esp
80101743:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101746:	c9                   	leave  
80101747:	c3                   	ret    

80101748 <stati>:
{
80101748:	55                   	push   %ebp
80101749:	89 e5                	mov    %esp,%ebp
8010174b:	8b 55 08             	mov    0x8(%ebp),%edx
8010174e:	8b 45 0c             	mov    0xc(%ebp),%eax
  st->dev = ip->dev;
80101751:	8b 0a                	mov    (%edx),%ecx
80101753:	89 48 04             	mov    %ecx,0x4(%eax)
  st->ino = ip->inum;
80101756:	8b 4a 04             	mov    0x4(%edx),%ecx
80101759:	89 48 08             	mov    %ecx,0x8(%eax)
  st->type = ip->type;
8010175c:	0f b7 4a 50          	movzwl 0x50(%edx),%ecx
80101760:	66 89 08             	mov    %cx,(%eax)
  st->nlink = ip->nlink;
80101763:	0f b7 4a 56          	movzwl 0x56(%edx),%ecx
80101767:	66 89 48 0c          	mov    %cx,0xc(%eax)
  st->size = ip->size;
8010176b:	8b 52 58             	mov    0x58(%edx),%edx
8010176e:	89 50 10             	mov    %edx,0x10(%eax)
}
80101771:	5d                   	pop    %ebp
80101772:	c3                   	ret    

80101773 <readi>:
{
80101773:	55                   	push   %ebp
80101774:	89 e5                	mov    %esp,%ebp
80101776:	57                   	push   %edi
80101777:	56                   	push   %esi
80101778:	53                   	push   %ebx
80101779:	83 ec 1c             	sub    $0x1c,%esp
8010177c:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(ip->type == T_DEV){
8010177f:	8b 45 08             	mov    0x8(%ebp),%eax
80101782:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101787:	74 2c                	je     801017b5 <readi+0x42>
  if(off > ip->size || off + n < off)
80101789:	8b 45 08             	mov    0x8(%ebp),%eax
8010178c:	8b 40 58             	mov    0x58(%eax),%eax
8010178f:	39 f8                	cmp    %edi,%eax
80101791:	0f 82 cb 00 00 00    	jb     80101862 <readi+0xef>
80101797:	89 fa                	mov    %edi,%edx
80101799:	03 55 14             	add    0x14(%ebp),%edx
8010179c:	0f 82 c7 00 00 00    	jb     80101869 <readi+0xf6>
  if(off + n > ip->size)
801017a2:	39 d0                	cmp    %edx,%eax
801017a4:	73 05                	jae    801017ab <readi+0x38>
    n = ip->size - off;
801017a6:	29 f8                	sub    %edi,%eax
801017a8:	89 45 14             	mov    %eax,0x14(%ebp)
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
801017ab:	be 00 00 00 00       	mov    $0x0,%esi
801017b0:	e9 8f 00 00 00       	jmp    80101844 <readi+0xd1>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
801017b5:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801017b9:	66 83 f8 09          	cmp    $0x9,%ax
801017bd:	0f 87 91 00 00 00    	ja     80101854 <readi+0xe1>
801017c3:	98                   	cwtl   
801017c4:	8b 04 c5 e0 a2 16 80 	mov    -0x7fe95d20(,%eax,8),%eax
801017cb:	85 c0                	test   %eax,%eax
801017cd:	0f 84 88 00 00 00    	je     8010185b <readi+0xe8>
    return devsw[ip->major].read(ip, dst, n);
801017d3:	83 ec 04             	sub    $0x4,%esp
801017d6:	ff 75 14             	pushl  0x14(%ebp)
801017d9:	ff 75 0c             	pushl  0xc(%ebp)
801017dc:	ff 75 08             	pushl  0x8(%ebp)
801017df:	ff d0                	call   *%eax
801017e1:	83 c4 10             	add    $0x10,%esp
801017e4:	eb 66                	jmp    8010184c <readi+0xd9>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801017e6:	89 fa                	mov    %edi,%edx
801017e8:	c1 ea 09             	shr    $0x9,%edx
801017eb:	8b 45 08             	mov    0x8(%ebp),%eax
801017ee:	e8 ee f8 ff ff       	call   801010e1 <bmap>
801017f3:	83 ec 08             	sub    $0x8,%esp
801017f6:	50                   	push   %eax
801017f7:	8b 45 08             	mov    0x8(%ebp),%eax
801017fa:	ff 30                	pushl  (%eax)
801017fc:	e8 6b e9 ff ff       	call   8010016c <bread>
80101801:	89 c1                	mov    %eax,%ecx
    m = min(n - tot, BSIZE - off%BSIZE);
80101803:	89 f8                	mov    %edi,%eax
80101805:	25 ff 01 00 00       	and    $0x1ff,%eax
8010180a:	bb 00 02 00 00       	mov    $0x200,%ebx
8010180f:	29 c3                	sub    %eax,%ebx
80101811:	8b 55 14             	mov    0x14(%ebp),%edx
80101814:	29 f2                	sub    %esi,%edx
80101816:	83 c4 0c             	add    $0xc,%esp
80101819:	39 d3                	cmp    %edx,%ebx
8010181b:	0f 47 da             	cmova  %edx,%ebx
    memmove(dst, bp->data + off%BSIZE, m);
8010181e:	53                   	push   %ebx
8010181f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
80101822:	8d 44 01 5c          	lea    0x5c(%ecx,%eax,1),%eax
80101826:	50                   	push   %eax
80101827:	ff 75 0c             	pushl  0xc(%ebp)
8010182a:	e8 7b 25 00 00       	call   80103daa <memmove>
    brelse(bp);
8010182f:	83 c4 04             	add    $0x4,%esp
80101832:	ff 75 e4             	pushl  -0x1c(%ebp)
80101835:	e8 9b e9 ff ff       	call   801001d5 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
8010183a:	01 de                	add    %ebx,%esi
8010183c:	01 df                	add    %ebx,%edi
8010183e:	01 5d 0c             	add    %ebx,0xc(%ebp)
80101841:	83 c4 10             	add    $0x10,%esp
80101844:	39 75 14             	cmp    %esi,0x14(%ebp)
80101847:	77 9d                	ja     801017e6 <readi+0x73>
  return n;
80101849:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010184c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010184f:	5b                   	pop    %ebx
80101850:	5e                   	pop    %esi
80101851:	5f                   	pop    %edi
80101852:	5d                   	pop    %ebp
80101853:	c3                   	ret    
      return -1;
80101854:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101859:	eb f1                	jmp    8010184c <readi+0xd9>
8010185b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101860:	eb ea                	jmp    8010184c <readi+0xd9>
    return -1;
80101862:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101867:	eb e3                	jmp    8010184c <readi+0xd9>
80101869:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010186e:	eb dc                	jmp    8010184c <readi+0xd9>

80101870 <writei>:
{
80101870:	55                   	push   %ebp
80101871:	89 e5                	mov    %esp,%ebp
80101873:	57                   	push   %edi
80101874:	56                   	push   %esi
80101875:	53                   	push   %ebx
80101876:	83 ec 0c             	sub    $0xc,%esp
  if(ip->type == T_DEV){
80101879:	8b 45 08             	mov    0x8(%ebp),%eax
8010187c:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101881:	74 2f                	je     801018b2 <writei+0x42>
  if(off > ip->size || off + n < off)
80101883:	8b 45 08             	mov    0x8(%ebp),%eax
80101886:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101889:	39 48 58             	cmp    %ecx,0x58(%eax)
8010188c:	0f 82 f4 00 00 00    	jb     80101986 <writei+0x116>
80101892:	89 c8                	mov    %ecx,%eax
80101894:	03 45 14             	add    0x14(%ebp),%eax
80101897:	0f 82 f0 00 00 00    	jb     8010198d <writei+0x11d>
  if(off + n > MAXFILE*BSIZE)
8010189d:	3d 00 18 01 00       	cmp    $0x11800,%eax
801018a2:	0f 87 ec 00 00 00    	ja     80101994 <writei+0x124>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801018a8:	be 00 00 00 00       	mov    $0x0,%esi
801018ad:	e9 94 00 00 00       	jmp    80101946 <writei+0xd6>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
801018b2:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801018b6:	66 83 f8 09          	cmp    $0x9,%ax
801018ba:	0f 87 b8 00 00 00    	ja     80101978 <writei+0x108>
801018c0:	98                   	cwtl   
801018c1:	8b 04 c5 e4 a2 16 80 	mov    -0x7fe95d1c(,%eax,8),%eax
801018c8:	85 c0                	test   %eax,%eax
801018ca:	0f 84 af 00 00 00    	je     8010197f <writei+0x10f>
    return devsw[ip->major].write(ip, src, n);
801018d0:	83 ec 04             	sub    $0x4,%esp
801018d3:	ff 75 14             	pushl  0x14(%ebp)
801018d6:	ff 75 0c             	pushl  0xc(%ebp)
801018d9:	ff 75 08             	pushl  0x8(%ebp)
801018dc:	ff d0                	call   *%eax
801018de:	83 c4 10             	add    $0x10,%esp
801018e1:	eb 7c                	jmp    8010195f <writei+0xef>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801018e3:	8b 55 10             	mov    0x10(%ebp),%edx
801018e6:	c1 ea 09             	shr    $0x9,%edx
801018e9:	8b 45 08             	mov    0x8(%ebp),%eax
801018ec:	e8 f0 f7 ff ff       	call   801010e1 <bmap>
801018f1:	83 ec 08             	sub    $0x8,%esp
801018f4:	50                   	push   %eax
801018f5:	8b 45 08             	mov    0x8(%ebp),%eax
801018f8:	ff 30                	pushl  (%eax)
801018fa:	e8 6d e8 ff ff       	call   8010016c <bread>
801018ff:	89 c7                	mov    %eax,%edi
    m = min(n - tot, BSIZE - off%BSIZE);
80101901:	8b 45 10             	mov    0x10(%ebp),%eax
80101904:	25 ff 01 00 00       	and    $0x1ff,%eax
80101909:	bb 00 02 00 00       	mov    $0x200,%ebx
8010190e:	29 c3                	sub    %eax,%ebx
80101910:	8b 55 14             	mov    0x14(%ebp),%edx
80101913:	29 f2                	sub    %esi,%edx
80101915:	83 c4 0c             	add    $0xc,%esp
80101918:	39 d3                	cmp    %edx,%ebx
8010191a:	0f 47 da             	cmova  %edx,%ebx
    memmove(bp->data + off%BSIZE, src, m);
8010191d:	53                   	push   %ebx
8010191e:	ff 75 0c             	pushl  0xc(%ebp)
80101921:	8d 44 07 5c          	lea    0x5c(%edi,%eax,1),%eax
80101925:	50                   	push   %eax
80101926:	e8 7f 24 00 00       	call   80103daa <memmove>
    log_write(bp);
8010192b:	89 3c 24             	mov    %edi,(%esp)
8010192e:	e8 de 0f 00 00       	call   80102911 <log_write>
    brelse(bp);
80101933:	89 3c 24             	mov    %edi,(%esp)
80101936:	e8 9a e8 ff ff       	call   801001d5 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010193b:	01 de                	add    %ebx,%esi
8010193d:	01 5d 10             	add    %ebx,0x10(%ebp)
80101940:	01 5d 0c             	add    %ebx,0xc(%ebp)
80101943:	83 c4 10             	add    $0x10,%esp
80101946:	3b 75 14             	cmp    0x14(%ebp),%esi
80101949:	72 98                	jb     801018e3 <writei+0x73>
  if(n > 0 && off > ip->size){
8010194b:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010194f:	74 0b                	je     8010195c <writei+0xec>
80101951:	8b 45 08             	mov    0x8(%ebp),%eax
80101954:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101957:	39 48 58             	cmp    %ecx,0x58(%eax)
8010195a:	72 0b                	jb     80101967 <writei+0xf7>
  return n;
8010195c:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010195f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101962:	5b                   	pop    %ebx
80101963:	5e                   	pop    %esi
80101964:	5f                   	pop    %edi
80101965:	5d                   	pop    %ebp
80101966:	c3                   	ret    
    ip->size = off;
80101967:	89 48 58             	mov    %ecx,0x58(%eax)
    iupdate(ip);
8010196a:	83 ec 0c             	sub    $0xc,%esp
8010196d:	50                   	push   %eax
8010196e:	e8 ad fa ff ff       	call   80101420 <iupdate>
80101973:	83 c4 10             	add    $0x10,%esp
80101976:	eb e4                	jmp    8010195c <writei+0xec>
      return -1;
80101978:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010197d:	eb e0                	jmp    8010195f <writei+0xef>
8010197f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101984:	eb d9                	jmp    8010195f <writei+0xef>
    return -1;
80101986:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010198b:	eb d2                	jmp    8010195f <writei+0xef>
8010198d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101992:	eb cb                	jmp    8010195f <writei+0xef>
    return -1;
80101994:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101999:	eb c4                	jmp    8010195f <writei+0xef>

8010199b <namecmp>:
{
8010199b:	55                   	push   %ebp
8010199c:	89 e5                	mov    %esp,%ebp
8010199e:	83 ec 0c             	sub    $0xc,%esp
  return strncmp(s, t, DIRSIZ);
801019a1:	6a 0e                	push   $0xe
801019a3:	ff 75 0c             	pushl  0xc(%ebp)
801019a6:	ff 75 08             	pushl  0x8(%ebp)
801019a9:	e8 63 24 00 00       	call   80103e11 <strncmp>
}
801019ae:	c9                   	leave  
801019af:	c3                   	ret    

801019b0 <dirlookup>:
{
801019b0:	55                   	push   %ebp
801019b1:	89 e5                	mov    %esp,%ebp
801019b3:	57                   	push   %edi
801019b4:	56                   	push   %esi
801019b5:	53                   	push   %ebx
801019b6:	83 ec 1c             	sub    $0x1c,%esp
801019b9:	8b 75 08             	mov    0x8(%ebp),%esi
801019bc:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if(dp->type != T_DIR)
801019bf:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
801019c4:	75 07                	jne    801019cd <dirlookup+0x1d>
  for(off = 0; off < dp->size; off += sizeof(de)){
801019c6:	bb 00 00 00 00       	mov    $0x0,%ebx
801019cb:	eb 1d                	jmp    801019ea <dirlookup+0x3a>
    panic("dirlookup not DIR");
801019cd:	83 ec 0c             	sub    $0xc,%esp
801019d0:	68 c7 66 10 80       	push   $0x801066c7
801019d5:	e8 6e e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019da:	83 ec 0c             	sub    $0xc,%esp
801019dd:	68 d9 66 10 80       	push   $0x801066d9
801019e2:	e8 61 e9 ff ff       	call   80100348 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
801019e7:	83 c3 10             	add    $0x10,%ebx
801019ea:	39 5e 58             	cmp    %ebx,0x58(%esi)
801019ed:	76 48                	jbe    80101a37 <dirlookup+0x87>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801019ef:	6a 10                	push   $0x10
801019f1:	53                   	push   %ebx
801019f2:	8d 45 d8             	lea    -0x28(%ebp),%eax
801019f5:	50                   	push   %eax
801019f6:	56                   	push   %esi
801019f7:	e8 77 fd ff ff       	call   80101773 <readi>
801019fc:	83 c4 10             	add    $0x10,%esp
801019ff:	83 f8 10             	cmp    $0x10,%eax
80101a02:	75 d6                	jne    801019da <dirlookup+0x2a>
    if(de.inum == 0)
80101a04:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101a09:	74 dc                	je     801019e7 <dirlookup+0x37>
    if(namecmp(name, de.name) == 0){
80101a0b:	83 ec 08             	sub    $0x8,%esp
80101a0e:	8d 45 da             	lea    -0x26(%ebp),%eax
80101a11:	50                   	push   %eax
80101a12:	57                   	push   %edi
80101a13:	e8 83 ff ff ff       	call   8010199b <namecmp>
80101a18:	83 c4 10             	add    $0x10,%esp
80101a1b:	85 c0                	test   %eax,%eax
80101a1d:	75 c8                	jne    801019e7 <dirlookup+0x37>
      if(poff)
80101a1f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80101a23:	74 05                	je     80101a2a <dirlookup+0x7a>
        *poff = off;
80101a25:	8b 45 10             	mov    0x10(%ebp),%eax
80101a28:	89 18                	mov    %ebx,(%eax)
      inum = de.inum;
80101a2a:	0f b7 55 d8          	movzwl -0x28(%ebp),%edx
      return iget(dp->dev, inum);
80101a2e:	8b 06                	mov    (%esi),%eax
80101a30:	e8 52 f7 ff ff       	call   80101187 <iget>
80101a35:	eb 05                	jmp    80101a3c <dirlookup+0x8c>
  return 0;
80101a37:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101a3c:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101a3f:	5b                   	pop    %ebx
80101a40:	5e                   	pop    %esi
80101a41:	5f                   	pop    %edi
80101a42:	5d                   	pop    %ebp
80101a43:	c3                   	ret    

80101a44 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80101a44:	55                   	push   %ebp
80101a45:	89 e5                	mov    %esp,%ebp
80101a47:	57                   	push   %edi
80101a48:	56                   	push   %esi
80101a49:	53                   	push   %ebx
80101a4a:	83 ec 1c             	sub    $0x1c,%esp
80101a4d:	89 c6                	mov    %eax,%esi
80101a4f:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101a52:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  struct inode *ip, *next;

  if(*path == '/')
80101a55:	80 38 2f             	cmpb   $0x2f,(%eax)
80101a58:	74 17                	je     80101a71 <namex+0x2d>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
80101a5a:	e8 d1 17 00 00       	call   80103230 <myproc>
80101a5f:	83 ec 0c             	sub    $0xc,%esp
80101a62:	ff 70 68             	pushl  0x68(%eax)
80101a65:	e8 e7 fa ff ff       	call   80101551 <idup>
80101a6a:	89 c3                	mov    %eax,%ebx
80101a6c:	83 c4 10             	add    $0x10,%esp
80101a6f:	eb 53                	jmp    80101ac4 <namex+0x80>
    ip = iget(ROOTDEV, ROOTINO);
80101a71:	ba 01 00 00 00       	mov    $0x1,%edx
80101a76:	b8 01 00 00 00       	mov    $0x1,%eax
80101a7b:	e8 07 f7 ff ff       	call   80101187 <iget>
80101a80:	89 c3                	mov    %eax,%ebx
80101a82:	eb 40                	jmp    80101ac4 <namex+0x80>

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
      iunlockput(ip);
80101a84:	83 ec 0c             	sub    $0xc,%esp
80101a87:	53                   	push   %ebx
80101a88:	e8 9b fc ff ff       	call   80101728 <iunlockput>
      return 0;
80101a8d:	83 c4 10             	add    $0x10,%esp
80101a90:	bb 00 00 00 00       	mov    $0x0,%ebx
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
80101a95:	89 d8                	mov    %ebx,%eax
80101a97:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101a9a:	5b                   	pop    %ebx
80101a9b:	5e                   	pop    %esi
80101a9c:	5f                   	pop    %edi
80101a9d:	5d                   	pop    %ebp
80101a9e:	c3                   	ret    
    if((next = dirlookup(ip, name, 0)) == 0){
80101a9f:	83 ec 04             	sub    $0x4,%esp
80101aa2:	6a 00                	push   $0x0
80101aa4:	ff 75 e4             	pushl  -0x1c(%ebp)
80101aa7:	53                   	push   %ebx
80101aa8:	e8 03 ff ff ff       	call   801019b0 <dirlookup>
80101aad:	89 c7                	mov    %eax,%edi
80101aaf:	83 c4 10             	add    $0x10,%esp
80101ab2:	85 c0                	test   %eax,%eax
80101ab4:	74 4a                	je     80101b00 <namex+0xbc>
    iunlockput(ip);
80101ab6:	83 ec 0c             	sub    $0xc,%esp
80101ab9:	53                   	push   %ebx
80101aba:	e8 69 fc ff ff       	call   80101728 <iunlockput>
    ip = next;
80101abf:	83 c4 10             	add    $0x10,%esp
80101ac2:	89 fb                	mov    %edi,%ebx
  while((path = skipelem(path, name)) != 0){
80101ac4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101ac7:	89 f0                	mov    %esi,%eax
80101ac9:	e8 77 f4 ff ff       	call   80100f45 <skipelem>
80101ace:	89 c6                	mov    %eax,%esi
80101ad0:	85 c0                	test   %eax,%eax
80101ad2:	74 3c                	je     80101b10 <namex+0xcc>
    ilock(ip);
80101ad4:	83 ec 0c             	sub    $0xc,%esp
80101ad7:	53                   	push   %ebx
80101ad8:	e8 a4 fa ff ff       	call   80101581 <ilock>
    if(ip->type != T_DIR){
80101add:	83 c4 10             	add    $0x10,%esp
80101ae0:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80101ae5:	75 9d                	jne    80101a84 <namex+0x40>
    if(nameiparent && *path == '\0'){
80101ae7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101aeb:	74 b2                	je     80101a9f <namex+0x5b>
80101aed:	80 3e 00             	cmpb   $0x0,(%esi)
80101af0:	75 ad                	jne    80101a9f <namex+0x5b>
      iunlock(ip);
80101af2:	83 ec 0c             	sub    $0xc,%esp
80101af5:	53                   	push   %ebx
80101af6:	e8 48 fb ff ff       	call   80101643 <iunlock>
      return ip;
80101afb:	83 c4 10             	add    $0x10,%esp
80101afe:	eb 95                	jmp    80101a95 <namex+0x51>
      iunlockput(ip);
80101b00:	83 ec 0c             	sub    $0xc,%esp
80101b03:	53                   	push   %ebx
80101b04:	e8 1f fc ff ff       	call   80101728 <iunlockput>
      return 0;
80101b09:	83 c4 10             	add    $0x10,%esp
80101b0c:	89 fb                	mov    %edi,%ebx
80101b0e:	eb 85                	jmp    80101a95 <namex+0x51>
  if(nameiparent){
80101b10:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101b14:	0f 84 7b ff ff ff    	je     80101a95 <namex+0x51>
    iput(ip);
80101b1a:	83 ec 0c             	sub    $0xc,%esp
80101b1d:	53                   	push   %ebx
80101b1e:	e8 65 fb ff ff       	call   80101688 <iput>
    return 0;
80101b23:	83 c4 10             	add    $0x10,%esp
80101b26:	bb 00 00 00 00       	mov    $0x0,%ebx
80101b2b:	e9 65 ff ff ff       	jmp    80101a95 <namex+0x51>

80101b30 <dirlink>:
{
80101b30:	55                   	push   %ebp
80101b31:	89 e5                	mov    %esp,%ebp
80101b33:	57                   	push   %edi
80101b34:	56                   	push   %esi
80101b35:	53                   	push   %ebx
80101b36:	83 ec 20             	sub    $0x20,%esp
80101b39:	8b 5d 08             	mov    0x8(%ebp),%ebx
80101b3c:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if((ip = dirlookup(dp, name, 0)) != 0){
80101b3f:	6a 00                	push   $0x0
80101b41:	57                   	push   %edi
80101b42:	53                   	push   %ebx
80101b43:	e8 68 fe ff ff       	call   801019b0 <dirlookup>
80101b48:	83 c4 10             	add    $0x10,%esp
80101b4b:	85 c0                	test   %eax,%eax
80101b4d:	75 2d                	jne    80101b7c <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101b4f:	b8 00 00 00 00       	mov    $0x0,%eax
80101b54:	89 c6                	mov    %eax,%esi
80101b56:	39 43 58             	cmp    %eax,0x58(%ebx)
80101b59:	76 41                	jbe    80101b9c <dirlink+0x6c>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101b5b:	6a 10                	push   $0x10
80101b5d:	50                   	push   %eax
80101b5e:	8d 45 d8             	lea    -0x28(%ebp),%eax
80101b61:	50                   	push   %eax
80101b62:	53                   	push   %ebx
80101b63:	e8 0b fc ff ff       	call   80101773 <readi>
80101b68:	83 c4 10             	add    $0x10,%esp
80101b6b:	83 f8 10             	cmp    $0x10,%eax
80101b6e:	75 1f                	jne    80101b8f <dirlink+0x5f>
    if(de.inum == 0)
80101b70:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101b75:	74 25                	je     80101b9c <dirlink+0x6c>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101b77:	8d 46 10             	lea    0x10(%esi),%eax
80101b7a:	eb d8                	jmp    80101b54 <dirlink+0x24>
    iput(ip);
80101b7c:	83 ec 0c             	sub    $0xc,%esp
80101b7f:	50                   	push   %eax
80101b80:	e8 03 fb ff ff       	call   80101688 <iput>
    return -1;
80101b85:	83 c4 10             	add    $0x10,%esp
80101b88:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101b8d:	eb 3d                	jmp    80101bcc <dirlink+0x9c>
      panic("dirlink read");
80101b8f:	83 ec 0c             	sub    $0xc,%esp
80101b92:	68 e8 66 10 80       	push   $0x801066e8
80101b97:	e8 ac e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101b9c:	83 ec 04             	sub    $0x4,%esp
80101b9f:	6a 0e                	push   $0xe
80101ba1:	57                   	push   %edi
80101ba2:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101ba5:	8d 45 da             	lea    -0x26(%ebp),%eax
80101ba8:	50                   	push   %eax
80101ba9:	e8 a0 22 00 00       	call   80103e4e <strncpy>
  de.inum = inum;
80101bae:	8b 45 10             	mov    0x10(%ebp),%eax
80101bb1:	66 89 45 d8          	mov    %ax,-0x28(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101bb5:	6a 10                	push   $0x10
80101bb7:	56                   	push   %esi
80101bb8:	57                   	push   %edi
80101bb9:	53                   	push   %ebx
80101bba:	e8 b1 fc ff ff       	call   80101870 <writei>
80101bbf:	83 c4 20             	add    $0x20,%esp
80101bc2:	83 f8 10             	cmp    $0x10,%eax
80101bc5:	75 0d                	jne    80101bd4 <dirlink+0xa4>
  return 0;
80101bc7:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101bcc:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101bcf:	5b                   	pop    %ebx
80101bd0:	5e                   	pop    %esi
80101bd1:	5f                   	pop    %edi
80101bd2:	5d                   	pop    %ebp
80101bd3:	c3                   	ret    
    panic("dirlink");
80101bd4:	83 ec 0c             	sub    $0xc,%esp
80101bd7:	68 14 6d 10 80       	push   $0x80106d14
80101bdc:	e8 67 e7 ff ff       	call   80100348 <panic>

80101be1 <namei>:

struct inode*
namei(char *path)
{
80101be1:	55                   	push   %ebp
80101be2:	89 e5                	mov    %esp,%ebp
80101be4:	83 ec 18             	sub    $0x18,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80101be7:	8d 4d ea             	lea    -0x16(%ebp),%ecx
80101bea:	ba 00 00 00 00       	mov    $0x0,%edx
80101bef:	8b 45 08             	mov    0x8(%ebp),%eax
80101bf2:	e8 4d fe ff ff       	call   80101a44 <namex>
}
80101bf7:	c9                   	leave  
80101bf8:	c3                   	ret    

80101bf9 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80101bf9:	55                   	push   %ebp
80101bfa:	89 e5                	mov    %esp,%ebp
80101bfc:	83 ec 08             	sub    $0x8,%esp
  return namex(path, 1, name);
80101bff:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80101c02:	ba 01 00 00 00       	mov    $0x1,%edx
80101c07:	8b 45 08             	mov    0x8(%ebp),%eax
80101c0a:	e8 35 fe ff ff       	call   80101a44 <namex>
}
80101c0f:	c9                   	leave  
80101c10:	c3                   	ret    

80101c11 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80101c11:	55                   	push   %ebp
80101c12:	89 e5                	mov    %esp,%ebp
80101c14:	89 c1                	mov    %eax,%ecx
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101c16:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101c1b:	ec                   	in     (%dx),%al
80101c1c:	89 c2                	mov    %eax,%edx
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY)
80101c1e:	83 e0 c0             	and    $0xffffffc0,%eax
80101c21:	3c 40                	cmp    $0x40,%al
80101c23:	75 f1                	jne    80101c16 <idewait+0x5>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80101c25:	85 c9                	test   %ecx,%ecx
80101c27:	74 0c                	je     80101c35 <idewait+0x24>
80101c29:	f6 c2 21             	test   $0x21,%dl
80101c2c:	75 0e                	jne    80101c3c <idewait+0x2b>
    return -1;
  return 0;
80101c2e:	b8 00 00 00 00       	mov    $0x0,%eax
80101c33:	eb 05                	jmp    80101c3a <idewait+0x29>
80101c35:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101c3a:	5d                   	pop    %ebp
80101c3b:	c3                   	ret    
    return -1;
80101c3c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101c41:	eb f7                	jmp    80101c3a <idewait+0x29>

80101c43 <idestart>:
}

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80101c43:	55                   	push   %ebp
80101c44:	89 e5                	mov    %esp,%ebp
80101c46:	56                   	push   %esi
80101c47:	53                   	push   %ebx
  if(b == 0)
80101c48:	85 c0                	test   %eax,%eax
80101c4a:	74 7d                	je     80101cc9 <idestart+0x86>
80101c4c:	89 c6                	mov    %eax,%esi
    panic("idestart");
  if(b->blockno >= FSSIZE)
80101c4e:	8b 58 08             	mov    0x8(%eax),%ebx
80101c51:	81 fb e7 03 00 00    	cmp    $0x3e7,%ebx
80101c57:	77 7d                	ja     80101cd6 <idestart+0x93>
  int read_cmd = (sector_per_block == 1) ? IDE_CMD_READ :  IDE_CMD_RDMUL;
  int write_cmd = (sector_per_block == 1) ? IDE_CMD_WRITE : IDE_CMD_WRMUL;

  if (sector_per_block > 7) panic("idestart");

  idewait(0);
80101c59:	b8 00 00 00 00       	mov    $0x0,%eax
80101c5e:	e8 ae ff ff ff       	call   80101c11 <idewait>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101c63:	b8 00 00 00 00       	mov    $0x0,%eax
80101c68:	ba f6 03 00 00       	mov    $0x3f6,%edx
80101c6d:	ee                   	out    %al,(%dx)
80101c6e:	b8 01 00 00 00       	mov    $0x1,%eax
80101c73:	ba f2 01 00 00       	mov    $0x1f2,%edx
80101c78:	ee                   	out    %al,(%dx)
80101c79:	ba f3 01 00 00       	mov    $0x1f3,%edx
80101c7e:	89 d8                	mov    %ebx,%eax
80101c80:	ee                   	out    %al,(%dx)
  outb(0x3f6, 0);  // generate interrupt
  outb(0x1f2, sector_per_block);  // number of sectors
  outb(0x1f3, sector & 0xff);
  outb(0x1f4, (sector >> 8) & 0xff);
80101c81:	89 d8                	mov    %ebx,%eax
80101c83:	c1 f8 08             	sar    $0x8,%eax
80101c86:	ba f4 01 00 00       	mov    $0x1f4,%edx
80101c8b:	ee                   	out    %al,(%dx)
  outb(0x1f5, (sector >> 16) & 0xff);
80101c8c:	89 d8                	mov    %ebx,%eax
80101c8e:	c1 f8 10             	sar    $0x10,%eax
80101c91:	ba f5 01 00 00       	mov    $0x1f5,%edx
80101c96:	ee                   	out    %al,(%dx)
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80101c97:	0f b6 46 04          	movzbl 0x4(%esi),%eax
80101c9b:	c1 e0 04             	shl    $0x4,%eax
80101c9e:	83 e0 10             	and    $0x10,%eax
80101ca1:	c1 fb 18             	sar    $0x18,%ebx
80101ca4:	83 e3 0f             	and    $0xf,%ebx
80101ca7:	09 d8                	or     %ebx,%eax
80101ca9:	83 c8 e0             	or     $0xffffffe0,%eax
80101cac:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101cb1:	ee                   	out    %al,(%dx)
  if(b->flags & B_DIRTY){
80101cb2:	f6 06 04             	testb  $0x4,(%esi)
80101cb5:	75 2c                	jne    80101ce3 <idestart+0xa0>
80101cb7:	b8 20 00 00 00       	mov    $0x20,%eax
80101cbc:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101cc1:	ee                   	out    %al,(%dx)
    outb(0x1f7, write_cmd);
    outsl(0x1f0, b->data, BSIZE/4);
  } else {
    outb(0x1f7, read_cmd);
  }
}
80101cc2:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101cc5:	5b                   	pop    %ebx
80101cc6:	5e                   	pop    %esi
80101cc7:	5d                   	pop    %ebp
80101cc8:	c3                   	ret    
    panic("idestart");
80101cc9:	83 ec 0c             	sub    $0xc,%esp
80101ccc:	68 4b 67 10 80       	push   $0x8010674b
80101cd1:	e8 72 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101cd6:	83 ec 0c             	sub    $0xc,%esp
80101cd9:	68 54 67 10 80       	push   $0x80106754
80101cde:	e8 65 e6 ff ff       	call   80100348 <panic>
80101ce3:	b8 30 00 00 00       	mov    $0x30,%eax
80101ce8:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101ced:	ee                   	out    %al,(%dx)
    outsl(0x1f0, b->data, BSIZE/4);
80101cee:	83 c6 5c             	add    $0x5c,%esi
  asm volatile("cld; rep outsl" :
80101cf1:	b9 80 00 00 00       	mov    $0x80,%ecx
80101cf6:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101cfb:	fc                   	cld    
80101cfc:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80101cfe:	eb c2                	jmp    80101cc2 <idestart+0x7f>

80101d00 <ideinit>:
{
80101d00:	55                   	push   %ebp
80101d01:	89 e5                	mov    %esp,%ebp
80101d03:	83 ec 10             	sub    $0x10,%esp
  initlock(&idelock, "ide");
80101d06:	68 66 67 10 80       	push   $0x80106766
80101d0b:	68 80 95 10 80       	push   $0x80109580
80101d10:	e8 32 1e 00 00       	call   80103b47 <initlock>
  ioapicenable(IRQ_IDE, ncpu - 1);
80101d15:	83 c4 08             	add    $0x8,%esp
80101d18:	a1 80 c6 16 80       	mov    0x8016c680,%eax
80101d1d:	83 e8 01             	sub    $0x1,%eax
80101d20:	50                   	push   %eax
80101d21:	6a 0e                	push   $0xe
80101d23:	e8 56 02 00 00       	call   80101f7e <ioapicenable>
  idewait(0);
80101d28:	b8 00 00 00 00       	mov    $0x0,%eax
80101d2d:	e8 df fe ff ff       	call   80101c11 <idewait>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101d32:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
80101d37:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101d3c:	ee                   	out    %al,(%dx)
  for(i=0; i<1000; i++){
80101d3d:	83 c4 10             	add    $0x10,%esp
80101d40:	b9 00 00 00 00       	mov    $0x0,%ecx
80101d45:	81 f9 e7 03 00 00    	cmp    $0x3e7,%ecx
80101d4b:	7f 19                	jg     80101d66 <ideinit+0x66>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101d4d:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101d52:	ec                   	in     (%dx),%al
    if(inb(0x1f7) != 0){
80101d53:	84 c0                	test   %al,%al
80101d55:	75 05                	jne    80101d5c <ideinit+0x5c>
  for(i=0; i<1000; i++){
80101d57:	83 c1 01             	add    $0x1,%ecx
80101d5a:	eb e9                	jmp    80101d45 <ideinit+0x45>
      havedisk1 = 1;
80101d5c:	c7 05 60 95 10 80 01 	movl   $0x1,0x80109560
80101d63:	00 00 00 
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101d66:	b8 e0 ff ff ff       	mov    $0xffffffe0,%eax
80101d6b:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101d70:	ee                   	out    %al,(%dx)
}
80101d71:	c9                   	leave  
80101d72:	c3                   	ret    

80101d73 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80101d73:	55                   	push   %ebp
80101d74:	89 e5                	mov    %esp,%ebp
80101d76:	57                   	push   %edi
80101d77:	53                   	push   %ebx
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80101d78:	83 ec 0c             	sub    $0xc,%esp
80101d7b:	68 80 95 10 80       	push   $0x80109580
80101d80:	e8 fe 1e 00 00       	call   80103c83 <acquire>

  if((b = idequeue) == 0){
80101d85:	8b 1d 64 95 10 80    	mov    0x80109564,%ebx
80101d8b:	83 c4 10             	add    $0x10,%esp
80101d8e:	85 db                	test   %ebx,%ebx
80101d90:	74 48                	je     80101dda <ideintr+0x67>
    release(&idelock);
    return;
  }
  idequeue = b->qnext;
80101d92:	8b 43 58             	mov    0x58(%ebx),%eax
80101d95:	a3 64 95 10 80       	mov    %eax,0x80109564

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101d9a:	f6 03 04             	testb  $0x4,(%ebx)
80101d9d:	74 4d                	je     80101dec <ideintr+0x79>
    insl(0x1f0, b->data, BSIZE/4);

  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80101d9f:	8b 03                	mov    (%ebx),%eax
80101da1:	83 c8 02             	or     $0x2,%eax
  b->flags &= ~B_DIRTY;
80101da4:	83 e0 fb             	and    $0xfffffffb,%eax
80101da7:	89 03                	mov    %eax,(%ebx)
  wakeup(b);
80101da9:	83 ec 0c             	sub    $0xc,%esp
80101dac:	53                   	push   %ebx
80101dad:	e8 a3 1a 00 00       	call   80103855 <wakeup>

  // Start disk on next buf in queue.
  if(idequeue != 0)
80101db2:	a1 64 95 10 80       	mov    0x80109564,%eax
80101db7:	83 c4 10             	add    $0x10,%esp
80101dba:	85 c0                	test   %eax,%eax
80101dbc:	74 05                	je     80101dc3 <ideintr+0x50>
    idestart(idequeue);
80101dbe:	e8 80 fe ff ff       	call   80101c43 <idestart>

  release(&idelock);
80101dc3:	83 ec 0c             	sub    $0xc,%esp
80101dc6:	68 80 95 10 80       	push   $0x80109580
80101dcb:	e8 18 1f 00 00       	call   80103ce8 <release>
80101dd0:	83 c4 10             	add    $0x10,%esp
}
80101dd3:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101dd6:	5b                   	pop    %ebx
80101dd7:	5f                   	pop    %edi
80101dd8:	5d                   	pop    %ebp
80101dd9:	c3                   	ret    
    release(&idelock);
80101dda:	83 ec 0c             	sub    $0xc,%esp
80101ddd:	68 80 95 10 80       	push   $0x80109580
80101de2:	e8 01 1f 00 00       	call   80103ce8 <release>
    return;
80101de7:	83 c4 10             	add    $0x10,%esp
80101dea:	eb e7                	jmp    80101dd3 <ideintr+0x60>
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101dec:	b8 01 00 00 00       	mov    $0x1,%eax
80101df1:	e8 1b fe ff ff       	call   80101c11 <idewait>
80101df6:	85 c0                	test   %eax,%eax
80101df8:	78 a5                	js     80101d9f <ideintr+0x2c>
    insl(0x1f0, b->data, BSIZE/4);
80101dfa:	8d 7b 5c             	lea    0x5c(%ebx),%edi
  asm volatile("cld; rep insl" :
80101dfd:	b9 80 00 00 00       	mov    $0x80,%ecx
80101e02:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101e07:	fc                   	cld    
80101e08:	f3 6d                	rep insl (%dx),%es:(%edi)
80101e0a:	eb 93                	jmp    80101d9f <ideintr+0x2c>

80101e0c <iderw>:
// Sync buf with disk.
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80101e0c:	55                   	push   %ebp
80101e0d:	89 e5                	mov    %esp,%ebp
80101e0f:	53                   	push   %ebx
80101e10:	83 ec 10             	sub    $0x10,%esp
80101e13:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct buf **pp;

  if(!holdingsleep(&b->lock))
80101e16:	8d 43 0c             	lea    0xc(%ebx),%eax
80101e19:	50                   	push   %eax
80101e1a:	e8 da 1c 00 00       	call   80103af9 <holdingsleep>
80101e1f:	83 c4 10             	add    $0x10,%esp
80101e22:	85 c0                	test   %eax,%eax
80101e24:	74 37                	je     80101e5d <iderw+0x51>
    panic("iderw: buf not locked");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80101e26:	8b 03                	mov    (%ebx),%eax
80101e28:	83 e0 06             	and    $0x6,%eax
80101e2b:	83 f8 02             	cmp    $0x2,%eax
80101e2e:	74 3a                	je     80101e6a <iderw+0x5e>
    panic("iderw: nothing to do");
  if(b->dev != 0 && !havedisk1)
80101e30:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80101e34:	74 09                	je     80101e3f <iderw+0x33>
80101e36:	83 3d 60 95 10 80 00 	cmpl   $0x0,0x80109560
80101e3d:	74 38                	je     80101e77 <iderw+0x6b>
    panic("iderw: ide disk 1 not present");

  acquire(&idelock);  //DOC:acquire-lock
80101e3f:	83 ec 0c             	sub    $0xc,%esp
80101e42:	68 80 95 10 80       	push   $0x80109580
80101e47:	e8 37 1e 00 00       	call   80103c83 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e4c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e53:	83 c4 10             	add    $0x10,%esp
80101e56:	ba 64 95 10 80       	mov    $0x80109564,%edx
80101e5b:	eb 2a                	jmp    80101e87 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e5d:	83 ec 0c             	sub    $0xc,%esp
80101e60:	68 6a 67 10 80       	push   $0x8010676a
80101e65:	e8 de e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	68 80 67 10 80       	push   $0x80106780
80101e72:	e8 d1 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e77:	83 ec 0c             	sub    $0xc,%esp
80101e7a:	68 95 67 10 80       	push   $0x80106795
80101e7f:	e8 c4 e4 ff ff       	call   80100348 <panic>
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e84:	8d 50 58             	lea    0x58(%eax),%edx
80101e87:	8b 02                	mov    (%edx),%eax
80101e89:	85 c0                	test   %eax,%eax
80101e8b:	75 f7                	jne    80101e84 <iderw+0x78>
    ;
  *pp = b;
80101e8d:	89 1a                	mov    %ebx,(%edx)

  // Start disk if necessary.
  if(idequeue == b)
80101e8f:	39 1d 64 95 10 80    	cmp    %ebx,0x80109564
80101e95:	75 1a                	jne    80101eb1 <iderw+0xa5>
    idestart(b);
80101e97:	89 d8                	mov    %ebx,%eax
80101e99:	e8 a5 fd ff ff       	call   80101c43 <idestart>
80101e9e:	eb 11                	jmp    80101eb1 <iderw+0xa5>

  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
    sleep(b, &idelock);
80101ea0:	83 ec 08             	sub    $0x8,%esp
80101ea3:	68 80 95 10 80       	push   $0x80109580
80101ea8:	53                   	push   %ebx
80101ea9:	e8 42 18 00 00       	call   801036f0 <sleep>
80101eae:	83 c4 10             	add    $0x10,%esp
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80101eb1:	8b 03                	mov    (%ebx),%eax
80101eb3:	83 e0 06             	and    $0x6,%eax
80101eb6:	83 f8 02             	cmp    $0x2,%eax
80101eb9:	75 e5                	jne    80101ea0 <iderw+0x94>
  }


  release(&idelock);
80101ebb:	83 ec 0c             	sub    $0xc,%esp
80101ebe:	68 80 95 10 80       	push   $0x80109580
80101ec3:	e8 20 1e 00 00       	call   80103ce8 <release>
}
80101ec8:	83 c4 10             	add    $0x10,%esp
80101ecb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101ece:	c9                   	leave  
80101ecf:	c3                   	ret    

80101ed0 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80101ed0:	55                   	push   %ebp
80101ed1:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80101ed3:	8b 15 b4 bf 16 80    	mov    0x8016bfb4,%edx
80101ed9:	89 02                	mov    %eax,(%edx)
  return ioapic->data;
80101edb:	a1 b4 bf 16 80       	mov    0x8016bfb4,%eax
80101ee0:	8b 40 10             	mov    0x10(%eax),%eax
}
80101ee3:	5d                   	pop    %ebp
80101ee4:	c3                   	ret    

80101ee5 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80101ee5:	55                   	push   %ebp
80101ee6:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80101ee8:	8b 0d b4 bf 16 80    	mov    0x8016bfb4,%ecx
80101eee:	89 01                	mov    %eax,(%ecx)
  ioapic->data = data;
80101ef0:	a1 b4 bf 16 80       	mov    0x8016bfb4,%eax
80101ef5:	89 50 10             	mov    %edx,0x10(%eax)
}
80101ef8:	5d                   	pop    %ebp
80101ef9:	c3                   	ret    

80101efa <ioapicinit>:

void
ioapicinit(void)
{
80101efa:	55                   	push   %ebp
80101efb:	89 e5                	mov    %esp,%ebp
80101efd:	57                   	push   %edi
80101efe:	56                   	push   %esi
80101eff:	53                   	push   %ebx
80101f00:	83 ec 0c             	sub    $0xc,%esp
  int i, id, maxintr;

  ioapic = (volatile struct ioapic*)IOAPIC;
80101f03:	c7 05 b4 bf 16 80 00 	movl   $0xfec00000,0x8016bfb4
80101f0a:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80101f0d:	b8 01 00 00 00       	mov    $0x1,%eax
80101f12:	e8 b9 ff ff ff       	call   80101ed0 <ioapicread>
80101f17:	c1 e8 10             	shr    $0x10,%eax
80101f1a:	0f b6 f8             	movzbl %al,%edi
  id = ioapicread(REG_ID) >> 24;
80101f1d:	b8 00 00 00 00       	mov    $0x0,%eax
80101f22:	e8 a9 ff ff ff       	call   80101ed0 <ioapicread>
80101f27:	c1 e8 18             	shr    $0x18,%eax
  if(id != ioapicid)
80101f2a:	0f b6 15 e0 c0 16 80 	movzbl 0x8016c0e0,%edx
80101f31:	39 c2                	cmp    %eax,%edx
80101f33:	75 07                	jne    80101f3c <ioapicinit+0x42>
{
80101f35:	bb 00 00 00 00       	mov    $0x0,%ebx
80101f3a:	eb 36                	jmp    80101f72 <ioapicinit+0x78>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80101f3c:	83 ec 0c             	sub    $0xc,%esp
80101f3f:	68 b4 67 10 80       	push   $0x801067b4
80101f44:	e8 c2 e6 ff ff       	call   8010060b <cprintf>
80101f49:	83 c4 10             	add    $0x10,%esp
80101f4c:	eb e7                	jmp    80101f35 <ioapicinit+0x3b>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80101f4e:	8d 53 20             	lea    0x20(%ebx),%edx
80101f51:	81 ca 00 00 01 00    	or     $0x10000,%edx
80101f57:	8d 74 1b 10          	lea    0x10(%ebx,%ebx,1),%esi
80101f5b:	89 f0                	mov    %esi,%eax
80101f5d:	e8 83 ff ff ff       	call   80101ee5 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80101f62:	8d 46 01             	lea    0x1(%esi),%eax
80101f65:	ba 00 00 00 00       	mov    $0x0,%edx
80101f6a:	e8 76 ff ff ff       	call   80101ee5 <ioapicwrite>
  for(i = 0; i <= maxintr; i++){
80101f6f:	83 c3 01             	add    $0x1,%ebx
80101f72:	39 fb                	cmp    %edi,%ebx
80101f74:	7e d8                	jle    80101f4e <ioapicinit+0x54>
  }
}
80101f76:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101f79:	5b                   	pop    %ebx
80101f7a:	5e                   	pop    %esi
80101f7b:	5f                   	pop    %edi
80101f7c:	5d                   	pop    %ebp
80101f7d:	c3                   	ret    

80101f7e <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80101f7e:	55                   	push   %ebp
80101f7f:	89 e5                	mov    %esp,%ebp
80101f81:	53                   	push   %ebx
80101f82:	8b 45 08             	mov    0x8(%ebp),%eax
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80101f85:	8d 50 20             	lea    0x20(%eax),%edx
80101f88:	8d 5c 00 10          	lea    0x10(%eax,%eax,1),%ebx
80101f8c:	89 d8                	mov    %ebx,%eax
80101f8e:	e8 52 ff ff ff       	call   80101ee5 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80101f93:	8b 55 0c             	mov    0xc(%ebp),%edx
80101f96:	c1 e2 18             	shl    $0x18,%edx
80101f99:	8d 43 01             	lea    0x1(%ebx),%eax
80101f9c:	e8 44 ff ff ff       	call   80101ee5 <ioapicwrite>
}
80101fa1:	5b                   	pop    %ebx
80101fa2:	5d                   	pop    %ebp
80101fa3:	c3                   	ret    

80101fa4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80101fa4:	55                   	push   %ebp
80101fa5:	89 e5                	mov    %esp,%ebp
80101fa7:	53                   	push   %ebx
80101fa8:	83 ec 04             	sub    $0x4,%esp
80101fab:	8b 5d 08             	mov    0x8(%ebp),%ebx
  //FRAMES[V2P(v)>>12] = -1;
  struct run *r;
  //cprintf("***************kfree phy frame: %d\n", V2P(v)>>12);
  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80101fae:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
80101fb4:	75 4c                	jne    80102002 <kfree+0x5e>
80101fb6:	81 fb 28 cf 35 80    	cmp    $0x8035cf28,%ebx
80101fbc:	72 44                	jb     80102002 <kfree+0x5e>
80101fbe:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80101fc4:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80101fc9:	77 37                	ja     80102002 <kfree+0x5e>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80101fcb:	83 ec 04             	sub    $0x4,%esp
80101fce:	68 00 10 00 00       	push   $0x1000
80101fd3:	6a 01                	push   $0x1
80101fd5:	53                   	push   %ebx
80101fd6:	e8 54 1d 00 00       	call   80103d2f <memset>

  if(kmem.use_lock)
80101fdb:	83 c4 10             	add    $0x10,%esp
80101fde:	83 3d f4 bf 16 80 00 	cmpl   $0x0,0x8016bff4
80101fe5:	75 28                	jne    8010200f <kfree+0x6b>
    acquire(&kmem.lock);
  r = (struct run*)v;
  r->next = kmem.freelist;
80101fe7:	a1 f8 bf 16 80       	mov    0x8016bff8,%eax
80101fec:	89 03                	mov    %eax,(%ebx)
  kmem.freelist = r;
80101fee:	89 1d f8 bf 16 80    	mov    %ebx,0x8016bff8
  if(kmem.use_lock)
80101ff4:	83 3d f4 bf 16 80 00 	cmpl   $0x0,0x8016bff4
80101ffb:	75 24                	jne    80102021 <kfree+0x7d>
    release(&kmem.lock);
}
80101ffd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102000:	c9                   	leave  
80102001:	c3                   	ret    
    panic("kfree");
80102002:	83 ec 0c             	sub    $0xc,%esp
80102005:	68 e6 67 10 80       	push   $0x801067e6
8010200a:	e8 39 e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
8010200f:	83 ec 0c             	sub    $0xc,%esp
80102012:	68 c0 bf 16 80       	push   $0x8016bfc0
80102017:	e8 67 1c 00 00       	call   80103c83 <acquire>
8010201c:	83 c4 10             	add    $0x10,%esp
8010201f:	eb c6                	jmp    80101fe7 <kfree+0x43>
    release(&kmem.lock);
80102021:	83 ec 0c             	sub    $0xc,%esp
80102024:	68 c0 bf 16 80       	push   $0x8016bfc0
80102029:	e8 ba 1c 00 00       	call   80103ce8 <release>
8010202e:	83 c4 10             	add    $0x10,%esp
}
80102031:	eb ca                	jmp    80101ffd <kfree+0x59>

80102033 <freerange>:
{
80102033:	55                   	push   %ebp
80102034:	89 e5                	mov    %esp,%ebp
80102036:	56                   	push   %esi
80102037:	53                   	push   %ebx
80102038:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  p = (char*)PGROUNDUP((uint)vstart);
8010203b:	8b 45 08             	mov    0x8(%ebp),%eax
8010203e:	05 ff 0f 00 00       	add    $0xfff,%eax
80102043:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE){
80102048:	eb 02                	jmp    8010204c <freerange+0x19>
{
8010204a:	89 f0                	mov    %esi,%eax
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE){
8010204c:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
80102052:	39 de                	cmp    %ebx,%esi
80102054:	77 13                	ja     80102069 <freerange+0x36>
    if((V2P(p)>>12)%2 == 0) continue;
80102056:	f6 c4 10             	test   $0x10,%ah
80102059:	74 ef                	je     8010204a <freerange+0x17>
    kfree(p);
8010205b:	83 ec 0c             	sub    $0xc,%esp
8010205e:	50                   	push   %eax
8010205f:	e8 40 ff ff ff       	call   80101fa4 <kfree>
80102064:	83 c4 10             	add    $0x10,%esp
80102067:	eb e1                	jmp    8010204a <freerange+0x17>
}
80102069:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010206c:	5b                   	pop    %ebx
8010206d:	5e                   	pop    %esi
8010206e:	5d                   	pop    %ebp
8010206f:	c3                   	ret    

80102070 <kinit1>:
{
80102070:	55                   	push   %ebp
80102071:	89 e5                	mov    %esp,%ebp
80102073:	83 ec 10             	sub    $0x10,%esp
  initlock(&kmem.lock, "kmem");
80102076:	68 ec 67 10 80       	push   $0x801067ec
8010207b:	68 c0 bf 16 80       	push   $0x8016bfc0
80102080:	e8 c2 1a 00 00       	call   80103b47 <initlock>
  kmem.use_lock = 0;
80102085:	c7 05 f4 bf 16 80 00 	movl   $0x0,0x8016bff4
8010208c:	00 00 00 
  freerange(vstart, vend);
8010208f:	83 c4 08             	add    $0x8,%esp
80102092:	ff 75 0c             	pushl  0xc(%ebp)
80102095:	ff 75 08             	pushl  0x8(%ebp)
80102098:	e8 96 ff ff ff       	call   80102033 <freerange>
}
8010209d:	83 c4 10             	add    $0x10,%esp
801020a0:	c9                   	leave  
801020a1:	c3                   	ret    

801020a2 <kinit2>:
{
801020a2:	55                   	push   %ebp
801020a3:	89 e5                	mov    %esp,%ebp
801020a5:	83 ec 10             	sub    $0x10,%esp
  freerange(vstart, vend);
801020a8:	ff 75 0c             	pushl  0xc(%ebp)
801020ab:	ff 75 08             	pushl  0x8(%ebp)
801020ae:	e8 80 ff ff ff       	call   80102033 <freerange>
  kmem.use_lock = 1;
801020b3:	c7 05 f4 bf 16 80 01 	movl   $0x1,0x8016bff4
801020ba:	00 00 00 
}
801020bd:	83 c4 10             	add    $0x10,%esp
801020c0:	c9                   	leave  
801020c1:	c3                   	ret    

801020c2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
801020c2:	55                   	push   %ebp
801020c3:	89 e5                	mov    %esp,%ebp
801020c5:	53                   	push   %ebx
801020c6:	83 ec 04             	sub    $0x4,%esp
  //cprintf("***************************inside kalloc\n");
  struct run *r;

  if(kmem.use_lock)
801020c9:	83 3d f4 bf 16 80 00 	cmpl   $0x0,0x8016bff4
801020d0:	75 54                	jne    80102126 <kalloc+0x64>
    acquire(&kmem.lock);
  r = kmem.freelist;
801020d2:	8b 1d f8 bf 16 80    	mov    0x8016bff8,%ebx
  if(r)
801020d8:	85 db                	test   %ebx,%ebx
801020da:	74 07                	je     801020e3 <kalloc+0x21>
    kmem.freelist = r->next;
801020dc:	8b 03                	mov    (%ebx),%eax
801020de:	a3 f8 bf 16 80       	mov    %eax,0x8016bff8
  if(kmem.use_lock)
801020e3:	83 3d f4 bf 16 80 00 	cmpl   $0x0,0x8016bff4
801020ea:	75 4c                	jne    80102138 <kalloc+0x76>
    release(&kmem.lock);
  //cprintf("***************kalloc phy frame: %d\n", V2P((char*)r)>>12);
  FRAMES[V2P((char*)r)>>12] = -2;
801020ec:	8d 93 00 00 00 80    	lea    -0x80000000(%ebx),%edx
801020f2:	c1 ea 0c             	shr    $0xc,%edx
801020f5:	c7 04 95 20 ef 10 80 	movl   $0xfffffffe,-0x7fef10e0(,%edx,4)
801020fc:	fe ff ff ff 
  log_frames[log_index]=V2P((char*)r)>>12;
80102100:	a1 2c 99 14 80       	mov    0x8014992c,%eax
80102105:	89 14 85 40 99 14 80 	mov    %edx,-0x7feb66c0(,%eax,4)
  log_pids[log_index]=-2;
8010210c:	c7 04 85 40 99 15 80 	movl   $0xfffffffe,-0x7fea66c0(,%eax,4)
80102113:	fe ff ff ff 
  log_index++;
80102117:	83 c0 01             	add    $0x1,%eax
8010211a:	a3 2c 99 14 80       	mov    %eax,0x8014992c
  return (char*)r;
}
8010211f:	89 d8                	mov    %ebx,%eax
80102121:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102124:	c9                   	leave  
80102125:	c3                   	ret    
    acquire(&kmem.lock);
80102126:	83 ec 0c             	sub    $0xc,%esp
80102129:	68 c0 bf 16 80       	push   $0x8016bfc0
8010212e:	e8 50 1b 00 00       	call   80103c83 <acquire>
80102133:	83 c4 10             	add    $0x10,%esp
80102136:	eb 9a                	jmp    801020d2 <kalloc+0x10>
    release(&kmem.lock);
80102138:	83 ec 0c             	sub    $0xc,%esp
8010213b:	68 c0 bf 16 80       	push   $0x8016bfc0
80102140:	e8 a3 1b 00 00       	call   80103ce8 <release>
80102145:	83 c4 10             	add    $0x10,%esp
80102148:	eb a2                	jmp    801020ec <kalloc+0x2a>

8010214a <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
8010214a:	55                   	push   %ebp
8010214b:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010214d:	ba 64 00 00 00       	mov    $0x64,%edx
80102152:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
80102153:	a8 01                	test   $0x1,%al
80102155:	0f 84 b5 00 00 00    	je     80102210 <kbdgetc+0xc6>
8010215b:	ba 60 00 00 00       	mov    $0x60,%edx
80102160:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
80102161:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
80102164:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
8010216a:	74 5c                	je     801021c8 <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
8010216c:	84 c0                	test   %al,%al
8010216e:	78 66                	js     801021d6 <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
80102170:	8b 0d b4 95 10 80    	mov    0x801095b4,%ecx
80102176:	f6 c1 40             	test   $0x40,%cl
80102179:	74 0f                	je     8010218a <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
8010217b:	83 c8 80             	or     $0xffffff80,%eax
8010217e:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
80102181:	83 e1 bf             	and    $0xffffffbf,%ecx
80102184:	89 0d b4 95 10 80    	mov    %ecx,0x801095b4
  }

  shift |= shiftcode[data];
8010218a:	0f b6 8a 20 69 10 80 	movzbl -0x7fef96e0(%edx),%ecx
80102191:	0b 0d b4 95 10 80    	or     0x801095b4,%ecx
  shift ^= togglecode[data];
80102197:	0f b6 82 20 68 10 80 	movzbl -0x7fef97e0(%edx),%eax
8010219e:	31 c1                	xor    %eax,%ecx
801021a0:	89 0d b4 95 10 80    	mov    %ecx,0x801095b4
  c = charcode[shift & (CTL | SHIFT)][data];
801021a6:	89 c8                	mov    %ecx,%eax
801021a8:	83 e0 03             	and    $0x3,%eax
801021ab:	8b 04 85 00 68 10 80 	mov    -0x7fef9800(,%eax,4),%eax
801021b2:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
801021b6:	f6 c1 08             	test   $0x8,%cl
801021b9:	74 19                	je     801021d4 <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
801021bb:	8d 50 9f             	lea    -0x61(%eax),%edx
801021be:	83 fa 19             	cmp    $0x19,%edx
801021c1:	77 40                	ja     80102203 <kbdgetc+0xb9>
      c += 'A' - 'a';
801021c3:	83 e8 20             	sub    $0x20,%eax
801021c6:	eb 0c                	jmp    801021d4 <kbdgetc+0x8a>
    shift |= E0ESC;
801021c8:	83 0d b4 95 10 80 40 	orl    $0x40,0x801095b4
    return 0;
801021cf:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
801021d4:	5d                   	pop    %ebp
801021d5:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
801021d6:	8b 0d b4 95 10 80    	mov    0x801095b4,%ecx
801021dc:	f6 c1 40             	test   $0x40,%cl
801021df:	75 05                	jne    801021e6 <kbdgetc+0x9c>
801021e1:	89 c2                	mov    %eax,%edx
801021e3:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
801021e6:	0f b6 82 20 69 10 80 	movzbl -0x7fef96e0(%edx),%eax
801021ed:	83 c8 40             	or     $0x40,%eax
801021f0:	0f b6 c0             	movzbl %al,%eax
801021f3:	f7 d0                	not    %eax
801021f5:	21 c8                	and    %ecx,%eax
801021f7:	a3 b4 95 10 80       	mov    %eax,0x801095b4
    return 0;
801021fc:	b8 00 00 00 00       	mov    $0x0,%eax
80102201:	eb d1                	jmp    801021d4 <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
80102203:	8d 50 bf             	lea    -0x41(%eax),%edx
80102206:	83 fa 19             	cmp    $0x19,%edx
80102209:	77 c9                	ja     801021d4 <kbdgetc+0x8a>
      c += 'a' - 'A';
8010220b:	83 c0 20             	add    $0x20,%eax
  return c;
8010220e:	eb c4                	jmp    801021d4 <kbdgetc+0x8a>
    return -1;
80102210:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102215:	eb bd                	jmp    801021d4 <kbdgetc+0x8a>

80102217 <kbdintr>:

void
kbdintr(void)
{
80102217:	55                   	push   %ebp
80102218:	89 e5                	mov    %esp,%ebp
8010221a:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
8010221d:	68 4a 21 10 80       	push   $0x8010214a
80102222:	e8 17 e5 ff ff       	call   8010073e <consoleintr>
}
80102227:	83 c4 10             	add    $0x10,%esp
8010222a:	c9                   	leave  
8010222b:	c3                   	ret    

8010222c <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
8010222c:	55                   	push   %ebp
8010222d:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
8010222f:	8b 0d fc bf 16 80    	mov    0x8016bffc,%ecx
80102235:	8d 04 81             	lea    (%ecx,%eax,4),%eax
80102238:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
8010223a:	a1 fc bf 16 80       	mov    0x8016bffc,%eax
8010223f:	8b 40 20             	mov    0x20(%eax),%eax
}
80102242:	5d                   	pop    %ebp
80102243:	c3                   	ret    

80102244 <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
80102244:	55                   	push   %ebp
80102245:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102247:	ba 70 00 00 00       	mov    $0x70,%edx
8010224c:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010224d:	ba 71 00 00 00       	mov    $0x71,%edx
80102252:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
80102253:	0f b6 c0             	movzbl %al,%eax
}
80102256:	5d                   	pop    %ebp
80102257:	c3                   	ret    

80102258 <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
80102258:	55                   	push   %ebp
80102259:	89 e5                	mov    %esp,%ebp
8010225b:	53                   	push   %ebx
8010225c:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
8010225e:	b8 00 00 00 00       	mov    $0x0,%eax
80102263:	e8 dc ff ff ff       	call   80102244 <cmos_read>
80102268:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
8010226a:	b8 02 00 00 00       	mov    $0x2,%eax
8010226f:	e8 d0 ff ff ff       	call   80102244 <cmos_read>
80102274:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
80102277:	b8 04 00 00 00       	mov    $0x4,%eax
8010227c:	e8 c3 ff ff ff       	call   80102244 <cmos_read>
80102281:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
80102284:	b8 07 00 00 00       	mov    $0x7,%eax
80102289:	e8 b6 ff ff ff       	call   80102244 <cmos_read>
8010228e:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
80102291:	b8 08 00 00 00       	mov    $0x8,%eax
80102296:	e8 a9 ff ff ff       	call   80102244 <cmos_read>
8010229b:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
8010229e:	b8 09 00 00 00       	mov    $0x9,%eax
801022a3:	e8 9c ff ff ff       	call   80102244 <cmos_read>
801022a8:	89 43 14             	mov    %eax,0x14(%ebx)
}
801022ab:	5b                   	pop    %ebx
801022ac:	5d                   	pop    %ebp
801022ad:	c3                   	ret    

801022ae <lapicinit>:
  if(!lapic)
801022ae:	83 3d fc bf 16 80 00 	cmpl   $0x0,0x8016bffc
801022b5:	0f 84 fb 00 00 00    	je     801023b6 <lapicinit+0x108>
{
801022bb:	55                   	push   %ebp
801022bc:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
801022be:	ba 3f 01 00 00       	mov    $0x13f,%edx
801022c3:	b8 3c 00 00 00       	mov    $0x3c,%eax
801022c8:	e8 5f ff ff ff       	call   8010222c <lapicw>
  lapicw(TDCR, X1);
801022cd:	ba 0b 00 00 00       	mov    $0xb,%edx
801022d2:	b8 f8 00 00 00       	mov    $0xf8,%eax
801022d7:	e8 50 ff ff ff       	call   8010222c <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
801022dc:	ba 20 00 02 00       	mov    $0x20020,%edx
801022e1:	b8 c8 00 00 00       	mov    $0xc8,%eax
801022e6:	e8 41 ff ff ff       	call   8010222c <lapicw>
  lapicw(TICR, 10000000);
801022eb:	ba 80 96 98 00       	mov    $0x989680,%edx
801022f0:	b8 e0 00 00 00       	mov    $0xe0,%eax
801022f5:	e8 32 ff ff ff       	call   8010222c <lapicw>
  lapicw(LINT0, MASKED);
801022fa:	ba 00 00 01 00       	mov    $0x10000,%edx
801022ff:	b8 d4 00 00 00       	mov    $0xd4,%eax
80102304:	e8 23 ff ff ff       	call   8010222c <lapicw>
  lapicw(LINT1, MASKED);
80102309:	ba 00 00 01 00       	mov    $0x10000,%edx
8010230e:	b8 d8 00 00 00       	mov    $0xd8,%eax
80102313:	e8 14 ff ff ff       	call   8010222c <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102318:	a1 fc bf 16 80       	mov    0x8016bffc,%eax
8010231d:	8b 40 30             	mov    0x30(%eax),%eax
80102320:	c1 e8 10             	shr    $0x10,%eax
80102323:	3c 03                	cmp    $0x3,%al
80102325:	77 7b                	ja     801023a2 <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102327:	ba 33 00 00 00       	mov    $0x33,%edx
8010232c:	b8 dc 00 00 00       	mov    $0xdc,%eax
80102331:	e8 f6 fe ff ff       	call   8010222c <lapicw>
  lapicw(ESR, 0);
80102336:	ba 00 00 00 00       	mov    $0x0,%edx
8010233b:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102340:	e8 e7 fe ff ff       	call   8010222c <lapicw>
  lapicw(ESR, 0);
80102345:	ba 00 00 00 00       	mov    $0x0,%edx
8010234a:	b8 a0 00 00 00       	mov    $0xa0,%eax
8010234f:	e8 d8 fe ff ff       	call   8010222c <lapicw>
  lapicw(EOI, 0);
80102354:	ba 00 00 00 00       	mov    $0x0,%edx
80102359:	b8 2c 00 00 00       	mov    $0x2c,%eax
8010235e:	e8 c9 fe ff ff       	call   8010222c <lapicw>
  lapicw(ICRHI, 0);
80102363:	ba 00 00 00 00       	mov    $0x0,%edx
80102368:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010236d:	e8 ba fe ff ff       	call   8010222c <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102372:	ba 00 85 08 00       	mov    $0x88500,%edx
80102377:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010237c:	e8 ab fe ff ff       	call   8010222c <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102381:	a1 fc bf 16 80       	mov    0x8016bffc,%eax
80102386:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
8010238c:	f6 c4 10             	test   $0x10,%ah
8010238f:	75 f0                	jne    80102381 <lapicinit+0xd3>
  lapicw(TPR, 0);
80102391:	ba 00 00 00 00       	mov    $0x0,%edx
80102396:	b8 20 00 00 00       	mov    $0x20,%eax
8010239b:	e8 8c fe ff ff       	call   8010222c <lapicw>
}
801023a0:	5d                   	pop    %ebp
801023a1:	c3                   	ret    
    lapicw(PCINT, MASKED);
801023a2:	ba 00 00 01 00       	mov    $0x10000,%edx
801023a7:	b8 d0 00 00 00       	mov    $0xd0,%eax
801023ac:	e8 7b fe ff ff       	call   8010222c <lapicw>
801023b1:	e9 71 ff ff ff       	jmp    80102327 <lapicinit+0x79>
801023b6:	f3 c3                	repz ret 

801023b8 <lapicid>:
{
801023b8:	55                   	push   %ebp
801023b9:	89 e5                	mov    %esp,%ebp
  if (!lapic)
801023bb:	a1 fc bf 16 80       	mov    0x8016bffc,%eax
801023c0:	85 c0                	test   %eax,%eax
801023c2:	74 08                	je     801023cc <lapicid+0x14>
  return lapic[ID] >> 24;
801023c4:	8b 40 20             	mov    0x20(%eax),%eax
801023c7:	c1 e8 18             	shr    $0x18,%eax
}
801023ca:	5d                   	pop    %ebp
801023cb:	c3                   	ret    
    return 0;
801023cc:	b8 00 00 00 00       	mov    $0x0,%eax
801023d1:	eb f7                	jmp    801023ca <lapicid+0x12>

801023d3 <lapiceoi>:
  if(lapic)
801023d3:	83 3d fc bf 16 80 00 	cmpl   $0x0,0x8016bffc
801023da:	74 14                	je     801023f0 <lapiceoi+0x1d>
{
801023dc:	55                   	push   %ebp
801023dd:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
801023df:	ba 00 00 00 00       	mov    $0x0,%edx
801023e4:	b8 2c 00 00 00       	mov    $0x2c,%eax
801023e9:	e8 3e fe ff ff       	call   8010222c <lapicw>
}
801023ee:	5d                   	pop    %ebp
801023ef:	c3                   	ret    
801023f0:	f3 c3                	repz ret 

801023f2 <microdelay>:
{
801023f2:	55                   	push   %ebp
801023f3:	89 e5                	mov    %esp,%ebp
}
801023f5:	5d                   	pop    %ebp
801023f6:	c3                   	ret    

801023f7 <lapicstartap>:
{
801023f7:	55                   	push   %ebp
801023f8:	89 e5                	mov    %esp,%ebp
801023fa:	57                   	push   %edi
801023fb:	56                   	push   %esi
801023fc:	53                   	push   %ebx
801023fd:	8b 75 08             	mov    0x8(%ebp),%esi
80102400:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102403:	b8 0f 00 00 00       	mov    $0xf,%eax
80102408:	ba 70 00 00 00       	mov    $0x70,%edx
8010240d:	ee                   	out    %al,(%dx)
8010240e:	b8 0a 00 00 00       	mov    $0xa,%eax
80102413:	ba 71 00 00 00       	mov    $0x71,%edx
80102418:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
80102419:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
80102420:	00 00 
  wrv[1] = addr >> 4;
80102422:	89 f8                	mov    %edi,%eax
80102424:	c1 e8 04             	shr    $0x4,%eax
80102427:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
8010242d:	c1 e6 18             	shl    $0x18,%esi
80102430:	89 f2                	mov    %esi,%edx
80102432:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102437:	e8 f0 fd ff ff       	call   8010222c <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
8010243c:	ba 00 c5 00 00       	mov    $0xc500,%edx
80102441:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102446:	e8 e1 fd ff ff       	call   8010222c <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
8010244b:	ba 00 85 00 00       	mov    $0x8500,%edx
80102450:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102455:	e8 d2 fd ff ff       	call   8010222c <lapicw>
  for(i = 0; i < 2; i++){
8010245a:	bb 00 00 00 00       	mov    $0x0,%ebx
8010245f:	eb 21                	jmp    80102482 <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
80102461:	89 f2                	mov    %esi,%edx
80102463:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102468:	e8 bf fd ff ff       	call   8010222c <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
8010246d:	89 fa                	mov    %edi,%edx
8010246f:	c1 ea 0c             	shr    $0xc,%edx
80102472:	80 ce 06             	or     $0x6,%dh
80102475:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010247a:	e8 ad fd ff ff       	call   8010222c <lapicw>
  for(i = 0; i < 2; i++){
8010247f:	83 c3 01             	add    $0x1,%ebx
80102482:	83 fb 01             	cmp    $0x1,%ebx
80102485:	7e da                	jle    80102461 <lapicstartap+0x6a>
}
80102487:	5b                   	pop    %ebx
80102488:	5e                   	pop    %esi
80102489:	5f                   	pop    %edi
8010248a:	5d                   	pop    %ebp
8010248b:	c3                   	ret    

8010248c <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
8010248c:	55                   	push   %ebp
8010248d:	89 e5                	mov    %esp,%ebp
8010248f:	57                   	push   %edi
80102490:	56                   	push   %esi
80102491:	53                   	push   %ebx
80102492:	83 ec 3c             	sub    $0x3c,%esp
80102495:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
80102498:	b8 0b 00 00 00       	mov    $0xb,%eax
8010249d:	e8 a2 fd ff ff       	call   80102244 <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
801024a2:	83 e0 04             	and    $0x4,%eax
801024a5:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
801024a7:	8d 45 d0             	lea    -0x30(%ebp),%eax
801024aa:	e8 a9 fd ff ff       	call   80102258 <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
801024af:	b8 0a 00 00 00       	mov    $0xa,%eax
801024b4:	e8 8b fd ff ff       	call   80102244 <cmos_read>
801024b9:	a8 80                	test   $0x80,%al
801024bb:	75 ea                	jne    801024a7 <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
801024bd:	8d 5d b8             	lea    -0x48(%ebp),%ebx
801024c0:	89 d8                	mov    %ebx,%eax
801024c2:	e8 91 fd ff ff       	call   80102258 <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
801024c7:	83 ec 04             	sub    $0x4,%esp
801024ca:	6a 18                	push   $0x18
801024cc:	53                   	push   %ebx
801024cd:	8d 45 d0             	lea    -0x30(%ebp),%eax
801024d0:	50                   	push   %eax
801024d1:	e8 9f 18 00 00       	call   80103d75 <memcmp>
801024d6:	83 c4 10             	add    $0x10,%esp
801024d9:	85 c0                	test   %eax,%eax
801024db:	75 ca                	jne    801024a7 <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
801024dd:	85 ff                	test   %edi,%edi
801024df:	0f 85 84 00 00 00    	jne    80102569 <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801024e5:	8b 55 d0             	mov    -0x30(%ebp),%edx
801024e8:	89 d0                	mov    %edx,%eax
801024ea:	c1 e8 04             	shr    $0x4,%eax
801024ed:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801024f0:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801024f3:	83 e2 0f             	and    $0xf,%edx
801024f6:	01 d0                	add    %edx,%eax
801024f8:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
801024fb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
801024fe:	89 d0                	mov    %edx,%eax
80102500:	c1 e8 04             	shr    $0x4,%eax
80102503:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102506:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102509:	83 e2 0f             	and    $0xf,%edx
8010250c:	01 d0                	add    %edx,%eax
8010250e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
80102511:	8b 55 d8             	mov    -0x28(%ebp),%edx
80102514:	89 d0                	mov    %edx,%eax
80102516:	c1 e8 04             	shr    $0x4,%eax
80102519:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010251c:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010251f:	83 e2 0f             	and    $0xf,%edx
80102522:	01 d0                	add    %edx,%eax
80102524:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
80102527:	8b 55 dc             	mov    -0x24(%ebp),%edx
8010252a:	89 d0                	mov    %edx,%eax
8010252c:	c1 e8 04             	shr    $0x4,%eax
8010252f:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102532:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102535:	83 e2 0f             	and    $0xf,%edx
80102538:	01 d0                	add    %edx,%eax
8010253a:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
8010253d:	8b 55 e0             	mov    -0x20(%ebp),%edx
80102540:	89 d0                	mov    %edx,%eax
80102542:	c1 e8 04             	shr    $0x4,%eax
80102545:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102548:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010254b:	83 e2 0f             	and    $0xf,%edx
8010254e:	01 d0                	add    %edx,%eax
80102550:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
80102553:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80102556:	89 d0                	mov    %edx,%eax
80102558:	c1 e8 04             	shr    $0x4,%eax
8010255b:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010255e:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102561:	83 e2 0f             	and    $0xf,%edx
80102564:	01 d0                	add    %edx,%eax
80102566:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
80102569:	8b 45 d0             	mov    -0x30(%ebp),%eax
8010256c:	89 06                	mov    %eax,(%esi)
8010256e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80102571:	89 46 04             	mov    %eax,0x4(%esi)
80102574:	8b 45 d8             	mov    -0x28(%ebp),%eax
80102577:	89 46 08             	mov    %eax,0x8(%esi)
8010257a:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010257d:	89 46 0c             	mov    %eax,0xc(%esi)
80102580:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102583:	89 46 10             	mov    %eax,0x10(%esi)
80102586:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102589:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
8010258c:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
80102593:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102596:	5b                   	pop    %ebx
80102597:	5e                   	pop    %esi
80102598:	5f                   	pop    %edi
80102599:	5d                   	pop    %ebp
8010259a:	c3                   	ret    

8010259b <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010259b:	55                   	push   %ebp
8010259c:	89 e5                	mov    %esp,%ebp
8010259e:	53                   	push   %ebx
8010259f:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
801025a2:	ff 35 34 c0 16 80    	pushl  0x8016c034
801025a8:	ff 35 44 c0 16 80    	pushl  0x8016c044
801025ae:	e8 b9 db ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
801025b3:	8b 58 5c             	mov    0x5c(%eax),%ebx
801025b6:	89 1d 48 c0 16 80    	mov    %ebx,0x8016c048
  for (i = 0; i < log.lh.n; i++) {
801025bc:	83 c4 10             	add    $0x10,%esp
801025bf:	ba 00 00 00 00       	mov    $0x0,%edx
801025c4:	eb 0e                	jmp    801025d4 <read_head+0x39>
    log.lh.block[i] = lh->block[i];
801025c6:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
801025ca:	89 0c 95 4c c0 16 80 	mov    %ecx,-0x7fe93fb4(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
801025d1:	83 c2 01             	add    $0x1,%edx
801025d4:	39 d3                	cmp    %edx,%ebx
801025d6:	7f ee                	jg     801025c6 <read_head+0x2b>
  }
  brelse(buf);
801025d8:	83 ec 0c             	sub    $0xc,%esp
801025db:	50                   	push   %eax
801025dc:	e8 f4 db ff ff       	call   801001d5 <brelse>
}
801025e1:	83 c4 10             	add    $0x10,%esp
801025e4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801025e7:	c9                   	leave  
801025e8:	c3                   	ret    

801025e9 <install_trans>:
{
801025e9:	55                   	push   %ebp
801025ea:	89 e5                	mov    %esp,%ebp
801025ec:	57                   	push   %edi
801025ed:	56                   	push   %esi
801025ee:	53                   	push   %ebx
801025ef:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
801025f2:	bb 00 00 00 00       	mov    $0x0,%ebx
801025f7:	eb 66                	jmp    8010265f <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801025f9:	89 d8                	mov    %ebx,%eax
801025fb:	03 05 34 c0 16 80    	add    0x8016c034,%eax
80102601:	83 c0 01             	add    $0x1,%eax
80102604:	83 ec 08             	sub    $0x8,%esp
80102607:	50                   	push   %eax
80102608:	ff 35 44 c0 16 80    	pushl  0x8016c044
8010260e:	e8 59 db ff ff       	call   8010016c <bread>
80102613:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
80102615:	83 c4 08             	add    $0x8,%esp
80102618:	ff 34 9d 4c c0 16 80 	pushl  -0x7fe93fb4(,%ebx,4)
8010261f:	ff 35 44 c0 16 80    	pushl  0x8016c044
80102625:	e8 42 db ff ff       	call   8010016c <bread>
8010262a:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
8010262c:	8d 57 5c             	lea    0x5c(%edi),%edx
8010262f:	8d 40 5c             	lea    0x5c(%eax),%eax
80102632:	83 c4 0c             	add    $0xc,%esp
80102635:	68 00 02 00 00       	push   $0x200
8010263a:	52                   	push   %edx
8010263b:	50                   	push   %eax
8010263c:	e8 69 17 00 00       	call   80103daa <memmove>
    bwrite(dbuf);  // write dst to disk
80102641:	89 34 24             	mov    %esi,(%esp)
80102644:	e8 51 db ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
80102649:	89 3c 24             	mov    %edi,(%esp)
8010264c:	e8 84 db ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
80102651:	89 34 24             	mov    %esi,(%esp)
80102654:	e8 7c db ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102659:	83 c3 01             	add    $0x1,%ebx
8010265c:	83 c4 10             	add    $0x10,%esp
8010265f:	39 1d 48 c0 16 80    	cmp    %ebx,0x8016c048
80102665:	7f 92                	jg     801025f9 <install_trans+0x10>
}
80102667:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010266a:	5b                   	pop    %ebx
8010266b:	5e                   	pop    %esi
8010266c:	5f                   	pop    %edi
8010266d:	5d                   	pop    %ebp
8010266e:	c3                   	ret    

8010266f <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
8010266f:	55                   	push   %ebp
80102670:	89 e5                	mov    %esp,%ebp
80102672:	53                   	push   %ebx
80102673:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102676:	ff 35 34 c0 16 80    	pushl  0x8016c034
8010267c:	ff 35 44 c0 16 80    	pushl  0x8016c044
80102682:	e8 e5 da ff ff       	call   8010016c <bread>
80102687:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
80102689:	8b 0d 48 c0 16 80    	mov    0x8016c048,%ecx
8010268f:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
80102692:	83 c4 10             	add    $0x10,%esp
80102695:	b8 00 00 00 00       	mov    $0x0,%eax
8010269a:	eb 0e                	jmp    801026aa <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
8010269c:	8b 14 85 4c c0 16 80 	mov    -0x7fe93fb4(,%eax,4),%edx
801026a3:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
801026a7:	83 c0 01             	add    $0x1,%eax
801026aa:	39 c1                	cmp    %eax,%ecx
801026ac:	7f ee                	jg     8010269c <write_head+0x2d>
  }
  bwrite(buf);
801026ae:	83 ec 0c             	sub    $0xc,%esp
801026b1:	53                   	push   %ebx
801026b2:	e8 e3 da ff ff       	call   8010019a <bwrite>
  brelse(buf);
801026b7:	89 1c 24             	mov    %ebx,(%esp)
801026ba:	e8 16 db ff ff       	call   801001d5 <brelse>
}
801026bf:	83 c4 10             	add    $0x10,%esp
801026c2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801026c5:	c9                   	leave  
801026c6:	c3                   	ret    

801026c7 <recover_from_log>:

static void
recover_from_log(void)
{
801026c7:	55                   	push   %ebp
801026c8:	89 e5                	mov    %esp,%ebp
801026ca:	83 ec 08             	sub    $0x8,%esp
  read_head();
801026cd:	e8 c9 fe ff ff       	call   8010259b <read_head>
  install_trans(); // if committed, copy from log to disk
801026d2:	e8 12 ff ff ff       	call   801025e9 <install_trans>
  log.lh.n = 0;
801026d7:	c7 05 48 c0 16 80 00 	movl   $0x0,0x8016c048
801026de:	00 00 00 
  write_head(); // clear the log
801026e1:	e8 89 ff ff ff       	call   8010266f <write_head>
}
801026e6:	c9                   	leave  
801026e7:	c3                   	ret    

801026e8 <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
801026e8:	55                   	push   %ebp
801026e9:	89 e5                	mov    %esp,%ebp
801026eb:	57                   	push   %edi
801026ec:	56                   	push   %esi
801026ed:	53                   	push   %ebx
801026ee:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801026f1:	bb 00 00 00 00       	mov    $0x0,%ebx
801026f6:	eb 66                	jmp    8010275e <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
801026f8:	89 d8                	mov    %ebx,%eax
801026fa:	03 05 34 c0 16 80    	add    0x8016c034,%eax
80102700:	83 c0 01             	add    $0x1,%eax
80102703:	83 ec 08             	sub    $0x8,%esp
80102706:	50                   	push   %eax
80102707:	ff 35 44 c0 16 80    	pushl  0x8016c044
8010270d:	e8 5a da ff ff       	call   8010016c <bread>
80102712:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
80102714:	83 c4 08             	add    $0x8,%esp
80102717:	ff 34 9d 4c c0 16 80 	pushl  -0x7fe93fb4(,%ebx,4)
8010271e:	ff 35 44 c0 16 80    	pushl  0x8016c044
80102724:	e8 43 da ff ff       	call   8010016c <bread>
80102729:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
8010272b:	8d 50 5c             	lea    0x5c(%eax),%edx
8010272e:	8d 46 5c             	lea    0x5c(%esi),%eax
80102731:	83 c4 0c             	add    $0xc,%esp
80102734:	68 00 02 00 00       	push   $0x200
80102739:	52                   	push   %edx
8010273a:	50                   	push   %eax
8010273b:	e8 6a 16 00 00       	call   80103daa <memmove>
    bwrite(to);  // write the log
80102740:	89 34 24             	mov    %esi,(%esp)
80102743:	e8 52 da ff ff       	call   8010019a <bwrite>
    brelse(from);
80102748:	89 3c 24             	mov    %edi,(%esp)
8010274b:	e8 85 da ff ff       	call   801001d5 <brelse>
    brelse(to);
80102750:	89 34 24             	mov    %esi,(%esp)
80102753:	e8 7d da ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102758:	83 c3 01             	add    $0x1,%ebx
8010275b:	83 c4 10             	add    $0x10,%esp
8010275e:	39 1d 48 c0 16 80    	cmp    %ebx,0x8016c048
80102764:	7f 92                	jg     801026f8 <write_log+0x10>
  }
}
80102766:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102769:	5b                   	pop    %ebx
8010276a:	5e                   	pop    %esi
8010276b:	5f                   	pop    %edi
8010276c:	5d                   	pop    %ebp
8010276d:	c3                   	ret    

8010276e <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
8010276e:	83 3d 48 c0 16 80 00 	cmpl   $0x0,0x8016c048
80102775:	7e 26                	jle    8010279d <commit+0x2f>
{
80102777:	55                   	push   %ebp
80102778:	89 e5                	mov    %esp,%ebp
8010277a:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
8010277d:	e8 66 ff ff ff       	call   801026e8 <write_log>
    write_head();    // Write header to disk -- the real commit
80102782:	e8 e8 fe ff ff       	call   8010266f <write_head>
    install_trans(); // Now install writes to home locations
80102787:	e8 5d fe ff ff       	call   801025e9 <install_trans>
    log.lh.n = 0;
8010278c:	c7 05 48 c0 16 80 00 	movl   $0x0,0x8016c048
80102793:	00 00 00 
    write_head();    // Erase the transaction from the log
80102796:	e8 d4 fe ff ff       	call   8010266f <write_head>
  }
}
8010279b:	c9                   	leave  
8010279c:	c3                   	ret    
8010279d:	f3 c3                	repz ret 

8010279f <initlog>:
{
8010279f:	55                   	push   %ebp
801027a0:	89 e5                	mov    %esp,%ebp
801027a2:	53                   	push   %ebx
801027a3:	83 ec 2c             	sub    $0x2c,%esp
801027a6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
801027a9:	68 20 6a 10 80       	push   $0x80106a20
801027ae:	68 00 c0 16 80       	push   $0x8016c000
801027b3:	e8 8f 13 00 00       	call   80103b47 <initlock>
  readsb(dev, &sb);
801027b8:	83 c4 08             	add    $0x8,%esp
801027bb:	8d 45 dc             	lea    -0x24(%ebp),%eax
801027be:	50                   	push   %eax
801027bf:	53                   	push   %ebx
801027c0:	e8 71 ea ff ff       	call   80101236 <readsb>
  log.start = sb.logstart;
801027c5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801027c8:	a3 34 c0 16 80       	mov    %eax,0x8016c034
  log.size = sb.nlog;
801027cd:	8b 45 e8             	mov    -0x18(%ebp),%eax
801027d0:	a3 38 c0 16 80       	mov    %eax,0x8016c038
  log.dev = dev;
801027d5:	89 1d 44 c0 16 80    	mov    %ebx,0x8016c044
  recover_from_log();
801027db:	e8 e7 fe ff ff       	call   801026c7 <recover_from_log>
}
801027e0:	83 c4 10             	add    $0x10,%esp
801027e3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801027e6:	c9                   	leave  
801027e7:	c3                   	ret    

801027e8 <begin_op>:
{
801027e8:	55                   	push   %ebp
801027e9:	89 e5                	mov    %esp,%ebp
801027eb:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
801027ee:	68 00 c0 16 80       	push   $0x8016c000
801027f3:	e8 8b 14 00 00       	call   80103c83 <acquire>
801027f8:	83 c4 10             	add    $0x10,%esp
801027fb:	eb 15                	jmp    80102812 <begin_op+0x2a>
      sleep(&log, &log.lock);
801027fd:	83 ec 08             	sub    $0x8,%esp
80102800:	68 00 c0 16 80       	push   $0x8016c000
80102805:	68 00 c0 16 80       	push   $0x8016c000
8010280a:	e8 e1 0e 00 00       	call   801036f0 <sleep>
8010280f:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
80102812:	83 3d 40 c0 16 80 00 	cmpl   $0x0,0x8016c040
80102819:	75 e2                	jne    801027fd <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
8010281b:	a1 3c c0 16 80       	mov    0x8016c03c,%eax
80102820:	83 c0 01             	add    $0x1,%eax
80102823:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102826:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
80102829:	03 15 48 c0 16 80    	add    0x8016c048,%edx
8010282f:	83 fa 1e             	cmp    $0x1e,%edx
80102832:	7e 17                	jle    8010284b <begin_op+0x63>
      sleep(&log, &log.lock);
80102834:	83 ec 08             	sub    $0x8,%esp
80102837:	68 00 c0 16 80       	push   $0x8016c000
8010283c:	68 00 c0 16 80       	push   $0x8016c000
80102841:	e8 aa 0e 00 00       	call   801036f0 <sleep>
80102846:	83 c4 10             	add    $0x10,%esp
80102849:	eb c7                	jmp    80102812 <begin_op+0x2a>
      log.outstanding += 1;
8010284b:	a3 3c c0 16 80       	mov    %eax,0x8016c03c
      release(&log.lock);
80102850:	83 ec 0c             	sub    $0xc,%esp
80102853:	68 00 c0 16 80       	push   $0x8016c000
80102858:	e8 8b 14 00 00       	call   80103ce8 <release>
}
8010285d:	83 c4 10             	add    $0x10,%esp
80102860:	c9                   	leave  
80102861:	c3                   	ret    

80102862 <end_op>:
{
80102862:	55                   	push   %ebp
80102863:	89 e5                	mov    %esp,%ebp
80102865:	53                   	push   %ebx
80102866:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
80102869:	68 00 c0 16 80       	push   $0x8016c000
8010286e:	e8 10 14 00 00       	call   80103c83 <acquire>
  log.outstanding -= 1;
80102873:	a1 3c c0 16 80       	mov    0x8016c03c,%eax
80102878:	83 e8 01             	sub    $0x1,%eax
8010287b:	a3 3c c0 16 80       	mov    %eax,0x8016c03c
  if(log.committing)
80102880:	8b 1d 40 c0 16 80    	mov    0x8016c040,%ebx
80102886:	83 c4 10             	add    $0x10,%esp
80102889:	85 db                	test   %ebx,%ebx
8010288b:	75 2c                	jne    801028b9 <end_op+0x57>
  if(log.outstanding == 0){
8010288d:	85 c0                	test   %eax,%eax
8010288f:	75 35                	jne    801028c6 <end_op+0x64>
    log.committing = 1;
80102891:	c7 05 40 c0 16 80 01 	movl   $0x1,0x8016c040
80102898:	00 00 00 
    do_commit = 1;
8010289b:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
801028a0:	83 ec 0c             	sub    $0xc,%esp
801028a3:	68 00 c0 16 80       	push   $0x8016c000
801028a8:	e8 3b 14 00 00       	call   80103ce8 <release>
  if(do_commit){
801028ad:	83 c4 10             	add    $0x10,%esp
801028b0:	85 db                	test   %ebx,%ebx
801028b2:	75 24                	jne    801028d8 <end_op+0x76>
}
801028b4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801028b7:	c9                   	leave  
801028b8:	c3                   	ret    
    panic("log.committing");
801028b9:	83 ec 0c             	sub    $0xc,%esp
801028bc:	68 24 6a 10 80       	push   $0x80106a24
801028c1:	e8 82 da ff ff       	call   80100348 <panic>
    wakeup(&log);
801028c6:	83 ec 0c             	sub    $0xc,%esp
801028c9:	68 00 c0 16 80       	push   $0x8016c000
801028ce:	e8 82 0f 00 00       	call   80103855 <wakeup>
801028d3:	83 c4 10             	add    $0x10,%esp
801028d6:	eb c8                	jmp    801028a0 <end_op+0x3e>
    commit();
801028d8:	e8 91 fe ff ff       	call   8010276e <commit>
    acquire(&log.lock);
801028dd:	83 ec 0c             	sub    $0xc,%esp
801028e0:	68 00 c0 16 80       	push   $0x8016c000
801028e5:	e8 99 13 00 00       	call   80103c83 <acquire>
    log.committing = 0;
801028ea:	c7 05 40 c0 16 80 00 	movl   $0x0,0x8016c040
801028f1:	00 00 00 
    wakeup(&log);
801028f4:	c7 04 24 00 c0 16 80 	movl   $0x8016c000,(%esp)
801028fb:	e8 55 0f 00 00       	call   80103855 <wakeup>
    release(&log.lock);
80102900:	c7 04 24 00 c0 16 80 	movl   $0x8016c000,(%esp)
80102907:	e8 dc 13 00 00       	call   80103ce8 <release>
8010290c:	83 c4 10             	add    $0x10,%esp
}
8010290f:	eb a3                	jmp    801028b4 <end_op+0x52>

80102911 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80102911:	55                   	push   %ebp
80102912:	89 e5                	mov    %esp,%ebp
80102914:	53                   	push   %ebx
80102915:	83 ec 04             	sub    $0x4,%esp
80102918:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
8010291b:	8b 15 48 c0 16 80    	mov    0x8016c048,%edx
80102921:	83 fa 1d             	cmp    $0x1d,%edx
80102924:	7f 45                	jg     8010296b <log_write+0x5a>
80102926:	a1 38 c0 16 80       	mov    0x8016c038,%eax
8010292b:	83 e8 01             	sub    $0x1,%eax
8010292e:	39 c2                	cmp    %eax,%edx
80102930:	7d 39                	jge    8010296b <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
80102932:	83 3d 3c c0 16 80 00 	cmpl   $0x0,0x8016c03c
80102939:	7e 3d                	jle    80102978 <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
8010293b:	83 ec 0c             	sub    $0xc,%esp
8010293e:	68 00 c0 16 80       	push   $0x8016c000
80102943:	e8 3b 13 00 00       	call   80103c83 <acquire>
  for (i = 0; i < log.lh.n; i++) {
80102948:	83 c4 10             	add    $0x10,%esp
8010294b:	b8 00 00 00 00       	mov    $0x0,%eax
80102950:	8b 15 48 c0 16 80    	mov    0x8016c048,%edx
80102956:	39 c2                	cmp    %eax,%edx
80102958:	7e 2b                	jle    80102985 <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
8010295a:	8b 4b 08             	mov    0x8(%ebx),%ecx
8010295d:	39 0c 85 4c c0 16 80 	cmp    %ecx,-0x7fe93fb4(,%eax,4)
80102964:	74 1f                	je     80102985 <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
80102966:	83 c0 01             	add    $0x1,%eax
80102969:	eb e5                	jmp    80102950 <log_write+0x3f>
    panic("too big a transaction");
8010296b:	83 ec 0c             	sub    $0xc,%esp
8010296e:	68 33 6a 10 80       	push   $0x80106a33
80102973:	e8 d0 d9 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
80102978:	83 ec 0c             	sub    $0xc,%esp
8010297b:	68 49 6a 10 80       	push   $0x80106a49
80102980:	e8 c3 d9 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
80102985:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102988:	89 0c 85 4c c0 16 80 	mov    %ecx,-0x7fe93fb4(,%eax,4)
  if (i == log.lh.n)
8010298f:	39 c2                	cmp    %eax,%edx
80102991:	74 18                	je     801029ab <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102993:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102996:	83 ec 0c             	sub    $0xc,%esp
80102999:	68 00 c0 16 80       	push   $0x8016c000
8010299e:	e8 45 13 00 00       	call   80103ce8 <release>
}
801029a3:	83 c4 10             	add    $0x10,%esp
801029a6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801029a9:	c9                   	leave  
801029aa:	c3                   	ret    
    log.lh.n++;
801029ab:	83 c2 01             	add    $0x1,%edx
801029ae:	89 15 48 c0 16 80    	mov    %edx,0x8016c048
801029b4:	eb dd                	jmp    80102993 <log_write+0x82>

801029b6 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
801029b6:	55                   	push   %ebp
801029b7:	89 e5                	mov    %esp,%ebp
801029b9:	53                   	push   %ebx
801029ba:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
801029bd:	68 8a 00 00 00       	push   $0x8a
801029c2:	68 8c 94 10 80       	push   $0x8010948c
801029c7:	68 00 70 00 80       	push   $0x80007000
801029cc:	e8 d9 13 00 00       	call   80103daa <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
801029d1:	83 c4 10             	add    $0x10,%esp
801029d4:	bb 00 c1 16 80       	mov    $0x8016c100,%ebx
801029d9:	eb 06                	jmp    801029e1 <startothers+0x2b>
801029db:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
801029e1:	69 05 80 c6 16 80 b0 	imul   $0xb0,0x8016c680,%eax
801029e8:	00 00 00 
801029eb:	05 00 c1 16 80       	add    $0x8016c100,%eax
801029f0:	39 d8                	cmp    %ebx,%eax
801029f2:	76 4c                	jbe    80102a40 <startothers+0x8a>
    if(c == mycpu())  // We've started already.
801029f4:	e8 c0 07 00 00       	call   801031b9 <mycpu>
801029f9:	39 d8                	cmp    %ebx,%eax
801029fb:	74 de                	je     801029db <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
801029fd:	e8 c0 f6 ff ff       	call   801020c2 <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102a02:	05 00 10 00 00       	add    $0x1000,%eax
80102a07:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
80102a0c:	c7 05 f8 6f 00 80 84 	movl   $0x80102a84,0x80006ff8
80102a13:	2a 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102a16:	c7 05 f4 6f 00 80 00 	movl   $0x108000,0x80006ff4
80102a1d:	80 10 00 

    lapicstartap(c->apicid, V2P(code));
80102a20:	83 ec 08             	sub    $0x8,%esp
80102a23:	68 00 70 00 00       	push   $0x7000
80102a28:	0f b6 03             	movzbl (%ebx),%eax
80102a2b:	50                   	push   %eax
80102a2c:	e8 c6 f9 ff ff       	call   801023f7 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102a31:	83 c4 10             	add    $0x10,%esp
80102a34:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102a3a:	85 c0                	test   %eax,%eax
80102a3c:	74 f6                	je     80102a34 <startothers+0x7e>
80102a3e:	eb 9b                	jmp    801029db <startothers+0x25>
      ;
  }
}
80102a40:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102a43:	c9                   	leave  
80102a44:	c3                   	ret    

80102a45 <mpmain>:
{
80102a45:	55                   	push   %ebp
80102a46:	89 e5                	mov    %esp,%ebp
80102a48:	53                   	push   %ebx
80102a49:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102a4c:	e8 c4 07 00 00       	call   80103215 <cpuid>
80102a51:	89 c3                	mov    %eax,%ebx
80102a53:	e8 bd 07 00 00       	call   80103215 <cpuid>
80102a58:	83 ec 04             	sub    $0x4,%esp
80102a5b:	53                   	push   %ebx
80102a5c:	50                   	push   %eax
80102a5d:	68 64 6a 10 80       	push   $0x80106a64
80102a62:	e8 a4 db ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102a67:	e8 95 24 00 00       	call   80104f01 <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102a6c:	e8 48 07 00 00       	call   801031b9 <mycpu>
80102a71:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102a73:	b8 01 00 00 00       	mov    $0x1,%eax
80102a78:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102a7f:	e8 47 0a 00 00       	call   801034cb <scheduler>

80102a84 <mpenter>:
{
80102a84:	55                   	push   %ebp
80102a85:	89 e5                	mov    %esp,%ebp
80102a87:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102a8a:	e8 7b 34 00 00       	call   80105f0a <switchkvm>
  seginit();
80102a8f:	e8 2a 33 00 00       	call   80105dbe <seginit>
  lapicinit();
80102a94:	e8 15 f8 ff ff       	call   801022ae <lapicinit>
  mpmain();
80102a99:	e8 a7 ff ff ff       	call   80102a45 <mpmain>

80102a9e <main>:
{
80102a9e:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102aa2:	83 e4 f0             	and    $0xfffffff0,%esp
80102aa5:	ff 71 fc             	pushl  -0x4(%ecx)
80102aa8:	55                   	push   %ebp
80102aa9:	89 e5                	mov    %esp,%ebp
80102aab:	51                   	push   %ecx
80102aac:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102aaf:	68 00 00 40 80       	push   $0x80400000
80102ab4:	68 28 cf 35 80       	push   $0x8035cf28
80102ab9:	e8 b2 f5 ff ff       	call   80102070 <kinit1>
  kvmalloc();      // kernel page table
80102abe:	e8 d4 38 00 00       	call   80106397 <kvmalloc>
  mpinit();        // detect other processors
80102ac3:	e8 c9 01 00 00       	call   80102c91 <mpinit>
  lapicinit();     // interrupt controller
80102ac8:	e8 e1 f7 ff ff       	call   801022ae <lapicinit>
  seginit();       // segment descriptors
80102acd:	e8 ec 32 00 00       	call   80105dbe <seginit>
  picinit();       // disable pic
80102ad2:	e8 82 02 00 00       	call   80102d59 <picinit>
  ioapicinit();    // another interrupt controller
80102ad7:	e8 1e f4 ff ff       	call   80101efa <ioapicinit>
  consoleinit();   // console hardware
80102adc:	e8 ad dd ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102ae1:	e8 c9 26 00 00       	call   801051af <uartinit>
  pinit();         // process table
80102ae6:	e8 b4 06 00 00       	call   8010319f <pinit>
  tvinit();        // trap vectors
80102aeb:	e8 60 23 00 00       	call   80104e50 <tvinit>
  binit();         // buffer cache
80102af0:	e8 ff d5 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102af5:	e8 19 e1 ff ff       	call   80100c13 <fileinit>
  ideinit();       // disk 
80102afa:	e8 01 f2 ff ff       	call   80101d00 <ideinit>
  startothers();   // start other processors
80102aff:	e8 b2 fe ff ff       	call   801029b6 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102b04:	83 c4 08             	add    $0x8,%esp
80102b07:	68 00 00 00 8e       	push   $0x8e000000
80102b0c:	68 00 00 40 80       	push   $0x80400000
80102b11:	e8 8c f5 ff ff       	call   801020a2 <kinit2>
  userinit();      // first user process
80102b16:	e8 39 07 00 00       	call   80103254 <userinit>
  mpmain();        // finish this processor's setup
80102b1b:	e8 25 ff ff ff       	call   80102a45 <mpmain>

80102b20 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102b20:	55                   	push   %ebp
80102b21:	89 e5                	mov    %esp,%ebp
80102b23:	56                   	push   %esi
80102b24:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102b25:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102b2a:	b9 00 00 00 00       	mov    $0x0,%ecx
80102b2f:	eb 09                	jmp    80102b3a <sum+0x1a>
    sum += addr[i];
80102b31:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102b35:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102b37:	83 c1 01             	add    $0x1,%ecx
80102b3a:	39 d1                	cmp    %edx,%ecx
80102b3c:	7c f3                	jl     80102b31 <sum+0x11>
  return sum;
}
80102b3e:	89 d8                	mov    %ebx,%eax
80102b40:	5b                   	pop    %ebx
80102b41:	5e                   	pop    %esi
80102b42:	5d                   	pop    %ebp
80102b43:	c3                   	ret    

80102b44 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102b44:	55                   	push   %ebp
80102b45:	89 e5                	mov    %esp,%ebp
80102b47:	56                   	push   %esi
80102b48:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102b49:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102b4f:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102b51:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102b53:	eb 03                	jmp    80102b58 <mpsearch1+0x14>
80102b55:	83 c3 10             	add    $0x10,%ebx
80102b58:	39 f3                	cmp    %esi,%ebx
80102b5a:	73 29                	jae    80102b85 <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102b5c:	83 ec 04             	sub    $0x4,%esp
80102b5f:	6a 04                	push   $0x4
80102b61:	68 78 6a 10 80       	push   $0x80106a78
80102b66:	53                   	push   %ebx
80102b67:	e8 09 12 00 00       	call   80103d75 <memcmp>
80102b6c:	83 c4 10             	add    $0x10,%esp
80102b6f:	85 c0                	test   %eax,%eax
80102b71:	75 e2                	jne    80102b55 <mpsearch1+0x11>
80102b73:	ba 10 00 00 00       	mov    $0x10,%edx
80102b78:	89 d8                	mov    %ebx,%eax
80102b7a:	e8 a1 ff ff ff       	call   80102b20 <sum>
80102b7f:	84 c0                	test   %al,%al
80102b81:	75 d2                	jne    80102b55 <mpsearch1+0x11>
80102b83:	eb 05                	jmp    80102b8a <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102b85:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102b8a:	89 d8                	mov    %ebx,%eax
80102b8c:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102b8f:	5b                   	pop    %ebx
80102b90:	5e                   	pop    %esi
80102b91:	5d                   	pop    %ebp
80102b92:	c3                   	ret    

80102b93 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102b93:	55                   	push   %ebp
80102b94:	89 e5                	mov    %esp,%ebp
80102b96:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102b99:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102ba0:	c1 e0 08             	shl    $0x8,%eax
80102ba3:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102baa:	09 d0                	or     %edx,%eax
80102bac:	c1 e0 04             	shl    $0x4,%eax
80102baf:	85 c0                	test   %eax,%eax
80102bb1:	74 1f                	je     80102bd2 <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102bb3:	ba 00 04 00 00       	mov    $0x400,%edx
80102bb8:	e8 87 ff ff ff       	call   80102b44 <mpsearch1>
80102bbd:	85 c0                	test   %eax,%eax
80102bbf:	75 0f                	jne    80102bd0 <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102bc1:	ba 00 00 01 00       	mov    $0x10000,%edx
80102bc6:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102bcb:	e8 74 ff ff ff       	call   80102b44 <mpsearch1>
}
80102bd0:	c9                   	leave  
80102bd1:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102bd2:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102bd9:	c1 e0 08             	shl    $0x8,%eax
80102bdc:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102be3:	09 d0                	or     %edx,%eax
80102be5:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102be8:	2d 00 04 00 00       	sub    $0x400,%eax
80102bed:	ba 00 04 00 00       	mov    $0x400,%edx
80102bf2:	e8 4d ff ff ff       	call   80102b44 <mpsearch1>
80102bf7:	85 c0                	test   %eax,%eax
80102bf9:	75 d5                	jne    80102bd0 <mpsearch+0x3d>
80102bfb:	eb c4                	jmp    80102bc1 <mpsearch+0x2e>

80102bfd <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102bfd:	55                   	push   %ebp
80102bfe:	89 e5                	mov    %esp,%ebp
80102c00:	57                   	push   %edi
80102c01:	56                   	push   %esi
80102c02:	53                   	push   %ebx
80102c03:	83 ec 1c             	sub    $0x1c,%esp
80102c06:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102c09:	e8 85 ff ff ff       	call   80102b93 <mpsearch>
80102c0e:	85 c0                	test   %eax,%eax
80102c10:	74 5c                	je     80102c6e <mpconfig+0x71>
80102c12:	89 c7                	mov    %eax,%edi
80102c14:	8b 58 04             	mov    0x4(%eax),%ebx
80102c17:	85 db                	test   %ebx,%ebx
80102c19:	74 5a                	je     80102c75 <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102c1b:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102c21:	83 ec 04             	sub    $0x4,%esp
80102c24:	6a 04                	push   $0x4
80102c26:	68 7d 6a 10 80       	push   $0x80106a7d
80102c2b:	56                   	push   %esi
80102c2c:	e8 44 11 00 00       	call   80103d75 <memcmp>
80102c31:	83 c4 10             	add    $0x10,%esp
80102c34:	85 c0                	test   %eax,%eax
80102c36:	75 44                	jne    80102c7c <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102c38:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102c3f:	3c 01                	cmp    $0x1,%al
80102c41:	0f 95 c2             	setne  %dl
80102c44:	3c 04                	cmp    $0x4,%al
80102c46:	0f 95 c0             	setne  %al
80102c49:	84 c2                	test   %al,%dl
80102c4b:	75 36                	jne    80102c83 <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102c4d:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102c54:	89 f0                	mov    %esi,%eax
80102c56:	e8 c5 fe ff ff       	call   80102b20 <sum>
80102c5b:	84 c0                	test   %al,%al
80102c5d:	75 2b                	jne    80102c8a <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102c5f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102c62:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102c64:	89 f0                	mov    %esi,%eax
80102c66:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102c69:	5b                   	pop    %ebx
80102c6a:	5e                   	pop    %esi
80102c6b:	5f                   	pop    %edi
80102c6c:	5d                   	pop    %ebp
80102c6d:	c3                   	ret    
    return 0;
80102c6e:	be 00 00 00 00       	mov    $0x0,%esi
80102c73:	eb ef                	jmp    80102c64 <mpconfig+0x67>
80102c75:	be 00 00 00 00       	mov    $0x0,%esi
80102c7a:	eb e8                	jmp    80102c64 <mpconfig+0x67>
    return 0;
80102c7c:	be 00 00 00 00       	mov    $0x0,%esi
80102c81:	eb e1                	jmp    80102c64 <mpconfig+0x67>
    return 0;
80102c83:	be 00 00 00 00       	mov    $0x0,%esi
80102c88:	eb da                	jmp    80102c64 <mpconfig+0x67>
    return 0;
80102c8a:	be 00 00 00 00       	mov    $0x0,%esi
80102c8f:	eb d3                	jmp    80102c64 <mpconfig+0x67>

80102c91 <mpinit>:

void
mpinit(void)
{
80102c91:	55                   	push   %ebp
80102c92:	89 e5                	mov    %esp,%ebp
80102c94:	57                   	push   %edi
80102c95:	56                   	push   %esi
80102c96:	53                   	push   %ebx
80102c97:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102c9a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102c9d:	e8 5b ff ff ff       	call   80102bfd <mpconfig>
80102ca2:	85 c0                	test   %eax,%eax
80102ca4:	74 19                	je     80102cbf <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102ca6:	8b 50 24             	mov    0x24(%eax),%edx
80102ca9:	89 15 fc bf 16 80    	mov    %edx,0x8016bffc
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102caf:	8d 50 2c             	lea    0x2c(%eax),%edx
80102cb2:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102cb6:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102cb8:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102cbd:	eb 34                	jmp    80102cf3 <mpinit+0x62>
    panic("Expect to run on an SMP");
80102cbf:	83 ec 0c             	sub    $0xc,%esp
80102cc2:	68 82 6a 10 80       	push   $0x80106a82
80102cc7:	e8 7c d6 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102ccc:	8b 35 80 c6 16 80    	mov    0x8016c680,%esi
80102cd2:	83 fe 07             	cmp    $0x7,%esi
80102cd5:	7f 19                	jg     80102cf0 <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102cd7:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102cdb:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102ce1:	88 87 00 c1 16 80    	mov    %al,-0x7fe93f00(%edi)
        ncpu++;
80102ce7:	83 c6 01             	add    $0x1,%esi
80102cea:	89 35 80 c6 16 80    	mov    %esi,0x8016c680
      }
      p += sizeof(struct mpproc);
80102cf0:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102cf3:	39 ca                	cmp    %ecx,%edx
80102cf5:	73 2b                	jae    80102d22 <mpinit+0x91>
    switch(*p){
80102cf7:	0f b6 02             	movzbl (%edx),%eax
80102cfa:	3c 04                	cmp    $0x4,%al
80102cfc:	77 1d                	ja     80102d1b <mpinit+0x8a>
80102cfe:	0f b6 c0             	movzbl %al,%eax
80102d01:	ff 24 85 bc 6a 10 80 	jmp    *-0x7fef9544(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80102d08:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102d0c:	a2 e0 c0 16 80       	mov    %al,0x8016c0e0
      p += sizeof(struct mpioapic);
80102d11:	83 c2 08             	add    $0x8,%edx
      continue;
80102d14:	eb dd                	jmp    80102cf3 <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102d16:	83 c2 08             	add    $0x8,%edx
      continue;
80102d19:	eb d8                	jmp    80102cf3 <mpinit+0x62>
    default:
      ismp = 0;
80102d1b:	bb 00 00 00 00       	mov    $0x0,%ebx
80102d20:	eb d1                	jmp    80102cf3 <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
80102d22:	85 db                	test   %ebx,%ebx
80102d24:	74 26                	je     80102d4c <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102d26:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102d29:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102d2d:	74 15                	je     80102d44 <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102d2f:	b8 70 00 00 00       	mov    $0x70,%eax
80102d34:	ba 22 00 00 00       	mov    $0x22,%edx
80102d39:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102d3a:	ba 23 00 00 00       	mov    $0x23,%edx
80102d3f:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102d40:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102d43:	ee                   	out    %al,(%dx)
  }
}
80102d44:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102d47:	5b                   	pop    %ebx
80102d48:	5e                   	pop    %esi
80102d49:	5f                   	pop    %edi
80102d4a:	5d                   	pop    %ebp
80102d4b:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102d4c:	83 ec 0c             	sub    $0xc,%esp
80102d4f:	68 9c 6a 10 80       	push   $0x80106a9c
80102d54:	e8 ef d5 ff ff       	call   80100348 <panic>

80102d59 <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80102d59:	55                   	push   %ebp
80102d5a:	89 e5                	mov    %esp,%ebp
80102d5c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102d61:	ba 21 00 00 00       	mov    $0x21,%edx
80102d66:	ee                   	out    %al,(%dx)
80102d67:	ba a1 00 00 00       	mov    $0xa1,%edx
80102d6c:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80102d6d:	5d                   	pop    %ebp
80102d6e:	c3                   	ret    

80102d6f <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80102d6f:	55                   	push   %ebp
80102d70:	89 e5                	mov    %esp,%ebp
80102d72:	57                   	push   %edi
80102d73:	56                   	push   %esi
80102d74:	53                   	push   %ebx
80102d75:	83 ec 0c             	sub    $0xc,%esp
80102d78:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102d7b:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80102d7e:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80102d84:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80102d8a:	e8 9e de ff ff       	call   80100c2d <filealloc>
80102d8f:	89 03                	mov    %eax,(%ebx)
80102d91:	85 c0                	test   %eax,%eax
80102d93:	74 16                	je     80102dab <pipealloc+0x3c>
80102d95:	e8 93 de ff ff       	call   80100c2d <filealloc>
80102d9a:	89 06                	mov    %eax,(%esi)
80102d9c:	85 c0                	test   %eax,%eax
80102d9e:	74 0b                	je     80102dab <pipealloc+0x3c>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80102da0:	e8 1d f3 ff ff       	call   801020c2 <kalloc>
80102da5:	89 c7                	mov    %eax,%edi
80102da7:	85 c0                	test   %eax,%eax
80102da9:	75 35                	jne    80102de0 <pipealloc+0x71>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
80102dab:	8b 03                	mov    (%ebx),%eax
80102dad:	85 c0                	test   %eax,%eax
80102daf:	74 0c                	je     80102dbd <pipealloc+0x4e>
    fileclose(*f0);
80102db1:	83 ec 0c             	sub    $0xc,%esp
80102db4:	50                   	push   %eax
80102db5:	e8 19 df ff ff       	call   80100cd3 <fileclose>
80102dba:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80102dbd:	8b 06                	mov    (%esi),%eax
80102dbf:	85 c0                	test   %eax,%eax
80102dc1:	0f 84 8b 00 00 00    	je     80102e52 <pipealloc+0xe3>
    fileclose(*f1);
80102dc7:	83 ec 0c             	sub    $0xc,%esp
80102dca:	50                   	push   %eax
80102dcb:	e8 03 df ff ff       	call   80100cd3 <fileclose>
80102dd0:	83 c4 10             	add    $0x10,%esp
  return -1;
80102dd3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80102dd8:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102ddb:	5b                   	pop    %ebx
80102ddc:	5e                   	pop    %esi
80102ddd:	5f                   	pop    %edi
80102dde:	5d                   	pop    %ebp
80102ddf:	c3                   	ret    
  p->readopen = 1;
80102de0:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80102de7:	00 00 00 
  p->writeopen = 1;
80102dea:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80102df1:	00 00 00 
  p->nwrite = 0;
80102df4:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80102dfb:	00 00 00 
  p->nread = 0;
80102dfe:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80102e05:	00 00 00 
  initlock(&p->lock, "pipe");
80102e08:	83 ec 08             	sub    $0x8,%esp
80102e0b:	68 d0 6a 10 80       	push   $0x80106ad0
80102e10:	50                   	push   %eax
80102e11:	e8 31 0d 00 00       	call   80103b47 <initlock>
  (*f0)->type = FD_PIPE;
80102e16:	8b 03                	mov    (%ebx),%eax
80102e18:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80102e1e:	8b 03                	mov    (%ebx),%eax
80102e20:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80102e24:	8b 03                	mov    (%ebx),%eax
80102e26:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80102e2a:	8b 03                	mov    (%ebx),%eax
80102e2c:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80102e2f:	8b 06                	mov    (%esi),%eax
80102e31:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80102e37:	8b 06                	mov    (%esi),%eax
80102e39:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80102e3d:	8b 06                	mov    (%esi),%eax
80102e3f:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80102e43:	8b 06                	mov    (%esi),%eax
80102e45:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
80102e48:	83 c4 10             	add    $0x10,%esp
80102e4b:	b8 00 00 00 00       	mov    $0x0,%eax
80102e50:	eb 86                	jmp    80102dd8 <pipealloc+0x69>
  return -1;
80102e52:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102e57:	e9 7c ff ff ff       	jmp    80102dd8 <pipealloc+0x69>

80102e5c <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80102e5c:	55                   	push   %ebp
80102e5d:	89 e5                	mov    %esp,%ebp
80102e5f:	53                   	push   %ebx
80102e60:	83 ec 10             	sub    $0x10,%esp
80102e63:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
80102e66:	53                   	push   %ebx
80102e67:	e8 17 0e 00 00       	call   80103c83 <acquire>
  if(writable){
80102e6c:	83 c4 10             	add    $0x10,%esp
80102e6f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102e73:	74 3f                	je     80102eb4 <pipeclose+0x58>
    p->writeopen = 0;
80102e75:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80102e7c:	00 00 00 
    wakeup(&p->nread);
80102e7f:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102e85:	83 ec 0c             	sub    $0xc,%esp
80102e88:	50                   	push   %eax
80102e89:	e8 c7 09 00 00       	call   80103855 <wakeup>
80102e8e:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80102e91:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102e98:	75 09                	jne    80102ea3 <pipeclose+0x47>
80102e9a:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80102ea1:	74 2f                	je     80102ed2 <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
80102ea3:	83 ec 0c             	sub    $0xc,%esp
80102ea6:	53                   	push   %ebx
80102ea7:	e8 3c 0e 00 00       	call   80103ce8 <release>
80102eac:	83 c4 10             	add    $0x10,%esp
}
80102eaf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102eb2:	c9                   	leave  
80102eb3:	c3                   	ret    
    p->readopen = 0;
80102eb4:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
80102ebb:	00 00 00 
    wakeup(&p->nwrite);
80102ebe:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102ec4:	83 ec 0c             	sub    $0xc,%esp
80102ec7:	50                   	push   %eax
80102ec8:	e8 88 09 00 00       	call   80103855 <wakeup>
80102ecd:	83 c4 10             	add    $0x10,%esp
80102ed0:	eb bf                	jmp    80102e91 <pipeclose+0x35>
    release(&p->lock);
80102ed2:	83 ec 0c             	sub    $0xc,%esp
80102ed5:	53                   	push   %ebx
80102ed6:	e8 0d 0e 00 00       	call   80103ce8 <release>
    kfree((char*)p);
80102edb:	89 1c 24             	mov    %ebx,(%esp)
80102ede:	e8 c1 f0 ff ff       	call   80101fa4 <kfree>
80102ee3:	83 c4 10             	add    $0x10,%esp
80102ee6:	eb c7                	jmp    80102eaf <pipeclose+0x53>

80102ee8 <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
80102ee8:	55                   	push   %ebp
80102ee9:	89 e5                	mov    %esp,%ebp
80102eeb:	57                   	push   %edi
80102eec:	56                   	push   %esi
80102eed:	53                   	push   %ebx
80102eee:	83 ec 18             	sub    $0x18,%esp
80102ef1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80102ef4:	89 de                	mov    %ebx,%esi
80102ef6:	53                   	push   %ebx
80102ef7:	e8 87 0d 00 00       	call   80103c83 <acquire>
  for(i = 0; i < n; i++){
80102efc:	83 c4 10             	add    $0x10,%esp
80102eff:	bf 00 00 00 00       	mov    $0x0,%edi
80102f04:	3b 7d 10             	cmp    0x10(%ebp),%edi
80102f07:	0f 8d 88 00 00 00    	jge    80102f95 <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80102f0d:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
80102f13:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80102f19:	05 00 02 00 00       	add    $0x200,%eax
80102f1e:	39 c2                	cmp    %eax,%edx
80102f20:	75 51                	jne    80102f73 <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
80102f22:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102f29:	74 2f                	je     80102f5a <pipewrite+0x72>
80102f2b:	e8 00 03 00 00       	call   80103230 <myproc>
80102f30:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80102f34:	75 24                	jne    80102f5a <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
80102f36:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102f3c:	83 ec 0c             	sub    $0xc,%esp
80102f3f:	50                   	push   %eax
80102f40:	e8 10 09 00 00       	call   80103855 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80102f45:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102f4b:	83 c4 08             	add    $0x8,%esp
80102f4e:	56                   	push   %esi
80102f4f:	50                   	push   %eax
80102f50:	e8 9b 07 00 00       	call   801036f0 <sleep>
80102f55:	83 c4 10             	add    $0x10,%esp
80102f58:	eb b3                	jmp    80102f0d <pipewrite+0x25>
        release(&p->lock);
80102f5a:	83 ec 0c             	sub    $0xc,%esp
80102f5d:	53                   	push   %ebx
80102f5e:	e8 85 0d 00 00       	call   80103ce8 <release>
        return -1;
80102f63:	83 c4 10             	add    $0x10,%esp
80102f66:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
80102f6b:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102f6e:	5b                   	pop    %ebx
80102f6f:	5e                   	pop    %esi
80102f70:	5f                   	pop    %edi
80102f71:	5d                   	pop    %ebp
80102f72:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80102f73:	8d 42 01             	lea    0x1(%edx),%eax
80102f76:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
80102f7c:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102f82:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f85:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
80102f89:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
80102f8d:	83 c7 01             	add    $0x1,%edi
80102f90:	e9 6f ff ff ff       	jmp    80102f04 <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80102f95:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102f9b:	83 ec 0c             	sub    $0xc,%esp
80102f9e:	50                   	push   %eax
80102f9f:	e8 b1 08 00 00       	call   80103855 <wakeup>
  release(&p->lock);
80102fa4:	89 1c 24             	mov    %ebx,(%esp)
80102fa7:	e8 3c 0d 00 00       	call   80103ce8 <release>
  return n;
80102fac:	83 c4 10             	add    $0x10,%esp
80102faf:	8b 45 10             	mov    0x10(%ebp),%eax
80102fb2:	eb b7                	jmp    80102f6b <pipewrite+0x83>

80102fb4 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80102fb4:	55                   	push   %ebp
80102fb5:	89 e5                	mov    %esp,%ebp
80102fb7:	57                   	push   %edi
80102fb8:	56                   	push   %esi
80102fb9:	53                   	push   %ebx
80102fba:	83 ec 18             	sub    $0x18,%esp
80102fbd:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80102fc0:	89 df                	mov    %ebx,%edi
80102fc2:	53                   	push   %ebx
80102fc3:	e8 bb 0c 00 00       	call   80103c83 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80102fc8:	83 c4 10             	add    $0x10,%esp
80102fcb:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
80102fd1:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
80102fd7:	75 3d                	jne    80103016 <piperead+0x62>
80102fd9:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
80102fdf:	85 f6                	test   %esi,%esi
80102fe1:	74 38                	je     8010301b <piperead+0x67>
    if(myproc()->killed){
80102fe3:	e8 48 02 00 00       	call   80103230 <myproc>
80102fe8:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80102fec:	75 15                	jne    80103003 <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80102fee:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102ff4:	83 ec 08             	sub    $0x8,%esp
80102ff7:	57                   	push   %edi
80102ff8:	50                   	push   %eax
80102ff9:	e8 f2 06 00 00       	call   801036f0 <sleep>
80102ffe:	83 c4 10             	add    $0x10,%esp
80103001:	eb c8                	jmp    80102fcb <piperead+0x17>
      release(&p->lock);
80103003:	83 ec 0c             	sub    $0xc,%esp
80103006:	53                   	push   %ebx
80103007:	e8 dc 0c 00 00       	call   80103ce8 <release>
      return -1;
8010300c:	83 c4 10             	add    $0x10,%esp
8010300f:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103014:	eb 50                	jmp    80103066 <piperead+0xb2>
80103016:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010301b:	3b 75 10             	cmp    0x10(%ebp),%esi
8010301e:	7d 2c                	jge    8010304c <piperead+0x98>
    if(p->nread == p->nwrite)
80103020:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80103026:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
8010302c:	74 1e                	je     8010304c <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
8010302e:	8d 50 01             	lea    0x1(%eax),%edx
80103031:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
80103037:	25 ff 01 00 00       	and    $0x1ff,%eax
8010303c:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
80103041:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103044:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103047:	83 c6 01             	add    $0x1,%esi
8010304a:	eb cf                	jmp    8010301b <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
8010304c:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103052:	83 ec 0c             	sub    $0xc,%esp
80103055:	50                   	push   %eax
80103056:	e8 fa 07 00 00       	call   80103855 <wakeup>
  release(&p->lock);
8010305b:	89 1c 24             	mov    %ebx,(%esp)
8010305e:	e8 85 0c 00 00       	call   80103ce8 <release>
  return i;
80103063:	83 c4 10             	add    $0x10,%esp
}
80103066:	89 f0                	mov    %esi,%eax
80103068:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010306b:	5b                   	pop    %ebx
8010306c:	5e                   	pop    %esi
8010306d:	5f                   	pop    %edi
8010306e:	5d                   	pop    %ebp
8010306f:	c3                   	ret    

80103070 <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80103070:	55                   	push   %ebp
80103071:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103073:	ba d4 c6 16 80       	mov    $0x8016c6d4,%edx
80103078:	eb 03                	jmp    8010307d <wakeup1+0xd>
8010307a:	83 c2 7c             	add    $0x7c,%edx
8010307d:	81 fa d4 e5 16 80    	cmp    $0x8016e5d4,%edx
80103083:	73 14                	jae    80103099 <wakeup1+0x29>
    if(p->state == SLEEPING && p->chan == chan)
80103085:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
80103089:	75 ef                	jne    8010307a <wakeup1+0xa>
8010308b:	39 42 20             	cmp    %eax,0x20(%edx)
8010308e:	75 ea                	jne    8010307a <wakeup1+0xa>
      p->state = RUNNABLE;
80103090:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
80103097:	eb e1                	jmp    8010307a <wakeup1+0xa>
}
80103099:	5d                   	pop    %ebp
8010309a:	c3                   	ret    

8010309b <allocproc>:
{
8010309b:	55                   	push   %ebp
8010309c:	89 e5                	mov    %esp,%ebp
8010309e:	53                   	push   %ebx
8010309f:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
801030a2:	68 a0 c6 16 80       	push   $0x8016c6a0
801030a7:	e8 d7 0b 00 00       	call   80103c83 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801030ac:	83 c4 10             	add    $0x10,%esp
801030af:	bb d4 c6 16 80       	mov    $0x8016c6d4,%ebx
801030b4:	81 fb d4 e5 16 80    	cmp    $0x8016e5d4,%ebx
801030ba:	73 0b                	jae    801030c7 <allocproc+0x2c>
    if(p->state == UNUSED)
801030bc:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
801030c0:	74 1c                	je     801030de <allocproc+0x43>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801030c2:	83 c3 7c             	add    $0x7c,%ebx
801030c5:	eb ed                	jmp    801030b4 <allocproc+0x19>
  release(&ptable.lock);
801030c7:	83 ec 0c             	sub    $0xc,%esp
801030ca:	68 a0 c6 16 80       	push   $0x8016c6a0
801030cf:	e8 14 0c 00 00       	call   80103ce8 <release>
  return 0;
801030d4:	83 c4 10             	add    $0x10,%esp
801030d7:	bb 00 00 00 00       	mov    $0x0,%ebx
801030dc:	eb 69                	jmp    80103147 <allocproc+0xac>
  p->state = EMBRYO;
801030de:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
801030e5:	a1 04 90 10 80       	mov    0x80109004,%eax
801030ea:	8d 50 01             	lea    0x1(%eax),%edx
801030ed:	89 15 04 90 10 80    	mov    %edx,0x80109004
801030f3:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
801030f6:	83 ec 0c             	sub    $0xc,%esp
801030f9:	68 a0 c6 16 80       	push   $0x8016c6a0
801030fe:	e8 e5 0b 00 00       	call   80103ce8 <release>
  if((p->kstack = kalloc()) == 0){
80103103:	e8 ba ef ff ff       	call   801020c2 <kalloc>
80103108:	89 43 08             	mov    %eax,0x8(%ebx)
8010310b:	83 c4 10             	add    $0x10,%esp
8010310e:	85 c0                	test   %eax,%eax
80103110:	74 3c                	je     8010314e <allocproc+0xb3>
  sp -= sizeof *p->tf;
80103112:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
80103118:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint*)sp = (uint)trapret;
8010311b:	c7 80 b0 0f 00 00 45 	movl   $0x80104e45,0xfb0(%eax)
80103122:	4e 10 80 
  sp -= sizeof *p->context;
80103125:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context*)sp;
8010312a:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
8010312d:	83 ec 04             	sub    $0x4,%esp
80103130:	6a 14                	push   $0x14
80103132:	6a 00                	push   $0x0
80103134:	50                   	push   %eax
80103135:	e8 f5 0b 00 00       	call   80103d2f <memset>
  p->context->eip = (uint)forkret;
8010313a:	8b 43 1c             	mov    0x1c(%ebx),%eax
8010313d:	c7 40 10 5c 31 10 80 	movl   $0x8010315c,0x10(%eax)
  return p;
80103144:	83 c4 10             	add    $0x10,%esp
}
80103147:	89 d8                	mov    %ebx,%eax
80103149:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010314c:	c9                   	leave  
8010314d:	c3                   	ret    
    p->state = UNUSED;
8010314e:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
80103155:	bb 00 00 00 00       	mov    $0x0,%ebx
8010315a:	eb eb                	jmp    80103147 <allocproc+0xac>

8010315c <forkret>:
{
8010315c:	55                   	push   %ebp
8010315d:	89 e5                	mov    %esp,%ebp
8010315f:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
80103162:	68 a0 c6 16 80       	push   $0x8016c6a0
80103167:	e8 7c 0b 00 00       	call   80103ce8 <release>
  if (first) {
8010316c:	83 c4 10             	add    $0x10,%esp
8010316f:	83 3d 00 90 10 80 00 	cmpl   $0x0,0x80109000
80103176:	75 02                	jne    8010317a <forkret+0x1e>
}
80103178:	c9                   	leave  
80103179:	c3                   	ret    
    first = 0;
8010317a:	c7 05 00 90 10 80 00 	movl   $0x0,0x80109000
80103181:	00 00 00 
    iinit(ROOTDEV);
80103184:	83 ec 0c             	sub    $0xc,%esp
80103187:	6a 01                	push   $0x1
80103189:	e8 5e e1 ff ff       	call   801012ec <iinit>
    initlog(ROOTDEV);
8010318e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103195:	e8 05 f6 ff ff       	call   8010279f <initlog>
8010319a:	83 c4 10             	add    $0x10,%esp
}
8010319d:	eb d9                	jmp    80103178 <forkret+0x1c>

8010319f <pinit>:
{
8010319f:	55                   	push   %ebp
801031a0:	89 e5                	mov    %esp,%ebp
801031a2:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
801031a5:	68 d5 6a 10 80       	push   $0x80106ad5
801031aa:	68 a0 c6 16 80       	push   $0x8016c6a0
801031af:	e8 93 09 00 00       	call   80103b47 <initlock>
}
801031b4:	83 c4 10             	add    $0x10,%esp
801031b7:	c9                   	leave  
801031b8:	c3                   	ret    

801031b9 <mycpu>:
{
801031b9:	55                   	push   %ebp
801031ba:	89 e5                	mov    %esp,%ebp
801031bc:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801031bf:	9c                   	pushf  
801031c0:	58                   	pop    %eax
  if(readeflags()&FL_IF)
801031c1:	f6 c4 02             	test   $0x2,%ah
801031c4:	75 28                	jne    801031ee <mycpu+0x35>
  apicid = lapicid();
801031c6:	e8 ed f1 ff ff       	call   801023b8 <lapicid>
  for (i = 0; i < ncpu; ++i) {
801031cb:	ba 00 00 00 00       	mov    $0x0,%edx
801031d0:	39 15 80 c6 16 80    	cmp    %edx,0x8016c680
801031d6:	7e 23                	jle    801031fb <mycpu+0x42>
    if (cpus[i].apicid == apicid)
801031d8:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
801031de:	0f b6 89 00 c1 16 80 	movzbl -0x7fe93f00(%ecx),%ecx
801031e5:	39 c1                	cmp    %eax,%ecx
801031e7:	74 1f                	je     80103208 <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i) {
801031e9:	83 c2 01             	add    $0x1,%edx
801031ec:	eb e2                	jmp    801031d0 <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
801031ee:	83 ec 0c             	sub    $0xc,%esp
801031f1:	68 b8 6b 10 80       	push   $0x80106bb8
801031f6:	e8 4d d1 ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
801031fb:	83 ec 0c             	sub    $0xc,%esp
801031fe:	68 dc 6a 10 80       	push   $0x80106adc
80103203:	e8 40 d1 ff ff       	call   80100348 <panic>
      return &cpus[i];
80103208:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
8010320e:	05 00 c1 16 80       	add    $0x8016c100,%eax
}
80103213:	c9                   	leave  
80103214:	c3                   	ret    

80103215 <cpuid>:
cpuid() {
80103215:	55                   	push   %ebp
80103216:	89 e5                	mov    %esp,%ebp
80103218:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
8010321b:	e8 99 ff ff ff       	call   801031b9 <mycpu>
80103220:	2d 00 c1 16 80       	sub    $0x8016c100,%eax
80103225:	c1 f8 04             	sar    $0x4,%eax
80103228:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
8010322e:	c9                   	leave  
8010322f:	c3                   	ret    

80103230 <myproc>:
myproc(void) {
80103230:	55                   	push   %ebp
80103231:	89 e5                	mov    %esp,%ebp
80103233:	53                   	push   %ebx
80103234:	83 ec 04             	sub    $0x4,%esp
  pushcli();
80103237:	e8 6a 09 00 00       	call   80103ba6 <pushcli>
  c = mycpu();
8010323c:	e8 78 ff ff ff       	call   801031b9 <mycpu>
  p = c->proc;
80103241:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
80103247:	e8 97 09 00 00       	call   80103be3 <popcli>
}
8010324c:	89 d8                	mov    %ebx,%eax
8010324e:	83 c4 04             	add    $0x4,%esp
80103251:	5b                   	pop    %ebx
80103252:	5d                   	pop    %ebp
80103253:	c3                   	ret    

80103254 <userinit>:
{
80103254:	55                   	push   %ebp
80103255:	89 e5                	mov    %esp,%ebp
80103257:	53                   	push   %ebx
80103258:	83 ec 04             	sub    $0x4,%esp
  for(int i=0; i<MAXSIZE; i++){
8010325b:	b8 00 00 00 00       	mov    $0x0,%eax
80103260:	eb 0e                	jmp    80103270 <userinit+0x1c>
    FRAMES[i] = -1;
80103262:	c7 04 85 20 ef 10 80 	movl   $0xffffffff,-0x7fef10e0(,%eax,4)
80103269:	ff ff ff ff 
  for(int i=0; i<MAXSIZE; i++){
8010326d:	83 c0 01             	add    $0x1,%eax
80103270:	3d 5f ea 00 00       	cmp    $0xea5f,%eax
80103275:	7e eb                	jle    80103262 <userinit+0xe>
  p = allocproc();
80103277:	e8 1f fe ff ff       	call   8010309b <allocproc>
8010327c:	89 c3                	mov    %eax,%ebx
  initproc = p;
8010327e:	a3 b8 95 10 80       	mov    %eax,0x801095b8
  if((p->pgdir = setupkvm()) == 0)
80103283:	e8 a1 30 00 00       	call   80106329 <setupkvm>
80103288:	89 43 04             	mov    %eax,0x4(%ebx)
8010328b:	85 c0                	test   %eax,%eax
8010328d:	0f 84 b7 00 00 00    	je     8010334a <userinit+0xf6>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80103293:	83 ec 04             	sub    $0x4,%esp
80103296:	68 2c 00 00 00       	push   $0x2c
8010329b:	68 60 94 10 80       	push   $0x80109460
801032a0:	50                   	push   %eax
801032a1:	e8 8e 2d 00 00       	call   80106034 <inituvm>
  p->sz = PGSIZE;
801032a6:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
801032ac:	83 c4 0c             	add    $0xc,%esp
801032af:	6a 4c                	push   $0x4c
801032b1:	6a 00                	push   $0x0
801032b3:	ff 73 18             	pushl  0x18(%ebx)
801032b6:	e8 74 0a 00 00       	call   80103d2f <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801032bb:	8b 43 18             	mov    0x18(%ebx),%eax
801032be:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801032c4:	8b 43 18             	mov    0x18(%ebx),%eax
801032c7:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
801032cd:	8b 43 18             	mov    0x18(%ebx),%eax
801032d0:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801032d4:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801032d8:	8b 43 18             	mov    0x18(%ebx),%eax
801032db:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801032df:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801032e3:	8b 43 18             	mov    0x18(%ebx),%eax
801032e6:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801032ed:	8b 43 18             	mov    0x18(%ebx),%eax
801032f0:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801032f7:	8b 43 18             	mov    0x18(%ebx),%eax
801032fa:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
80103301:	8d 43 6c             	lea    0x6c(%ebx),%eax
80103304:	83 c4 0c             	add    $0xc,%esp
80103307:	6a 10                	push   $0x10
80103309:	68 05 6b 10 80       	push   $0x80106b05
8010330e:	50                   	push   %eax
8010330f:	e8 82 0b 00 00       	call   80103e96 <safestrcpy>
  p->cwd = namei("/");
80103314:	c7 04 24 0e 6b 10 80 	movl   $0x80106b0e,(%esp)
8010331b:	e8 c1 e8 ff ff       	call   80101be1 <namei>
80103320:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
80103323:	c7 04 24 a0 c6 16 80 	movl   $0x8016c6a0,(%esp)
8010332a:	e8 54 09 00 00       	call   80103c83 <acquire>
  p->state = RUNNABLE;
8010332f:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
80103336:	c7 04 24 a0 c6 16 80 	movl   $0x8016c6a0,(%esp)
8010333d:	e8 a6 09 00 00       	call   80103ce8 <release>
}
80103342:	83 c4 10             	add    $0x10,%esp
80103345:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103348:	c9                   	leave  
80103349:	c3                   	ret    
    panic("userinit: out of memory?");
8010334a:	83 ec 0c             	sub    $0xc,%esp
8010334d:	68 ec 6a 10 80       	push   $0x80106aec
80103352:	e8 f1 cf ff ff       	call   80100348 <panic>

80103357 <growproc>:
{
80103357:	55                   	push   %ebp
80103358:	89 e5                	mov    %esp,%ebp
8010335a:	56                   	push   %esi
8010335b:	53                   	push   %ebx
8010335c:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
8010335f:	e8 cc fe ff ff       	call   80103230 <myproc>
80103364:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
80103366:	8b 00                	mov    (%eax),%eax
  if(n > 0){
80103368:	85 f6                	test   %esi,%esi
8010336a:	7f 21                	jg     8010338d <growproc+0x36>
  } else if(n < 0){
8010336c:	85 f6                	test   %esi,%esi
8010336e:	79 33                	jns    801033a3 <growproc+0x4c>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103370:	83 ec 04             	sub    $0x4,%esp
80103373:	01 c6                	add    %eax,%esi
80103375:	56                   	push   %esi
80103376:	50                   	push   %eax
80103377:	ff 73 04             	pushl  0x4(%ebx)
8010337a:	e8 be 2d 00 00       	call   8010613d <deallocuvm>
8010337f:	83 c4 10             	add    $0x10,%esp
80103382:	85 c0                	test   %eax,%eax
80103384:	75 1d                	jne    801033a3 <growproc+0x4c>
      return -1;
80103386:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010338b:	eb 29                	jmp    801033b6 <growproc+0x5f>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
8010338d:	83 ec 04             	sub    $0x4,%esp
80103390:	01 c6                	add    %eax,%esi
80103392:	56                   	push   %esi
80103393:	50                   	push   %eax
80103394:	ff 73 04             	pushl  0x4(%ebx)
80103397:	e8 33 2e 00 00       	call   801061cf <allocuvm>
8010339c:	83 c4 10             	add    $0x10,%esp
8010339f:	85 c0                	test   %eax,%eax
801033a1:	74 1a                	je     801033bd <growproc+0x66>
  curproc->sz = sz;
801033a3:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
801033a5:	83 ec 0c             	sub    $0xc,%esp
801033a8:	53                   	push   %ebx
801033a9:	e8 6e 2b 00 00       	call   80105f1c <switchuvm>
  return 0;
801033ae:	83 c4 10             	add    $0x10,%esp
801033b1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801033b6:	8d 65 f8             	lea    -0x8(%ebp),%esp
801033b9:	5b                   	pop    %ebx
801033ba:	5e                   	pop    %esi
801033bb:	5d                   	pop    %ebp
801033bc:	c3                   	ret    
      return -1;
801033bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801033c2:	eb f2                	jmp    801033b6 <growproc+0x5f>

801033c4 <fork>:
{
801033c4:	55                   	push   %ebp
801033c5:	89 e5                	mov    %esp,%ebp
801033c7:	57                   	push   %edi
801033c8:	56                   	push   %esi
801033c9:	53                   	push   %ebx
801033ca:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
801033cd:	e8 5e fe ff ff       	call   80103230 <myproc>
801033d2:	89 c3                	mov    %eax,%ebx
  if((np = allocproc()) == 0){
801033d4:	e8 c2 fc ff ff       	call   8010309b <allocproc>
801033d9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801033dc:	85 c0                	test   %eax,%eax
801033de:	0f 84 e0 00 00 00    	je     801034c4 <fork+0x100>
801033e4:	89 c7                	mov    %eax,%edi
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0){ //pid???????????????????
801033e6:	83 ec 08             	sub    $0x8,%esp
801033e9:	ff 33                	pushl  (%ebx)
801033eb:	ff 73 04             	pushl  0x4(%ebx)
801033ee:	e8 e7 2f 00 00       	call   801063da <copyuvm>
801033f3:	89 47 04             	mov    %eax,0x4(%edi)
801033f6:	83 c4 10             	add    $0x10,%esp
801033f9:	85 c0                	test   %eax,%eax
801033fb:	74 2a                	je     80103427 <fork+0x63>
  np->sz = curproc->sz;
801033fd:	8b 03                	mov    (%ebx),%eax
801033ff:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80103402:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
80103404:	89 c8                	mov    %ecx,%eax
80103406:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
80103409:	8b 73 18             	mov    0x18(%ebx),%esi
8010340c:	8b 79 18             	mov    0x18(%ecx),%edi
8010340f:	b9 13 00 00 00       	mov    $0x13,%ecx
80103414:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
80103416:	8b 40 18             	mov    0x18(%eax),%eax
80103419:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for(i = 0; i < NOFILE; i++)
80103420:	be 00 00 00 00       	mov    $0x0,%esi
80103425:	eb 29                	jmp    80103450 <fork+0x8c>
    kfree(np->kstack);
80103427:	83 ec 0c             	sub    $0xc,%esp
8010342a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
8010342d:	ff 73 08             	pushl  0x8(%ebx)
80103430:	e8 6f eb ff ff       	call   80101fa4 <kfree>
    np->kstack = 0;
80103435:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
8010343c:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
80103443:	83 c4 10             	add    $0x10,%esp
80103446:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010344b:	eb 6d                	jmp    801034ba <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
8010344d:	83 c6 01             	add    $0x1,%esi
80103450:	83 fe 0f             	cmp    $0xf,%esi
80103453:	7f 1d                	jg     80103472 <fork+0xae>
    if(curproc->ofile[i])
80103455:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
80103459:	85 c0                	test   %eax,%eax
8010345b:	74 f0                	je     8010344d <fork+0x89>
      np->ofile[i] = filedup(curproc->ofile[i]);
8010345d:	83 ec 0c             	sub    $0xc,%esp
80103460:	50                   	push   %eax
80103461:	e8 28 d8 ff ff       	call   80100c8e <filedup>
80103466:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103469:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
8010346d:	83 c4 10             	add    $0x10,%esp
80103470:	eb db                	jmp    8010344d <fork+0x89>
  np->cwd = idup(curproc->cwd);
80103472:	83 ec 0c             	sub    $0xc,%esp
80103475:	ff 73 68             	pushl  0x68(%ebx)
80103478:	e8 d4 e0 ff ff       	call   80101551 <idup>
8010347d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103480:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
80103483:	83 c3 6c             	add    $0x6c,%ebx
80103486:	8d 47 6c             	lea    0x6c(%edi),%eax
80103489:	83 c4 0c             	add    $0xc,%esp
8010348c:	6a 10                	push   $0x10
8010348e:	53                   	push   %ebx
8010348f:	50                   	push   %eax
80103490:	e8 01 0a 00 00       	call   80103e96 <safestrcpy>
  pid = np->pid;
80103495:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
80103498:	c7 04 24 a0 c6 16 80 	movl   $0x8016c6a0,(%esp)
8010349f:	e8 df 07 00 00       	call   80103c83 <acquire>
  np->state = RUNNABLE;
801034a4:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
801034ab:	c7 04 24 a0 c6 16 80 	movl   $0x8016c6a0,(%esp)
801034b2:	e8 31 08 00 00       	call   80103ce8 <release>
  return pid;
801034b7:	83 c4 10             	add    $0x10,%esp
}
801034ba:	89 d8                	mov    %ebx,%eax
801034bc:	8d 65 f4             	lea    -0xc(%ebp),%esp
801034bf:	5b                   	pop    %ebx
801034c0:	5e                   	pop    %esi
801034c1:	5f                   	pop    %edi
801034c2:	5d                   	pop    %ebp
801034c3:	c3                   	ret    
    return -1;
801034c4:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801034c9:	eb ef                	jmp    801034ba <fork+0xf6>

801034cb <scheduler>:
{
801034cb:	55                   	push   %ebp
801034cc:	89 e5                	mov    %esp,%ebp
801034ce:	56                   	push   %esi
801034cf:	53                   	push   %ebx
  struct cpu *c = mycpu();
801034d0:	e8 e4 fc ff ff       	call   801031b9 <mycpu>
801034d5:	89 c6                	mov    %eax,%esi
  c->proc = 0;
801034d7:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
801034de:	00 00 00 
801034e1:	eb 5a                	jmp    8010353d <scheduler+0x72>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801034e3:	83 c3 7c             	add    $0x7c,%ebx
801034e6:	81 fb d4 e5 16 80    	cmp    $0x8016e5d4,%ebx
801034ec:	73 3f                	jae    8010352d <scheduler+0x62>
      if(p->state != RUNNABLE)
801034ee:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
801034f2:	75 ef                	jne    801034e3 <scheduler+0x18>
      c->proc = p;
801034f4:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
801034fa:	83 ec 0c             	sub    $0xc,%esp
801034fd:	53                   	push   %ebx
801034fe:	e8 19 2a 00 00       	call   80105f1c <switchuvm>
      p->state = RUNNING;
80103503:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
8010350a:	83 c4 08             	add    $0x8,%esp
8010350d:	ff 73 1c             	pushl  0x1c(%ebx)
80103510:	8d 46 04             	lea    0x4(%esi),%eax
80103513:	50                   	push   %eax
80103514:	e8 d0 09 00 00       	call   80103ee9 <swtch>
      switchkvm();
80103519:	e8 ec 29 00 00       	call   80105f0a <switchkvm>
      c->proc = 0;
8010351e:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
80103525:	00 00 00 
80103528:	83 c4 10             	add    $0x10,%esp
8010352b:	eb b6                	jmp    801034e3 <scheduler+0x18>
    release(&ptable.lock);
8010352d:	83 ec 0c             	sub    $0xc,%esp
80103530:	68 a0 c6 16 80       	push   $0x8016c6a0
80103535:	e8 ae 07 00 00       	call   80103ce8 <release>
    sti();
8010353a:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
8010353d:	fb                   	sti    
    acquire(&ptable.lock);
8010353e:	83 ec 0c             	sub    $0xc,%esp
80103541:	68 a0 c6 16 80       	push   $0x8016c6a0
80103546:	e8 38 07 00 00       	call   80103c83 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010354b:	83 c4 10             	add    $0x10,%esp
8010354e:	bb d4 c6 16 80       	mov    $0x8016c6d4,%ebx
80103553:	eb 91                	jmp    801034e6 <scheduler+0x1b>

80103555 <sched>:
{
80103555:	55                   	push   %ebp
80103556:	89 e5                	mov    %esp,%ebp
80103558:	56                   	push   %esi
80103559:	53                   	push   %ebx
  struct proc *p = myproc();
8010355a:	e8 d1 fc ff ff       	call   80103230 <myproc>
8010355f:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
80103561:	83 ec 0c             	sub    $0xc,%esp
80103564:	68 a0 c6 16 80       	push   $0x8016c6a0
80103569:	e8 d5 06 00 00       	call   80103c43 <holding>
8010356e:	83 c4 10             	add    $0x10,%esp
80103571:	85 c0                	test   %eax,%eax
80103573:	74 4f                	je     801035c4 <sched+0x6f>
  if(mycpu()->ncli != 1)
80103575:	e8 3f fc ff ff       	call   801031b9 <mycpu>
8010357a:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
80103581:	75 4e                	jne    801035d1 <sched+0x7c>
  if(p->state == RUNNING)
80103583:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
80103587:	74 55                	je     801035de <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103589:	9c                   	pushf  
8010358a:	58                   	pop    %eax
  if(readeflags()&FL_IF)
8010358b:	f6 c4 02             	test   $0x2,%ah
8010358e:	75 5b                	jne    801035eb <sched+0x96>
  intena = mycpu()->intena;
80103590:	e8 24 fc ff ff       	call   801031b9 <mycpu>
80103595:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
8010359b:	e8 19 fc ff ff       	call   801031b9 <mycpu>
801035a0:	83 ec 08             	sub    $0x8,%esp
801035a3:	ff 70 04             	pushl  0x4(%eax)
801035a6:	83 c3 1c             	add    $0x1c,%ebx
801035a9:	53                   	push   %ebx
801035aa:	e8 3a 09 00 00       	call   80103ee9 <swtch>
  mycpu()->intena = intena;
801035af:	e8 05 fc ff ff       	call   801031b9 <mycpu>
801035b4:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
801035ba:	83 c4 10             	add    $0x10,%esp
801035bd:	8d 65 f8             	lea    -0x8(%ebp),%esp
801035c0:	5b                   	pop    %ebx
801035c1:	5e                   	pop    %esi
801035c2:	5d                   	pop    %ebp
801035c3:	c3                   	ret    
    panic("sched ptable.lock");
801035c4:	83 ec 0c             	sub    $0xc,%esp
801035c7:	68 10 6b 10 80       	push   $0x80106b10
801035cc:	e8 77 cd ff ff       	call   80100348 <panic>
    panic("sched locks");
801035d1:	83 ec 0c             	sub    $0xc,%esp
801035d4:	68 22 6b 10 80       	push   $0x80106b22
801035d9:	e8 6a cd ff ff       	call   80100348 <panic>
    panic("sched running");
801035de:	83 ec 0c             	sub    $0xc,%esp
801035e1:	68 2e 6b 10 80       	push   $0x80106b2e
801035e6:	e8 5d cd ff ff       	call   80100348 <panic>
    panic("sched interruptible");
801035eb:	83 ec 0c             	sub    $0xc,%esp
801035ee:	68 3c 6b 10 80       	push   $0x80106b3c
801035f3:	e8 50 cd ff ff       	call   80100348 <panic>

801035f8 <exit>:
{
801035f8:	55                   	push   %ebp
801035f9:	89 e5                	mov    %esp,%ebp
801035fb:	56                   	push   %esi
801035fc:	53                   	push   %ebx
  struct proc *curproc = myproc();
801035fd:	e8 2e fc ff ff       	call   80103230 <myproc>
  if(curproc == initproc)
80103602:	39 05 b8 95 10 80    	cmp    %eax,0x801095b8
80103608:	74 09                	je     80103613 <exit+0x1b>
8010360a:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
8010360c:	bb 00 00 00 00       	mov    $0x0,%ebx
80103611:	eb 10                	jmp    80103623 <exit+0x2b>
    panic("init exiting");
80103613:	83 ec 0c             	sub    $0xc,%esp
80103616:	68 50 6b 10 80       	push   $0x80106b50
8010361b:	e8 28 cd ff ff       	call   80100348 <panic>
  for(fd = 0; fd < NOFILE; fd++){
80103620:	83 c3 01             	add    $0x1,%ebx
80103623:	83 fb 0f             	cmp    $0xf,%ebx
80103626:	7f 1e                	jg     80103646 <exit+0x4e>
    if(curproc->ofile[fd]){
80103628:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
8010362c:	85 c0                	test   %eax,%eax
8010362e:	74 f0                	je     80103620 <exit+0x28>
      fileclose(curproc->ofile[fd]);
80103630:	83 ec 0c             	sub    $0xc,%esp
80103633:	50                   	push   %eax
80103634:	e8 9a d6 ff ff       	call   80100cd3 <fileclose>
      curproc->ofile[fd] = 0;
80103639:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
80103640:	00 
80103641:	83 c4 10             	add    $0x10,%esp
80103644:	eb da                	jmp    80103620 <exit+0x28>
  begin_op();
80103646:	e8 9d f1 ff ff       	call   801027e8 <begin_op>
  iput(curproc->cwd);
8010364b:	83 ec 0c             	sub    $0xc,%esp
8010364e:	ff 76 68             	pushl  0x68(%esi)
80103651:	e8 32 e0 ff ff       	call   80101688 <iput>
  end_op();
80103656:	e8 07 f2 ff ff       	call   80102862 <end_op>
  curproc->cwd = 0;
8010365b:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
80103662:	c7 04 24 a0 c6 16 80 	movl   $0x8016c6a0,(%esp)
80103669:	e8 15 06 00 00       	call   80103c83 <acquire>
  wakeup1(curproc->parent);
8010366e:	8b 46 14             	mov    0x14(%esi),%eax
80103671:	e8 fa f9 ff ff       	call   80103070 <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103676:	83 c4 10             	add    $0x10,%esp
80103679:	bb d4 c6 16 80       	mov    $0x8016c6d4,%ebx
8010367e:	eb 03                	jmp    80103683 <exit+0x8b>
80103680:	83 c3 7c             	add    $0x7c,%ebx
80103683:	81 fb d4 e5 16 80    	cmp    $0x8016e5d4,%ebx
80103689:	73 1a                	jae    801036a5 <exit+0xad>
    if(p->parent == curproc){
8010368b:	39 73 14             	cmp    %esi,0x14(%ebx)
8010368e:	75 f0                	jne    80103680 <exit+0x88>
      p->parent = initproc;
80103690:	a1 b8 95 10 80       	mov    0x801095b8,%eax
80103695:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
80103698:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
8010369c:	75 e2                	jne    80103680 <exit+0x88>
        wakeup1(initproc);
8010369e:	e8 cd f9 ff ff       	call   80103070 <wakeup1>
801036a3:	eb db                	jmp    80103680 <exit+0x88>
  curproc->state = ZOMBIE;
801036a5:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
801036ac:	e8 a4 fe ff ff       	call   80103555 <sched>
  panic("zombie exit");
801036b1:	83 ec 0c             	sub    $0xc,%esp
801036b4:	68 5d 6b 10 80       	push   $0x80106b5d
801036b9:	e8 8a cc ff ff       	call   80100348 <panic>

801036be <yield>:
{
801036be:	55                   	push   %ebp
801036bf:	89 e5                	mov    %esp,%ebp
801036c1:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
801036c4:	68 a0 c6 16 80       	push   $0x8016c6a0
801036c9:	e8 b5 05 00 00       	call   80103c83 <acquire>
  myproc()->state = RUNNABLE;
801036ce:	e8 5d fb ff ff       	call   80103230 <myproc>
801036d3:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
801036da:	e8 76 fe ff ff       	call   80103555 <sched>
  release(&ptable.lock);
801036df:	c7 04 24 a0 c6 16 80 	movl   $0x8016c6a0,(%esp)
801036e6:	e8 fd 05 00 00       	call   80103ce8 <release>
}
801036eb:	83 c4 10             	add    $0x10,%esp
801036ee:	c9                   	leave  
801036ef:	c3                   	ret    

801036f0 <sleep>:
{
801036f0:	55                   	push   %ebp
801036f1:	89 e5                	mov    %esp,%ebp
801036f3:	56                   	push   %esi
801036f4:	53                   	push   %ebx
801036f5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
801036f8:	e8 33 fb ff ff       	call   80103230 <myproc>
  if(p == 0)
801036fd:	85 c0                	test   %eax,%eax
801036ff:	74 66                	je     80103767 <sleep+0x77>
80103701:	89 c6                	mov    %eax,%esi
  if(lk == 0)
80103703:	85 db                	test   %ebx,%ebx
80103705:	74 6d                	je     80103774 <sleep+0x84>
  if(lk != &ptable.lock){  //DOC: sleeplock0
80103707:	81 fb a0 c6 16 80    	cmp    $0x8016c6a0,%ebx
8010370d:	74 18                	je     80103727 <sleep+0x37>
    acquire(&ptable.lock);  //DOC: sleeplock1
8010370f:	83 ec 0c             	sub    $0xc,%esp
80103712:	68 a0 c6 16 80       	push   $0x8016c6a0
80103717:	e8 67 05 00 00       	call   80103c83 <acquire>
    release(lk);
8010371c:	89 1c 24             	mov    %ebx,(%esp)
8010371f:	e8 c4 05 00 00       	call   80103ce8 <release>
80103724:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
80103727:	8b 45 08             	mov    0x8(%ebp),%eax
8010372a:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
8010372d:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
80103734:	e8 1c fe ff ff       	call   80103555 <sched>
  p->chan = 0;
80103739:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if(lk != &ptable.lock){  //DOC: sleeplock2
80103740:	81 fb a0 c6 16 80    	cmp    $0x8016c6a0,%ebx
80103746:	74 18                	je     80103760 <sleep+0x70>
    release(&ptable.lock);
80103748:	83 ec 0c             	sub    $0xc,%esp
8010374b:	68 a0 c6 16 80       	push   $0x8016c6a0
80103750:	e8 93 05 00 00       	call   80103ce8 <release>
    acquire(lk);
80103755:	89 1c 24             	mov    %ebx,(%esp)
80103758:	e8 26 05 00 00       	call   80103c83 <acquire>
8010375d:	83 c4 10             	add    $0x10,%esp
}
80103760:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103763:	5b                   	pop    %ebx
80103764:	5e                   	pop    %esi
80103765:	5d                   	pop    %ebp
80103766:	c3                   	ret    
    panic("sleep");
80103767:	83 ec 0c             	sub    $0xc,%esp
8010376a:	68 69 6b 10 80       	push   $0x80106b69
8010376f:	e8 d4 cb ff ff       	call   80100348 <panic>
    panic("sleep without lk");
80103774:	83 ec 0c             	sub    $0xc,%esp
80103777:	68 6f 6b 10 80       	push   $0x80106b6f
8010377c:	e8 c7 cb ff ff       	call   80100348 <panic>

80103781 <wait>:
{
80103781:	55                   	push   %ebp
80103782:	89 e5                	mov    %esp,%ebp
80103784:	56                   	push   %esi
80103785:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103786:	e8 a5 fa ff ff       	call   80103230 <myproc>
8010378b:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
8010378d:	83 ec 0c             	sub    $0xc,%esp
80103790:	68 a0 c6 16 80       	push   $0x8016c6a0
80103795:	e8 e9 04 00 00       	call   80103c83 <acquire>
8010379a:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
8010379d:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801037a2:	bb d4 c6 16 80       	mov    $0x8016c6d4,%ebx
801037a7:	eb 5b                	jmp    80103804 <wait+0x83>
        pid = p->pid;
801037a9:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
801037ac:	83 ec 0c             	sub    $0xc,%esp
801037af:	ff 73 08             	pushl  0x8(%ebx)
801037b2:	e8 ed e7 ff ff       	call   80101fa4 <kfree>
        p->kstack = 0;
801037b7:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
801037be:	83 c4 04             	add    $0x4,%esp
801037c1:	ff 73 04             	pushl  0x4(%ebx)
801037c4:	e8 f0 2a 00 00       	call   801062b9 <freevm>
        p->pid = 0;
801037c9:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
801037d0:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
801037d7:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
801037db:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
801037e2:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
801037e9:	c7 04 24 a0 c6 16 80 	movl   $0x8016c6a0,(%esp)
801037f0:	e8 f3 04 00 00       	call   80103ce8 <release>
        return pid;
801037f5:	83 c4 10             	add    $0x10,%esp
}
801037f8:	89 f0                	mov    %esi,%eax
801037fa:	8d 65 f8             	lea    -0x8(%ebp),%esp
801037fd:	5b                   	pop    %ebx
801037fe:	5e                   	pop    %esi
801037ff:	5d                   	pop    %ebp
80103800:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103801:	83 c3 7c             	add    $0x7c,%ebx
80103804:	81 fb d4 e5 16 80    	cmp    $0x8016e5d4,%ebx
8010380a:	73 12                	jae    8010381e <wait+0x9d>
      if(p->parent != curproc)
8010380c:	39 73 14             	cmp    %esi,0x14(%ebx)
8010380f:	75 f0                	jne    80103801 <wait+0x80>
      if(p->state == ZOMBIE){
80103811:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103815:	74 92                	je     801037a9 <wait+0x28>
      havekids = 1;
80103817:	b8 01 00 00 00       	mov    $0x1,%eax
8010381c:	eb e3                	jmp    80103801 <wait+0x80>
    if(!havekids || curproc->killed){
8010381e:	85 c0                	test   %eax,%eax
80103820:	74 06                	je     80103828 <wait+0xa7>
80103822:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
80103826:	74 17                	je     8010383f <wait+0xbe>
      release(&ptable.lock);
80103828:	83 ec 0c             	sub    $0xc,%esp
8010382b:	68 a0 c6 16 80       	push   $0x8016c6a0
80103830:	e8 b3 04 00 00       	call   80103ce8 <release>
      return -1;
80103835:	83 c4 10             	add    $0x10,%esp
80103838:	be ff ff ff ff       	mov    $0xffffffff,%esi
8010383d:	eb b9                	jmp    801037f8 <wait+0x77>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
8010383f:	83 ec 08             	sub    $0x8,%esp
80103842:	68 a0 c6 16 80       	push   $0x8016c6a0
80103847:	56                   	push   %esi
80103848:	e8 a3 fe ff ff       	call   801036f0 <sleep>
    havekids = 0;
8010384d:	83 c4 10             	add    $0x10,%esp
80103850:	e9 48 ff ff ff       	jmp    8010379d <wait+0x1c>

80103855 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80103855:	55                   	push   %ebp
80103856:	89 e5                	mov    %esp,%ebp
80103858:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
8010385b:	68 a0 c6 16 80       	push   $0x8016c6a0
80103860:	e8 1e 04 00 00       	call   80103c83 <acquire>
  wakeup1(chan);
80103865:	8b 45 08             	mov    0x8(%ebp),%eax
80103868:	e8 03 f8 ff ff       	call   80103070 <wakeup1>
  release(&ptable.lock);
8010386d:	c7 04 24 a0 c6 16 80 	movl   $0x8016c6a0,(%esp)
80103874:	e8 6f 04 00 00       	call   80103ce8 <release>
}
80103879:	83 c4 10             	add    $0x10,%esp
8010387c:	c9                   	leave  
8010387d:	c3                   	ret    

8010387e <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
8010387e:	55                   	push   %ebp
8010387f:	89 e5                	mov    %esp,%ebp
80103881:	53                   	push   %ebx
80103882:	83 ec 10             	sub    $0x10,%esp
80103885:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
80103888:	68 a0 c6 16 80       	push   $0x8016c6a0
8010388d:	e8 f1 03 00 00       	call   80103c83 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103892:	83 c4 10             	add    $0x10,%esp
80103895:	b8 d4 c6 16 80       	mov    $0x8016c6d4,%eax
8010389a:	3d d4 e5 16 80       	cmp    $0x8016e5d4,%eax
8010389f:	73 3a                	jae    801038db <kill+0x5d>
    if(p->pid == pid){
801038a1:	39 58 10             	cmp    %ebx,0x10(%eax)
801038a4:	74 05                	je     801038ab <kill+0x2d>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801038a6:	83 c0 7c             	add    $0x7c,%eax
801038a9:	eb ef                	jmp    8010389a <kill+0x1c>
      p->killed = 1;
801038ab:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
801038b2:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
801038b6:	74 1a                	je     801038d2 <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
801038b8:	83 ec 0c             	sub    $0xc,%esp
801038bb:	68 a0 c6 16 80       	push   $0x8016c6a0
801038c0:	e8 23 04 00 00       	call   80103ce8 <release>
      return 0;
801038c5:	83 c4 10             	add    $0x10,%esp
801038c8:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
801038cd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801038d0:	c9                   	leave  
801038d1:	c3                   	ret    
        p->state = RUNNABLE;
801038d2:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
801038d9:	eb dd                	jmp    801038b8 <kill+0x3a>
  release(&ptable.lock);
801038db:	83 ec 0c             	sub    $0xc,%esp
801038de:	68 a0 c6 16 80       	push   $0x8016c6a0
801038e3:	e8 00 04 00 00       	call   80103ce8 <release>
  return -1;
801038e8:	83 c4 10             	add    $0x10,%esp
801038eb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801038f0:	eb db                	jmp    801038cd <kill+0x4f>

801038f2 <dump_physmem>:

//find which process owns each frame of physical memory
int dump_physmem(int *frames, int *pids, int numframes)
{
801038f2:	55                   	push   %ebp
801038f3:	89 e5                	mov    %esp,%ebp
801038f5:	57                   	push   %edi
801038f6:	56                   	push   %esi
801038f7:	53                   	push   %ebx
801038f8:	83 ec 0c             	sub    $0xc,%esp
801038fb:	8b 7d 0c             	mov    0xc(%ebp),%edi
801038fe:	8b 75 10             	mov    0x10(%ebp),%esi
  if(pids <= 0 || numframes <= 0){
80103901:	85 ff                	test   %edi,%edi
80103903:	0f 94 c2             	sete   %dl
80103906:	85 f6                	test   %esi,%esi
80103908:	0f 9e c0             	setle  %al
8010390b:	08 c2                	or     %al,%dl
8010390d:	75 6d                	jne    8010397c <dump_physmem+0x8a>
    return -1;
  }
  if(numframes > NFRAME || numframes < 0){
8010390f:	81 fe 00 40 00 00    	cmp    $0x4000,%esi
80103915:	77 6c                	ja     80103983 <dump_physmem+0x91>
      pids[index] = FRAMES[i];
      index++;
    }
  }
  */
  for(int i=65; i<log_index; i++){
80103917:	bb 41 00 00 00       	mov    $0x41,%ebx
8010391c:	eb 03                	jmp    80103921 <dump_physmem+0x2f>
8010391e:	83 c3 01             	add    $0x1,%ebx
80103921:	39 1d 2c 99 14 80    	cmp    %ebx,0x8014992c
80103927:	7e 46                	jle    8010396f <dump_physmem+0x7d>
    if(i-65 < numframes){
80103929:	8d 43 bf             	lea    -0x41(%ebx),%eax
8010392c:	39 f0                	cmp    %esi,%eax
8010392e:	7d ee                	jge    8010391e <dump_physmem+0x2c>
      frames[i-65] = log_frames[i];
80103930:	8d 14 9d fc fe ff ff 	lea    -0x104(,%ebx,4),%edx
80103937:	8b 0c 9d 40 99 14 80 	mov    -0x7feb66c0(,%ebx,4),%ecx
8010393e:	8b 7d 08             	mov    0x8(%ebp),%edi
80103941:	89 0c 17             	mov    %ecx,(%edi,%edx,1)
      pids[i-65] = log_pids[i];
80103944:	8b 0c 9d 40 99 15 80 	mov    -0x7fea66c0(,%ebx,4),%ecx
8010394b:	8b 7d 0c             	mov    0xc(%ebp),%edi
8010394e:	89 0c 17             	mov    %ecx,(%edi,%edx,1)
      cprintf("~~~~~~~~~~~index: %d, frame:%d, pid:%d\n", i-65, log_frames[i], log_pids[i]);
80103951:	ff 34 9d 40 99 15 80 	pushl  -0x7fea66c0(,%ebx,4)
80103958:	ff 34 9d 40 99 14 80 	pushl  -0x7feb66c0(,%ebx,4)
8010395f:	50                   	push   %eax
80103960:	68 e0 6b 10 80       	push   $0x80106be0
80103965:	e8 a1 cc ff ff       	call   8010060b <cprintf>
8010396a:	83 c4 10             	add    $0x10,%esp
8010396d:	eb af                	jmp    8010391e <dump_physmem+0x2c>
    }
  }
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~eeeeee\n");
  return 0;
8010396f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103974:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103977:	5b                   	pop    %ebx
80103978:	5e                   	pop    %esi
80103979:	5f                   	pop    %edi
8010397a:	5d                   	pop    %ebp
8010397b:	c3                   	ret    
    return -1;
8010397c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103981:	eb f1                	jmp    80103974 <dump_physmem+0x82>
    return -1;
80103983:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103988:	eb ea                	jmp    80103974 <dump_physmem+0x82>

8010398a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
8010398a:	55                   	push   %ebp
8010398b:	89 e5                	mov    %esp,%ebp
8010398d:	56                   	push   %esi
8010398e:	53                   	push   %ebx
8010398f:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103992:	bb d4 c6 16 80       	mov    $0x8016c6d4,%ebx
80103997:	eb 33                	jmp    801039cc <procdump+0x42>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
80103999:	b8 80 6b 10 80       	mov    $0x80106b80,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
8010399e:	8d 53 6c             	lea    0x6c(%ebx),%edx
801039a1:	52                   	push   %edx
801039a2:	50                   	push   %eax
801039a3:	ff 73 10             	pushl  0x10(%ebx)
801039a6:	68 84 6b 10 80       	push   $0x80106b84
801039ab:	e8 5b cc ff ff       	call   8010060b <cprintf>
    if(p->state == SLEEPING){
801039b0:	83 c4 10             	add    $0x10,%esp
801039b3:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
801039b7:	74 39                	je     801039f2 <procdump+0x68>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
801039b9:	83 ec 0c             	sub    $0xc,%esp
801039bc:	68 1b 6f 10 80       	push   $0x80106f1b
801039c1:	e8 45 cc ff ff       	call   8010060b <cprintf>
801039c6:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801039c9:	83 c3 7c             	add    $0x7c,%ebx
801039cc:	81 fb d4 e5 16 80    	cmp    $0x8016e5d4,%ebx
801039d2:	73 61                	jae    80103a35 <procdump+0xab>
    if(p->state == UNUSED)
801039d4:	8b 43 0c             	mov    0xc(%ebx),%eax
801039d7:	85 c0                	test   %eax,%eax
801039d9:	74 ee                	je     801039c9 <procdump+0x3f>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
801039db:	83 f8 05             	cmp    $0x5,%eax
801039de:	77 b9                	ja     80103999 <procdump+0xf>
801039e0:	8b 04 85 08 6c 10 80 	mov    -0x7fef93f8(,%eax,4),%eax
801039e7:	85 c0                	test   %eax,%eax
801039e9:	75 b3                	jne    8010399e <procdump+0x14>
      state = "???";
801039eb:	b8 80 6b 10 80       	mov    $0x80106b80,%eax
801039f0:	eb ac                	jmp    8010399e <procdump+0x14>
      getcallerpcs((uint*)p->context->ebp+2, pc);
801039f2:	8b 43 1c             	mov    0x1c(%ebx),%eax
801039f5:	8b 40 0c             	mov    0xc(%eax),%eax
801039f8:	83 c0 08             	add    $0x8,%eax
801039fb:	83 ec 08             	sub    $0x8,%esp
801039fe:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103a01:	52                   	push   %edx
80103a02:	50                   	push   %eax
80103a03:	e8 5a 01 00 00       	call   80103b62 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80103a08:	83 c4 10             	add    $0x10,%esp
80103a0b:	be 00 00 00 00       	mov    $0x0,%esi
80103a10:	eb 14                	jmp    80103a26 <procdump+0x9c>
        cprintf(" %p", pc[i]);
80103a12:	83 ec 08             	sub    $0x8,%esp
80103a15:	50                   	push   %eax
80103a16:	68 c1 65 10 80       	push   $0x801065c1
80103a1b:	e8 eb cb ff ff       	call   8010060b <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
80103a20:	83 c6 01             	add    $0x1,%esi
80103a23:	83 c4 10             	add    $0x10,%esp
80103a26:	83 fe 09             	cmp    $0x9,%esi
80103a29:	7f 8e                	jg     801039b9 <procdump+0x2f>
80103a2b:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103a2f:	85 c0                	test   %eax,%eax
80103a31:	75 df                	jne    80103a12 <procdump+0x88>
80103a33:	eb 84                	jmp    801039b9 <procdump+0x2f>
  }
}
80103a35:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103a38:	5b                   	pop    %ebx
80103a39:	5e                   	pop    %esi
80103a3a:	5d                   	pop    %ebp
80103a3b:	c3                   	ret    

80103a3c <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103a3c:	55                   	push   %ebp
80103a3d:	89 e5                	mov    %esp,%ebp
80103a3f:	53                   	push   %ebx
80103a40:	83 ec 0c             	sub    $0xc,%esp
80103a43:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103a46:	68 20 6c 10 80       	push   $0x80106c20
80103a4b:	8d 43 04             	lea    0x4(%ebx),%eax
80103a4e:	50                   	push   %eax
80103a4f:	e8 f3 00 00 00       	call   80103b47 <initlock>
  lk->name = name;
80103a54:	8b 45 0c             	mov    0xc(%ebp),%eax
80103a57:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103a5a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103a60:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103a67:	83 c4 10             	add    $0x10,%esp
80103a6a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103a6d:	c9                   	leave  
80103a6e:	c3                   	ret    

80103a6f <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103a6f:	55                   	push   %ebp
80103a70:	89 e5                	mov    %esp,%ebp
80103a72:	56                   	push   %esi
80103a73:	53                   	push   %ebx
80103a74:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103a77:	8d 73 04             	lea    0x4(%ebx),%esi
80103a7a:	83 ec 0c             	sub    $0xc,%esp
80103a7d:	56                   	push   %esi
80103a7e:	e8 00 02 00 00       	call   80103c83 <acquire>
  while (lk->locked) {
80103a83:	83 c4 10             	add    $0x10,%esp
80103a86:	eb 0d                	jmp    80103a95 <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103a88:	83 ec 08             	sub    $0x8,%esp
80103a8b:	56                   	push   %esi
80103a8c:	53                   	push   %ebx
80103a8d:	e8 5e fc ff ff       	call   801036f0 <sleep>
80103a92:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103a95:	83 3b 00             	cmpl   $0x0,(%ebx)
80103a98:	75 ee                	jne    80103a88 <acquiresleep+0x19>
  }
  lk->locked = 1;
80103a9a:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103aa0:	e8 8b f7 ff ff       	call   80103230 <myproc>
80103aa5:	8b 40 10             	mov    0x10(%eax),%eax
80103aa8:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103aab:	83 ec 0c             	sub    $0xc,%esp
80103aae:	56                   	push   %esi
80103aaf:	e8 34 02 00 00       	call   80103ce8 <release>
}
80103ab4:	83 c4 10             	add    $0x10,%esp
80103ab7:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103aba:	5b                   	pop    %ebx
80103abb:	5e                   	pop    %esi
80103abc:	5d                   	pop    %ebp
80103abd:	c3                   	ret    

80103abe <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103abe:	55                   	push   %ebp
80103abf:	89 e5                	mov    %esp,%ebp
80103ac1:	56                   	push   %esi
80103ac2:	53                   	push   %ebx
80103ac3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103ac6:	8d 73 04             	lea    0x4(%ebx),%esi
80103ac9:	83 ec 0c             	sub    $0xc,%esp
80103acc:	56                   	push   %esi
80103acd:	e8 b1 01 00 00       	call   80103c83 <acquire>
  lk->locked = 0;
80103ad2:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103ad8:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103adf:	89 1c 24             	mov    %ebx,(%esp)
80103ae2:	e8 6e fd ff ff       	call   80103855 <wakeup>
  release(&lk->lk);
80103ae7:	89 34 24             	mov    %esi,(%esp)
80103aea:	e8 f9 01 00 00       	call   80103ce8 <release>
}
80103aef:	83 c4 10             	add    $0x10,%esp
80103af2:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103af5:	5b                   	pop    %ebx
80103af6:	5e                   	pop    %esi
80103af7:	5d                   	pop    %ebp
80103af8:	c3                   	ret    

80103af9 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103af9:	55                   	push   %ebp
80103afa:	89 e5                	mov    %esp,%ebp
80103afc:	56                   	push   %esi
80103afd:	53                   	push   %ebx
80103afe:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103b01:	8d 73 04             	lea    0x4(%ebx),%esi
80103b04:	83 ec 0c             	sub    $0xc,%esp
80103b07:	56                   	push   %esi
80103b08:	e8 76 01 00 00       	call   80103c83 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103b0d:	83 c4 10             	add    $0x10,%esp
80103b10:	83 3b 00             	cmpl   $0x0,(%ebx)
80103b13:	75 17                	jne    80103b2c <holdingsleep+0x33>
80103b15:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103b1a:	83 ec 0c             	sub    $0xc,%esp
80103b1d:	56                   	push   %esi
80103b1e:	e8 c5 01 00 00       	call   80103ce8 <release>
  return r;
}
80103b23:	89 d8                	mov    %ebx,%eax
80103b25:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b28:	5b                   	pop    %ebx
80103b29:	5e                   	pop    %esi
80103b2a:	5d                   	pop    %ebp
80103b2b:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103b2c:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103b2f:	e8 fc f6 ff ff       	call   80103230 <myproc>
80103b34:	3b 58 10             	cmp    0x10(%eax),%ebx
80103b37:	74 07                	je     80103b40 <holdingsleep+0x47>
80103b39:	bb 00 00 00 00       	mov    $0x0,%ebx
80103b3e:	eb da                	jmp    80103b1a <holdingsleep+0x21>
80103b40:	bb 01 00 00 00       	mov    $0x1,%ebx
80103b45:	eb d3                	jmp    80103b1a <holdingsleep+0x21>

80103b47 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103b47:	55                   	push   %ebp
80103b48:	89 e5                	mov    %esp,%ebp
80103b4a:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103b4d:	8b 55 0c             	mov    0xc(%ebp),%edx
80103b50:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103b53:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103b59:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103b60:	5d                   	pop    %ebp
80103b61:	c3                   	ret    

80103b62 <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103b62:	55                   	push   %ebp
80103b63:	89 e5                	mov    %esp,%ebp
80103b65:	53                   	push   %ebx
80103b66:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103b69:	8b 45 08             	mov    0x8(%ebp),%eax
80103b6c:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103b6f:	b8 00 00 00 00       	mov    $0x0,%eax
80103b74:	83 f8 09             	cmp    $0x9,%eax
80103b77:	7f 25                	jg     80103b9e <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103b79:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103b7f:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103b85:	77 17                	ja     80103b9e <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103b87:	8b 5a 04             	mov    0x4(%edx),%ebx
80103b8a:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103b8d:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103b8f:	83 c0 01             	add    $0x1,%eax
80103b92:	eb e0                	jmp    80103b74 <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103b94:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103b9b:	83 c0 01             	add    $0x1,%eax
80103b9e:	83 f8 09             	cmp    $0x9,%eax
80103ba1:	7e f1                	jle    80103b94 <getcallerpcs+0x32>
}
80103ba3:	5b                   	pop    %ebx
80103ba4:	5d                   	pop    %ebp
80103ba5:	c3                   	ret    

80103ba6 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103ba6:	55                   	push   %ebp
80103ba7:	89 e5                	mov    %esp,%ebp
80103ba9:	53                   	push   %ebx
80103baa:	83 ec 04             	sub    $0x4,%esp
80103bad:	9c                   	pushf  
80103bae:	5b                   	pop    %ebx
  asm volatile("cli");
80103baf:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103bb0:	e8 04 f6 ff ff       	call   801031b9 <mycpu>
80103bb5:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103bbc:	74 12                	je     80103bd0 <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103bbe:	e8 f6 f5 ff ff       	call   801031b9 <mycpu>
80103bc3:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103bca:	83 c4 04             	add    $0x4,%esp
80103bcd:	5b                   	pop    %ebx
80103bce:	5d                   	pop    %ebp
80103bcf:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103bd0:	e8 e4 f5 ff ff       	call   801031b9 <mycpu>
80103bd5:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103bdb:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103be1:	eb db                	jmp    80103bbe <pushcli+0x18>

80103be3 <popcli>:

void
popcli(void)
{
80103be3:	55                   	push   %ebp
80103be4:	89 e5                	mov    %esp,%ebp
80103be6:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103be9:	9c                   	pushf  
80103bea:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103beb:	f6 c4 02             	test   $0x2,%ah
80103bee:	75 28                	jne    80103c18 <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103bf0:	e8 c4 f5 ff ff       	call   801031b9 <mycpu>
80103bf5:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103bfb:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103bfe:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103c04:	85 d2                	test   %edx,%edx
80103c06:	78 1d                	js     80103c25 <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103c08:	e8 ac f5 ff ff       	call   801031b9 <mycpu>
80103c0d:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103c14:	74 1c                	je     80103c32 <popcli+0x4f>
    sti();
}
80103c16:	c9                   	leave  
80103c17:	c3                   	ret    
    panic("popcli - interruptible");
80103c18:	83 ec 0c             	sub    $0xc,%esp
80103c1b:	68 2b 6c 10 80       	push   $0x80106c2b
80103c20:	e8 23 c7 ff ff       	call   80100348 <panic>
    panic("popcli");
80103c25:	83 ec 0c             	sub    $0xc,%esp
80103c28:	68 42 6c 10 80       	push   $0x80106c42
80103c2d:	e8 16 c7 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103c32:	e8 82 f5 ff ff       	call   801031b9 <mycpu>
80103c37:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103c3e:	74 d6                	je     80103c16 <popcli+0x33>
  asm volatile("sti");
80103c40:	fb                   	sti    
}
80103c41:	eb d3                	jmp    80103c16 <popcli+0x33>

80103c43 <holding>:
{
80103c43:	55                   	push   %ebp
80103c44:	89 e5                	mov    %esp,%ebp
80103c46:	53                   	push   %ebx
80103c47:	83 ec 04             	sub    $0x4,%esp
80103c4a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103c4d:	e8 54 ff ff ff       	call   80103ba6 <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103c52:	83 3b 00             	cmpl   $0x0,(%ebx)
80103c55:	75 12                	jne    80103c69 <holding+0x26>
80103c57:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103c5c:	e8 82 ff ff ff       	call   80103be3 <popcli>
}
80103c61:	89 d8                	mov    %ebx,%eax
80103c63:	83 c4 04             	add    $0x4,%esp
80103c66:	5b                   	pop    %ebx
80103c67:	5d                   	pop    %ebp
80103c68:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103c69:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103c6c:	e8 48 f5 ff ff       	call   801031b9 <mycpu>
80103c71:	39 c3                	cmp    %eax,%ebx
80103c73:	74 07                	je     80103c7c <holding+0x39>
80103c75:	bb 00 00 00 00       	mov    $0x0,%ebx
80103c7a:	eb e0                	jmp    80103c5c <holding+0x19>
80103c7c:	bb 01 00 00 00       	mov    $0x1,%ebx
80103c81:	eb d9                	jmp    80103c5c <holding+0x19>

80103c83 <acquire>:
{
80103c83:	55                   	push   %ebp
80103c84:	89 e5                	mov    %esp,%ebp
80103c86:	53                   	push   %ebx
80103c87:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103c8a:	e8 17 ff ff ff       	call   80103ba6 <pushcli>
  if(holding(lk))
80103c8f:	83 ec 0c             	sub    $0xc,%esp
80103c92:	ff 75 08             	pushl  0x8(%ebp)
80103c95:	e8 a9 ff ff ff       	call   80103c43 <holding>
80103c9a:	83 c4 10             	add    $0x10,%esp
80103c9d:	85 c0                	test   %eax,%eax
80103c9f:	75 3a                	jne    80103cdb <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103ca1:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103ca4:	b8 01 00 00 00       	mov    $0x1,%eax
80103ca9:	f0 87 02             	lock xchg %eax,(%edx)
80103cac:	85 c0                	test   %eax,%eax
80103cae:	75 f1                	jne    80103ca1 <acquire+0x1e>
  __sync_synchronize();
80103cb0:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103cb5:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103cb8:	e8 fc f4 ff ff       	call   801031b9 <mycpu>
80103cbd:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103cc0:	8b 45 08             	mov    0x8(%ebp),%eax
80103cc3:	83 c0 0c             	add    $0xc,%eax
80103cc6:	83 ec 08             	sub    $0x8,%esp
80103cc9:	50                   	push   %eax
80103cca:	8d 45 08             	lea    0x8(%ebp),%eax
80103ccd:	50                   	push   %eax
80103cce:	e8 8f fe ff ff       	call   80103b62 <getcallerpcs>
}
80103cd3:	83 c4 10             	add    $0x10,%esp
80103cd6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103cd9:	c9                   	leave  
80103cda:	c3                   	ret    
    panic("acquire");
80103cdb:	83 ec 0c             	sub    $0xc,%esp
80103cde:	68 49 6c 10 80       	push   $0x80106c49
80103ce3:	e8 60 c6 ff ff       	call   80100348 <panic>

80103ce8 <release>:
{
80103ce8:	55                   	push   %ebp
80103ce9:	89 e5                	mov    %esp,%ebp
80103ceb:	53                   	push   %ebx
80103cec:	83 ec 10             	sub    $0x10,%esp
80103cef:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103cf2:	53                   	push   %ebx
80103cf3:	e8 4b ff ff ff       	call   80103c43 <holding>
80103cf8:	83 c4 10             	add    $0x10,%esp
80103cfb:	85 c0                	test   %eax,%eax
80103cfd:	74 23                	je     80103d22 <release+0x3a>
  lk->pcs[0] = 0;
80103cff:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103d06:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103d0d:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103d12:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103d18:	e8 c6 fe ff ff       	call   80103be3 <popcli>
}
80103d1d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103d20:	c9                   	leave  
80103d21:	c3                   	ret    
    panic("release");
80103d22:	83 ec 0c             	sub    $0xc,%esp
80103d25:	68 51 6c 10 80       	push   $0x80106c51
80103d2a:	e8 19 c6 ff ff       	call   80100348 <panic>

80103d2f <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103d2f:	55                   	push   %ebp
80103d30:	89 e5                	mov    %esp,%ebp
80103d32:	57                   	push   %edi
80103d33:	53                   	push   %ebx
80103d34:	8b 55 08             	mov    0x8(%ebp),%edx
80103d37:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103d3a:	f6 c2 03             	test   $0x3,%dl
80103d3d:	75 05                	jne    80103d44 <memset+0x15>
80103d3f:	f6 c1 03             	test   $0x3,%cl
80103d42:	74 0e                	je     80103d52 <memset+0x23>
  asm volatile("cld; rep stosb" :
80103d44:	89 d7                	mov    %edx,%edi
80103d46:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d49:	fc                   	cld    
80103d4a:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80103d4c:	89 d0                	mov    %edx,%eax
80103d4e:	5b                   	pop    %ebx
80103d4f:	5f                   	pop    %edi
80103d50:	5d                   	pop    %ebp
80103d51:	c3                   	ret    
    c &= 0xFF;
80103d52:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103d56:	c1 e9 02             	shr    $0x2,%ecx
80103d59:	89 f8                	mov    %edi,%eax
80103d5b:	c1 e0 18             	shl    $0x18,%eax
80103d5e:	89 fb                	mov    %edi,%ebx
80103d60:	c1 e3 10             	shl    $0x10,%ebx
80103d63:	09 d8                	or     %ebx,%eax
80103d65:	89 fb                	mov    %edi,%ebx
80103d67:	c1 e3 08             	shl    $0x8,%ebx
80103d6a:	09 d8                	or     %ebx,%eax
80103d6c:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103d6e:	89 d7                	mov    %edx,%edi
80103d70:	fc                   	cld    
80103d71:	f3 ab                	rep stos %eax,%es:(%edi)
80103d73:	eb d7                	jmp    80103d4c <memset+0x1d>

80103d75 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103d75:	55                   	push   %ebp
80103d76:	89 e5                	mov    %esp,%ebp
80103d78:	56                   	push   %esi
80103d79:	53                   	push   %ebx
80103d7a:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103d7d:	8b 55 0c             	mov    0xc(%ebp),%edx
80103d80:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103d83:	8d 70 ff             	lea    -0x1(%eax),%esi
80103d86:	85 c0                	test   %eax,%eax
80103d88:	74 1c                	je     80103da6 <memcmp+0x31>
    if(*s1 != *s2)
80103d8a:	0f b6 01             	movzbl (%ecx),%eax
80103d8d:	0f b6 1a             	movzbl (%edx),%ebx
80103d90:	38 d8                	cmp    %bl,%al
80103d92:	75 0a                	jne    80103d9e <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
80103d94:	83 c1 01             	add    $0x1,%ecx
80103d97:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103d9a:	89 f0                	mov    %esi,%eax
80103d9c:	eb e5                	jmp    80103d83 <memcmp+0xe>
      return *s1 - *s2;
80103d9e:	0f b6 c0             	movzbl %al,%eax
80103da1:	0f b6 db             	movzbl %bl,%ebx
80103da4:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103da6:	5b                   	pop    %ebx
80103da7:	5e                   	pop    %esi
80103da8:	5d                   	pop    %ebp
80103da9:	c3                   	ret    

80103daa <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103daa:	55                   	push   %ebp
80103dab:	89 e5                	mov    %esp,%ebp
80103dad:	56                   	push   %esi
80103dae:	53                   	push   %ebx
80103daf:	8b 45 08             	mov    0x8(%ebp),%eax
80103db2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103db5:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80103db8:	39 c1                	cmp    %eax,%ecx
80103dba:	73 3a                	jae    80103df6 <memmove+0x4c>
80103dbc:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
80103dbf:	39 c3                	cmp    %eax,%ebx
80103dc1:	76 37                	jbe    80103dfa <memmove+0x50>
    s += n;
    d += n;
80103dc3:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80103dc6:	eb 0d                	jmp    80103dd5 <memmove+0x2b>
      *--d = *--s;
80103dc8:	83 eb 01             	sub    $0x1,%ebx
80103dcb:	83 e9 01             	sub    $0x1,%ecx
80103dce:	0f b6 13             	movzbl (%ebx),%edx
80103dd1:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
80103dd3:	89 f2                	mov    %esi,%edx
80103dd5:	8d 72 ff             	lea    -0x1(%edx),%esi
80103dd8:	85 d2                	test   %edx,%edx
80103dda:	75 ec                	jne    80103dc8 <memmove+0x1e>
80103ddc:	eb 14                	jmp    80103df2 <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80103dde:	0f b6 11             	movzbl (%ecx),%edx
80103de1:	88 13                	mov    %dl,(%ebx)
80103de3:	8d 5b 01             	lea    0x1(%ebx),%ebx
80103de6:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80103de9:	89 f2                	mov    %esi,%edx
80103deb:	8d 72 ff             	lea    -0x1(%edx),%esi
80103dee:	85 d2                	test   %edx,%edx
80103df0:	75 ec                	jne    80103dde <memmove+0x34>

  return dst;
}
80103df2:	5b                   	pop    %ebx
80103df3:	5e                   	pop    %esi
80103df4:	5d                   	pop    %ebp
80103df5:	c3                   	ret    
80103df6:	89 c3                	mov    %eax,%ebx
80103df8:	eb f1                	jmp    80103deb <memmove+0x41>
80103dfa:	89 c3                	mov    %eax,%ebx
80103dfc:	eb ed                	jmp    80103deb <memmove+0x41>

80103dfe <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80103dfe:	55                   	push   %ebp
80103dff:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80103e01:	ff 75 10             	pushl  0x10(%ebp)
80103e04:	ff 75 0c             	pushl  0xc(%ebp)
80103e07:	ff 75 08             	pushl  0x8(%ebp)
80103e0a:	e8 9b ff ff ff       	call   80103daa <memmove>
}
80103e0f:	c9                   	leave  
80103e10:	c3                   	ret    

80103e11 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80103e11:	55                   	push   %ebp
80103e12:	89 e5                	mov    %esp,%ebp
80103e14:	53                   	push   %ebx
80103e15:	8b 55 08             	mov    0x8(%ebp),%edx
80103e18:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103e1b:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80103e1e:	eb 09                	jmp    80103e29 <strncmp+0x18>
    n--, p++, q++;
80103e20:	83 e8 01             	sub    $0x1,%eax
80103e23:	83 c2 01             	add    $0x1,%edx
80103e26:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80103e29:	85 c0                	test   %eax,%eax
80103e2b:	74 0b                	je     80103e38 <strncmp+0x27>
80103e2d:	0f b6 1a             	movzbl (%edx),%ebx
80103e30:	84 db                	test   %bl,%bl
80103e32:	74 04                	je     80103e38 <strncmp+0x27>
80103e34:	3a 19                	cmp    (%ecx),%bl
80103e36:	74 e8                	je     80103e20 <strncmp+0xf>
  if(n == 0)
80103e38:	85 c0                	test   %eax,%eax
80103e3a:	74 0b                	je     80103e47 <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
80103e3c:	0f b6 02             	movzbl (%edx),%eax
80103e3f:	0f b6 11             	movzbl (%ecx),%edx
80103e42:	29 d0                	sub    %edx,%eax
}
80103e44:	5b                   	pop    %ebx
80103e45:	5d                   	pop    %ebp
80103e46:	c3                   	ret    
    return 0;
80103e47:	b8 00 00 00 00       	mov    $0x0,%eax
80103e4c:	eb f6                	jmp    80103e44 <strncmp+0x33>

80103e4e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80103e4e:	55                   	push   %ebp
80103e4f:	89 e5                	mov    %esp,%ebp
80103e51:	57                   	push   %edi
80103e52:	56                   	push   %esi
80103e53:	53                   	push   %ebx
80103e54:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103e57:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80103e5a:	8b 45 08             	mov    0x8(%ebp),%eax
80103e5d:	eb 04                	jmp    80103e63 <strncpy+0x15>
80103e5f:	89 fb                	mov    %edi,%ebx
80103e61:	89 f0                	mov    %esi,%eax
80103e63:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103e66:	85 c9                	test   %ecx,%ecx
80103e68:	7e 1d                	jle    80103e87 <strncpy+0x39>
80103e6a:	8d 7b 01             	lea    0x1(%ebx),%edi
80103e6d:	8d 70 01             	lea    0x1(%eax),%esi
80103e70:	0f b6 1b             	movzbl (%ebx),%ebx
80103e73:	88 18                	mov    %bl,(%eax)
80103e75:	89 d1                	mov    %edx,%ecx
80103e77:	84 db                	test   %bl,%bl
80103e79:	75 e4                	jne    80103e5f <strncpy+0x11>
80103e7b:	89 f0                	mov    %esi,%eax
80103e7d:	eb 08                	jmp    80103e87 <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
80103e7f:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
80103e82:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
80103e84:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
80103e87:	8d 4a ff             	lea    -0x1(%edx),%ecx
80103e8a:	85 d2                	test   %edx,%edx
80103e8c:	7f f1                	jg     80103e7f <strncpy+0x31>
  return os;
}
80103e8e:	8b 45 08             	mov    0x8(%ebp),%eax
80103e91:	5b                   	pop    %ebx
80103e92:	5e                   	pop    %esi
80103e93:	5f                   	pop    %edi
80103e94:	5d                   	pop    %ebp
80103e95:	c3                   	ret    

80103e96 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80103e96:	55                   	push   %ebp
80103e97:	89 e5                	mov    %esp,%ebp
80103e99:	57                   	push   %edi
80103e9a:	56                   	push   %esi
80103e9b:	53                   	push   %ebx
80103e9c:	8b 45 08             	mov    0x8(%ebp),%eax
80103e9f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103ea2:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
80103ea5:	85 d2                	test   %edx,%edx
80103ea7:	7e 23                	jle    80103ecc <safestrcpy+0x36>
80103ea9:	89 c1                	mov    %eax,%ecx
80103eab:	eb 04                	jmp    80103eb1 <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80103ead:	89 fb                	mov    %edi,%ebx
80103eaf:	89 f1                	mov    %esi,%ecx
80103eb1:	83 ea 01             	sub    $0x1,%edx
80103eb4:	85 d2                	test   %edx,%edx
80103eb6:	7e 11                	jle    80103ec9 <safestrcpy+0x33>
80103eb8:	8d 7b 01             	lea    0x1(%ebx),%edi
80103ebb:	8d 71 01             	lea    0x1(%ecx),%esi
80103ebe:	0f b6 1b             	movzbl (%ebx),%ebx
80103ec1:	88 19                	mov    %bl,(%ecx)
80103ec3:	84 db                	test   %bl,%bl
80103ec5:	75 e6                	jne    80103ead <safestrcpy+0x17>
80103ec7:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
80103ec9:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
80103ecc:	5b                   	pop    %ebx
80103ecd:	5e                   	pop    %esi
80103ece:	5f                   	pop    %edi
80103ecf:	5d                   	pop    %ebp
80103ed0:	c3                   	ret    

80103ed1 <strlen>:

int
strlen(const char *s)
{
80103ed1:	55                   	push   %ebp
80103ed2:	89 e5                	mov    %esp,%ebp
80103ed4:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80103ed7:	b8 00 00 00 00       	mov    $0x0,%eax
80103edc:	eb 03                	jmp    80103ee1 <strlen+0x10>
80103ede:	83 c0 01             	add    $0x1,%eax
80103ee1:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80103ee5:	75 f7                	jne    80103ede <strlen+0xd>
    ;
  return n;
}
80103ee7:	5d                   	pop    %ebp
80103ee8:	c3                   	ret    

80103ee9 <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80103ee9:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80103eed:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
80103ef1:	55                   	push   %ebp
  pushl %ebx
80103ef2:	53                   	push   %ebx
  pushl %esi
80103ef3:	56                   	push   %esi
  pushl %edi
80103ef4:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80103ef5:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80103ef7:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80103ef9:	5f                   	pop    %edi
  popl %esi
80103efa:	5e                   	pop    %esi
  popl %ebx
80103efb:	5b                   	pop    %ebx
  popl %ebp
80103efc:	5d                   	pop    %ebp
  ret
80103efd:	c3                   	ret    

80103efe <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80103efe:	55                   	push   %ebp
80103eff:	89 e5                	mov    %esp,%ebp
80103f01:	53                   	push   %ebx
80103f02:	83 ec 04             	sub    $0x4,%esp
80103f05:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80103f08:	e8 23 f3 ff ff       	call   80103230 <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80103f0d:	8b 00                	mov    (%eax),%eax
80103f0f:	39 d8                	cmp    %ebx,%eax
80103f11:	76 19                	jbe    80103f2c <fetchint+0x2e>
80103f13:	8d 53 04             	lea    0x4(%ebx),%edx
80103f16:	39 d0                	cmp    %edx,%eax
80103f18:	72 19                	jb     80103f33 <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
80103f1a:	8b 13                	mov    (%ebx),%edx
80103f1c:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f1f:	89 10                	mov    %edx,(%eax)
  return 0;
80103f21:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103f26:	83 c4 04             	add    $0x4,%esp
80103f29:	5b                   	pop    %ebx
80103f2a:	5d                   	pop    %ebp
80103f2b:	c3                   	ret    
    return -1;
80103f2c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f31:	eb f3                	jmp    80103f26 <fetchint+0x28>
80103f33:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f38:	eb ec                	jmp    80103f26 <fetchint+0x28>

80103f3a <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80103f3a:	55                   	push   %ebp
80103f3b:	89 e5                	mov    %esp,%ebp
80103f3d:	53                   	push   %ebx
80103f3e:	83 ec 04             	sub    $0x4,%esp
80103f41:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
80103f44:	e8 e7 f2 ff ff       	call   80103230 <myproc>

  if(addr >= curproc->sz)
80103f49:	39 18                	cmp    %ebx,(%eax)
80103f4b:	76 26                	jbe    80103f73 <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
80103f4d:	8b 55 0c             	mov    0xc(%ebp),%edx
80103f50:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
80103f52:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
80103f54:	89 d8                	mov    %ebx,%eax
80103f56:	39 d0                	cmp    %edx,%eax
80103f58:	73 0e                	jae    80103f68 <fetchstr+0x2e>
    if(*s == 0)
80103f5a:	80 38 00             	cmpb   $0x0,(%eax)
80103f5d:	74 05                	je     80103f64 <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
80103f5f:	83 c0 01             	add    $0x1,%eax
80103f62:	eb f2                	jmp    80103f56 <fetchstr+0x1c>
      return s - *pp;
80103f64:	29 d8                	sub    %ebx,%eax
80103f66:	eb 05                	jmp    80103f6d <fetchstr+0x33>
  }
  return -1;
80103f68:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103f6d:	83 c4 04             	add    $0x4,%esp
80103f70:	5b                   	pop    %ebx
80103f71:	5d                   	pop    %ebp
80103f72:	c3                   	ret    
    return -1;
80103f73:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f78:	eb f3                	jmp    80103f6d <fetchstr+0x33>

80103f7a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80103f7a:	55                   	push   %ebp
80103f7b:	89 e5                	mov    %esp,%ebp
80103f7d:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
80103f80:	e8 ab f2 ff ff       	call   80103230 <myproc>
80103f85:	8b 50 18             	mov    0x18(%eax),%edx
80103f88:	8b 45 08             	mov    0x8(%ebp),%eax
80103f8b:	c1 e0 02             	shl    $0x2,%eax
80103f8e:	03 42 44             	add    0x44(%edx),%eax
80103f91:	83 ec 08             	sub    $0x8,%esp
80103f94:	ff 75 0c             	pushl  0xc(%ebp)
80103f97:	83 c0 04             	add    $0x4,%eax
80103f9a:	50                   	push   %eax
80103f9b:	e8 5e ff ff ff       	call   80103efe <fetchint>
}
80103fa0:	c9                   	leave  
80103fa1:	c3                   	ret    

80103fa2 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80103fa2:	55                   	push   %ebp
80103fa3:	89 e5                	mov    %esp,%ebp
80103fa5:	56                   	push   %esi
80103fa6:	53                   	push   %ebx
80103fa7:	83 ec 10             	sub    $0x10,%esp
80103faa:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
80103fad:	e8 7e f2 ff ff       	call   80103230 <myproc>
80103fb2:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
80103fb4:	83 ec 08             	sub    $0x8,%esp
80103fb7:	8d 45 f4             	lea    -0xc(%ebp),%eax
80103fba:	50                   	push   %eax
80103fbb:	ff 75 08             	pushl  0x8(%ebp)
80103fbe:	e8 b7 ff ff ff       	call   80103f7a <argint>
80103fc3:	83 c4 10             	add    $0x10,%esp
80103fc6:	85 c0                	test   %eax,%eax
80103fc8:	78 24                	js     80103fee <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
80103fca:	85 db                	test   %ebx,%ebx
80103fcc:	78 27                	js     80103ff5 <argptr+0x53>
80103fce:	8b 16                	mov    (%esi),%edx
80103fd0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103fd3:	39 c2                	cmp    %eax,%edx
80103fd5:	76 25                	jbe    80103ffc <argptr+0x5a>
80103fd7:	01 c3                	add    %eax,%ebx
80103fd9:	39 da                	cmp    %ebx,%edx
80103fdb:	72 26                	jb     80104003 <argptr+0x61>
    return -1;
  *pp = (char*)i;
80103fdd:	8b 55 0c             	mov    0xc(%ebp),%edx
80103fe0:	89 02                	mov    %eax,(%edx)
  return 0;
80103fe2:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103fe7:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103fea:	5b                   	pop    %ebx
80103feb:	5e                   	pop    %esi
80103fec:	5d                   	pop    %ebp
80103fed:	c3                   	ret    
    return -1;
80103fee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103ff3:	eb f2                	jmp    80103fe7 <argptr+0x45>
    return -1;
80103ff5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103ffa:	eb eb                	jmp    80103fe7 <argptr+0x45>
80103ffc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104001:	eb e4                	jmp    80103fe7 <argptr+0x45>
80104003:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104008:	eb dd                	jmp    80103fe7 <argptr+0x45>

8010400a <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
8010400a:	55                   	push   %ebp
8010400b:	89 e5                	mov    %esp,%ebp
8010400d:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
80104010:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104013:	50                   	push   %eax
80104014:	ff 75 08             	pushl  0x8(%ebp)
80104017:	e8 5e ff ff ff       	call   80103f7a <argint>
8010401c:	83 c4 10             	add    $0x10,%esp
8010401f:	85 c0                	test   %eax,%eax
80104021:	78 13                	js     80104036 <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
80104023:	83 ec 08             	sub    $0x8,%esp
80104026:	ff 75 0c             	pushl  0xc(%ebp)
80104029:	ff 75 f4             	pushl  -0xc(%ebp)
8010402c:	e8 09 ff ff ff       	call   80103f3a <fetchstr>
80104031:	83 c4 10             	add    $0x10,%esp
}
80104034:	c9                   	leave  
80104035:	c3                   	ret    
    return -1;
80104036:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010403b:	eb f7                	jmp    80104034 <argstr+0x2a>

8010403d <syscall>:
[SYS_dump_physmem] sys_dump_physmem,
};

void
syscall(void)
{
8010403d:	55                   	push   %ebp
8010403e:	89 e5                	mov    %esp,%ebp
80104040:	53                   	push   %ebx
80104041:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
80104044:	e8 e7 f1 ff ff       	call   80103230 <myproc>
80104049:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
8010404b:	8b 40 18             	mov    0x18(%eax),%eax
8010404e:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80104051:	8d 50 ff             	lea    -0x1(%eax),%edx
80104054:	83 fa 15             	cmp    $0x15,%edx
80104057:	77 18                	ja     80104071 <syscall+0x34>
80104059:	8b 14 85 80 6c 10 80 	mov    -0x7fef9380(,%eax,4),%edx
80104060:	85 d2                	test   %edx,%edx
80104062:	74 0d                	je     80104071 <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
80104064:	ff d2                	call   *%edx
80104066:	8b 53 18             	mov    0x18(%ebx),%edx
80104069:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
8010406c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010406f:	c9                   	leave  
80104070:	c3                   	ret    
            curproc->pid, curproc->name, num);
80104071:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
80104074:	50                   	push   %eax
80104075:	52                   	push   %edx
80104076:	ff 73 10             	pushl  0x10(%ebx)
80104079:	68 59 6c 10 80       	push   $0x80106c59
8010407e:	e8 88 c5 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
80104083:	8b 43 18             	mov    0x18(%ebx),%eax
80104086:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
8010408d:	83 c4 10             	add    $0x10,%esp
}
80104090:	eb da                	jmp    8010406c <syscall+0x2f>

80104092 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80104092:	55                   	push   %ebp
80104093:	89 e5                	mov    %esp,%ebp
80104095:	56                   	push   %esi
80104096:	53                   	push   %ebx
80104097:	83 ec 18             	sub    $0x18,%esp
8010409a:	89 d6                	mov    %edx,%esi
8010409c:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
8010409e:	8d 55 f4             	lea    -0xc(%ebp),%edx
801040a1:	52                   	push   %edx
801040a2:	50                   	push   %eax
801040a3:	e8 d2 fe ff ff       	call   80103f7a <argint>
801040a8:	83 c4 10             	add    $0x10,%esp
801040ab:	85 c0                	test   %eax,%eax
801040ad:	78 2e                	js     801040dd <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
801040af:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
801040b3:	77 2f                	ja     801040e4 <argfd+0x52>
801040b5:	e8 76 f1 ff ff       	call   80103230 <myproc>
801040ba:	8b 55 f4             	mov    -0xc(%ebp),%edx
801040bd:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
801040c1:	85 c0                	test   %eax,%eax
801040c3:	74 26                	je     801040eb <argfd+0x59>
    return -1;
  if(pfd)
801040c5:	85 f6                	test   %esi,%esi
801040c7:	74 02                	je     801040cb <argfd+0x39>
    *pfd = fd;
801040c9:	89 16                	mov    %edx,(%esi)
  if(pf)
801040cb:	85 db                	test   %ebx,%ebx
801040cd:	74 23                	je     801040f2 <argfd+0x60>
    *pf = f;
801040cf:	89 03                	mov    %eax,(%ebx)
  return 0;
801040d1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801040d6:	8d 65 f8             	lea    -0x8(%ebp),%esp
801040d9:	5b                   	pop    %ebx
801040da:	5e                   	pop    %esi
801040db:	5d                   	pop    %ebp
801040dc:	c3                   	ret    
    return -1;
801040dd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040e2:	eb f2                	jmp    801040d6 <argfd+0x44>
    return -1;
801040e4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040e9:	eb eb                	jmp    801040d6 <argfd+0x44>
801040eb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040f0:	eb e4                	jmp    801040d6 <argfd+0x44>
  return 0;
801040f2:	b8 00 00 00 00       	mov    $0x0,%eax
801040f7:	eb dd                	jmp    801040d6 <argfd+0x44>

801040f9 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801040f9:	55                   	push   %ebp
801040fa:	89 e5                	mov    %esp,%ebp
801040fc:	53                   	push   %ebx
801040fd:	83 ec 04             	sub    $0x4,%esp
80104100:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
80104102:	e8 29 f1 ff ff       	call   80103230 <myproc>

  for(fd = 0; fd < NOFILE; fd++){
80104107:	ba 00 00 00 00       	mov    $0x0,%edx
8010410c:	83 fa 0f             	cmp    $0xf,%edx
8010410f:	7f 18                	jg     80104129 <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
80104111:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
80104116:	74 05                	je     8010411d <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
80104118:	83 c2 01             	add    $0x1,%edx
8010411b:	eb ef                	jmp    8010410c <fdalloc+0x13>
      curproc->ofile[fd] = f;
8010411d:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
80104121:	89 d0                	mov    %edx,%eax
80104123:	83 c4 04             	add    $0x4,%esp
80104126:	5b                   	pop    %ebx
80104127:	5d                   	pop    %ebp
80104128:	c3                   	ret    
  return -1;
80104129:	ba ff ff ff ff       	mov    $0xffffffff,%edx
8010412e:	eb f1                	jmp    80104121 <fdalloc+0x28>

80104130 <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80104130:	55                   	push   %ebp
80104131:	89 e5                	mov    %esp,%ebp
80104133:	56                   	push   %esi
80104134:	53                   	push   %ebx
80104135:	83 ec 10             	sub    $0x10,%esp
80104138:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010413a:	b8 20 00 00 00       	mov    $0x20,%eax
8010413f:	89 c6                	mov    %eax,%esi
80104141:	39 43 58             	cmp    %eax,0x58(%ebx)
80104144:	76 2e                	jbe    80104174 <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104146:	6a 10                	push   $0x10
80104148:	50                   	push   %eax
80104149:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010414c:	50                   	push   %eax
8010414d:	53                   	push   %ebx
8010414e:	e8 20 d6 ff ff       	call   80101773 <readi>
80104153:	83 c4 10             	add    $0x10,%esp
80104156:	83 f8 10             	cmp    $0x10,%eax
80104159:	75 0c                	jne    80104167 <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
8010415b:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
80104160:	75 1e                	jne    80104180 <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80104162:	8d 46 10             	lea    0x10(%esi),%eax
80104165:	eb d8                	jmp    8010413f <isdirempty+0xf>
      panic("isdirempty: readi");
80104167:	83 ec 0c             	sub    $0xc,%esp
8010416a:	68 dc 6c 10 80       	push   $0x80106cdc
8010416f:	e8 d4 c1 ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
80104174:	b8 01 00 00 00       	mov    $0x1,%eax
}
80104179:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010417c:	5b                   	pop    %ebx
8010417d:	5e                   	pop    %esi
8010417e:	5d                   	pop    %ebp
8010417f:	c3                   	ret    
      return 0;
80104180:	b8 00 00 00 00       	mov    $0x0,%eax
80104185:	eb f2                	jmp    80104179 <isdirempty+0x49>

80104187 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
80104187:	55                   	push   %ebp
80104188:	89 e5                	mov    %esp,%ebp
8010418a:	57                   	push   %edi
8010418b:	56                   	push   %esi
8010418c:	53                   	push   %ebx
8010418d:	83 ec 44             	sub    $0x44,%esp
80104190:	89 55 c4             	mov    %edx,-0x3c(%ebp)
80104193:	89 4d c0             	mov    %ecx,-0x40(%ebp)
80104196:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80104199:	8d 55 d6             	lea    -0x2a(%ebp),%edx
8010419c:	52                   	push   %edx
8010419d:	50                   	push   %eax
8010419e:	e8 56 da ff ff       	call   80101bf9 <nameiparent>
801041a3:	89 c6                	mov    %eax,%esi
801041a5:	83 c4 10             	add    $0x10,%esp
801041a8:	85 c0                	test   %eax,%eax
801041aa:	0f 84 3a 01 00 00    	je     801042ea <create+0x163>
    return 0;
  ilock(dp);
801041b0:	83 ec 0c             	sub    $0xc,%esp
801041b3:	50                   	push   %eax
801041b4:	e8 c8 d3 ff ff       	call   80101581 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
801041b9:	83 c4 0c             	add    $0xc,%esp
801041bc:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801041bf:	50                   	push   %eax
801041c0:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801041c3:	50                   	push   %eax
801041c4:	56                   	push   %esi
801041c5:	e8 e6 d7 ff ff       	call   801019b0 <dirlookup>
801041ca:	89 c3                	mov    %eax,%ebx
801041cc:	83 c4 10             	add    $0x10,%esp
801041cf:	85 c0                	test   %eax,%eax
801041d1:	74 3f                	je     80104212 <create+0x8b>
    iunlockput(dp);
801041d3:	83 ec 0c             	sub    $0xc,%esp
801041d6:	56                   	push   %esi
801041d7:	e8 4c d5 ff ff       	call   80101728 <iunlockput>
    ilock(ip);
801041dc:	89 1c 24             	mov    %ebx,(%esp)
801041df:	e8 9d d3 ff ff       	call   80101581 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
801041e4:	83 c4 10             	add    $0x10,%esp
801041e7:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
801041ec:	75 11                	jne    801041ff <create+0x78>
801041ee:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
801041f3:	75 0a                	jne    801041ff <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
801041f5:	89 d8                	mov    %ebx,%eax
801041f7:	8d 65 f4             	lea    -0xc(%ebp),%esp
801041fa:	5b                   	pop    %ebx
801041fb:	5e                   	pop    %esi
801041fc:	5f                   	pop    %edi
801041fd:	5d                   	pop    %ebp
801041fe:	c3                   	ret    
    iunlockput(ip);
801041ff:	83 ec 0c             	sub    $0xc,%esp
80104202:	53                   	push   %ebx
80104203:	e8 20 d5 ff ff       	call   80101728 <iunlockput>
    return 0;
80104208:	83 c4 10             	add    $0x10,%esp
8010420b:	bb 00 00 00 00       	mov    $0x0,%ebx
80104210:	eb e3                	jmp    801041f5 <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
80104212:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
80104216:	83 ec 08             	sub    $0x8,%esp
80104219:	50                   	push   %eax
8010421a:	ff 36                	pushl  (%esi)
8010421c:	e8 5d d1 ff ff       	call   8010137e <ialloc>
80104221:	89 c3                	mov    %eax,%ebx
80104223:	83 c4 10             	add    $0x10,%esp
80104226:	85 c0                	test   %eax,%eax
80104228:	74 55                	je     8010427f <create+0xf8>
  ilock(ip);
8010422a:	83 ec 0c             	sub    $0xc,%esp
8010422d:	50                   	push   %eax
8010422e:	e8 4e d3 ff ff       	call   80101581 <ilock>
  ip->major = major;
80104233:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
80104237:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
8010423b:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
8010423f:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
80104245:	89 1c 24             	mov    %ebx,(%esp)
80104248:	e8 d3 d1 ff ff       	call   80101420 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
8010424d:	83 c4 10             	add    $0x10,%esp
80104250:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
80104255:	74 35                	je     8010428c <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
80104257:	83 ec 04             	sub    $0x4,%esp
8010425a:	ff 73 04             	pushl  0x4(%ebx)
8010425d:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104260:	50                   	push   %eax
80104261:	56                   	push   %esi
80104262:	e8 c9 d8 ff ff       	call   80101b30 <dirlink>
80104267:	83 c4 10             	add    $0x10,%esp
8010426a:	85 c0                	test   %eax,%eax
8010426c:	78 6f                	js     801042dd <create+0x156>
  iunlockput(dp);
8010426e:	83 ec 0c             	sub    $0xc,%esp
80104271:	56                   	push   %esi
80104272:	e8 b1 d4 ff ff       	call   80101728 <iunlockput>
  return ip;
80104277:	83 c4 10             	add    $0x10,%esp
8010427a:	e9 76 ff ff ff       	jmp    801041f5 <create+0x6e>
    panic("create: ialloc");
8010427f:	83 ec 0c             	sub    $0xc,%esp
80104282:	68 ee 6c 10 80       	push   $0x80106cee
80104287:	e8 bc c0 ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
8010428c:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104290:	83 c0 01             	add    $0x1,%eax
80104293:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104297:	83 ec 0c             	sub    $0xc,%esp
8010429a:	56                   	push   %esi
8010429b:	e8 80 d1 ff ff       	call   80101420 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
801042a0:	83 c4 0c             	add    $0xc,%esp
801042a3:	ff 73 04             	pushl  0x4(%ebx)
801042a6:	68 fe 6c 10 80       	push   $0x80106cfe
801042ab:	53                   	push   %ebx
801042ac:	e8 7f d8 ff ff       	call   80101b30 <dirlink>
801042b1:	83 c4 10             	add    $0x10,%esp
801042b4:	85 c0                	test   %eax,%eax
801042b6:	78 18                	js     801042d0 <create+0x149>
801042b8:	83 ec 04             	sub    $0x4,%esp
801042bb:	ff 76 04             	pushl  0x4(%esi)
801042be:	68 fd 6c 10 80       	push   $0x80106cfd
801042c3:	53                   	push   %ebx
801042c4:	e8 67 d8 ff ff       	call   80101b30 <dirlink>
801042c9:	83 c4 10             	add    $0x10,%esp
801042cc:	85 c0                	test   %eax,%eax
801042ce:	79 87                	jns    80104257 <create+0xd0>
      panic("create dots");
801042d0:	83 ec 0c             	sub    $0xc,%esp
801042d3:	68 00 6d 10 80       	push   $0x80106d00
801042d8:	e8 6b c0 ff ff       	call   80100348 <panic>
    panic("create: dirlink");
801042dd:	83 ec 0c             	sub    $0xc,%esp
801042e0:	68 0c 6d 10 80       	push   $0x80106d0c
801042e5:	e8 5e c0 ff ff       	call   80100348 <panic>
    return 0;
801042ea:	89 c3                	mov    %eax,%ebx
801042ec:	e9 04 ff ff ff       	jmp    801041f5 <create+0x6e>

801042f1 <sys_dup>:
{
801042f1:	55                   	push   %ebp
801042f2:	89 e5                	mov    %esp,%ebp
801042f4:	53                   	push   %ebx
801042f5:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
801042f8:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801042fb:	ba 00 00 00 00       	mov    $0x0,%edx
80104300:	b8 00 00 00 00       	mov    $0x0,%eax
80104305:	e8 88 fd ff ff       	call   80104092 <argfd>
8010430a:	85 c0                	test   %eax,%eax
8010430c:	78 23                	js     80104331 <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
8010430e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104311:	e8 e3 fd ff ff       	call   801040f9 <fdalloc>
80104316:	89 c3                	mov    %eax,%ebx
80104318:	85 c0                	test   %eax,%eax
8010431a:	78 1c                	js     80104338 <sys_dup+0x47>
  filedup(f);
8010431c:	83 ec 0c             	sub    $0xc,%esp
8010431f:	ff 75 f4             	pushl  -0xc(%ebp)
80104322:	e8 67 c9 ff ff       	call   80100c8e <filedup>
  return fd;
80104327:	83 c4 10             	add    $0x10,%esp
}
8010432a:	89 d8                	mov    %ebx,%eax
8010432c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010432f:	c9                   	leave  
80104330:	c3                   	ret    
    return -1;
80104331:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104336:	eb f2                	jmp    8010432a <sys_dup+0x39>
    return -1;
80104338:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010433d:	eb eb                	jmp    8010432a <sys_dup+0x39>

8010433f <sys_read>:
{
8010433f:	55                   	push   %ebp
80104340:	89 e5                	mov    %esp,%ebp
80104342:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104345:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104348:	ba 00 00 00 00       	mov    $0x0,%edx
8010434d:	b8 00 00 00 00       	mov    $0x0,%eax
80104352:	e8 3b fd ff ff       	call   80104092 <argfd>
80104357:	85 c0                	test   %eax,%eax
80104359:	78 43                	js     8010439e <sys_read+0x5f>
8010435b:	83 ec 08             	sub    $0x8,%esp
8010435e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104361:	50                   	push   %eax
80104362:	6a 02                	push   $0x2
80104364:	e8 11 fc ff ff       	call   80103f7a <argint>
80104369:	83 c4 10             	add    $0x10,%esp
8010436c:	85 c0                	test   %eax,%eax
8010436e:	78 35                	js     801043a5 <sys_read+0x66>
80104370:	83 ec 04             	sub    $0x4,%esp
80104373:	ff 75 f0             	pushl  -0x10(%ebp)
80104376:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104379:	50                   	push   %eax
8010437a:	6a 01                	push   $0x1
8010437c:	e8 21 fc ff ff       	call   80103fa2 <argptr>
80104381:	83 c4 10             	add    $0x10,%esp
80104384:	85 c0                	test   %eax,%eax
80104386:	78 24                	js     801043ac <sys_read+0x6d>
  return fileread(f, p, n);
80104388:	83 ec 04             	sub    $0x4,%esp
8010438b:	ff 75 f0             	pushl  -0x10(%ebp)
8010438e:	ff 75 ec             	pushl  -0x14(%ebp)
80104391:	ff 75 f4             	pushl  -0xc(%ebp)
80104394:	e8 3e ca ff ff       	call   80100dd7 <fileread>
80104399:	83 c4 10             	add    $0x10,%esp
}
8010439c:	c9                   	leave  
8010439d:	c3                   	ret    
    return -1;
8010439e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043a3:	eb f7                	jmp    8010439c <sys_read+0x5d>
801043a5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043aa:	eb f0                	jmp    8010439c <sys_read+0x5d>
801043ac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043b1:	eb e9                	jmp    8010439c <sys_read+0x5d>

801043b3 <sys_write>:
{
801043b3:	55                   	push   %ebp
801043b4:	89 e5                	mov    %esp,%ebp
801043b6:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801043b9:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801043bc:	ba 00 00 00 00       	mov    $0x0,%edx
801043c1:	b8 00 00 00 00       	mov    $0x0,%eax
801043c6:	e8 c7 fc ff ff       	call   80104092 <argfd>
801043cb:	85 c0                	test   %eax,%eax
801043cd:	78 43                	js     80104412 <sys_write+0x5f>
801043cf:	83 ec 08             	sub    $0x8,%esp
801043d2:	8d 45 f0             	lea    -0x10(%ebp),%eax
801043d5:	50                   	push   %eax
801043d6:	6a 02                	push   $0x2
801043d8:	e8 9d fb ff ff       	call   80103f7a <argint>
801043dd:	83 c4 10             	add    $0x10,%esp
801043e0:	85 c0                	test   %eax,%eax
801043e2:	78 35                	js     80104419 <sys_write+0x66>
801043e4:	83 ec 04             	sub    $0x4,%esp
801043e7:	ff 75 f0             	pushl  -0x10(%ebp)
801043ea:	8d 45 ec             	lea    -0x14(%ebp),%eax
801043ed:	50                   	push   %eax
801043ee:	6a 01                	push   $0x1
801043f0:	e8 ad fb ff ff       	call   80103fa2 <argptr>
801043f5:	83 c4 10             	add    $0x10,%esp
801043f8:	85 c0                	test   %eax,%eax
801043fa:	78 24                	js     80104420 <sys_write+0x6d>
  return filewrite(f, p, n);
801043fc:	83 ec 04             	sub    $0x4,%esp
801043ff:	ff 75 f0             	pushl  -0x10(%ebp)
80104402:	ff 75 ec             	pushl  -0x14(%ebp)
80104405:	ff 75 f4             	pushl  -0xc(%ebp)
80104408:	e8 4f ca ff ff       	call   80100e5c <filewrite>
8010440d:	83 c4 10             	add    $0x10,%esp
}
80104410:	c9                   	leave  
80104411:	c3                   	ret    
    return -1;
80104412:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104417:	eb f7                	jmp    80104410 <sys_write+0x5d>
80104419:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010441e:	eb f0                	jmp    80104410 <sys_write+0x5d>
80104420:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104425:	eb e9                	jmp    80104410 <sys_write+0x5d>

80104427 <sys_close>:
{
80104427:	55                   	push   %ebp
80104428:	89 e5                	mov    %esp,%ebp
8010442a:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
8010442d:	8d 4d f0             	lea    -0x10(%ebp),%ecx
80104430:	8d 55 f4             	lea    -0xc(%ebp),%edx
80104433:	b8 00 00 00 00       	mov    $0x0,%eax
80104438:	e8 55 fc ff ff       	call   80104092 <argfd>
8010443d:	85 c0                	test   %eax,%eax
8010443f:	78 25                	js     80104466 <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
80104441:	e8 ea ed ff ff       	call   80103230 <myproc>
80104446:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104449:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
80104450:	00 
  fileclose(f);
80104451:	83 ec 0c             	sub    $0xc,%esp
80104454:	ff 75 f0             	pushl  -0x10(%ebp)
80104457:	e8 77 c8 ff ff       	call   80100cd3 <fileclose>
  return 0;
8010445c:	83 c4 10             	add    $0x10,%esp
8010445f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104464:	c9                   	leave  
80104465:	c3                   	ret    
    return -1;
80104466:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010446b:	eb f7                	jmp    80104464 <sys_close+0x3d>

8010446d <sys_fstat>:
{
8010446d:	55                   	push   %ebp
8010446e:	89 e5                	mov    %esp,%ebp
80104470:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80104473:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104476:	ba 00 00 00 00       	mov    $0x0,%edx
8010447b:	b8 00 00 00 00       	mov    $0x0,%eax
80104480:	e8 0d fc ff ff       	call   80104092 <argfd>
80104485:	85 c0                	test   %eax,%eax
80104487:	78 2a                	js     801044b3 <sys_fstat+0x46>
80104489:	83 ec 04             	sub    $0x4,%esp
8010448c:	6a 14                	push   $0x14
8010448e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104491:	50                   	push   %eax
80104492:	6a 01                	push   $0x1
80104494:	e8 09 fb ff ff       	call   80103fa2 <argptr>
80104499:	83 c4 10             	add    $0x10,%esp
8010449c:	85 c0                	test   %eax,%eax
8010449e:	78 1a                	js     801044ba <sys_fstat+0x4d>
  return filestat(f, st);
801044a0:	83 ec 08             	sub    $0x8,%esp
801044a3:	ff 75 f0             	pushl  -0x10(%ebp)
801044a6:	ff 75 f4             	pushl  -0xc(%ebp)
801044a9:	e8 e2 c8 ff ff       	call   80100d90 <filestat>
801044ae:	83 c4 10             	add    $0x10,%esp
}
801044b1:	c9                   	leave  
801044b2:	c3                   	ret    
    return -1;
801044b3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044b8:	eb f7                	jmp    801044b1 <sys_fstat+0x44>
801044ba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044bf:	eb f0                	jmp    801044b1 <sys_fstat+0x44>

801044c1 <sys_link>:
{
801044c1:	55                   	push   %ebp
801044c2:	89 e5                	mov    %esp,%ebp
801044c4:	56                   	push   %esi
801044c5:	53                   	push   %ebx
801044c6:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801044c9:	8d 45 e0             	lea    -0x20(%ebp),%eax
801044cc:	50                   	push   %eax
801044cd:	6a 00                	push   $0x0
801044cf:	e8 36 fb ff ff       	call   8010400a <argstr>
801044d4:	83 c4 10             	add    $0x10,%esp
801044d7:	85 c0                	test   %eax,%eax
801044d9:	0f 88 32 01 00 00    	js     80104611 <sys_link+0x150>
801044df:	83 ec 08             	sub    $0x8,%esp
801044e2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801044e5:	50                   	push   %eax
801044e6:	6a 01                	push   $0x1
801044e8:	e8 1d fb ff ff       	call   8010400a <argstr>
801044ed:	83 c4 10             	add    $0x10,%esp
801044f0:	85 c0                	test   %eax,%eax
801044f2:	0f 88 20 01 00 00    	js     80104618 <sys_link+0x157>
  begin_op();
801044f8:	e8 eb e2 ff ff       	call   801027e8 <begin_op>
  if((ip = namei(old)) == 0){
801044fd:	83 ec 0c             	sub    $0xc,%esp
80104500:	ff 75 e0             	pushl  -0x20(%ebp)
80104503:	e8 d9 d6 ff ff       	call   80101be1 <namei>
80104508:	89 c3                	mov    %eax,%ebx
8010450a:	83 c4 10             	add    $0x10,%esp
8010450d:	85 c0                	test   %eax,%eax
8010450f:	0f 84 99 00 00 00    	je     801045ae <sys_link+0xed>
  ilock(ip);
80104515:	83 ec 0c             	sub    $0xc,%esp
80104518:	50                   	push   %eax
80104519:	e8 63 d0 ff ff       	call   80101581 <ilock>
  if(ip->type == T_DIR){
8010451e:	83 c4 10             	add    $0x10,%esp
80104521:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104526:	0f 84 8e 00 00 00    	je     801045ba <sys_link+0xf9>
  ip->nlink++;
8010452c:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104530:	83 c0 01             	add    $0x1,%eax
80104533:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104537:	83 ec 0c             	sub    $0xc,%esp
8010453a:	53                   	push   %ebx
8010453b:	e8 e0 ce ff ff       	call   80101420 <iupdate>
  iunlock(ip);
80104540:	89 1c 24             	mov    %ebx,(%esp)
80104543:	e8 fb d0 ff ff       	call   80101643 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
80104548:	83 c4 08             	add    $0x8,%esp
8010454b:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010454e:	50                   	push   %eax
8010454f:	ff 75 e4             	pushl  -0x1c(%ebp)
80104552:	e8 a2 d6 ff ff       	call   80101bf9 <nameiparent>
80104557:	89 c6                	mov    %eax,%esi
80104559:	83 c4 10             	add    $0x10,%esp
8010455c:	85 c0                	test   %eax,%eax
8010455e:	74 7e                	je     801045de <sys_link+0x11d>
  ilock(dp);
80104560:	83 ec 0c             	sub    $0xc,%esp
80104563:	50                   	push   %eax
80104564:	e8 18 d0 ff ff       	call   80101581 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80104569:	83 c4 10             	add    $0x10,%esp
8010456c:	8b 03                	mov    (%ebx),%eax
8010456e:	39 06                	cmp    %eax,(%esi)
80104570:	75 60                	jne    801045d2 <sys_link+0x111>
80104572:	83 ec 04             	sub    $0x4,%esp
80104575:	ff 73 04             	pushl  0x4(%ebx)
80104578:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010457b:	50                   	push   %eax
8010457c:	56                   	push   %esi
8010457d:	e8 ae d5 ff ff       	call   80101b30 <dirlink>
80104582:	83 c4 10             	add    $0x10,%esp
80104585:	85 c0                	test   %eax,%eax
80104587:	78 49                	js     801045d2 <sys_link+0x111>
  iunlockput(dp);
80104589:	83 ec 0c             	sub    $0xc,%esp
8010458c:	56                   	push   %esi
8010458d:	e8 96 d1 ff ff       	call   80101728 <iunlockput>
  iput(ip);
80104592:	89 1c 24             	mov    %ebx,(%esp)
80104595:	e8 ee d0 ff ff       	call   80101688 <iput>
  end_op();
8010459a:	e8 c3 e2 ff ff       	call   80102862 <end_op>
  return 0;
8010459f:	83 c4 10             	add    $0x10,%esp
801045a2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801045a7:	8d 65 f8             	lea    -0x8(%ebp),%esp
801045aa:	5b                   	pop    %ebx
801045ab:	5e                   	pop    %esi
801045ac:	5d                   	pop    %ebp
801045ad:	c3                   	ret    
    end_op();
801045ae:	e8 af e2 ff ff       	call   80102862 <end_op>
    return -1;
801045b3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045b8:	eb ed                	jmp    801045a7 <sys_link+0xe6>
    iunlockput(ip);
801045ba:	83 ec 0c             	sub    $0xc,%esp
801045bd:	53                   	push   %ebx
801045be:	e8 65 d1 ff ff       	call   80101728 <iunlockput>
    end_op();
801045c3:	e8 9a e2 ff ff       	call   80102862 <end_op>
    return -1;
801045c8:	83 c4 10             	add    $0x10,%esp
801045cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045d0:	eb d5                	jmp    801045a7 <sys_link+0xe6>
    iunlockput(dp);
801045d2:	83 ec 0c             	sub    $0xc,%esp
801045d5:	56                   	push   %esi
801045d6:	e8 4d d1 ff ff       	call   80101728 <iunlockput>
    goto bad;
801045db:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
801045de:	83 ec 0c             	sub    $0xc,%esp
801045e1:	53                   	push   %ebx
801045e2:	e8 9a cf ff ff       	call   80101581 <ilock>
  ip->nlink--;
801045e7:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801045eb:	83 e8 01             	sub    $0x1,%eax
801045ee:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801045f2:	89 1c 24             	mov    %ebx,(%esp)
801045f5:	e8 26 ce ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
801045fa:	89 1c 24             	mov    %ebx,(%esp)
801045fd:	e8 26 d1 ff ff       	call   80101728 <iunlockput>
  end_op();
80104602:	e8 5b e2 ff ff       	call   80102862 <end_op>
  return -1;
80104607:	83 c4 10             	add    $0x10,%esp
8010460a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010460f:	eb 96                	jmp    801045a7 <sys_link+0xe6>
    return -1;
80104611:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104616:	eb 8f                	jmp    801045a7 <sys_link+0xe6>
80104618:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010461d:	eb 88                	jmp    801045a7 <sys_link+0xe6>

8010461f <sys_unlink>:
{
8010461f:	55                   	push   %ebp
80104620:	89 e5                	mov    %esp,%ebp
80104622:	57                   	push   %edi
80104623:	56                   	push   %esi
80104624:	53                   	push   %ebx
80104625:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
80104628:	8d 45 c4             	lea    -0x3c(%ebp),%eax
8010462b:	50                   	push   %eax
8010462c:	6a 00                	push   $0x0
8010462e:	e8 d7 f9 ff ff       	call   8010400a <argstr>
80104633:	83 c4 10             	add    $0x10,%esp
80104636:	85 c0                	test   %eax,%eax
80104638:	0f 88 83 01 00 00    	js     801047c1 <sys_unlink+0x1a2>
  begin_op();
8010463e:	e8 a5 e1 ff ff       	call   801027e8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80104643:	83 ec 08             	sub    $0x8,%esp
80104646:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104649:	50                   	push   %eax
8010464a:	ff 75 c4             	pushl  -0x3c(%ebp)
8010464d:	e8 a7 d5 ff ff       	call   80101bf9 <nameiparent>
80104652:	89 c6                	mov    %eax,%esi
80104654:	83 c4 10             	add    $0x10,%esp
80104657:	85 c0                	test   %eax,%eax
80104659:	0f 84 ed 00 00 00    	je     8010474c <sys_unlink+0x12d>
  ilock(dp);
8010465f:	83 ec 0c             	sub    $0xc,%esp
80104662:	50                   	push   %eax
80104663:	e8 19 cf ff ff       	call   80101581 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80104668:	83 c4 08             	add    $0x8,%esp
8010466b:	68 fe 6c 10 80       	push   $0x80106cfe
80104670:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104673:	50                   	push   %eax
80104674:	e8 22 d3 ff ff       	call   8010199b <namecmp>
80104679:	83 c4 10             	add    $0x10,%esp
8010467c:	85 c0                	test   %eax,%eax
8010467e:	0f 84 fc 00 00 00    	je     80104780 <sys_unlink+0x161>
80104684:	83 ec 08             	sub    $0x8,%esp
80104687:	68 fd 6c 10 80       	push   $0x80106cfd
8010468c:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010468f:	50                   	push   %eax
80104690:	e8 06 d3 ff ff       	call   8010199b <namecmp>
80104695:	83 c4 10             	add    $0x10,%esp
80104698:	85 c0                	test   %eax,%eax
8010469a:	0f 84 e0 00 00 00    	je     80104780 <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
801046a0:	83 ec 04             	sub    $0x4,%esp
801046a3:	8d 45 c0             	lea    -0x40(%ebp),%eax
801046a6:	50                   	push   %eax
801046a7:	8d 45 ca             	lea    -0x36(%ebp),%eax
801046aa:	50                   	push   %eax
801046ab:	56                   	push   %esi
801046ac:	e8 ff d2 ff ff       	call   801019b0 <dirlookup>
801046b1:	89 c3                	mov    %eax,%ebx
801046b3:	83 c4 10             	add    $0x10,%esp
801046b6:	85 c0                	test   %eax,%eax
801046b8:	0f 84 c2 00 00 00    	je     80104780 <sys_unlink+0x161>
  ilock(ip);
801046be:	83 ec 0c             	sub    $0xc,%esp
801046c1:	50                   	push   %eax
801046c2:	e8 ba ce ff ff       	call   80101581 <ilock>
  if(ip->nlink < 1)
801046c7:	83 c4 10             	add    $0x10,%esp
801046ca:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801046cf:	0f 8e 83 00 00 00    	jle    80104758 <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
801046d5:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801046da:	0f 84 85 00 00 00    	je     80104765 <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
801046e0:	83 ec 04             	sub    $0x4,%esp
801046e3:	6a 10                	push   $0x10
801046e5:	6a 00                	push   $0x0
801046e7:	8d 7d d8             	lea    -0x28(%ebp),%edi
801046ea:	57                   	push   %edi
801046eb:	e8 3f f6 ff ff       	call   80103d2f <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801046f0:	6a 10                	push   $0x10
801046f2:	ff 75 c0             	pushl  -0x40(%ebp)
801046f5:	57                   	push   %edi
801046f6:	56                   	push   %esi
801046f7:	e8 74 d1 ff ff       	call   80101870 <writei>
801046fc:	83 c4 20             	add    $0x20,%esp
801046ff:	83 f8 10             	cmp    $0x10,%eax
80104702:	0f 85 90 00 00 00    	jne    80104798 <sys_unlink+0x179>
  if(ip->type == T_DIR){
80104708:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
8010470d:	0f 84 92 00 00 00    	je     801047a5 <sys_unlink+0x186>
  iunlockput(dp);
80104713:	83 ec 0c             	sub    $0xc,%esp
80104716:	56                   	push   %esi
80104717:	e8 0c d0 ff ff       	call   80101728 <iunlockput>
  ip->nlink--;
8010471c:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104720:	83 e8 01             	sub    $0x1,%eax
80104723:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104727:	89 1c 24             	mov    %ebx,(%esp)
8010472a:	e8 f1 cc ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
8010472f:	89 1c 24             	mov    %ebx,(%esp)
80104732:	e8 f1 cf ff ff       	call   80101728 <iunlockput>
  end_op();
80104737:	e8 26 e1 ff ff       	call   80102862 <end_op>
  return 0;
8010473c:	83 c4 10             	add    $0x10,%esp
8010473f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104744:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104747:	5b                   	pop    %ebx
80104748:	5e                   	pop    %esi
80104749:	5f                   	pop    %edi
8010474a:	5d                   	pop    %ebp
8010474b:	c3                   	ret    
    end_op();
8010474c:	e8 11 e1 ff ff       	call   80102862 <end_op>
    return -1;
80104751:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104756:	eb ec                	jmp    80104744 <sys_unlink+0x125>
    panic("unlink: nlink < 1");
80104758:	83 ec 0c             	sub    $0xc,%esp
8010475b:	68 1c 6d 10 80       	push   $0x80106d1c
80104760:	e8 e3 bb ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104765:	89 d8                	mov    %ebx,%eax
80104767:	e8 c4 f9 ff ff       	call   80104130 <isdirempty>
8010476c:	85 c0                	test   %eax,%eax
8010476e:	0f 85 6c ff ff ff    	jne    801046e0 <sys_unlink+0xc1>
    iunlockput(ip);
80104774:	83 ec 0c             	sub    $0xc,%esp
80104777:	53                   	push   %ebx
80104778:	e8 ab cf ff ff       	call   80101728 <iunlockput>
    goto bad;
8010477d:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
80104780:	83 ec 0c             	sub    $0xc,%esp
80104783:	56                   	push   %esi
80104784:	e8 9f cf ff ff       	call   80101728 <iunlockput>
  end_op();
80104789:	e8 d4 e0 ff ff       	call   80102862 <end_op>
  return -1;
8010478e:	83 c4 10             	add    $0x10,%esp
80104791:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104796:	eb ac                	jmp    80104744 <sys_unlink+0x125>
    panic("unlink: writei");
80104798:	83 ec 0c             	sub    $0xc,%esp
8010479b:	68 2e 6d 10 80       	push   $0x80106d2e
801047a0:	e8 a3 bb ff ff       	call   80100348 <panic>
    dp->nlink--;
801047a5:	0f b7 46 56          	movzwl 0x56(%esi),%eax
801047a9:	83 e8 01             	sub    $0x1,%eax
801047ac:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801047b0:	83 ec 0c             	sub    $0xc,%esp
801047b3:	56                   	push   %esi
801047b4:	e8 67 cc ff ff       	call   80101420 <iupdate>
801047b9:	83 c4 10             	add    $0x10,%esp
801047bc:	e9 52 ff ff ff       	jmp    80104713 <sys_unlink+0xf4>
    return -1;
801047c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047c6:	e9 79 ff ff ff       	jmp    80104744 <sys_unlink+0x125>

801047cb <sys_open>:

int
sys_open(void)
{
801047cb:	55                   	push   %ebp
801047cc:	89 e5                	mov    %esp,%ebp
801047ce:	57                   	push   %edi
801047cf:	56                   	push   %esi
801047d0:	53                   	push   %ebx
801047d1:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
801047d4:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801047d7:	50                   	push   %eax
801047d8:	6a 00                	push   $0x0
801047da:	e8 2b f8 ff ff       	call   8010400a <argstr>
801047df:	83 c4 10             	add    $0x10,%esp
801047e2:	85 c0                	test   %eax,%eax
801047e4:	0f 88 30 01 00 00    	js     8010491a <sys_open+0x14f>
801047ea:	83 ec 08             	sub    $0x8,%esp
801047ed:	8d 45 e0             	lea    -0x20(%ebp),%eax
801047f0:	50                   	push   %eax
801047f1:	6a 01                	push   $0x1
801047f3:	e8 82 f7 ff ff       	call   80103f7a <argint>
801047f8:	83 c4 10             	add    $0x10,%esp
801047fb:	85 c0                	test   %eax,%eax
801047fd:	0f 88 21 01 00 00    	js     80104924 <sys_open+0x159>
    return -1;

  begin_op();
80104803:	e8 e0 df ff ff       	call   801027e8 <begin_op>

  if(omode & O_CREATE){
80104808:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
8010480c:	0f 84 84 00 00 00    	je     80104896 <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
80104812:	83 ec 0c             	sub    $0xc,%esp
80104815:	6a 00                	push   $0x0
80104817:	b9 00 00 00 00       	mov    $0x0,%ecx
8010481c:	ba 02 00 00 00       	mov    $0x2,%edx
80104821:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104824:	e8 5e f9 ff ff       	call   80104187 <create>
80104829:	89 c6                	mov    %eax,%esi
    if(ip == 0){
8010482b:	83 c4 10             	add    $0x10,%esp
8010482e:	85 c0                	test   %eax,%eax
80104830:	74 58                	je     8010488a <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80104832:	e8 f6 c3 ff ff       	call   80100c2d <filealloc>
80104837:	89 c3                	mov    %eax,%ebx
80104839:	85 c0                	test   %eax,%eax
8010483b:	0f 84 ae 00 00 00    	je     801048ef <sys_open+0x124>
80104841:	e8 b3 f8 ff ff       	call   801040f9 <fdalloc>
80104846:	89 c7                	mov    %eax,%edi
80104848:	85 c0                	test   %eax,%eax
8010484a:	0f 88 9f 00 00 00    	js     801048ef <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104850:	83 ec 0c             	sub    $0xc,%esp
80104853:	56                   	push   %esi
80104854:	e8 ea cd ff ff       	call   80101643 <iunlock>
  end_op();
80104859:	e8 04 e0 ff ff       	call   80102862 <end_op>

  f->type = FD_INODE;
8010485e:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
80104864:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
80104867:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
8010486e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104871:	83 c4 10             	add    $0x10,%esp
80104874:	a8 01                	test   $0x1,%al
80104876:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
8010487a:	a8 03                	test   $0x3,%al
8010487c:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
80104880:	89 f8                	mov    %edi,%eax
80104882:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104885:	5b                   	pop    %ebx
80104886:	5e                   	pop    %esi
80104887:	5f                   	pop    %edi
80104888:	5d                   	pop    %ebp
80104889:	c3                   	ret    
      end_op();
8010488a:	e8 d3 df ff ff       	call   80102862 <end_op>
      return -1;
8010488f:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104894:	eb ea                	jmp    80104880 <sys_open+0xb5>
    if((ip = namei(path)) == 0){
80104896:	83 ec 0c             	sub    $0xc,%esp
80104899:	ff 75 e4             	pushl  -0x1c(%ebp)
8010489c:	e8 40 d3 ff ff       	call   80101be1 <namei>
801048a1:	89 c6                	mov    %eax,%esi
801048a3:	83 c4 10             	add    $0x10,%esp
801048a6:	85 c0                	test   %eax,%eax
801048a8:	74 39                	je     801048e3 <sys_open+0x118>
    ilock(ip);
801048aa:	83 ec 0c             	sub    $0xc,%esp
801048ad:	50                   	push   %eax
801048ae:	e8 ce cc ff ff       	call   80101581 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
801048b3:	83 c4 10             	add    $0x10,%esp
801048b6:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
801048bb:	0f 85 71 ff ff ff    	jne    80104832 <sys_open+0x67>
801048c1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801048c5:	0f 84 67 ff ff ff    	je     80104832 <sys_open+0x67>
      iunlockput(ip);
801048cb:	83 ec 0c             	sub    $0xc,%esp
801048ce:	56                   	push   %esi
801048cf:	e8 54 ce ff ff       	call   80101728 <iunlockput>
      end_op();
801048d4:	e8 89 df ff ff       	call   80102862 <end_op>
      return -1;
801048d9:	83 c4 10             	add    $0x10,%esp
801048dc:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801048e1:	eb 9d                	jmp    80104880 <sys_open+0xb5>
      end_op();
801048e3:	e8 7a df ff ff       	call   80102862 <end_op>
      return -1;
801048e8:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801048ed:	eb 91                	jmp    80104880 <sys_open+0xb5>
    if(f)
801048ef:	85 db                	test   %ebx,%ebx
801048f1:	74 0c                	je     801048ff <sys_open+0x134>
      fileclose(f);
801048f3:	83 ec 0c             	sub    $0xc,%esp
801048f6:	53                   	push   %ebx
801048f7:	e8 d7 c3 ff ff       	call   80100cd3 <fileclose>
801048fc:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
801048ff:	83 ec 0c             	sub    $0xc,%esp
80104902:	56                   	push   %esi
80104903:	e8 20 ce ff ff       	call   80101728 <iunlockput>
    end_op();
80104908:	e8 55 df ff ff       	call   80102862 <end_op>
    return -1;
8010490d:	83 c4 10             	add    $0x10,%esp
80104910:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104915:	e9 66 ff ff ff       	jmp    80104880 <sys_open+0xb5>
    return -1;
8010491a:	bf ff ff ff ff       	mov    $0xffffffff,%edi
8010491f:	e9 5c ff ff ff       	jmp    80104880 <sys_open+0xb5>
80104924:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104929:	e9 52 ff ff ff       	jmp    80104880 <sys_open+0xb5>

8010492e <sys_mkdir>:

int
sys_mkdir(void)
{
8010492e:	55                   	push   %ebp
8010492f:	89 e5                	mov    %esp,%ebp
80104931:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80104934:	e8 af de ff ff       	call   801027e8 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104939:	83 ec 08             	sub    $0x8,%esp
8010493c:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010493f:	50                   	push   %eax
80104940:	6a 00                	push   $0x0
80104942:	e8 c3 f6 ff ff       	call   8010400a <argstr>
80104947:	83 c4 10             	add    $0x10,%esp
8010494a:	85 c0                	test   %eax,%eax
8010494c:	78 36                	js     80104984 <sys_mkdir+0x56>
8010494e:	83 ec 0c             	sub    $0xc,%esp
80104951:	6a 00                	push   $0x0
80104953:	b9 00 00 00 00       	mov    $0x0,%ecx
80104958:	ba 01 00 00 00       	mov    $0x1,%edx
8010495d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104960:	e8 22 f8 ff ff       	call   80104187 <create>
80104965:	83 c4 10             	add    $0x10,%esp
80104968:	85 c0                	test   %eax,%eax
8010496a:	74 18                	je     80104984 <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
8010496c:	83 ec 0c             	sub    $0xc,%esp
8010496f:	50                   	push   %eax
80104970:	e8 b3 cd ff ff       	call   80101728 <iunlockput>
  end_op();
80104975:	e8 e8 de ff ff       	call   80102862 <end_op>
  return 0;
8010497a:	83 c4 10             	add    $0x10,%esp
8010497d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104982:	c9                   	leave  
80104983:	c3                   	ret    
    end_op();
80104984:	e8 d9 de ff ff       	call   80102862 <end_op>
    return -1;
80104989:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010498e:	eb f2                	jmp    80104982 <sys_mkdir+0x54>

80104990 <sys_mknod>:

int
sys_mknod(void)
{
80104990:	55                   	push   %ebp
80104991:	89 e5                	mov    %esp,%ebp
80104993:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104996:	e8 4d de ff ff       	call   801027e8 <begin_op>
  if((argstr(0, &path)) < 0 ||
8010499b:	83 ec 08             	sub    $0x8,%esp
8010499e:	8d 45 f4             	lea    -0xc(%ebp),%eax
801049a1:	50                   	push   %eax
801049a2:	6a 00                	push   $0x0
801049a4:	e8 61 f6 ff ff       	call   8010400a <argstr>
801049a9:	83 c4 10             	add    $0x10,%esp
801049ac:	85 c0                	test   %eax,%eax
801049ae:	78 62                	js     80104a12 <sys_mknod+0x82>
     argint(1, &major) < 0 ||
801049b0:	83 ec 08             	sub    $0x8,%esp
801049b3:	8d 45 f0             	lea    -0x10(%ebp),%eax
801049b6:	50                   	push   %eax
801049b7:	6a 01                	push   $0x1
801049b9:	e8 bc f5 ff ff       	call   80103f7a <argint>
  if((argstr(0, &path)) < 0 ||
801049be:	83 c4 10             	add    $0x10,%esp
801049c1:	85 c0                	test   %eax,%eax
801049c3:	78 4d                	js     80104a12 <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
801049c5:	83 ec 08             	sub    $0x8,%esp
801049c8:	8d 45 ec             	lea    -0x14(%ebp),%eax
801049cb:	50                   	push   %eax
801049cc:	6a 02                	push   $0x2
801049ce:	e8 a7 f5 ff ff       	call   80103f7a <argint>
     argint(1, &major) < 0 ||
801049d3:	83 c4 10             	add    $0x10,%esp
801049d6:	85 c0                	test   %eax,%eax
801049d8:	78 38                	js     80104a12 <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
801049da:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
801049de:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
801049e2:	83 ec 0c             	sub    $0xc,%esp
801049e5:	50                   	push   %eax
801049e6:	ba 03 00 00 00       	mov    $0x3,%edx
801049eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049ee:	e8 94 f7 ff ff       	call   80104187 <create>
801049f3:	83 c4 10             	add    $0x10,%esp
801049f6:	85 c0                	test   %eax,%eax
801049f8:	74 18                	je     80104a12 <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
801049fa:	83 ec 0c             	sub    $0xc,%esp
801049fd:	50                   	push   %eax
801049fe:	e8 25 cd ff ff       	call   80101728 <iunlockput>
  end_op();
80104a03:	e8 5a de ff ff       	call   80102862 <end_op>
  return 0;
80104a08:	83 c4 10             	add    $0x10,%esp
80104a0b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104a10:	c9                   	leave  
80104a11:	c3                   	ret    
    end_op();
80104a12:	e8 4b de ff ff       	call   80102862 <end_op>
    return -1;
80104a17:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a1c:	eb f2                	jmp    80104a10 <sys_mknod+0x80>

80104a1e <sys_chdir>:

int
sys_chdir(void)
{
80104a1e:	55                   	push   %ebp
80104a1f:	89 e5                	mov    %esp,%ebp
80104a21:	56                   	push   %esi
80104a22:	53                   	push   %ebx
80104a23:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104a26:	e8 05 e8 ff ff       	call   80103230 <myproc>
80104a2b:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104a2d:	e8 b6 dd ff ff       	call   801027e8 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104a32:	83 ec 08             	sub    $0x8,%esp
80104a35:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104a38:	50                   	push   %eax
80104a39:	6a 00                	push   $0x0
80104a3b:	e8 ca f5 ff ff       	call   8010400a <argstr>
80104a40:	83 c4 10             	add    $0x10,%esp
80104a43:	85 c0                	test   %eax,%eax
80104a45:	78 52                	js     80104a99 <sys_chdir+0x7b>
80104a47:	83 ec 0c             	sub    $0xc,%esp
80104a4a:	ff 75 f4             	pushl  -0xc(%ebp)
80104a4d:	e8 8f d1 ff ff       	call   80101be1 <namei>
80104a52:	89 c3                	mov    %eax,%ebx
80104a54:	83 c4 10             	add    $0x10,%esp
80104a57:	85 c0                	test   %eax,%eax
80104a59:	74 3e                	je     80104a99 <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104a5b:	83 ec 0c             	sub    $0xc,%esp
80104a5e:	50                   	push   %eax
80104a5f:	e8 1d cb ff ff       	call   80101581 <ilock>
  if(ip->type != T_DIR){
80104a64:	83 c4 10             	add    $0x10,%esp
80104a67:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104a6c:	75 37                	jne    80104aa5 <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104a6e:	83 ec 0c             	sub    $0xc,%esp
80104a71:	53                   	push   %ebx
80104a72:	e8 cc cb ff ff       	call   80101643 <iunlock>
  iput(curproc->cwd);
80104a77:	83 c4 04             	add    $0x4,%esp
80104a7a:	ff 76 68             	pushl  0x68(%esi)
80104a7d:	e8 06 cc ff ff       	call   80101688 <iput>
  end_op();
80104a82:	e8 db dd ff ff       	call   80102862 <end_op>
  curproc->cwd = ip;
80104a87:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104a8a:	83 c4 10             	add    $0x10,%esp
80104a8d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104a92:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104a95:	5b                   	pop    %ebx
80104a96:	5e                   	pop    %esi
80104a97:	5d                   	pop    %ebp
80104a98:	c3                   	ret    
    end_op();
80104a99:	e8 c4 dd ff ff       	call   80102862 <end_op>
    return -1;
80104a9e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104aa3:	eb ed                	jmp    80104a92 <sys_chdir+0x74>
    iunlockput(ip);
80104aa5:	83 ec 0c             	sub    $0xc,%esp
80104aa8:	53                   	push   %ebx
80104aa9:	e8 7a cc ff ff       	call   80101728 <iunlockput>
    end_op();
80104aae:	e8 af dd ff ff       	call   80102862 <end_op>
    return -1;
80104ab3:	83 c4 10             	add    $0x10,%esp
80104ab6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104abb:	eb d5                	jmp    80104a92 <sys_chdir+0x74>

80104abd <sys_exec>:

int
sys_exec(void)
{
80104abd:	55                   	push   %ebp
80104abe:	89 e5                	mov    %esp,%ebp
80104ac0:	53                   	push   %ebx
80104ac1:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104ac7:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104aca:	50                   	push   %eax
80104acb:	6a 00                	push   $0x0
80104acd:	e8 38 f5 ff ff       	call   8010400a <argstr>
80104ad2:	83 c4 10             	add    $0x10,%esp
80104ad5:	85 c0                	test   %eax,%eax
80104ad7:	0f 88 a8 00 00 00    	js     80104b85 <sys_exec+0xc8>
80104add:	83 ec 08             	sub    $0x8,%esp
80104ae0:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104ae6:	50                   	push   %eax
80104ae7:	6a 01                	push   $0x1
80104ae9:	e8 8c f4 ff ff       	call   80103f7a <argint>
80104aee:	83 c4 10             	add    $0x10,%esp
80104af1:	85 c0                	test   %eax,%eax
80104af3:	0f 88 93 00 00 00    	js     80104b8c <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104af9:	83 ec 04             	sub    $0x4,%esp
80104afc:	68 80 00 00 00       	push   $0x80
80104b01:	6a 00                	push   $0x0
80104b03:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104b09:	50                   	push   %eax
80104b0a:	e8 20 f2 ff ff       	call   80103d2f <memset>
80104b0f:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104b12:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104b17:	83 fb 1f             	cmp    $0x1f,%ebx
80104b1a:	77 77                	ja     80104b93 <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104b1c:	83 ec 08             	sub    $0x8,%esp
80104b1f:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104b25:	50                   	push   %eax
80104b26:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104b2c:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104b2f:	50                   	push   %eax
80104b30:	e8 c9 f3 ff ff       	call   80103efe <fetchint>
80104b35:	83 c4 10             	add    $0x10,%esp
80104b38:	85 c0                	test   %eax,%eax
80104b3a:	78 5e                	js     80104b9a <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104b3c:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104b42:	85 c0                	test   %eax,%eax
80104b44:	74 1d                	je     80104b63 <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104b46:	83 ec 08             	sub    $0x8,%esp
80104b49:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104b50:	52                   	push   %edx
80104b51:	50                   	push   %eax
80104b52:	e8 e3 f3 ff ff       	call   80103f3a <fetchstr>
80104b57:	83 c4 10             	add    $0x10,%esp
80104b5a:	85 c0                	test   %eax,%eax
80104b5c:	78 46                	js     80104ba4 <sys_exec+0xe7>
  for(i=0;; i++){
80104b5e:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104b61:	eb b4                	jmp    80104b17 <sys_exec+0x5a>
      argv[i] = 0;
80104b63:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104b6a:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104b6e:	83 ec 08             	sub    $0x8,%esp
80104b71:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104b77:	50                   	push   %eax
80104b78:	ff 75 f4             	pushl  -0xc(%ebp)
80104b7b:	e8 52 bd ff ff       	call   801008d2 <exec>
80104b80:	83 c4 10             	add    $0x10,%esp
80104b83:	eb 1a                	jmp    80104b9f <sys_exec+0xe2>
    return -1;
80104b85:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b8a:	eb 13                	jmp    80104b9f <sys_exec+0xe2>
80104b8c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b91:	eb 0c                	jmp    80104b9f <sys_exec+0xe2>
      return -1;
80104b93:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b98:	eb 05                	jmp    80104b9f <sys_exec+0xe2>
      return -1;
80104b9a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104b9f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104ba2:	c9                   	leave  
80104ba3:	c3                   	ret    
      return -1;
80104ba4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ba9:	eb f4                	jmp    80104b9f <sys_exec+0xe2>

80104bab <sys_pipe>:

int
sys_pipe(void)
{
80104bab:	55                   	push   %ebp
80104bac:	89 e5                	mov    %esp,%ebp
80104bae:	53                   	push   %ebx
80104baf:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104bb2:	6a 08                	push   $0x8
80104bb4:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104bb7:	50                   	push   %eax
80104bb8:	6a 00                	push   $0x0
80104bba:	e8 e3 f3 ff ff       	call   80103fa2 <argptr>
80104bbf:	83 c4 10             	add    $0x10,%esp
80104bc2:	85 c0                	test   %eax,%eax
80104bc4:	78 77                	js     80104c3d <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104bc6:	83 ec 08             	sub    $0x8,%esp
80104bc9:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104bcc:	50                   	push   %eax
80104bcd:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104bd0:	50                   	push   %eax
80104bd1:	e8 99 e1 ff ff       	call   80102d6f <pipealloc>
80104bd6:	83 c4 10             	add    $0x10,%esp
80104bd9:	85 c0                	test   %eax,%eax
80104bdb:	78 67                	js     80104c44 <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104bdd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104be0:	e8 14 f5 ff ff       	call   801040f9 <fdalloc>
80104be5:	89 c3                	mov    %eax,%ebx
80104be7:	85 c0                	test   %eax,%eax
80104be9:	78 21                	js     80104c0c <sys_pipe+0x61>
80104beb:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104bee:	e8 06 f5 ff ff       	call   801040f9 <fdalloc>
80104bf3:	85 c0                	test   %eax,%eax
80104bf5:	78 15                	js     80104c0c <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104bf7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104bfa:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104bfc:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104bff:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104c02:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104c07:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104c0a:	c9                   	leave  
80104c0b:	c3                   	ret    
    if(fd0 >= 0)
80104c0c:	85 db                	test   %ebx,%ebx
80104c0e:	78 0d                	js     80104c1d <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104c10:	e8 1b e6 ff ff       	call   80103230 <myproc>
80104c15:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104c1c:	00 
    fileclose(rf);
80104c1d:	83 ec 0c             	sub    $0xc,%esp
80104c20:	ff 75 f0             	pushl  -0x10(%ebp)
80104c23:	e8 ab c0 ff ff       	call   80100cd3 <fileclose>
    fileclose(wf);
80104c28:	83 c4 04             	add    $0x4,%esp
80104c2b:	ff 75 ec             	pushl  -0x14(%ebp)
80104c2e:	e8 a0 c0 ff ff       	call   80100cd3 <fileclose>
    return -1;
80104c33:	83 c4 10             	add    $0x10,%esp
80104c36:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c3b:	eb ca                	jmp    80104c07 <sys_pipe+0x5c>
    return -1;
80104c3d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c42:	eb c3                	jmp    80104c07 <sys_pipe+0x5c>
    return -1;
80104c44:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c49:	eb bc                	jmp    80104c07 <sys_pipe+0x5c>

80104c4b <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104c4b:	55                   	push   %ebp
80104c4c:	89 e5                	mov    %esp,%ebp
80104c4e:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104c51:	e8 6e e7 ff ff       	call   801033c4 <fork>
}
80104c56:	c9                   	leave  
80104c57:	c3                   	ret    

80104c58 <sys_exit>:

int
sys_exit(void)
{
80104c58:	55                   	push   %ebp
80104c59:	89 e5                	mov    %esp,%ebp
80104c5b:	83 ec 08             	sub    $0x8,%esp
  exit();
80104c5e:	e8 95 e9 ff ff       	call   801035f8 <exit>
  return 0;  // not reached
}
80104c63:	b8 00 00 00 00       	mov    $0x0,%eax
80104c68:	c9                   	leave  
80104c69:	c3                   	ret    

80104c6a <sys_wait>:

int
sys_wait(void)
{
80104c6a:	55                   	push   %ebp
80104c6b:	89 e5                	mov    %esp,%ebp
80104c6d:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104c70:	e8 0c eb ff ff       	call   80103781 <wait>
}
80104c75:	c9                   	leave  
80104c76:	c3                   	ret    

80104c77 <sys_kill>:

int
sys_kill(void)
{
80104c77:	55                   	push   %ebp
80104c78:	89 e5                	mov    %esp,%ebp
80104c7a:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104c7d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c80:	50                   	push   %eax
80104c81:	6a 00                	push   $0x0
80104c83:	e8 f2 f2 ff ff       	call   80103f7a <argint>
80104c88:	83 c4 10             	add    $0x10,%esp
80104c8b:	85 c0                	test   %eax,%eax
80104c8d:	78 10                	js     80104c9f <sys_kill+0x28>
    return -1;
  return kill(pid);
80104c8f:	83 ec 0c             	sub    $0xc,%esp
80104c92:	ff 75 f4             	pushl  -0xc(%ebp)
80104c95:	e8 e4 eb ff ff       	call   8010387e <kill>
80104c9a:	83 c4 10             	add    $0x10,%esp
}
80104c9d:	c9                   	leave  
80104c9e:	c3                   	ret    
    return -1;
80104c9f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ca4:	eb f7                	jmp    80104c9d <sys_kill+0x26>

80104ca6 <sys_dump_physmem>:

int
sys_dump_physmem(void)
{
80104ca6:	55                   	push   %ebp
80104ca7:	89 e5                	mov    %esp,%ebp
80104ca9:	83 ec 1c             	sub    $0x1c,%esp
  int *frames;
  int *pids;
  int numframes;
  
  if (argptr(0, (void *)&frames, sizeof(*frames)) < 0) {
80104cac:	6a 04                	push   $0x4
80104cae:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104cb1:	50                   	push   %eax
80104cb2:	6a 00                	push   $0x0
80104cb4:	e8 e9 f2 ff ff       	call   80103fa2 <argptr>
80104cb9:	83 c4 10             	add    $0x10,%esp
80104cbc:	85 c0                	test   %eax,%eax
80104cbe:	78 42                	js     80104d02 <sys_dump_physmem+0x5c>
    return -1;
  }
  if (argptr(1, (void *)&pids, sizeof(*pids)) < 0) {
80104cc0:	83 ec 04             	sub    $0x4,%esp
80104cc3:	6a 04                	push   $0x4
80104cc5:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104cc8:	50                   	push   %eax
80104cc9:	6a 01                	push   $0x1
80104ccb:	e8 d2 f2 ff ff       	call   80103fa2 <argptr>
80104cd0:	83 c4 10             	add    $0x10,%esp
80104cd3:	85 c0                	test   %eax,%eax
80104cd5:	78 32                	js     80104d09 <sys_dump_physmem+0x63>
    return -1;
  }
  if(argint(2, &numframes) < 0)
80104cd7:	83 ec 08             	sub    $0x8,%esp
80104cda:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104cdd:	50                   	push   %eax
80104cde:	6a 02                	push   $0x2
80104ce0:	e8 95 f2 ff ff       	call   80103f7a <argint>
80104ce5:	83 c4 10             	add    $0x10,%esp
80104ce8:	85 c0                	test   %eax,%eax
80104cea:	78 24                	js     80104d10 <sys_dump_physmem+0x6a>
    return -1;
  return dump_physmem(frames, pids, numframes);
80104cec:	83 ec 04             	sub    $0x4,%esp
80104cef:	ff 75 ec             	pushl  -0x14(%ebp)
80104cf2:	ff 75 f0             	pushl  -0x10(%ebp)
80104cf5:	ff 75 f4             	pushl  -0xc(%ebp)
80104cf8:	e8 f5 eb ff ff       	call   801038f2 <dump_physmem>
80104cfd:	83 c4 10             	add    $0x10,%esp
}
80104d00:	c9                   	leave  
80104d01:	c3                   	ret    
    return -1;
80104d02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d07:	eb f7                	jmp    80104d00 <sys_dump_physmem+0x5a>
    return -1;
80104d09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d0e:	eb f0                	jmp    80104d00 <sys_dump_physmem+0x5a>
    return -1;
80104d10:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d15:	eb e9                	jmp    80104d00 <sys_dump_physmem+0x5a>

80104d17 <sys_getpid>:

int
sys_getpid(void)
{
80104d17:	55                   	push   %ebp
80104d18:	89 e5                	mov    %esp,%ebp
80104d1a:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104d1d:	e8 0e e5 ff ff       	call   80103230 <myproc>
80104d22:	8b 40 10             	mov    0x10(%eax),%eax
}
80104d25:	c9                   	leave  
80104d26:	c3                   	ret    

80104d27 <sys_sbrk>:

int
sys_sbrk(void)
{
80104d27:	55                   	push   %ebp
80104d28:	89 e5                	mov    %esp,%ebp
80104d2a:	53                   	push   %ebx
80104d2b:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104d2e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d31:	50                   	push   %eax
80104d32:	6a 00                	push   $0x0
80104d34:	e8 41 f2 ff ff       	call   80103f7a <argint>
80104d39:	83 c4 10             	add    $0x10,%esp
80104d3c:	85 c0                	test   %eax,%eax
80104d3e:	78 27                	js     80104d67 <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80104d40:	e8 eb e4 ff ff       	call   80103230 <myproc>
80104d45:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104d47:	83 ec 0c             	sub    $0xc,%esp
80104d4a:	ff 75 f4             	pushl  -0xc(%ebp)
80104d4d:	e8 05 e6 ff ff       	call   80103357 <growproc>
80104d52:	83 c4 10             	add    $0x10,%esp
80104d55:	85 c0                	test   %eax,%eax
80104d57:	78 07                	js     80104d60 <sys_sbrk+0x39>
    return -1;
  return addr;
}
80104d59:	89 d8                	mov    %ebx,%eax
80104d5b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104d5e:	c9                   	leave  
80104d5f:	c3                   	ret    
    return -1;
80104d60:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104d65:	eb f2                	jmp    80104d59 <sys_sbrk+0x32>
    return -1;
80104d67:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104d6c:	eb eb                	jmp    80104d59 <sys_sbrk+0x32>

80104d6e <sys_sleep>:

int
sys_sleep(void)
{
80104d6e:	55                   	push   %ebp
80104d6f:	89 e5                	mov    %esp,%ebp
80104d71:	53                   	push   %ebx
80104d72:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104d75:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d78:	50                   	push   %eax
80104d79:	6a 00                	push   $0x0
80104d7b:	e8 fa f1 ff ff       	call   80103f7a <argint>
80104d80:	83 c4 10             	add    $0x10,%esp
80104d83:	85 c0                	test   %eax,%eax
80104d85:	78 75                	js     80104dfc <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80104d87:	83 ec 0c             	sub    $0xc,%esp
80104d8a:	68 e0 c6 35 80       	push   $0x8035c6e0
80104d8f:	e8 ef ee ff ff       	call   80103c83 <acquire>
  ticks0 = ticks;
80104d94:	8b 1d 20 cf 35 80    	mov    0x8035cf20,%ebx
  while(ticks - ticks0 < n){
80104d9a:	83 c4 10             	add    $0x10,%esp
80104d9d:	a1 20 cf 35 80       	mov    0x8035cf20,%eax
80104da2:	29 d8                	sub    %ebx,%eax
80104da4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104da7:	73 39                	jae    80104de2 <sys_sleep+0x74>
    if(myproc()->killed){
80104da9:	e8 82 e4 ff ff       	call   80103230 <myproc>
80104dae:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104db2:	75 17                	jne    80104dcb <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80104db4:	83 ec 08             	sub    $0x8,%esp
80104db7:	68 e0 c6 35 80       	push   $0x8035c6e0
80104dbc:	68 20 cf 35 80       	push   $0x8035cf20
80104dc1:	e8 2a e9 ff ff       	call   801036f0 <sleep>
80104dc6:	83 c4 10             	add    $0x10,%esp
80104dc9:	eb d2                	jmp    80104d9d <sys_sleep+0x2f>
      release(&tickslock);
80104dcb:	83 ec 0c             	sub    $0xc,%esp
80104dce:	68 e0 c6 35 80       	push   $0x8035c6e0
80104dd3:	e8 10 ef ff ff       	call   80103ce8 <release>
      return -1;
80104dd8:	83 c4 10             	add    $0x10,%esp
80104ddb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104de0:	eb 15                	jmp    80104df7 <sys_sleep+0x89>
  }
  release(&tickslock);
80104de2:	83 ec 0c             	sub    $0xc,%esp
80104de5:	68 e0 c6 35 80       	push   $0x8035c6e0
80104dea:	e8 f9 ee ff ff       	call   80103ce8 <release>
  return 0;
80104def:	83 c4 10             	add    $0x10,%esp
80104df2:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104df7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104dfa:	c9                   	leave  
80104dfb:	c3                   	ret    
    return -1;
80104dfc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e01:	eb f4                	jmp    80104df7 <sys_sleep+0x89>

80104e03 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104e03:	55                   	push   %ebp
80104e04:	89 e5                	mov    %esp,%ebp
80104e06:	53                   	push   %ebx
80104e07:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80104e0a:	68 e0 c6 35 80       	push   $0x8035c6e0
80104e0f:	e8 6f ee ff ff       	call   80103c83 <acquire>
  xticks = ticks;
80104e14:	8b 1d 20 cf 35 80    	mov    0x8035cf20,%ebx
  release(&tickslock);
80104e1a:	c7 04 24 e0 c6 35 80 	movl   $0x8035c6e0,(%esp)
80104e21:	e8 c2 ee ff ff       	call   80103ce8 <release>
  return xticks;
}
80104e26:	89 d8                	mov    %ebx,%eax
80104e28:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e2b:	c9                   	leave  
80104e2c:	c3                   	ret    

80104e2d <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80104e2d:	1e                   	push   %ds
  pushl %es
80104e2e:	06                   	push   %es
  pushl %fs
80104e2f:	0f a0                	push   %fs
  pushl %gs
80104e31:	0f a8                	push   %gs
  pushal
80104e33:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80104e34:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80104e38:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80104e3a:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80104e3c:	54                   	push   %esp
  call trap
80104e3d:	e8 e3 00 00 00       	call   80104f25 <trap>
  addl $4, %esp
80104e42:	83 c4 04             	add    $0x4,%esp

80104e45 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80104e45:	61                   	popa   
  popl %gs
80104e46:	0f a9                	pop    %gs
  popl %fs
80104e48:	0f a1                	pop    %fs
  popl %es
80104e4a:	07                   	pop    %es
  popl %ds
80104e4b:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80104e4c:	83 c4 08             	add    $0x8,%esp
  iret
80104e4f:	cf                   	iret   

80104e50 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80104e50:	55                   	push   %ebp
80104e51:	89 e5                	mov    %esp,%ebp
80104e53:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
80104e56:	b8 00 00 00 00       	mov    $0x0,%eax
80104e5b:	eb 4a                	jmp    80104ea7 <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80104e5d:	8b 0c 85 08 90 10 80 	mov    -0x7fef6ff8(,%eax,4),%ecx
80104e64:	66 89 0c c5 20 c7 35 	mov    %cx,-0x7fca38e0(,%eax,8)
80104e6b:	80 
80104e6c:	66 c7 04 c5 22 c7 35 	movw   $0x8,-0x7fca38de(,%eax,8)
80104e73:	80 08 00 
80104e76:	c6 04 c5 24 c7 35 80 	movb   $0x0,-0x7fca38dc(,%eax,8)
80104e7d:	00 
80104e7e:	0f b6 14 c5 25 c7 35 	movzbl -0x7fca38db(,%eax,8),%edx
80104e85:	80 
80104e86:	83 e2 f0             	and    $0xfffffff0,%edx
80104e89:	83 ca 0e             	or     $0xe,%edx
80104e8c:	83 e2 8f             	and    $0xffffff8f,%edx
80104e8f:	83 ca 80             	or     $0xffffff80,%edx
80104e92:	88 14 c5 25 c7 35 80 	mov    %dl,-0x7fca38db(,%eax,8)
80104e99:	c1 e9 10             	shr    $0x10,%ecx
80104e9c:	66 89 0c c5 26 c7 35 	mov    %cx,-0x7fca38da(,%eax,8)
80104ea3:	80 
  for(i = 0; i < 256; i++)
80104ea4:	83 c0 01             	add    $0x1,%eax
80104ea7:	3d ff 00 00 00       	cmp    $0xff,%eax
80104eac:	7e af                	jle    80104e5d <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80104eae:	8b 15 08 91 10 80    	mov    0x80109108,%edx
80104eb4:	66 89 15 20 c9 35 80 	mov    %dx,0x8035c920
80104ebb:	66 c7 05 22 c9 35 80 	movw   $0x8,0x8035c922
80104ec2:	08 00 
80104ec4:	c6 05 24 c9 35 80 00 	movb   $0x0,0x8035c924
80104ecb:	0f b6 05 25 c9 35 80 	movzbl 0x8035c925,%eax
80104ed2:	83 c8 0f             	or     $0xf,%eax
80104ed5:	83 e0 ef             	and    $0xffffffef,%eax
80104ed8:	83 c8 e0             	or     $0xffffffe0,%eax
80104edb:	a2 25 c9 35 80       	mov    %al,0x8035c925
80104ee0:	c1 ea 10             	shr    $0x10,%edx
80104ee3:	66 89 15 26 c9 35 80 	mov    %dx,0x8035c926

  initlock(&tickslock, "time");
80104eea:	83 ec 08             	sub    $0x8,%esp
80104eed:	68 3d 6d 10 80       	push   $0x80106d3d
80104ef2:	68 e0 c6 35 80       	push   $0x8035c6e0
80104ef7:	e8 4b ec ff ff       	call   80103b47 <initlock>
}
80104efc:	83 c4 10             	add    $0x10,%esp
80104eff:	c9                   	leave  
80104f00:	c3                   	ret    

80104f01 <idtinit>:

void
idtinit(void)
{
80104f01:	55                   	push   %ebp
80104f02:	89 e5                	mov    %esp,%ebp
80104f04:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80104f07:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
80104f0d:	b8 20 c7 35 80       	mov    $0x8035c720,%eax
80104f12:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80104f16:	c1 e8 10             	shr    $0x10,%eax
80104f19:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
80104f1d:	8d 45 fa             	lea    -0x6(%ebp),%eax
80104f20:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
80104f23:	c9                   	leave  
80104f24:	c3                   	ret    

80104f25 <trap>:

void
trap(struct trapframe *tf)
{
80104f25:	55                   	push   %ebp
80104f26:	89 e5                	mov    %esp,%ebp
80104f28:	57                   	push   %edi
80104f29:	56                   	push   %esi
80104f2a:	53                   	push   %ebx
80104f2b:	83 ec 1c             	sub    $0x1c,%esp
80104f2e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
80104f31:	8b 43 30             	mov    0x30(%ebx),%eax
80104f34:	83 f8 40             	cmp    $0x40,%eax
80104f37:	74 13                	je     80104f4c <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
80104f39:	83 e8 20             	sub    $0x20,%eax
80104f3c:	83 f8 1f             	cmp    $0x1f,%eax
80104f3f:	0f 87 3a 01 00 00    	ja     8010507f <trap+0x15a>
80104f45:	ff 24 85 e4 6d 10 80 	jmp    *-0x7fef921c(,%eax,4)
    if(myproc()->killed)
80104f4c:	e8 df e2 ff ff       	call   80103230 <myproc>
80104f51:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104f55:	75 1f                	jne    80104f76 <trap+0x51>
    myproc()->tf = tf;
80104f57:	e8 d4 e2 ff ff       	call   80103230 <myproc>
80104f5c:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
80104f5f:	e8 d9 f0 ff ff       	call   8010403d <syscall>
    if(myproc()->killed)
80104f64:	e8 c7 e2 ff ff       	call   80103230 <myproc>
80104f69:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104f6d:	74 7e                	je     80104fed <trap+0xc8>
      exit();
80104f6f:	e8 84 e6 ff ff       	call   801035f8 <exit>
80104f74:	eb 77                	jmp    80104fed <trap+0xc8>
      exit();
80104f76:	e8 7d e6 ff ff       	call   801035f8 <exit>
80104f7b:	eb da                	jmp    80104f57 <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
80104f7d:	e8 93 e2 ff ff       	call   80103215 <cpuid>
80104f82:	85 c0                	test   %eax,%eax
80104f84:	74 6f                	je     80104ff5 <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
80104f86:	e8 48 d4 ff ff       	call   801023d3 <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80104f8b:	e8 a0 e2 ff ff       	call   80103230 <myproc>
80104f90:	85 c0                	test   %eax,%eax
80104f92:	74 1c                	je     80104fb0 <trap+0x8b>
80104f94:	e8 97 e2 ff ff       	call   80103230 <myproc>
80104f99:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104f9d:	74 11                	je     80104fb0 <trap+0x8b>
80104f9f:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80104fa3:	83 e0 03             	and    $0x3,%eax
80104fa6:	66 83 f8 03          	cmp    $0x3,%ax
80104faa:	0f 84 62 01 00 00    	je     80105112 <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80104fb0:	e8 7b e2 ff ff       	call   80103230 <myproc>
80104fb5:	85 c0                	test   %eax,%eax
80104fb7:	74 0f                	je     80104fc8 <trap+0xa3>
80104fb9:	e8 72 e2 ff ff       	call   80103230 <myproc>
80104fbe:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
80104fc2:	0f 84 54 01 00 00    	je     8010511c <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80104fc8:	e8 63 e2 ff ff       	call   80103230 <myproc>
80104fcd:	85 c0                	test   %eax,%eax
80104fcf:	74 1c                	je     80104fed <trap+0xc8>
80104fd1:	e8 5a e2 ff ff       	call   80103230 <myproc>
80104fd6:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104fda:	74 11                	je     80104fed <trap+0xc8>
80104fdc:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80104fe0:	83 e0 03             	and    $0x3,%eax
80104fe3:	66 83 f8 03          	cmp    $0x3,%ax
80104fe7:	0f 84 43 01 00 00    	je     80105130 <trap+0x20b>
    exit();
}
80104fed:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104ff0:	5b                   	pop    %ebx
80104ff1:	5e                   	pop    %esi
80104ff2:	5f                   	pop    %edi
80104ff3:	5d                   	pop    %ebp
80104ff4:	c3                   	ret    
      acquire(&tickslock);
80104ff5:	83 ec 0c             	sub    $0xc,%esp
80104ff8:	68 e0 c6 35 80       	push   $0x8035c6e0
80104ffd:	e8 81 ec ff ff       	call   80103c83 <acquire>
      ticks++;
80105002:	83 05 20 cf 35 80 01 	addl   $0x1,0x8035cf20
      wakeup(&ticks);
80105009:	c7 04 24 20 cf 35 80 	movl   $0x8035cf20,(%esp)
80105010:	e8 40 e8 ff ff       	call   80103855 <wakeup>
      release(&tickslock);
80105015:	c7 04 24 e0 c6 35 80 	movl   $0x8035c6e0,(%esp)
8010501c:	e8 c7 ec ff ff       	call   80103ce8 <release>
80105021:	83 c4 10             	add    $0x10,%esp
80105024:	e9 5d ff ff ff       	jmp    80104f86 <trap+0x61>
    ideintr();
80105029:	e8 45 cd ff ff       	call   80101d73 <ideintr>
    lapiceoi();
8010502e:	e8 a0 d3 ff ff       	call   801023d3 <lapiceoi>
    break;
80105033:	e9 53 ff ff ff       	jmp    80104f8b <trap+0x66>
    kbdintr();
80105038:	e8 da d1 ff ff       	call   80102217 <kbdintr>
    lapiceoi();
8010503d:	e8 91 d3 ff ff       	call   801023d3 <lapiceoi>
    break;
80105042:	e9 44 ff ff ff       	jmp    80104f8b <trap+0x66>
    uartintr();
80105047:	e8 05 02 00 00       	call   80105251 <uartintr>
    lapiceoi();
8010504c:	e8 82 d3 ff ff       	call   801023d3 <lapiceoi>
    break;
80105051:	e9 35 ff ff ff       	jmp    80104f8b <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80105056:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
80105059:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010505d:	e8 b3 e1 ff ff       	call   80103215 <cpuid>
80105062:	57                   	push   %edi
80105063:	0f b7 f6             	movzwl %si,%esi
80105066:	56                   	push   %esi
80105067:	50                   	push   %eax
80105068:	68 48 6d 10 80       	push   $0x80106d48
8010506d:	e8 99 b5 ff ff       	call   8010060b <cprintf>
    lapiceoi();
80105072:	e8 5c d3 ff ff       	call   801023d3 <lapiceoi>
    break;
80105077:	83 c4 10             	add    $0x10,%esp
8010507a:	e9 0c ff ff ff       	jmp    80104f8b <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
8010507f:	e8 ac e1 ff ff       	call   80103230 <myproc>
80105084:	85 c0                	test   %eax,%eax
80105086:	74 5f                	je     801050e7 <trap+0x1c2>
80105088:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
8010508c:	74 59                	je     801050e7 <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
8010508e:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105091:	8b 43 38             	mov    0x38(%ebx),%eax
80105094:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105097:	e8 79 e1 ff ff       	call   80103215 <cpuid>
8010509c:	89 45 e0             	mov    %eax,-0x20(%ebp)
8010509f:	8b 53 34             	mov    0x34(%ebx),%edx
801050a2:	89 55 dc             	mov    %edx,-0x24(%ebp)
801050a5:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
801050a8:	e8 83 e1 ff ff       	call   80103230 <myproc>
801050ad:	8d 48 6c             	lea    0x6c(%eax),%ecx
801050b0:	89 4d d8             	mov    %ecx,-0x28(%ebp)
801050b3:	e8 78 e1 ff ff       	call   80103230 <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801050b8:	57                   	push   %edi
801050b9:	ff 75 e4             	pushl  -0x1c(%ebp)
801050bc:	ff 75 e0             	pushl  -0x20(%ebp)
801050bf:	ff 75 dc             	pushl  -0x24(%ebp)
801050c2:	56                   	push   %esi
801050c3:	ff 75 d8             	pushl  -0x28(%ebp)
801050c6:	ff 70 10             	pushl  0x10(%eax)
801050c9:	68 a0 6d 10 80       	push   $0x80106da0
801050ce:	e8 38 b5 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
801050d3:	83 c4 20             	add    $0x20,%esp
801050d6:	e8 55 e1 ff ff       	call   80103230 <myproc>
801050db:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
801050e2:	e9 a4 fe ff ff       	jmp    80104f8b <trap+0x66>
801050e7:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801050ea:	8b 73 38             	mov    0x38(%ebx),%esi
801050ed:	e8 23 e1 ff ff       	call   80103215 <cpuid>
801050f2:	83 ec 0c             	sub    $0xc,%esp
801050f5:	57                   	push   %edi
801050f6:	56                   	push   %esi
801050f7:	50                   	push   %eax
801050f8:	ff 73 30             	pushl  0x30(%ebx)
801050fb:	68 6c 6d 10 80       	push   $0x80106d6c
80105100:	e8 06 b5 ff ff       	call   8010060b <cprintf>
      panic("trap");
80105105:	83 c4 14             	add    $0x14,%esp
80105108:	68 42 6d 10 80       	push   $0x80106d42
8010510d:	e8 36 b2 ff ff       	call   80100348 <panic>
    exit();
80105112:	e8 e1 e4 ff ff       	call   801035f8 <exit>
80105117:	e9 94 fe ff ff       	jmp    80104fb0 <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
8010511c:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
80105120:	0f 85 a2 fe ff ff    	jne    80104fc8 <trap+0xa3>
    yield();
80105126:	e8 93 e5 ff ff       	call   801036be <yield>
8010512b:	e9 98 fe ff ff       	jmp    80104fc8 <trap+0xa3>
    exit();
80105130:	e8 c3 e4 ff ff       	call   801035f8 <exit>
80105135:	e9 b3 fe ff ff       	jmp    80104fed <trap+0xc8>

8010513a <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
8010513a:	55                   	push   %ebp
8010513b:	89 e5                	mov    %esp,%ebp
  if(!uart)
8010513d:	83 3d bc 95 10 80 00 	cmpl   $0x0,0x801095bc
80105144:	74 15                	je     8010515b <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80105146:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010514b:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
8010514c:	a8 01                	test   $0x1,%al
8010514e:	74 12                	je     80105162 <uartgetc+0x28>
80105150:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105155:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
80105156:	0f b6 c0             	movzbl %al,%eax
}
80105159:	5d                   	pop    %ebp
8010515a:	c3                   	ret    
    return -1;
8010515b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105160:	eb f7                	jmp    80105159 <uartgetc+0x1f>
    return -1;
80105162:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105167:	eb f0                	jmp    80105159 <uartgetc+0x1f>

80105169 <uartputc>:
  if(!uart)
80105169:	83 3d bc 95 10 80 00 	cmpl   $0x0,0x801095bc
80105170:	74 3b                	je     801051ad <uartputc+0x44>
{
80105172:	55                   	push   %ebp
80105173:	89 e5                	mov    %esp,%ebp
80105175:	53                   	push   %ebx
80105176:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105179:	bb 00 00 00 00       	mov    $0x0,%ebx
8010517e:	eb 10                	jmp    80105190 <uartputc+0x27>
    microdelay(10);
80105180:	83 ec 0c             	sub    $0xc,%esp
80105183:	6a 0a                	push   $0xa
80105185:	e8 68 d2 ff ff       	call   801023f2 <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010518a:	83 c3 01             	add    $0x1,%ebx
8010518d:	83 c4 10             	add    $0x10,%esp
80105190:	83 fb 7f             	cmp    $0x7f,%ebx
80105193:	7f 0a                	jg     8010519f <uartputc+0x36>
80105195:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010519a:	ec                   	in     (%dx),%al
8010519b:	a8 20                	test   $0x20,%al
8010519d:	74 e1                	je     80105180 <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010519f:	8b 45 08             	mov    0x8(%ebp),%eax
801051a2:	ba f8 03 00 00       	mov    $0x3f8,%edx
801051a7:	ee                   	out    %al,(%dx)
}
801051a8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801051ab:	c9                   	leave  
801051ac:	c3                   	ret    
801051ad:	f3 c3                	repz ret 

801051af <uartinit>:
{
801051af:	55                   	push   %ebp
801051b0:	89 e5                	mov    %esp,%ebp
801051b2:	56                   	push   %esi
801051b3:	53                   	push   %ebx
801051b4:	b9 00 00 00 00       	mov    $0x0,%ecx
801051b9:	ba fa 03 00 00       	mov    $0x3fa,%edx
801051be:	89 c8                	mov    %ecx,%eax
801051c0:	ee                   	out    %al,(%dx)
801051c1:	be fb 03 00 00       	mov    $0x3fb,%esi
801051c6:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
801051cb:	89 f2                	mov    %esi,%edx
801051cd:	ee                   	out    %al,(%dx)
801051ce:	b8 0c 00 00 00       	mov    $0xc,%eax
801051d3:	ba f8 03 00 00       	mov    $0x3f8,%edx
801051d8:	ee                   	out    %al,(%dx)
801051d9:	bb f9 03 00 00       	mov    $0x3f9,%ebx
801051de:	89 c8                	mov    %ecx,%eax
801051e0:	89 da                	mov    %ebx,%edx
801051e2:	ee                   	out    %al,(%dx)
801051e3:	b8 03 00 00 00       	mov    $0x3,%eax
801051e8:	89 f2                	mov    %esi,%edx
801051ea:	ee                   	out    %al,(%dx)
801051eb:	ba fc 03 00 00       	mov    $0x3fc,%edx
801051f0:	89 c8                	mov    %ecx,%eax
801051f2:	ee                   	out    %al,(%dx)
801051f3:	b8 01 00 00 00       	mov    $0x1,%eax
801051f8:	89 da                	mov    %ebx,%edx
801051fa:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801051fb:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105200:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
80105201:	3c ff                	cmp    $0xff,%al
80105203:	74 45                	je     8010524a <uartinit+0x9b>
  uart = 1;
80105205:	c7 05 bc 95 10 80 01 	movl   $0x1,0x801095bc
8010520c:	00 00 00 
8010520f:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105214:	ec                   	in     (%dx),%al
80105215:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010521a:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
8010521b:	83 ec 08             	sub    $0x8,%esp
8010521e:	6a 00                	push   $0x0
80105220:	6a 04                	push   $0x4
80105222:	e8 57 cd ff ff       	call   80101f7e <ioapicenable>
  for(p="xv6...\n"; *p; p++)
80105227:	83 c4 10             	add    $0x10,%esp
8010522a:	bb 64 6e 10 80       	mov    $0x80106e64,%ebx
8010522f:	eb 12                	jmp    80105243 <uartinit+0x94>
    uartputc(*p);
80105231:	83 ec 0c             	sub    $0xc,%esp
80105234:	0f be c0             	movsbl %al,%eax
80105237:	50                   	push   %eax
80105238:	e8 2c ff ff ff       	call   80105169 <uartputc>
  for(p="xv6...\n"; *p; p++)
8010523d:	83 c3 01             	add    $0x1,%ebx
80105240:	83 c4 10             	add    $0x10,%esp
80105243:	0f b6 03             	movzbl (%ebx),%eax
80105246:	84 c0                	test   %al,%al
80105248:	75 e7                	jne    80105231 <uartinit+0x82>
}
8010524a:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010524d:	5b                   	pop    %ebx
8010524e:	5e                   	pop    %esi
8010524f:	5d                   	pop    %ebp
80105250:	c3                   	ret    

80105251 <uartintr>:

void
uartintr(void)
{
80105251:	55                   	push   %ebp
80105252:	89 e5                	mov    %esp,%ebp
80105254:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
80105257:	68 3a 51 10 80       	push   $0x8010513a
8010525c:	e8 dd b4 ff ff       	call   8010073e <consoleintr>
}
80105261:	83 c4 10             	add    $0x10,%esp
80105264:	c9                   	leave  
80105265:	c3                   	ret    

80105266 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80105266:	6a 00                	push   $0x0
  pushl $0
80105268:	6a 00                	push   $0x0
  jmp alltraps
8010526a:	e9 be fb ff ff       	jmp    80104e2d <alltraps>

8010526f <vector1>:
.globl vector1
vector1:
  pushl $0
8010526f:	6a 00                	push   $0x0
  pushl $1
80105271:	6a 01                	push   $0x1
  jmp alltraps
80105273:	e9 b5 fb ff ff       	jmp    80104e2d <alltraps>

80105278 <vector2>:
.globl vector2
vector2:
  pushl $0
80105278:	6a 00                	push   $0x0
  pushl $2
8010527a:	6a 02                	push   $0x2
  jmp alltraps
8010527c:	e9 ac fb ff ff       	jmp    80104e2d <alltraps>

80105281 <vector3>:
.globl vector3
vector3:
  pushl $0
80105281:	6a 00                	push   $0x0
  pushl $3
80105283:	6a 03                	push   $0x3
  jmp alltraps
80105285:	e9 a3 fb ff ff       	jmp    80104e2d <alltraps>

8010528a <vector4>:
.globl vector4
vector4:
  pushl $0
8010528a:	6a 00                	push   $0x0
  pushl $4
8010528c:	6a 04                	push   $0x4
  jmp alltraps
8010528e:	e9 9a fb ff ff       	jmp    80104e2d <alltraps>

80105293 <vector5>:
.globl vector5
vector5:
  pushl $0
80105293:	6a 00                	push   $0x0
  pushl $5
80105295:	6a 05                	push   $0x5
  jmp alltraps
80105297:	e9 91 fb ff ff       	jmp    80104e2d <alltraps>

8010529c <vector6>:
.globl vector6
vector6:
  pushl $0
8010529c:	6a 00                	push   $0x0
  pushl $6
8010529e:	6a 06                	push   $0x6
  jmp alltraps
801052a0:	e9 88 fb ff ff       	jmp    80104e2d <alltraps>

801052a5 <vector7>:
.globl vector7
vector7:
  pushl $0
801052a5:	6a 00                	push   $0x0
  pushl $7
801052a7:	6a 07                	push   $0x7
  jmp alltraps
801052a9:	e9 7f fb ff ff       	jmp    80104e2d <alltraps>

801052ae <vector8>:
.globl vector8
vector8:
  pushl $8
801052ae:	6a 08                	push   $0x8
  jmp alltraps
801052b0:	e9 78 fb ff ff       	jmp    80104e2d <alltraps>

801052b5 <vector9>:
.globl vector9
vector9:
  pushl $0
801052b5:	6a 00                	push   $0x0
  pushl $9
801052b7:	6a 09                	push   $0x9
  jmp alltraps
801052b9:	e9 6f fb ff ff       	jmp    80104e2d <alltraps>

801052be <vector10>:
.globl vector10
vector10:
  pushl $10
801052be:	6a 0a                	push   $0xa
  jmp alltraps
801052c0:	e9 68 fb ff ff       	jmp    80104e2d <alltraps>

801052c5 <vector11>:
.globl vector11
vector11:
  pushl $11
801052c5:	6a 0b                	push   $0xb
  jmp alltraps
801052c7:	e9 61 fb ff ff       	jmp    80104e2d <alltraps>

801052cc <vector12>:
.globl vector12
vector12:
  pushl $12
801052cc:	6a 0c                	push   $0xc
  jmp alltraps
801052ce:	e9 5a fb ff ff       	jmp    80104e2d <alltraps>

801052d3 <vector13>:
.globl vector13
vector13:
  pushl $13
801052d3:	6a 0d                	push   $0xd
  jmp alltraps
801052d5:	e9 53 fb ff ff       	jmp    80104e2d <alltraps>

801052da <vector14>:
.globl vector14
vector14:
  pushl $14
801052da:	6a 0e                	push   $0xe
  jmp alltraps
801052dc:	e9 4c fb ff ff       	jmp    80104e2d <alltraps>

801052e1 <vector15>:
.globl vector15
vector15:
  pushl $0
801052e1:	6a 00                	push   $0x0
  pushl $15
801052e3:	6a 0f                	push   $0xf
  jmp alltraps
801052e5:	e9 43 fb ff ff       	jmp    80104e2d <alltraps>

801052ea <vector16>:
.globl vector16
vector16:
  pushl $0
801052ea:	6a 00                	push   $0x0
  pushl $16
801052ec:	6a 10                	push   $0x10
  jmp alltraps
801052ee:	e9 3a fb ff ff       	jmp    80104e2d <alltraps>

801052f3 <vector17>:
.globl vector17
vector17:
  pushl $17
801052f3:	6a 11                	push   $0x11
  jmp alltraps
801052f5:	e9 33 fb ff ff       	jmp    80104e2d <alltraps>

801052fa <vector18>:
.globl vector18
vector18:
  pushl $0
801052fa:	6a 00                	push   $0x0
  pushl $18
801052fc:	6a 12                	push   $0x12
  jmp alltraps
801052fe:	e9 2a fb ff ff       	jmp    80104e2d <alltraps>

80105303 <vector19>:
.globl vector19
vector19:
  pushl $0
80105303:	6a 00                	push   $0x0
  pushl $19
80105305:	6a 13                	push   $0x13
  jmp alltraps
80105307:	e9 21 fb ff ff       	jmp    80104e2d <alltraps>

8010530c <vector20>:
.globl vector20
vector20:
  pushl $0
8010530c:	6a 00                	push   $0x0
  pushl $20
8010530e:	6a 14                	push   $0x14
  jmp alltraps
80105310:	e9 18 fb ff ff       	jmp    80104e2d <alltraps>

80105315 <vector21>:
.globl vector21
vector21:
  pushl $0
80105315:	6a 00                	push   $0x0
  pushl $21
80105317:	6a 15                	push   $0x15
  jmp alltraps
80105319:	e9 0f fb ff ff       	jmp    80104e2d <alltraps>

8010531e <vector22>:
.globl vector22
vector22:
  pushl $0
8010531e:	6a 00                	push   $0x0
  pushl $22
80105320:	6a 16                	push   $0x16
  jmp alltraps
80105322:	e9 06 fb ff ff       	jmp    80104e2d <alltraps>

80105327 <vector23>:
.globl vector23
vector23:
  pushl $0
80105327:	6a 00                	push   $0x0
  pushl $23
80105329:	6a 17                	push   $0x17
  jmp alltraps
8010532b:	e9 fd fa ff ff       	jmp    80104e2d <alltraps>

80105330 <vector24>:
.globl vector24
vector24:
  pushl $0
80105330:	6a 00                	push   $0x0
  pushl $24
80105332:	6a 18                	push   $0x18
  jmp alltraps
80105334:	e9 f4 fa ff ff       	jmp    80104e2d <alltraps>

80105339 <vector25>:
.globl vector25
vector25:
  pushl $0
80105339:	6a 00                	push   $0x0
  pushl $25
8010533b:	6a 19                	push   $0x19
  jmp alltraps
8010533d:	e9 eb fa ff ff       	jmp    80104e2d <alltraps>

80105342 <vector26>:
.globl vector26
vector26:
  pushl $0
80105342:	6a 00                	push   $0x0
  pushl $26
80105344:	6a 1a                	push   $0x1a
  jmp alltraps
80105346:	e9 e2 fa ff ff       	jmp    80104e2d <alltraps>

8010534b <vector27>:
.globl vector27
vector27:
  pushl $0
8010534b:	6a 00                	push   $0x0
  pushl $27
8010534d:	6a 1b                	push   $0x1b
  jmp alltraps
8010534f:	e9 d9 fa ff ff       	jmp    80104e2d <alltraps>

80105354 <vector28>:
.globl vector28
vector28:
  pushl $0
80105354:	6a 00                	push   $0x0
  pushl $28
80105356:	6a 1c                	push   $0x1c
  jmp alltraps
80105358:	e9 d0 fa ff ff       	jmp    80104e2d <alltraps>

8010535d <vector29>:
.globl vector29
vector29:
  pushl $0
8010535d:	6a 00                	push   $0x0
  pushl $29
8010535f:	6a 1d                	push   $0x1d
  jmp alltraps
80105361:	e9 c7 fa ff ff       	jmp    80104e2d <alltraps>

80105366 <vector30>:
.globl vector30
vector30:
  pushl $0
80105366:	6a 00                	push   $0x0
  pushl $30
80105368:	6a 1e                	push   $0x1e
  jmp alltraps
8010536a:	e9 be fa ff ff       	jmp    80104e2d <alltraps>

8010536f <vector31>:
.globl vector31
vector31:
  pushl $0
8010536f:	6a 00                	push   $0x0
  pushl $31
80105371:	6a 1f                	push   $0x1f
  jmp alltraps
80105373:	e9 b5 fa ff ff       	jmp    80104e2d <alltraps>

80105378 <vector32>:
.globl vector32
vector32:
  pushl $0
80105378:	6a 00                	push   $0x0
  pushl $32
8010537a:	6a 20                	push   $0x20
  jmp alltraps
8010537c:	e9 ac fa ff ff       	jmp    80104e2d <alltraps>

80105381 <vector33>:
.globl vector33
vector33:
  pushl $0
80105381:	6a 00                	push   $0x0
  pushl $33
80105383:	6a 21                	push   $0x21
  jmp alltraps
80105385:	e9 a3 fa ff ff       	jmp    80104e2d <alltraps>

8010538a <vector34>:
.globl vector34
vector34:
  pushl $0
8010538a:	6a 00                	push   $0x0
  pushl $34
8010538c:	6a 22                	push   $0x22
  jmp alltraps
8010538e:	e9 9a fa ff ff       	jmp    80104e2d <alltraps>

80105393 <vector35>:
.globl vector35
vector35:
  pushl $0
80105393:	6a 00                	push   $0x0
  pushl $35
80105395:	6a 23                	push   $0x23
  jmp alltraps
80105397:	e9 91 fa ff ff       	jmp    80104e2d <alltraps>

8010539c <vector36>:
.globl vector36
vector36:
  pushl $0
8010539c:	6a 00                	push   $0x0
  pushl $36
8010539e:	6a 24                	push   $0x24
  jmp alltraps
801053a0:	e9 88 fa ff ff       	jmp    80104e2d <alltraps>

801053a5 <vector37>:
.globl vector37
vector37:
  pushl $0
801053a5:	6a 00                	push   $0x0
  pushl $37
801053a7:	6a 25                	push   $0x25
  jmp alltraps
801053a9:	e9 7f fa ff ff       	jmp    80104e2d <alltraps>

801053ae <vector38>:
.globl vector38
vector38:
  pushl $0
801053ae:	6a 00                	push   $0x0
  pushl $38
801053b0:	6a 26                	push   $0x26
  jmp alltraps
801053b2:	e9 76 fa ff ff       	jmp    80104e2d <alltraps>

801053b7 <vector39>:
.globl vector39
vector39:
  pushl $0
801053b7:	6a 00                	push   $0x0
  pushl $39
801053b9:	6a 27                	push   $0x27
  jmp alltraps
801053bb:	e9 6d fa ff ff       	jmp    80104e2d <alltraps>

801053c0 <vector40>:
.globl vector40
vector40:
  pushl $0
801053c0:	6a 00                	push   $0x0
  pushl $40
801053c2:	6a 28                	push   $0x28
  jmp alltraps
801053c4:	e9 64 fa ff ff       	jmp    80104e2d <alltraps>

801053c9 <vector41>:
.globl vector41
vector41:
  pushl $0
801053c9:	6a 00                	push   $0x0
  pushl $41
801053cb:	6a 29                	push   $0x29
  jmp alltraps
801053cd:	e9 5b fa ff ff       	jmp    80104e2d <alltraps>

801053d2 <vector42>:
.globl vector42
vector42:
  pushl $0
801053d2:	6a 00                	push   $0x0
  pushl $42
801053d4:	6a 2a                	push   $0x2a
  jmp alltraps
801053d6:	e9 52 fa ff ff       	jmp    80104e2d <alltraps>

801053db <vector43>:
.globl vector43
vector43:
  pushl $0
801053db:	6a 00                	push   $0x0
  pushl $43
801053dd:	6a 2b                	push   $0x2b
  jmp alltraps
801053df:	e9 49 fa ff ff       	jmp    80104e2d <alltraps>

801053e4 <vector44>:
.globl vector44
vector44:
  pushl $0
801053e4:	6a 00                	push   $0x0
  pushl $44
801053e6:	6a 2c                	push   $0x2c
  jmp alltraps
801053e8:	e9 40 fa ff ff       	jmp    80104e2d <alltraps>

801053ed <vector45>:
.globl vector45
vector45:
  pushl $0
801053ed:	6a 00                	push   $0x0
  pushl $45
801053ef:	6a 2d                	push   $0x2d
  jmp alltraps
801053f1:	e9 37 fa ff ff       	jmp    80104e2d <alltraps>

801053f6 <vector46>:
.globl vector46
vector46:
  pushl $0
801053f6:	6a 00                	push   $0x0
  pushl $46
801053f8:	6a 2e                	push   $0x2e
  jmp alltraps
801053fa:	e9 2e fa ff ff       	jmp    80104e2d <alltraps>

801053ff <vector47>:
.globl vector47
vector47:
  pushl $0
801053ff:	6a 00                	push   $0x0
  pushl $47
80105401:	6a 2f                	push   $0x2f
  jmp alltraps
80105403:	e9 25 fa ff ff       	jmp    80104e2d <alltraps>

80105408 <vector48>:
.globl vector48
vector48:
  pushl $0
80105408:	6a 00                	push   $0x0
  pushl $48
8010540a:	6a 30                	push   $0x30
  jmp alltraps
8010540c:	e9 1c fa ff ff       	jmp    80104e2d <alltraps>

80105411 <vector49>:
.globl vector49
vector49:
  pushl $0
80105411:	6a 00                	push   $0x0
  pushl $49
80105413:	6a 31                	push   $0x31
  jmp alltraps
80105415:	e9 13 fa ff ff       	jmp    80104e2d <alltraps>

8010541a <vector50>:
.globl vector50
vector50:
  pushl $0
8010541a:	6a 00                	push   $0x0
  pushl $50
8010541c:	6a 32                	push   $0x32
  jmp alltraps
8010541e:	e9 0a fa ff ff       	jmp    80104e2d <alltraps>

80105423 <vector51>:
.globl vector51
vector51:
  pushl $0
80105423:	6a 00                	push   $0x0
  pushl $51
80105425:	6a 33                	push   $0x33
  jmp alltraps
80105427:	e9 01 fa ff ff       	jmp    80104e2d <alltraps>

8010542c <vector52>:
.globl vector52
vector52:
  pushl $0
8010542c:	6a 00                	push   $0x0
  pushl $52
8010542e:	6a 34                	push   $0x34
  jmp alltraps
80105430:	e9 f8 f9 ff ff       	jmp    80104e2d <alltraps>

80105435 <vector53>:
.globl vector53
vector53:
  pushl $0
80105435:	6a 00                	push   $0x0
  pushl $53
80105437:	6a 35                	push   $0x35
  jmp alltraps
80105439:	e9 ef f9 ff ff       	jmp    80104e2d <alltraps>

8010543e <vector54>:
.globl vector54
vector54:
  pushl $0
8010543e:	6a 00                	push   $0x0
  pushl $54
80105440:	6a 36                	push   $0x36
  jmp alltraps
80105442:	e9 e6 f9 ff ff       	jmp    80104e2d <alltraps>

80105447 <vector55>:
.globl vector55
vector55:
  pushl $0
80105447:	6a 00                	push   $0x0
  pushl $55
80105449:	6a 37                	push   $0x37
  jmp alltraps
8010544b:	e9 dd f9 ff ff       	jmp    80104e2d <alltraps>

80105450 <vector56>:
.globl vector56
vector56:
  pushl $0
80105450:	6a 00                	push   $0x0
  pushl $56
80105452:	6a 38                	push   $0x38
  jmp alltraps
80105454:	e9 d4 f9 ff ff       	jmp    80104e2d <alltraps>

80105459 <vector57>:
.globl vector57
vector57:
  pushl $0
80105459:	6a 00                	push   $0x0
  pushl $57
8010545b:	6a 39                	push   $0x39
  jmp alltraps
8010545d:	e9 cb f9 ff ff       	jmp    80104e2d <alltraps>

80105462 <vector58>:
.globl vector58
vector58:
  pushl $0
80105462:	6a 00                	push   $0x0
  pushl $58
80105464:	6a 3a                	push   $0x3a
  jmp alltraps
80105466:	e9 c2 f9 ff ff       	jmp    80104e2d <alltraps>

8010546b <vector59>:
.globl vector59
vector59:
  pushl $0
8010546b:	6a 00                	push   $0x0
  pushl $59
8010546d:	6a 3b                	push   $0x3b
  jmp alltraps
8010546f:	e9 b9 f9 ff ff       	jmp    80104e2d <alltraps>

80105474 <vector60>:
.globl vector60
vector60:
  pushl $0
80105474:	6a 00                	push   $0x0
  pushl $60
80105476:	6a 3c                	push   $0x3c
  jmp alltraps
80105478:	e9 b0 f9 ff ff       	jmp    80104e2d <alltraps>

8010547d <vector61>:
.globl vector61
vector61:
  pushl $0
8010547d:	6a 00                	push   $0x0
  pushl $61
8010547f:	6a 3d                	push   $0x3d
  jmp alltraps
80105481:	e9 a7 f9 ff ff       	jmp    80104e2d <alltraps>

80105486 <vector62>:
.globl vector62
vector62:
  pushl $0
80105486:	6a 00                	push   $0x0
  pushl $62
80105488:	6a 3e                	push   $0x3e
  jmp alltraps
8010548a:	e9 9e f9 ff ff       	jmp    80104e2d <alltraps>

8010548f <vector63>:
.globl vector63
vector63:
  pushl $0
8010548f:	6a 00                	push   $0x0
  pushl $63
80105491:	6a 3f                	push   $0x3f
  jmp alltraps
80105493:	e9 95 f9 ff ff       	jmp    80104e2d <alltraps>

80105498 <vector64>:
.globl vector64
vector64:
  pushl $0
80105498:	6a 00                	push   $0x0
  pushl $64
8010549a:	6a 40                	push   $0x40
  jmp alltraps
8010549c:	e9 8c f9 ff ff       	jmp    80104e2d <alltraps>

801054a1 <vector65>:
.globl vector65
vector65:
  pushl $0
801054a1:	6a 00                	push   $0x0
  pushl $65
801054a3:	6a 41                	push   $0x41
  jmp alltraps
801054a5:	e9 83 f9 ff ff       	jmp    80104e2d <alltraps>

801054aa <vector66>:
.globl vector66
vector66:
  pushl $0
801054aa:	6a 00                	push   $0x0
  pushl $66
801054ac:	6a 42                	push   $0x42
  jmp alltraps
801054ae:	e9 7a f9 ff ff       	jmp    80104e2d <alltraps>

801054b3 <vector67>:
.globl vector67
vector67:
  pushl $0
801054b3:	6a 00                	push   $0x0
  pushl $67
801054b5:	6a 43                	push   $0x43
  jmp alltraps
801054b7:	e9 71 f9 ff ff       	jmp    80104e2d <alltraps>

801054bc <vector68>:
.globl vector68
vector68:
  pushl $0
801054bc:	6a 00                	push   $0x0
  pushl $68
801054be:	6a 44                	push   $0x44
  jmp alltraps
801054c0:	e9 68 f9 ff ff       	jmp    80104e2d <alltraps>

801054c5 <vector69>:
.globl vector69
vector69:
  pushl $0
801054c5:	6a 00                	push   $0x0
  pushl $69
801054c7:	6a 45                	push   $0x45
  jmp alltraps
801054c9:	e9 5f f9 ff ff       	jmp    80104e2d <alltraps>

801054ce <vector70>:
.globl vector70
vector70:
  pushl $0
801054ce:	6a 00                	push   $0x0
  pushl $70
801054d0:	6a 46                	push   $0x46
  jmp alltraps
801054d2:	e9 56 f9 ff ff       	jmp    80104e2d <alltraps>

801054d7 <vector71>:
.globl vector71
vector71:
  pushl $0
801054d7:	6a 00                	push   $0x0
  pushl $71
801054d9:	6a 47                	push   $0x47
  jmp alltraps
801054db:	e9 4d f9 ff ff       	jmp    80104e2d <alltraps>

801054e0 <vector72>:
.globl vector72
vector72:
  pushl $0
801054e0:	6a 00                	push   $0x0
  pushl $72
801054e2:	6a 48                	push   $0x48
  jmp alltraps
801054e4:	e9 44 f9 ff ff       	jmp    80104e2d <alltraps>

801054e9 <vector73>:
.globl vector73
vector73:
  pushl $0
801054e9:	6a 00                	push   $0x0
  pushl $73
801054eb:	6a 49                	push   $0x49
  jmp alltraps
801054ed:	e9 3b f9 ff ff       	jmp    80104e2d <alltraps>

801054f2 <vector74>:
.globl vector74
vector74:
  pushl $0
801054f2:	6a 00                	push   $0x0
  pushl $74
801054f4:	6a 4a                	push   $0x4a
  jmp alltraps
801054f6:	e9 32 f9 ff ff       	jmp    80104e2d <alltraps>

801054fb <vector75>:
.globl vector75
vector75:
  pushl $0
801054fb:	6a 00                	push   $0x0
  pushl $75
801054fd:	6a 4b                	push   $0x4b
  jmp alltraps
801054ff:	e9 29 f9 ff ff       	jmp    80104e2d <alltraps>

80105504 <vector76>:
.globl vector76
vector76:
  pushl $0
80105504:	6a 00                	push   $0x0
  pushl $76
80105506:	6a 4c                	push   $0x4c
  jmp alltraps
80105508:	e9 20 f9 ff ff       	jmp    80104e2d <alltraps>

8010550d <vector77>:
.globl vector77
vector77:
  pushl $0
8010550d:	6a 00                	push   $0x0
  pushl $77
8010550f:	6a 4d                	push   $0x4d
  jmp alltraps
80105511:	e9 17 f9 ff ff       	jmp    80104e2d <alltraps>

80105516 <vector78>:
.globl vector78
vector78:
  pushl $0
80105516:	6a 00                	push   $0x0
  pushl $78
80105518:	6a 4e                	push   $0x4e
  jmp alltraps
8010551a:	e9 0e f9 ff ff       	jmp    80104e2d <alltraps>

8010551f <vector79>:
.globl vector79
vector79:
  pushl $0
8010551f:	6a 00                	push   $0x0
  pushl $79
80105521:	6a 4f                	push   $0x4f
  jmp alltraps
80105523:	e9 05 f9 ff ff       	jmp    80104e2d <alltraps>

80105528 <vector80>:
.globl vector80
vector80:
  pushl $0
80105528:	6a 00                	push   $0x0
  pushl $80
8010552a:	6a 50                	push   $0x50
  jmp alltraps
8010552c:	e9 fc f8 ff ff       	jmp    80104e2d <alltraps>

80105531 <vector81>:
.globl vector81
vector81:
  pushl $0
80105531:	6a 00                	push   $0x0
  pushl $81
80105533:	6a 51                	push   $0x51
  jmp alltraps
80105535:	e9 f3 f8 ff ff       	jmp    80104e2d <alltraps>

8010553a <vector82>:
.globl vector82
vector82:
  pushl $0
8010553a:	6a 00                	push   $0x0
  pushl $82
8010553c:	6a 52                	push   $0x52
  jmp alltraps
8010553e:	e9 ea f8 ff ff       	jmp    80104e2d <alltraps>

80105543 <vector83>:
.globl vector83
vector83:
  pushl $0
80105543:	6a 00                	push   $0x0
  pushl $83
80105545:	6a 53                	push   $0x53
  jmp alltraps
80105547:	e9 e1 f8 ff ff       	jmp    80104e2d <alltraps>

8010554c <vector84>:
.globl vector84
vector84:
  pushl $0
8010554c:	6a 00                	push   $0x0
  pushl $84
8010554e:	6a 54                	push   $0x54
  jmp alltraps
80105550:	e9 d8 f8 ff ff       	jmp    80104e2d <alltraps>

80105555 <vector85>:
.globl vector85
vector85:
  pushl $0
80105555:	6a 00                	push   $0x0
  pushl $85
80105557:	6a 55                	push   $0x55
  jmp alltraps
80105559:	e9 cf f8 ff ff       	jmp    80104e2d <alltraps>

8010555e <vector86>:
.globl vector86
vector86:
  pushl $0
8010555e:	6a 00                	push   $0x0
  pushl $86
80105560:	6a 56                	push   $0x56
  jmp alltraps
80105562:	e9 c6 f8 ff ff       	jmp    80104e2d <alltraps>

80105567 <vector87>:
.globl vector87
vector87:
  pushl $0
80105567:	6a 00                	push   $0x0
  pushl $87
80105569:	6a 57                	push   $0x57
  jmp alltraps
8010556b:	e9 bd f8 ff ff       	jmp    80104e2d <alltraps>

80105570 <vector88>:
.globl vector88
vector88:
  pushl $0
80105570:	6a 00                	push   $0x0
  pushl $88
80105572:	6a 58                	push   $0x58
  jmp alltraps
80105574:	e9 b4 f8 ff ff       	jmp    80104e2d <alltraps>

80105579 <vector89>:
.globl vector89
vector89:
  pushl $0
80105579:	6a 00                	push   $0x0
  pushl $89
8010557b:	6a 59                	push   $0x59
  jmp alltraps
8010557d:	e9 ab f8 ff ff       	jmp    80104e2d <alltraps>

80105582 <vector90>:
.globl vector90
vector90:
  pushl $0
80105582:	6a 00                	push   $0x0
  pushl $90
80105584:	6a 5a                	push   $0x5a
  jmp alltraps
80105586:	e9 a2 f8 ff ff       	jmp    80104e2d <alltraps>

8010558b <vector91>:
.globl vector91
vector91:
  pushl $0
8010558b:	6a 00                	push   $0x0
  pushl $91
8010558d:	6a 5b                	push   $0x5b
  jmp alltraps
8010558f:	e9 99 f8 ff ff       	jmp    80104e2d <alltraps>

80105594 <vector92>:
.globl vector92
vector92:
  pushl $0
80105594:	6a 00                	push   $0x0
  pushl $92
80105596:	6a 5c                	push   $0x5c
  jmp alltraps
80105598:	e9 90 f8 ff ff       	jmp    80104e2d <alltraps>

8010559d <vector93>:
.globl vector93
vector93:
  pushl $0
8010559d:	6a 00                	push   $0x0
  pushl $93
8010559f:	6a 5d                	push   $0x5d
  jmp alltraps
801055a1:	e9 87 f8 ff ff       	jmp    80104e2d <alltraps>

801055a6 <vector94>:
.globl vector94
vector94:
  pushl $0
801055a6:	6a 00                	push   $0x0
  pushl $94
801055a8:	6a 5e                	push   $0x5e
  jmp alltraps
801055aa:	e9 7e f8 ff ff       	jmp    80104e2d <alltraps>

801055af <vector95>:
.globl vector95
vector95:
  pushl $0
801055af:	6a 00                	push   $0x0
  pushl $95
801055b1:	6a 5f                	push   $0x5f
  jmp alltraps
801055b3:	e9 75 f8 ff ff       	jmp    80104e2d <alltraps>

801055b8 <vector96>:
.globl vector96
vector96:
  pushl $0
801055b8:	6a 00                	push   $0x0
  pushl $96
801055ba:	6a 60                	push   $0x60
  jmp alltraps
801055bc:	e9 6c f8 ff ff       	jmp    80104e2d <alltraps>

801055c1 <vector97>:
.globl vector97
vector97:
  pushl $0
801055c1:	6a 00                	push   $0x0
  pushl $97
801055c3:	6a 61                	push   $0x61
  jmp alltraps
801055c5:	e9 63 f8 ff ff       	jmp    80104e2d <alltraps>

801055ca <vector98>:
.globl vector98
vector98:
  pushl $0
801055ca:	6a 00                	push   $0x0
  pushl $98
801055cc:	6a 62                	push   $0x62
  jmp alltraps
801055ce:	e9 5a f8 ff ff       	jmp    80104e2d <alltraps>

801055d3 <vector99>:
.globl vector99
vector99:
  pushl $0
801055d3:	6a 00                	push   $0x0
  pushl $99
801055d5:	6a 63                	push   $0x63
  jmp alltraps
801055d7:	e9 51 f8 ff ff       	jmp    80104e2d <alltraps>

801055dc <vector100>:
.globl vector100
vector100:
  pushl $0
801055dc:	6a 00                	push   $0x0
  pushl $100
801055de:	6a 64                	push   $0x64
  jmp alltraps
801055e0:	e9 48 f8 ff ff       	jmp    80104e2d <alltraps>

801055e5 <vector101>:
.globl vector101
vector101:
  pushl $0
801055e5:	6a 00                	push   $0x0
  pushl $101
801055e7:	6a 65                	push   $0x65
  jmp alltraps
801055e9:	e9 3f f8 ff ff       	jmp    80104e2d <alltraps>

801055ee <vector102>:
.globl vector102
vector102:
  pushl $0
801055ee:	6a 00                	push   $0x0
  pushl $102
801055f0:	6a 66                	push   $0x66
  jmp alltraps
801055f2:	e9 36 f8 ff ff       	jmp    80104e2d <alltraps>

801055f7 <vector103>:
.globl vector103
vector103:
  pushl $0
801055f7:	6a 00                	push   $0x0
  pushl $103
801055f9:	6a 67                	push   $0x67
  jmp alltraps
801055fb:	e9 2d f8 ff ff       	jmp    80104e2d <alltraps>

80105600 <vector104>:
.globl vector104
vector104:
  pushl $0
80105600:	6a 00                	push   $0x0
  pushl $104
80105602:	6a 68                	push   $0x68
  jmp alltraps
80105604:	e9 24 f8 ff ff       	jmp    80104e2d <alltraps>

80105609 <vector105>:
.globl vector105
vector105:
  pushl $0
80105609:	6a 00                	push   $0x0
  pushl $105
8010560b:	6a 69                	push   $0x69
  jmp alltraps
8010560d:	e9 1b f8 ff ff       	jmp    80104e2d <alltraps>

80105612 <vector106>:
.globl vector106
vector106:
  pushl $0
80105612:	6a 00                	push   $0x0
  pushl $106
80105614:	6a 6a                	push   $0x6a
  jmp alltraps
80105616:	e9 12 f8 ff ff       	jmp    80104e2d <alltraps>

8010561b <vector107>:
.globl vector107
vector107:
  pushl $0
8010561b:	6a 00                	push   $0x0
  pushl $107
8010561d:	6a 6b                	push   $0x6b
  jmp alltraps
8010561f:	e9 09 f8 ff ff       	jmp    80104e2d <alltraps>

80105624 <vector108>:
.globl vector108
vector108:
  pushl $0
80105624:	6a 00                	push   $0x0
  pushl $108
80105626:	6a 6c                	push   $0x6c
  jmp alltraps
80105628:	e9 00 f8 ff ff       	jmp    80104e2d <alltraps>

8010562d <vector109>:
.globl vector109
vector109:
  pushl $0
8010562d:	6a 00                	push   $0x0
  pushl $109
8010562f:	6a 6d                	push   $0x6d
  jmp alltraps
80105631:	e9 f7 f7 ff ff       	jmp    80104e2d <alltraps>

80105636 <vector110>:
.globl vector110
vector110:
  pushl $0
80105636:	6a 00                	push   $0x0
  pushl $110
80105638:	6a 6e                	push   $0x6e
  jmp alltraps
8010563a:	e9 ee f7 ff ff       	jmp    80104e2d <alltraps>

8010563f <vector111>:
.globl vector111
vector111:
  pushl $0
8010563f:	6a 00                	push   $0x0
  pushl $111
80105641:	6a 6f                	push   $0x6f
  jmp alltraps
80105643:	e9 e5 f7 ff ff       	jmp    80104e2d <alltraps>

80105648 <vector112>:
.globl vector112
vector112:
  pushl $0
80105648:	6a 00                	push   $0x0
  pushl $112
8010564a:	6a 70                	push   $0x70
  jmp alltraps
8010564c:	e9 dc f7 ff ff       	jmp    80104e2d <alltraps>

80105651 <vector113>:
.globl vector113
vector113:
  pushl $0
80105651:	6a 00                	push   $0x0
  pushl $113
80105653:	6a 71                	push   $0x71
  jmp alltraps
80105655:	e9 d3 f7 ff ff       	jmp    80104e2d <alltraps>

8010565a <vector114>:
.globl vector114
vector114:
  pushl $0
8010565a:	6a 00                	push   $0x0
  pushl $114
8010565c:	6a 72                	push   $0x72
  jmp alltraps
8010565e:	e9 ca f7 ff ff       	jmp    80104e2d <alltraps>

80105663 <vector115>:
.globl vector115
vector115:
  pushl $0
80105663:	6a 00                	push   $0x0
  pushl $115
80105665:	6a 73                	push   $0x73
  jmp alltraps
80105667:	e9 c1 f7 ff ff       	jmp    80104e2d <alltraps>

8010566c <vector116>:
.globl vector116
vector116:
  pushl $0
8010566c:	6a 00                	push   $0x0
  pushl $116
8010566e:	6a 74                	push   $0x74
  jmp alltraps
80105670:	e9 b8 f7 ff ff       	jmp    80104e2d <alltraps>

80105675 <vector117>:
.globl vector117
vector117:
  pushl $0
80105675:	6a 00                	push   $0x0
  pushl $117
80105677:	6a 75                	push   $0x75
  jmp alltraps
80105679:	e9 af f7 ff ff       	jmp    80104e2d <alltraps>

8010567e <vector118>:
.globl vector118
vector118:
  pushl $0
8010567e:	6a 00                	push   $0x0
  pushl $118
80105680:	6a 76                	push   $0x76
  jmp alltraps
80105682:	e9 a6 f7 ff ff       	jmp    80104e2d <alltraps>

80105687 <vector119>:
.globl vector119
vector119:
  pushl $0
80105687:	6a 00                	push   $0x0
  pushl $119
80105689:	6a 77                	push   $0x77
  jmp alltraps
8010568b:	e9 9d f7 ff ff       	jmp    80104e2d <alltraps>

80105690 <vector120>:
.globl vector120
vector120:
  pushl $0
80105690:	6a 00                	push   $0x0
  pushl $120
80105692:	6a 78                	push   $0x78
  jmp alltraps
80105694:	e9 94 f7 ff ff       	jmp    80104e2d <alltraps>

80105699 <vector121>:
.globl vector121
vector121:
  pushl $0
80105699:	6a 00                	push   $0x0
  pushl $121
8010569b:	6a 79                	push   $0x79
  jmp alltraps
8010569d:	e9 8b f7 ff ff       	jmp    80104e2d <alltraps>

801056a2 <vector122>:
.globl vector122
vector122:
  pushl $0
801056a2:	6a 00                	push   $0x0
  pushl $122
801056a4:	6a 7a                	push   $0x7a
  jmp alltraps
801056a6:	e9 82 f7 ff ff       	jmp    80104e2d <alltraps>

801056ab <vector123>:
.globl vector123
vector123:
  pushl $0
801056ab:	6a 00                	push   $0x0
  pushl $123
801056ad:	6a 7b                	push   $0x7b
  jmp alltraps
801056af:	e9 79 f7 ff ff       	jmp    80104e2d <alltraps>

801056b4 <vector124>:
.globl vector124
vector124:
  pushl $0
801056b4:	6a 00                	push   $0x0
  pushl $124
801056b6:	6a 7c                	push   $0x7c
  jmp alltraps
801056b8:	e9 70 f7 ff ff       	jmp    80104e2d <alltraps>

801056bd <vector125>:
.globl vector125
vector125:
  pushl $0
801056bd:	6a 00                	push   $0x0
  pushl $125
801056bf:	6a 7d                	push   $0x7d
  jmp alltraps
801056c1:	e9 67 f7 ff ff       	jmp    80104e2d <alltraps>

801056c6 <vector126>:
.globl vector126
vector126:
  pushl $0
801056c6:	6a 00                	push   $0x0
  pushl $126
801056c8:	6a 7e                	push   $0x7e
  jmp alltraps
801056ca:	e9 5e f7 ff ff       	jmp    80104e2d <alltraps>

801056cf <vector127>:
.globl vector127
vector127:
  pushl $0
801056cf:	6a 00                	push   $0x0
  pushl $127
801056d1:	6a 7f                	push   $0x7f
  jmp alltraps
801056d3:	e9 55 f7 ff ff       	jmp    80104e2d <alltraps>

801056d8 <vector128>:
.globl vector128
vector128:
  pushl $0
801056d8:	6a 00                	push   $0x0
  pushl $128
801056da:	68 80 00 00 00       	push   $0x80
  jmp alltraps
801056df:	e9 49 f7 ff ff       	jmp    80104e2d <alltraps>

801056e4 <vector129>:
.globl vector129
vector129:
  pushl $0
801056e4:	6a 00                	push   $0x0
  pushl $129
801056e6:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801056eb:	e9 3d f7 ff ff       	jmp    80104e2d <alltraps>

801056f0 <vector130>:
.globl vector130
vector130:
  pushl $0
801056f0:	6a 00                	push   $0x0
  pushl $130
801056f2:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801056f7:	e9 31 f7 ff ff       	jmp    80104e2d <alltraps>

801056fc <vector131>:
.globl vector131
vector131:
  pushl $0
801056fc:	6a 00                	push   $0x0
  pushl $131
801056fe:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80105703:	e9 25 f7 ff ff       	jmp    80104e2d <alltraps>

80105708 <vector132>:
.globl vector132
vector132:
  pushl $0
80105708:	6a 00                	push   $0x0
  pushl $132
8010570a:	68 84 00 00 00       	push   $0x84
  jmp alltraps
8010570f:	e9 19 f7 ff ff       	jmp    80104e2d <alltraps>

80105714 <vector133>:
.globl vector133
vector133:
  pushl $0
80105714:	6a 00                	push   $0x0
  pushl $133
80105716:	68 85 00 00 00       	push   $0x85
  jmp alltraps
8010571b:	e9 0d f7 ff ff       	jmp    80104e2d <alltraps>

80105720 <vector134>:
.globl vector134
vector134:
  pushl $0
80105720:	6a 00                	push   $0x0
  pushl $134
80105722:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80105727:	e9 01 f7 ff ff       	jmp    80104e2d <alltraps>

8010572c <vector135>:
.globl vector135
vector135:
  pushl $0
8010572c:	6a 00                	push   $0x0
  pushl $135
8010572e:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80105733:	e9 f5 f6 ff ff       	jmp    80104e2d <alltraps>

80105738 <vector136>:
.globl vector136
vector136:
  pushl $0
80105738:	6a 00                	push   $0x0
  pushl $136
8010573a:	68 88 00 00 00       	push   $0x88
  jmp alltraps
8010573f:	e9 e9 f6 ff ff       	jmp    80104e2d <alltraps>

80105744 <vector137>:
.globl vector137
vector137:
  pushl $0
80105744:	6a 00                	push   $0x0
  pushl $137
80105746:	68 89 00 00 00       	push   $0x89
  jmp alltraps
8010574b:	e9 dd f6 ff ff       	jmp    80104e2d <alltraps>

80105750 <vector138>:
.globl vector138
vector138:
  pushl $0
80105750:	6a 00                	push   $0x0
  pushl $138
80105752:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80105757:	e9 d1 f6 ff ff       	jmp    80104e2d <alltraps>

8010575c <vector139>:
.globl vector139
vector139:
  pushl $0
8010575c:	6a 00                	push   $0x0
  pushl $139
8010575e:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80105763:	e9 c5 f6 ff ff       	jmp    80104e2d <alltraps>

80105768 <vector140>:
.globl vector140
vector140:
  pushl $0
80105768:	6a 00                	push   $0x0
  pushl $140
8010576a:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
8010576f:	e9 b9 f6 ff ff       	jmp    80104e2d <alltraps>

80105774 <vector141>:
.globl vector141
vector141:
  pushl $0
80105774:	6a 00                	push   $0x0
  pushl $141
80105776:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
8010577b:	e9 ad f6 ff ff       	jmp    80104e2d <alltraps>

80105780 <vector142>:
.globl vector142
vector142:
  pushl $0
80105780:	6a 00                	push   $0x0
  pushl $142
80105782:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80105787:	e9 a1 f6 ff ff       	jmp    80104e2d <alltraps>

8010578c <vector143>:
.globl vector143
vector143:
  pushl $0
8010578c:	6a 00                	push   $0x0
  pushl $143
8010578e:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80105793:	e9 95 f6 ff ff       	jmp    80104e2d <alltraps>

80105798 <vector144>:
.globl vector144
vector144:
  pushl $0
80105798:	6a 00                	push   $0x0
  pushl $144
8010579a:	68 90 00 00 00       	push   $0x90
  jmp alltraps
8010579f:	e9 89 f6 ff ff       	jmp    80104e2d <alltraps>

801057a4 <vector145>:
.globl vector145
vector145:
  pushl $0
801057a4:	6a 00                	push   $0x0
  pushl $145
801057a6:	68 91 00 00 00       	push   $0x91
  jmp alltraps
801057ab:	e9 7d f6 ff ff       	jmp    80104e2d <alltraps>

801057b0 <vector146>:
.globl vector146
vector146:
  pushl $0
801057b0:	6a 00                	push   $0x0
  pushl $146
801057b2:	68 92 00 00 00       	push   $0x92
  jmp alltraps
801057b7:	e9 71 f6 ff ff       	jmp    80104e2d <alltraps>

801057bc <vector147>:
.globl vector147
vector147:
  pushl $0
801057bc:	6a 00                	push   $0x0
  pushl $147
801057be:	68 93 00 00 00       	push   $0x93
  jmp alltraps
801057c3:	e9 65 f6 ff ff       	jmp    80104e2d <alltraps>

801057c8 <vector148>:
.globl vector148
vector148:
  pushl $0
801057c8:	6a 00                	push   $0x0
  pushl $148
801057ca:	68 94 00 00 00       	push   $0x94
  jmp alltraps
801057cf:	e9 59 f6 ff ff       	jmp    80104e2d <alltraps>

801057d4 <vector149>:
.globl vector149
vector149:
  pushl $0
801057d4:	6a 00                	push   $0x0
  pushl $149
801057d6:	68 95 00 00 00       	push   $0x95
  jmp alltraps
801057db:	e9 4d f6 ff ff       	jmp    80104e2d <alltraps>

801057e0 <vector150>:
.globl vector150
vector150:
  pushl $0
801057e0:	6a 00                	push   $0x0
  pushl $150
801057e2:	68 96 00 00 00       	push   $0x96
  jmp alltraps
801057e7:	e9 41 f6 ff ff       	jmp    80104e2d <alltraps>

801057ec <vector151>:
.globl vector151
vector151:
  pushl $0
801057ec:	6a 00                	push   $0x0
  pushl $151
801057ee:	68 97 00 00 00       	push   $0x97
  jmp alltraps
801057f3:	e9 35 f6 ff ff       	jmp    80104e2d <alltraps>

801057f8 <vector152>:
.globl vector152
vector152:
  pushl $0
801057f8:	6a 00                	push   $0x0
  pushl $152
801057fa:	68 98 00 00 00       	push   $0x98
  jmp alltraps
801057ff:	e9 29 f6 ff ff       	jmp    80104e2d <alltraps>

80105804 <vector153>:
.globl vector153
vector153:
  pushl $0
80105804:	6a 00                	push   $0x0
  pushl $153
80105806:	68 99 00 00 00       	push   $0x99
  jmp alltraps
8010580b:	e9 1d f6 ff ff       	jmp    80104e2d <alltraps>

80105810 <vector154>:
.globl vector154
vector154:
  pushl $0
80105810:	6a 00                	push   $0x0
  pushl $154
80105812:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80105817:	e9 11 f6 ff ff       	jmp    80104e2d <alltraps>

8010581c <vector155>:
.globl vector155
vector155:
  pushl $0
8010581c:	6a 00                	push   $0x0
  pushl $155
8010581e:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80105823:	e9 05 f6 ff ff       	jmp    80104e2d <alltraps>

80105828 <vector156>:
.globl vector156
vector156:
  pushl $0
80105828:	6a 00                	push   $0x0
  pushl $156
8010582a:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
8010582f:	e9 f9 f5 ff ff       	jmp    80104e2d <alltraps>

80105834 <vector157>:
.globl vector157
vector157:
  pushl $0
80105834:	6a 00                	push   $0x0
  pushl $157
80105836:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
8010583b:	e9 ed f5 ff ff       	jmp    80104e2d <alltraps>

80105840 <vector158>:
.globl vector158
vector158:
  pushl $0
80105840:	6a 00                	push   $0x0
  pushl $158
80105842:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80105847:	e9 e1 f5 ff ff       	jmp    80104e2d <alltraps>

8010584c <vector159>:
.globl vector159
vector159:
  pushl $0
8010584c:	6a 00                	push   $0x0
  pushl $159
8010584e:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80105853:	e9 d5 f5 ff ff       	jmp    80104e2d <alltraps>

80105858 <vector160>:
.globl vector160
vector160:
  pushl $0
80105858:	6a 00                	push   $0x0
  pushl $160
8010585a:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
8010585f:	e9 c9 f5 ff ff       	jmp    80104e2d <alltraps>

80105864 <vector161>:
.globl vector161
vector161:
  pushl $0
80105864:	6a 00                	push   $0x0
  pushl $161
80105866:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
8010586b:	e9 bd f5 ff ff       	jmp    80104e2d <alltraps>

80105870 <vector162>:
.globl vector162
vector162:
  pushl $0
80105870:	6a 00                	push   $0x0
  pushl $162
80105872:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80105877:	e9 b1 f5 ff ff       	jmp    80104e2d <alltraps>

8010587c <vector163>:
.globl vector163
vector163:
  pushl $0
8010587c:	6a 00                	push   $0x0
  pushl $163
8010587e:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80105883:	e9 a5 f5 ff ff       	jmp    80104e2d <alltraps>

80105888 <vector164>:
.globl vector164
vector164:
  pushl $0
80105888:	6a 00                	push   $0x0
  pushl $164
8010588a:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
8010588f:	e9 99 f5 ff ff       	jmp    80104e2d <alltraps>

80105894 <vector165>:
.globl vector165
vector165:
  pushl $0
80105894:	6a 00                	push   $0x0
  pushl $165
80105896:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
8010589b:	e9 8d f5 ff ff       	jmp    80104e2d <alltraps>

801058a0 <vector166>:
.globl vector166
vector166:
  pushl $0
801058a0:	6a 00                	push   $0x0
  pushl $166
801058a2:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
801058a7:	e9 81 f5 ff ff       	jmp    80104e2d <alltraps>

801058ac <vector167>:
.globl vector167
vector167:
  pushl $0
801058ac:	6a 00                	push   $0x0
  pushl $167
801058ae:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
801058b3:	e9 75 f5 ff ff       	jmp    80104e2d <alltraps>

801058b8 <vector168>:
.globl vector168
vector168:
  pushl $0
801058b8:	6a 00                	push   $0x0
  pushl $168
801058ba:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
801058bf:	e9 69 f5 ff ff       	jmp    80104e2d <alltraps>

801058c4 <vector169>:
.globl vector169
vector169:
  pushl $0
801058c4:	6a 00                	push   $0x0
  pushl $169
801058c6:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
801058cb:	e9 5d f5 ff ff       	jmp    80104e2d <alltraps>

801058d0 <vector170>:
.globl vector170
vector170:
  pushl $0
801058d0:	6a 00                	push   $0x0
  pushl $170
801058d2:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
801058d7:	e9 51 f5 ff ff       	jmp    80104e2d <alltraps>

801058dc <vector171>:
.globl vector171
vector171:
  pushl $0
801058dc:	6a 00                	push   $0x0
  pushl $171
801058de:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
801058e3:	e9 45 f5 ff ff       	jmp    80104e2d <alltraps>

801058e8 <vector172>:
.globl vector172
vector172:
  pushl $0
801058e8:	6a 00                	push   $0x0
  pushl $172
801058ea:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
801058ef:	e9 39 f5 ff ff       	jmp    80104e2d <alltraps>

801058f4 <vector173>:
.globl vector173
vector173:
  pushl $0
801058f4:	6a 00                	push   $0x0
  pushl $173
801058f6:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
801058fb:	e9 2d f5 ff ff       	jmp    80104e2d <alltraps>

80105900 <vector174>:
.globl vector174
vector174:
  pushl $0
80105900:	6a 00                	push   $0x0
  pushl $174
80105902:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80105907:	e9 21 f5 ff ff       	jmp    80104e2d <alltraps>

8010590c <vector175>:
.globl vector175
vector175:
  pushl $0
8010590c:	6a 00                	push   $0x0
  pushl $175
8010590e:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80105913:	e9 15 f5 ff ff       	jmp    80104e2d <alltraps>

80105918 <vector176>:
.globl vector176
vector176:
  pushl $0
80105918:	6a 00                	push   $0x0
  pushl $176
8010591a:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
8010591f:	e9 09 f5 ff ff       	jmp    80104e2d <alltraps>

80105924 <vector177>:
.globl vector177
vector177:
  pushl $0
80105924:	6a 00                	push   $0x0
  pushl $177
80105926:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
8010592b:	e9 fd f4 ff ff       	jmp    80104e2d <alltraps>

80105930 <vector178>:
.globl vector178
vector178:
  pushl $0
80105930:	6a 00                	push   $0x0
  pushl $178
80105932:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80105937:	e9 f1 f4 ff ff       	jmp    80104e2d <alltraps>

8010593c <vector179>:
.globl vector179
vector179:
  pushl $0
8010593c:	6a 00                	push   $0x0
  pushl $179
8010593e:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80105943:	e9 e5 f4 ff ff       	jmp    80104e2d <alltraps>

80105948 <vector180>:
.globl vector180
vector180:
  pushl $0
80105948:	6a 00                	push   $0x0
  pushl $180
8010594a:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
8010594f:	e9 d9 f4 ff ff       	jmp    80104e2d <alltraps>

80105954 <vector181>:
.globl vector181
vector181:
  pushl $0
80105954:	6a 00                	push   $0x0
  pushl $181
80105956:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
8010595b:	e9 cd f4 ff ff       	jmp    80104e2d <alltraps>

80105960 <vector182>:
.globl vector182
vector182:
  pushl $0
80105960:	6a 00                	push   $0x0
  pushl $182
80105962:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105967:	e9 c1 f4 ff ff       	jmp    80104e2d <alltraps>

8010596c <vector183>:
.globl vector183
vector183:
  pushl $0
8010596c:	6a 00                	push   $0x0
  pushl $183
8010596e:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105973:	e9 b5 f4 ff ff       	jmp    80104e2d <alltraps>

80105978 <vector184>:
.globl vector184
vector184:
  pushl $0
80105978:	6a 00                	push   $0x0
  pushl $184
8010597a:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
8010597f:	e9 a9 f4 ff ff       	jmp    80104e2d <alltraps>

80105984 <vector185>:
.globl vector185
vector185:
  pushl $0
80105984:	6a 00                	push   $0x0
  pushl $185
80105986:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
8010598b:	e9 9d f4 ff ff       	jmp    80104e2d <alltraps>

80105990 <vector186>:
.globl vector186
vector186:
  pushl $0
80105990:	6a 00                	push   $0x0
  pushl $186
80105992:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105997:	e9 91 f4 ff ff       	jmp    80104e2d <alltraps>

8010599c <vector187>:
.globl vector187
vector187:
  pushl $0
8010599c:	6a 00                	push   $0x0
  pushl $187
8010599e:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
801059a3:	e9 85 f4 ff ff       	jmp    80104e2d <alltraps>

801059a8 <vector188>:
.globl vector188
vector188:
  pushl $0
801059a8:	6a 00                	push   $0x0
  pushl $188
801059aa:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
801059af:	e9 79 f4 ff ff       	jmp    80104e2d <alltraps>

801059b4 <vector189>:
.globl vector189
vector189:
  pushl $0
801059b4:	6a 00                	push   $0x0
  pushl $189
801059b6:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
801059bb:	e9 6d f4 ff ff       	jmp    80104e2d <alltraps>

801059c0 <vector190>:
.globl vector190
vector190:
  pushl $0
801059c0:	6a 00                	push   $0x0
  pushl $190
801059c2:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
801059c7:	e9 61 f4 ff ff       	jmp    80104e2d <alltraps>

801059cc <vector191>:
.globl vector191
vector191:
  pushl $0
801059cc:	6a 00                	push   $0x0
  pushl $191
801059ce:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
801059d3:	e9 55 f4 ff ff       	jmp    80104e2d <alltraps>

801059d8 <vector192>:
.globl vector192
vector192:
  pushl $0
801059d8:	6a 00                	push   $0x0
  pushl $192
801059da:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
801059df:	e9 49 f4 ff ff       	jmp    80104e2d <alltraps>

801059e4 <vector193>:
.globl vector193
vector193:
  pushl $0
801059e4:	6a 00                	push   $0x0
  pushl $193
801059e6:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
801059eb:	e9 3d f4 ff ff       	jmp    80104e2d <alltraps>

801059f0 <vector194>:
.globl vector194
vector194:
  pushl $0
801059f0:	6a 00                	push   $0x0
  pushl $194
801059f2:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
801059f7:	e9 31 f4 ff ff       	jmp    80104e2d <alltraps>

801059fc <vector195>:
.globl vector195
vector195:
  pushl $0
801059fc:	6a 00                	push   $0x0
  pushl $195
801059fe:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105a03:	e9 25 f4 ff ff       	jmp    80104e2d <alltraps>

80105a08 <vector196>:
.globl vector196
vector196:
  pushl $0
80105a08:	6a 00                	push   $0x0
  pushl $196
80105a0a:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105a0f:	e9 19 f4 ff ff       	jmp    80104e2d <alltraps>

80105a14 <vector197>:
.globl vector197
vector197:
  pushl $0
80105a14:	6a 00                	push   $0x0
  pushl $197
80105a16:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105a1b:	e9 0d f4 ff ff       	jmp    80104e2d <alltraps>

80105a20 <vector198>:
.globl vector198
vector198:
  pushl $0
80105a20:	6a 00                	push   $0x0
  pushl $198
80105a22:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105a27:	e9 01 f4 ff ff       	jmp    80104e2d <alltraps>

80105a2c <vector199>:
.globl vector199
vector199:
  pushl $0
80105a2c:	6a 00                	push   $0x0
  pushl $199
80105a2e:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105a33:	e9 f5 f3 ff ff       	jmp    80104e2d <alltraps>

80105a38 <vector200>:
.globl vector200
vector200:
  pushl $0
80105a38:	6a 00                	push   $0x0
  pushl $200
80105a3a:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105a3f:	e9 e9 f3 ff ff       	jmp    80104e2d <alltraps>

80105a44 <vector201>:
.globl vector201
vector201:
  pushl $0
80105a44:	6a 00                	push   $0x0
  pushl $201
80105a46:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105a4b:	e9 dd f3 ff ff       	jmp    80104e2d <alltraps>

80105a50 <vector202>:
.globl vector202
vector202:
  pushl $0
80105a50:	6a 00                	push   $0x0
  pushl $202
80105a52:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105a57:	e9 d1 f3 ff ff       	jmp    80104e2d <alltraps>

80105a5c <vector203>:
.globl vector203
vector203:
  pushl $0
80105a5c:	6a 00                	push   $0x0
  pushl $203
80105a5e:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105a63:	e9 c5 f3 ff ff       	jmp    80104e2d <alltraps>

80105a68 <vector204>:
.globl vector204
vector204:
  pushl $0
80105a68:	6a 00                	push   $0x0
  pushl $204
80105a6a:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105a6f:	e9 b9 f3 ff ff       	jmp    80104e2d <alltraps>

80105a74 <vector205>:
.globl vector205
vector205:
  pushl $0
80105a74:	6a 00                	push   $0x0
  pushl $205
80105a76:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105a7b:	e9 ad f3 ff ff       	jmp    80104e2d <alltraps>

80105a80 <vector206>:
.globl vector206
vector206:
  pushl $0
80105a80:	6a 00                	push   $0x0
  pushl $206
80105a82:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105a87:	e9 a1 f3 ff ff       	jmp    80104e2d <alltraps>

80105a8c <vector207>:
.globl vector207
vector207:
  pushl $0
80105a8c:	6a 00                	push   $0x0
  pushl $207
80105a8e:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105a93:	e9 95 f3 ff ff       	jmp    80104e2d <alltraps>

80105a98 <vector208>:
.globl vector208
vector208:
  pushl $0
80105a98:	6a 00                	push   $0x0
  pushl $208
80105a9a:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105a9f:	e9 89 f3 ff ff       	jmp    80104e2d <alltraps>

80105aa4 <vector209>:
.globl vector209
vector209:
  pushl $0
80105aa4:	6a 00                	push   $0x0
  pushl $209
80105aa6:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105aab:	e9 7d f3 ff ff       	jmp    80104e2d <alltraps>

80105ab0 <vector210>:
.globl vector210
vector210:
  pushl $0
80105ab0:	6a 00                	push   $0x0
  pushl $210
80105ab2:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105ab7:	e9 71 f3 ff ff       	jmp    80104e2d <alltraps>

80105abc <vector211>:
.globl vector211
vector211:
  pushl $0
80105abc:	6a 00                	push   $0x0
  pushl $211
80105abe:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105ac3:	e9 65 f3 ff ff       	jmp    80104e2d <alltraps>

80105ac8 <vector212>:
.globl vector212
vector212:
  pushl $0
80105ac8:	6a 00                	push   $0x0
  pushl $212
80105aca:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105acf:	e9 59 f3 ff ff       	jmp    80104e2d <alltraps>

80105ad4 <vector213>:
.globl vector213
vector213:
  pushl $0
80105ad4:	6a 00                	push   $0x0
  pushl $213
80105ad6:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105adb:	e9 4d f3 ff ff       	jmp    80104e2d <alltraps>

80105ae0 <vector214>:
.globl vector214
vector214:
  pushl $0
80105ae0:	6a 00                	push   $0x0
  pushl $214
80105ae2:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105ae7:	e9 41 f3 ff ff       	jmp    80104e2d <alltraps>

80105aec <vector215>:
.globl vector215
vector215:
  pushl $0
80105aec:	6a 00                	push   $0x0
  pushl $215
80105aee:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105af3:	e9 35 f3 ff ff       	jmp    80104e2d <alltraps>

80105af8 <vector216>:
.globl vector216
vector216:
  pushl $0
80105af8:	6a 00                	push   $0x0
  pushl $216
80105afa:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105aff:	e9 29 f3 ff ff       	jmp    80104e2d <alltraps>

80105b04 <vector217>:
.globl vector217
vector217:
  pushl $0
80105b04:	6a 00                	push   $0x0
  pushl $217
80105b06:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105b0b:	e9 1d f3 ff ff       	jmp    80104e2d <alltraps>

80105b10 <vector218>:
.globl vector218
vector218:
  pushl $0
80105b10:	6a 00                	push   $0x0
  pushl $218
80105b12:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105b17:	e9 11 f3 ff ff       	jmp    80104e2d <alltraps>

80105b1c <vector219>:
.globl vector219
vector219:
  pushl $0
80105b1c:	6a 00                	push   $0x0
  pushl $219
80105b1e:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105b23:	e9 05 f3 ff ff       	jmp    80104e2d <alltraps>

80105b28 <vector220>:
.globl vector220
vector220:
  pushl $0
80105b28:	6a 00                	push   $0x0
  pushl $220
80105b2a:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105b2f:	e9 f9 f2 ff ff       	jmp    80104e2d <alltraps>

80105b34 <vector221>:
.globl vector221
vector221:
  pushl $0
80105b34:	6a 00                	push   $0x0
  pushl $221
80105b36:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105b3b:	e9 ed f2 ff ff       	jmp    80104e2d <alltraps>

80105b40 <vector222>:
.globl vector222
vector222:
  pushl $0
80105b40:	6a 00                	push   $0x0
  pushl $222
80105b42:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105b47:	e9 e1 f2 ff ff       	jmp    80104e2d <alltraps>

80105b4c <vector223>:
.globl vector223
vector223:
  pushl $0
80105b4c:	6a 00                	push   $0x0
  pushl $223
80105b4e:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105b53:	e9 d5 f2 ff ff       	jmp    80104e2d <alltraps>

80105b58 <vector224>:
.globl vector224
vector224:
  pushl $0
80105b58:	6a 00                	push   $0x0
  pushl $224
80105b5a:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105b5f:	e9 c9 f2 ff ff       	jmp    80104e2d <alltraps>

80105b64 <vector225>:
.globl vector225
vector225:
  pushl $0
80105b64:	6a 00                	push   $0x0
  pushl $225
80105b66:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105b6b:	e9 bd f2 ff ff       	jmp    80104e2d <alltraps>

80105b70 <vector226>:
.globl vector226
vector226:
  pushl $0
80105b70:	6a 00                	push   $0x0
  pushl $226
80105b72:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105b77:	e9 b1 f2 ff ff       	jmp    80104e2d <alltraps>

80105b7c <vector227>:
.globl vector227
vector227:
  pushl $0
80105b7c:	6a 00                	push   $0x0
  pushl $227
80105b7e:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105b83:	e9 a5 f2 ff ff       	jmp    80104e2d <alltraps>

80105b88 <vector228>:
.globl vector228
vector228:
  pushl $0
80105b88:	6a 00                	push   $0x0
  pushl $228
80105b8a:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105b8f:	e9 99 f2 ff ff       	jmp    80104e2d <alltraps>

80105b94 <vector229>:
.globl vector229
vector229:
  pushl $0
80105b94:	6a 00                	push   $0x0
  pushl $229
80105b96:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105b9b:	e9 8d f2 ff ff       	jmp    80104e2d <alltraps>

80105ba0 <vector230>:
.globl vector230
vector230:
  pushl $0
80105ba0:	6a 00                	push   $0x0
  pushl $230
80105ba2:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105ba7:	e9 81 f2 ff ff       	jmp    80104e2d <alltraps>

80105bac <vector231>:
.globl vector231
vector231:
  pushl $0
80105bac:	6a 00                	push   $0x0
  pushl $231
80105bae:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105bb3:	e9 75 f2 ff ff       	jmp    80104e2d <alltraps>

80105bb8 <vector232>:
.globl vector232
vector232:
  pushl $0
80105bb8:	6a 00                	push   $0x0
  pushl $232
80105bba:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105bbf:	e9 69 f2 ff ff       	jmp    80104e2d <alltraps>

80105bc4 <vector233>:
.globl vector233
vector233:
  pushl $0
80105bc4:	6a 00                	push   $0x0
  pushl $233
80105bc6:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105bcb:	e9 5d f2 ff ff       	jmp    80104e2d <alltraps>

80105bd0 <vector234>:
.globl vector234
vector234:
  pushl $0
80105bd0:	6a 00                	push   $0x0
  pushl $234
80105bd2:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105bd7:	e9 51 f2 ff ff       	jmp    80104e2d <alltraps>

80105bdc <vector235>:
.globl vector235
vector235:
  pushl $0
80105bdc:	6a 00                	push   $0x0
  pushl $235
80105bde:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105be3:	e9 45 f2 ff ff       	jmp    80104e2d <alltraps>

80105be8 <vector236>:
.globl vector236
vector236:
  pushl $0
80105be8:	6a 00                	push   $0x0
  pushl $236
80105bea:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105bef:	e9 39 f2 ff ff       	jmp    80104e2d <alltraps>

80105bf4 <vector237>:
.globl vector237
vector237:
  pushl $0
80105bf4:	6a 00                	push   $0x0
  pushl $237
80105bf6:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105bfb:	e9 2d f2 ff ff       	jmp    80104e2d <alltraps>

80105c00 <vector238>:
.globl vector238
vector238:
  pushl $0
80105c00:	6a 00                	push   $0x0
  pushl $238
80105c02:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105c07:	e9 21 f2 ff ff       	jmp    80104e2d <alltraps>

80105c0c <vector239>:
.globl vector239
vector239:
  pushl $0
80105c0c:	6a 00                	push   $0x0
  pushl $239
80105c0e:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105c13:	e9 15 f2 ff ff       	jmp    80104e2d <alltraps>

80105c18 <vector240>:
.globl vector240
vector240:
  pushl $0
80105c18:	6a 00                	push   $0x0
  pushl $240
80105c1a:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105c1f:	e9 09 f2 ff ff       	jmp    80104e2d <alltraps>

80105c24 <vector241>:
.globl vector241
vector241:
  pushl $0
80105c24:	6a 00                	push   $0x0
  pushl $241
80105c26:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105c2b:	e9 fd f1 ff ff       	jmp    80104e2d <alltraps>

80105c30 <vector242>:
.globl vector242
vector242:
  pushl $0
80105c30:	6a 00                	push   $0x0
  pushl $242
80105c32:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105c37:	e9 f1 f1 ff ff       	jmp    80104e2d <alltraps>

80105c3c <vector243>:
.globl vector243
vector243:
  pushl $0
80105c3c:	6a 00                	push   $0x0
  pushl $243
80105c3e:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105c43:	e9 e5 f1 ff ff       	jmp    80104e2d <alltraps>

80105c48 <vector244>:
.globl vector244
vector244:
  pushl $0
80105c48:	6a 00                	push   $0x0
  pushl $244
80105c4a:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105c4f:	e9 d9 f1 ff ff       	jmp    80104e2d <alltraps>

80105c54 <vector245>:
.globl vector245
vector245:
  pushl $0
80105c54:	6a 00                	push   $0x0
  pushl $245
80105c56:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105c5b:	e9 cd f1 ff ff       	jmp    80104e2d <alltraps>

80105c60 <vector246>:
.globl vector246
vector246:
  pushl $0
80105c60:	6a 00                	push   $0x0
  pushl $246
80105c62:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105c67:	e9 c1 f1 ff ff       	jmp    80104e2d <alltraps>

80105c6c <vector247>:
.globl vector247
vector247:
  pushl $0
80105c6c:	6a 00                	push   $0x0
  pushl $247
80105c6e:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105c73:	e9 b5 f1 ff ff       	jmp    80104e2d <alltraps>

80105c78 <vector248>:
.globl vector248
vector248:
  pushl $0
80105c78:	6a 00                	push   $0x0
  pushl $248
80105c7a:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105c7f:	e9 a9 f1 ff ff       	jmp    80104e2d <alltraps>

80105c84 <vector249>:
.globl vector249
vector249:
  pushl $0
80105c84:	6a 00                	push   $0x0
  pushl $249
80105c86:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105c8b:	e9 9d f1 ff ff       	jmp    80104e2d <alltraps>

80105c90 <vector250>:
.globl vector250
vector250:
  pushl $0
80105c90:	6a 00                	push   $0x0
  pushl $250
80105c92:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105c97:	e9 91 f1 ff ff       	jmp    80104e2d <alltraps>

80105c9c <vector251>:
.globl vector251
vector251:
  pushl $0
80105c9c:	6a 00                	push   $0x0
  pushl $251
80105c9e:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105ca3:	e9 85 f1 ff ff       	jmp    80104e2d <alltraps>

80105ca8 <vector252>:
.globl vector252
vector252:
  pushl $0
80105ca8:	6a 00                	push   $0x0
  pushl $252
80105caa:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105caf:	e9 79 f1 ff ff       	jmp    80104e2d <alltraps>

80105cb4 <vector253>:
.globl vector253
vector253:
  pushl $0
80105cb4:	6a 00                	push   $0x0
  pushl $253
80105cb6:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105cbb:	e9 6d f1 ff ff       	jmp    80104e2d <alltraps>

80105cc0 <vector254>:
.globl vector254
vector254:
  pushl $0
80105cc0:	6a 00                	push   $0x0
  pushl $254
80105cc2:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105cc7:	e9 61 f1 ff ff       	jmp    80104e2d <alltraps>

80105ccc <vector255>:
.globl vector255
vector255:
  pushl $0
80105ccc:	6a 00                	push   $0x0
  pushl $255
80105cce:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105cd3:	e9 55 f1 ff ff       	jmp    80104e2d <alltraps>

80105cd8 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105cd8:	55                   	push   %ebp
80105cd9:	89 e5                	mov    %esp,%ebp
80105cdb:	57                   	push   %edi
80105cdc:	56                   	push   %esi
80105cdd:	53                   	push   %ebx
80105cde:	83 ec 0c             	sub    $0xc,%esp
80105ce1:	89 d6                	mov    %edx,%esi
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~inside walkpgdir\n");
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105ce3:	c1 ea 16             	shr    $0x16,%edx
80105ce6:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105ce9:	8b 1f                	mov    (%edi),%ebx
80105ceb:	f6 c3 01             	test   $0x1,%bl
80105cee:	74 22                	je     80105d12 <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105cf0:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80105cf6:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105cfc:	c1 ee 0c             	shr    $0xc,%esi
80105cff:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
80105d05:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80105d08:	89 d8                	mov    %ebx,%eax
80105d0a:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105d0d:	5b                   	pop    %ebx
80105d0e:	5e                   	pop    %esi
80105d0f:	5f                   	pop    %edi
80105d10:	5d                   	pop    %ebp
80105d11:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80105d12:	85 c9                	test   %ecx,%ecx
80105d14:	74 2b                	je     80105d41 <walkpgdir+0x69>
80105d16:	e8 a7 c3 ff ff       	call   801020c2 <kalloc>
80105d1b:	89 c3                	mov    %eax,%ebx
80105d1d:	85 c0                	test   %eax,%eax
80105d1f:	74 e7                	je     80105d08 <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80105d21:	83 ec 04             	sub    $0x4,%esp
80105d24:	68 00 10 00 00       	push   $0x1000
80105d29:	6a 00                	push   $0x0
80105d2b:	50                   	push   %eax
80105d2c:	e8 fe df ff ff       	call   80103d2f <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105d31:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80105d37:	83 c8 07             	or     $0x7,%eax
80105d3a:	89 07                	mov    %eax,(%edi)
80105d3c:	83 c4 10             	add    $0x10,%esp
80105d3f:	eb bb                	jmp    80105cfc <walkpgdir+0x24>
      return 0;
80105d41:	bb 00 00 00 00       	mov    $0x0,%ebx
80105d46:	eb c0                	jmp    80105d08 <walkpgdir+0x30>

80105d48 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105d48:	55                   	push   %ebp
80105d49:	89 e5                	mov    %esp,%ebp
80105d4b:	57                   	push   %edi
80105d4c:	56                   	push   %esi
80105d4d:	53                   	push   %ebx
80105d4e:	83 ec 1c             	sub    $0x1c,%esp
80105d51:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105d54:	8b 75 08             	mov    0x8(%ebp),%esi
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~inside mappages\n");
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80105d57:	89 d3                	mov    %edx,%ebx
80105d59:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105d5f:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105d63:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105d69:	b9 01 00 00 00       	mov    $0x1,%ecx
80105d6e:	89 da                	mov    %ebx,%edx
80105d70:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105d73:	e8 60 ff ff ff       	call   80105cd8 <walkpgdir>
80105d78:	85 c0                	test   %eax,%eax
80105d7a:	74 2e                	je     80105daa <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105d7c:	f6 00 01             	testb  $0x1,(%eax)
80105d7f:	75 1c                	jne    80105d9d <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105d81:	89 f2                	mov    %esi,%edx
80105d83:	0b 55 0c             	or     0xc(%ebp),%edx
80105d86:	83 ca 01             	or     $0x1,%edx
80105d89:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105d8b:	39 fb                	cmp    %edi,%ebx
80105d8d:	74 28                	je     80105db7 <mappages+0x6f>
      break;
    a += PGSIZE;
80105d8f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105d95:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105d9b:	eb cc                	jmp    80105d69 <mappages+0x21>
      panic("remap");
80105d9d:	83 ec 0c             	sub    $0xc,%esp
80105da0:	68 6c 6e 10 80       	push   $0x80106e6c
80105da5:	e8 9e a5 ff ff       	call   80100348 <panic>
      return -1;
80105daa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105daf:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105db2:	5b                   	pop    %ebx
80105db3:	5e                   	pop    %esi
80105db4:	5f                   	pop    %edi
80105db5:	5d                   	pop    %ebp
80105db6:	c3                   	ret    
  return 0;
80105db7:	b8 00 00 00 00       	mov    $0x0,%eax
80105dbc:	eb f1                	jmp    80105daf <mappages+0x67>

80105dbe <seginit>:
{
80105dbe:	55                   	push   %ebp
80105dbf:	89 e5                	mov    %esp,%ebp
80105dc1:	53                   	push   %ebx
80105dc2:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80105dc5:	e8 4b d4 ff ff       	call   80103215 <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80105dca:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80105dd0:	66 c7 80 78 c1 16 80 	movw   $0xffff,-0x7fe93e88(%eax)
80105dd7:	ff ff 
80105dd9:	66 c7 80 7a c1 16 80 	movw   $0x0,-0x7fe93e86(%eax)
80105de0:	00 00 
80105de2:	c6 80 7c c1 16 80 00 	movb   $0x0,-0x7fe93e84(%eax)
80105de9:	0f b6 88 7d c1 16 80 	movzbl -0x7fe93e83(%eax),%ecx
80105df0:	83 e1 f0             	and    $0xfffffff0,%ecx
80105df3:	83 c9 1a             	or     $0x1a,%ecx
80105df6:	83 e1 9f             	and    $0xffffff9f,%ecx
80105df9:	83 c9 80             	or     $0xffffff80,%ecx
80105dfc:	88 88 7d c1 16 80    	mov    %cl,-0x7fe93e83(%eax)
80105e02:	0f b6 88 7e c1 16 80 	movzbl -0x7fe93e82(%eax),%ecx
80105e09:	83 c9 0f             	or     $0xf,%ecx
80105e0c:	83 e1 cf             	and    $0xffffffcf,%ecx
80105e0f:	83 c9 c0             	or     $0xffffffc0,%ecx
80105e12:	88 88 7e c1 16 80    	mov    %cl,-0x7fe93e82(%eax)
80105e18:	c6 80 7f c1 16 80 00 	movb   $0x0,-0x7fe93e81(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80105e1f:	66 c7 80 80 c1 16 80 	movw   $0xffff,-0x7fe93e80(%eax)
80105e26:	ff ff 
80105e28:	66 c7 80 82 c1 16 80 	movw   $0x0,-0x7fe93e7e(%eax)
80105e2f:	00 00 
80105e31:	c6 80 84 c1 16 80 00 	movb   $0x0,-0x7fe93e7c(%eax)
80105e38:	0f b6 88 85 c1 16 80 	movzbl -0x7fe93e7b(%eax),%ecx
80105e3f:	83 e1 f0             	and    $0xfffffff0,%ecx
80105e42:	83 c9 12             	or     $0x12,%ecx
80105e45:	83 e1 9f             	and    $0xffffff9f,%ecx
80105e48:	83 c9 80             	or     $0xffffff80,%ecx
80105e4b:	88 88 85 c1 16 80    	mov    %cl,-0x7fe93e7b(%eax)
80105e51:	0f b6 88 86 c1 16 80 	movzbl -0x7fe93e7a(%eax),%ecx
80105e58:	83 c9 0f             	or     $0xf,%ecx
80105e5b:	83 e1 cf             	and    $0xffffffcf,%ecx
80105e5e:	83 c9 c0             	or     $0xffffffc0,%ecx
80105e61:	88 88 86 c1 16 80    	mov    %cl,-0x7fe93e7a(%eax)
80105e67:	c6 80 87 c1 16 80 00 	movb   $0x0,-0x7fe93e79(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80105e6e:	66 c7 80 88 c1 16 80 	movw   $0xffff,-0x7fe93e78(%eax)
80105e75:	ff ff 
80105e77:	66 c7 80 8a c1 16 80 	movw   $0x0,-0x7fe93e76(%eax)
80105e7e:	00 00 
80105e80:	c6 80 8c c1 16 80 00 	movb   $0x0,-0x7fe93e74(%eax)
80105e87:	c6 80 8d c1 16 80 fa 	movb   $0xfa,-0x7fe93e73(%eax)
80105e8e:	0f b6 88 8e c1 16 80 	movzbl -0x7fe93e72(%eax),%ecx
80105e95:	83 c9 0f             	or     $0xf,%ecx
80105e98:	83 e1 cf             	and    $0xffffffcf,%ecx
80105e9b:	83 c9 c0             	or     $0xffffffc0,%ecx
80105e9e:	88 88 8e c1 16 80    	mov    %cl,-0x7fe93e72(%eax)
80105ea4:	c6 80 8f c1 16 80 00 	movb   $0x0,-0x7fe93e71(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80105eab:	66 c7 80 90 c1 16 80 	movw   $0xffff,-0x7fe93e70(%eax)
80105eb2:	ff ff 
80105eb4:	66 c7 80 92 c1 16 80 	movw   $0x0,-0x7fe93e6e(%eax)
80105ebb:	00 00 
80105ebd:	c6 80 94 c1 16 80 00 	movb   $0x0,-0x7fe93e6c(%eax)
80105ec4:	c6 80 95 c1 16 80 f2 	movb   $0xf2,-0x7fe93e6b(%eax)
80105ecb:	0f b6 88 96 c1 16 80 	movzbl -0x7fe93e6a(%eax),%ecx
80105ed2:	83 c9 0f             	or     $0xf,%ecx
80105ed5:	83 e1 cf             	and    $0xffffffcf,%ecx
80105ed8:	83 c9 c0             	or     $0xffffffc0,%ecx
80105edb:	88 88 96 c1 16 80    	mov    %cl,-0x7fe93e6a(%eax)
80105ee1:	c6 80 97 c1 16 80 00 	movb   $0x0,-0x7fe93e69(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80105ee8:	05 70 c1 16 80       	add    $0x8016c170,%eax
  pd[0] = size-1;
80105eed:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
80105ef3:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
80105ef7:	c1 e8 10             	shr    $0x10,%eax
80105efa:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
80105efe:	8d 45 f2             	lea    -0xe(%ebp),%eax
80105f01:	0f 01 10             	lgdtl  (%eax)
}
80105f04:	83 c4 14             	add    $0x14,%esp
80105f07:	5b                   	pop    %ebx
80105f08:	5d                   	pop    %ebp
80105f09:	c3                   	ret    

80105f0a <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80105f0a:	55                   	push   %ebp
80105f0b:	89 e5                	mov    %esp,%ebp
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~inside switchkvm\n");
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80105f0d:	a1 24 cf 35 80       	mov    0x8035cf24,%eax
80105f12:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
80105f17:	0f 22 d8             	mov    %eax,%cr3
}
80105f1a:	5d                   	pop    %ebp
80105f1b:	c3                   	ret    

80105f1c <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80105f1c:	55                   	push   %ebp
80105f1d:	89 e5                	mov    %esp,%ebp
80105f1f:	57                   	push   %edi
80105f20:	56                   	push   %esi
80105f21:	53                   	push   %ebx
80105f22:	83 ec 1c             	sub    $0x1c,%esp
80105f25:	8b 75 08             	mov    0x8(%ebp),%esi
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~inside switchuvm\n");
  if(p == 0)
80105f28:	85 f6                	test   %esi,%esi
80105f2a:	0f 84 dd 00 00 00    	je     8010600d <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
80105f30:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
80105f34:	0f 84 e0 00 00 00    	je     8010601a <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
80105f3a:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
80105f3e:	0f 84 e3 00 00 00    	je     80106027 <switchuvm+0x10b>
    panic("switchuvm: no pgdir");
  pushcli();
80105f44:	e8 5d dc ff ff       	call   80103ba6 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80105f49:	e8 6b d2 ff ff       	call   801031b9 <mycpu>
80105f4e:	89 c3                	mov    %eax,%ebx
80105f50:	e8 64 d2 ff ff       	call   801031b9 <mycpu>
80105f55:	8d 78 08             	lea    0x8(%eax),%edi
80105f58:	e8 5c d2 ff ff       	call   801031b9 <mycpu>
80105f5d:	83 c0 08             	add    $0x8,%eax
80105f60:	c1 e8 10             	shr    $0x10,%eax
80105f63:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105f66:	e8 4e d2 ff ff       	call   801031b9 <mycpu>
80105f6b:	83 c0 08             	add    $0x8,%eax
80105f6e:	c1 e8 18             	shr    $0x18,%eax
80105f71:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80105f78:	67 00 
80105f7a:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
80105f81:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
80105f85:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
80105f8b:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
80105f92:	83 e2 f0             	and    $0xfffffff0,%edx
80105f95:	83 ca 19             	or     $0x19,%edx
80105f98:	83 e2 9f             	and    $0xffffff9f,%edx
80105f9b:	83 ca 80             	or     $0xffffff80,%edx
80105f9e:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
80105fa4:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
80105fab:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
80105fb1:	e8 03 d2 ff ff       	call   801031b9 <mycpu>
80105fb6:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80105fbd:	83 e2 ef             	and    $0xffffffef,%edx
80105fc0:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
80105fc6:	e8 ee d1 ff ff       	call   801031b9 <mycpu>
80105fcb:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
80105fd1:	8b 5e 08             	mov    0x8(%esi),%ebx
80105fd4:	e8 e0 d1 ff ff       	call   801031b9 <mycpu>
80105fd9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80105fdf:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
80105fe2:	e8 d2 d1 ff ff       	call   801031b9 <mycpu>
80105fe7:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
80105fed:	b8 28 00 00 00       	mov    $0x28,%eax
80105ff2:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
80105ff5:	8b 46 04             	mov    0x4(%esi),%eax
80105ff8:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
80105ffd:	0f 22 d8             	mov    %eax,%cr3
  popcli();
80106000:	e8 de db ff ff       	call   80103be3 <popcli>
}
80106005:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106008:	5b                   	pop    %ebx
80106009:	5e                   	pop    %esi
8010600a:	5f                   	pop    %edi
8010600b:	5d                   	pop    %ebp
8010600c:	c3                   	ret    
    panic("switchuvm: no process");
8010600d:	83 ec 0c             	sub    $0xc,%esp
80106010:	68 72 6e 10 80       	push   $0x80106e72
80106015:	e8 2e a3 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
8010601a:	83 ec 0c             	sub    $0xc,%esp
8010601d:	68 88 6e 10 80       	push   $0x80106e88
80106022:	e8 21 a3 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
80106027:	83 ec 0c             	sub    $0xc,%esp
8010602a:	68 9d 6e 10 80       	push   $0x80106e9d
8010602f:	e8 14 a3 ff ff       	call   80100348 <panic>

80106034 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80106034:	55                   	push   %ebp
80106035:	89 e5                	mov    %esp,%ebp
80106037:	56                   	push   %esi
80106038:	53                   	push   %ebx
80106039:	8b 75 10             	mov    0x10(%ebp),%esi
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~inside inituvm\n");
  char *mem;

  if(sz >= PGSIZE)
8010603c:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106042:	77 4c                	ja     80106090 <inituvm+0x5c>
    panic("inituvm: more than a page");
  mem = kalloc();
80106044:	e8 79 c0 ff ff       	call   801020c2 <kalloc>
80106049:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
8010604b:	83 ec 04             	sub    $0x4,%esp
8010604e:	68 00 10 00 00       	push   $0x1000
80106053:	6a 00                	push   $0x0
80106055:	50                   	push   %eax
80106056:	e8 d4 dc ff ff       	call   80103d2f <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
8010605b:	83 c4 08             	add    $0x8,%esp
8010605e:	6a 06                	push   $0x6
80106060:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106066:	50                   	push   %eax
80106067:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010606c:	ba 00 00 00 00       	mov    $0x0,%edx
80106071:	8b 45 08             	mov    0x8(%ebp),%eax
80106074:	e8 cf fc ff ff       	call   80105d48 <mappages>
  memmove(mem, init, sz);
80106079:	83 c4 0c             	add    $0xc,%esp
8010607c:	56                   	push   %esi
8010607d:	ff 75 0c             	pushl  0xc(%ebp)
80106080:	53                   	push   %ebx
80106081:	e8 24 dd ff ff       	call   80103daa <memmove>
}
80106086:	83 c4 10             	add    $0x10,%esp
80106089:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010608c:	5b                   	pop    %ebx
8010608d:	5e                   	pop    %esi
8010608e:	5d                   	pop    %ebp
8010608f:	c3                   	ret    
    panic("inituvm: more than a page");
80106090:	83 ec 0c             	sub    $0xc,%esp
80106093:	68 b1 6e 10 80       	push   $0x80106eb1
80106098:	e8 ab a2 ff ff       	call   80100348 <panic>

8010609d <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
8010609d:	55                   	push   %ebp
8010609e:	89 e5                	mov    %esp,%ebp
801060a0:	57                   	push   %edi
801060a1:	56                   	push   %esi
801060a2:	53                   	push   %ebx
801060a3:	83 ec 0c             	sub    $0xc,%esp
801060a6:	8b 7d 18             	mov    0x18(%ebp),%edi
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~inside loaduvm\n");
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
801060a9:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
801060b0:	75 07                	jne    801060b9 <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
801060b2:	bb 00 00 00 00       	mov    $0x0,%ebx
801060b7:	eb 3c                	jmp    801060f5 <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
801060b9:	83 ec 0c             	sub    $0xc,%esp
801060bc:	68 6c 6f 10 80       	push   $0x80106f6c
801060c1:	e8 82 a2 ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
801060c6:	83 ec 0c             	sub    $0xc,%esp
801060c9:	68 cb 6e 10 80       	push   $0x80106ecb
801060ce:	e8 75 a2 ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
801060d3:	05 00 00 00 80       	add    $0x80000000,%eax
801060d8:	56                   	push   %esi
801060d9:	89 da                	mov    %ebx,%edx
801060db:	03 55 14             	add    0x14(%ebp),%edx
801060de:	52                   	push   %edx
801060df:	50                   	push   %eax
801060e0:	ff 75 10             	pushl  0x10(%ebp)
801060e3:	e8 8b b6 ff ff       	call   80101773 <readi>
801060e8:	83 c4 10             	add    $0x10,%esp
801060eb:	39 f0                	cmp    %esi,%eax
801060ed:	75 47                	jne    80106136 <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
801060ef:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801060f5:	39 fb                	cmp    %edi,%ebx
801060f7:	73 30                	jae    80106129 <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
801060f9:	89 da                	mov    %ebx,%edx
801060fb:	03 55 0c             	add    0xc(%ebp),%edx
801060fe:	b9 00 00 00 00       	mov    $0x0,%ecx
80106103:	8b 45 08             	mov    0x8(%ebp),%eax
80106106:	e8 cd fb ff ff       	call   80105cd8 <walkpgdir>
8010610b:	85 c0                	test   %eax,%eax
8010610d:	74 b7                	je     801060c6 <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
8010610f:	8b 00                	mov    (%eax),%eax
80106111:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
80106116:	89 fe                	mov    %edi,%esi
80106118:	29 de                	sub    %ebx,%esi
8010611a:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106120:	76 b1                	jbe    801060d3 <loaduvm+0x36>
      n = PGSIZE;
80106122:	be 00 10 00 00       	mov    $0x1000,%esi
80106127:	eb aa                	jmp    801060d3 <loaduvm+0x36>
      return -1;
  }
  return 0;
80106129:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010612e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106131:	5b                   	pop    %ebx
80106132:	5e                   	pop    %esi
80106133:	5f                   	pop    %edi
80106134:	5d                   	pop    %ebp
80106135:	c3                   	ret    
      return -1;
80106136:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010613b:	eb f1                	jmp    8010612e <loaduvm+0x91>

8010613d <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
8010613d:	55                   	push   %ebp
8010613e:	89 e5                	mov    %esp,%ebp
80106140:	57                   	push   %edi
80106141:	56                   	push   %esi
80106142:	53                   	push   %ebx
80106143:	83 ec 0c             	sub    $0xc,%esp
80106146:	8b 7d 0c             	mov    0xc(%ebp),%edi
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~inside deallocuvm\n");
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80106149:	39 7d 10             	cmp    %edi,0x10(%ebp)
8010614c:	73 11                	jae    8010615f <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
8010614e:	8b 45 10             	mov    0x10(%ebp),%eax
80106151:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80106157:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
8010615d:	eb 19                	jmp    80106178 <deallocuvm+0x3b>
    return oldsz;
8010615f:	89 f8                	mov    %edi,%eax
80106161:	eb 64                	jmp    801061c7 <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
80106163:	c1 eb 16             	shr    $0x16,%ebx
80106166:	83 c3 01             	add    $0x1,%ebx
80106169:	c1 e3 16             	shl    $0x16,%ebx
8010616c:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
80106172:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106178:	39 fb                	cmp    %edi,%ebx
8010617a:	73 48                	jae    801061c4 <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
8010617c:	b9 00 00 00 00       	mov    $0x0,%ecx
80106181:	89 da                	mov    %ebx,%edx
80106183:	8b 45 08             	mov    0x8(%ebp),%eax
80106186:	e8 4d fb ff ff       	call   80105cd8 <walkpgdir>
8010618b:	89 c6                	mov    %eax,%esi
    if(!pte)
8010618d:	85 c0                	test   %eax,%eax
8010618f:	74 d2                	je     80106163 <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
80106191:	8b 00                	mov    (%eax),%eax
80106193:	a8 01                	test   $0x1,%al
80106195:	74 db                	je     80106172 <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
80106197:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010619c:	74 19                	je     801061b7 <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
8010619e:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801061a3:	83 ec 0c             	sub    $0xc,%esp
801061a6:	50                   	push   %eax
801061a7:	e8 f8 bd ff ff       	call   80101fa4 <kfree>
      *pte = 0;
801061ac:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
801061b2:	83 c4 10             	add    $0x10,%esp
801061b5:	eb bb                	jmp    80106172 <deallocuvm+0x35>
        panic("kfree");
801061b7:	83 ec 0c             	sub    $0xc,%esp
801061ba:	68 e6 67 10 80       	push   $0x801067e6
801061bf:	e8 84 a1 ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
801061c4:	8b 45 10             	mov    0x10(%ebp),%eax
}
801061c7:	8d 65 f4             	lea    -0xc(%ebp),%esp
801061ca:	5b                   	pop    %ebx
801061cb:	5e                   	pop    %esi
801061cc:	5f                   	pop    %edi
801061cd:	5d                   	pop    %ebp
801061ce:	c3                   	ret    

801061cf <allocuvm>:
{
801061cf:	55                   	push   %ebp
801061d0:	89 e5                	mov    %esp,%ebp
801061d2:	57                   	push   %edi
801061d3:	56                   	push   %esi
801061d4:	53                   	push   %ebx
801061d5:	83 ec 1c             	sub    $0x1c,%esp
801061d8:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
801061db:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801061de:	85 ff                	test   %edi,%edi
801061e0:	0f 88 c1 00 00 00    	js     801062a7 <allocuvm+0xd8>
  if(newsz < oldsz)
801061e6:	3b 7d 0c             	cmp    0xc(%ebp),%edi
801061e9:	72 5c                	jb     80106247 <allocuvm+0x78>
  a = PGROUNDUP(oldsz);
801061eb:	8b 45 0c             	mov    0xc(%ebp),%eax
801061ee:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801061f4:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
801061fa:	39 fb                	cmp    %edi,%ebx
801061fc:	0f 83 ac 00 00 00    	jae    801062ae <allocuvm+0xdf>
    mem = kalloc();
80106202:	e8 bb be ff ff       	call   801020c2 <kalloc>
80106207:	89 c6                	mov    %eax,%esi
    if(mem == 0){
80106209:	85 c0                	test   %eax,%eax
8010620b:	74 42                	je     8010624f <allocuvm+0x80>
    memset(mem, 0, PGSIZE);
8010620d:	83 ec 04             	sub    $0x4,%esp
80106210:	68 00 10 00 00       	push   $0x1000
80106215:	6a 00                	push   $0x0
80106217:	50                   	push   %eax
80106218:	e8 12 db ff ff       	call   80103d2f <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
8010621d:	83 c4 08             	add    $0x8,%esp
80106220:	6a 06                	push   $0x6
80106222:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
80106228:	50                   	push   %eax
80106229:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010622e:	89 da                	mov    %ebx,%edx
80106230:	8b 45 08             	mov    0x8(%ebp),%eax
80106233:	e8 10 fb ff ff       	call   80105d48 <mappages>
80106238:	83 c4 10             	add    $0x10,%esp
8010623b:	85 c0                	test   %eax,%eax
8010623d:	78 38                	js     80106277 <allocuvm+0xa8>
  for(; a < newsz; a += PGSIZE){
8010623f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106245:	eb b3                	jmp    801061fa <allocuvm+0x2b>
    return oldsz;
80106247:	8b 45 0c             	mov    0xc(%ebp),%eax
8010624a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010624d:	eb 5f                	jmp    801062ae <allocuvm+0xdf>
      cprintf("allocuvm out of memory\n");
8010624f:	83 ec 0c             	sub    $0xc,%esp
80106252:	68 e9 6e 10 80       	push   $0x80106ee9
80106257:	e8 af a3 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010625c:	83 c4 0c             	add    $0xc,%esp
8010625f:	ff 75 0c             	pushl  0xc(%ebp)
80106262:	57                   	push   %edi
80106263:	ff 75 08             	pushl  0x8(%ebp)
80106266:	e8 d2 fe ff ff       	call   8010613d <deallocuvm>
      return 0;
8010626b:	83 c4 10             	add    $0x10,%esp
8010626e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106275:	eb 37                	jmp    801062ae <allocuvm+0xdf>
      cprintf("allocuvm out of memory (2)\n");
80106277:	83 ec 0c             	sub    $0xc,%esp
8010627a:	68 01 6f 10 80       	push   $0x80106f01
8010627f:	e8 87 a3 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80106284:	83 c4 0c             	add    $0xc,%esp
80106287:	ff 75 0c             	pushl  0xc(%ebp)
8010628a:	57                   	push   %edi
8010628b:	ff 75 08             	pushl  0x8(%ebp)
8010628e:	e8 aa fe ff ff       	call   8010613d <deallocuvm>
      kfree(mem);
80106293:	89 34 24             	mov    %esi,(%esp)
80106296:	e8 09 bd ff ff       	call   80101fa4 <kfree>
      return 0;
8010629b:	83 c4 10             	add    $0x10,%esp
8010629e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801062a5:	eb 07                	jmp    801062ae <allocuvm+0xdf>
    return 0;
801062a7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
801062ae:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801062b1:	8d 65 f4             	lea    -0xc(%ebp),%esp
801062b4:	5b                   	pop    %ebx
801062b5:	5e                   	pop    %esi
801062b6:	5f                   	pop    %edi
801062b7:	5d                   	pop    %ebp
801062b8:	c3                   	ret    

801062b9 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
801062b9:	55                   	push   %ebp
801062ba:	89 e5                	mov    %esp,%ebp
801062bc:	56                   	push   %esi
801062bd:	53                   	push   %ebx
801062be:	8b 75 08             	mov    0x8(%ebp),%esi
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~inside freevm\n");
  uint i;

  if(pgdir == 0)
801062c1:	85 f6                	test   %esi,%esi
801062c3:	74 1a                	je     801062df <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
801062c5:	83 ec 04             	sub    $0x4,%esp
801062c8:	6a 00                	push   $0x0
801062ca:	68 00 00 00 80       	push   $0x80000000
801062cf:	56                   	push   %esi
801062d0:	e8 68 fe ff ff       	call   8010613d <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
801062d5:	83 c4 10             	add    $0x10,%esp
801062d8:	bb 00 00 00 00       	mov    $0x0,%ebx
801062dd:	eb 10                	jmp    801062ef <freevm+0x36>
    panic("freevm: no pgdir");
801062df:	83 ec 0c             	sub    $0xc,%esp
801062e2:	68 1d 6f 10 80       	push   $0x80106f1d
801062e7:	e8 5c a0 ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
801062ec:	83 c3 01             	add    $0x1,%ebx
801062ef:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
801062f5:	77 1f                	ja     80106316 <freevm+0x5d>
    if(pgdir[i] & PTE_P){
801062f7:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
801062fa:	a8 01                	test   $0x1,%al
801062fc:	74 ee                	je     801062ec <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
801062fe:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106303:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
80106308:	83 ec 0c             	sub    $0xc,%esp
8010630b:	50                   	push   %eax
8010630c:	e8 93 bc ff ff       	call   80101fa4 <kfree>
80106311:	83 c4 10             	add    $0x10,%esp
80106314:	eb d6                	jmp    801062ec <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
80106316:	83 ec 0c             	sub    $0xc,%esp
80106319:	56                   	push   %esi
8010631a:	e8 85 bc ff ff       	call   80101fa4 <kfree>
}
8010631f:	83 c4 10             	add    $0x10,%esp
80106322:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106325:	5b                   	pop    %ebx
80106326:	5e                   	pop    %esi
80106327:	5d                   	pop    %ebp
80106328:	c3                   	ret    

80106329 <setupkvm>:
{
80106329:	55                   	push   %ebp
8010632a:	89 e5                	mov    %esp,%ebp
8010632c:	56                   	push   %esi
8010632d:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc()) == 0)
8010632e:	e8 8f bd ff ff       	call   801020c2 <kalloc>
80106333:	89 c6                	mov    %eax,%esi
80106335:	85 c0                	test   %eax,%eax
80106337:	74 55                	je     8010638e <setupkvm+0x65>
  memset(pgdir, 0, PGSIZE);
80106339:	83 ec 04             	sub    $0x4,%esp
8010633c:	68 00 10 00 00       	push   $0x1000
80106341:	6a 00                	push   $0x0
80106343:	50                   	push   %eax
80106344:	e8 e6 d9 ff ff       	call   80103d2f <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80106349:	83 c4 10             	add    $0x10,%esp
8010634c:	bb 20 94 10 80       	mov    $0x80109420,%ebx
80106351:	81 fb 60 94 10 80    	cmp    $0x80109460,%ebx
80106357:	73 35                	jae    8010638e <setupkvm+0x65>
                (uint)k->phys_start, k->perm) < 0) {
80106359:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
8010635c:	8b 4b 08             	mov    0x8(%ebx),%ecx
8010635f:	29 c1                	sub    %eax,%ecx
80106361:	83 ec 08             	sub    $0x8,%esp
80106364:	ff 73 0c             	pushl  0xc(%ebx)
80106367:	50                   	push   %eax
80106368:	8b 13                	mov    (%ebx),%edx
8010636a:	89 f0                	mov    %esi,%eax
8010636c:	e8 d7 f9 ff ff       	call   80105d48 <mappages>
80106371:	83 c4 10             	add    $0x10,%esp
80106374:	85 c0                	test   %eax,%eax
80106376:	78 05                	js     8010637d <setupkvm+0x54>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80106378:	83 c3 10             	add    $0x10,%ebx
8010637b:	eb d4                	jmp    80106351 <setupkvm+0x28>
      freevm(pgdir);
8010637d:	83 ec 0c             	sub    $0xc,%esp
80106380:	56                   	push   %esi
80106381:	e8 33 ff ff ff       	call   801062b9 <freevm>
      return 0;
80106386:	83 c4 10             	add    $0x10,%esp
80106389:	be 00 00 00 00       	mov    $0x0,%esi
}
8010638e:	89 f0                	mov    %esi,%eax
80106390:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106393:	5b                   	pop    %ebx
80106394:	5e                   	pop    %esi
80106395:	5d                   	pop    %ebp
80106396:	c3                   	ret    

80106397 <kvmalloc>:
{
80106397:	55                   	push   %ebp
80106398:	89 e5                	mov    %esp,%ebp
8010639a:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
8010639d:	e8 87 ff ff ff       	call   80106329 <setupkvm>
801063a2:	a3 24 cf 35 80       	mov    %eax,0x8035cf24
  switchkvm();
801063a7:	e8 5e fb ff ff       	call   80105f0a <switchkvm>
}
801063ac:	c9                   	leave  
801063ad:	c3                   	ret    

801063ae <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
801063ae:	55                   	push   %ebp
801063af:	89 e5                	mov    %esp,%ebp
801063b1:	83 ec 08             	sub    $0x8,%esp
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~inside clearpteu\n");
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801063b4:	b9 00 00 00 00       	mov    $0x0,%ecx
801063b9:	8b 55 0c             	mov    0xc(%ebp),%edx
801063bc:	8b 45 08             	mov    0x8(%ebp),%eax
801063bf:	e8 14 f9 ff ff       	call   80105cd8 <walkpgdir>
  if(pte == 0)
801063c4:	85 c0                	test   %eax,%eax
801063c6:	74 05                	je     801063cd <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
801063c8:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
801063cb:	c9                   	leave  
801063cc:	c3                   	ret    
    panic("clearpteu");
801063cd:	83 ec 0c             	sub    $0xc,%esp
801063d0:	68 2e 6f 10 80       	push   $0x80106f2e
801063d5:	e8 6e 9f ff ff       	call   80100348 <panic>

801063da <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
801063da:	55                   	push   %ebp
801063db:	89 e5                	mov    %esp,%ebp
801063dd:	57                   	push   %edi
801063de:	56                   	push   %esi
801063df:	53                   	push   %ebx
801063e0:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
801063e3:	e8 41 ff ff ff       	call   80106329 <setupkvm>
801063e8:	89 45 dc             	mov    %eax,-0x24(%ebp)
801063eb:	85 c0                	test   %eax,%eax
801063ed:	0f 84 c4 00 00 00    	je     801064b7 <copyuvm+0xdd>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801063f3:	bf 00 00 00 00       	mov    $0x0,%edi
801063f8:	3b 7d 0c             	cmp    0xc(%ebp),%edi
801063fb:	0f 83 b6 00 00 00    	jae    801064b7 <copyuvm+0xdd>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80106401:	89 7d e4             	mov    %edi,-0x1c(%ebp)
80106404:	b9 00 00 00 00       	mov    $0x0,%ecx
80106409:	89 fa                	mov    %edi,%edx
8010640b:	8b 45 08             	mov    0x8(%ebp),%eax
8010640e:	e8 c5 f8 ff ff       	call   80105cd8 <walkpgdir>
80106413:	85 c0                	test   %eax,%eax
80106415:	74 65                	je     8010647c <copyuvm+0xa2>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
80106417:	8b 00                	mov    (%eax),%eax
80106419:	a8 01                	test   $0x1,%al
8010641b:	74 6c                	je     80106489 <copyuvm+0xaf>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
8010641d:	89 c6                	mov    %eax,%esi
8010641f:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    flags = PTE_FLAGS(*pte);
80106425:	25 ff 0f 00 00       	and    $0xfff,%eax
8010642a:	89 45 e0             	mov    %eax,-0x20(%ebp)
    if((mem = kalloc()) == 0)
8010642d:	e8 90 bc ff ff       	call   801020c2 <kalloc>
80106432:	89 c3                	mov    %eax,%ebx
80106434:	85 c0                	test   %eax,%eax
80106436:	74 6a                	je     801064a2 <copyuvm+0xc8>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
80106438:	81 c6 00 00 00 80    	add    $0x80000000,%esi
8010643e:	83 ec 04             	sub    $0x4,%esp
80106441:	68 00 10 00 00       	push   $0x1000
80106446:	56                   	push   %esi
80106447:	50                   	push   %eax
80106448:	e8 5d d9 ff ff       	call   80103daa <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
8010644d:	83 c4 08             	add    $0x8,%esp
80106450:	ff 75 e0             	pushl  -0x20(%ebp)
80106453:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106459:	50                   	push   %eax
8010645a:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010645f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80106462:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106465:	e8 de f8 ff ff       	call   80105d48 <mappages>
8010646a:	83 c4 10             	add    $0x10,%esp
8010646d:	85 c0                	test   %eax,%eax
8010646f:	78 25                	js     80106496 <copyuvm+0xbc>
  for(i = 0; i < sz; i += PGSIZE){
80106471:	81 c7 00 10 00 00    	add    $0x1000,%edi
80106477:	e9 7c ff ff ff       	jmp    801063f8 <copyuvm+0x1e>
      panic("copyuvm: pte should exist");
8010647c:	83 ec 0c             	sub    $0xc,%esp
8010647f:	68 38 6f 10 80       	push   $0x80106f38
80106484:	e8 bf 9e ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
80106489:	83 ec 0c             	sub    $0xc,%esp
8010648c:	68 52 6f 10 80       	push   $0x80106f52
80106491:	e8 b2 9e ff ff       	call   80100348 <panic>
      kfree(mem);
80106496:	83 ec 0c             	sub    $0xc,%esp
80106499:	53                   	push   %ebx
8010649a:	e8 05 bb ff ff       	call   80101fa4 <kfree>
      goto bad;
8010649f:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
801064a2:	83 ec 0c             	sub    $0xc,%esp
801064a5:	ff 75 dc             	pushl  -0x24(%ebp)
801064a8:	e8 0c fe ff ff       	call   801062b9 <freevm>
  return 0;
801064ad:	83 c4 10             	add    $0x10,%esp
801064b0:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
801064b7:	8b 45 dc             	mov    -0x24(%ebp),%eax
801064ba:	8d 65 f4             	lea    -0xc(%ebp),%esp
801064bd:	5b                   	pop    %ebx
801064be:	5e                   	pop    %esi
801064bf:	5f                   	pop    %edi
801064c0:	5d                   	pop    %ebp
801064c1:	c3                   	ret    

801064c2 <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801064c2:	55                   	push   %ebp
801064c3:	89 e5                	mov    %esp,%ebp
801064c5:	83 ec 08             	sub    $0x8,%esp
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~inside uva2ka\n");
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801064c8:	b9 00 00 00 00       	mov    $0x0,%ecx
801064cd:	8b 55 0c             	mov    0xc(%ebp),%edx
801064d0:	8b 45 08             	mov    0x8(%ebp),%eax
801064d3:	e8 00 f8 ff ff       	call   80105cd8 <walkpgdir>
  if((*pte & PTE_P) == 0)
801064d8:	8b 00                	mov    (%eax),%eax
801064da:	a8 01                	test   $0x1,%al
801064dc:	74 10                	je     801064ee <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
801064de:	a8 04                	test   $0x4,%al
801064e0:	74 13                	je     801064f5 <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
801064e2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801064e7:	05 00 00 00 80       	add    $0x80000000,%eax
}
801064ec:	c9                   	leave  
801064ed:	c3                   	ret    
    return 0;
801064ee:	b8 00 00 00 00       	mov    $0x0,%eax
801064f3:	eb f7                	jmp    801064ec <uva2ka+0x2a>
    return 0;
801064f5:	b8 00 00 00 00       	mov    $0x0,%eax
801064fa:	eb f0                	jmp    801064ec <uva2ka+0x2a>

801064fc <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801064fc:	55                   	push   %ebp
801064fd:	89 e5                	mov    %esp,%ebp
801064ff:	57                   	push   %edi
80106500:	56                   	push   %esi
80106501:	53                   	push   %ebx
80106502:	83 ec 0c             	sub    $0xc,%esp
80106505:	8b 7d 14             	mov    0x14(%ebp),%edi
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~inside copyout\n");
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80106508:	eb 25                	jmp    8010652f <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
8010650a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010650d:	29 f2                	sub    %esi,%edx
8010650f:	01 d0                	add    %edx,%eax
80106511:	83 ec 04             	sub    $0x4,%esp
80106514:	53                   	push   %ebx
80106515:	ff 75 10             	pushl  0x10(%ebp)
80106518:	50                   	push   %eax
80106519:	e8 8c d8 ff ff       	call   80103daa <memmove>
    len -= n;
8010651e:	29 df                	sub    %ebx,%edi
    buf += n;
80106520:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
80106523:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
80106529:	89 45 0c             	mov    %eax,0xc(%ebp)
8010652c:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
8010652f:	85 ff                	test   %edi,%edi
80106531:	74 2f                	je     80106562 <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
80106533:	8b 75 0c             	mov    0xc(%ebp),%esi
80106536:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
8010653c:	83 ec 08             	sub    $0x8,%esp
8010653f:	56                   	push   %esi
80106540:	ff 75 08             	pushl  0x8(%ebp)
80106543:	e8 7a ff ff ff       	call   801064c2 <uva2ka>
    if(pa0 == 0)
80106548:	83 c4 10             	add    $0x10,%esp
8010654b:	85 c0                	test   %eax,%eax
8010654d:	74 20                	je     8010656f <copyout+0x73>
    n = PGSIZE - (va - va0);
8010654f:	89 f3                	mov    %esi,%ebx
80106551:	2b 5d 0c             	sub    0xc(%ebp),%ebx
80106554:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
8010655a:	39 df                	cmp    %ebx,%edi
8010655c:	73 ac                	jae    8010650a <copyout+0xe>
      n = len;
8010655e:	89 fb                	mov    %edi,%ebx
80106560:	eb a8                	jmp    8010650a <copyout+0xe>
  }
  return 0;
80106562:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106567:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010656a:	5b                   	pop    %ebx
8010656b:	5e                   	pop    %esi
8010656c:	5f                   	pop    %edi
8010656d:	5d                   	pop    %ebp
8010656e:	c3                   	ret    
      return -1;
8010656f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106574:	eb f1                	jmp    80106567 <copyout+0x6b>
