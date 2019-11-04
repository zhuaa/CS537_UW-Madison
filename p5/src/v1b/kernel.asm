
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
80100015:	b8 00 90 10 00       	mov    $0x109000,%eax
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
80100028:	bc c0 b5 10 80       	mov    $0x8010b5c0,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 12 2b 10 80       	mov    $0x80102b12,%eax
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
80100041:	68 c0 b5 10 80       	push   $0x8010b5c0
80100046:	e8 d8 3c 00 00       	call   80103d23 <acquire>

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
8010004b:	8b 1d 10 fd 10 80    	mov    0x8010fd10,%ebx
80100051:	83 c4 10             	add    $0x10,%esp
80100054:	eb 03                	jmp    80100059 <bget+0x25>
80100056:	8b 5b 54             	mov    0x54(%ebx),%ebx
80100059:	81 fb bc fc 10 80    	cmp    $0x8010fcbc,%ebx
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
80100077:	68 c0 b5 10 80       	push   $0x8010b5c0
8010007c:	e8 07 3d 00 00       	call   80103d88 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 83 3a 00 00       	call   80103b0f <acquiresleep>
      return b;
8010008c:	83 c4 10             	add    $0x10,%esp
8010008f:	eb 4c                	jmp    801000dd <bget+0xa9>
  }

  // Not cached; recycle an unused buffer.
  // Even if refcnt==0, B_DIRTY indicates a buffer is in use
  // because log.c has modified it but not yet committed it.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100091:	8b 1d 0c fd 10 80    	mov    0x8010fd0c,%ebx
80100097:	eb 03                	jmp    8010009c <bget+0x68>
80100099:	8b 5b 50             	mov    0x50(%ebx),%ebx
8010009c:	81 fb bc fc 10 80    	cmp    $0x8010fcbc,%ebx
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
801000c5:	68 c0 b5 10 80       	push   $0x8010b5c0
801000ca:	e8 b9 3c 00 00       	call   80103d88 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 35 3a 00 00       	call   80103b0f <acquiresleep>
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
801000ea:	68 60 66 10 80       	push   $0x80106660
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 71 66 10 80       	push   $0x80106671
80100100:	68 c0 b5 10 80       	push   $0x8010b5c0
80100105:	e8 dd 3a 00 00       	call   80103be7 <initlock>
  bcache.head.prev = &bcache.head;
8010010a:	c7 05 0c fd 10 80 bc 	movl   $0x8010fcbc,0x8010fd0c
80100111:	fc 10 80 
  bcache.head.next = &bcache.head;
80100114:	c7 05 10 fd 10 80 bc 	movl   $0x8010fcbc,0x8010fd10
8010011b:	fc 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010011e:	83 c4 10             	add    $0x10,%esp
80100121:	bb f4 b5 10 80       	mov    $0x8010b5f4,%ebx
80100126:	eb 37                	jmp    8010015f <binit+0x6b>
    b->next = bcache.head.next;
80100128:	a1 10 fd 10 80       	mov    0x8010fd10,%eax
8010012d:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
80100130:	c7 43 50 bc fc 10 80 	movl   $0x8010fcbc,0x50(%ebx)
    initsleeplock(&b->lock, "buffer");
80100137:	83 ec 08             	sub    $0x8,%esp
8010013a:	68 78 66 10 80       	push   $0x80106678
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 94 39 00 00       	call   80103adc <initsleeplock>
    bcache.head.next->prev = b;
80100148:	a1 10 fd 10 80       	mov    0x8010fd10,%eax
8010014d:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
80100150:	89 1d 10 fd 10 80    	mov    %ebx,0x8010fd10
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100156:	81 c3 5c 02 00 00    	add    $0x25c,%ebx
8010015c:	83 c4 10             	add    $0x10,%esp
8010015f:	81 fb bc fc 10 80    	cmp    $0x8010fcbc,%ebx
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
801001a8:	e8 ec 39 00 00       	call   80103b99 <holdingsleep>
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
801001cb:	68 7f 66 10 80       	push   $0x8010667f
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
801001e4:	e8 b0 39 00 00       	call   80103b99 <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 65 39 00 00       	call   80103b5e <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100200:	e8 1e 3b 00 00       	call   80103d23 <acquire>
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
80100227:	a1 10 fd 10 80       	mov    0x8010fd10,%eax
8010022c:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
8010022f:	c7 43 50 bc fc 10 80 	movl   $0x8010fcbc,0x50(%ebx)
    bcache.head.next->prev = b;
80100236:	a1 10 fd 10 80       	mov    0x8010fd10,%eax
8010023b:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
8010023e:	89 1d 10 fd 10 80    	mov    %ebx,0x8010fd10
  }
  
  release(&bcache.lock);
80100244:	83 ec 0c             	sub    $0xc,%esp
80100247:	68 c0 b5 10 80       	push   $0x8010b5c0
8010024c:	e8 37 3b 00 00       	call   80103d88 <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 86 66 10 80       	push   $0x80106686
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
80100283:	c7 04 24 20 a5 10 80 	movl   $0x8010a520,(%esp)
8010028a:	e8 94 3a 00 00       	call   80103d23 <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 20 a9 14 80       	mov    0x8014a920,%eax
8010029f:	3b 05 24 a9 14 80    	cmp    0x8014a924,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 16 30 00 00       	call   801032c2 <myproc>
801002ac:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801002b0:	75 17                	jne    801002c9 <consoleread+0x61>
        release(&cons.lock);
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
801002b2:	83 ec 08             	sub    $0x8,%esp
801002b5:	68 20 a5 10 80       	push   $0x8010a520
801002ba:	68 20 a9 14 80       	push   $0x8014a920
801002bf:	e8 d7 34 00 00       	call   8010379b <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 a5 10 80       	push   $0x8010a520
801002d1:	e8 b2 3a 00 00       	call   80103d88 <release>
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
801002f1:	89 15 20 a9 14 80    	mov    %edx,0x8014a920
801002f7:	89 c2                	mov    %eax,%edx
801002f9:	83 e2 7f             	and    $0x7f,%edx
801002fc:	0f b6 8a a0 a8 14 80 	movzbl -0x7feb5760(%edx),%ecx
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
80100324:	a3 20 a9 14 80       	mov    %eax,0x8014a920
  release(&cons.lock);
80100329:	83 ec 0c             	sub    $0xc,%esp
8010032c:	68 20 a5 10 80       	push   $0x8010a520
80100331:	e8 52 3a 00 00       	call   80103d88 <release>
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
80100350:	c7 05 54 a5 10 80 00 	movl   $0x0,0x8010a554
80100357:	00 00 00 
  cprintf("lapicid %d: panic: ", lapicid());
8010035a:	e8 cd 20 00 00       	call   8010242c <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 8d 66 10 80       	push   $0x8010668d
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 db 6f 10 80 	movl   $0x80106fdb,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 6e 38 00 00       	call   80103c02 <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 a1 66 10 80       	push   $0x801066a1
801003aa:	e8 5c 02 00 00       	call   8010060b <cprintf>
  for(i=0; i<10; i++)
801003af:	83 c3 01             	add    $0x1,%ebx
801003b2:	83 c4 10             	add    $0x10,%esp
801003b5:	83 fb 09             	cmp    $0x9,%ebx
801003b8:	7e e4                	jle    8010039e <panic+0x56>
  panicked = 1; // freeze other CPU
801003ba:	c7 05 58 a5 10 80 01 	movl   $0x1,0x8010a558
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
8010049e:	68 a5 66 10 80       	push   $0x801066a5
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 8b 39 00 00       	call   80103e4a <memmove>
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
801004d9:	e8 f1 38 00 00       	call   80103dcf <memset>
801004de:	83 c4 10             	add    $0x10,%esp
801004e1:	e9 4c ff ff ff       	jmp    80100432 <cgaputc+0x6c>

801004e6 <consputc>:
  if(panicked){
801004e6:	83 3d 58 a5 10 80 00 	cmpl   $0x0,0x8010a558
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
80100506:	e8 fe 4c 00 00       	call   80105209 <uartputc>
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
8010051f:	e8 e5 4c 00 00       	call   80105209 <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 d9 4c 00 00       	call   80105209 <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 cd 4c 00 00       	call   80105209 <uartputc>
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
80100576:	0f b6 92 d0 66 10 80 	movzbl -0x7fef9930(%edx),%edx
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
801005c3:	c7 04 24 20 a5 10 80 	movl   $0x8010a520,(%esp)
801005ca:	e8 54 37 00 00       	call   80103d23 <acquire>
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
801005ec:	68 20 a5 10 80       	push   $0x8010a520
801005f1:	e8 92 37 00 00       	call   80103d88 <release>
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
80100614:	a1 54 a5 10 80       	mov    0x8010a554,%eax
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
80100633:	68 20 a5 10 80       	push   $0x8010a520
80100638:	e8 e6 36 00 00       	call   80103d23 <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 bf 66 10 80       	push   $0x801066bf
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
801006ee:	be b8 66 10 80       	mov    $0x801066b8,%esi
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
8010072f:	68 20 a5 10 80       	push   $0x8010a520
80100734:	e8 4f 36 00 00       	call   80103d88 <release>
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
8010074a:	68 20 a5 10 80       	push   $0x8010a520
8010074f:	e8 cf 35 00 00       	call   80103d23 <acquire>
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
80100772:	a1 28 a9 14 80       	mov    0x8014a928,%eax
80100777:	89 c2                	mov    %eax,%edx
80100779:	2b 15 20 a9 14 80    	sub    0x8014a920,%edx
8010077f:	83 fa 7f             	cmp    $0x7f,%edx
80100782:	0f 87 9e 00 00 00    	ja     80100826 <consoleintr+0xe8>
        c = (c == '\r') ? '\n' : c;
80100788:	83 ff 0d             	cmp    $0xd,%edi
8010078b:	0f 84 86 00 00 00    	je     80100817 <consoleintr+0xd9>
        input.buf[input.e++ % INPUT_BUF] = c;
80100791:	8d 50 01             	lea    0x1(%eax),%edx
80100794:	89 15 28 a9 14 80    	mov    %edx,0x8014a928
8010079a:	83 e0 7f             	and    $0x7f,%eax
8010079d:	89 f9                	mov    %edi,%ecx
8010079f:	88 88 a0 a8 14 80    	mov    %cl,-0x7feb5760(%eax)
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
801007bc:	a1 20 a9 14 80       	mov    0x8014a920,%eax
801007c1:	83 e8 80             	sub    $0xffffff80,%eax
801007c4:	39 05 28 a9 14 80    	cmp    %eax,0x8014a928
801007ca:	75 5a                	jne    80100826 <consoleintr+0xe8>
          input.w = input.e;
801007cc:	a1 28 a9 14 80       	mov    0x8014a928,%eax
801007d1:	a3 24 a9 14 80       	mov    %eax,0x8014a924
          wakeup(&input.r);
801007d6:	83 ec 0c             	sub    $0xc,%esp
801007d9:	68 20 a9 14 80       	push   $0x8014a920
801007de:	e8 37 31 00 00       	call   8010391a <wakeup>
801007e3:	83 c4 10             	add    $0x10,%esp
801007e6:	eb 3e                	jmp    80100826 <consoleintr+0xe8>
        input.e--;
801007e8:	a3 28 a9 14 80       	mov    %eax,0x8014a928
        consputc(BACKSPACE);
801007ed:	b8 00 01 00 00       	mov    $0x100,%eax
801007f2:	e8 ef fc ff ff       	call   801004e6 <consputc>
      while(input.e != input.w &&
801007f7:	a1 28 a9 14 80       	mov    0x8014a928,%eax
801007fc:	3b 05 24 a9 14 80    	cmp    0x8014a924,%eax
80100802:	74 22                	je     80100826 <consoleintr+0xe8>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100804:	83 e8 01             	sub    $0x1,%eax
80100807:	89 c2                	mov    %eax,%edx
80100809:	83 e2 7f             	and    $0x7f,%edx
      while(input.e != input.w &&
8010080c:	80 ba a0 a8 14 80 0a 	cmpb   $0xa,-0x7feb5760(%edx)
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
8010084a:	a1 28 a9 14 80       	mov    0x8014a928,%eax
8010084f:	3b 05 24 a9 14 80    	cmp    0x8014a924,%eax
80100855:	74 cf                	je     80100826 <consoleintr+0xe8>
        input.e--;
80100857:	83 e8 01             	sub    $0x1,%eax
8010085a:	a3 28 a9 14 80       	mov    %eax,0x8014a928
        consputc(BACKSPACE);
8010085f:	b8 00 01 00 00       	mov    $0x100,%eax
80100864:	e8 7d fc ff ff       	call   801004e6 <consputc>
80100869:	eb bb                	jmp    80100826 <consoleintr+0xe8>
  release(&cons.lock);
8010086b:	83 ec 0c             	sub    $0xc,%esp
8010086e:	68 20 a5 10 80       	push   $0x8010a520
80100873:	e8 10 35 00 00       	call   80103d88 <release>
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
80100887:	e8 9e 31 00 00       	call   80103a2a <procdump>
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
80100894:	68 c8 66 10 80       	push   $0x801066c8
80100899:	68 20 a5 10 80       	push   $0x8010a520
8010089e:	e8 44 33 00 00       	call   80103be7 <initlock>

  devsw[CONSOLE].write = consolewrite;
801008a3:	c7 05 ec b2 16 80 ac 	movl   $0x801005ac,0x8016b2ec
801008aa:	05 10 80 
  devsw[CONSOLE].read = consoleread;
801008ad:	c7 05 e8 b2 16 80 68 	movl   $0x80100268,0x8016b2e8
801008b4:	02 10 80 
  cons.locking = 1;
801008b7:	c7 05 54 a5 10 80 01 	movl   $0x1,0x8010a554
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
801008de:	e8 df 29 00 00       	call   801032c2 <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 6e 1f 00 00       	call   8010285c <begin_op>

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
80100935:	e8 9c 1f 00 00       	call   801028d6 <end_op>
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
8010094a:	e8 87 1f 00 00       	call   801028d6 <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 e1 66 10 80       	push   $0x801066e1
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
80100972:	e8 6d 5a 00 00       	call   801063e4 <setupkvm>
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
80100a06:	e8 71 58 00 00       	call   8010627c <allocuvm>
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
80100a38:	e8 0d 57 00 00       	call   8010614a <loaduvm>
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
80100a53:	e8 7e 1e 00 00       	call   801028d6 <end_op>
  sz = PGROUNDUP(sz);
80100a58:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100a63:	83 c4 0c             	add    $0xc,%esp
80100a66:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a6c:	52                   	push   %edx
80100a6d:	50                   	push   %eax
80100a6e:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a74:	e8 03 58 00 00       	call   8010627c <allocuvm>
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
80100a9d:	e8 d2 58 00 00       	call   80106374 <freevm>
80100aa2:	83 c4 10             	add    $0x10,%esp
80100aa5:	e9 7a fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aaa:	89 c7                	mov    %eax,%edi
80100aac:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100ab2:	83 ec 08             	sub    $0x8,%esp
80100ab5:	50                   	push   %eax
80100ab6:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100abc:	e8 b0 59 00 00       	call   80106471 <clearpteu>
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
80100ae2:	e8 8a 34 00 00       	call   80103f71 <strlen>
80100ae7:	29 c7                	sub    %eax,%edi
80100ae9:	83 ef 01             	sub    $0x1,%edi
80100aec:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100aef:	83 c4 04             	add    $0x4,%esp
80100af2:	ff 36                	pushl  (%esi)
80100af4:	e8 78 34 00 00       	call   80103f71 <strlen>
80100af9:	83 c0 01             	add    $0x1,%eax
80100afc:	50                   	push   %eax
80100afd:	ff 36                	pushl  (%esi)
80100aff:	57                   	push   %edi
80100b00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b06:	e8 c2 5a 00 00       	call   801065cd <copyout>
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
80100b66:	e8 62 5a 00 00       	call   801065cd <copyout>
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
80100ba3:	e8 8e 33 00 00       	call   80103f36 <safestrcpy>
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
80100bd1:	e8 ee 53 00 00       	call   80105fc4 <switchuvm>
  freevm(oldpgdir);
80100bd6:	89 1c 24             	mov    %ebx,(%esp)
80100bd9:	e8 96 57 00 00       	call   80106374 <freevm>
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
80100c19:	68 ed 66 10 80       	push   $0x801066ed
80100c1e:	68 40 a9 16 80       	push   $0x8016a940
80100c23:	e8 bf 2f 00 00       	call   80103be7 <initlock>
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
80100c34:	68 40 a9 16 80       	push   $0x8016a940
80100c39:	e8 e5 30 00 00       	call   80103d23 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c3e:	83 c4 10             	add    $0x10,%esp
80100c41:	bb 74 a9 16 80       	mov    $0x8016a974,%ebx
80100c46:	81 fb d4 b2 16 80    	cmp    $0x8016b2d4,%ebx
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
80100c63:	68 40 a9 16 80       	push   $0x8016a940
80100c68:	e8 1b 31 00 00       	call   80103d88 <release>
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
80100c7a:	68 40 a9 16 80       	push   $0x8016a940
80100c7f:	e8 04 31 00 00       	call   80103d88 <release>
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
80100c98:	68 40 a9 16 80       	push   $0x8016a940
80100c9d:	e8 81 30 00 00       	call   80103d23 <acquire>
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
80100cb5:	68 40 a9 16 80       	push   $0x8016a940
80100cba:	e8 c9 30 00 00       	call   80103d88 <release>
  return f;
}
80100cbf:	89 d8                	mov    %ebx,%eax
80100cc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cc4:	c9                   	leave  
80100cc5:	c3                   	ret    
    panic("filedup");
80100cc6:	83 ec 0c             	sub    $0xc,%esp
80100cc9:	68 f4 66 10 80       	push   $0x801066f4
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
80100cdd:	68 40 a9 16 80       	push   $0x8016a940
80100ce2:	e8 3c 30 00 00       	call   80103d23 <acquire>
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
80100cfe:	68 40 a9 16 80       	push   $0x8016a940
80100d03:	e8 80 30 00 00       	call   80103d88 <release>
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
80100d13:	68 fc 66 10 80       	push   $0x801066fc
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
80100d44:	68 40 a9 16 80       	push   $0x8016a940
80100d49:	e8 3a 30 00 00       	call   80103d88 <release>
  if(ff.type == FD_PIPE)
80100d4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d51:	83 c4 10             	add    $0x10,%esp
80100d54:	83 f8 01             	cmp    $0x1,%eax
80100d57:	74 1f                	je     80100d78 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d59:	83 f8 02             	cmp    $0x2,%eax
80100d5c:	75 ad                	jne    80100d0b <fileclose+0x38>
    begin_op();
80100d5e:	e8 f9 1a 00 00       	call   8010285c <begin_op>
    iput(ff.ip);
80100d63:	83 ec 0c             	sub    $0xc,%esp
80100d66:	ff 75 f0             	pushl  -0x10(%ebp)
80100d69:	e8 1a 09 00 00       	call   80101688 <iput>
    end_op();
80100d6e:	e8 63 1b 00 00       	call   801028d6 <end_op>
80100d73:	83 c4 10             	add    $0x10,%esp
80100d76:	eb 93                	jmp    80100d0b <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d78:	83 ec 08             	sub    $0x8,%esp
80100d7b:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d7f:	50                   	push   %eax
80100d80:	ff 75 ec             	pushl  -0x14(%ebp)
80100d83:	e8 48 21 00 00       	call   80102ed0 <pipeclose>
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
80100e3c:	e8 e7 21 00 00       	call   80103028 <piperead>
80100e41:	89 c6                	mov    %eax,%esi
80100e43:	83 c4 10             	add    $0x10,%esp
80100e46:	eb df                	jmp    80100e27 <fileread+0x50>
  panic("fileread");
80100e48:	83 ec 0c             	sub    $0xc,%esp
80100e4b:	68 06 67 10 80       	push   $0x80106706
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
80100e95:	e8 c2 20 00 00       	call   80102f5c <pipewrite>
80100e9a:	83 c4 10             	add    $0x10,%esp
80100e9d:	e9 80 00 00 00       	jmp    80100f22 <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100ea2:	e8 b5 19 00 00       	call   8010285c <begin_op>
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
80100edd:	e8 f4 19 00 00       	call   801028d6 <end_op>

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
80100f10:	68 0f 67 10 80       	push   $0x8010670f
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
80100f2d:	68 15 67 10 80       	push   $0x80106715
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
80100f8a:	e8 bb 2e 00 00       	call   80103e4a <memmove>
80100f8f:	83 c4 10             	add    $0x10,%esp
80100f92:	eb 17                	jmp    80100fab <skipelem+0x66>
  else {
    memmove(name, s, len);
80100f94:	83 ec 04             	sub    $0x4,%esp
80100f97:	56                   	push   %esi
80100f98:	50                   	push   %eax
80100f99:	57                   	push   %edi
80100f9a:	e8 ab 2e 00 00       	call   80103e4a <memmove>
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
80100fdf:	e8 eb 2d 00 00       	call   80103dcf <memset>
  log_write(bp);
80100fe4:	89 1c 24             	mov    %ebx,(%esp)
80100fe7:	e8 99 19 00 00       	call   80102985 <log_write>
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
80101023:	39 35 40 b3 16 80    	cmp    %esi,0x8016b340
80101029:	76 75                	jbe    801010a0 <balloc+0xa4>
    bp = bread(dev, BBLOCK(b, sb));
8010102b:	8d 86 ff 0f 00 00    	lea    0xfff(%esi),%eax
80101031:	85 f6                	test   %esi,%esi
80101033:	0f 49 c6             	cmovns %esi,%eax
80101036:	c1 f8 0c             	sar    $0xc,%eax
80101039:	03 05 58 b3 16 80    	add    0x8016b358,%eax
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
80101063:	3b 1d 40 b3 16 80    	cmp    0x8016b340,%ebx
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
801010a3:	68 1f 67 10 80       	push   $0x8010671f
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
801010bf:	e8 c1 18 00 00       	call   80102985 <log_write>
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
80101170:	e8 10 18 00 00       	call   80102985 <log_write>
80101175:	83 c4 10             	add    $0x10,%esp
80101178:	eb bf                	jmp    80101139 <bmap+0x58>
  panic("bmap: out of range");
8010117a:	83 ec 0c             	sub    $0xc,%esp
8010117d:	68 35 67 10 80       	push   $0x80106735
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
80101195:	68 60 b3 16 80       	push   $0x8016b360
8010119a:	e8 84 2b 00 00       	call   80103d23 <acquire>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010119f:	83 c4 10             	add    $0x10,%esp
  empty = 0;
801011a2:	be 00 00 00 00       	mov    $0x0,%esi
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011a7:	bb 94 b3 16 80       	mov    $0x8016b394,%ebx
801011ac:	eb 0a                	jmp    801011b8 <iget+0x31>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801011ae:	85 f6                	test   %esi,%esi
801011b0:	74 3b                	je     801011ed <iget+0x66>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011b2:	81 c3 90 00 00 00    	add    $0x90,%ebx
801011b8:	81 fb b4 cf 16 80    	cmp    $0x8016cfb4,%ebx
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
801011dc:	68 60 b3 16 80       	push   $0x8016b360
801011e1:	e8 a2 2b 00 00       	call   80103d88 <release>
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
80101212:	68 60 b3 16 80       	push   $0x8016b360
80101217:	e8 6c 2b 00 00       	call   80103d88 <release>
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
8010122c:	68 48 67 10 80       	push   $0x80106748
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
80101255:	e8 f0 2b 00 00       	call   80103e4a <memmove>
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
80101276:	68 40 b3 16 80       	push   $0x8016b340
8010127b:	50                   	push   %eax
8010127c:	e8 b5 ff ff ff       	call   80101236 <readsb>
  bp = bread(dev, BBLOCK(b, sb));
80101281:	89 d8                	mov    %ebx,%eax
80101283:	c1 e8 0c             	shr    $0xc,%eax
80101286:	03 05 58 b3 16 80    	add    0x8016b358,%eax
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
801012c8:	e8 b8 16 00 00       	call   80102985 <log_write>
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
801012e2:	68 58 67 10 80       	push   $0x80106758
801012e7:	e8 5c f0 ff ff       	call   80100348 <panic>

801012ec <iinit>:
{
801012ec:	55                   	push   %ebp
801012ed:	89 e5                	mov    %esp,%ebp
801012ef:	53                   	push   %ebx
801012f0:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012f3:	68 6b 67 10 80       	push   $0x8010676b
801012f8:	68 60 b3 16 80       	push   $0x8016b360
801012fd:	e8 e5 28 00 00       	call   80103be7 <initlock>
  for(i = 0; i < NINODE; i++) {
80101302:	83 c4 10             	add    $0x10,%esp
80101305:	bb 00 00 00 00       	mov    $0x0,%ebx
8010130a:	eb 21                	jmp    8010132d <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
8010130c:	83 ec 08             	sub    $0x8,%esp
8010130f:	68 72 67 10 80       	push   $0x80106772
80101314:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101317:	89 d0                	mov    %edx,%eax
80101319:	c1 e0 04             	shl    $0x4,%eax
8010131c:	05 a0 b3 16 80       	add    $0x8016b3a0,%eax
80101321:	50                   	push   %eax
80101322:	e8 b5 27 00 00       	call   80103adc <initsleeplock>
  for(i = 0; i < NINODE; i++) {
80101327:	83 c3 01             	add    $0x1,%ebx
8010132a:	83 c4 10             	add    $0x10,%esp
8010132d:	83 fb 31             	cmp    $0x31,%ebx
80101330:	7e da                	jle    8010130c <iinit+0x20>
  readsb(dev, &sb);
80101332:	83 ec 08             	sub    $0x8,%esp
80101335:	68 40 b3 16 80       	push   $0x8016b340
8010133a:	ff 75 08             	pushl  0x8(%ebp)
8010133d:	e8 f4 fe ff ff       	call   80101236 <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d\
80101342:	ff 35 58 b3 16 80    	pushl  0x8016b358
80101348:	ff 35 54 b3 16 80    	pushl  0x8016b354
8010134e:	ff 35 50 b3 16 80    	pushl  0x8016b350
80101354:	ff 35 4c b3 16 80    	pushl  0x8016b34c
8010135a:	ff 35 48 b3 16 80    	pushl  0x8016b348
80101360:	ff 35 44 b3 16 80    	pushl  0x8016b344
80101366:	ff 35 40 b3 16 80    	pushl  0x8016b340
8010136c:	68 d8 67 10 80       	push   $0x801067d8
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
80101395:	39 1d 48 b3 16 80    	cmp    %ebx,0x8016b348
8010139b:	76 3f                	jbe    801013dc <ialloc+0x5e>
    bp = bread(dev, IBLOCK(inum, sb));
8010139d:	89 d8                	mov    %ebx,%eax
8010139f:	c1 e8 03             	shr    $0x3,%eax
801013a2:	03 05 54 b3 16 80    	add    0x8016b354,%eax
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
801013df:	68 78 67 10 80       	push   $0x80106778
801013e4:	e8 5f ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013e9:	83 ec 04             	sub    $0x4,%esp
801013ec:	6a 40                	push   $0x40
801013ee:	6a 00                	push   $0x0
801013f0:	57                   	push   %edi
801013f1:	e8 d9 29 00 00       	call   80103dcf <memset>
      dip->type = type;
801013f6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801013fa:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
801013fd:	89 34 24             	mov    %esi,(%esp)
80101400:	e8 80 15 00 00       	call   80102985 <log_write>
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
8010142e:	03 05 54 b3 16 80    	add    0x8016b354,%eax
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
80101480:	e8 c5 29 00 00       	call   80103e4a <memmove>
  log_write(bp);
80101485:	89 34 24             	mov    %esi,(%esp)
80101488:	e8 f8 14 00 00       	call   80102985 <log_write>
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
8010155b:	68 60 b3 16 80       	push   $0x8016b360
80101560:	e8 be 27 00 00       	call   80103d23 <acquire>
  ip->ref++;
80101565:	8b 43 08             	mov    0x8(%ebx),%eax
80101568:	83 c0 01             	add    $0x1,%eax
8010156b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010156e:	c7 04 24 60 b3 16 80 	movl   $0x8016b360,(%esp)
80101575:	e8 0e 28 00 00       	call   80103d88 <release>
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
8010159a:	e8 70 25 00 00       	call   80103b0f <acquiresleep>
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
801015b2:	68 8a 67 10 80       	push   $0x8010678a
801015b7:	e8 8c ed ff ff       	call   80100348 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
801015bc:	8b 43 04             	mov    0x4(%ebx),%eax
801015bf:	c1 e8 03             	shr    $0x3,%eax
801015c2:	03 05 54 b3 16 80    	add    0x8016b354,%eax
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
80101614:	e8 31 28 00 00       	call   80103e4a <memmove>
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
80101639:	68 90 67 10 80       	push   $0x80106790
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
80101656:	e8 3e 25 00 00       	call   80103b99 <holdingsleep>
8010165b:	83 c4 10             	add    $0x10,%esp
8010165e:	85 c0                	test   %eax,%eax
80101660:	74 19                	je     8010167b <iunlock+0x38>
80101662:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101666:	7e 13                	jle    8010167b <iunlock+0x38>
  releasesleep(&ip->lock);
80101668:	83 ec 0c             	sub    $0xc,%esp
8010166b:	56                   	push   %esi
8010166c:	e8 ed 24 00 00       	call   80103b5e <releasesleep>
}
80101671:	83 c4 10             	add    $0x10,%esp
80101674:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101677:	5b                   	pop    %ebx
80101678:	5e                   	pop    %esi
80101679:	5d                   	pop    %ebp
8010167a:	c3                   	ret    
    panic("iunlock");
8010167b:	83 ec 0c             	sub    $0xc,%esp
8010167e:	68 9f 67 10 80       	push   $0x8010679f
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
80101698:	e8 72 24 00 00       	call   80103b0f <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010169d:	83 c4 10             	add    $0x10,%esp
801016a0:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016a4:	74 07                	je     801016ad <iput+0x25>
801016a6:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016ab:	74 35                	je     801016e2 <iput+0x5a>
  releasesleep(&ip->lock);
801016ad:	83 ec 0c             	sub    $0xc,%esp
801016b0:	56                   	push   %esi
801016b1:	e8 a8 24 00 00       	call   80103b5e <releasesleep>
  acquire(&icache.lock);
801016b6:	c7 04 24 60 b3 16 80 	movl   $0x8016b360,(%esp)
801016bd:	e8 61 26 00 00       	call   80103d23 <acquire>
  ip->ref--;
801016c2:	8b 43 08             	mov    0x8(%ebx),%eax
801016c5:	83 e8 01             	sub    $0x1,%eax
801016c8:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016cb:	c7 04 24 60 b3 16 80 	movl   $0x8016b360,(%esp)
801016d2:	e8 b1 26 00 00       	call   80103d88 <release>
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
801016e5:	68 60 b3 16 80       	push   $0x8016b360
801016ea:	e8 34 26 00 00       	call   80103d23 <acquire>
    int r = ip->ref;
801016ef:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016f2:	c7 04 24 60 b3 16 80 	movl   $0x8016b360,(%esp)
801016f9:	e8 8a 26 00 00       	call   80103d88 <release>
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
801017c4:	8b 04 c5 e0 b2 16 80 	mov    -0x7fe94d20(,%eax,8),%eax
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
8010182a:	e8 1b 26 00 00       	call   80103e4a <memmove>
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
801018c1:	8b 04 c5 e4 b2 16 80 	mov    -0x7fe94d1c(,%eax,8),%eax
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
80101926:	e8 1f 25 00 00       	call   80103e4a <memmove>
    log_write(bp);
8010192b:	89 3c 24             	mov    %edi,(%esp)
8010192e:	e8 52 10 00 00       	call   80102985 <log_write>
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
801019a9:	e8 03 25 00 00       	call   80103eb1 <strncmp>
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
801019d0:	68 a7 67 10 80       	push   $0x801067a7
801019d5:	e8 6e e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019da:	83 ec 0c             	sub    $0xc,%esp
801019dd:	68 b9 67 10 80       	push   $0x801067b9
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
80101a5a:	e8 63 18 00 00       	call   801032c2 <myproc>
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
80101b92:	68 c8 67 10 80       	push   $0x801067c8
80101b97:	e8 ac e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101b9c:	83 ec 04             	sub    $0x4,%esp
80101b9f:	6a 0e                	push   $0xe
80101ba1:	57                   	push   %edi
80101ba2:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101ba5:	8d 45 da             	lea    -0x26(%ebp),%eax
80101ba8:	50                   	push   %eax
80101ba9:	e8 40 23 00 00       	call   80103eee <strncpy>
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
80101bd7:	68 d4 6d 10 80       	push   $0x80106dd4
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
80101ccc:	68 2b 68 10 80       	push   $0x8010682b
80101cd1:	e8 72 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101cd6:	83 ec 0c             	sub    $0xc,%esp
80101cd9:	68 34 68 10 80       	push   $0x80106834
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
80101d06:	68 46 68 10 80       	push   $0x80106846
80101d0b:	68 80 a5 10 80       	push   $0x8010a580
80101d10:	e8 d2 1e 00 00       	call   80103be7 <initlock>
  ioapicenable(IRQ_IDE, ncpu - 1);
80101d15:	83 c4 08             	add    $0x8,%esp
80101d18:	a1 80 d6 16 80       	mov    0x8016d680,%eax
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
80101d5c:	c7 05 60 a5 10 80 01 	movl   $0x1,0x8010a560
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
80101d7b:	68 80 a5 10 80       	push   $0x8010a580
80101d80:	e8 9e 1f 00 00       	call   80103d23 <acquire>

  if((b = idequeue) == 0){
80101d85:	8b 1d 64 a5 10 80    	mov    0x8010a564,%ebx
80101d8b:	83 c4 10             	add    $0x10,%esp
80101d8e:	85 db                	test   %ebx,%ebx
80101d90:	74 48                	je     80101dda <ideintr+0x67>
    release(&idelock);
    return;
  }
  idequeue = b->qnext;
80101d92:	8b 43 58             	mov    0x58(%ebx),%eax
80101d95:	a3 64 a5 10 80       	mov    %eax,0x8010a564

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
80101dad:	e8 68 1b 00 00       	call   8010391a <wakeup>

  // Start disk on next buf in queue.
  if(idequeue != 0)
80101db2:	a1 64 a5 10 80       	mov    0x8010a564,%eax
80101db7:	83 c4 10             	add    $0x10,%esp
80101dba:	85 c0                	test   %eax,%eax
80101dbc:	74 05                	je     80101dc3 <ideintr+0x50>
    idestart(idequeue);
80101dbe:	e8 80 fe ff ff       	call   80101c43 <idestart>

  release(&idelock);
80101dc3:	83 ec 0c             	sub    $0xc,%esp
80101dc6:	68 80 a5 10 80       	push   $0x8010a580
80101dcb:	e8 b8 1f 00 00       	call   80103d88 <release>
80101dd0:	83 c4 10             	add    $0x10,%esp
}
80101dd3:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101dd6:	5b                   	pop    %ebx
80101dd7:	5f                   	pop    %edi
80101dd8:	5d                   	pop    %ebp
80101dd9:	c3                   	ret    
    release(&idelock);
80101dda:	83 ec 0c             	sub    $0xc,%esp
80101ddd:	68 80 a5 10 80       	push   $0x8010a580
80101de2:	e8 a1 1f 00 00       	call   80103d88 <release>
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
80101e1a:	e8 7a 1d 00 00       	call   80103b99 <holdingsleep>
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
80101e36:	83 3d 60 a5 10 80 00 	cmpl   $0x0,0x8010a560
80101e3d:	74 38                	je     80101e77 <iderw+0x6b>
    panic("iderw: ide disk 1 not present");

  acquire(&idelock);  //DOC:acquire-lock
80101e3f:	83 ec 0c             	sub    $0xc,%esp
80101e42:	68 80 a5 10 80       	push   $0x8010a580
80101e47:	e8 d7 1e 00 00       	call   80103d23 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e4c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e53:	83 c4 10             	add    $0x10,%esp
80101e56:	ba 64 a5 10 80       	mov    $0x8010a564,%edx
80101e5b:	eb 2a                	jmp    80101e87 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e5d:	83 ec 0c             	sub    $0xc,%esp
80101e60:	68 4a 68 10 80       	push   $0x8010684a
80101e65:	e8 de e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	68 60 68 10 80       	push   $0x80106860
80101e72:	e8 d1 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e77:	83 ec 0c             	sub    $0xc,%esp
80101e7a:	68 75 68 10 80       	push   $0x80106875
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
80101e8f:	39 1d 64 a5 10 80    	cmp    %ebx,0x8010a564
80101e95:	75 1a                	jne    80101eb1 <iderw+0xa5>
    idestart(b);
80101e97:	89 d8                	mov    %ebx,%eax
80101e99:	e8 a5 fd ff ff       	call   80101c43 <idestart>
80101e9e:	eb 11                	jmp    80101eb1 <iderw+0xa5>

  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
    sleep(b, &idelock);
80101ea0:	83 ec 08             	sub    $0x8,%esp
80101ea3:	68 80 a5 10 80       	push   $0x8010a580
80101ea8:	53                   	push   %ebx
80101ea9:	e8 ed 18 00 00       	call   8010379b <sleep>
80101eae:	83 c4 10             	add    $0x10,%esp
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80101eb1:	8b 03                	mov    (%ebx),%eax
80101eb3:	83 e0 06             	and    $0x6,%eax
80101eb6:	83 f8 02             	cmp    $0x2,%eax
80101eb9:	75 e5                	jne    80101ea0 <iderw+0x94>
  }


  release(&idelock);
80101ebb:	83 ec 0c             	sub    $0xc,%esp
80101ebe:	68 80 a5 10 80       	push   $0x8010a580
80101ec3:	e8 c0 1e 00 00       	call   80103d88 <release>
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
80101ed3:	8b 15 b4 cf 16 80    	mov    0x8016cfb4,%edx
80101ed9:	89 02                	mov    %eax,(%edx)
  return ioapic->data;
80101edb:	a1 b4 cf 16 80       	mov    0x8016cfb4,%eax
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
80101ee8:	8b 0d b4 cf 16 80    	mov    0x8016cfb4,%ecx
80101eee:	89 01                	mov    %eax,(%ecx)
  ioapic->data = data;
80101ef0:	a1 b4 cf 16 80       	mov    0x8016cfb4,%eax
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
80101f03:	c7 05 b4 cf 16 80 00 	movl   $0xfec00000,0x8016cfb4
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
80101f2a:	0f b6 15 e0 d0 16 80 	movzbl 0x8016d0e0,%edx
80101f31:	39 c2                	cmp    %eax,%edx
80101f33:	75 07                	jne    80101f3c <ioapicinit+0x42>
{
80101f35:	bb 00 00 00 00       	mov    $0x0,%ebx
80101f3a:	eb 36                	jmp    80101f72 <ioapicinit+0x78>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80101f3c:	83 ec 0c             	sub    $0xc,%esp
80101f3f:	68 94 68 10 80       	push   $0x80106894
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
  //
  //if(FRAMES[V2P(v)>>12] != 0 && FRAMES[V2P(v)>>12]!=-1){
  //  return;
  //} 
  FRAMES[V2P(v)>>12] = -1;
80101fae:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80101fb4:	89 c2                	mov    %eax,%edx
80101fb6:	c1 ea 0c             	shr    $0xc,%edx
80101fb9:	c7 04 95 20 ff 10 80 	movl   $0xffffffff,-0x7fef00e0(,%edx,4)
80101fc0:	ff ff ff ff 
  struct run *r;
  //if (V2P(v)>>12 == 57341)
  //  cprintf("***************kfree phy frame: %d, pid: %d\n", V2P(v)>>12, FRAMES[V2P(v)>>12]);
  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80101fc4:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
80101fca:	75 46                	jne    80102012 <kfree+0x6e>
80101fcc:	81 fb 28 df 35 80    	cmp    $0x8035df28,%ebx
80101fd2:	72 3e                	jb     80102012 <kfree+0x6e>
80101fd4:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80101fd9:	77 37                	ja     80102012 <kfree+0x6e>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80101fdb:	83 ec 04             	sub    $0x4,%esp
80101fde:	68 00 10 00 00       	push   $0x1000
80101fe3:	6a 01                	push   $0x1
80101fe5:	53                   	push   %ebx
80101fe6:	e8 e4 1d 00 00       	call   80103dcf <memset>

  if(kmem.use_lock)
80101feb:	83 c4 10             	add    $0x10,%esp
80101fee:	83 3d f4 cf 16 80 00 	cmpl   $0x0,0x8016cff4
80101ff5:	75 28                	jne    8010201f <kfree+0x7b>
    acquire(&kmem.lock);
  r = (struct run*)v;
  r->next = kmem.freelist;
80101ff7:	a1 f8 cf 16 80       	mov    0x8016cff8,%eax
80101ffc:	89 03                	mov    %eax,(%ebx)
  kmem.freelist = r;
80101ffe:	89 1d f8 cf 16 80    	mov    %ebx,0x8016cff8
  if(kmem.use_lock)
80102004:	83 3d f4 cf 16 80 00 	cmpl   $0x0,0x8016cff4
8010200b:	75 24                	jne    80102031 <kfree+0x8d>
    release(&kmem.lock);
}
8010200d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102010:	c9                   	leave  
80102011:	c3                   	ret    
    panic("kfree");
80102012:	83 ec 0c             	sub    $0xc,%esp
80102015:	68 c6 68 10 80       	push   $0x801068c6
8010201a:	e8 29 e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
8010201f:	83 ec 0c             	sub    $0xc,%esp
80102022:	68 c0 cf 16 80       	push   $0x8016cfc0
80102027:	e8 f7 1c 00 00       	call   80103d23 <acquire>
8010202c:	83 c4 10             	add    $0x10,%esp
8010202f:	eb c6                	jmp    80101ff7 <kfree+0x53>
    release(&kmem.lock);
80102031:	83 ec 0c             	sub    $0xc,%esp
80102034:	68 c0 cf 16 80       	push   $0x8016cfc0
80102039:	e8 4a 1d 00 00       	call   80103d88 <release>
8010203e:	83 c4 10             	add    $0x10,%esp
}
80102041:	eb ca                	jmp    8010200d <kfree+0x69>

80102043 <freerange>:
{
80102043:	55                   	push   %ebp
80102044:	89 e5                	mov    %esp,%ebp
80102046:	56                   	push   %esi
80102047:	53                   	push   %ebx
80102048:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  p = (char*)PGROUNDUP((uint)vstart);
8010204b:	8b 45 08             	mov    0x8(%ebp),%eax
8010204e:	05 ff 0f 00 00       	add    $0xfff,%eax
80102053:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE){
80102058:	eb 02                	jmp    8010205c <freerange+0x19>
{
8010205a:	89 f0                	mov    %esi,%eax
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE){
8010205c:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
80102062:	39 de                	cmp    %ebx,%esi
80102064:	77 13                	ja     80102079 <freerange+0x36>
    if((V2P(p)>>12)%2 == 0) continue;
80102066:	f6 c4 10             	test   $0x10,%ah
80102069:	74 ef                	je     8010205a <freerange+0x17>
    kfree(p);
8010206b:	83 ec 0c             	sub    $0xc,%esp
8010206e:	50                   	push   %eax
8010206f:	e8 30 ff ff ff       	call   80101fa4 <kfree>
80102074:	83 c4 10             	add    $0x10,%esp
80102077:	eb e1                	jmp    8010205a <freerange+0x17>
}
80102079:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010207c:	5b                   	pop    %ebx
8010207d:	5e                   	pop    %esi
8010207e:	5d                   	pop    %ebp
8010207f:	c3                   	ret    

80102080 <kinit1>:
{
80102080:	55                   	push   %ebp
80102081:	89 e5                	mov    %esp,%ebp
80102083:	83 ec 10             	sub    $0x10,%esp
  initlock(&kmem.lock, "kmem");
80102086:	68 cc 68 10 80       	push   $0x801068cc
8010208b:	68 c0 cf 16 80       	push   $0x8016cfc0
80102090:	e8 52 1b 00 00       	call   80103be7 <initlock>
  kmem.use_lock = 0;
80102095:	c7 05 f4 cf 16 80 00 	movl   $0x0,0x8016cff4
8010209c:	00 00 00 
  freerange(vstart, vend);
8010209f:	83 c4 08             	add    $0x8,%esp
801020a2:	ff 75 0c             	pushl  0xc(%ebp)
801020a5:	ff 75 08             	pushl  0x8(%ebp)
801020a8:	e8 96 ff ff ff       	call   80102043 <freerange>
}
801020ad:	83 c4 10             	add    $0x10,%esp
801020b0:	c9                   	leave  
801020b1:	c3                   	ret    

801020b2 <kinit2>:
{
801020b2:	55                   	push   %ebp
801020b3:	89 e5                	mov    %esp,%ebp
801020b5:	83 ec 10             	sub    $0x10,%esp
  freerange(vstart, vend);
801020b8:	ff 75 0c             	pushl  0xc(%ebp)
801020bb:	ff 75 08             	pushl  0x8(%ebp)
801020be:	e8 80 ff ff ff       	call   80102043 <freerange>
  kmem.use_lock = 1;
801020c3:	c7 05 f4 cf 16 80 01 	movl   $0x1,0x8016cff4
801020ca:	00 00 00 
}
801020cd:	83 c4 10             	add    $0x10,%esp
801020d0:	c9                   	leave  
801020d1:	c3                   	ret    

801020d2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
801020d2:	55                   	push   %ebp
801020d3:	89 e5                	mov    %esp,%ebp
801020d5:	53                   	push   %ebx
801020d6:	83 ec 04             	sub    $0x4,%esp
  //cprintf("***************************inside kalloc\n");
  struct run *r;

  if(kmem.use_lock)
801020d9:	83 3d f4 cf 16 80 00 	cmpl   $0x0,0x8016cff4
801020e0:	75 35                	jne    80102117 <kalloc+0x45>
    acquire(&kmem.lock);
  r = kmem.freelist;
801020e2:	8b 1d f8 cf 16 80    	mov    0x8016cff8,%ebx
  if(r)
801020e8:	85 db                	test   %ebx,%ebx
801020ea:	74 07                	je     801020f3 <kalloc+0x21>
    kmem.freelist = r->next;
801020ec:	8b 03                	mov    (%ebx),%eax
801020ee:	a3 f8 cf 16 80       	mov    %eax,0x8016cff8
  if(kmem.use_lock)
801020f3:	83 3d f4 cf 16 80 00 	cmpl   $0x0,0x8016cff4
801020fa:	75 2d                	jne    80102129 <kalloc+0x57>
    release(&kmem.lock);
  //cprintf("***************kalloc phy frame: %d\n", V2P((char*)r)>>12);
  FRAMES[V2P((char*)r)>>12] = -2;
801020fc:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80102102:	c1 e8 0c             	shr    $0xc,%eax
80102105:	c7 04 85 20 ff 10 80 	movl   $0xfffffffe,-0x7fef00e0(,%eax,4)
8010210c:	fe ff ff ff 
  return (char*)r;
}
80102110:	89 d8                	mov    %ebx,%eax
80102112:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102115:	c9                   	leave  
80102116:	c3                   	ret    
    acquire(&kmem.lock);
80102117:	83 ec 0c             	sub    $0xc,%esp
8010211a:	68 c0 cf 16 80       	push   $0x8016cfc0
8010211f:	e8 ff 1b 00 00       	call   80103d23 <acquire>
80102124:	83 c4 10             	add    $0x10,%esp
80102127:	eb b9                	jmp    801020e2 <kalloc+0x10>
    release(&kmem.lock);
80102129:	83 ec 0c             	sub    $0xc,%esp
8010212c:	68 c0 cf 16 80       	push   $0x8016cfc0
80102131:	e8 52 1c 00 00       	call   80103d88 <release>
80102136:	83 c4 10             	add    $0x10,%esp
80102139:	eb c1                	jmp    801020fc <kalloc+0x2a>

8010213b <kalloc2>:


// new functions with pid
char*
kalloc2(int pid)
{
8010213b:	55                   	push   %ebp
8010213c:	89 e5                	mov    %esp,%ebp
8010213e:	56                   	push   %esi
8010213f:	53                   	push   %ebx
80102140:	8b 75 08             	mov    0x8(%ebp),%esi
  struct run *r;

  if(kmem.use_lock)
80102143:	83 3d f4 cf 16 80 00 	cmpl   $0x0,0x8016cff4
8010214a:	75 4e                	jne    8010219a <kalloc2+0x5f>
    acquire(&kmem.lock);
  r = kmem.freelist;
8010214c:	8b 1d f8 cf 16 80    	mov    0x8016cff8,%ebx
  if(r)
80102152:	85 db                	test   %ebx,%ebx
80102154:	74 07                	je     8010215d <kalloc2+0x22>
    kmem.freelist = r->next;
80102156:	8b 03                	mov    (%ebx),%eax
80102158:	a3 f8 cf 16 80       	mov    %eax,0x8016cff8
  if(kmem.use_lock)
8010215d:	83 3d f4 cf 16 80 00 	cmpl   $0x0,0x8016cff4
80102164:	75 46                	jne    801021ac <kalloc2+0x71>
    release(&kmem.lock);
  FRAMES[V2P((char*)r)>>12] = pid;
80102166:	8d 93 00 00 00 80    	lea    -0x80000000(%ebx),%edx
8010216c:	c1 ea 0c             	shr    $0xc,%edx
8010216f:	89 34 95 20 ff 10 80 	mov    %esi,-0x7fef00e0(,%edx,4)
  //cprintf("~~~~~~~~log_index: %d, frame: %d, pid: %d\n", log_index, V2P((char*)r)>>12, pid);
  log_frames[log_index] = V2P((char*)r)>>12;
80102176:	a1 2c a9 14 80       	mov    0x8014a92c,%eax
8010217b:	89 14 85 40 a9 14 80 	mov    %edx,-0x7feb56c0(,%eax,4)
  log_pids[log_index] = pid;
80102182:	89 34 85 40 a9 15 80 	mov    %esi,-0x7fea56c0(,%eax,4)
  log_index++;
80102189:	83 c0 01             	add    $0x1,%eax
8010218c:	a3 2c a9 14 80       	mov    %eax,0x8014a92c
  return (char*)r;
}
80102191:	89 d8                	mov    %ebx,%eax
80102193:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102196:	5b                   	pop    %ebx
80102197:	5e                   	pop    %esi
80102198:	5d                   	pop    %ebp
80102199:	c3                   	ret    
    acquire(&kmem.lock);
8010219a:	83 ec 0c             	sub    $0xc,%esp
8010219d:	68 c0 cf 16 80       	push   $0x8016cfc0
801021a2:	e8 7c 1b 00 00       	call   80103d23 <acquire>
801021a7:	83 c4 10             	add    $0x10,%esp
801021aa:	eb a0                	jmp    8010214c <kalloc2+0x11>
    release(&kmem.lock);
801021ac:	83 ec 0c             	sub    $0xc,%esp
801021af:	68 c0 cf 16 80       	push   $0x8016cfc0
801021b4:	e8 cf 1b 00 00       	call   80103d88 <release>
801021b9:	83 c4 10             	add    $0x10,%esp
801021bc:	eb a8                	jmp    80102166 <kalloc2+0x2b>

801021be <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
801021be:	55                   	push   %ebp
801021bf:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801021c1:	ba 64 00 00 00       	mov    $0x64,%edx
801021c6:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
801021c7:	a8 01                	test   $0x1,%al
801021c9:	0f 84 b5 00 00 00    	je     80102284 <kbdgetc+0xc6>
801021cf:	ba 60 00 00 00       	mov    $0x60,%edx
801021d4:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
801021d5:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
801021d8:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
801021de:	74 5c                	je     8010223c <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
801021e0:	84 c0                	test   %al,%al
801021e2:	78 66                	js     8010224a <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
801021e4:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
801021ea:	f6 c1 40             	test   $0x40,%cl
801021ed:	74 0f                	je     801021fe <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
801021ef:	83 c8 80             	or     $0xffffff80,%eax
801021f2:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
801021f5:	83 e1 bf             	and    $0xffffffbf,%ecx
801021f8:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  }

  shift |= shiftcode[data];
801021fe:	0f b6 8a 00 6a 10 80 	movzbl -0x7fef9600(%edx),%ecx
80102205:	0b 0d b4 a5 10 80    	or     0x8010a5b4,%ecx
  shift ^= togglecode[data];
8010220b:	0f b6 82 00 69 10 80 	movzbl -0x7fef9700(%edx),%eax
80102212:	31 c1                	xor    %eax,%ecx
80102214:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  c = charcode[shift & (CTL | SHIFT)][data];
8010221a:	89 c8                	mov    %ecx,%eax
8010221c:	83 e0 03             	and    $0x3,%eax
8010221f:	8b 04 85 e0 68 10 80 	mov    -0x7fef9720(,%eax,4),%eax
80102226:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
8010222a:	f6 c1 08             	test   $0x8,%cl
8010222d:	74 19                	je     80102248 <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
8010222f:	8d 50 9f             	lea    -0x61(%eax),%edx
80102232:	83 fa 19             	cmp    $0x19,%edx
80102235:	77 40                	ja     80102277 <kbdgetc+0xb9>
      c += 'A' - 'a';
80102237:	83 e8 20             	sub    $0x20,%eax
8010223a:	eb 0c                	jmp    80102248 <kbdgetc+0x8a>
    shift |= E0ESC;
8010223c:	83 0d b4 a5 10 80 40 	orl    $0x40,0x8010a5b4
    return 0;
80102243:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
80102248:	5d                   	pop    %ebp
80102249:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
8010224a:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
80102250:	f6 c1 40             	test   $0x40,%cl
80102253:	75 05                	jne    8010225a <kbdgetc+0x9c>
80102255:	89 c2                	mov    %eax,%edx
80102257:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
8010225a:	0f b6 82 00 6a 10 80 	movzbl -0x7fef9600(%edx),%eax
80102261:	83 c8 40             	or     $0x40,%eax
80102264:	0f b6 c0             	movzbl %al,%eax
80102267:	f7 d0                	not    %eax
80102269:	21 c8                	and    %ecx,%eax
8010226b:	a3 b4 a5 10 80       	mov    %eax,0x8010a5b4
    return 0;
80102270:	b8 00 00 00 00       	mov    $0x0,%eax
80102275:	eb d1                	jmp    80102248 <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
80102277:	8d 50 bf             	lea    -0x41(%eax),%edx
8010227a:	83 fa 19             	cmp    $0x19,%edx
8010227d:	77 c9                	ja     80102248 <kbdgetc+0x8a>
      c += 'a' - 'A';
8010227f:	83 c0 20             	add    $0x20,%eax
  return c;
80102282:	eb c4                	jmp    80102248 <kbdgetc+0x8a>
    return -1;
80102284:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102289:	eb bd                	jmp    80102248 <kbdgetc+0x8a>

8010228b <kbdintr>:

void
kbdintr(void)
{
8010228b:	55                   	push   %ebp
8010228c:	89 e5                	mov    %esp,%ebp
8010228e:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
80102291:	68 be 21 10 80       	push   $0x801021be
80102296:	e8 a3 e4 ff ff       	call   8010073e <consoleintr>
}
8010229b:	83 c4 10             	add    $0x10,%esp
8010229e:	c9                   	leave  
8010229f:	c3                   	ret    

801022a0 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
801022a0:	55                   	push   %ebp
801022a1:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
801022a3:	8b 0d fc cf 16 80    	mov    0x8016cffc,%ecx
801022a9:	8d 04 81             	lea    (%ecx,%eax,4),%eax
801022ac:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
801022ae:	a1 fc cf 16 80       	mov    0x8016cffc,%eax
801022b3:	8b 40 20             	mov    0x20(%eax),%eax
}
801022b6:	5d                   	pop    %ebp
801022b7:	c3                   	ret    

801022b8 <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
801022b8:	55                   	push   %ebp
801022b9:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801022bb:	ba 70 00 00 00       	mov    $0x70,%edx
801022c0:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801022c1:	ba 71 00 00 00       	mov    $0x71,%edx
801022c6:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
801022c7:	0f b6 c0             	movzbl %al,%eax
}
801022ca:	5d                   	pop    %ebp
801022cb:	c3                   	ret    

801022cc <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
801022cc:	55                   	push   %ebp
801022cd:	89 e5                	mov    %esp,%ebp
801022cf:	53                   	push   %ebx
801022d0:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
801022d2:	b8 00 00 00 00       	mov    $0x0,%eax
801022d7:	e8 dc ff ff ff       	call   801022b8 <cmos_read>
801022dc:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
801022de:	b8 02 00 00 00       	mov    $0x2,%eax
801022e3:	e8 d0 ff ff ff       	call   801022b8 <cmos_read>
801022e8:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
801022eb:	b8 04 00 00 00       	mov    $0x4,%eax
801022f0:	e8 c3 ff ff ff       	call   801022b8 <cmos_read>
801022f5:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
801022f8:	b8 07 00 00 00       	mov    $0x7,%eax
801022fd:	e8 b6 ff ff ff       	call   801022b8 <cmos_read>
80102302:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
80102305:	b8 08 00 00 00       	mov    $0x8,%eax
8010230a:	e8 a9 ff ff ff       	call   801022b8 <cmos_read>
8010230f:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
80102312:	b8 09 00 00 00       	mov    $0x9,%eax
80102317:	e8 9c ff ff ff       	call   801022b8 <cmos_read>
8010231c:	89 43 14             	mov    %eax,0x14(%ebx)
}
8010231f:	5b                   	pop    %ebx
80102320:	5d                   	pop    %ebp
80102321:	c3                   	ret    

80102322 <lapicinit>:
  if(!lapic)
80102322:	83 3d fc cf 16 80 00 	cmpl   $0x0,0x8016cffc
80102329:	0f 84 fb 00 00 00    	je     8010242a <lapicinit+0x108>
{
8010232f:	55                   	push   %ebp
80102330:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102332:	ba 3f 01 00 00       	mov    $0x13f,%edx
80102337:	b8 3c 00 00 00       	mov    $0x3c,%eax
8010233c:	e8 5f ff ff ff       	call   801022a0 <lapicw>
  lapicw(TDCR, X1);
80102341:	ba 0b 00 00 00       	mov    $0xb,%edx
80102346:	b8 f8 00 00 00       	mov    $0xf8,%eax
8010234b:	e8 50 ff ff ff       	call   801022a0 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102350:	ba 20 00 02 00       	mov    $0x20020,%edx
80102355:	b8 c8 00 00 00       	mov    $0xc8,%eax
8010235a:	e8 41 ff ff ff       	call   801022a0 <lapicw>
  lapicw(TICR, 10000000);
8010235f:	ba 80 96 98 00       	mov    $0x989680,%edx
80102364:	b8 e0 00 00 00       	mov    $0xe0,%eax
80102369:	e8 32 ff ff ff       	call   801022a0 <lapicw>
  lapicw(LINT0, MASKED);
8010236e:	ba 00 00 01 00       	mov    $0x10000,%edx
80102373:	b8 d4 00 00 00       	mov    $0xd4,%eax
80102378:	e8 23 ff ff ff       	call   801022a0 <lapicw>
  lapicw(LINT1, MASKED);
8010237d:	ba 00 00 01 00       	mov    $0x10000,%edx
80102382:	b8 d8 00 00 00       	mov    $0xd8,%eax
80102387:	e8 14 ff ff ff       	call   801022a0 <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
8010238c:	a1 fc cf 16 80       	mov    0x8016cffc,%eax
80102391:	8b 40 30             	mov    0x30(%eax),%eax
80102394:	c1 e8 10             	shr    $0x10,%eax
80102397:	3c 03                	cmp    $0x3,%al
80102399:	77 7b                	ja     80102416 <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
8010239b:	ba 33 00 00 00       	mov    $0x33,%edx
801023a0:	b8 dc 00 00 00       	mov    $0xdc,%eax
801023a5:	e8 f6 fe ff ff       	call   801022a0 <lapicw>
  lapicw(ESR, 0);
801023aa:	ba 00 00 00 00       	mov    $0x0,%edx
801023af:	b8 a0 00 00 00       	mov    $0xa0,%eax
801023b4:	e8 e7 fe ff ff       	call   801022a0 <lapicw>
  lapicw(ESR, 0);
801023b9:	ba 00 00 00 00       	mov    $0x0,%edx
801023be:	b8 a0 00 00 00       	mov    $0xa0,%eax
801023c3:	e8 d8 fe ff ff       	call   801022a0 <lapicw>
  lapicw(EOI, 0);
801023c8:	ba 00 00 00 00       	mov    $0x0,%edx
801023cd:	b8 2c 00 00 00       	mov    $0x2c,%eax
801023d2:	e8 c9 fe ff ff       	call   801022a0 <lapicw>
  lapicw(ICRHI, 0);
801023d7:	ba 00 00 00 00       	mov    $0x0,%edx
801023dc:	b8 c4 00 00 00       	mov    $0xc4,%eax
801023e1:	e8 ba fe ff ff       	call   801022a0 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
801023e6:	ba 00 85 08 00       	mov    $0x88500,%edx
801023eb:	b8 c0 00 00 00       	mov    $0xc0,%eax
801023f0:	e8 ab fe ff ff       	call   801022a0 <lapicw>
  while(lapic[ICRLO] & DELIVS)
801023f5:	a1 fc cf 16 80       	mov    0x8016cffc,%eax
801023fa:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
80102400:	f6 c4 10             	test   $0x10,%ah
80102403:	75 f0                	jne    801023f5 <lapicinit+0xd3>
  lapicw(TPR, 0);
80102405:	ba 00 00 00 00       	mov    $0x0,%edx
8010240a:	b8 20 00 00 00       	mov    $0x20,%eax
8010240f:	e8 8c fe ff ff       	call   801022a0 <lapicw>
}
80102414:	5d                   	pop    %ebp
80102415:	c3                   	ret    
    lapicw(PCINT, MASKED);
80102416:	ba 00 00 01 00       	mov    $0x10000,%edx
8010241b:	b8 d0 00 00 00       	mov    $0xd0,%eax
80102420:	e8 7b fe ff ff       	call   801022a0 <lapicw>
80102425:	e9 71 ff ff ff       	jmp    8010239b <lapicinit+0x79>
8010242a:	f3 c3                	repz ret 

8010242c <lapicid>:
{
8010242c:	55                   	push   %ebp
8010242d:	89 e5                	mov    %esp,%ebp
  if (!lapic)
8010242f:	a1 fc cf 16 80       	mov    0x8016cffc,%eax
80102434:	85 c0                	test   %eax,%eax
80102436:	74 08                	je     80102440 <lapicid+0x14>
  return lapic[ID] >> 24;
80102438:	8b 40 20             	mov    0x20(%eax),%eax
8010243b:	c1 e8 18             	shr    $0x18,%eax
}
8010243e:	5d                   	pop    %ebp
8010243f:	c3                   	ret    
    return 0;
80102440:	b8 00 00 00 00       	mov    $0x0,%eax
80102445:	eb f7                	jmp    8010243e <lapicid+0x12>

80102447 <lapiceoi>:
  if(lapic)
80102447:	83 3d fc cf 16 80 00 	cmpl   $0x0,0x8016cffc
8010244e:	74 14                	je     80102464 <lapiceoi+0x1d>
{
80102450:	55                   	push   %ebp
80102451:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
80102453:	ba 00 00 00 00       	mov    $0x0,%edx
80102458:	b8 2c 00 00 00       	mov    $0x2c,%eax
8010245d:	e8 3e fe ff ff       	call   801022a0 <lapicw>
}
80102462:	5d                   	pop    %ebp
80102463:	c3                   	ret    
80102464:	f3 c3                	repz ret 

80102466 <microdelay>:
{
80102466:	55                   	push   %ebp
80102467:	89 e5                	mov    %esp,%ebp
}
80102469:	5d                   	pop    %ebp
8010246a:	c3                   	ret    

8010246b <lapicstartap>:
{
8010246b:	55                   	push   %ebp
8010246c:	89 e5                	mov    %esp,%ebp
8010246e:	57                   	push   %edi
8010246f:	56                   	push   %esi
80102470:	53                   	push   %ebx
80102471:	8b 75 08             	mov    0x8(%ebp),%esi
80102474:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102477:	b8 0f 00 00 00       	mov    $0xf,%eax
8010247c:	ba 70 00 00 00       	mov    $0x70,%edx
80102481:	ee                   	out    %al,(%dx)
80102482:	b8 0a 00 00 00       	mov    $0xa,%eax
80102487:	ba 71 00 00 00       	mov    $0x71,%edx
8010248c:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
8010248d:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
80102494:	00 00 
  wrv[1] = addr >> 4;
80102496:	89 f8                	mov    %edi,%eax
80102498:	c1 e8 04             	shr    $0x4,%eax
8010249b:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
801024a1:	c1 e6 18             	shl    $0x18,%esi
801024a4:	89 f2                	mov    %esi,%edx
801024a6:	b8 c4 00 00 00       	mov    $0xc4,%eax
801024ab:	e8 f0 fd ff ff       	call   801022a0 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801024b0:	ba 00 c5 00 00       	mov    $0xc500,%edx
801024b5:	b8 c0 00 00 00       	mov    $0xc0,%eax
801024ba:	e8 e1 fd ff ff       	call   801022a0 <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
801024bf:	ba 00 85 00 00       	mov    $0x8500,%edx
801024c4:	b8 c0 00 00 00       	mov    $0xc0,%eax
801024c9:	e8 d2 fd ff ff       	call   801022a0 <lapicw>
  for(i = 0; i < 2; i++){
801024ce:	bb 00 00 00 00       	mov    $0x0,%ebx
801024d3:	eb 21                	jmp    801024f6 <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
801024d5:	89 f2                	mov    %esi,%edx
801024d7:	b8 c4 00 00 00       	mov    $0xc4,%eax
801024dc:	e8 bf fd ff ff       	call   801022a0 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
801024e1:	89 fa                	mov    %edi,%edx
801024e3:	c1 ea 0c             	shr    $0xc,%edx
801024e6:	80 ce 06             	or     $0x6,%dh
801024e9:	b8 c0 00 00 00       	mov    $0xc0,%eax
801024ee:	e8 ad fd ff ff       	call   801022a0 <lapicw>
  for(i = 0; i < 2; i++){
801024f3:	83 c3 01             	add    $0x1,%ebx
801024f6:	83 fb 01             	cmp    $0x1,%ebx
801024f9:	7e da                	jle    801024d5 <lapicstartap+0x6a>
}
801024fb:	5b                   	pop    %ebx
801024fc:	5e                   	pop    %esi
801024fd:	5f                   	pop    %edi
801024fe:	5d                   	pop    %ebp
801024ff:	c3                   	ret    

80102500 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
80102500:	55                   	push   %ebp
80102501:	89 e5                	mov    %esp,%ebp
80102503:	57                   	push   %edi
80102504:	56                   	push   %esi
80102505:	53                   	push   %ebx
80102506:	83 ec 3c             	sub    $0x3c,%esp
80102509:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
8010250c:	b8 0b 00 00 00       	mov    $0xb,%eax
80102511:	e8 a2 fd ff ff       	call   801022b8 <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
80102516:	83 e0 04             	and    $0x4,%eax
80102519:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
8010251b:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010251e:	e8 a9 fd ff ff       	call   801022cc <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
80102523:	b8 0a 00 00 00       	mov    $0xa,%eax
80102528:	e8 8b fd ff ff       	call   801022b8 <cmos_read>
8010252d:	a8 80                	test   $0x80,%al
8010252f:	75 ea                	jne    8010251b <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
80102531:	8d 5d b8             	lea    -0x48(%ebp),%ebx
80102534:	89 d8                	mov    %ebx,%eax
80102536:	e8 91 fd ff ff       	call   801022cc <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
8010253b:	83 ec 04             	sub    $0x4,%esp
8010253e:	6a 18                	push   $0x18
80102540:	53                   	push   %ebx
80102541:	8d 45 d0             	lea    -0x30(%ebp),%eax
80102544:	50                   	push   %eax
80102545:	e8 cb 18 00 00       	call   80103e15 <memcmp>
8010254a:	83 c4 10             	add    $0x10,%esp
8010254d:	85 c0                	test   %eax,%eax
8010254f:	75 ca                	jne    8010251b <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
80102551:	85 ff                	test   %edi,%edi
80102553:	0f 85 84 00 00 00    	jne    801025dd <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
80102559:	8b 55 d0             	mov    -0x30(%ebp),%edx
8010255c:	89 d0                	mov    %edx,%eax
8010255e:	c1 e8 04             	shr    $0x4,%eax
80102561:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102564:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102567:	83 e2 0f             	and    $0xf,%edx
8010256a:	01 d0                	add    %edx,%eax
8010256c:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
8010256f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80102572:	89 d0                	mov    %edx,%eax
80102574:	c1 e8 04             	shr    $0x4,%eax
80102577:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010257a:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010257d:	83 e2 0f             	and    $0xf,%edx
80102580:	01 d0                	add    %edx,%eax
80102582:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
80102585:	8b 55 d8             	mov    -0x28(%ebp),%edx
80102588:	89 d0                	mov    %edx,%eax
8010258a:	c1 e8 04             	shr    $0x4,%eax
8010258d:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102590:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102593:	83 e2 0f             	and    $0xf,%edx
80102596:	01 d0                	add    %edx,%eax
80102598:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
8010259b:	8b 55 dc             	mov    -0x24(%ebp),%edx
8010259e:	89 d0                	mov    %edx,%eax
801025a0:	c1 e8 04             	shr    $0x4,%eax
801025a3:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801025a6:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801025a9:	83 e2 0f             	and    $0xf,%edx
801025ac:	01 d0                	add    %edx,%eax
801025ae:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
801025b1:	8b 55 e0             	mov    -0x20(%ebp),%edx
801025b4:	89 d0                	mov    %edx,%eax
801025b6:	c1 e8 04             	shr    $0x4,%eax
801025b9:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801025bc:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801025bf:	83 e2 0f             	and    $0xf,%edx
801025c2:	01 d0                	add    %edx,%eax
801025c4:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
801025c7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801025ca:	89 d0                	mov    %edx,%eax
801025cc:	c1 e8 04             	shr    $0x4,%eax
801025cf:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801025d2:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801025d5:	83 e2 0f             	and    $0xf,%edx
801025d8:	01 d0                	add    %edx,%eax
801025da:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
801025dd:	8b 45 d0             	mov    -0x30(%ebp),%eax
801025e0:	89 06                	mov    %eax,(%esi)
801025e2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
801025e5:	89 46 04             	mov    %eax,0x4(%esi)
801025e8:	8b 45 d8             	mov    -0x28(%ebp),%eax
801025eb:	89 46 08             	mov    %eax,0x8(%esi)
801025ee:	8b 45 dc             	mov    -0x24(%ebp),%eax
801025f1:	89 46 0c             	mov    %eax,0xc(%esi)
801025f4:	8b 45 e0             	mov    -0x20(%ebp),%eax
801025f7:	89 46 10             	mov    %eax,0x10(%esi)
801025fa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801025fd:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
80102600:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
80102607:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010260a:	5b                   	pop    %ebx
8010260b:	5e                   	pop    %esi
8010260c:	5f                   	pop    %edi
8010260d:	5d                   	pop    %ebp
8010260e:	c3                   	ret    

8010260f <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010260f:	55                   	push   %ebp
80102610:	89 e5                	mov    %esp,%ebp
80102612:	53                   	push   %ebx
80102613:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102616:	ff 35 34 d0 16 80    	pushl  0x8016d034
8010261c:	ff 35 44 d0 16 80    	pushl  0x8016d044
80102622:	e8 45 db ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
80102627:	8b 58 5c             	mov    0x5c(%eax),%ebx
8010262a:	89 1d 48 d0 16 80    	mov    %ebx,0x8016d048
  for (i = 0; i < log.lh.n; i++) {
80102630:	83 c4 10             	add    $0x10,%esp
80102633:	ba 00 00 00 00       	mov    $0x0,%edx
80102638:	eb 0e                	jmp    80102648 <read_head+0x39>
    log.lh.block[i] = lh->block[i];
8010263a:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
8010263e:	89 0c 95 4c d0 16 80 	mov    %ecx,-0x7fe92fb4(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
80102645:	83 c2 01             	add    $0x1,%edx
80102648:	39 d3                	cmp    %edx,%ebx
8010264a:	7f ee                	jg     8010263a <read_head+0x2b>
  }
  brelse(buf);
8010264c:	83 ec 0c             	sub    $0xc,%esp
8010264f:	50                   	push   %eax
80102650:	e8 80 db ff ff       	call   801001d5 <brelse>
}
80102655:	83 c4 10             	add    $0x10,%esp
80102658:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010265b:	c9                   	leave  
8010265c:	c3                   	ret    

8010265d <install_trans>:
{
8010265d:	55                   	push   %ebp
8010265e:	89 e5                	mov    %esp,%ebp
80102660:	57                   	push   %edi
80102661:	56                   	push   %esi
80102662:	53                   	push   %ebx
80102663:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
80102666:	bb 00 00 00 00       	mov    $0x0,%ebx
8010266b:	eb 66                	jmp    801026d3 <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
8010266d:	89 d8                	mov    %ebx,%eax
8010266f:	03 05 34 d0 16 80    	add    0x8016d034,%eax
80102675:	83 c0 01             	add    $0x1,%eax
80102678:	83 ec 08             	sub    $0x8,%esp
8010267b:	50                   	push   %eax
8010267c:	ff 35 44 d0 16 80    	pushl  0x8016d044
80102682:	e8 e5 da ff ff       	call   8010016c <bread>
80102687:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
80102689:	83 c4 08             	add    $0x8,%esp
8010268c:	ff 34 9d 4c d0 16 80 	pushl  -0x7fe92fb4(,%ebx,4)
80102693:	ff 35 44 d0 16 80    	pushl  0x8016d044
80102699:	e8 ce da ff ff       	call   8010016c <bread>
8010269e:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801026a0:	8d 57 5c             	lea    0x5c(%edi),%edx
801026a3:	8d 40 5c             	lea    0x5c(%eax),%eax
801026a6:	83 c4 0c             	add    $0xc,%esp
801026a9:	68 00 02 00 00       	push   $0x200
801026ae:	52                   	push   %edx
801026af:	50                   	push   %eax
801026b0:	e8 95 17 00 00       	call   80103e4a <memmove>
    bwrite(dbuf);  // write dst to disk
801026b5:	89 34 24             	mov    %esi,(%esp)
801026b8:	e8 dd da ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
801026bd:	89 3c 24             	mov    %edi,(%esp)
801026c0:	e8 10 db ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
801026c5:	89 34 24             	mov    %esi,(%esp)
801026c8:	e8 08 db ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
801026cd:	83 c3 01             	add    $0x1,%ebx
801026d0:	83 c4 10             	add    $0x10,%esp
801026d3:	39 1d 48 d0 16 80    	cmp    %ebx,0x8016d048
801026d9:	7f 92                	jg     8010266d <install_trans+0x10>
}
801026db:	8d 65 f4             	lea    -0xc(%ebp),%esp
801026de:	5b                   	pop    %ebx
801026df:	5e                   	pop    %esi
801026e0:	5f                   	pop    %edi
801026e1:	5d                   	pop    %ebp
801026e2:	c3                   	ret    

801026e3 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
801026e3:	55                   	push   %ebp
801026e4:	89 e5                	mov    %esp,%ebp
801026e6:	53                   	push   %ebx
801026e7:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
801026ea:	ff 35 34 d0 16 80    	pushl  0x8016d034
801026f0:	ff 35 44 d0 16 80    	pushl  0x8016d044
801026f6:	e8 71 da ff ff       	call   8010016c <bread>
801026fb:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
801026fd:	8b 0d 48 d0 16 80    	mov    0x8016d048,%ecx
80102703:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
80102706:	83 c4 10             	add    $0x10,%esp
80102709:	b8 00 00 00 00       	mov    $0x0,%eax
8010270e:	eb 0e                	jmp    8010271e <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
80102710:	8b 14 85 4c d0 16 80 	mov    -0x7fe92fb4(,%eax,4),%edx
80102717:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
8010271b:	83 c0 01             	add    $0x1,%eax
8010271e:	39 c1                	cmp    %eax,%ecx
80102720:	7f ee                	jg     80102710 <write_head+0x2d>
  }
  bwrite(buf);
80102722:	83 ec 0c             	sub    $0xc,%esp
80102725:	53                   	push   %ebx
80102726:	e8 6f da ff ff       	call   8010019a <bwrite>
  brelse(buf);
8010272b:	89 1c 24             	mov    %ebx,(%esp)
8010272e:	e8 a2 da ff ff       	call   801001d5 <brelse>
}
80102733:	83 c4 10             	add    $0x10,%esp
80102736:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102739:	c9                   	leave  
8010273a:	c3                   	ret    

8010273b <recover_from_log>:

static void
recover_from_log(void)
{
8010273b:	55                   	push   %ebp
8010273c:	89 e5                	mov    %esp,%ebp
8010273e:	83 ec 08             	sub    $0x8,%esp
  read_head();
80102741:	e8 c9 fe ff ff       	call   8010260f <read_head>
  install_trans(); // if committed, copy from log to disk
80102746:	e8 12 ff ff ff       	call   8010265d <install_trans>
  log.lh.n = 0;
8010274b:	c7 05 48 d0 16 80 00 	movl   $0x0,0x8016d048
80102752:	00 00 00 
  write_head(); // clear the log
80102755:	e8 89 ff ff ff       	call   801026e3 <write_head>
}
8010275a:	c9                   	leave  
8010275b:	c3                   	ret    

8010275c <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
8010275c:	55                   	push   %ebp
8010275d:	89 e5                	mov    %esp,%ebp
8010275f:	57                   	push   %edi
80102760:	56                   	push   %esi
80102761:	53                   	push   %ebx
80102762:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80102765:	bb 00 00 00 00       	mov    $0x0,%ebx
8010276a:	eb 66                	jmp    801027d2 <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
8010276c:	89 d8                	mov    %ebx,%eax
8010276e:	03 05 34 d0 16 80    	add    0x8016d034,%eax
80102774:	83 c0 01             	add    $0x1,%eax
80102777:	83 ec 08             	sub    $0x8,%esp
8010277a:	50                   	push   %eax
8010277b:	ff 35 44 d0 16 80    	pushl  0x8016d044
80102781:	e8 e6 d9 ff ff       	call   8010016c <bread>
80102786:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
80102788:	83 c4 08             	add    $0x8,%esp
8010278b:	ff 34 9d 4c d0 16 80 	pushl  -0x7fe92fb4(,%ebx,4)
80102792:	ff 35 44 d0 16 80    	pushl  0x8016d044
80102798:	e8 cf d9 ff ff       	call   8010016c <bread>
8010279d:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
8010279f:	8d 50 5c             	lea    0x5c(%eax),%edx
801027a2:	8d 46 5c             	lea    0x5c(%esi),%eax
801027a5:	83 c4 0c             	add    $0xc,%esp
801027a8:	68 00 02 00 00       	push   $0x200
801027ad:	52                   	push   %edx
801027ae:	50                   	push   %eax
801027af:	e8 96 16 00 00       	call   80103e4a <memmove>
    bwrite(to);  // write the log
801027b4:	89 34 24             	mov    %esi,(%esp)
801027b7:	e8 de d9 ff ff       	call   8010019a <bwrite>
    brelse(from);
801027bc:	89 3c 24             	mov    %edi,(%esp)
801027bf:	e8 11 da ff ff       	call   801001d5 <brelse>
    brelse(to);
801027c4:	89 34 24             	mov    %esi,(%esp)
801027c7:	e8 09 da ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
801027cc:	83 c3 01             	add    $0x1,%ebx
801027cf:	83 c4 10             	add    $0x10,%esp
801027d2:	39 1d 48 d0 16 80    	cmp    %ebx,0x8016d048
801027d8:	7f 92                	jg     8010276c <write_log+0x10>
  }
}
801027da:	8d 65 f4             	lea    -0xc(%ebp),%esp
801027dd:	5b                   	pop    %ebx
801027de:	5e                   	pop    %esi
801027df:	5f                   	pop    %edi
801027e0:	5d                   	pop    %ebp
801027e1:	c3                   	ret    

801027e2 <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
801027e2:	83 3d 48 d0 16 80 00 	cmpl   $0x0,0x8016d048
801027e9:	7e 26                	jle    80102811 <commit+0x2f>
{
801027eb:	55                   	push   %ebp
801027ec:	89 e5                	mov    %esp,%ebp
801027ee:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
801027f1:	e8 66 ff ff ff       	call   8010275c <write_log>
    write_head();    // Write header to disk -- the real commit
801027f6:	e8 e8 fe ff ff       	call   801026e3 <write_head>
    install_trans(); // Now install writes to home locations
801027fb:	e8 5d fe ff ff       	call   8010265d <install_trans>
    log.lh.n = 0;
80102800:	c7 05 48 d0 16 80 00 	movl   $0x0,0x8016d048
80102807:	00 00 00 
    write_head();    // Erase the transaction from the log
8010280a:	e8 d4 fe ff ff       	call   801026e3 <write_head>
  }
}
8010280f:	c9                   	leave  
80102810:	c3                   	ret    
80102811:	f3 c3                	repz ret 

80102813 <initlog>:
{
80102813:	55                   	push   %ebp
80102814:	89 e5                	mov    %esp,%ebp
80102816:	53                   	push   %ebx
80102817:	83 ec 2c             	sub    $0x2c,%esp
8010281a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
8010281d:	68 00 6b 10 80       	push   $0x80106b00
80102822:	68 00 d0 16 80       	push   $0x8016d000
80102827:	e8 bb 13 00 00       	call   80103be7 <initlock>
  readsb(dev, &sb);
8010282c:	83 c4 08             	add    $0x8,%esp
8010282f:	8d 45 dc             	lea    -0x24(%ebp),%eax
80102832:	50                   	push   %eax
80102833:	53                   	push   %ebx
80102834:	e8 fd e9 ff ff       	call   80101236 <readsb>
  log.start = sb.logstart;
80102839:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010283c:	a3 34 d0 16 80       	mov    %eax,0x8016d034
  log.size = sb.nlog;
80102841:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102844:	a3 38 d0 16 80       	mov    %eax,0x8016d038
  log.dev = dev;
80102849:	89 1d 44 d0 16 80    	mov    %ebx,0x8016d044
  recover_from_log();
8010284f:	e8 e7 fe ff ff       	call   8010273b <recover_from_log>
}
80102854:	83 c4 10             	add    $0x10,%esp
80102857:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010285a:	c9                   	leave  
8010285b:	c3                   	ret    

8010285c <begin_op>:
{
8010285c:	55                   	push   %ebp
8010285d:	89 e5                	mov    %esp,%ebp
8010285f:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
80102862:	68 00 d0 16 80       	push   $0x8016d000
80102867:	e8 b7 14 00 00       	call   80103d23 <acquire>
8010286c:	83 c4 10             	add    $0x10,%esp
8010286f:	eb 15                	jmp    80102886 <begin_op+0x2a>
      sleep(&log, &log.lock);
80102871:	83 ec 08             	sub    $0x8,%esp
80102874:	68 00 d0 16 80       	push   $0x8016d000
80102879:	68 00 d0 16 80       	push   $0x8016d000
8010287e:	e8 18 0f 00 00       	call   8010379b <sleep>
80102883:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
80102886:	83 3d 40 d0 16 80 00 	cmpl   $0x0,0x8016d040
8010288d:	75 e2                	jne    80102871 <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
8010288f:	a1 3c d0 16 80       	mov    0x8016d03c,%eax
80102894:	83 c0 01             	add    $0x1,%eax
80102897:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010289a:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
8010289d:	03 15 48 d0 16 80    	add    0x8016d048,%edx
801028a3:	83 fa 1e             	cmp    $0x1e,%edx
801028a6:	7e 17                	jle    801028bf <begin_op+0x63>
      sleep(&log, &log.lock);
801028a8:	83 ec 08             	sub    $0x8,%esp
801028ab:	68 00 d0 16 80       	push   $0x8016d000
801028b0:	68 00 d0 16 80       	push   $0x8016d000
801028b5:	e8 e1 0e 00 00       	call   8010379b <sleep>
801028ba:	83 c4 10             	add    $0x10,%esp
801028bd:	eb c7                	jmp    80102886 <begin_op+0x2a>
      log.outstanding += 1;
801028bf:	a3 3c d0 16 80       	mov    %eax,0x8016d03c
      release(&log.lock);
801028c4:	83 ec 0c             	sub    $0xc,%esp
801028c7:	68 00 d0 16 80       	push   $0x8016d000
801028cc:	e8 b7 14 00 00       	call   80103d88 <release>
}
801028d1:	83 c4 10             	add    $0x10,%esp
801028d4:	c9                   	leave  
801028d5:	c3                   	ret    

801028d6 <end_op>:
{
801028d6:	55                   	push   %ebp
801028d7:	89 e5                	mov    %esp,%ebp
801028d9:	53                   	push   %ebx
801028da:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
801028dd:	68 00 d0 16 80       	push   $0x8016d000
801028e2:	e8 3c 14 00 00       	call   80103d23 <acquire>
  log.outstanding -= 1;
801028e7:	a1 3c d0 16 80       	mov    0x8016d03c,%eax
801028ec:	83 e8 01             	sub    $0x1,%eax
801028ef:	a3 3c d0 16 80       	mov    %eax,0x8016d03c
  if(log.committing)
801028f4:	8b 1d 40 d0 16 80    	mov    0x8016d040,%ebx
801028fa:	83 c4 10             	add    $0x10,%esp
801028fd:	85 db                	test   %ebx,%ebx
801028ff:	75 2c                	jne    8010292d <end_op+0x57>
  if(log.outstanding == 0){
80102901:	85 c0                	test   %eax,%eax
80102903:	75 35                	jne    8010293a <end_op+0x64>
    log.committing = 1;
80102905:	c7 05 40 d0 16 80 01 	movl   $0x1,0x8016d040
8010290c:	00 00 00 
    do_commit = 1;
8010290f:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
80102914:	83 ec 0c             	sub    $0xc,%esp
80102917:	68 00 d0 16 80       	push   $0x8016d000
8010291c:	e8 67 14 00 00       	call   80103d88 <release>
  if(do_commit){
80102921:	83 c4 10             	add    $0x10,%esp
80102924:	85 db                	test   %ebx,%ebx
80102926:	75 24                	jne    8010294c <end_op+0x76>
}
80102928:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010292b:	c9                   	leave  
8010292c:	c3                   	ret    
    panic("log.committing");
8010292d:	83 ec 0c             	sub    $0xc,%esp
80102930:	68 04 6b 10 80       	push   $0x80106b04
80102935:	e8 0e da ff ff       	call   80100348 <panic>
    wakeup(&log);
8010293a:	83 ec 0c             	sub    $0xc,%esp
8010293d:	68 00 d0 16 80       	push   $0x8016d000
80102942:	e8 d3 0f 00 00       	call   8010391a <wakeup>
80102947:	83 c4 10             	add    $0x10,%esp
8010294a:	eb c8                	jmp    80102914 <end_op+0x3e>
    commit();
8010294c:	e8 91 fe ff ff       	call   801027e2 <commit>
    acquire(&log.lock);
80102951:	83 ec 0c             	sub    $0xc,%esp
80102954:	68 00 d0 16 80       	push   $0x8016d000
80102959:	e8 c5 13 00 00       	call   80103d23 <acquire>
    log.committing = 0;
8010295e:	c7 05 40 d0 16 80 00 	movl   $0x0,0x8016d040
80102965:	00 00 00 
    wakeup(&log);
80102968:	c7 04 24 00 d0 16 80 	movl   $0x8016d000,(%esp)
8010296f:	e8 a6 0f 00 00       	call   8010391a <wakeup>
    release(&log.lock);
80102974:	c7 04 24 00 d0 16 80 	movl   $0x8016d000,(%esp)
8010297b:	e8 08 14 00 00       	call   80103d88 <release>
80102980:	83 c4 10             	add    $0x10,%esp
}
80102983:	eb a3                	jmp    80102928 <end_op+0x52>

80102985 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80102985:	55                   	push   %ebp
80102986:	89 e5                	mov    %esp,%ebp
80102988:	53                   	push   %ebx
80102989:	83 ec 04             	sub    $0x4,%esp
8010298c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
8010298f:	8b 15 48 d0 16 80    	mov    0x8016d048,%edx
80102995:	83 fa 1d             	cmp    $0x1d,%edx
80102998:	7f 45                	jg     801029df <log_write+0x5a>
8010299a:	a1 38 d0 16 80       	mov    0x8016d038,%eax
8010299f:	83 e8 01             	sub    $0x1,%eax
801029a2:	39 c2                	cmp    %eax,%edx
801029a4:	7d 39                	jge    801029df <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
801029a6:	83 3d 3c d0 16 80 00 	cmpl   $0x0,0x8016d03c
801029ad:	7e 3d                	jle    801029ec <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
801029af:	83 ec 0c             	sub    $0xc,%esp
801029b2:	68 00 d0 16 80       	push   $0x8016d000
801029b7:	e8 67 13 00 00       	call   80103d23 <acquire>
  for (i = 0; i < log.lh.n; i++) {
801029bc:	83 c4 10             	add    $0x10,%esp
801029bf:	b8 00 00 00 00       	mov    $0x0,%eax
801029c4:	8b 15 48 d0 16 80    	mov    0x8016d048,%edx
801029ca:	39 c2                	cmp    %eax,%edx
801029cc:	7e 2b                	jle    801029f9 <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
801029ce:	8b 4b 08             	mov    0x8(%ebx),%ecx
801029d1:	39 0c 85 4c d0 16 80 	cmp    %ecx,-0x7fe92fb4(,%eax,4)
801029d8:	74 1f                	je     801029f9 <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
801029da:	83 c0 01             	add    $0x1,%eax
801029dd:	eb e5                	jmp    801029c4 <log_write+0x3f>
    panic("too big a transaction");
801029df:	83 ec 0c             	sub    $0xc,%esp
801029e2:	68 13 6b 10 80       	push   $0x80106b13
801029e7:	e8 5c d9 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
801029ec:	83 ec 0c             	sub    $0xc,%esp
801029ef:	68 29 6b 10 80       	push   $0x80106b29
801029f4:	e8 4f d9 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
801029f9:	8b 4b 08             	mov    0x8(%ebx),%ecx
801029fc:	89 0c 85 4c d0 16 80 	mov    %ecx,-0x7fe92fb4(,%eax,4)
  if (i == log.lh.n)
80102a03:	39 c2                	cmp    %eax,%edx
80102a05:	74 18                	je     80102a1f <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102a07:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102a0a:	83 ec 0c             	sub    $0xc,%esp
80102a0d:	68 00 d0 16 80       	push   $0x8016d000
80102a12:	e8 71 13 00 00       	call   80103d88 <release>
}
80102a17:	83 c4 10             	add    $0x10,%esp
80102a1a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102a1d:	c9                   	leave  
80102a1e:	c3                   	ret    
    log.lh.n++;
80102a1f:	83 c2 01             	add    $0x1,%edx
80102a22:	89 15 48 d0 16 80    	mov    %edx,0x8016d048
80102a28:	eb dd                	jmp    80102a07 <log_write+0x82>

80102a2a <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102a2a:	55                   	push   %ebp
80102a2b:	89 e5                	mov    %esp,%ebp
80102a2d:	53                   	push   %ebx
80102a2e:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102a31:	68 8a 00 00 00       	push   $0x8a
80102a36:	68 8c a4 10 80       	push   $0x8010a48c
80102a3b:	68 00 70 00 80       	push   $0x80007000
80102a40:	e8 05 14 00 00       	call   80103e4a <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102a45:	83 c4 10             	add    $0x10,%esp
80102a48:	bb 00 d1 16 80       	mov    $0x8016d100,%ebx
80102a4d:	eb 06                	jmp    80102a55 <startothers+0x2b>
80102a4f:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102a55:	69 05 80 d6 16 80 b0 	imul   $0xb0,0x8016d680,%eax
80102a5c:	00 00 00 
80102a5f:	05 00 d1 16 80       	add    $0x8016d100,%eax
80102a64:	39 d8                	cmp    %ebx,%eax
80102a66:	76 4c                	jbe    80102ab4 <startothers+0x8a>
    if(c == mycpu())  // We've started already.
80102a68:	e8 de 07 00 00       	call   8010324b <mycpu>
80102a6d:	39 d8                	cmp    %ebx,%eax
80102a6f:	74 de                	je     80102a4f <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80102a71:	e8 5c f6 ff ff       	call   801020d2 <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102a76:	05 00 10 00 00       	add    $0x1000,%eax
80102a7b:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
80102a80:	c7 05 f8 6f 00 80 f8 	movl   $0x80102af8,0x80006ff8
80102a87:	2a 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102a8a:	c7 05 f4 6f 00 80 00 	movl   $0x109000,0x80006ff4
80102a91:	90 10 00 

    lapicstartap(c->apicid, V2P(code));
80102a94:	83 ec 08             	sub    $0x8,%esp
80102a97:	68 00 70 00 00       	push   $0x7000
80102a9c:	0f b6 03             	movzbl (%ebx),%eax
80102a9f:	50                   	push   %eax
80102aa0:	e8 c6 f9 ff ff       	call   8010246b <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102aa5:	83 c4 10             	add    $0x10,%esp
80102aa8:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102aae:	85 c0                	test   %eax,%eax
80102ab0:	74 f6                	je     80102aa8 <startothers+0x7e>
80102ab2:	eb 9b                	jmp    80102a4f <startothers+0x25>
      ;
  }
}
80102ab4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102ab7:	c9                   	leave  
80102ab8:	c3                   	ret    

80102ab9 <mpmain>:
{
80102ab9:	55                   	push   %ebp
80102aba:	89 e5                	mov    %esp,%ebp
80102abc:	53                   	push   %ebx
80102abd:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102ac0:	e8 e2 07 00 00       	call   801032a7 <cpuid>
80102ac5:	89 c3                	mov    %eax,%ebx
80102ac7:	e8 db 07 00 00       	call   801032a7 <cpuid>
80102acc:	83 ec 04             	sub    $0x4,%esp
80102acf:	53                   	push   %ebx
80102ad0:	50                   	push   %eax
80102ad1:	68 44 6b 10 80       	push   $0x80106b44
80102ad6:	e8 30 db ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102adb:	e8 c1 24 00 00       	call   80104fa1 <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102ae0:	e8 66 07 00 00       	call   8010324b <mycpu>
80102ae5:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102ae7:	b8 01 00 00 00       	mov    $0x1,%eax
80102aec:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102af3:	e8 7e 0a 00 00       	call   80103576 <scheduler>

80102af8 <mpenter>:
{
80102af8:	55                   	push   %ebp
80102af9:	89 e5                	mov    %esp,%ebp
80102afb:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102afe:	e8 af 34 00 00       	call   80105fb2 <switchkvm>
  seginit();
80102b03:	e8 5e 33 00 00       	call   80105e66 <seginit>
  lapicinit();
80102b08:	e8 15 f8 ff ff       	call   80102322 <lapicinit>
  mpmain();
80102b0d:	e8 a7 ff ff ff       	call   80102ab9 <mpmain>

80102b12 <main>:
{
80102b12:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102b16:	83 e4 f0             	and    $0xfffffff0,%esp
80102b19:	ff 71 fc             	pushl  -0x4(%ecx)
80102b1c:	55                   	push   %ebp
80102b1d:	89 e5                	mov    %esp,%ebp
80102b1f:	51                   	push   %ecx
80102b20:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102b23:	68 00 00 40 80       	push   $0x80400000
80102b28:	68 28 df 35 80       	push   $0x8035df28
80102b2d:	e8 4e f5 ff ff       	call   80102080 <kinit1>
  kvmalloc();      // kernel page table
80102b32:	e8 23 39 00 00       	call   8010645a <kvmalloc>
  mpinit();        // detect other processors
80102b37:	e8 c9 01 00 00       	call   80102d05 <mpinit>
  lapicinit();     // interrupt controller
80102b3c:	e8 e1 f7 ff ff       	call   80102322 <lapicinit>
  seginit();       // segment descriptors
80102b41:	e8 20 33 00 00       	call   80105e66 <seginit>
  picinit();       // disable pic
80102b46:	e8 82 02 00 00       	call   80102dcd <picinit>
  ioapicinit();    // another interrupt controller
80102b4b:	e8 aa f3 ff ff       	call   80101efa <ioapicinit>
  consoleinit();   // console hardware
80102b50:	e8 39 dd ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102b55:	e8 f5 26 00 00       	call   8010524f <uartinit>
  pinit();         // process table
80102b5a:	e8 d2 06 00 00       	call   80103231 <pinit>
  tvinit();        // trap vectors
80102b5f:	e8 8c 23 00 00       	call   80104ef0 <tvinit>
  binit();         // buffer cache
80102b64:	e8 8b d5 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102b69:	e8 a5 e0 ff ff       	call   80100c13 <fileinit>
  ideinit();       // disk 
80102b6e:	e8 8d f1 ff ff       	call   80101d00 <ideinit>
  startothers();   // start other processors
80102b73:	e8 b2 fe ff ff       	call   80102a2a <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102b78:	83 c4 08             	add    $0x8,%esp
80102b7b:	68 00 00 00 8e       	push   $0x8e000000
80102b80:	68 00 00 40 80       	push   $0x80400000
80102b85:	e8 28 f5 ff ff       	call   801020b2 <kinit2>
  userinit();      // first user process
80102b8a:	e8 57 07 00 00       	call   801032e6 <userinit>
  mpmain();        // finish this processor's setup
80102b8f:	e8 25 ff ff ff       	call   80102ab9 <mpmain>

80102b94 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102b94:	55                   	push   %ebp
80102b95:	89 e5                	mov    %esp,%ebp
80102b97:	56                   	push   %esi
80102b98:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102b99:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102b9e:	b9 00 00 00 00       	mov    $0x0,%ecx
80102ba3:	eb 09                	jmp    80102bae <sum+0x1a>
    sum += addr[i];
80102ba5:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102ba9:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102bab:	83 c1 01             	add    $0x1,%ecx
80102bae:	39 d1                	cmp    %edx,%ecx
80102bb0:	7c f3                	jl     80102ba5 <sum+0x11>
  return sum;
}
80102bb2:	89 d8                	mov    %ebx,%eax
80102bb4:	5b                   	pop    %ebx
80102bb5:	5e                   	pop    %esi
80102bb6:	5d                   	pop    %ebp
80102bb7:	c3                   	ret    

80102bb8 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102bb8:	55                   	push   %ebp
80102bb9:	89 e5                	mov    %esp,%ebp
80102bbb:	56                   	push   %esi
80102bbc:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102bbd:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102bc3:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102bc5:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102bc7:	eb 03                	jmp    80102bcc <mpsearch1+0x14>
80102bc9:	83 c3 10             	add    $0x10,%ebx
80102bcc:	39 f3                	cmp    %esi,%ebx
80102bce:	73 29                	jae    80102bf9 <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102bd0:	83 ec 04             	sub    $0x4,%esp
80102bd3:	6a 04                	push   $0x4
80102bd5:	68 58 6b 10 80       	push   $0x80106b58
80102bda:	53                   	push   %ebx
80102bdb:	e8 35 12 00 00       	call   80103e15 <memcmp>
80102be0:	83 c4 10             	add    $0x10,%esp
80102be3:	85 c0                	test   %eax,%eax
80102be5:	75 e2                	jne    80102bc9 <mpsearch1+0x11>
80102be7:	ba 10 00 00 00       	mov    $0x10,%edx
80102bec:	89 d8                	mov    %ebx,%eax
80102bee:	e8 a1 ff ff ff       	call   80102b94 <sum>
80102bf3:	84 c0                	test   %al,%al
80102bf5:	75 d2                	jne    80102bc9 <mpsearch1+0x11>
80102bf7:	eb 05                	jmp    80102bfe <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102bf9:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102bfe:	89 d8                	mov    %ebx,%eax
80102c00:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102c03:	5b                   	pop    %ebx
80102c04:	5e                   	pop    %esi
80102c05:	5d                   	pop    %ebp
80102c06:	c3                   	ret    

80102c07 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102c07:	55                   	push   %ebp
80102c08:	89 e5                	mov    %esp,%ebp
80102c0a:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102c0d:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102c14:	c1 e0 08             	shl    $0x8,%eax
80102c17:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102c1e:	09 d0                	or     %edx,%eax
80102c20:	c1 e0 04             	shl    $0x4,%eax
80102c23:	85 c0                	test   %eax,%eax
80102c25:	74 1f                	je     80102c46 <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102c27:	ba 00 04 00 00       	mov    $0x400,%edx
80102c2c:	e8 87 ff ff ff       	call   80102bb8 <mpsearch1>
80102c31:	85 c0                	test   %eax,%eax
80102c33:	75 0f                	jne    80102c44 <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102c35:	ba 00 00 01 00       	mov    $0x10000,%edx
80102c3a:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102c3f:	e8 74 ff ff ff       	call   80102bb8 <mpsearch1>
}
80102c44:	c9                   	leave  
80102c45:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102c46:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102c4d:	c1 e0 08             	shl    $0x8,%eax
80102c50:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102c57:	09 d0                	or     %edx,%eax
80102c59:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102c5c:	2d 00 04 00 00       	sub    $0x400,%eax
80102c61:	ba 00 04 00 00       	mov    $0x400,%edx
80102c66:	e8 4d ff ff ff       	call   80102bb8 <mpsearch1>
80102c6b:	85 c0                	test   %eax,%eax
80102c6d:	75 d5                	jne    80102c44 <mpsearch+0x3d>
80102c6f:	eb c4                	jmp    80102c35 <mpsearch+0x2e>

80102c71 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102c71:	55                   	push   %ebp
80102c72:	89 e5                	mov    %esp,%ebp
80102c74:	57                   	push   %edi
80102c75:	56                   	push   %esi
80102c76:	53                   	push   %ebx
80102c77:	83 ec 1c             	sub    $0x1c,%esp
80102c7a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102c7d:	e8 85 ff ff ff       	call   80102c07 <mpsearch>
80102c82:	85 c0                	test   %eax,%eax
80102c84:	74 5c                	je     80102ce2 <mpconfig+0x71>
80102c86:	89 c7                	mov    %eax,%edi
80102c88:	8b 58 04             	mov    0x4(%eax),%ebx
80102c8b:	85 db                	test   %ebx,%ebx
80102c8d:	74 5a                	je     80102ce9 <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102c8f:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102c95:	83 ec 04             	sub    $0x4,%esp
80102c98:	6a 04                	push   $0x4
80102c9a:	68 5d 6b 10 80       	push   $0x80106b5d
80102c9f:	56                   	push   %esi
80102ca0:	e8 70 11 00 00       	call   80103e15 <memcmp>
80102ca5:	83 c4 10             	add    $0x10,%esp
80102ca8:	85 c0                	test   %eax,%eax
80102caa:	75 44                	jne    80102cf0 <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102cac:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102cb3:	3c 01                	cmp    $0x1,%al
80102cb5:	0f 95 c2             	setne  %dl
80102cb8:	3c 04                	cmp    $0x4,%al
80102cba:	0f 95 c0             	setne  %al
80102cbd:	84 c2                	test   %al,%dl
80102cbf:	75 36                	jne    80102cf7 <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102cc1:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102cc8:	89 f0                	mov    %esi,%eax
80102cca:	e8 c5 fe ff ff       	call   80102b94 <sum>
80102ccf:	84 c0                	test   %al,%al
80102cd1:	75 2b                	jne    80102cfe <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102cd3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102cd6:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102cd8:	89 f0                	mov    %esi,%eax
80102cda:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102cdd:	5b                   	pop    %ebx
80102cde:	5e                   	pop    %esi
80102cdf:	5f                   	pop    %edi
80102ce0:	5d                   	pop    %ebp
80102ce1:	c3                   	ret    
    return 0;
80102ce2:	be 00 00 00 00       	mov    $0x0,%esi
80102ce7:	eb ef                	jmp    80102cd8 <mpconfig+0x67>
80102ce9:	be 00 00 00 00       	mov    $0x0,%esi
80102cee:	eb e8                	jmp    80102cd8 <mpconfig+0x67>
    return 0;
80102cf0:	be 00 00 00 00       	mov    $0x0,%esi
80102cf5:	eb e1                	jmp    80102cd8 <mpconfig+0x67>
    return 0;
80102cf7:	be 00 00 00 00       	mov    $0x0,%esi
80102cfc:	eb da                	jmp    80102cd8 <mpconfig+0x67>
    return 0;
80102cfe:	be 00 00 00 00       	mov    $0x0,%esi
80102d03:	eb d3                	jmp    80102cd8 <mpconfig+0x67>

80102d05 <mpinit>:

void
mpinit(void)
{
80102d05:	55                   	push   %ebp
80102d06:	89 e5                	mov    %esp,%ebp
80102d08:	57                   	push   %edi
80102d09:	56                   	push   %esi
80102d0a:	53                   	push   %ebx
80102d0b:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102d0e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102d11:	e8 5b ff ff ff       	call   80102c71 <mpconfig>
80102d16:	85 c0                	test   %eax,%eax
80102d18:	74 19                	je     80102d33 <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102d1a:	8b 50 24             	mov    0x24(%eax),%edx
80102d1d:	89 15 fc cf 16 80    	mov    %edx,0x8016cffc
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d23:	8d 50 2c             	lea    0x2c(%eax),%edx
80102d26:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102d2a:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102d2c:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d31:	eb 34                	jmp    80102d67 <mpinit+0x62>
    panic("Expect to run on an SMP");
80102d33:	83 ec 0c             	sub    $0xc,%esp
80102d36:	68 62 6b 10 80       	push   $0x80106b62
80102d3b:	e8 08 d6 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102d40:	8b 35 80 d6 16 80    	mov    0x8016d680,%esi
80102d46:	83 fe 07             	cmp    $0x7,%esi
80102d49:	7f 19                	jg     80102d64 <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102d4b:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102d4f:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102d55:	88 87 00 d1 16 80    	mov    %al,-0x7fe92f00(%edi)
        ncpu++;
80102d5b:	83 c6 01             	add    $0x1,%esi
80102d5e:	89 35 80 d6 16 80    	mov    %esi,0x8016d680
      }
      p += sizeof(struct mpproc);
80102d64:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d67:	39 ca                	cmp    %ecx,%edx
80102d69:	73 2b                	jae    80102d96 <mpinit+0x91>
    switch(*p){
80102d6b:	0f b6 02             	movzbl (%edx),%eax
80102d6e:	3c 04                	cmp    $0x4,%al
80102d70:	77 1d                	ja     80102d8f <mpinit+0x8a>
80102d72:	0f b6 c0             	movzbl %al,%eax
80102d75:	ff 24 85 9c 6b 10 80 	jmp    *-0x7fef9464(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80102d7c:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102d80:	a2 e0 d0 16 80       	mov    %al,0x8016d0e0
      p += sizeof(struct mpioapic);
80102d85:	83 c2 08             	add    $0x8,%edx
      continue;
80102d88:	eb dd                	jmp    80102d67 <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102d8a:	83 c2 08             	add    $0x8,%edx
      continue;
80102d8d:	eb d8                	jmp    80102d67 <mpinit+0x62>
    default:
      ismp = 0;
80102d8f:	bb 00 00 00 00       	mov    $0x0,%ebx
80102d94:	eb d1                	jmp    80102d67 <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
80102d96:	85 db                	test   %ebx,%ebx
80102d98:	74 26                	je     80102dc0 <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102d9a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102d9d:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102da1:	74 15                	je     80102db8 <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102da3:	b8 70 00 00 00       	mov    $0x70,%eax
80102da8:	ba 22 00 00 00       	mov    $0x22,%edx
80102dad:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102dae:	ba 23 00 00 00       	mov    $0x23,%edx
80102db3:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102db4:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102db7:	ee                   	out    %al,(%dx)
  }
}
80102db8:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102dbb:	5b                   	pop    %ebx
80102dbc:	5e                   	pop    %esi
80102dbd:	5f                   	pop    %edi
80102dbe:	5d                   	pop    %ebp
80102dbf:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102dc0:	83 ec 0c             	sub    $0xc,%esp
80102dc3:	68 7c 6b 10 80       	push   $0x80106b7c
80102dc8:	e8 7b d5 ff ff       	call   80100348 <panic>

80102dcd <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80102dcd:	55                   	push   %ebp
80102dce:	89 e5                	mov    %esp,%ebp
80102dd0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102dd5:	ba 21 00 00 00       	mov    $0x21,%edx
80102dda:	ee                   	out    %al,(%dx)
80102ddb:	ba a1 00 00 00       	mov    $0xa1,%edx
80102de0:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80102de1:	5d                   	pop    %ebp
80102de2:	c3                   	ret    

80102de3 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80102de3:	55                   	push   %ebp
80102de4:	89 e5                	mov    %esp,%ebp
80102de6:	57                   	push   %edi
80102de7:	56                   	push   %esi
80102de8:	53                   	push   %ebx
80102de9:	83 ec 0c             	sub    $0xc,%esp
80102dec:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102def:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80102df2:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80102df8:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80102dfe:	e8 2a de ff ff       	call   80100c2d <filealloc>
80102e03:	89 03                	mov    %eax,(%ebx)
80102e05:	85 c0                	test   %eax,%eax
80102e07:	74 16                	je     80102e1f <pipealloc+0x3c>
80102e09:	e8 1f de ff ff       	call   80100c2d <filealloc>
80102e0e:	89 06                	mov    %eax,(%esi)
80102e10:	85 c0                	test   %eax,%eax
80102e12:	74 0b                	je     80102e1f <pipealloc+0x3c>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80102e14:	e8 b9 f2 ff ff       	call   801020d2 <kalloc>
80102e19:	89 c7                	mov    %eax,%edi
80102e1b:	85 c0                	test   %eax,%eax
80102e1d:	75 35                	jne    80102e54 <pipealloc+0x71>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
80102e1f:	8b 03                	mov    (%ebx),%eax
80102e21:	85 c0                	test   %eax,%eax
80102e23:	74 0c                	je     80102e31 <pipealloc+0x4e>
    fileclose(*f0);
80102e25:	83 ec 0c             	sub    $0xc,%esp
80102e28:	50                   	push   %eax
80102e29:	e8 a5 de ff ff       	call   80100cd3 <fileclose>
80102e2e:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80102e31:	8b 06                	mov    (%esi),%eax
80102e33:	85 c0                	test   %eax,%eax
80102e35:	0f 84 8b 00 00 00    	je     80102ec6 <pipealloc+0xe3>
    fileclose(*f1);
80102e3b:	83 ec 0c             	sub    $0xc,%esp
80102e3e:	50                   	push   %eax
80102e3f:	e8 8f de ff ff       	call   80100cd3 <fileclose>
80102e44:	83 c4 10             	add    $0x10,%esp
  return -1;
80102e47:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80102e4c:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102e4f:	5b                   	pop    %ebx
80102e50:	5e                   	pop    %esi
80102e51:	5f                   	pop    %edi
80102e52:	5d                   	pop    %ebp
80102e53:	c3                   	ret    
  p->readopen = 1;
80102e54:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80102e5b:	00 00 00 
  p->writeopen = 1;
80102e5e:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80102e65:	00 00 00 
  p->nwrite = 0;
80102e68:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80102e6f:	00 00 00 
  p->nread = 0;
80102e72:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80102e79:	00 00 00 
  initlock(&p->lock, "pipe");
80102e7c:	83 ec 08             	sub    $0x8,%esp
80102e7f:	68 b0 6b 10 80       	push   $0x80106bb0
80102e84:	50                   	push   %eax
80102e85:	e8 5d 0d 00 00       	call   80103be7 <initlock>
  (*f0)->type = FD_PIPE;
80102e8a:	8b 03                	mov    (%ebx),%eax
80102e8c:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80102e92:	8b 03                	mov    (%ebx),%eax
80102e94:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80102e98:	8b 03                	mov    (%ebx),%eax
80102e9a:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80102e9e:	8b 03                	mov    (%ebx),%eax
80102ea0:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80102ea3:	8b 06                	mov    (%esi),%eax
80102ea5:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80102eab:	8b 06                	mov    (%esi),%eax
80102ead:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80102eb1:	8b 06                	mov    (%esi),%eax
80102eb3:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80102eb7:	8b 06                	mov    (%esi),%eax
80102eb9:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
80102ebc:	83 c4 10             	add    $0x10,%esp
80102ebf:	b8 00 00 00 00       	mov    $0x0,%eax
80102ec4:	eb 86                	jmp    80102e4c <pipealloc+0x69>
  return -1;
80102ec6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102ecb:	e9 7c ff ff ff       	jmp    80102e4c <pipealloc+0x69>

80102ed0 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80102ed0:	55                   	push   %ebp
80102ed1:	89 e5                	mov    %esp,%ebp
80102ed3:	53                   	push   %ebx
80102ed4:	83 ec 10             	sub    $0x10,%esp
80102ed7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
80102eda:	53                   	push   %ebx
80102edb:	e8 43 0e 00 00       	call   80103d23 <acquire>
  if(writable){
80102ee0:	83 c4 10             	add    $0x10,%esp
80102ee3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102ee7:	74 3f                	je     80102f28 <pipeclose+0x58>
    p->writeopen = 0;
80102ee9:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80102ef0:	00 00 00 
    wakeup(&p->nread);
80102ef3:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102ef9:	83 ec 0c             	sub    $0xc,%esp
80102efc:	50                   	push   %eax
80102efd:	e8 18 0a 00 00       	call   8010391a <wakeup>
80102f02:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80102f05:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102f0c:	75 09                	jne    80102f17 <pipeclose+0x47>
80102f0e:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80102f15:	74 2f                	je     80102f46 <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
80102f17:	83 ec 0c             	sub    $0xc,%esp
80102f1a:	53                   	push   %ebx
80102f1b:	e8 68 0e 00 00       	call   80103d88 <release>
80102f20:	83 c4 10             	add    $0x10,%esp
}
80102f23:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102f26:	c9                   	leave  
80102f27:	c3                   	ret    
    p->readopen = 0;
80102f28:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
80102f2f:	00 00 00 
    wakeup(&p->nwrite);
80102f32:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102f38:	83 ec 0c             	sub    $0xc,%esp
80102f3b:	50                   	push   %eax
80102f3c:	e8 d9 09 00 00       	call   8010391a <wakeup>
80102f41:	83 c4 10             	add    $0x10,%esp
80102f44:	eb bf                	jmp    80102f05 <pipeclose+0x35>
    release(&p->lock);
80102f46:	83 ec 0c             	sub    $0xc,%esp
80102f49:	53                   	push   %ebx
80102f4a:	e8 39 0e 00 00       	call   80103d88 <release>
    kfree((char*)p);
80102f4f:	89 1c 24             	mov    %ebx,(%esp)
80102f52:	e8 4d f0 ff ff       	call   80101fa4 <kfree>
80102f57:	83 c4 10             	add    $0x10,%esp
80102f5a:	eb c7                	jmp    80102f23 <pipeclose+0x53>

80102f5c <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
80102f5c:	55                   	push   %ebp
80102f5d:	89 e5                	mov    %esp,%ebp
80102f5f:	57                   	push   %edi
80102f60:	56                   	push   %esi
80102f61:	53                   	push   %ebx
80102f62:	83 ec 18             	sub    $0x18,%esp
80102f65:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80102f68:	89 de                	mov    %ebx,%esi
80102f6a:	53                   	push   %ebx
80102f6b:	e8 b3 0d 00 00       	call   80103d23 <acquire>
  for(i = 0; i < n; i++){
80102f70:	83 c4 10             	add    $0x10,%esp
80102f73:	bf 00 00 00 00       	mov    $0x0,%edi
80102f78:	3b 7d 10             	cmp    0x10(%ebp),%edi
80102f7b:	0f 8d 88 00 00 00    	jge    80103009 <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80102f81:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
80102f87:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80102f8d:	05 00 02 00 00       	add    $0x200,%eax
80102f92:	39 c2                	cmp    %eax,%edx
80102f94:	75 51                	jne    80102fe7 <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
80102f96:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102f9d:	74 2f                	je     80102fce <pipewrite+0x72>
80102f9f:	e8 1e 03 00 00       	call   801032c2 <myproc>
80102fa4:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80102fa8:	75 24                	jne    80102fce <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
80102faa:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102fb0:	83 ec 0c             	sub    $0xc,%esp
80102fb3:	50                   	push   %eax
80102fb4:	e8 61 09 00 00       	call   8010391a <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80102fb9:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102fbf:	83 c4 08             	add    $0x8,%esp
80102fc2:	56                   	push   %esi
80102fc3:	50                   	push   %eax
80102fc4:	e8 d2 07 00 00       	call   8010379b <sleep>
80102fc9:	83 c4 10             	add    $0x10,%esp
80102fcc:	eb b3                	jmp    80102f81 <pipewrite+0x25>
        release(&p->lock);
80102fce:	83 ec 0c             	sub    $0xc,%esp
80102fd1:	53                   	push   %ebx
80102fd2:	e8 b1 0d 00 00       	call   80103d88 <release>
        return -1;
80102fd7:	83 c4 10             	add    $0x10,%esp
80102fda:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
80102fdf:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102fe2:	5b                   	pop    %ebx
80102fe3:	5e                   	pop    %esi
80102fe4:	5f                   	pop    %edi
80102fe5:	5d                   	pop    %ebp
80102fe6:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80102fe7:	8d 42 01             	lea    0x1(%edx),%eax
80102fea:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
80102ff0:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102ff6:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ff9:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
80102ffd:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
80103001:	83 c7 01             	add    $0x1,%edi
80103004:	e9 6f ff ff ff       	jmp    80102f78 <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80103009:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
8010300f:	83 ec 0c             	sub    $0xc,%esp
80103012:	50                   	push   %eax
80103013:	e8 02 09 00 00       	call   8010391a <wakeup>
  release(&p->lock);
80103018:	89 1c 24             	mov    %ebx,(%esp)
8010301b:	e8 68 0d 00 00       	call   80103d88 <release>
  return n;
80103020:	83 c4 10             	add    $0x10,%esp
80103023:	8b 45 10             	mov    0x10(%ebp),%eax
80103026:	eb b7                	jmp    80102fdf <pipewrite+0x83>

80103028 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80103028:	55                   	push   %ebp
80103029:	89 e5                	mov    %esp,%ebp
8010302b:	57                   	push   %edi
8010302c:	56                   	push   %esi
8010302d:	53                   	push   %ebx
8010302e:	83 ec 18             	sub    $0x18,%esp
80103031:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80103034:	89 df                	mov    %ebx,%edi
80103036:	53                   	push   %ebx
80103037:	e8 e7 0c 00 00       	call   80103d23 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010303c:	83 c4 10             	add    $0x10,%esp
8010303f:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
80103045:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
8010304b:	75 3d                	jne    8010308a <piperead+0x62>
8010304d:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
80103053:	85 f6                	test   %esi,%esi
80103055:	74 38                	je     8010308f <piperead+0x67>
    if(myproc()->killed){
80103057:	e8 66 02 00 00       	call   801032c2 <myproc>
8010305c:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80103060:	75 15                	jne    80103077 <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80103062:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103068:	83 ec 08             	sub    $0x8,%esp
8010306b:	57                   	push   %edi
8010306c:	50                   	push   %eax
8010306d:	e8 29 07 00 00       	call   8010379b <sleep>
80103072:	83 c4 10             	add    $0x10,%esp
80103075:	eb c8                	jmp    8010303f <piperead+0x17>
      release(&p->lock);
80103077:	83 ec 0c             	sub    $0xc,%esp
8010307a:	53                   	push   %ebx
8010307b:	e8 08 0d 00 00       	call   80103d88 <release>
      return -1;
80103080:	83 c4 10             	add    $0x10,%esp
80103083:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103088:	eb 50                	jmp    801030da <piperead+0xb2>
8010308a:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010308f:	3b 75 10             	cmp    0x10(%ebp),%esi
80103092:	7d 2c                	jge    801030c0 <piperead+0x98>
    if(p->nread == p->nwrite)
80103094:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
8010309a:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
801030a0:	74 1e                	je     801030c0 <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
801030a2:	8d 50 01             	lea    0x1(%eax),%edx
801030a5:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
801030ab:	25 ff 01 00 00       	and    $0x1ff,%eax
801030b0:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
801030b5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801030b8:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801030bb:	83 c6 01             	add    $0x1,%esi
801030be:	eb cf                	jmp    8010308f <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
801030c0:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
801030c6:	83 ec 0c             	sub    $0xc,%esp
801030c9:	50                   	push   %eax
801030ca:	e8 4b 08 00 00       	call   8010391a <wakeup>
  release(&p->lock);
801030cf:	89 1c 24             	mov    %ebx,(%esp)
801030d2:	e8 b1 0c 00 00       	call   80103d88 <release>
  return i;
801030d7:	83 c4 10             	add    $0x10,%esp
}
801030da:	89 f0                	mov    %esi,%eax
801030dc:	8d 65 f4             	lea    -0xc(%ebp),%esp
801030df:	5b                   	pop    %ebx
801030e0:	5e                   	pop    %esi
801030e1:	5f                   	pop    %edi
801030e2:	5d                   	pop    %ebp
801030e3:	c3                   	ret    

801030e4 <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
801030e4:	55                   	push   %ebp
801030e5:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801030e7:	ba d4 d6 16 80       	mov    $0x8016d6d4,%edx
801030ec:	eb 03                	jmp    801030f1 <wakeup1+0xd>
801030ee:	83 c2 7c             	add    $0x7c,%edx
801030f1:	81 fa d4 f5 16 80    	cmp    $0x8016f5d4,%edx
801030f7:	73 14                	jae    8010310d <wakeup1+0x29>
    if(p->state == SLEEPING && p->chan == chan)
801030f9:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
801030fd:	75 ef                	jne    801030ee <wakeup1+0xa>
801030ff:	39 42 20             	cmp    %eax,0x20(%edx)
80103102:	75 ea                	jne    801030ee <wakeup1+0xa>
      p->state = RUNNABLE;
80103104:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
8010310b:	eb e1                	jmp    801030ee <wakeup1+0xa>
}
8010310d:	5d                   	pop    %ebp
8010310e:	c3                   	ret    

8010310f <allocproc>:
{
8010310f:	55                   	push   %ebp
80103110:	89 e5                	mov    %esp,%ebp
80103112:	53                   	push   %ebx
80103113:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
80103116:	68 a0 d6 16 80       	push   $0x8016d6a0
8010311b:	e8 03 0c 00 00       	call   80103d23 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103120:	83 c4 10             	add    $0x10,%esp
80103123:	bb d4 d6 16 80       	mov    $0x8016d6d4,%ebx
80103128:	81 fb d4 f5 16 80    	cmp    $0x8016f5d4,%ebx
8010312e:	73 0b                	jae    8010313b <allocproc+0x2c>
    if(p->state == UNUSED)
80103130:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
80103134:	74 1f                	je     80103155 <allocproc+0x46>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103136:	83 c3 7c             	add    $0x7c,%ebx
80103139:	eb ed                	jmp    80103128 <allocproc+0x19>
  release(&ptable.lock);
8010313b:	83 ec 0c             	sub    $0xc,%esp
8010313e:	68 a0 d6 16 80       	push   $0x8016d6a0
80103143:	e8 40 0c 00 00       	call   80103d88 <release>
  return 0;
80103148:	83 c4 10             	add    $0x10,%esp
8010314b:	bb 00 00 00 00       	mov    $0x0,%ebx
80103150:	e9 84 00 00 00       	jmp    801031d9 <allocproc+0xca>
  p->state = EMBRYO;
80103155:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
8010315c:	a1 04 a0 10 80       	mov    0x8010a004,%eax
80103161:	8d 50 01             	lea    0x1(%eax),%edx
80103164:	89 15 04 a0 10 80    	mov    %edx,0x8010a004
8010316a:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
8010316d:	83 ec 0c             	sub    $0xc,%esp
80103170:	68 a0 d6 16 80       	push   $0x8016d6a0
80103175:	e8 0e 0c 00 00       	call   80103d88 <release>
  if((p->kstack = kalloc2(p->pid)) == 0){
8010317a:	83 c4 04             	add    $0x4,%esp
8010317d:	ff 73 10             	pushl  0x10(%ebx)
80103180:	e8 b6 ef ff ff       	call   8010213b <kalloc2>
80103185:	89 43 08             	mov    %eax,0x8(%ebx)
80103188:	83 c4 10             	add    $0x10,%esp
8010318b:	85 c0                	test   %eax,%eax
8010318d:	74 51                	je     801031e0 <allocproc+0xd1>
  FRAMES[V2P(p->kstack) >> 12] = p->pid;
8010318f:	05 00 00 00 80       	add    $0x80000000,%eax
80103194:	c1 e8 0c             	shr    $0xc,%eax
80103197:	8b 53 10             	mov    0x10(%ebx),%edx
8010319a:	89 14 85 20 ff 10 80 	mov    %edx,-0x7fef00e0(,%eax,4)
  sp = p->kstack + KSTACKSIZE;
801031a1:	8b 43 08             	mov    0x8(%ebx),%eax
  sp -= sizeof *p->tf;
801031a4:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
801031aa:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint*)sp = (uint)trapret;
801031ad:	c7 80 b0 0f 00 00 e5 	movl   $0x80104ee5,0xfb0(%eax)
801031b4:	4e 10 80 
  sp -= sizeof *p->context;
801031b7:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context*)sp;
801031bc:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
801031bf:	83 ec 04             	sub    $0x4,%esp
801031c2:	6a 14                	push   $0x14
801031c4:	6a 00                	push   $0x0
801031c6:	50                   	push   %eax
801031c7:	e8 03 0c 00 00       	call   80103dcf <memset>
  p->context->eip = (uint)forkret;
801031cc:	8b 43 1c             	mov    0x1c(%ebx),%eax
801031cf:	c7 40 10 ee 31 10 80 	movl   $0x801031ee,0x10(%eax)
  return p;
801031d6:	83 c4 10             	add    $0x10,%esp
}
801031d9:	89 d8                	mov    %ebx,%eax
801031db:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801031de:	c9                   	leave  
801031df:	c3                   	ret    
    p->state = UNUSED;
801031e0:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
801031e7:	bb 00 00 00 00       	mov    $0x0,%ebx
801031ec:	eb eb                	jmp    801031d9 <allocproc+0xca>

801031ee <forkret>:
{
801031ee:	55                   	push   %ebp
801031ef:	89 e5                	mov    %esp,%ebp
801031f1:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
801031f4:	68 a0 d6 16 80       	push   $0x8016d6a0
801031f9:	e8 8a 0b 00 00       	call   80103d88 <release>
  if (first) {
801031fe:	83 c4 10             	add    $0x10,%esp
80103201:	83 3d 00 a0 10 80 00 	cmpl   $0x0,0x8010a000
80103208:	75 02                	jne    8010320c <forkret+0x1e>
}
8010320a:	c9                   	leave  
8010320b:	c3                   	ret    
    first = 0;
8010320c:	c7 05 00 a0 10 80 00 	movl   $0x0,0x8010a000
80103213:	00 00 00 
    iinit(ROOTDEV);
80103216:	83 ec 0c             	sub    $0xc,%esp
80103219:	6a 01                	push   $0x1
8010321b:	e8 cc e0 ff ff       	call   801012ec <iinit>
    initlog(ROOTDEV);
80103220:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103227:	e8 e7 f5 ff ff       	call   80102813 <initlog>
8010322c:	83 c4 10             	add    $0x10,%esp
}
8010322f:	eb d9                	jmp    8010320a <forkret+0x1c>

80103231 <pinit>:
{
80103231:	55                   	push   %ebp
80103232:	89 e5                	mov    %esp,%ebp
80103234:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
80103237:	68 b5 6b 10 80       	push   $0x80106bb5
8010323c:	68 a0 d6 16 80       	push   $0x8016d6a0
80103241:	e8 a1 09 00 00       	call   80103be7 <initlock>
}
80103246:	83 c4 10             	add    $0x10,%esp
80103249:	c9                   	leave  
8010324a:	c3                   	ret    

8010324b <mycpu>:
{
8010324b:	55                   	push   %ebp
8010324c:	89 e5                	mov    %esp,%ebp
8010324e:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103251:	9c                   	pushf  
80103252:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103253:	f6 c4 02             	test   $0x2,%ah
80103256:	75 28                	jne    80103280 <mycpu+0x35>
  apicid = lapicid();
80103258:	e8 cf f1 ff ff       	call   8010242c <lapicid>
  for (i = 0; i < ncpu; ++i) {
8010325d:	ba 00 00 00 00       	mov    $0x0,%edx
80103262:	39 15 80 d6 16 80    	cmp    %edx,0x8016d680
80103268:	7e 23                	jle    8010328d <mycpu+0x42>
    if (cpus[i].apicid == apicid)
8010326a:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
80103270:	0f b6 89 00 d1 16 80 	movzbl -0x7fe92f00(%ecx),%ecx
80103277:	39 c1                	cmp    %eax,%ecx
80103279:	74 1f                	je     8010329a <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i) {
8010327b:	83 c2 01             	add    $0x1,%edx
8010327e:	eb e2                	jmp    80103262 <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
80103280:	83 ec 0c             	sub    $0xc,%esp
80103283:	68 98 6c 10 80       	push   $0x80106c98
80103288:	e8 bb d0 ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
8010328d:	83 ec 0c             	sub    $0xc,%esp
80103290:	68 bc 6b 10 80       	push   $0x80106bbc
80103295:	e8 ae d0 ff ff       	call   80100348 <panic>
      return &cpus[i];
8010329a:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
801032a0:	05 00 d1 16 80       	add    $0x8016d100,%eax
}
801032a5:	c9                   	leave  
801032a6:	c3                   	ret    

801032a7 <cpuid>:
cpuid() {
801032a7:	55                   	push   %ebp
801032a8:	89 e5                	mov    %esp,%ebp
801032aa:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
801032ad:	e8 99 ff ff ff       	call   8010324b <mycpu>
801032b2:	2d 00 d1 16 80       	sub    $0x8016d100,%eax
801032b7:	c1 f8 04             	sar    $0x4,%eax
801032ba:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
801032c0:	c9                   	leave  
801032c1:	c3                   	ret    

801032c2 <myproc>:
myproc(void) {
801032c2:	55                   	push   %ebp
801032c3:	89 e5                	mov    %esp,%ebp
801032c5:	53                   	push   %ebx
801032c6:	83 ec 04             	sub    $0x4,%esp
  pushcli();
801032c9:	e8 78 09 00 00       	call   80103c46 <pushcli>
  c = mycpu();
801032ce:	e8 78 ff ff ff       	call   8010324b <mycpu>
  p = c->proc;
801032d3:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
801032d9:	e8 a5 09 00 00       	call   80103c83 <popcli>
}
801032de:	89 d8                	mov    %ebx,%eax
801032e0:	83 c4 04             	add    $0x4,%esp
801032e3:	5b                   	pop    %ebx
801032e4:	5d                   	pop    %ebp
801032e5:	c3                   	ret    

801032e6 <userinit>:
{
801032e6:	55                   	push   %ebp
801032e7:	89 e5                	mov    %esp,%ebp
801032e9:	53                   	push   %ebx
801032ea:	83 ec 04             	sub    $0x4,%esp
  for(int i=0; i<MAXSIZE; i++){
801032ed:	b8 00 00 00 00       	mov    $0x0,%eax
801032f2:	eb 0e                	jmp    80103302 <userinit+0x1c>
    FRAMES[i] = -1;
801032f4:	c7 04 85 20 ff 10 80 	movl   $0xffffffff,-0x7fef00e0(,%eax,4)
801032fb:	ff ff ff ff 
  for(int i=0; i<MAXSIZE; i++){
801032ff:	83 c0 01             	add    $0x1,%eax
80103302:	3d 5f ea 00 00       	cmp    $0xea5f,%eax
80103307:	7e eb                	jle    801032f4 <userinit+0xe>
  p = allocproc();
80103309:	e8 01 fe ff ff       	call   8010310f <allocproc>
8010330e:	89 c3                	mov    %eax,%ebx
  initproc = p;
80103310:	a3 b8 a5 10 80       	mov    %eax,0x8010a5b8
  if((p->pgdir = setupkvm()) == 0)
80103315:	e8 ca 30 00 00       	call   801063e4 <setupkvm>
8010331a:	89 43 04             	mov    %eax,0x4(%ebx)
8010331d:	85 c0                	test   %eax,%eax
8010331f:	0f 84 b7 00 00 00    	je     801033dc <userinit+0xf6>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80103325:	83 ec 04             	sub    $0x4,%esp
80103328:	68 2c 00 00 00       	push   $0x2c
8010332d:	68 60 a4 10 80       	push   $0x8010a460
80103332:	50                   	push   %eax
80103333:	e8 a4 2d 00 00       	call   801060dc <inituvm>
  p->sz = PGSIZE;
80103338:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
8010333e:	83 c4 0c             	add    $0xc,%esp
80103341:	6a 4c                	push   $0x4c
80103343:	6a 00                	push   $0x0
80103345:	ff 73 18             	pushl  0x18(%ebx)
80103348:	e8 82 0a 00 00       	call   80103dcf <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
8010334d:	8b 43 18             	mov    0x18(%ebx),%eax
80103350:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80103356:	8b 43 18             	mov    0x18(%ebx),%eax
80103359:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
8010335f:	8b 43 18             	mov    0x18(%ebx),%eax
80103362:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
80103366:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
8010336a:	8b 43 18             	mov    0x18(%ebx),%eax
8010336d:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
80103371:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80103375:	8b 43 18             	mov    0x18(%ebx),%eax
80103378:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
8010337f:	8b 43 18             	mov    0x18(%ebx),%eax
80103382:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80103389:	8b 43 18             	mov    0x18(%ebx),%eax
8010338c:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
80103393:	8d 43 6c             	lea    0x6c(%ebx),%eax
80103396:	83 c4 0c             	add    $0xc,%esp
80103399:	6a 10                	push   $0x10
8010339b:	68 e5 6b 10 80       	push   $0x80106be5
801033a0:	50                   	push   %eax
801033a1:	e8 90 0b 00 00       	call   80103f36 <safestrcpy>
  p->cwd = namei("/");
801033a6:	c7 04 24 ee 6b 10 80 	movl   $0x80106bee,(%esp)
801033ad:	e8 2f e8 ff ff       	call   80101be1 <namei>
801033b2:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
801033b5:	c7 04 24 a0 d6 16 80 	movl   $0x8016d6a0,(%esp)
801033bc:	e8 62 09 00 00       	call   80103d23 <acquire>
  p->state = RUNNABLE;
801033c1:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
801033c8:	c7 04 24 a0 d6 16 80 	movl   $0x8016d6a0,(%esp)
801033cf:	e8 b4 09 00 00       	call   80103d88 <release>
}
801033d4:	83 c4 10             	add    $0x10,%esp
801033d7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801033da:	c9                   	leave  
801033db:	c3                   	ret    
    panic("userinit: out of memory?");
801033dc:	83 ec 0c             	sub    $0xc,%esp
801033df:	68 cc 6b 10 80       	push   $0x80106bcc
801033e4:	e8 5f cf ff ff       	call   80100348 <panic>

801033e9 <growproc>:
{
801033e9:	55                   	push   %ebp
801033ea:	89 e5                	mov    %esp,%ebp
801033ec:	56                   	push   %esi
801033ed:	53                   	push   %ebx
801033ee:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
801033f1:	e8 cc fe ff ff       	call   801032c2 <myproc>
801033f6:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
801033f8:	8b 00                	mov    (%eax),%eax
  if(n > 0){
801033fa:	85 f6                	test   %esi,%esi
801033fc:	7f 21                	jg     8010341f <growproc+0x36>
  } else if(n < 0){
801033fe:	85 f6                	test   %esi,%esi
80103400:	79 33                	jns    80103435 <growproc+0x4c>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103402:	83 ec 04             	sub    $0x4,%esp
80103405:	01 c6                	add    %eax,%esi
80103407:	56                   	push   %esi
80103408:	50                   	push   %eax
80103409:	ff 73 04             	pushl  0x4(%ebx)
8010340c:	e8 d9 2d 00 00       	call   801061ea <deallocuvm>
80103411:	83 c4 10             	add    $0x10,%esp
80103414:	85 c0                	test   %eax,%eax
80103416:	75 1d                	jne    80103435 <growproc+0x4c>
      return -1;
80103418:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010341d:	eb 29                	jmp    80103448 <growproc+0x5f>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
8010341f:	83 ec 04             	sub    $0x4,%esp
80103422:	01 c6                	add    %eax,%esi
80103424:	56                   	push   %esi
80103425:	50                   	push   %eax
80103426:	ff 73 04             	pushl  0x4(%ebx)
80103429:	e8 4e 2e 00 00       	call   8010627c <allocuvm>
8010342e:	83 c4 10             	add    $0x10,%esp
80103431:	85 c0                	test   %eax,%eax
80103433:	74 1a                	je     8010344f <growproc+0x66>
  curproc->sz = sz;
80103435:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
80103437:	83 ec 0c             	sub    $0xc,%esp
8010343a:	53                   	push   %ebx
8010343b:	e8 84 2b 00 00       	call   80105fc4 <switchuvm>
  return 0;
80103440:	83 c4 10             	add    $0x10,%esp
80103443:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103448:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010344b:	5b                   	pop    %ebx
8010344c:	5e                   	pop    %esi
8010344d:	5d                   	pop    %ebp
8010344e:	c3                   	ret    
      return -1;
8010344f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103454:	eb f2                	jmp    80103448 <growproc+0x5f>

80103456 <fork>:
{
80103456:	55                   	push   %ebp
80103457:	89 e5                	mov    %esp,%ebp
80103459:	57                   	push   %edi
8010345a:	56                   	push   %esi
8010345b:	53                   	push   %ebx
8010345c:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
8010345f:	e8 5e fe ff ff       	call   801032c2 <myproc>
80103464:	89 c3                	mov    %eax,%ebx
  if((np = allocproc()) == 0){
80103466:	e8 a4 fc ff ff       	call   8010310f <allocproc>
8010346b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010346e:	85 c0                	test   %eax,%eax
80103470:	0f 84 f9 00 00 00    	je     8010356f <fork+0x119>
80103476:	89 c7                	mov    %eax,%edi
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0){ //pid???????????????????
80103478:	83 ec 08             	sub    $0x8,%esp
8010347b:	ff 33                	pushl  (%ebx)
8010347d:	ff 73 04             	pushl  0x4(%ebx)
80103480:	e8 18 30 00 00       	call   8010649d <copyuvm>
80103485:	89 47 04             	mov    %eax,0x4(%edi)
80103488:	83 c4 10             	add    $0x10,%esp
8010348b:	85 c0                	test   %eax,%eax
8010348d:	74 2a                	je     801034b9 <fork+0x63>
  np->sz = curproc->sz;
8010348f:	8b 03                	mov    (%ebx),%eax
80103491:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80103494:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
80103496:	89 c8                	mov    %ecx,%eax
80103498:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
8010349b:	8b 73 18             	mov    0x18(%ebx),%esi
8010349e:	8b 79 18             	mov    0x18(%ecx),%edi
801034a1:	b9 13 00 00 00       	mov    $0x13,%ecx
801034a6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
801034a8:	8b 40 18             	mov    0x18(%eax),%eax
801034ab:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for(i = 0; i < NOFILE; i++)
801034b2:	be 00 00 00 00       	mov    $0x0,%esi
801034b7:	eb 42                	jmp    801034fb <fork+0xa5>
    kfree(np->kstack);
801034b9:	83 ec 0c             	sub    $0xc,%esp
801034bc:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
801034bf:	ff 73 08             	pushl  0x8(%ebx)
801034c2:	e8 dd ea ff ff       	call   80101fa4 <kfree>
    FRAMES[V2P(np->kstack) >> 12] = -1;
801034c7:	8b 43 08             	mov    0x8(%ebx),%eax
801034ca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801034cd:	05 00 00 00 80       	add    $0x80000000,%eax
801034d2:	c1 e8 0c             	shr    $0xc,%eax
801034d5:	c7 04 85 20 ff 10 80 	movl   $0xffffffff,-0x7fef00e0(,%eax,4)
801034dc:	ff ff ff ff 
    np->kstack = 0;
801034e0:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
801034e7:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
801034ee:	83 c4 10             	add    $0x10,%esp
801034f1:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801034f6:	eb 6d                	jmp    80103565 <fork+0x10f>
  for(i = 0; i < NOFILE; i++)
801034f8:	83 c6 01             	add    $0x1,%esi
801034fb:	83 fe 0f             	cmp    $0xf,%esi
801034fe:	7f 1d                	jg     8010351d <fork+0xc7>
    if(curproc->ofile[i])
80103500:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
80103504:	85 c0                	test   %eax,%eax
80103506:	74 f0                	je     801034f8 <fork+0xa2>
      np->ofile[i] = filedup(curproc->ofile[i]);
80103508:	83 ec 0c             	sub    $0xc,%esp
8010350b:	50                   	push   %eax
8010350c:	e8 7d d7 ff ff       	call   80100c8e <filedup>
80103511:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103514:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
80103518:	83 c4 10             	add    $0x10,%esp
8010351b:	eb db                	jmp    801034f8 <fork+0xa2>
  np->cwd = idup(curproc->cwd);
8010351d:	83 ec 0c             	sub    $0xc,%esp
80103520:	ff 73 68             	pushl  0x68(%ebx)
80103523:	e8 29 e0 ff ff       	call   80101551 <idup>
80103528:	8b 7d e4             	mov    -0x1c(%ebp),%edi
8010352b:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
8010352e:	83 c3 6c             	add    $0x6c,%ebx
80103531:	8d 47 6c             	lea    0x6c(%edi),%eax
80103534:	83 c4 0c             	add    $0xc,%esp
80103537:	6a 10                	push   $0x10
80103539:	53                   	push   %ebx
8010353a:	50                   	push   %eax
8010353b:	e8 f6 09 00 00       	call   80103f36 <safestrcpy>
  pid = np->pid;
80103540:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
80103543:	c7 04 24 a0 d6 16 80 	movl   $0x8016d6a0,(%esp)
8010354a:	e8 d4 07 00 00       	call   80103d23 <acquire>
  np->state = RUNNABLE;
8010354f:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
80103556:	c7 04 24 a0 d6 16 80 	movl   $0x8016d6a0,(%esp)
8010355d:	e8 26 08 00 00       	call   80103d88 <release>
  return pid;
80103562:	83 c4 10             	add    $0x10,%esp
}
80103565:	89 d8                	mov    %ebx,%eax
80103567:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010356a:	5b                   	pop    %ebx
8010356b:	5e                   	pop    %esi
8010356c:	5f                   	pop    %edi
8010356d:	5d                   	pop    %ebp
8010356e:	c3                   	ret    
    return -1;
8010356f:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103574:	eb ef                	jmp    80103565 <fork+0x10f>

80103576 <scheduler>:
{
80103576:	55                   	push   %ebp
80103577:	89 e5                	mov    %esp,%ebp
80103579:	56                   	push   %esi
8010357a:	53                   	push   %ebx
  struct cpu *c = mycpu();
8010357b:	e8 cb fc ff ff       	call   8010324b <mycpu>
80103580:	89 c6                	mov    %eax,%esi
  c->proc = 0;
80103582:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
80103589:	00 00 00 
8010358c:	eb 5a                	jmp    801035e8 <scheduler+0x72>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010358e:	83 c3 7c             	add    $0x7c,%ebx
80103591:	81 fb d4 f5 16 80    	cmp    $0x8016f5d4,%ebx
80103597:	73 3f                	jae    801035d8 <scheduler+0x62>
      if(p->state != RUNNABLE)
80103599:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
8010359d:	75 ef                	jne    8010358e <scheduler+0x18>
      c->proc = p;
8010359f:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
801035a5:	83 ec 0c             	sub    $0xc,%esp
801035a8:	53                   	push   %ebx
801035a9:	e8 16 2a 00 00       	call   80105fc4 <switchuvm>
      p->state = RUNNING;
801035ae:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
801035b5:	83 c4 08             	add    $0x8,%esp
801035b8:	ff 73 1c             	pushl  0x1c(%ebx)
801035bb:	8d 46 04             	lea    0x4(%esi),%eax
801035be:	50                   	push   %eax
801035bf:	e8 c5 09 00 00       	call   80103f89 <swtch>
      switchkvm();
801035c4:	e8 e9 29 00 00       	call   80105fb2 <switchkvm>
      c->proc = 0;
801035c9:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
801035d0:	00 00 00 
801035d3:	83 c4 10             	add    $0x10,%esp
801035d6:	eb b6                	jmp    8010358e <scheduler+0x18>
    release(&ptable.lock);
801035d8:	83 ec 0c             	sub    $0xc,%esp
801035db:	68 a0 d6 16 80       	push   $0x8016d6a0
801035e0:	e8 a3 07 00 00       	call   80103d88 <release>
    sti();
801035e5:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
801035e8:	fb                   	sti    
    acquire(&ptable.lock);
801035e9:	83 ec 0c             	sub    $0xc,%esp
801035ec:	68 a0 d6 16 80       	push   $0x8016d6a0
801035f1:	e8 2d 07 00 00       	call   80103d23 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801035f6:	83 c4 10             	add    $0x10,%esp
801035f9:	bb d4 d6 16 80       	mov    $0x8016d6d4,%ebx
801035fe:	eb 91                	jmp    80103591 <scheduler+0x1b>

80103600 <sched>:
{
80103600:	55                   	push   %ebp
80103601:	89 e5                	mov    %esp,%ebp
80103603:	56                   	push   %esi
80103604:	53                   	push   %ebx
  struct proc *p = myproc();
80103605:	e8 b8 fc ff ff       	call   801032c2 <myproc>
8010360a:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
8010360c:	83 ec 0c             	sub    $0xc,%esp
8010360f:	68 a0 d6 16 80       	push   $0x8016d6a0
80103614:	e8 ca 06 00 00       	call   80103ce3 <holding>
80103619:	83 c4 10             	add    $0x10,%esp
8010361c:	85 c0                	test   %eax,%eax
8010361e:	74 4f                	je     8010366f <sched+0x6f>
  if(mycpu()->ncli != 1)
80103620:	e8 26 fc ff ff       	call   8010324b <mycpu>
80103625:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
8010362c:	75 4e                	jne    8010367c <sched+0x7c>
  if(p->state == RUNNING)
8010362e:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
80103632:	74 55                	je     80103689 <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103634:	9c                   	pushf  
80103635:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103636:	f6 c4 02             	test   $0x2,%ah
80103639:	75 5b                	jne    80103696 <sched+0x96>
  intena = mycpu()->intena;
8010363b:	e8 0b fc ff ff       	call   8010324b <mycpu>
80103640:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
80103646:	e8 00 fc ff ff       	call   8010324b <mycpu>
8010364b:	83 ec 08             	sub    $0x8,%esp
8010364e:	ff 70 04             	pushl  0x4(%eax)
80103651:	83 c3 1c             	add    $0x1c,%ebx
80103654:	53                   	push   %ebx
80103655:	e8 2f 09 00 00       	call   80103f89 <swtch>
  mycpu()->intena = intena;
8010365a:	e8 ec fb ff ff       	call   8010324b <mycpu>
8010365f:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
80103665:	83 c4 10             	add    $0x10,%esp
80103668:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010366b:	5b                   	pop    %ebx
8010366c:	5e                   	pop    %esi
8010366d:	5d                   	pop    %ebp
8010366e:	c3                   	ret    
    panic("sched ptable.lock");
8010366f:	83 ec 0c             	sub    $0xc,%esp
80103672:	68 f0 6b 10 80       	push   $0x80106bf0
80103677:	e8 cc cc ff ff       	call   80100348 <panic>
    panic("sched locks");
8010367c:	83 ec 0c             	sub    $0xc,%esp
8010367f:	68 02 6c 10 80       	push   $0x80106c02
80103684:	e8 bf cc ff ff       	call   80100348 <panic>
    panic("sched running");
80103689:	83 ec 0c             	sub    $0xc,%esp
8010368c:	68 0e 6c 10 80       	push   $0x80106c0e
80103691:	e8 b2 cc ff ff       	call   80100348 <panic>
    panic("sched interruptible");
80103696:	83 ec 0c             	sub    $0xc,%esp
80103699:	68 1c 6c 10 80       	push   $0x80106c1c
8010369e:	e8 a5 cc ff ff       	call   80100348 <panic>

801036a3 <exit>:
{
801036a3:	55                   	push   %ebp
801036a4:	89 e5                	mov    %esp,%ebp
801036a6:	56                   	push   %esi
801036a7:	53                   	push   %ebx
  struct proc *curproc = myproc();
801036a8:	e8 15 fc ff ff       	call   801032c2 <myproc>
  if(curproc == initproc)
801036ad:	39 05 b8 a5 10 80    	cmp    %eax,0x8010a5b8
801036b3:	74 09                	je     801036be <exit+0x1b>
801036b5:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
801036b7:	bb 00 00 00 00       	mov    $0x0,%ebx
801036bc:	eb 10                	jmp    801036ce <exit+0x2b>
    panic("init exiting");
801036be:	83 ec 0c             	sub    $0xc,%esp
801036c1:	68 30 6c 10 80       	push   $0x80106c30
801036c6:	e8 7d cc ff ff       	call   80100348 <panic>
  for(fd = 0; fd < NOFILE; fd++){
801036cb:	83 c3 01             	add    $0x1,%ebx
801036ce:	83 fb 0f             	cmp    $0xf,%ebx
801036d1:	7f 1e                	jg     801036f1 <exit+0x4e>
    if(curproc->ofile[fd]){
801036d3:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
801036d7:	85 c0                	test   %eax,%eax
801036d9:	74 f0                	je     801036cb <exit+0x28>
      fileclose(curproc->ofile[fd]);
801036db:	83 ec 0c             	sub    $0xc,%esp
801036de:	50                   	push   %eax
801036df:	e8 ef d5 ff ff       	call   80100cd3 <fileclose>
      curproc->ofile[fd] = 0;
801036e4:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
801036eb:	00 
801036ec:	83 c4 10             	add    $0x10,%esp
801036ef:	eb da                	jmp    801036cb <exit+0x28>
  begin_op();
801036f1:	e8 66 f1 ff ff       	call   8010285c <begin_op>
  iput(curproc->cwd);
801036f6:	83 ec 0c             	sub    $0xc,%esp
801036f9:	ff 76 68             	pushl  0x68(%esi)
801036fc:	e8 87 df ff ff       	call   80101688 <iput>
  end_op();
80103701:	e8 d0 f1 ff ff       	call   801028d6 <end_op>
  curproc->cwd = 0;
80103706:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
8010370d:	c7 04 24 a0 d6 16 80 	movl   $0x8016d6a0,(%esp)
80103714:	e8 0a 06 00 00       	call   80103d23 <acquire>
  wakeup1(curproc->parent);
80103719:	8b 46 14             	mov    0x14(%esi),%eax
8010371c:	e8 c3 f9 ff ff       	call   801030e4 <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103721:	83 c4 10             	add    $0x10,%esp
80103724:	bb d4 d6 16 80       	mov    $0x8016d6d4,%ebx
80103729:	eb 03                	jmp    8010372e <exit+0x8b>
8010372b:	83 c3 7c             	add    $0x7c,%ebx
8010372e:	81 fb d4 f5 16 80    	cmp    $0x8016f5d4,%ebx
80103734:	73 1a                	jae    80103750 <exit+0xad>
    if(p->parent == curproc){
80103736:	39 73 14             	cmp    %esi,0x14(%ebx)
80103739:	75 f0                	jne    8010372b <exit+0x88>
      p->parent = initproc;
8010373b:	a1 b8 a5 10 80       	mov    0x8010a5b8,%eax
80103740:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
80103743:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103747:	75 e2                	jne    8010372b <exit+0x88>
        wakeup1(initproc);
80103749:	e8 96 f9 ff ff       	call   801030e4 <wakeup1>
8010374e:	eb db                	jmp    8010372b <exit+0x88>
  curproc->state = ZOMBIE;
80103750:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
80103757:	e8 a4 fe ff ff       	call   80103600 <sched>
  panic("zombie exit");
8010375c:	83 ec 0c             	sub    $0xc,%esp
8010375f:	68 3d 6c 10 80       	push   $0x80106c3d
80103764:	e8 df cb ff ff       	call   80100348 <panic>

80103769 <yield>:
{
80103769:	55                   	push   %ebp
8010376a:	89 e5                	mov    %esp,%ebp
8010376c:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
8010376f:	68 a0 d6 16 80       	push   $0x8016d6a0
80103774:	e8 aa 05 00 00       	call   80103d23 <acquire>
  myproc()->state = RUNNABLE;
80103779:	e8 44 fb ff ff       	call   801032c2 <myproc>
8010377e:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80103785:	e8 76 fe ff ff       	call   80103600 <sched>
  release(&ptable.lock);
8010378a:	c7 04 24 a0 d6 16 80 	movl   $0x8016d6a0,(%esp)
80103791:	e8 f2 05 00 00       	call   80103d88 <release>
}
80103796:	83 c4 10             	add    $0x10,%esp
80103799:	c9                   	leave  
8010379a:	c3                   	ret    

8010379b <sleep>:
{
8010379b:	55                   	push   %ebp
8010379c:	89 e5                	mov    %esp,%ebp
8010379e:	56                   	push   %esi
8010379f:	53                   	push   %ebx
801037a0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
801037a3:	e8 1a fb ff ff       	call   801032c2 <myproc>
  if(p == 0)
801037a8:	85 c0                	test   %eax,%eax
801037aa:	74 66                	je     80103812 <sleep+0x77>
801037ac:	89 c6                	mov    %eax,%esi
  if(lk == 0)
801037ae:	85 db                	test   %ebx,%ebx
801037b0:	74 6d                	je     8010381f <sleep+0x84>
  if(lk != &ptable.lock){  //DOC: sleeplock0
801037b2:	81 fb a0 d6 16 80    	cmp    $0x8016d6a0,%ebx
801037b8:	74 18                	je     801037d2 <sleep+0x37>
    acquire(&ptable.lock);  //DOC: sleeplock1
801037ba:	83 ec 0c             	sub    $0xc,%esp
801037bd:	68 a0 d6 16 80       	push   $0x8016d6a0
801037c2:	e8 5c 05 00 00       	call   80103d23 <acquire>
    release(lk);
801037c7:	89 1c 24             	mov    %ebx,(%esp)
801037ca:	e8 b9 05 00 00       	call   80103d88 <release>
801037cf:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
801037d2:	8b 45 08             	mov    0x8(%ebp),%eax
801037d5:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
801037d8:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
801037df:	e8 1c fe ff ff       	call   80103600 <sched>
  p->chan = 0;
801037e4:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if(lk != &ptable.lock){  //DOC: sleeplock2
801037eb:	81 fb a0 d6 16 80    	cmp    $0x8016d6a0,%ebx
801037f1:	74 18                	je     8010380b <sleep+0x70>
    release(&ptable.lock);
801037f3:	83 ec 0c             	sub    $0xc,%esp
801037f6:	68 a0 d6 16 80       	push   $0x8016d6a0
801037fb:	e8 88 05 00 00       	call   80103d88 <release>
    acquire(lk);
80103800:	89 1c 24             	mov    %ebx,(%esp)
80103803:	e8 1b 05 00 00       	call   80103d23 <acquire>
80103808:	83 c4 10             	add    $0x10,%esp
}
8010380b:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010380e:	5b                   	pop    %ebx
8010380f:	5e                   	pop    %esi
80103810:	5d                   	pop    %ebp
80103811:	c3                   	ret    
    panic("sleep");
80103812:	83 ec 0c             	sub    $0xc,%esp
80103815:	68 49 6c 10 80       	push   $0x80106c49
8010381a:	e8 29 cb ff ff       	call   80100348 <panic>
    panic("sleep without lk");
8010381f:	83 ec 0c             	sub    $0xc,%esp
80103822:	68 4f 6c 10 80       	push   $0x80106c4f
80103827:	e8 1c cb ff ff       	call   80100348 <panic>

8010382c <wait>:
{
8010382c:	55                   	push   %ebp
8010382d:	89 e5                	mov    %esp,%ebp
8010382f:	56                   	push   %esi
80103830:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103831:	e8 8c fa ff ff       	call   801032c2 <myproc>
80103836:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
80103838:	83 ec 0c             	sub    $0xc,%esp
8010383b:	68 a0 d6 16 80       	push   $0x8016d6a0
80103840:	e8 de 04 00 00       	call   80103d23 <acquire>
80103845:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
80103848:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010384d:	bb d4 d6 16 80       	mov    $0x8016d6d4,%ebx
80103852:	eb 71                	jmp    801038c5 <wait+0x99>
        pid = p->pid;
80103854:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
80103857:	83 ec 0c             	sub    $0xc,%esp
8010385a:	ff 73 08             	pushl  0x8(%ebx)
8010385d:	e8 42 e7 ff ff       	call   80101fa4 <kfree>
	FRAMES[V2P(p->kstack) >> 12] = -1;
80103862:	8b 43 08             	mov    0x8(%ebx),%eax
80103865:	05 00 00 00 80       	add    $0x80000000,%eax
8010386a:	c1 e8 0c             	shr    $0xc,%eax
8010386d:	c7 04 85 20 ff 10 80 	movl   $0xffffffff,-0x7fef00e0(,%eax,4)
80103874:	ff ff ff ff 
        p->kstack = 0;
80103878:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
8010387f:	83 c4 04             	add    $0x4,%esp
80103882:	ff 73 04             	pushl  0x4(%ebx)
80103885:	e8 ea 2a 00 00       	call   80106374 <freevm>
        p->pid = 0;
8010388a:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
80103891:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
80103898:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
8010389c:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
801038a3:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
801038aa:	c7 04 24 a0 d6 16 80 	movl   $0x8016d6a0,(%esp)
801038b1:	e8 d2 04 00 00       	call   80103d88 <release>
        return pid;
801038b6:	83 c4 10             	add    $0x10,%esp
}
801038b9:	89 f0                	mov    %esi,%eax
801038bb:	8d 65 f8             	lea    -0x8(%ebp),%esp
801038be:	5b                   	pop    %ebx
801038bf:	5e                   	pop    %esi
801038c0:	5d                   	pop    %ebp
801038c1:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801038c2:	83 c3 7c             	add    $0x7c,%ebx
801038c5:	81 fb d4 f5 16 80    	cmp    $0x8016f5d4,%ebx
801038cb:	73 16                	jae    801038e3 <wait+0xb7>
      if(p->parent != curproc)
801038cd:	39 73 14             	cmp    %esi,0x14(%ebx)
801038d0:	75 f0                	jne    801038c2 <wait+0x96>
      if(p->state == ZOMBIE){
801038d2:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
801038d6:	0f 84 78 ff ff ff    	je     80103854 <wait+0x28>
      havekids = 1;
801038dc:	b8 01 00 00 00       	mov    $0x1,%eax
801038e1:	eb df                	jmp    801038c2 <wait+0x96>
    if(!havekids || curproc->killed){
801038e3:	85 c0                	test   %eax,%eax
801038e5:	74 06                	je     801038ed <wait+0xc1>
801038e7:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
801038eb:	74 17                	je     80103904 <wait+0xd8>
      release(&ptable.lock);
801038ed:	83 ec 0c             	sub    $0xc,%esp
801038f0:	68 a0 d6 16 80       	push   $0x8016d6a0
801038f5:	e8 8e 04 00 00       	call   80103d88 <release>
      return -1;
801038fa:	83 c4 10             	add    $0x10,%esp
801038fd:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103902:	eb b5                	jmp    801038b9 <wait+0x8d>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
80103904:	83 ec 08             	sub    $0x8,%esp
80103907:	68 a0 d6 16 80       	push   $0x8016d6a0
8010390c:	56                   	push   %esi
8010390d:	e8 89 fe ff ff       	call   8010379b <sleep>
    havekids = 0;
80103912:	83 c4 10             	add    $0x10,%esp
80103915:	e9 2e ff ff ff       	jmp    80103848 <wait+0x1c>

8010391a <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
8010391a:	55                   	push   %ebp
8010391b:	89 e5                	mov    %esp,%ebp
8010391d:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
80103920:	68 a0 d6 16 80       	push   $0x8016d6a0
80103925:	e8 f9 03 00 00       	call   80103d23 <acquire>
  wakeup1(chan);
8010392a:	8b 45 08             	mov    0x8(%ebp),%eax
8010392d:	e8 b2 f7 ff ff       	call   801030e4 <wakeup1>
  release(&ptable.lock);
80103932:	c7 04 24 a0 d6 16 80 	movl   $0x8016d6a0,(%esp)
80103939:	e8 4a 04 00 00       	call   80103d88 <release>
}
8010393e:	83 c4 10             	add    $0x10,%esp
80103941:	c9                   	leave  
80103942:	c3                   	ret    

80103943 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80103943:	55                   	push   %ebp
80103944:	89 e5                	mov    %esp,%ebp
80103946:	53                   	push   %ebx
80103947:	83 ec 10             	sub    $0x10,%esp
8010394a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
8010394d:	68 a0 d6 16 80       	push   $0x8016d6a0
80103952:	e8 cc 03 00 00       	call   80103d23 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103957:	83 c4 10             	add    $0x10,%esp
8010395a:	b8 d4 d6 16 80       	mov    $0x8016d6d4,%eax
8010395f:	3d d4 f5 16 80       	cmp    $0x8016f5d4,%eax
80103964:	73 3a                	jae    801039a0 <kill+0x5d>
    if(p->pid == pid){
80103966:	39 58 10             	cmp    %ebx,0x10(%eax)
80103969:	74 05                	je     80103970 <kill+0x2d>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010396b:	83 c0 7c             	add    $0x7c,%eax
8010396e:	eb ef                	jmp    8010395f <kill+0x1c>
      p->killed = 1;
80103970:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80103977:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
8010397b:	74 1a                	je     80103997 <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
8010397d:	83 ec 0c             	sub    $0xc,%esp
80103980:	68 a0 d6 16 80       	push   $0x8016d6a0
80103985:	e8 fe 03 00 00       	call   80103d88 <release>
      return 0;
8010398a:	83 c4 10             	add    $0x10,%esp
8010398d:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
80103992:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103995:	c9                   	leave  
80103996:	c3                   	ret    
        p->state = RUNNABLE;
80103997:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
8010399e:	eb dd                	jmp    8010397d <kill+0x3a>
  release(&ptable.lock);
801039a0:	83 ec 0c             	sub    $0xc,%esp
801039a3:	68 a0 d6 16 80       	push   $0x8016d6a0
801039a8:	e8 db 03 00 00       	call   80103d88 <release>
  return -1;
801039ad:	83 c4 10             	add    $0x10,%esp
801039b0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801039b5:	eb db                	jmp    80103992 <kill+0x4f>

801039b7 <dump_physmem>:

//find which process owns each frame of physical memory
int dump_physmem(int *frames, int *pids, int numframes)
{
801039b7:	55                   	push   %ebp
801039b8:	89 e5                	mov    %esp,%ebp
801039ba:	57                   	push   %edi
801039bb:	56                   	push   %esi
801039bc:	53                   	push   %ebx
801039bd:	8b 5d 08             	mov    0x8(%ebp),%ebx
801039c0:	8b 75 0c             	mov    0xc(%ebp),%esi
801039c3:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if(pids <= 0 || frames<=0){
801039c6:	85 f6                	test   %esi,%esi
801039c8:	0f 94 c2             	sete   %dl
801039cb:	85 db                	test   %ebx,%ebx
801039cd:	0f 94 c0             	sete   %al
801039d0:	08 c2                	or     %al,%dl
801039d2:	75 48                	jne    80103a1c <dump_physmem+0x65>
    return -1;
  }
  if(numframes > NFRAME || numframes < 0){
801039d4:	81 f9 00 40 00 00    	cmp    $0x4000,%ecx
801039da:	77 47                	ja     80103a23 <dump_physmem+0x6c>
      pids[index] = FRAMES[i];
      index++;
    }
  }
  */
  for(int i=65; i<log_index; i++){
801039dc:	b8 41 00 00 00       	mov    $0x41,%eax
801039e1:	eb 03                	jmp    801039e6 <dump_physmem+0x2f>
801039e3:	83 c0 01             	add    $0x1,%eax
801039e6:	39 05 2c a9 14 80    	cmp    %eax,0x8014a92c
801039ec:	7e 24                	jle    80103a12 <dump_physmem+0x5b>
    if(i-65 < numframes){
801039ee:	8d 50 bf             	lea    -0x41(%eax),%edx
801039f1:	39 ca                	cmp    %ecx,%edx
801039f3:	7d ee                	jge    801039e3 <dump_physmem+0x2c>
      frames[i-65] = log_frames[i];
801039f5:	8d 14 85 fc fe ff ff 	lea    -0x104(,%eax,4),%edx
801039fc:	8b 3c 85 40 a9 14 80 	mov    -0x7feb56c0(,%eax,4),%edi
80103a03:	89 3c 13             	mov    %edi,(%ebx,%edx,1)
      pids[i-65] = log_pids[i];
80103a06:	8b 3c 85 40 a9 15 80 	mov    -0x7fea56c0(,%eax,4),%edi
80103a0d:	89 3c 16             	mov    %edi,(%esi,%edx,1)
80103a10:	eb d1                	jmp    801039e3 <dump_physmem+0x2c>
      //cprintf("~~~~~~~~~~~index: %d, frame:%d, pid:%d\n", i-65, log_frames[i], log_pids[i]);
    }
  }
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~eeeeee\n");
  return 0;
80103a12:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103a17:	5b                   	pop    %ebx
80103a18:	5e                   	pop    %esi
80103a19:	5f                   	pop    %edi
80103a1a:	5d                   	pop    %ebp
80103a1b:	c3                   	ret    
    return -1;
80103a1c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103a21:	eb f4                	jmp    80103a17 <dump_physmem+0x60>
    return -1;
80103a23:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103a28:	eb ed                	jmp    80103a17 <dump_physmem+0x60>

80103a2a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80103a2a:	55                   	push   %ebp
80103a2b:	89 e5                	mov    %esp,%ebp
80103a2d:	56                   	push   %esi
80103a2e:	53                   	push   %ebx
80103a2f:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103a32:	bb d4 d6 16 80       	mov    $0x8016d6d4,%ebx
80103a37:	eb 33                	jmp    80103a6c <procdump+0x42>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
80103a39:	b8 60 6c 10 80       	mov    $0x80106c60,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
80103a3e:	8d 53 6c             	lea    0x6c(%ebx),%edx
80103a41:	52                   	push   %edx
80103a42:	50                   	push   %eax
80103a43:	ff 73 10             	pushl  0x10(%ebx)
80103a46:	68 64 6c 10 80       	push   $0x80106c64
80103a4b:	e8 bb cb ff ff       	call   8010060b <cprintf>
    if(p->state == SLEEPING){
80103a50:	83 c4 10             	add    $0x10,%esp
80103a53:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
80103a57:	74 39                	je     80103a92 <procdump+0x68>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80103a59:	83 ec 0c             	sub    $0xc,%esp
80103a5c:	68 db 6f 10 80       	push   $0x80106fdb
80103a61:	e8 a5 cb ff ff       	call   8010060b <cprintf>
80103a66:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103a69:	83 c3 7c             	add    $0x7c,%ebx
80103a6c:	81 fb d4 f5 16 80    	cmp    $0x8016f5d4,%ebx
80103a72:	73 61                	jae    80103ad5 <procdump+0xab>
    if(p->state == UNUSED)
80103a74:	8b 43 0c             	mov    0xc(%ebx),%eax
80103a77:	85 c0                	test   %eax,%eax
80103a79:	74 ee                	je     80103a69 <procdump+0x3f>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103a7b:	83 f8 05             	cmp    $0x5,%eax
80103a7e:	77 b9                	ja     80103a39 <procdump+0xf>
80103a80:	8b 04 85 c0 6c 10 80 	mov    -0x7fef9340(,%eax,4),%eax
80103a87:	85 c0                	test   %eax,%eax
80103a89:	75 b3                	jne    80103a3e <procdump+0x14>
      state = "???";
80103a8b:	b8 60 6c 10 80       	mov    $0x80106c60,%eax
80103a90:	eb ac                	jmp    80103a3e <procdump+0x14>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80103a92:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103a95:	8b 40 0c             	mov    0xc(%eax),%eax
80103a98:	83 c0 08             	add    $0x8,%eax
80103a9b:	83 ec 08             	sub    $0x8,%esp
80103a9e:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103aa1:	52                   	push   %edx
80103aa2:	50                   	push   %eax
80103aa3:	e8 5a 01 00 00       	call   80103c02 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80103aa8:	83 c4 10             	add    $0x10,%esp
80103aab:	be 00 00 00 00       	mov    $0x0,%esi
80103ab0:	eb 14                	jmp    80103ac6 <procdump+0x9c>
        cprintf(" %p", pc[i]);
80103ab2:	83 ec 08             	sub    $0x8,%esp
80103ab5:	50                   	push   %eax
80103ab6:	68 a1 66 10 80       	push   $0x801066a1
80103abb:	e8 4b cb ff ff       	call   8010060b <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
80103ac0:	83 c6 01             	add    $0x1,%esi
80103ac3:	83 c4 10             	add    $0x10,%esp
80103ac6:	83 fe 09             	cmp    $0x9,%esi
80103ac9:	7f 8e                	jg     80103a59 <procdump+0x2f>
80103acb:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103acf:	85 c0                	test   %eax,%eax
80103ad1:	75 df                	jne    80103ab2 <procdump+0x88>
80103ad3:	eb 84                	jmp    80103a59 <procdump+0x2f>
  }
}
80103ad5:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103ad8:	5b                   	pop    %ebx
80103ad9:	5e                   	pop    %esi
80103ada:	5d                   	pop    %ebp
80103adb:	c3                   	ret    

80103adc <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103adc:	55                   	push   %ebp
80103add:	89 e5                	mov    %esp,%ebp
80103adf:	53                   	push   %ebx
80103ae0:	83 ec 0c             	sub    $0xc,%esp
80103ae3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103ae6:	68 d8 6c 10 80       	push   $0x80106cd8
80103aeb:	8d 43 04             	lea    0x4(%ebx),%eax
80103aee:	50                   	push   %eax
80103aef:	e8 f3 00 00 00       	call   80103be7 <initlock>
  lk->name = name;
80103af4:	8b 45 0c             	mov    0xc(%ebp),%eax
80103af7:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103afa:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103b00:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103b07:	83 c4 10             	add    $0x10,%esp
80103b0a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103b0d:	c9                   	leave  
80103b0e:	c3                   	ret    

80103b0f <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103b0f:	55                   	push   %ebp
80103b10:	89 e5                	mov    %esp,%ebp
80103b12:	56                   	push   %esi
80103b13:	53                   	push   %ebx
80103b14:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103b17:	8d 73 04             	lea    0x4(%ebx),%esi
80103b1a:	83 ec 0c             	sub    $0xc,%esp
80103b1d:	56                   	push   %esi
80103b1e:	e8 00 02 00 00       	call   80103d23 <acquire>
  while (lk->locked) {
80103b23:	83 c4 10             	add    $0x10,%esp
80103b26:	eb 0d                	jmp    80103b35 <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103b28:	83 ec 08             	sub    $0x8,%esp
80103b2b:	56                   	push   %esi
80103b2c:	53                   	push   %ebx
80103b2d:	e8 69 fc ff ff       	call   8010379b <sleep>
80103b32:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103b35:	83 3b 00             	cmpl   $0x0,(%ebx)
80103b38:	75 ee                	jne    80103b28 <acquiresleep+0x19>
  }
  lk->locked = 1;
80103b3a:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103b40:	e8 7d f7 ff ff       	call   801032c2 <myproc>
80103b45:	8b 40 10             	mov    0x10(%eax),%eax
80103b48:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103b4b:	83 ec 0c             	sub    $0xc,%esp
80103b4e:	56                   	push   %esi
80103b4f:	e8 34 02 00 00       	call   80103d88 <release>
}
80103b54:	83 c4 10             	add    $0x10,%esp
80103b57:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b5a:	5b                   	pop    %ebx
80103b5b:	5e                   	pop    %esi
80103b5c:	5d                   	pop    %ebp
80103b5d:	c3                   	ret    

80103b5e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103b5e:	55                   	push   %ebp
80103b5f:	89 e5                	mov    %esp,%ebp
80103b61:	56                   	push   %esi
80103b62:	53                   	push   %ebx
80103b63:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103b66:	8d 73 04             	lea    0x4(%ebx),%esi
80103b69:	83 ec 0c             	sub    $0xc,%esp
80103b6c:	56                   	push   %esi
80103b6d:	e8 b1 01 00 00       	call   80103d23 <acquire>
  lk->locked = 0;
80103b72:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103b78:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103b7f:	89 1c 24             	mov    %ebx,(%esp)
80103b82:	e8 93 fd ff ff       	call   8010391a <wakeup>
  release(&lk->lk);
80103b87:	89 34 24             	mov    %esi,(%esp)
80103b8a:	e8 f9 01 00 00       	call   80103d88 <release>
}
80103b8f:	83 c4 10             	add    $0x10,%esp
80103b92:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b95:	5b                   	pop    %ebx
80103b96:	5e                   	pop    %esi
80103b97:	5d                   	pop    %ebp
80103b98:	c3                   	ret    

80103b99 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103b99:	55                   	push   %ebp
80103b9a:	89 e5                	mov    %esp,%ebp
80103b9c:	56                   	push   %esi
80103b9d:	53                   	push   %ebx
80103b9e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103ba1:	8d 73 04             	lea    0x4(%ebx),%esi
80103ba4:	83 ec 0c             	sub    $0xc,%esp
80103ba7:	56                   	push   %esi
80103ba8:	e8 76 01 00 00       	call   80103d23 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103bad:	83 c4 10             	add    $0x10,%esp
80103bb0:	83 3b 00             	cmpl   $0x0,(%ebx)
80103bb3:	75 17                	jne    80103bcc <holdingsleep+0x33>
80103bb5:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103bba:	83 ec 0c             	sub    $0xc,%esp
80103bbd:	56                   	push   %esi
80103bbe:	e8 c5 01 00 00       	call   80103d88 <release>
  return r;
}
80103bc3:	89 d8                	mov    %ebx,%eax
80103bc5:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103bc8:	5b                   	pop    %ebx
80103bc9:	5e                   	pop    %esi
80103bca:	5d                   	pop    %ebp
80103bcb:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103bcc:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103bcf:	e8 ee f6 ff ff       	call   801032c2 <myproc>
80103bd4:	3b 58 10             	cmp    0x10(%eax),%ebx
80103bd7:	74 07                	je     80103be0 <holdingsleep+0x47>
80103bd9:	bb 00 00 00 00       	mov    $0x0,%ebx
80103bde:	eb da                	jmp    80103bba <holdingsleep+0x21>
80103be0:	bb 01 00 00 00       	mov    $0x1,%ebx
80103be5:	eb d3                	jmp    80103bba <holdingsleep+0x21>

80103be7 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103be7:	55                   	push   %ebp
80103be8:	89 e5                	mov    %esp,%ebp
80103bea:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103bed:	8b 55 0c             	mov    0xc(%ebp),%edx
80103bf0:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103bf3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103bf9:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103c00:	5d                   	pop    %ebp
80103c01:	c3                   	ret    

80103c02 <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103c02:	55                   	push   %ebp
80103c03:	89 e5                	mov    %esp,%ebp
80103c05:	53                   	push   %ebx
80103c06:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103c09:	8b 45 08             	mov    0x8(%ebp),%eax
80103c0c:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103c0f:	b8 00 00 00 00       	mov    $0x0,%eax
80103c14:	83 f8 09             	cmp    $0x9,%eax
80103c17:	7f 25                	jg     80103c3e <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103c19:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103c1f:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103c25:	77 17                	ja     80103c3e <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103c27:	8b 5a 04             	mov    0x4(%edx),%ebx
80103c2a:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103c2d:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103c2f:	83 c0 01             	add    $0x1,%eax
80103c32:	eb e0                	jmp    80103c14 <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103c34:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103c3b:	83 c0 01             	add    $0x1,%eax
80103c3e:	83 f8 09             	cmp    $0x9,%eax
80103c41:	7e f1                	jle    80103c34 <getcallerpcs+0x32>
}
80103c43:	5b                   	pop    %ebx
80103c44:	5d                   	pop    %ebp
80103c45:	c3                   	ret    

80103c46 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103c46:	55                   	push   %ebp
80103c47:	89 e5                	mov    %esp,%ebp
80103c49:	53                   	push   %ebx
80103c4a:	83 ec 04             	sub    $0x4,%esp
80103c4d:	9c                   	pushf  
80103c4e:	5b                   	pop    %ebx
  asm volatile("cli");
80103c4f:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103c50:	e8 f6 f5 ff ff       	call   8010324b <mycpu>
80103c55:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103c5c:	74 12                	je     80103c70 <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103c5e:	e8 e8 f5 ff ff       	call   8010324b <mycpu>
80103c63:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103c6a:	83 c4 04             	add    $0x4,%esp
80103c6d:	5b                   	pop    %ebx
80103c6e:	5d                   	pop    %ebp
80103c6f:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103c70:	e8 d6 f5 ff ff       	call   8010324b <mycpu>
80103c75:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103c7b:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103c81:	eb db                	jmp    80103c5e <pushcli+0x18>

80103c83 <popcli>:

void
popcli(void)
{
80103c83:	55                   	push   %ebp
80103c84:	89 e5                	mov    %esp,%ebp
80103c86:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103c89:	9c                   	pushf  
80103c8a:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103c8b:	f6 c4 02             	test   $0x2,%ah
80103c8e:	75 28                	jne    80103cb8 <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103c90:	e8 b6 f5 ff ff       	call   8010324b <mycpu>
80103c95:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103c9b:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103c9e:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103ca4:	85 d2                	test   %edx,%edx
80103ca6:	78 1d                	js     80103cc5 <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103ca8:	e8 9e f5 ff ff       	call   8010324b <mycpu>
80103cad:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103cb4:	74 1c                	je     80103cd2 <popcli+0x4f>
    sti();
}
80103cb6:	c9                   	leave  
80103cb7:	c3                   	ret    
    panic("popcli - interruptible");
80103cb8:	83 ec 0c             	sub    $0xc,%esp
80103cbb:	68 e3 6c 10 80       	push   $0x80106ce3
80103cc0:	e8 83 c6 ff ff       	call   80100348 <panic>
    panic("popcli");
80103cc5:	83 ec 0c             	sub    $0xc,%esp
80103cc8:	68 fa 6c 10 80       	push   $0x80106cfa
80103ccd:	e8 76 c6 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103cd2:	e8 74 f5 ff ff       	call   8010324b <mycpu>
80103cd7:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103cde:	74 d6                	je     80103cb6 <popcli+0x33>
  asm volatile("sti");
80103ce0:	fb                   	sti    
}
80103ce1:	eb d3                	jmp    80103cb6 <popcli+0x33>

80103ce3 <holding>:
{
80103ce3:	55                   	push   %ebp
80103ce4:	89 e5                	mov    %esp,%ebp
80103ce6:	53                   	push   %ebx
80103ce7:	83 ec 04             	sub    $0x4,%esp
80103cea:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103ced:	e8 54 ff ff ff       	call   80103c46 <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103cf2:	83 3b 00             	cmpl   $0x0,(%ebx)
80103cf5:	75 12                	jne    80103d09 <holding+0x26>
80103cf7:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103cfc:	e8 82 ff ff ff       	call   80103c83 <popcli>
}
80103d01:	89 d8                	mov    %ebx,%eax
80103d03:	83 c4 04             	add    $0x4,%esp
80103d06:	5b                   	pop    %ebx
80103d07:	5d                   	pop    %ebp
80103d08:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103d09:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103d0c:	e8 3a f5 ff ff       	call   8010324b <mycpu>
80103d11:	39 c3                	cmp    %eax,%ebx
80103d13:	74 07                	je     80103d1c <holding+0x39>
80103d15:	bb 00 00 00 00       	mov    $0x0,%ebx
80103d1a:	eb e0                	jmp    80103cfc <holding+0x19>
80103d1c:	bb 01 00 00 00       	mov    $0x1,%ebx
80103d21:	eb d9                	jmp    80103cfc <holding+0x19>

80103d23 <acquire>:
{
80103d23:	55                   	push   %ebp
80103d24:	89 e5                	mov    %esp,%ebp
80103d26:	53                   	push   %ebx
80103d27:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103d2a:	e8 17 ff ff ff       	call   80103c46 <pushcli>
  if(holding(lk))
80103d2f:	83 ec 0c             	sub    $0xc,%esp
80103d32:	ff 75 08             	pushl  0x8(%ebp)
80103d35:	e8 a9 ff ff ff       	call   80103ce3 <holding>
80103d3a:	83 c4 10             	add    $0x10,%esp
80103d3d:	85 c0                	test   %eax,%eax
80103d3f:	75 3a                	jne    80103d7b <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103d41:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103d44:	b8 01 00 00 00       	mov    $0x1,%eax
80103d49:	f0 87 02             	lock xchg %eax,(%edx)
80103d4c:	85 c0                	test   %eax,%eax
80103d4e:	75 f1                	jne    80103d41 <acquire+0x1e>
  __sync_synchronize();
80103d50:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103d55:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103d58:	e8 ee f4 ff ff       	call   8010324b <mycpu>
80103d5d:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103d60:	8b 45 08             	mov    0x8(%ebp),%eax
80103d63:	83 c0 0c             	add    $0xc,%eax
80103d66:	83 ec 08             	sub    $0x8,%esp
80103d69:	50                   	push   %eax
80103d6a:	8d 45 08             	lea    0x8(%ebp),%eax
80103d6d:	50                   	push   %eax
80103d6e:	e8 8f fe ff ff       	call   80103c02 <getcallerpcs>
}
80103d73:	83 c4 10             	add    $0x10,%esp
80103d76:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103d79:	c9                   	leave  
80103d7a:	c3                   	ret    
    panic("acquire");
80103d7b:	83 ec 0c             	sub    $0xc,%esp
80103d7e:	68 01 6d 10 80       	push   $0x80106d01
80103d83:	e8 c0 c5 ff ff       	call   80100348 <panic>

80103d88 <release>:
{
80103d88:	55                   	push   %ebp
80103d89:	89 e5                	mov    %esp,%ebp
80103d8b:	53                   	push   %ebx
80103d8c:	83 ec 10             	sub    $0x10,%esp
80103d8f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103d92:	53                   	push   %ebx
80103d93:	e8 4b ff ff ff       	call   80103ce3 <holding>
80103d98:	83 c4 10             	add    $0x10,%esp
80103d9b:	85 c0                	test   %eax,%eax
80103d9d:	74 23                	je     80103dc2 <release+0x3a>
  lk->pcs[0] = 0;
80103d9f:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103da6:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103dad:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103db2:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103db8:	e8 c6 fe ff ff       	call   80103c83 <popcli>
}
80103dbd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103dc0:	c9                   	leave  
80103dc1:	c3                   	ret    
    panic("release");
80103dc2:	83 ec 0c             	sub    $0xc,%esp
80103dc5:	68 09 6d 10 80       	push   $0x80106d09
80103dca:	e8 79 c5 ff ff       	call   80100348 <panic>

80103dcf <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103dcf:	55                   	push   %ebp
80103dd0:	89 e5                	mov    %esp,%ebp
80103dd2:	57                   	push   %edi
80103dd3:	53                   	push   %ebx
80103dd4:	8b 55 08             	mov    0x8(%ebp),%edx
80103dd7:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103dda:	f6 c2 03             	test   $0x3,%dl
80103ddd:	75 05                	jne    80103de4 <memset+0x15>
80103ddf:	f6 c1 03             	test   $0x3,%cl
80103de2:	74 0e                	je     80103df2 <memset+0x23>
  asm volatile("cld; rep stosb" :
80103de4:	89 d7                	mov    %edx,%edi
80103de6:	8b 45 0c             	mov    0xc(%ebp),%eax
80103de9:	fc                   	cld    
80103dea:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80103dec:	89 d0                	mov    %edx,%eax
80103dee:	5b                   	pop    %ebx
80103def:	5f                   	pop    %edi
80103df0:	5d                   	pop    %ebp
80103df1:	c3                   	ret    
    c &= 0xFF;
80103df2:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103df6:	c1 e9 02             	shr    $0x2,%ecx
80103df9:	89 f8                	mov    %edi,%eax
80103dfb:	c1 e0 18             	shl    $0x18,%eax
80103dfe:	89 fb                	mov    %edi,%ebx
80103e00:	c1 e3 10             	shl    $0x10,%ebx
80103e03:	09 d8                	or     %ebx,%eax
80103e05:	89 fb                	mov    %edi,%ebx
80103e07:	c1 e3 08             	shl    $0x8,%ebx
80103e0a:	09 d8                	or     %ebx,%eax
80103e0c:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103e0e:	89 d7                	mov    %edx,%edi
80103e10:	fc                   	cld    
80103e11:	f3 ab                	rep stos %eax,%es:(%edi)
80103e13:	eb d7                	jmp    80103dec <memset+0x1d>

80103e15 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103e15:	55                   	push   %ebp
80103e16:	89 e5                	mov    %esp,%ebp
80103e18:	56                   	push   %esi
80103e19:	53                   	push   %ebx
80103e1a:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103e1d:	8b 55 0c             	mov    0xc(%ebp),%edx
80103e20:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103e23:	8d 70 ff             	lea    -0x1(%eax),%esi
80103e26:	85 c0                	test   %eax,%eax
80103e28:	74 1c                	je     80103e46 <memcmp+0x31>
    if(*s1 != *s2)
80103e2a:	0f b6 01             	movzbl (%ecx),%eax
80103e2d:	0f b6 1a             	movzbl (%edx),%ebx
80103e30:	38 d8                	cmp    %bl,%al
80103e32:	75 0a                	jne    80103e3e <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
80103e34:	83 c1 01             	add    $0x1,%ecx
80103e37:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103e3a:	89 f0                	mov    %esi,%eax
80103e3c:	eb e5                	jmp    80103e23 <memcmp+0xe>
      return *s1 - *s2;
80103e3e:	0f b6 c0             	movzbl %al,%eax
80103e41:	0f b6 db             	movzbl %bl,%ebx
80103e44:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103e46:	5b                   	pop    %ebx
80103e47:	5e                   	pop    %esi
80103e48:	5d                   	pop    %ebp
80103e49:	c3                   	ret    

80103e4a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103e4a:	55                   	push   %ebp
80103e4b:	89 e5                	mov    %esp,%ebp
80103e4d:	56                   	push   %esi
80103e4e:	53                   	push   %ebx
80103e4f:	8b 45 08             	mov    0x8(%ebp),%eax
80103e52:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103e55:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80103e58:	39 c1                	cmp    %eax,%ecx
80103e5a:	73 3a                	jae    80103e96 <memmove+0x4c>
80103e5c:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
80103e5f:	39 c3                	cmp    %eax,%ebx
80103e61:	76 37                	jbe    80103e9a <memmove+0x50>
    s += n;
    d += n;
80103e63:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80103e66:	eb 0d                	jmp    80103e75 <memmove+0x2b>
      *--d = *--s;
80103e68:	83 eb 01             	sub    $0x1,%ebx
80103e6b:	83 e9 01             	sub    $0x1,%ecx
80103e6e:	0f b6 13             	movzbl (%ebx),%edx
80103e71:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
80103e73:	89 f2                	mov    %esi,%edx
80103e75:	8d 72 ff             	lea    -0x1(%edx),%esi
80103e78:	85 d2                	test   %edx,%edx
80103e7a:	75 ec                	jne    80103e68 <memmove+0x1e>
80103e7c:	eb 14                	jmp    80103e92 <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80103e7e:	0f b6 11             	movzbl (%ecx),%edx
80103e81:	88 13                	mov    %dl,(%ebx)
80103e83:	8d 5b 01             	lea    0x1(%ebx),%ebx
80103e86:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80103e89:	89 f2                	mov    %esi,%edx
80103e8b:	8d 72 ff             	lea    -0x1(%edx),%esi
80103e8e:	85 d2                	test   %edx,%edx
80103e90:	75 ec                	jne    80103e7e <memmove+0x34>

  return dst;
}
80103e92:	5b                   	pop    %ebx
80103e93:	5e                   	pop    %esi
80103e94:	5d                   	pop    %ebp
80103e95:	c3                   	ret    
80103e96:	89 c3                	mov    %eax,%ebx
80103e98:	eb f1                	jmp    80103e8b <memmove+0x41>
80103e9a:	89 c3                	mov    %eax,%ebx
80103e9c:	eb ed                	jmp    80103e8b <memmove+0x41>

80103e9e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80103e9e:	55                   	push   %ebp
80103e9f:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80103ea1:	ff 75 10             	pushl  0x10(%ebp)
80103ea4:	ff 75 0c             	pushl  0xc(%ebp)
80103ea7:	ff 75 08             	pushl  0x8(%ebp)
80103eaa:	e8 9b ff ff ff       	call   80103e4a <memmove>
}
80103eaf:	c9                   	leave  
80103eb0:	c3                   	ret    

80103eb1 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80103eb1:	55                   	push   %ebp
80103eb2:	89 e5                	mov    %esp,%ebp
80103eb4:	53                   	push   %ebx
80103eb5:	8b 55 08             	mov    0x8(%ebp),%edx
80103eb8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103ebb:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80103ebe:	eb 09                	jmp    80103ec9 <strncmp+0x18>
    n--, p++, q++;
80103ec0:	83 e8 01             	sub    $0x1,%eax
80103ec3:	83 c2 01             	add    $0x1,%edx
80103ec6:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80103ec9:	85 c0                	test   %eax,%eax
80103ecb:	74 0b                	je     80103ed8 <strncmp+0x27>
80103ecd:	0f b6 1a             	movzbl (%edx),%ebx
80103ed0:	84 db                	test   %bl,%bl
80103ed2:	74 04                	je     80103ed8 <strncmp+0x27>
80103ed4:	3a 19                	cmp    (%ecx),%bl
80103ed6:	74 e8                	je     80103ec0 <strncmp+0xf>
  if(n == 0)
80103ed8:	85 c0                	test   %eax,%eax
80103eda:	74 0b                	je     80103ee7 <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
80103edc:	0f b6 02             	movzbl (%edx),%eax
80103edf:	0f b6 11             	movzbl (%ecx),%edx
80103ee2:	29 d0                	sub    %edx,%eax
}
80103ee4:	5b                   	pop    %ebx
80103ee5:	5d                   	pop    %ebp
80103ee6:	c3                   	ret    
    return 0;
80103ee7:	b8 00 00 00 00       	mov    $0x0,%eax
80103eec:	eb f6                	jmp    80103ee4 <strncmp+0x33>

80103eee <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80103eee:	55                   	push   %ebp
80103eef:	89 e5                	mov    %esp,%ebp
80103ef1:	57                   	push   %edi
80103ef2:	56                   	push   %esi
80103ef3:	53                   	push   %ebx
80103ef4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103ef7:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80103efa:	8b 45 08             	mov    0x8(%ebp),%eax
80103efd:	eb 04                	jmp    80103f03 <strncpy+0x15>
80103eff:	89 fb                	mov    %edi,%ebx
80103f01:	89 f0                	mov    %esi,%eax
80103f03:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103f06:	85 c9                	test   %ecx,%ecx
80103f08:	7e 1d                	jle    80103f27 <strncpy+0x39>
80103f0a:	8d 7b 01             	lea    0x1(%ebx),%edi
80103f0d:	8d 70 01             	lea    0x1(%eax),%esi
80103f10:	0f b6 1b             	movzbl (%ebx),%ebx
80103f13:	88 18                	mov    %bl,(%eax)
80103f15:	89 d1                	mov    %edx,%ecx
80103f17:	84 db                	test   %bl,%bl
80103f19:	75 e4                	jne    80103eff <strncpy+0x11>
80103f1b:	89 f0                	mov    %esi,%eax
80103f1d:	eb 08                	jmp    80103f27 <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
80103f1f:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
80103f22:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
80103f24:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
80103f27:	8d 4a ff             	lea    -0x1(%edx),%ecx
80103f2a:	85 d2                	test   %edx,%edx
80103f2c:	7f f1                	jg     80103f1f <strncpy+0x31>
  return os;
}
80103f2e:	8b 45 08             	mov    0x8(%ebp),%eax
80103f31:	5b                   	pop    %ebx
80103f32:	5e                   	pop    %esi
80103f33:	5f                   	pop    %edi
80103f34:	5d                   	pop    %ebp
80103f35:	c3                   	ret    

80103f36 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80103f36:	55                   	push   %ebp
80103f37:	89 e5                	mov    %esp,%ebp
80103f39:	57                   	push   %edi
80103f3a:	56                   	push   %esi
80103f3b:	53                   	push   %ebx
80103f3c:	8b 45 08             	mov    0x8(%ebp),%eax
80103f3f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103f42:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
80103f45:	85 d2                	test   %edx,%edx
80103f47:	7e 23                	jle    80103f6c <safestrcpy+0x36>
80103f49:	89 c1                	mov    %eax,%ecx
80103f4b:	eb 04                	jmp    80103f51 <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80103f4d:	89 fb                	mov    %edi,%ebx
80103f4f:	89 f1                	mov    %esi,%ecx
80103f51:	83 ea 01             	sub    $0x1,%edx
80103f54:	85 d2                	test   %edx,%edx
80103f56:	7e 11                	jle    80103f69 <safestrcpy+0x33>
80103f58:	8d 7b 01             	lea    0x1(%ebx),%edi
80103f5b:	8d 71 01             	lea    0x1(%ecx),%esi
80103f5e:	0f b6 1b             	movzbl (%ebx),%ebx
80103f61:	88 19                	mov    %bl,(%ecx)
80103f63:	84 db                	test   %bl,%bl
80103f65:	75 e6                	jne    80103f4d <safestrcpy+0x17>
80103f67:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
80103f69:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
80103f6c:	5b                   	pop    %ebx
80103f6d:	5e                   	pop    %esi
80103f6e:	5f                   	pop    %edi
80103f6f:	5d                   	pop    %ebp
80103f70:	c3                   	ret    

80103f71 <strlen>:

int
strlen(const char *s)
{
80103f71:	55                   	push   %ebp
80103f72:	89 e5                	mov    %esp,%ebp
80103f74:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80103f77:	b8 00 00 00 00       	mov    $0x0,%eax
80103f7c:	eb 03                	jmp    80103f81 <strlen+0x10>
80103f7e:	83 c0 01             	add    $0x1,%eax
80103f81:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80103f85:	75 f7                	jne    80103f7e <strlen+0xd>
    ;
  return n;
}
80103f87:	5d                   	pop    %ebp
80103f88:	c3                   	ret    

80103f89 <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80103f89:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80103f8d:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
80103f91:	55                   	push   %ebp
  pushl %ebx
80103f92:	53                   	push   %ebx
  pushl %esi
80103f93:	56                   	push   %esi
  pushl %edi
80103f94:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80103f95:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80103f97:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80103f99:	5f                   	pop    %edi
  popl %esi
80103f9a:	5e                   	pop    %esi
  popl %ebx
80103f9b:	5b                   	pop    %ebx
  popl %ebp
80103f9c:	5d                   	pop    %ebp
  ret
80103f9d:	c3                   	ret    

80103f9e <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80103f9e:	55                   	push   %ebp
80103f9f:	89 e5                	mov    %esp,%ebp
80103fa1:	53                   	push   %ebx
80103fa2:	83 ec 04             	sub    $0x4,%esp
80103fa5:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80103fa8:	e8 15 f3 ff ff       	call   801032c2 <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80103fad:	8b 00                	mov    (%eax),%eax
80103faf:	39 d8                	cmp    %ebx,%eax
80103fb1:	76 19                	jbe    80103fcc <fetchint+0x2e>
80103fb3:	8d 53 04             	lea    0x4(%ebx),%edx
80103fb6:	39 d0                	cmp    %edx,%eax
80103fb8:	72 19                	jb     80103fd3 <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
80103fba:	8b 13                	mov    (%ebx),%edx
80103fbc:	8b 45 0c             	mov    0xc(%ebp),%eax
80103fbf:	89 10                	mov    %edx,(%eax)
  return 0;
80103fc1:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103fc6:	83 c4 04             	add    $0x4,%esp
80103fc9:	5b                   	pop    %ebx
80103fca:	5d                   	pop    %ebp
80103fcb:	c3                   	ret    
    return -1;
80103fcc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103fd1:	eb f3                	jmp    80103fc6 <fetchint+0x28>
80103fd3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103fd8:	eb ec                	jmp    80103fc6 <fetchint+0x28>

80103fda <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80103fda:	55                   	push   %ebp
80103fdb:	89 e5                	mov    %esp,%ebp
80103fdd:	53                   	push   %ebx
80103fde:	83 ec 04             	sub    $0x4,%esp
80103fe1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
80103fe4:	e8 d9 f2 ff ff       	call   801032c2 <myproc>

  if(addr >= curproc->sz)
80103fe9:	39 18                	cmp    %ebx,(%eax)
80103feb:	76 26                	jbe    80104013 <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
80103fed:	8b 55 0c             	mov    0xc(%ebp),%edx
80103ff0:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
80103ff2:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
80103ff4:	89 d8                	mov    %ebx,%eax
80103ff6:	39 d0                	cmp    %edx,%eax
80103ff8:	73 0e                	jae    80104008 <fetchstr+0x2e>
    if(*s == 0)
80103ffa:	80 38 00             	cmpb   $0x0,(%eax)
80103ffd:	74 05                	je     80104004 <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
80103fff:	83 c0 01             	add    $0x1,%eax
80104002:	eb f2                	jmp    80103ff6 <fetchstr+0x1c>
      return s - *pp;
80104004:	29 d8                	sub    %ebx,%eax
80104006:	eb 05                	jmp    8010400d <fetchstr+0x33>
  }
  return -1;
80104008:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010400d:	83 c4 04             	add    $0x4,%esp
80104010:	5b                   	pop    %ebx
80104011:	5d                   	pop    %ebp
80104012:	c3                   	ret    
    return -1;
80104013:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104018:	eb f3                	jmp    8010400d <fetchstr+0x33>

8010401a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
8010401a:	55                   	push   %ebp
8010401b:	89 e5                	mov    %esp,%ebp
8010401d:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
80104020:	e8 9d f2 ff ff       	call   801032c2 <myproc>
80104025:	8b 50 18             	mov    0x18(%eax),%edx
80104028:	8b 45 08             	mov    0x8(%ebp),%eax
8010402b:	c1 e0 02             	shl    $0x2,%eax
8010402e:	03 42 44             	add    0x44(%edx),%eax
80104031:	83 ec 08             	sub    $0x8,%esp
80104034:	ff 75 0c             	pushl  0xc(%ebp)
80104037:	83 c0 04             	add    $0x4,%eax
8010403a:	50                   	push   %eax
8010403b:	e8 5e ff ff ff       	call   80103f9e <fetchint>
}
80104040:	c9                   	leave  
80104041:	c3                   	ret    

80104042 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80104042:	55                   	push   %ebp
80104043:	89 e5                	mov    %esp,%ebp
80104045:	56                   	push   %esi
80104046:	53                   	push   %ebx
80104047:	83 ec 10             	sub    $0x10,%esp
8010404a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
8010404d:	e8 70 f2 ff ff       	call   801032c2 <myproc>
80104052:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
80104054:	83 ec 08             	sub    $0x8,%esp
80104057:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010405a:	50                   	push   %eax
8010405b:	ff 75 08             	pushl  0x8(%ebp)
8010405e:	e8 b7 ff ff ff       	call   8010401a <argint>
80104063:	83 c4 10             	add    $0x10,%esp
80104066:	85 c0                	test   %eax,%eax
80104068:	78 24                	js     8010408e <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
8010406a:	85 db                	test   %ebx,%ebx
8010406c:	78 27                	js     80104095 <argptr+0x53>
8010406e:	8b 16                	mov    (%esi),%edx
80104070:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104073:	39 c2                	cmp    %eax,%edx
80104075:	76 25                	jbe    8010409c <argptr+0x5a>
80104077:	01 c3                	add    %eax,%ebx
80104079:	39 da                	cmp    %ebx,%edx
8010407b:	72 26                	jb     801040a3 <argptr+0x61>
    return -1;
  *pp = (char*)i;
8010407d:	8b 55 0c             	mov    0xc(%ebp),%edx
80104080:	89 02                	mov    %eax,(%edx)
  return 0;
80104082:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104087:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010408a:	5b                   	pop    %ebx
8010408b:	5e                   	pop    %esi
8010408c:	5d                   	pop    %ebp
8010408d:	c3                   	ret    
    return -1;
8010408e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104093:	eb f2                	jmp    80104087 <argptr+0x45>
    return -1;
80104095:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010409a:	eb eb                	jmp    80104087 <argptr+0x45>
8010409c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040a1:	eb e4                	jmp    80104087 <argptr+0x45>
801040a3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040a8:	eb dd                	jmp    80104087 <argptr+0x45>

801040aa <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
801040aa:	55                   	push   %ebp
801040ab:	89 e5                	mov    %esp,%ebp
801040ad:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
801040b0:	8d 45 f4             	lea    -0xc(%ebp),%eax
801040b3:	50                   	push   %eax
801040b4:	ff 75 08             	pushl  0x8(%ebp)
801040b7:	e8 5e ff ff ff       	call   8010401a <argint>
801040bc:	83 c4 10             	add    $0x10,%esp
801040bf:	85 c0                	test   %eax,%eax
801040c1:	78 13                	js     801040d6 <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
801040c3:	83 ec 08             	sub    $0x8,%esp
801040c6:	ff 75 0c             	pushl  0xc(%ebp)
801040c9:	ff 75 f4             	pushl  -0xc(%ebp)
801040cc:	e8 09 ff ff ff       	call   80103fda <fetchstr>
801040d1:	83 c4 10             	add    $0x10,%esp
}
801040d4:	c9                   	leave  
801040d5:	c3                   	ret    
    return -1;
801040d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040db:	eb f7                	jmp    801040d4 <argstr+0x2a>

801040dd <syscall>:
[SYS_dump_physmem] sys_dump_physmem,
};

void
syscall(void)
{
801040dd:	55                   	push   %ebp
801040de:	89 e5                	mov    %esp,%ebp
801040e0:	53                   	push   %ebx
801040e1:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
801040e4:	e8 d9 f1 ff ff       	call   801032c2 <myproc>
801040e9:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
801040eb:	8b 40 18             	mov    0x18(%eax),%eax
801040ee:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
801040f1:	8d 50 ff             	lea    -0x1(%eax),%edx
801040f4:	83 fa 15             	cmp    $0x15,%edx
801040f7:	77 18                	ja     80104111 <syscall+0x34>
801040f9:	8b 14 85 40 6d 10 80 	mov    -0x7fef92c0(,%eax,4),%edx
80104100:	85 d2                	test   %edx,%edx
80104102:	74 0d                	je     80104111 <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
80104104:	ff d2                	call   *%edx
80104106:	8b 53 18             	mov    0x18(%ebx),%edx
80104109:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
8010410c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010410f:	c9                   	leave  
80104110:	c3                   	ret    
            curproc->pid, curproc->name, num);
80104111:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
80104114:	50                   	push   %eax
80104115:	52                   	push   %edx
80104116:	ff 73 10             	pushl  0x10(%ebx)
80104119:	68 11 6d 10 80       	push   $0x80106d11
8010411e:	e8 e8 c4 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
80104123:	8b 43 18             	mov    0x18(%ebx),%eax
80104126:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
8010412d:	83 c4 10             	add    $0x10,%esp
}
80104130:	eb da                	jmp    8010410c <syscall+0x2f>

80104132 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80104132:	55                   	push   %ebp
80104133:	89 e5                	mov    %esp,%ebp
80104135:	56                   	push   %esi
80104136:	53                   	push   %ebx
80104137:	83 ec 18             	sub    $0x18,%esp
8010413a:	89 d6                	mov    %edx,%esi
8010413c:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
8010413e:	8d 55 f4             	lea    -0xc(%ebp),%edx
80104141:	52                   	push   %edx
80104142:	50                   	push   %eax
80104143:	e8 d2 fe ff ff       	call   8010401a <argint>
80104148:	83 c4 10             	add    $0x10,%esp
8010414b:	85 c0                	test   %eax,%eax
8010414d:	78 2e                	js     8010417d <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
8010414f:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
80104153:	77 2f                	ja     80104184 <argfd+0x52>
80104155:	e8 68 f1 ff ff       	call   801032c2 <myproc>
8010415a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010415d:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
80104161:	85 c0                	test   %eax,%eax
80104163:	74 26                	je     8010418b <argfd+0x59>
    return -1;
  if(pfd)
80104165:	85 f6                	test   %esi,%esi
80104167:	74 02                	je     8010416b <argfd+0x39>
    *pfd = fd;
80104169:	89 16                	mov    %edx,(%esi)
  if(pf)
8010416b:	85 db                	test   %ebx,%ebx
8010416d:	74 23                	je     80104192 <argfd+0x60>
    *pf = f;
8010416f:	89 03                	mov    %eax,(%ebx)
  return 0;
80104171:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104176:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104179:	5b                   	pop    %ebx
8010417a:	5e                   	pop    %esi
8010417b:	5d                   	pop    %ebp
8010417c:	c3                   	ret    
    return -1;
8010417d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104182:	eb f2                	jmp    80104176 <argfd+0x44>
    return -1;
80104184:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104189:	eb eb                	jmp    80104176 <argfd+0x44>
8010418b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104190:	eb e4                	jmp    80104176 <argfd+0x44>
  return 0;
80104192:	b8 00 00 00 00       	mov    $0x0,%eax
80104197:	eb dd                	jmp    80104176 <argfd+0x44>

80104199 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80104199:	55                   	push   %ebp
8010419a:	89 e5                	mov    %esp,%ebp
8010419c:	53                   	push   %ebx
8010419d:	83 ec 04             	sub    $0x4,%esp
801041a0:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
801041a2:	e8 1b f1 ff ff       	call   801032c2 <myproc>

  for(fd = 0; fd < NOFILE; fd++){
801041a7:	ba 00 00 00 00       	mov    $0x0,%edx
801041ac:	83 fa 0f             	cmp    $0xf,%edx
801041af:	7f 18                	jg     801041c9 <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
801041b1:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
801041b6:	74 05                	je     801041bd <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
801041b8:	83 c2 01             	add    $0x1,%edx
801041bb:	eb ef                	jmp    801041ac <fdalloc+0x13>
      curproc->ofile[fd] = f;
801041bd:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
801041c1:	89 d0                	mov    %edx,%eax
801041c3:	83 c4 04             	add    $0x4,%esp
801041c6:	5b                   	pop    %ebx
801041c7:	5d                   	pop    %ebp
801041c8:	c3                   	ret    
  return -1;
801041c9:	ba ff ff ff ff       	mov    $0xffffffff,%edx
801041ce:	eb f1                	jmp    801041c1 <fdalloc+0x28>

801041d0 <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
801041d0:	55                   	push   %ebp
801041d1:	89 e5                	mov    %esp,%ebp
801041d3:	56                   	push   %esi
801041d4:	53                   	push   %ebx
801041d5:	83 ec 10             	sub    $0x10,%esp
801041d8:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801041da:	b8 20 00 00 00       	mov    $0x20,%eax
801041df:	89 c6                	mov    %eax,%esi
801041e1:	39 43 58             	cmp    %eax,0x58(%ebx)
801041e4:	76 2e                	jbe    80104214 <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801041e6:	6a 10                	push   $0x10
801041e8:	50                   	push   %eax
801041e9:	8d 45 e8             	lea    -0x18(%ebp),%eax
801041ec:	50                   	push   %eax
801041ed:	53                   	push   %ebx
801041ee:	e8 80 d5 ff ff       	call   80101773 <readi>
801041f3:	83 c4 10             	add    $0x10,%esp
801041f6:	83 f8 10             	cmp    $0x10,%eax
801041f9:	75 0c                	jne    80104207 <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
801041fb:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
80104200:	75 1e                	jne    80104220 <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80104202:	8d 46 10             	lea    0x10(%esi),%eax
80104205:	eb d8                	jmp    801041df <isdirempty+0xf>
      panic("isdirempty: readi");
80104207:	83 ec 0c             	sub    $0xc,%esp
8010420a:	68 9c 6d 10 80       	push   $0x80106d9c
8010420f:	e8 34 c1 ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
80104214:	b8 01 00 00 00       	mov    $0x1,%eax
}
80104219:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010421c:	5b                   	pop    %ebx
8010421d:	5e                   	pop    %esi
8010421e:	5d                   	pop    %ebp
8010421f:	c3                   	ret    
      return 0;
80104220:	b8 00 00 00 00       	mov    $0x0,%eax
80104225:	eb f2                	jmp    80104219 <isdirempty+0x49>

80104227 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
80104227:	55                   	push   %ebp
80104228:	89 e5                	mov    %esp,%ebp
8010422a:	57                   	push   %edi
8010422b:	56                   	push   %esi
8010422c:	53                   	push   %ebx
8010422d:	83 ec 44             	sub    $0x44,%esp
80104230:	89 55 c4             	mov    %edx,-0x3c(%ebp)
80104233:	89 4d c0             	mov    %ecx,-0x40(%ebp)
80104236:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80104239:	8d 55 d6             	lea    -0x2a(%ebp),%edx
8010423c:	52                   	push   %edx
8010423d:	50                   	push   %eax
8010423e:	e8 b6 d9 ff ff       	call   80101bf9 <nameiparent>
80104243:	89 c6                	mov    %eax,%esi
80104245:	83 c4 10             	add    $0x10,%esp
80104248:	85 c0                	test   %eax,%eax
8010424a:	0f 84 3a 01 00 00    	je     8010438a <create+0x163>
    return 0;
  ilock(dp);
80104250:	83 ec 0c             	sub    $0xc,%esp
80104253:	50                   	push   %eax
80104254:	e8 28 d3 ff ff       	call   80101581 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80104259:	83 c4 0c             	add    $0xc,%esp
8010425c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010425f:	50                   	push   %eax
80104260:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104263:	50                   	push   %eax
80104264:	56                   	push   %esi
80104265:	e8 46 d7 ff ff       	call   801019b0 <dirlookup>
8010426a:	89 c3                	mov    %eax,%ebx
8010426c:	83 c4 10             	add    $0x10,%esp
8010426f:	85 c0                	test   %eax,%eax
80104271:	74 3f                	je     801042b2 <create+0x8b>
    iunlockput(dp);
80104273:	83 ec 0c             	sub    $0xc,%esp
80104276:	56                   	push   %esi
80104277:	e8 ac d4 ff ff       	call   80101728 <iunlockput>
    ilock(ip);
8010427c:	89 1c 24             	mov    %ebx,(%esp)
8010427f:	e8 fd d2 ff ff       	call   80101581 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80104284:	83 c4 10             	add    $0x10,%esp
80104287:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
8010428c:	75 11                	jne    8010429f <create+0x78>
8010428e:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
80104293:	75 0a                	jne    8010429f <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
80104295:	89 d8                	mov    %ebx,%eax
80104297:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010429a:	5b                   	pop    %ebx
8010429b:	5e                   	pop    %esi
8010429c:	5f                   	pop    %edi
8010429d:	5d                   	pop    %ebp
8010429e:	c3                   	ret    
    iunlockput(ip);
8010429f:	83 ec 0c             	sub    $0xc,%esp
801042a2:	53                   	push   %ebx
801042a3:	e8 80 d4 ff ff       	call   80101728 <iunlockput>
    return 0;
801042a8:	83 c4 10             	add    $0x10,%esp
801042ab:	bb 00 00 00 00       	mov    $0x0,%ebx
801042b0:	eb e3                	jmp    80104295 <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
801042b2:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
801042b6:	83 ec 08             	sub    $0x8,%esp
801042b9:	50                   	push   %eax
801042ba:	ff 36                	pushl  (%esi)
801042bc:	e8 bd d0 ff ff       	call   8010137e <ialloc>
801042c1:	89 c3                	mov    %eax,%ebx
801042c3:	83 c4 10             	add    $0x10,%esp
801042c6:	85 c0                	test   %eax,%eax
801042c8:	74 55                	je     8010431f <create+0xf8>
  ilock(ip);
801042ca:	83 ec 0c             	sub    $0xc,%esp
801042cd:	50                   	push   %eax
801042ce:	e8 ae d2 ff ff       	call   80101581 <ilock>
  ip->major = major;
801042d3:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
801042d7:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
801042db:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
801042df:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
801042e5:	89 1c 24             	mov    %ebx,(%esp)
801042e8:	e8 33 d1 ff ff       	call   80101420 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
801042ed:	83 c4 10             	add    $0x10,%esp
801042f0:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
801042f5:	74 35                	je     8010432c <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
801042f7:	83 ec 04             	sub    $0x4,%esp
801042fa:	ff 73 04             	pushl  0x4(%ebx)
801042fd:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104300:	50                   	push   %eax
80104301:	56                   	push   %esi
80104302:	e8 29 d8 ff ff       	call   80101b30 <dirlink>
80104307:	83 c4 10             	add    $0x10,%esp
8010430a:	85 c0                	test   %eax,%eax
8010430c:	78 6f                	js     8010437d <create+0x156>
  iunlockput(dp);
8010430e:	83 ec 0c             	sub    $0xc,%esp
80104311:	56                   	push   %esi
80104312:	e8 11 d4 ff ff       	call   80101728 <iunlockput>
  return ip;
80104317:	83 c4 10             	add    $0x10,%esp
8010431a:	e9 76 ff ff ff       	jmp    80104295 <create+0x6e>
    panic("create: ialloc");
8010431f:	83 ec 0c             	sub    $0xc,%esp
80104322:	68 ae 6d 10 80       	push   $0x80106dae
80104327:	e8 1c c0 ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
8010432c:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104330:	83 c0 01             	add    $0x1,%eax
80104333:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104337:	83 ec 0c             	sub    $0xc,%esp
8010433a:	56                   	push   %esi
8010433b:	e8 e0 d0 ff ff       	call   80101420 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80104340:	83 c4 0c             	add    $0xc,%esp
80104343:	ff 73 04             	pushl  0x4(%ebx)
80104346:	68 be 6d 10 80       	push   $0x80106dbe
8010434b:	53                   	push   %ebx
8010434c:	e8 df d7 ff ff       	call   80101b30 <dirlink>
80104351:	83 c4 10             	add    $0x10,%esp
80104354:	85 c0                	test   %eax,%eax
80104356:	78 18                	js     80104370 <create+0x149>
80104358:	83 ec 04             	sub    $0x4,%esp
8010435b:	ff 76 04             	pushl  0x4(%esi)
8010435e:	68 bd 6d 10 80       	push   $0x80106dbd
80104363:	53                   	push   %ebx
80104364:	e8 c7 d7 ff ff       	call   80101b30 <dirlink>
80104369:	83 c4 10             	add    $0x10,%esp
8010436c:	85 c0                	test   %eax,%eax
8010436e:	79 87                	jns    801042f7 <create+0xd0>
      panic("create dots");
80104370:	83 ec 0c             	sub    $0xc,%esp
80104373:	68 c0 6d 10 80       	push   $0x80106dc0
80104378:	e8 cb bf ff ff       	call   80100348 <panic>
    panic("create: dirlink");
8010437d:	83 ec 0c             	sub    $0xc,%esp
80104380:	68 cc 6d 10 80       	push   $0x80106dcc
80104385:	e8 be bf ff ff       	call   80100348 <panic>
    return 0;
8010438a:	89 c3                	mov    %eax,%ebx
8010438c:	e9 04 ff ff ff       	jmp    80104295 <create+0x6e>

80104391 <sys_dup>:
{
80104391:	55                   	push   %ebp
80104392:	89 e5                	mov    %esp,%ebp
80104394:	53                   	push   %ebx
80104395:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
80104398:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010439b:	ba 00 00 00 00       	mov    $0x0,%edx
801043a0:	b8 00 00 00 00       	mov    $0x0,%eax
801043a5:	e8 88 fd ff ff       	call   80104132 <argfd>
801043aa:	85 c0                	test   %eax,%eax
801043ac:	78 23                	js     801043d1 <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
801043ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043b1:	e8 e3 fd ff ff       	call   80104199 <fdalloc>
801043b6:	89 c3                	mov    %eax,%ebx
801043b8:	85 c0                	test   %eax,%eax
801043ba:	78 1c                	js     801043d8 <sys_dup+0x47>
  filedup(f);
801043bc:	83 ec 0c             	sub    $0xc,%esp
801043bf:	ff 75 f4             	pushl  -0xc(%ebp)
801043c2:	e8 c7 c8 ff ff       	call   80100c8e <filedup>
  return fd;
801043c7:	83 c4 10             	add    $0x10,%esp
}
801043ca:	89 d8                	mov    %ebx,%eax
801043cc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801043cf:	c9                   	leave  
801043d0:	c3                   	ret    
    return -1;
801043d1:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801043d6:	eb f2                	jmp    801043ca <sys_dup+0x39>
    return -1;
801043d8:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801043dd:	eb eb                	jmp    801043ca <sys_dup+0x39>

801043df <sys_read>:
{
801043df:	55                   	push   %ebp
801043e0:	89 e5                	mov    %esp,%ebp
801043e2:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801043e5:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801043e8:	ba 00 00 00 00       	mov    $0x0,%edx
801043ed:	b8 00 00 00 00       	mov    $0x0,%eax
801043f2:	e8 3b fd ff ff       	call   80104132 <argfd>
801043f7:	85 c0                	test   %eax,%eax
801043f9:	78 43                	js     8010443e <sys_read+0x5f>
801043fb:	83 ec 08             	sub    $0x8,%esp
801043fe:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104401:	50                   	push   %eax
80104402:	6a 02                	push   $0x2
80104404:	e8 11 fc ff ff       	call   8010401a <argint>
80104409:	83 c4 10             	add    $0x10,%esp
8010440c:	85 c0                	test   %eax,%eax
8010440e:	78 35                	js     80104445 <sys_read+0x66>
80104410:	83 ec 04             	sub    $0x4,%esp
80104413:	ff 75 f0             	pushl  -0x10(%ebp)
80104416:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104419:	50                   	push   %eax
8010441a:	6a 01                	push   $0x1
8010441c:	e8 21 fc ff ff       	call   80104042 <argptr>
80104421:	83 c4 10             	add    $0x10,%esp
80104424:	85 c0                	test   %eax,%eax
80104426:	78 24                	js     8010444c <sys_read+0x6d>
  return fileread(f, p, n);
80104428:	83 ec 04             	sub    $0x4,%esp
8010442b:	ff 75 f0             	pushl  -0x10(%ebp)
8010442e:	ff 75 ec             	pushl  -0x14(%ebp)
80104431:	ff 75 f4             	pushl  -0xc(%ebp)
80104434:	e8 9e c9 ff ff       	call   80100dd7 <fileread>
80104439:	83 c4 10             	add    $0x10,%esp
}
8010443c:	c9                   	leave  
8010443d:	c3                   	ret    
    return -1;
8010443e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104443:	eb f7                	jmp    8010443c <sys_read+0x5d>
80104445:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010444a:	eb f0                	jmp    8010443c <sys_read+0x5d>
8010444c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104451:	eb e9                	jmp    8010443c <sys_read+0x5d>

80104453 <sys_write>:
{
80104453:	55                   	push   %ebp
80104454:	89 e5                	mov    %esp,%ebp
80104456:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104459:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010445c:	ba 00 00 00 00       	mov    $0x0,%edx
80104461:	b8 00 00 00 00       	mov    $0x0,%eax
80104466:	e8 c7 fc ff ff       	call   80104132 <argfd>
8010446b:	85 c0                	test   %eax,%eax
8010446d:	78 43                	js     801044b2 <sys_write+0x5f>
8010446f:	83 ec 08             	sub    $0x8,%esp
80104472:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104475:	50                   	push   %eax
80104476:	6a 02                	push   $0x2
80104478:	e8 9d fb ff ff       	call   8010401a <argint>
8010447d:	83 c4 10             	add    $0x10,%esp
80104480:	85 c0                	test   %eax,%eax
80104482:	78 35                	js     801044b9 <sys_write+0x66>
80104484:	83 ec 04             	sub    $0x4,%esp
80104487:	ff 75 f0             	pushl  -0x10(%ebp)
8010448a:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010448d:	50                   	push   %eax
8010448e:	6a 01                	push   $0x1
80104490:	e8 ad fb ff ff       	call   80104042 <argptr>
80104495:	83 c4 10             	add    $0x10,%esp
80104498:	85 c0                	test   %eax,%eax
8010449a:	78 24                	js     801044c0 <sys_write+0x6d>
  return filewrite(f, p, n);
8010449c:	83 ec 04             	sub    $0x4,%esp
8010449f:	ff 75 f0             	pushl  -0x10(%ebp)
801044a2:	ff 75 ec             	pushl  -0x14(%ebp)
801044a5:	ff 75 f4             	pushl  -0xc(%ebp)
801044a8:	e8 af c9 ff ff       	call   80100e5c <filewrite>
801044ad:	83 c4 10             	add    $0x10,%esp
}
801044b0:	c9                   	leave  
801044b1:	c3                   	ret    
    return -1;
801044b2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044b7:	eb f7                	jmp    801044b0 <sys_write+0x5d>
801044b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044be:	eb f0                	jmp    801044b0 <sys_write+0x5d>
801044c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044c5:	eb e9                	jmp    801044b0 <sys_write+0x5d>

801044c7 <sys_close>:
{
801044c7:	55                   	push   %ebp
801044c8:	89 e5                	mov    %esp,%ebp
801044ca:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
801044cd:	8d 4d f0             	lea    -0x10(%ebp),%ecx
801044d0:	8d 55 f4             	lea    -0xc(%ebp),%edx
801044d3:	b8 00 00 00 00       	mov    $0x0,%eax
801044d8:	e8 55 fc ff ff       	call   80104132 <argfd>
801044dd:	85 c0                	test   %eax,%eax
801044df:	78 25                	js     80104506 <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
801044e1:	e8 dc ed ff ff       	call   801032c2 <myproc>
801044e6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801044e9:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
801044f0:	00 
  fileclose(f);
801044f1:	83 ec 0c             	sub    $0xc,%esp
801044f4:	ff 75 f0             	pushl  -0x10(%ebp)
801044f7:	e8 d7 c7 ff ff       	call   80100cd3 <fileclose>
  return 0;
801044fc:	83 c4 10             	add    $0x10,%esp
801044ff:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104504:	c9                   	leave  
80104505:	c3                   	ret    
    return -1;
80104506:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010450b:	eb f7                	jmp    80104504 <sys_close+0x3d>

8010450d <sys_fstat>:
{
8010450d:	55                   	push   %ebp
8010450e:	89 e5                	mov    %esp,%ebp
80104510:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80104513:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104516:	ba 00 00 00 00       	mov    $0x0,%edx
8010451b:	b8 00 00 00 00       	mov    $0x0,%eax
80104520:	e8 0d fc ff ff       	call   80104132 <argfd>
80104525:	85 c0                	test   %eax,%eax
80104527:	78 2a                	js     80104553 <sys_fstat+0x46>
80104529:	83 ec 04             	sub    $0x4,%esp
8010452c:	6a 14                	push   $0x14
8010452e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104531:	50                   	push   %eax
80104532:	6a 01                	push   $0x1
80104534:	e8 09 fb ff ff       	call   80104042 <argptr>
80104539:	83 c4 10             	add    $0x10,%esp
8010453c:	85 c0                	test   %eax,%eax
8010453e:	78 1a                	js     8010455a <sys_fstat+0x4d>
  return filestat(f, st);
80104540:	83 ec 08             	sub    $0x8,%esp
80104543:	ff 75 f0             	pushl  -0x10(%ebp)
80104546:	ff 75 f4             	pushl  -0xc(%ebp)
80104549:	e8 42 c8 ff ff       	call   80100d90 <filestat>
8010454e:	83 c4 10             	add    $0x10,%esp
}
80104551:	c9                   	leave  
80104552:	c3                   	ret    
    return -1;
80104553:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104558:	eb f7                	jmp    80104551 <sys_fstat+0x44>
8010455a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010455f:	eb f0                	jmp    80104551 <sys_fstat+0x44>

80104561 <sys_link>:
{
80104561:	55                   	push   %ebp
80104562:	89 e5                	mov    %esp,%ebp
80104564:	56                   	push   %esi
80104565:	53                   	push   %ebx
80104566:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80104569:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010456c:	50                   	push   %eax
8010456d:	6a 00                	push   $0x0
8010456f:	e8 36 fb ff ff       	call   801040aa <argstr>
80104574:	83 c4 10             	add    $0x10,%esp
80104577:	85 c0                	test   %eax,%eax
80104579:	0f 88 32 01 00 00    	js     801046b1 <sys_link+0x150>
8010457f:	83 ec 08             	sub    $0x8,%esp
80104582:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104585:	50                   	push   %eax
80104586:	6a 01                	push   $0x1
80104588:	e8 1d fb ff ff       	call   801040aa <argstr>
8010458d:	83 c4 10             	add    $0x10,%esp
80104590:	85 c0                	test   %eax,%eax
80104592:	0f 88 20 01 00 00    	js     801046b8 <sys_link+0x157>
  begin_op();
80104598:	e8 bf e2 ff ff       	call   8010285c <begin_op>
  if((ip = namei(old)) == 0){
8010459d:	83 ec 0c             	sub    $0xc,%esp
801045a0:	ff 75 e0             	pushl  -0x20(%ebp)
801045a3:	e8 39 d6 ff ff       	call   80101be1 <namei>
801045a8:	89 c3                	mov    %eax,%ebx
801045aa:	83 c4 10             	add    $0x10,%esp
801045ad:	85 c0                	test   %eax,%eax
801045af:	0f 84 99 00 00 00    	je     8010464e <sys_link+0xed>
  ilock(ip);
801045b5:	83 ec 0c             	sub    $0xc,%esp
801045b8:	50                   	push   %eax
801045b9:	e8 c3 cf ff ff       	call   80101581 <ilock>
  if(ip->type == T_DIR){
801045be:	83 c4 10             	add    $0x10,%esp
801045c1:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801045c6:	0f 84 8e 00 00 00    	je     8010465a <sys_link+0xf9>
  ip->nlink++;
801045cc:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801045d0:	83 c0 01             	add    $0x1,%eax
801045d3:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801045d7:	83 ec 0c             	sub    $0xc,%esp
801045da:	53                   	push   %ebx
801045db:	e8 40 ce ff ff       	call   80101420 <iupdate>
  iunlock(ip);
801045e0:	89 1c 24             	mov    %ebx,(%esp)
801045e3:	e8 5b d0 ff ff       	call   80101643 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
801045e8:	83 c4 08             	add    $0x8,%esp
801045eb:	8d 45 ea             	lea    -0x16(%ebp),%eax
801045ee:	50                   	push   %eax
801045ef:	ff 75 e4             	pushl  -0x1c(%ebp)
801045f2:	e8 02 d6 ff ff       	call   80101bf9 <nameiparent>
801045f7:	89 c6                	mov    %eax,%esi
801045f9:	83 c4 10             	add    $0x10,%esp
801045fc:	85 c0                	test   %eax,%eax
801045fe:	74 7e                	je     8010467e <sys_link+0x11d>
  ilock(dp);
80104600:	83 ec 0c             	sub    $0xc,%esp
80104603:	50                   	push   %eax
80104604:	e8 78 cf ff ff       	call   80101581 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80104609:	83 c4 10             	add    $0x10,%esp
8010460c:	8b 03                	mov    (%ebx),%eax
8010460e:	39 06                	cmp    %eax,(%esi)
80104610:	75 60                	jne    80104672 <sys_link+0x111>
80104612:	83 ec 04             	sub    $0x4,%esp
80104615:	ff 73 04             	pushl  0x4(%ebx)
80104618:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010461b:	50                   	push   %eax
8010461c:	56                   	push   %esi
8010461d:	e8 0e d5 ff ff       	call   80101b30 <dirlink>
80104622:	83 c4 10             	add    $0x10,%esp
80104625:	85 c0                	test   %eax,%eax
80104627:	78 49                	js     80104672 <sys_link+0x111>
  iunlockput(dp);
80104629:	83 ec 0c             	sub    $0xc,%esp
8010462c:	56                   	push   %esi
8010462d:	e8 f6 d0 ff ff       	call   80101728 <iunlockput>
  iput(ip);
80104632:	89 1c 24             	mov    %ebx,(%esp)
80104635:	e8 4e d0 ff ff       	call   80101688 <iput>
  end_op();
8010463a:	e8 97 e2 ff ff       	call   801028d6 <end_op>
  return 0;
8010463f:	83 c4 10             	add    $0x10,%esp
80104642:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104647:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010464a:	5b                   	pop    %ebx
8010464b:	5e                   	pop    %esi
8010464c:	5d                   	pop    %ebp
8010464d:	c3                   	ret    
    end_op();
8010464e:	e8 83 e2 ff ff       	call   801028d6 <end_op>
    return -1;
80104653:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104658:	eb ed                	jmp    80104647 <sys_link+0xe6>
    iunlockput(ip);
8010465a:	83 ec 0c             	sub    $0xc,%esp
8010465d:	53                   	push   %ebx
8010465e:	e8 c5 d0 ff ff       	call   80101728 <iunlockput>
    end_op();
80104663:	e8 6e e2 ff ff       	call   801028d6 <end_op>
    return -1;
80104668:	83 c4 10             	add    $0x10,%esp
8010466b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104670:	eb d5                	jmp    80104647 <sys_link+0xe6>
    iunlockput(dp);
80104672:	83 ec 0c             	sub    $0xc,%esp
80104675:	56                   	push   %esi
80104676:	e8 ad d0 ff ff       	call   80101728 <iunlockput>
    goto bad;
8010467b:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
8010467e:	83 ec 0c             	sub    $0xc,%esp
80104681:	53                   	push   %ebx
80104682:	e8 fa ce ff ff       	call   80101581 <ilock>
  ip->nlink--;
80104687:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
8010468b:	83 e8 01             	sub    $0x1,%eax
8010468e:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104692:	89 1c 24             	mov    %ebx,(%esp)
80104695:	e8 86 cd ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
8010469a:	89 1c 24             	mov    %ebx,(%esp)
8010469d:	e8 86 d0 ff ff       	call   80101728 <iunlockput>
  end_op();
801046a2:	e8 2f e2 ff ff       	call   801028d6 <end_op>
  return -1;
801046a7:	83 c4 10             	add    $0x10,%esp
801046aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046af:	eb 96                	jmp    80104647 <sys_link+0xe6>
    return -1;
801046b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046b6:	eb 8f                	jmp    80104647 <sys_link+0xe6>
801046b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046bd:	eb 88                	jmp    80104647 <sys_link+0xe6>

801046bf <sys_unlink>:
{
801046bf:	55                   	push   %ebp
801046c0:	89 e5                	mov    %esp,%ebp
801046c2:	57                   	push   %edi
801046c3:	56                   	push   %esi
801046c4:	53                   	push   %ebx
801046c5:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
801046c8:	8d 45 c4             	lea    -0x3c(%ebp),%eax
801046cb:	50                   	push   %eax
801046cc:	6a 00                	push   $0x0
801046ce:	e8 d7 f9 ff ff       	call   801040aa <argstr>
801046d3:	83 c4 10             	add    $0x10,%esp
801046d6:	85 c0                	test   %eax,%eax
801046d8:	0f 88 83 01 00 00    	js     80104861 <sys_unlink+0x1a2>
  begin_op();
801046de:	e8 79 e1 ff ff       	call   8010285c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
801046e3:	83 ec 08             	sub    $0x8,%esp
801046e6:	8d 45 ca             	lea    -0x36(%ebp),%eax
801046e9:	50                   	push   %eax
801046ea:	ff 75 c4             	pushl  -0x3c(%ebp)
801046ed:	e8 07 d5 ff ff       	call   80101bf9 <nameiparent>
801046f2:	89 c6                	mov    %eax,%esi
801046f4:	83 c4 10             	add    $0x10,%esp
801046f7:	85 c0                	test   %eax,%eax
801046f9:	0f 84 ed 00 00 00    	je     801047ec <sys_unlink+0x12d>
  ilock(dp);
801046ff:	83 ec 0c             	sub    $0xc,%esp
80104702:	50                   	push   %eax
80104703:	e8 79 ce ff ff       	call   80101581 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80104708:	83 c4 08             	add    $0x8,%esp
8010470b:	68 be 6d 10 80       	push   $0x80106dbe
80104710:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104713:	50                   	push   %eax
80104714:	e8 82 d2 ff ff       	call   8010199b <namecmp>
80104719:	83 c4 10             	add    $0x10,%esp
8010471c:	85 c0                	test   %eax,%eax
8010471e:	0f 84 fc 00 00 00    	je     80104820 <sys_unlink+0x161>
80104724:	83 ec 08             	sub    $0x8,%esp
80104727:	68 bd 6d 10 80       	push   $0x80106dbd
8010472c:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010472f:	50                   	push   %eax
80104730:	e8 66 d2 ff ff       	call   8010199b <namecmp>
80104735:	83 c4 10             	add    $0x10,%esp
80104738:	85 c0                	test   %eax,%eax
8010473a:	0f 84 e0 00 00 00    	je     80104820 <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
80104740:	83 ec 04             	sub    $0x4,%esp
80104743:	8d 45 c0             	lea    -0x40(%ebp),%eax
80104746:	50                   	push   %eax
80104747:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010474a:	50                   	push   %eax
8010474b:	56                   	push   %esi
8010474c:	e8 5f d2 ff ff       	call   801019b0 <dirlookup>
80104751:	89 c3                	mov    %eax,%ebx
80104753:	83 c4 10             	add    $0x10,%esp
80104756:	85 c0                	test   %eax,%eax
80104758:	0f 84 c2 00 00 00    	je     80104820 <sys_unlink+0x161>
  ilock(ip);
8010475e:	83 ec 0c             	sub    $0xc,%esp
80104761:	50                   	push   %eax
80104762:	e8 1a ce ff ff       	call   80101581 <ilock>
  if(ip->nlink < 1)
80104767:	83 c4 10             	add    $0x10,%esp
8010476a:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
8010476f:	0f 8e 83 00 00 00    	jle    801047f8 <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104775:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
8010477a:	0f 84 85 00 00 00    	je     80104805 <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
80104780:	83 ec 04             	sub    $0x4,%esp
80104783:	6a 10                	push   $0x10
80104785:	6a 00                	push   $0x0
80104787:	8d 7d d8             	lea    -0x28(%ebp),%edi
8010478a:	57                   	push   %edi
8010478b:	e8 3f f6 ff ff       	call   80103dcf <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104790:	6a 10                	push   $0x10
80104792:	ff 75 c0             	pushl  -0x40(%ebp)
80104795:	57                   	push   %edi
80104796:	56                   	push   %esi
80104797:	e8 d4 d0 ff ff       	call   80101870 <writei>
8010479c:	83 c4 20             	add    $0x20,%esp
8010479f:	83 f8 10             	cmp    $0x10,%eax
801047a2:	0f 85 90 00 00 00    	jne    80104838 <sys_unlink+0x179>
  if(ip->type == T_DIR){
801047a8:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801047ad:	0f 84 92 00 00 00    	je     80104845 <sys_unlink+0x186>
  iunlockput(dp);
801047b3:	83 ec 0c             	sub    $0xc,%esp
801047b6:	56                   	push   %esi
801047b7:	e8 6c cf ff ff       	call   80101728 <iunlockput>
  ip->nlink--;
801047bc:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801047c0:	83 e8 01             	sub    $0x1,%eax
801047c3:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801047c7:	89 1c 24             	mov    %ebx,(%esp)
801047ca:	e8 51 cc ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
801047cf:	89 1c 24             	mov    %ebx,(%esp)
801047d2:	e8 51 cf ff ff       	call   80101728 <iunlockput>
  end_op();
801047d7:	e8 fa e0 ff ff       	call   801028d6 <end_op>
  return 0;
801047dc:	83 c4 10             	add    $0x10,%esp
801047df:	b8 00 00 00 00       	mov    $0x0,%eax
}
801047e4:	8d 65 f4             	lea    -0xc(%ebp),%esp
801047e7:	5b                   	pop    %ebx
801047e8:	5e                   	pop    %esi
801047e9:	5f                   	pop    %edi
801047ea:	5d                   	pop    %ebp
801047eb:	c3                   	ret    
    end_op();
801047ec:	e8 e5 e0 ff ff       	call   801028d6 <end_op>
    return -1;
801047f1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047f6:	eb ec                	jmp    801047e4 <sys_unlink+0x125>
    panic("unlink: nlink < 1");
801047f8:	83 ec 0c             	sub    $0xc,%esp
801047fb:	68 dc 6d 10 80       	push   $0x80106ddc
80104800:	e8 43 bb ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104805:	89 d8                	mov    %ebx,%eax
80104807:	e8 c4 f9 ff ff       	call   801041d0 <isdirempty>
8010480c:	85 c0                	test   %eax,%eax
8010480e:	0f 85 6c ff ff ff    	jne    80104780 <sys_unlink+0xc1>
    iunlockput(ip);
80104814:	83 ec 0c             	sub    $0xc,%esp
80104817:	53                   	push   %ebx
80104818:	e8 0b cf ff ff       	call   80101728 <iunlockput>
    goto bad;
8010481d:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
80104820:	83 ec 0c             	sub    $0xc,%esp
80104823:	56                   	push   %esi
80104824:	e8 ff ce ff ff       	call   80101728 <iunlockput>
  end_op();
80104829:	e8 a8 e0 ff ff       	call   801028d6 <end_op>
  return -1;
8010482e:	83 c4 10             	add    $0x10,%esp
80104831:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104836:	eb ac                	jmp    801047e4 <sys_unlink+0x125>
    panic("unlink: writei");
80104838:	83 ec 0c             	sub    $0xc,%esp
8010483b:	68 ee 6d 10 80       	push   $0x80106dee
80104840:	e8 03 bb ff ff       	call   80100348 <panic>
    dp->nlink--;
80104845:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104849:	83 e8 01             	sub    $0x1,%eax
8010484c:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104850:	83 ec 0c             	sub    $0xc,%esp
80104853:	56                   	push   %esi
80104854:	e8 c7 cb ff ff       	call   80101420 <iupdate>
80104859:	83 c4 10             	add    $0x10,%esp
8010485c:	e9 52 ff ff ff       	jmp    801047b3 <sys_unlink+0xf4>
    return -1;
80104861:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104866:	e9 79 ff ff ff       	jmp    801047e4 <sys_unlink+0x125>

8010486b <sys_open>:

int
sys_open(void)
{
8010486b:	55                   	push   %ebp
8010486c:	89 e5                	mov    %esp,%ebp
8010486e:	57                   	push   %edi
8010486f:	56                   	push   %esi
80104870:	53                   	push   %ebx
80104871:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80104874:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104877:	50                   	push   %eax
80104878:	6a 00                	push   $0x0
8010487a:	e8 2b f8 ff ff       	call   801040aa <argstr>
8010487f:	83 c4 10             	add    $0x10,%esp
80104882:	85 c0                	test   %eax,%eax
80104884:	0f 88 30 01 00 00    	js     801049ba <sys_open+0x14f>
8010488a:	83 ec 08             	sub    $0x8,%esp
8010488d:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104890:	50                   	push   %eax
80104891:	6a 01                	push   $0x1
80104893:	e8 82 f7 ff ff       	call   8010401a <argint>
80104898:	83 c4 10             	add    $0x10,%esp
8010489b:	85 c0                	test   %eax,%eax
8010489d:	0f 88 21 01 00 00    	js     801049c4 <sys_open+0x159>
    return -1;

  begin_op();
801048a3:	e8 b4 df ff ff       	call   8010285c <begin_op>

  if(omode & O_CREATE){
801048a8:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
801048ac:	0f 84 84 00 00 00    	je     80104936 <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
801048b2:	83 ec 0c             	sub    $0xc,%esp
801048b5:	6a 00                	push   $0x0
801048b7:	b9 00 00 00 00       	mov    $0x0,%ecx
801048bc:	ba 02 00 00 00       	mov    $0x2,%edx
801048c1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801048c4:	e8 5e f9 ff ff       	call   80104227 <create>
801048c9:	89 c6                	mov    %eax,%esi
    if(ip == 0){
801048cb:	83 c4 10             	add    $0x10,%esp
801048ce:	85 c0                	test   %eax,%eax
801048d0:	74 58                	je     8010492a <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
801048d2:	e8 56 c3 ff ff       	call   80100c2d <filealloc>
801048d7:	89 c3                	mov    %eax,%ebx
801048d9:	85 c0                	test   %eax,%eax
801048db:	0f 84 ae 00 00 00    	je     8010498f <sys_open+0x124>
801048e1:	e8 b3 f8 ff ff       	call   80104199 <fdalloc>
801048e6:	89 c7                	mov    %eax,%edi
801048e8:	85 c0                	test   %eax,%eax
801048ea:	0f 88 9f 00 00 00    	js     8010498f <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
801048f0:	83 ec 0c             	sub    $0xc,%esp
801048f3:	56                   	push   %esi
801048f4:	e8 4a cd ff ff       	call   80101643 <iunlock>
  end_op();
801048f9:	e8 d8 df ff ff       	call   801028d6 <end_op>

  f->type = FD_INODE;
801048fe:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
80104904:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
80104907:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
8010490e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104911:	83 c4 10             	add    $0x10,%esp
80104914:	a8 01                	test   $0x1,%al
80104916:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
8010491a:	a8 03                	test   $0x3,%al
8010491c:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
80104920:	89 f8                	mov    %edi,%eax
80104922:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104925:	5b                   	pop    %ebx
80104926:	5e                   	pop    %esi
80104927:	5f                   	pop    %edi
80104928:	5d                   	pop    %ebp
80104929:	c3                   	ret    
      end_op();
8010492a:	e8 a7 df ff ff       	call   801028d6 <end_op>
      return -1;
8010492f:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104934:	eb ea                	jmp    80104920 <sys_open+0xb5>
    if((ip = namei(path)) == 0){
80104936:	83 ec 0c             	sub    $0xc,%esp
80104939:	ff 75 e4             	pushl  -0x1c(%ebp)
8010493c:	e8 a0 d2 ff ff       	call   80101be1 <namei>
80104941:	89 c6                	mov    %eax,%esi
80104943:	83 c4 10             	add    $0x10,%esp
80104946:	85 c0                	test   %eax,%eax
80104948:	74 39                	je     80104983 <sys_open+0x118>
    ilock(ip);
8010494a:	83 ec 0c             	sub    $0xc,%esp
8010494d:	50                   	push   %eax
8010494e:	e8 2e cc ff ff       	call   80101581 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80104953:	83 c4 10             	add    $0x10,%esp
80104956:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
8010495b:	0f 85 71 ff ff ff    	jne    801048d2 <sys_open+0x67>
80104961:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104965:	0f 84 67 ff ff ff    	je     801048d2 <sys_open+0x67>
      iunlockput(ip);
8010496b:	83 ec 0c             	sub    $0xc,%esp
8010496e:	56                   	push   %esi
8010496f:	e8 b4 cd ff ff       	call   80101728 <iunlockput>
      end_op();
80104974:	e8 5d df ff ff       	call   801028d6 <end_op>
      return -1;
80104979:	83 c4 10             	add    $0x10,%esp
8010497c:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104981:	eb 9d                	jmp    80104920 <sys_open+0xb5>
      end_op();
80104983:	e8 4e df ff ff       	call   801028d6 <end_op>
      return -1;
80104988:	bf ff ff ff ff       	mov    $0xffffffff,%edi
8010498d:	eb 91                	jmp    80104920 <sys_open+0xb5>
    if(f)
8010498f:	85 db                	test   %ebx,%ebx
80104991:	74 0c                	je     8010499f <sys_open+0x134>
      fileclose(f);
80104993:	83 ec 0c             	sub    $0xc,%esp
80104996:	53                   	push   %ebx
80104997:	e8 37 c3 ff ff       	call   80100cd3 <fileclose>
8010499c:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
8010499f:	83 ec 0c             	sub    $0xc,%esp
801049a2:	56                   	push   %esi
801049a3:	e8 80 cd ff ff       	call   80101728 <iunlockput>
    end_op();
801049a8:	e8 29 df ff ff       	call   801028d6 <end_op>
    return -1;
801049ad:	83 c4 10             	add    $0x10,%esp
801049b0:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801049b5:	e9 66 ff ff ff       	jmp    80104920 <sys_open+0xb5>
    return -1;
801049ba:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801049bf:	e9 5c ff ff ff       	jmp    80104920 <sys_open+0xb5>
801049c4:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801049c9:	e9 52 ff ff ff       	jmp    80104920 <sys_open+0xb5>

801049ce <sys_mkdir>:

int
sys_mkdir(void)
{
801049ce:	55                   	push   %ebp
801049cf:	89 e5                	mov    %esp,%ebp
801049d1:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
801049d4:	e8 83 de ff ff       	call   8010285c <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
801049d9:	83 ec 08             	sub    $0x8,%esp
801049dc:	8d 45 f4             	lea    -0xc(%ebp),%eax
801049df:	50                   	push   %eax
801049e0:	6a 00                	push   $0x0
801049e2:	e8 c3 f6 ff ff       	call   801040aa <argstr>
801049e7:	83 c4 10             	add    $0x10,%esp
801049ea:	85 c0                	test   %eax,%eax
801049ec:	78 36                	js     80104a24 <sys_mkdir+0x56>
801049ee:	83 ec 0c             	sub    $0xc,%esp
801049f1:	6a 00                	push   $0x0
801049f3:	b9 00 00 00 00       	mov    $0x0,%ecx
801049f8:	ba 01 00 00 00       	mov    $0x1,%edx
801049fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a00:	e8 22 f8 ff ff       	call   80104227 <create>
80104a05:	83 c4 10             	add    $0x10,%esp
80104a08:	85 c0                	test   %eax,%eax
80104a0a:	74 18                	je     80104a24 <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104a0c:	83 ec 0c             	sub    $0xc,%esp
80104a0f:	50                   	push   %eax
80104a10:	e8 13 cd ff ff       	call   80101728 <iunlockput>
  end_op();
80104a15:	e8 bc de ff ff       	call   801028d6 <end_op>
  return 0;
80104a1a:	83 c4 10             	add    $0x10,%esp
80104a1d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104a22:	c9                   	leave  
80104a23:	c3                   	ret    
    end_op();
80104a24:	e8 ad de ff ff       	call   801028d6 <end_op>
    return -1;
80104a29:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a2e:	eb f2                	jmp    80104a22 <sys_mkdir+0x54>

80104a30 <sys_mknod>:

int
sys_mknod(void)
{
80104a30:	55                   	push   %ebp
80104a31:	89 e5                	mov    %esp,%ebp
80104a33:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104a36:	e8 21 de ff ff       	call   8010285c <begin_op>
  if((argstr(0, &path)) < 0 ||
80104a3b:	83 ec 08             	sub    $0x8,%esp
80104a3e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104a41:	50                   	push   %eax
80104a42:	6a 00                	push   $0x0
80104a44:	e8 61 f6 ff ff       	call   801040aa <argstr>
80104a49:	83 c4 10             	add    $0x10,%esp
80104a4c:	85 c0                	test   %eax,%eax
80104a4e:	78 62                	js     80104ab2 <sys_mknod+0x82>
     argint(1, &major) < 0 ||
80104a50:	83 ec 08             	sub    $0x8,%esp
80104a53:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104a56:	50                   	push   %eax
80104a57:	6a 01                	push   $0x1
80104a59:	e8 bc f5 ff ff       	call   8010401a <argint>
  if((argstr(0, &path)) < 0 ||
80104a5e:	83 c4 10             	add    $0x10,%esp
80104a61:	85 c0                	test   %eax,%eax
80104a63:	78 4d                	js     80104ab2 <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
80104a65:	83 ec 08             	sub    $0x8,%esp
80104a68:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104a6b:	50                   	push   %eax
80104a6c:	6a 02                	push   $0x2
80104a6e:	e8 a7 f5 ff ff       	call   8010401a <argint>
     argint(1, &major) < 0 ||
80104a73:	83 c4 10             	add    $0x10,%esp
80104a76:	85 c0                	test   %eax,%eax
80104a78:	78 38                	js     80104ab2 <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104a7a:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104a7e:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
80104a82:	83 ec 0c             	sub    $0xc,%esp
80104a85:	50                   	push   %eax
80104a86:	ba 03 00 00 00       	mov    $0x3,%edx
80104a8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a8e:	e8 94 f7 ff ff       	call   80104227 <create>
80104a93:	83 c4 10             	add    $0x10,%esp
80104a96:	85 c0                	test   %eax,%eax
80104a98:	74 18                	je     80104ab2 <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104a9a:	83 ec 0c             	sub    $0xc,%esp
80104a9d:	50                   	push   %eax
80104a9e:	e8 85 cc ff ff       	call   80101728 <iunlockput>
  end_op();
80104aa3:	e8 2e de ff ff       	call   801028d6 <end_op>
  return 0;
80104aa8:	83 c4 10             	add    $0x10,%esp
80104aab:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104ab0:	c9                   	leave  
80104ab1:	c3                   	ret    
    end_op();
80104ab2:	e8 1f de ff ff       	call   801028d6 <end_op>
    return -1;
80104ab7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104abc:	eb f2                	jmp    80104ab0 <sys_mknod+0x80>

80104abe <sys_chdir>:

int
sys_chdir(void)
{
80104abe:	55                   	push   %ebp
80104abf:	89 e5                	mov    %esp,%ebp
80104ac1:	56                   	push   %esi
80104ac2:	53                   	push   %ebx
80104ac3:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104ac6:	e8 f7 e7 ff ff       	call   801032c2 <myproc>
80104acb:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104acd:	e8 8a dd ff ff       	call   8010285c <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104ad2:	83 ec 08             	sub    $0x8,%esp
80104ad5:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ad8:	50                   	push   %eax
80104ad9:	6a 00                	push   $0x0
80104adb:	e8 ca f5 ff ff       	call   801040aa <argstr>
80104ae0:	83 c4 10             	add    $0x10,%esp
80104ae3:	85 c0                	test   %eax,%eax
80104ae5:	78 52                	js     80104b39 <sys_chdir+0x7b>
80104ae7:	83 ec 0c             	sub    $0xc,%esp
80104aea:	ff 75 f4             	pushl  -0xc(%ebp)
80104aed:	e8 ef d0 ff ff       	call   80101be1 <namei>
80104af2:	89 c3                	mov    %eax,%ebx
80104af4:	83 c4 10             	add    $0x10,%esp
80104af7:	85 c0                	test   %eax,%eax
80104af9:	74 3e                	je     80104b39 <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104afb:	83 ec 0c             	sub    $0xc,%esp
80104afe:	50                   	push   %eax
80104aff:	e8 7d ca ff ff       	call   80101581 <ilock>
  if(ip->type != T_DIR){
80104b04:	83 c4 10             	add    $0x10,%esp
80104b07:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104b0c:	75 37                	jne    80104b45 <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104b0e:	83 ec 0c             	sub    $0xc,%esp
80104b11:	53                   	push   %ebx
80104b12:	e8 2c cb ff ff       	call   80101643 <iunlock>
  iput(curproc->cwd);
80104b17:	83 c4 04             	add    $0x4,%esp
80104b1a:	ff 76 68             	pushl  0x68(%esi)
80104b1d:	e8 66 cb ff ff       	call   80101688 <iput>
  end_op();
80104b22:	e8 af dd ff ff       	call   801028d6 <end_op>
  curproc->cwd = ip;
80104b27:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104b2a:	83 c4 10             	add    $0x10,%esp
80104b2d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104b32:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104b35:	5b                   	pop    %ebx
80104b36:	5e                   	pop    %esi
80104b37:	5d                   	pop    %ebp
80104b38:	c3                   	ret    
    end_op();
80104b39:	e8 98 dd ff ff       	call   801028d6 <end_op>
    return -1;
80104b3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b43:	eb ed                	jmp    80104b32 <sys_chdir+0x74>
    iunlockput(ip);
80104b45:	83 ec 0c             	sub    $0xc,%esp
80104b48:	53                   	push   %ebx
80104b49:	e8 da cb ff ff       	call   80101728 <iunlockput>
    end_op();
80104b4e:	e8 83 dd ff ff       	call   801028d6 <end_op>
    return -1;
80104b53:	83 c4 10             	add    $0x10,%esp
80104b56:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b5b:	eb d5                	jmp    80104b32 <sys_chdir+0x74>

80104b5d <sys_exec>:

int
sys_exec(void)
{
80104b5d:	55                   	push   %ebp
80104b5e:	89 e5                	mov    %esp,%ebp
80104b60:	53                   	push   %ebx
80104b61:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104b67:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104b6a:	50                   	push   %eax
80104b6b:	6a 00                	push   $0x0
80104b6d:	e8 38 f5 ff ff       	call   801040aa <argstr>
80104b72:	83 c4 10             	add    $0x10,%esp
80104b75:	85 c0                	test   %eax,%eax
80104b77:	0f 88 a8 00 00 00    	js     80104c25 <sys_exec+0xc8>
80104b7d:	83 ec 08             	sub    $0x8,%esp
80104b80:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104b86:	50                   	push   %eax
80104b87:	6a 01                	push   $0x1
80104b89:	e8 8c f4 ff ff       	call   8010401a <argint>
80104b8e:	83 c4 10             	add    $0x10,%esp
80104b91:	85 c0                	test   %eax,%eax
80104b93:	0f 88 93 00 00 00    	js     80104c2c <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104b99:	83 ec 04             	sub    $0x4,%esp
80104b9c:	68 80 00 00 00       	push   $0x80
80104ba1:	6a 00                	push   $0x0
80104ba3:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104ba9:	50                   	push   %eax
80104baa:	e8 20 f2 ff ff       	call   80103dcf <memset>
80104baf:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104bb2:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104bb7:	83 fb 1f             	cmp    $0x1f,%ebx
80104bba:	77 77                	ja     80104c33 <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104bbc:	83 ec 08             	sub    $0x8,%esp
80104bbf:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104bc5:	50                   	push   %eax
80104bc6:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104bcc:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104bcf:	50                   	push   %eax
80104bd0:	e8 c9 f3 ff ff       	call   80103f9e <fetchint>
80104bd5:	83 c4 10             	add    $0x10,%esp
80104bd8:	85 c0                	test   %eax,%eax
80104bda:	78 5e                	js     80104c3a <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104bdc:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104be2:	85 c0                	test   %eax,%eax
80104be4:	74 1d                	je     80104c03 <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104be6:	83 ec 08             	sub    $0x8,%esp
80104be9:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104bf0:	52                   	push   %edx
80104bf1:	50                   	push   %eax
80104bf2:	e8 e3 f3 ff ff       	call   80103fda <fetchstr>
80104bf7:	83 c4 10             	add    $0x10,%esp
80104bfa:	85 c0                	test   %eax,%eax
80104bfc:	78 46                	js     80104c44 <sys_exec+0xe7>
  for(i=0;; i++){
80104bfe:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104c01:	eb b4                	jmp    80104bb7 <sys_exec+0x5a>
      argv[i] = 0;
80104c03:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104c0a:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104c0e:	83 ec 08             	sub    $0x8,%esp
80104c11:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104c17:	50                   	push   %eax
80104c18:	ff 75 f4             	pushl  -0xc(%ebp)
80104c1b:	e8 b2 bc ff ff       	call   801008d2 <exec>
80104c20:	83 c4 10             	add    $0x10,%esp
80104c23:	eb 1a                	jmp    80104c3f <sys_exec+0xe2>
    return -1;
80104c25:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c2a:	eb 13                	jmp    80104c3f <sys_exec+0xe2>
80104c2c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c31:	eb 0c                	jmp    80104c3f <sys_exec+0xe2>
      return -1;
80104c33:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c38:	eb 05                	jmp    80104c3f <sys_exec+0xe2>
      return -1;
80104c3a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104c3f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104c42:	c9                   	leave  
80104c43:	c3                   	ret    
      return -1;
80104c44:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c49:	eb f4                	jmp    80104c3f <sys_exec+0xe2>

80104c4b <sys_pipe>:

int
sys_pipe(void)
{
80104c4b:	55                   	push   %ebp
80104c4c:	89 e5                	mov    %esp,%ebp
80104c4e:	53                   	push   %ebx
80104c4f:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104c52:	6a 08                	push   $0x8
80104c54:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c57:	50                   	push   %eax
80104c58:	6a 00                	push   $0x0
80104c5a:	e8 e3 f3 ff ff       	call   80104042 <argptr>
80104c5f:	83 c4 10             	add    $0x10,%esp
80104c62:	85 c0                	test   %eax,%eax
80104c64:	78 77                	js     80104cdd <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104c66:	83 ec 08             	sub    $0x8,%esp
80104c69:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104c6c:	50                   	push   %eax
80104c6d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104c70:	50                   	push   %eax
80104c71:	e8 6d e1 ff ff       	call   80102de3 <pipealloc>
80104c76:	83 c4 10             	add    $0x10,%esp
80104c79:	85 c0                	test   %eax,%eax
80104c7b:	78 67                	js     80104ce4 <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104c7d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c80:	e8 14 f5 ff ff       	call   80104199 <fdalloc>
80104c85:	89 c3                	mov    %eax,%ebx
80104c87:	85 c0                	test   %eax,%eax
80104c89:	78 21                	js     80104cac <sys_pipe+0x61>
80104c8b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104c8e:	e8 06 f5 ff ff       	call   80104199 <fdalloc>
80104c93:	85 c0                	test   %eax,%eax
80104c95:	78 15                	js     80104cac <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104c97:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c9a:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104c9c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c9f:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104ca2:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104ca7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104caa:	c9                   	leave  
80104cab:	c3                   	ret    
    if(fd0 >= 0)
80104cac:	85 db                	test   %ebx,%ebx
80104cae:	78 0d                	js     80104cbd <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104cb0:	e8 0d e6 ff ff       	call   801032c2 <myproc>
80104cb5:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104cbc:	00 
    fileclose(rf);
80104cbd:	83 ec 0c             	sub    $0xc,%esp
80104cc0:	ff 75 f0             	pushl  -0x10(%ebp)
80104cc3:	e8 0b c0 ff ff       	call   80100cd3 <fileclose>
    fileclose(wf);
80104cc8:	83 c4 04             	add    $0x4,%esp
80104ccb:	ff 75 ec             	pushl  -0x14(%ebp)
80104cce:	e8 00 c0 ff ff       	call   80100cd3 <fileclose>
    return -1;
80104cd3:	83 c4 10             	add    $0x10,%esp
80104cd6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cdb:	eb ca                	jmp    80104ca7 <sys_pipe+0x5c>
    return -1;
80104cdd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ce2:	eb c3                	jmp    80104ca7 <sys_pipe+0x5c>
    return -1;
80104ce4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ce9:	eb bc                	jmp    80104ca7 <sys_pipe+0x5c>

80104ceb <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104ceb:	55                   	push   %ebp
80104cec:	89 e5                	mov    %esp,%ebp
80104cee:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104cf1:	e8 60 e7 ff ff       	call   80103456 <fork>
}
80104cf6:	c9                   	leave  
80104cf7:	c3                   	ret    

80104cf8 <sys_exit>:

int
sys_exit(void)
{
80104cf8:	55                   	push   %ebp
80104cf9:	89 e5                	mov    %esp,%ebp
80104cfb:	83 ec 08             	sub    $0x8,%esp
  exit();
80104cfe:	e8 a0 e9 ff ff       	call   801036a3 <exit>
  return 0;  // not reached
}
80104d03:	b8 00 00 00 00       	mov    $0x0,%eax
80104d08:	c9                   	leave  
80104d09:	c3                   	ret    

80104d0a <sys_wait>:

int
sys_wait(void)
{
80104d0a:	55                   	push   %ebp
80104d0b:	89 e5                	mov    %esp,%ebp
80104d0d:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104d10:	e8 17 eb ff ff       	call   8010382c <wait>
}
80104d15:	c9                   	leave  
80104d16:	c3                   	ret    

80104d17 <sys_kill>:

int
sys_kill(void)
{
80104d17:	55                   	push   %ebp
80104d18:	89 e5                	mov    %esp,%ebp
80104d1a:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104d1d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d20:	50                   	push   %eax
80104d21:	6a 00                	push   $0x0
80104d23:	e8 f2 f2 ff ff       	call   8010401a <argint>
80104d28:	83 c4 10             	add    $0x10,%esp
80104d2b:	85 c0                	test   %eax,%eax
80104d2d:	78 10                	js     80104d3f <sys_kill+0x28>
    return -1;
  return kill(pid);
80104d2f:	83 ec 0c             	sub    $0xc,%esp
80104d32:	ff 75 f4             	pushl  -0xc(%ebp)
80104d35:	e8 09 ec ff ff       	call   80103943 <kill>
80104d3a:	83 c4 10             	add    $0x10,%esp
}
80104d3d:	c9                   	leave  
80104d3e:	c3                   	ret    
    return -1;
80104d3f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d44:	eb f7                	jmp    80104d3d <sys_kill+0x26>

80104d46 <sys_dump_physmem>:

int
sys_dump_physmem(void)
{
80104d46:	55                   	push   %ebp
80104d47:	89 e5                	mov    %esp,%ebp
80104d49:	83 ec 1c             	sub    $0x1c,%esp
  int *frames;
  int *pids;
  int numframes;
  
  if (argptr(0, (void *)&frames, sizeof(*frames)) < 0) {
80104d4c:	6a 04                	push   $0x4
80104d4e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d51:	50                   	push   %eax
80104d52:	6a 00                	push   $0x0
80104d54:	e8 e9 f2 ff ff       	call   80104042 <argptr>
80104d59:	83 c4 10             	add    $0x10,%esp
80104d5c:	85 c0                	test   %eax,%eax
80104d5e:	78 42                	js     80104da2 <sys_dump_physmem+0x5c>
    return -1;
  }
  if (argptr(1, (void *)&pids, sizeof(*pids)) < 0) {
80104d60:	83 ec 04             	sub    $0x4,%esp
80104d63:	6a 04                	push   $0x4
80104d65:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104d68:	50                   	push   %eax
80104d69:	6a 01                	push   $0x1
80104d6b:	e8 d2 f2 ff ff       	call   80104042 <argptr>
80104d70:	83 c4 10             	add    $0x10,%esp
80104d73:	85 c0                	test   %eax,%eax
80104d75:	78 32                	js     80104da9 <sys_dump_physmem+0x63>
    return -1;
  }
  if(argint(2, &numframes) < 0)
80104d77:	83 ec 08             	sub    $0x8,%esp
80104d7a:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104d7d:	50                   	push   %eax
80104d7e:	6a 02                	push   $0x2
80104d80:	e8 95 f2 ff ff       	call   8010401a <argint>
80104d85:	83 c4 10             	add    $0x10,%esp
80104d88:	85 c0                	test   %eax,%eax
80104d8a:	78 24                	js     80104db0 <sys_dump_physmem+0x6a>
    return -1;
  return dump_physmem(frames, pids, numframes);
80104d8c:	83 ec 04             	sub    $0x4,%esp
80104d8f:	ff 75 ec             	pushl  -0x14(%ebp)
80104d92:	ff 75 f0             	pushl  -0x10(%ebp)
80104d95:	ff 75 f4             	pushl  -0xc(%ebp)
80104d98:	e8 1a ec ff ff       	call   801039b7 <dump_physmem>
80104d9d:	83 c4 10             	add    $0x10,%esp
}
80104da0:	c9                   	leave  
80104da1:	c3                   	ret    
    return -1;
80104da2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104da7:	eb f7                	jmp    80104da0 <sys_dump_physmem+0x5a>
    return -1;
80104da9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104dae:	eb f0                	jmp    80104da0 <sys_dump_physmem+0x5a>
    return -1;
80104db0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104db5:	eb e9                	jmp    80104da0 <sys_dump_physmem+0x5a>

80104db7 <sys_getpid>:

int
sys_getpid(void)
{
80104db7:	55                   	push   %ebp
80104db8:	89 e5                	mov    %esp,%ebp
80104dba:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104dbd:	e8 00 e5 ff ff       	call   801032c2 <myproc>
80104dc2:	8b 40 10             	mov    0x10(%eax),%eax
}
80104dc5:	c9                   	leave  
80104dc6:	c3                   	ret    

80104dc7 <sys_sbrk>:

int
sys_sbrk(void)
{
80104dc7:	55                   	push   %ebp
80104dc8:	89 e5                	mov    %esp,%ebp
80104dca:	53                   	push   %ebx
80104dcb:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104dce:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104dd1:	50                   	push   %eax
80104dd2:	6a 00                	push   $0x0
80104dd4:	e8 41 f2 ff ff       	call   8010401a <argint>
80104dd9:	83 c4 10             	add    $0x10,%esp
80104ddc:	85 c0                	test   %eax,%eax
80104dde:	78 27                	js     80104e07 <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80104de0:	e8 dd e4 ff ff       	call   801032c2 <myproc>
80104de5:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104de7:	83 ec 0c             	sub    $0xc,%esp
80104dea:	ff 75 f4             	pushl  -0xc(%ebp)
80104ded:	e8 f7 e5 ff ff       	call   801033e9 <growproc>
80104df2:	83 c4 10             	add    $0x10,%esp
80104df5:	85 c0                	test   %eax,%eax
80104df7:	78 07                	js     80104e00 <sys_sbrk+0x39>
    return -1;
  return addr;
}
80104df9:	89 d8                	mov    %ebx,%eax
80104dfb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104dfe:	c9                   	leave  
80104dff:	c3                   	ret    
    return -1;
80104e00:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104e05:	eb f2                	jmp    80104df9 <sys_sbrk+0x32>
    return -1;
80104e07:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104e0c:	eb eb                	jmp    80104df9 <sys_sbrk+0x32>

80104e0e <sys_sleep>:

int
sys_sleep(void)
{
80104e0e:	55                   	push   %ebp
80104e0f:	89 e5                	mov    %esp,%ebp
80104e11:	53                   	push   %ebx
80104e12:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104e15:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e18:	50                   	push   %eax
80104e19:	6a 00                	push   $0x0
80104e1b:	e8 fa f1 ff ff       	call   8010401a <argint>
80104e20:	83 c4 10             	add    $0x10,%esp
80104e23:	85 c0                	test   %eax,%eax
80104e25:	78 75                	js     80104e9c <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80104e27:	83 ec 0c             	sub    $0xc,%esp
80104e2a:	68 e0 d6 35 80       	push   $0x8035d6e0
80104e2f:	e8 ef ee ff ff       	call   80103d23 <acquire>
  ticks0 = ticks;
80104e34:	8b 1d 20 df 35 80    	mov    0x8035df20,%ebx
  while(ticks - ticks0 < n){
80104e3a:	83 c4 10             	add    $0x10,%esp
80104e3d:	a1 20 df 35 80       	mov    0x8035df20,%eax
80104e42:	29 d8                	sub    %ebx,%eax
80104e44:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104e47:	73 39                	jae    80104e82 <sys_sleep+0x74>
    if(myproc()->killed){
80104e49:	e8 74 e4 ff ff       	call   801032c2 <myproc>
80104e4e:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104e52:	75 17                	jne    80104e6b <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80104e54:	83 ec 08             	sub    $0x8,%esp
80104e57:	68 e0 d6 35 80       	push   $0x8035d6e0
80104e5c:	68 20 df 35 80       	push   $0x8035df20
80104e61:	e8 35 e9 ff ff       	call   8010379b <sleep>
80104e66:	83 c4 10             	add    $0x10,%esp
80104e69:	eb d2                	jmp    80104e3d <sys_sleep+0x2f>
      release(&tickslock);
80104e6b:	83 ec 0c             	sub    $0xc,%esp
80104e6e:	68 e0 d6 35 80       	push   $0x8035d6e0
80104e73:	e8 10 ef ff ff       	call   80103d88 <release>
      return -1;
80104e78:	83 c4 10             	add    $0x10,%esp
80104e7b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e80:	eb 15                	jmp    80104e97 <sys_sleep+0x89>
  }
  release(&tickslock);
80104e82:	83 ec 0c             	sub    $0xc,%esp
80104e85:	68 e0 d6 35 80       	push   $0x8035d6e0
80104e8a:	e8 f9 ee ff ff       	call   80103d88 <release>
  return 0;
80104e8f:	83 c4 10             	add    $0x10,%esp
80104e92:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e97:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e9a:	c9                   	leave  
80104e9b:	c3                   	ret    
    return -1;
80104e9c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ea1:	eb f4                	jmp    80104e97 <sys_sleep+0x89>

80104ea3 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104ea3:	55                   	push   %ebp
80104ea4:	89 e5                	mov    %esp,%ebp
80104ea6:	53                   	push   %ebx
80104ea7:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80104eaa:	68 e0 d6 35 80       	push   $0x8035d6e0
80104eaf:	e8 6f ee ff ff       	call   80103d23 <acquire>
  xticks = ticks;
80104eb4:	8b 1d 20 df 35 80    	mov    0x8035df20,%ebx
  release(&tickslock);
80104eba:	c7 04 24 e0 d6 35 80 	movl   $0x8035d6e0,(%esp)
80104ec1:	e8 c2 ee ff ff       	call   80103d88 <release>
  return xticks;
}
80104ec6:	89 d8                	mov    %ebx,%eax
80104ec8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104ecb:	c9                   	leave  
80104ecc:	c3                   	ret    

80104ecd <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80104ecd:	1e                   	push   %ds
  pushl %es
80104ece:	06                   	push   %es
  pushl %fs
80104ecf:	0f a0                	push   %fs
  pushl %gs
80104ed1:	0f a8                	push   %gs
  pushal
80104ed3:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80104ed4:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80104ed8:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80104eda:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80104edc:	54                   	push   %esp
  call trap
80104edd:	e8 e3 00 00 00       	call   80104fc5 <trap>
  addl $4, %esp
80104ee2:	83 c4 04             	add    $0x4,%esp

80104ee5 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80104ee5:	61                   	popa   
  popl %gs
80104ee6:	0f a9                	pop    %gs
  popl %fs
80104ee8:	0f a1                	pop    %fs
  popl %es
80104eea:	07                   	pop    %es
  popl %ds
80104eeb:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80104eec:	83 c4 08             	add    $0x8,%esp
  iret
80104eef:	cf                   	iret   

80104ef0 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80104ef0:	55                   	push   %ebp
80104ef1:	89 e5                	mov    %esp,%ebp
80104ef3:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
80104ef6:	b8 00 00 00 00       	mov    $0x0,%eax
80104efb:	eb 4a                	jmp    80104f47 <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80104efd:	8b 0c 85 08 a0 10 80 	mov    -0x7fef5ff8(,%eax,4),%ecx
80104f04:	66 89 0c c5 20 d7 35 	mov    %cx,-0x7fca28e0(,%eax,8)
80104f0b:	80 
80104f0c:	66 c7 04 c5 22 d7 35 	movw   $0x8,-0x7fca28de(,%eax,8)
80104f13:	80 08 00 
80104f16:	c6 04 c5 24 d7 35 80 	movb   $0x0,-0x7fca28dc(,%eax,8)
80104f1d:	00 
80104f1e:	0f b6 14 c5 25 d7 35 	movzbl -0x7fca28db(,%eax,8),%edx
80104f25:	80 
80104f26:	83 e2 f0             	and    $0xfffffff0,%edx
80104f29:	83 ca 0e             	or     $0xe,%edx
80104f2c:	83 e2 8f             	and    $0xffffff8f,%edx
80104f2f:	83 ca 80             	or     $0xffffff80,%edx
80104f32:	88 14 c5 25 d7 35 80 	mov    %dl,-0x7fca28db(,%eax,8)
80104f39:	c1 e9 10             	shr    $0x10,%ecx
80104f3c:	66 89 0c c5 26 d7 35 	mov    %cx,-0x7fca28da(,%eax,8)
80104f43:	80 
  for(i = 0; i < 256; i++)
80104f44:	83 c0 01             	add    $0x1,%eax
80104f47:	3d ff 00 00 00       	cmp    $0xff,%eax
80104f4c:	7e af                	jle    80104efd <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80104f4e:	8b 15 08 a1 10 80    	mov    0x8010a108,%edx
80104f54:	66 89 15 20 d9 35 80 	mov    %dx,0x8035d920
80104f5b:	66 c7 05 22 d9 35 80 	movw   $0x8,0x8035d922
80104f62:	08 00 
80104f64:	c6 05 24 d9 35 80 00 	movb   $0x0,0x8035d924
80104f6b:	0f b6 05 25 d9 35 80 	movzbl 0x8035d925,%eax
80104f72:	83 c8 0f             	or     $0xf,%eax
80104f75:	83 e0 ef             	and    $0xffffffef,%eax
80104f78:	83 c8 e0             	or     $0xffffffe0,%eax
80104f7b:	a2 25 d9 35 80       	mov    %al,0x8035d925
80104f80:	c1 ea 10             	shr    $0x10,%edx
80104f83:	66 89 15 26 d9 35 80 	mov    %dx,0x8035d926

  initlock(&tickslock, "time");
80104f8a:	83 ec 08             	sub    $0x8,%esp
80104f8d:	68 fd 6d 10 80       	push   $0x80106dfd
80104f92:	68 e0 d6 35 80       	push   $0x8035d6e0
80104f97:	e8 4b ec ff ff       	call   80103be7 <initlock>
}
80104f9c:	83 c4 10             	add    $0x10,%esp
80104f9f:	c9                   	leave  
80104fa0:	c3                   	ret    

80104fa1 <idtinit>:

void
idtinit(void)
{
80104fa1:	55                   	push   %ebp
80104fa2:	89 e5                	mov    %esp,%ebp
80104fa4:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80104fa7:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
80104fad:	b8 20 d7 35 80       	mov    $0x8035d720,%eax
80104fb2:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80104fb6:	c1 e8 10             	shr    $0x10,%eax
80104fb9:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
80104fbd:	8d 45 fa             	lea    -0x6(%ebp),%eax
80104fc0:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
80104fc3:	c9                   	leave  
80104fc4:	c3                   	ret    

80104fc5 <trap>:

void
trap(struct trapframe *tf)
{
80104fc5:	55                   	push   %ebp
80104fc6:	89 e5                	mov    %esp,%ebp
80104fc8:	57                   	push   %edi
80104fc9:	56                   	push   %esi
80104fca:	53                   	push   %ebx
80104fcb:	83 ec 1c             	sub    $0x1c,%esp
80104fce:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
80104fd1:	8b 43 30             	mov    0x30(%ebx),%eax
80104fd4:	83 f8 40             	cmp    $0x40,%eax
80104fd7:	74 13                	je     80104fec <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
80104fd9:	83 e8 20             	sub    $0x20,%eax
80104fdc:	83 f8 1f             	cmp    $0x1f,%eax
80104fdf:	0f 87 3a 01 00 00    	ja     8010511f <trap+0x15a>
80104fe5:	ff 24 85 a4 6e 10 80 	jmp    *-0x7fef915c(,%eax,4)
    if(myproc()->killed)
80104fec:	e8 d1 e2 ff ff       	call   801032c2 <myproc>
80104ff1:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104ff5:	75 1f                	jne    80105016 <trap+0x51>
    myproc()->tf = tf;
80104ff7:	e8 c6 e2 ff ff       	call   801032c2 <myproc>
80104ffc:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
80104fff:	e8 d9 f0 ff ff       	call   801040dd <syscall>
    if(myproc()->killed)
80105004:	e8 b9 e2 ff ff       	call   801032c2 <myproc>
80105009:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010500d:	74 7e                	je     8010508d <trap+0xc8>
      exit();
8010500f:	e8 8f e6 ff ff       	call   801036a3 <exit>
80105014:	eb 77                	jmp    8010508d <trap+0xc8>
      exit();
80105016:	e8 88 e6 ff ff       	call   801036a3 <exit>
8010501b:	eb da                	jmp    80104ff7 <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
8010501d:	e8 85 e2 ff ff       	call   801032a7 <cpuid>
80105022:	85 c0                	test   %eax,%eax
80105024:	74 6f                	je     80105095 <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
80105026:	e8 1c d4 ff ff       	call   80102447 <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
8010502b:	e8 92 e2 ff ff       	call   801032c2 <myproc>
80105030:	85 c0                	test   %eax,%eax
80105032:	74 1c                	je     80105050 <trap+0x8b>
80105034:	e8 89 e2 ff ff       	call   801032c2 <myproc>
80105039:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010503d:	74 11                	je     80105050 <trap+0x8b>
8010503f:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105043:	83 e0 03             	and    $0x3,%eax
80105046:	66 83 f8 03          	cmp    $0x3,%ax
8010504a:	0f 84 62 01 00 00    	je     801051b2 <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80105050:	e8 6d e2 ff ff       	call   801032c2 <myproc>
80105055:	85 c0                	test   %eax,%eax
80105057:	74 0f                	je     80105068 <trap+0xa3>
80105059:	e8 64 e2 ff ff       	call   801032c2 <myproc>
8010505e:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
80105062:	0f 84 54 01 00 00    	je     801051bc <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80105068:	e8 55 e2 ff ff       	call   801032c2 <myproc>
8010506d:	85 c0                	test   %eax,%eax
8010506f:	74 1c                	je     8010508d <trap+0xc8>
80105071:	e8 4c e2 ff ff       	call   801032c2 <myproc>
80105076:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010507a:	74 11                	je     8010508d <trap+0xc8>
8010507c:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105080:	83 e0 03             	and    $0x3,%eax
80105083:	66 83 f8 03          	cmp    $0x3,%ax
80105087:	0f 84 43 01 00 00    	je     801051d0 <trap+0x20b>
    exit();
}
8010508d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105090:	5b                   	pop    %ebx
80105091:	5e                   	pop    %esi
80105092:	5f                   	pop    %edi
80105093:	5d                   	pop    %ebp
80105094:	c3                   	ret    
      acquire(&tickslock);
80105095:	83 ec 0c             	sub    $0xc,%esp
80105098:	68 e0 d6 35 80       	push   $0x8035d6e0
8010509d:	e8 81 ec ff ff       	call   80103d23 <acquire>
      ticks++;
801050a2:	83 05 20 df 35 80 01 	addl   $0x1,0x8035df20
      wakeup(&ticks);
801050a9:	c7 04 24 20 df 35 80 	movl   $0x8035df20,(%esp)
801050b0:	e8 65 e8 ff ff       	call   8010391a <wakeup>
      release(&tickslock);
801050b5:	c7 04 24 e0 d6 35 80 	movl   $0x8035d6e0,(%esp)
801050bc:	e8 c7 ec ff ff       	call   80103d88 <release>
801050c1:	83 c4 10             	add    $0x10,%esp
801050c4:	e9 5d ff ff ff       	jmp    80105026 <trap+0x61>
    ideintr();
801050c9:	e8 a5 cc ff ff       	call   80101d73 <ideintr>
    lapiceoi();
801050ce:	e8 74 d3 ff ff       	call   80102447 <lapiceoi>
    break;
801050d3:	e9 53 ff ff ff       	jmp    8010502b <trap+0x66>
    kbdintr();
801050d8:	e8 ae d1 ff ff       	call   8010228b <kbdintr>
    lapiceoi();
801050dd:	e8 65 d3 ff ff       	call   80102447 <lapiceoi>
    break;
801050e2:	e9 44 ff ff ff       	jmp    8010502b <trap+0x66>
    uartintr();
801050e7:	e8 05 02 00 00       	call   801052f1 <uartintr>
    lapiceoi();
801050ec:	e8 56 d3 ff ff       	call   80102447 <lapiceoi>
    break;
801050f1:	e9 35 ff ff ff       	jmp    8010502b <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801050f6:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
801050f9:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801050fd:	e8 a5 e1 ff ff       	call   801032a7 <cpuid>
80105102:	57                   	push   %edi
80105103:	0f b7 f6             	movzwl %si,%esi
80105106:	56                   	push   %esi
80105107:	50                   	push   %eax
80105108:	68 08 6e 10 80       	push   $0x80106e08
8010510d:	e8 f9 b4 ff ff       	call   8010060b <cprintf>
    lapiceoi();
80105112:	e8 30 d3 ff ff       	call   80102447 <lapiceoi>
    break;
80105117:	83 c4 10             	add    $0x10,%esp
8010511a:	e9 0c ff ff ff       	jmp    8010502b <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
8010511f:	e8 9e e1 ff ff       	call   801032c2 <myproc>
80105124:	85 c0                	test   %eax,%eax
80105126:	74 5f                	je     80105187 <trap+0x1c2>
80105128:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
8010512c:	74 59                	je     80105187 <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
8010512e:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105131:	8b 43 38             	mov    0x38(%ebx),%eax
80105134:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105137:	e8 6b e1 ff ff       	call   801032a7 <cpuid>
8010513c:	89 45 e0             	mov    %eax,-0x20(%ebp)
8010513f:	8b 53 34             	mov    0x34(%ebx),%edx
80105142:	89 55 dc             	mov    %edx,-0x24(%ebp)
80105145:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
80105148:	e8 75 e1 ff ff       	call   801032c2 <myproc>
8010514d:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105150:	89 4d d8             	mov    %ecx,-0x28(%ebp)
80105153:	e8 6a e1 ff ff       	call   801032c2 <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105158:	57                   	push   %edi
80105159:	ff 75 e4             	pushl  -0x1c(%ebp)
8010515c:	ff 75 e0             	pushl  -0x20(%ebp)
8010515f:	ff 75 dc             	pushl  -0x24(%ebp)
80105162:	56                   	push   %esi
80105163:	ff 75 d8             	pushl  -0x28(%ebp)
80105166:	ff 70 10             	pushl  0x10(%eax)
80105169:	68 60 6e 10 80       	push   $0x80106e60
8010516e:	e8 98 b4 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
80105173:	83 c4 20             	add    $0x20,%esp
80105176:	e8 47 e1 ff ff       	call   801032c2 <myproc>
8010517b:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80105182:	e9 a4 fe ff ff       	jmp    8010502b <trap+0x66>
80105187:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010518a:	8b 73 38             	mov    0x38(%ebx),%esi
8010518d:	e8 15 e1 ff ff       	call   801032a7 <cpuid>
80105192:	83 ec 0c             	sub    $0xc,%esp
80105195:	57                   	push   %edi
80105196:	56                   	push   %esi
80105197:	50                   	push   %eax
80105198:	ff 73 30             	pushl  0x30(%ebx)
8010519b:	68 2c 6e 10 80       	push   $0x80106e2c
801051a0:	e8 66 b4 ff ff       	call   8010060b <cprintf>
      panic("trap");
801051a5:	83 c4 14             	add    $0x14,%esp
801051a8:	68 02 6e 10 80       	push   $0x80106e02
801051ad:	e8 96 b1 ff ff       	call   80100348 <panic>
    exit();
801051b2:	e8 ec e4 ff ff       	call   801036a3 <exit>
801051b7:	e9 94 fe ff ff       	jmp    80105050 <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
801051bc:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
801051c0:	0f 85 a2 fe ff ff    	jne    80105068 <trap+0xa3>
    yield();
801051c6:	e8 9e e5 ff ff       	call   80103769 <yield>
801051cb:	e9 98 fe ff ff       	jmp    80105068 <trap+0xa3>
    exit();
801051d0:	e8 ce e4 ff ff       	call   801036a3 <exit>
801051d5:	e9 b3 fe ff ff       	jmp    8010508d <trap+0xc8>

801051da <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
801051da:	55                   	push   %ebp
801051db:	89 e5                	mov    %esp,%ebp
  if(!uart)
801051dd:	83 3d bc a5 10 80 00 	cmpl   $0x0,0x8010a5bc
801051e4:	74 15                	je     801051fb <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801051e6:	ba fd 03 00 00       	mov    $0x3fd,%edx
801051eb:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
801051ec:	a8 01                	test   $0x1,%al
801051ee:	74 12                	je     80105202 <uartgetc+0x28>
801051f0:	ba f8 03 00 00       	mov    $0x3f8,%edx
801051f5:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
801051f6:	0f b6 c0             	movzbl %al,%eax
}
801051f9:	5d                   	pop    %ebp
801051fa:	c3                   	ret    
    return -1;
801051fb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105200:	eb f7                	jmp    801051f9 <uartgetc+0x1f>
    return -1;
80105202:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105207:	eb f0                	jmp    801051f9 <uartgetc+0x1f>

80105209 <uartputc>:
  if(!uart)
80105209:	83 3d bc a5 10 80 00 	cmpl   $0x0,0x8010a5bc
80105210:	74 3b                	je     8010524d <uartputc+0x44>
{
80105212:	55                   	push   %ebp
80105213:	89 e5                	mov    %esp,%ebp
80105215:	53                   	push   %ebx
80105216:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105219:	bb 00 00 00 00       	mov    $0x0,%ebx
8010521e:	eb 10                	jmp    80105230 <uartputc+0x27>
    microdelay(10);
80105220:	83 ec 0c             	sub    $0xc,%esp
80105223:	6a 0a                	push   $0xa
80105225:	e8 3c d2 ff ff       	call   80102466 <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010522a:	83 c3 01             	add    $0x1,%ebx
8010522d:	83 c4 10             	add    $0x10,%esp
80105230:	83 fb 7f             	cmp    $0x7f,%ebx
80105233:	7f 0a                	jg     8010523f <uartputc+0x36>
80105235:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010523a:	ec                   	in     (%dx),%al
8010523b:	a8 20                	test   $0x20,%al
8010523d:	74 e1                	je     80105220 <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010523f:	8b 45 08             	mov    0x8(%ebp),%eax
80105242:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105247:	ee                   	out    %al,(%dx)
}
80105248:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010524b:	c9                   	leave  
8010524c:	c3                   	ret    
8010524d:	f3 c3                	repz ret 

8010524f <uartinit>:
{
8010524f:	55                   	push   %ebp
80105250:	89 e5                	mov    %esp,%ebp
80105252:	56                   	push   %esi
80105253:	53                   	push   %ebx
80105254:	b9 00 00 00 00       	mov    $0x0,%ecx
80105259:	ba fa 03 00 00       	mov    $0x3fa,%edx
8010525e:	89 c8                	mov    %ecx,%eax
80105260:	ee                   	out    %al,(%dx)
80105261:	be fb 03 00 00       	mov    $0x3fb,%esi
80105266:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
8010526b:	89 f2                	mov    %esi,%edx
8010526d:	ee                   	out    %al,(%dx)
8010526e:	b8 0c 00 00 00       	mov    $0xc,%eax
80105273:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105278:	ee                   	out    %al,(%dx)
80105279:	bb f9 03 00 00       	mov    $0x3f9,%ebx
8010527e:	89 c8                	mov    %ecx,%eax
80105280:	89 da                	mov    %ebx,%edx
80105282:	ee                   	out    %al,(%dx)
80105283:	b8 03 00 00 00       	mov    $0x3,%eax
80105288:	89 f2                	mov    %esi,%edx
8010528a:	ee                   	out    %al,(%dx)
8010528b:	ba fc 03 00 00       	mov    $0x3fc,%edx
80105290:	89 c8                	mov    %ecx,%eax
80105292:	ee                   	out    %al,(%dx)
80105293:	b8 01 00 00 00       	mov    $0x1,%eax
80105298:	89 da                	mov    %ebx,%edx
8010529a:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010529b:	ba fd 03 00 00       	mov    $0x3fd,%edx
801052a0:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
801052a1:	3c ff                	cmp    $0xff,%al
801052a3:	74 45                	je     801052ea <uartinit+0x9b>
  uart = 1;
801052a5:	c7 05 bc a5 10 80 01 	movl   $0x1,0x8010a5bc
801052ac:	00 00 00 
801052af:	ba fa 03 00 00       	mov    $0x3fa,%edx
801052b4:	ec                   	in     (%dx),%al
801052b5:	ba f8 03 00 00       	mov    $0x3f8,%edx
801052ba:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
801052bb:	83 ec 08             	sub    $0x8,%esp
801052be:	6a 00                	push   $0x0
801052c0:	6a 04                	push   $0x4
801052c2:	e8 b7 cc ff ff       	call   80101f7e <ioapicenable>
  for(p="xv6...\n"; *p; p++)
801052c7:	83 c4 10             	add    $0x10,%esp
801052ca:	bb 24 6f 10 80       	mov    $0x80106f24,%ebx
801052cf:	eb 12                	jmp    801052e3 <uartinit+0x94>
    uartputc(*p);
801052d1:	83 ec 0c             	sub    $0xc,%esp
801052d4:	0f be c0             	movsbl %al,%eax
801052d7:	50                   	push   %eax
801052d8:	e8 2c ff ff ff       	call   80105209 <uartputc>
  for(p="xv6...\n"; *p; p++)
801052dd:	83 c3 01             	add    $0x1,%ebx
801052e0:	83 c4 10             	add    $0x10,%esp
801052e3:	0f b6 03             	movzbl (%ebx),%eax
801052e6:	84 c0                	test   %al,%al
801052e8:	75 e7                	jne    801052d1 <uartinit+0x82>
}
801052ea:	8d 65 f8             	lea    -0x8(%ebp),%esp
801052ed:	5b                   	pop    %ebx
801052ee:	5e                   	pop    %esi
801052ef:	5d                   	pop    %ebp
801052f0:	c3                   	ret    

801052f1 <uartintr>:

void
uartintr(void)
{
801052f1:	55                   	push   %ebp
801052f2:	89 e5                	mov    %esp,%ebp
801052f4:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
801052f7:	68 da 51 10 80       	push   $0x801051da
801052fc:	e8 3d b4 ff ff       	call   8010073e <consoleintr>
}
80105301:	83 c4 10             	add    $0x10,%esp
80105304:	c9                   	leave  
80105305:	c3                   	ret    

80105306 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80105306:	6a 00                	push   $0x0
  pushl $0
80105308:	6a 00                	push   $0x0
  jmp alltraps
8010530a:	e9 be fb ff ff       	jmp    80104ecd <alltraps>

8010530f <vector1>:
.globl vector1
vector1:
  pushl $0
8010530f:	6a 00                	push   $0x0
  pushl $1
80105311:	6a 01                	push   $0x1
  jmp alltraps
80105313:	e9 b5 fb ff ff       	jmp    80104ecd <alltraps>

80105318 <vector2>:
.globl vector2
vector2:
  pushl $0
80105318:	6a 00                	push   $0x0
  pushl $2
8010531a:	6a 02                	push   $0x2
  jmp alltraps
8010531c:	e9 ac fb ff ff       	jmp    80104ecd <alltraps>

80105321 <vector3>:
.globl vector3
vector3:
  pushl $0
80105321:	6a 00                	push   $0x0
  pushl $3
80105323:	6a 03                	push   $0x3
  jmp alltraps
80105325:	e9 a3 fb ff ff       	jmp    80104ecd <alltraps>

8010532a <vector4>:
.globl vector4
vector4:
  pushl $0
8010532a:	6a 00                	push   $0x0
  pushl $4
8010532c:	6a 04                	push   $0x4
  jmp alltraps
8010532e:	e9 9a fb ff ff       	jmp    80104ecd <alltraps>

80105333 <vector5>:
.globl vector5
vector5:
  pushl $0
80105333:	6a 00                	push   $0x0
  pushl $5
80105335:	6a 05                	push   $0x5
  jmp alltraps
80105337:	e9 91 fb ff ff       	jmp    80104ecd <alltraps>

8010533c <vector6>:
.globl vector6
vector6:
  pushl $0
8010533c:	6a 00                	push   $0x0
  pushl $6
8010533e:	6a 06                	push   $0x6
  jmp alltraps
80105340:	e9 88 fb ff ff       	jmp    80104ecd <alltraps>

80105345 <vector7>:
.globl vector7
vector7:
  pushl $0
80105345:	6a 00                	push   $0x0
  pushl $7
80105347:	6a 07                	push   $0x7
  jmp alltraps
80105349:	e9 7f fb ff ff       	jmp    80104ecd <alltraps>

8010534e <vector8>:
.globl vector8
vector8:
  pushl $8
8010534e:	6a 08                	push   $0x8
  jmp alltraps
80105350:	e9 78 fb ff ff       	jmp    80104ecd <alltraps>

80105355 <vector9>:
.globl vector9
vector9:
  pushl $0
80105355:	6a 00                	push   $0x0
  pushl $9
80105357:	6a 09                	push   $0x9
  jmp alltraps
80105359:	e9 6f fb ff ff       	jmp    80104ecd <alltraps>

8010535e <vector10>:
.globl vector10
vector10:
  pushl $10
8010535e:	6a 0a                	push   $0xa
  jmp alltraps
80105360:	e9 68 fb ff ff       	jmp    80104ecd <alltraps>

80105365 <vector11>:
.globl vector11
vector11:
  pushl $11
80105365:	6a 0b                	push   $0xb
  jmp alltraps
80105367:	e9 61 fb ff ff       	jmp    80104ecd <alltraps>

8010536c <vector12>:
.globl vector12
vector12:
  pushl $12
8010536c:	6a 0c                	push   $0xc
  jmp alltraps
8010536e:	e9 5a fb ff ff       	jmp    80104ecd <alltraps>

80105373 <vector13>:
.globl vector13
vector13:
  pushl $13
80105373:	6a 0d                	push   $0xd
  jmp alltraps
80105375:	e9 53 fb ff ff       	jmp    80104ecd <alltraps>

8010537a <vector14>:
.globl vector14
vector14:
  pushl $14
8010537a:	6a 0e                	push   $0xe
  jmp alltraps
8010537c:	e9 4c fb ff ff       	jmp    80104ecd <alltraps>

80105381 <vector15>:
.globl vector15
vector15:
  pushl $0
80105381:	6a 00                	push   $0x0
  pushl $15
80105383:	6a 0f                	push   $0xf
  jmp alltraps
80105385:	e9 43 fb ff ff       	jmp    80104ecd <alltraps>

8010538a <vector16>:
.globl vector16
vector16:
  pushl $0
8010538a:	6a 00                	push   $0x0
  pushl $16
8010538c:	6a 10                	push   $0x10
  jmp alltraps
8010538e:	e9 3a fb ff ff       	jmp    80104ecd <alltraps>

80105393 <vector17>:
.globl vector17
vector17:
  pushl $17
80105393:	6a 11                	push   $0x11
  jmp alltraps
80105395:	e9 33 fb ff ff       	jmp    80104ecd <alltraps>

8010539a <vector18>:
.globl vector18
vector18:
  pushl $0
8010539a:	6a 00                	push   $0x0
  pushl $18
8010539c:	6a 12                	push   $0x12
  jmp alltraps
8010539e:	e9 2a fb ff ff       	jmp    80104ecd <alltraps>

801053a3 <vector19>:
.globl vector19
vector19:
  pushl $0
801053a3:	6a 00                	push   $0x0
  pushl $19
801053a5:	6a 13                	push   $0x13
  jmp alltraps
801053a7:	e9 21 fb ff ff       	jmp    80104ecd <alltraps>

801053ac <vector20>:
.globl vector20
vector20:
  pushl $0
801053ac:	6a 00                	push   $0x0
  pushl $20
801053ae:	6a 14                	push   $0x14
  jmp alltraps
801053b0:	e9 18 fb ff ff       	jmp    80104ecd <alltraps>

801053b5 <vector21>:
.globl vector21
vector21:
  pushl $0
801053b5:	6a 00                	push   $0x0
  pushl $21
801053b7:	6a 15                	push   $0x15
  jmp alltraps
801053b9:	e9 0f fb ff ff       	jmp    80104ecd <alltraps>

801053be <vector22>:
.globl vector22
vector22:
  pushl $0
801053be:	6a 00                	push   $0x0
  pushl $22
801053c0:	6a 16                	push   $0x16
  jmp alltraps
801053c2:	e9 06 fb ff ff       	jmp    80104ecd <alltraps>

801053c7 <vector23>:
.globl vector23
vector23:
  pushl $0
801053c7:	6a 00                	push   $0x0
  pushl $23
801053c9:	6a 17                	push   $0x17
  jmp alltraps
801053cb:	e9 fd fa ff ff       	jmp    80104ecd <alltraps>

801053d0 <vector24>:
.globl vector24
vector24:
  pushl $0
801053d0:	6a 00                	push   $0x0
  pushl $24
801053d2:	6a 18                	push   $0x18
  jmp alltraps
801053d4:	e9 f4 fa ff ff       	jmp    80104ecd <alltraps>

801053d9 <vector25>:
.globl vector25
vector25:
  pushl $0
801053d9:	6a 00                	push   $0x0
  pushl $25
801053db:	6a 19                	push   $0x19
  jmp alltraps
801053dd:	e9 eb fa ff ff       	jmp    80104ecd <alltraps>

801053e2 <vector26>:
.globl vector26
vector26:
  pushl $0
801053e2:	6a 00                	push   $0x0
  pushl $26
801053e4:	6a 1a                	push   $0x1a
  jmp alltraps
801053e6:	e9 e2 fa ff ff       	jmp    80104ecd <alltraps>

801053eb <vector27>:
.globl vector27
vector27:
  pushl $0
801053eb:	6a 00                	push   $0x0
  pushl $27
801053ed:	6a 1b                	push   $0x1b
  jmp alltraps
801053ef:	e9 d9 fa ff ff       	jmp    80104ecd <alltraps>

801053f4 <vector28>:
.globl vector28
vector28:
  pushl $0
801053f4:	6a 00                	push   $0x0
  pushl $28
801053f6:	6a 1c                	push   $0x1c
  jmp alltraps
801053f8:	e9 d0 fa ff ff       	jmp    80104ecd <alltraps>

801053fd <vector29>:
.globl vector29
vector29:
  pushl $0
801053fd:	6a 00                	push   $0x0
  pushl $29
801053ff:	6a 1d                	push   $0x1d
  jmp alltraps
80105401:	e9 c7 fa ff ff       	jmp    80104ecd <alltraps>

80105406 <vector30>:
.globl vector30
vector30:
  pushl $0
80105406:	6a 00                	push   $0x0
  pushl $30
80105408:	6a 1e                	push   $0x1e
  jmp alltraps
8010540a:	e9 be fa ff ff       	jmp    80104ecd <alltraps>

8010540f <vector31>:
.globl vector31
vector31:
  pushl $0
8010540f:	6a 00                	push   $0x0
  pushl $31
80105411:	6a 1f                	push   $0x1f
  jmp alltraps
80105413:	e9 b5 fa ff ff       	jmp    80104ecd <alltraps>

80105418 <vector32>:
.globl vector32
vector32:
  pushl $0
80105418:	6a 00                	push   $0x0
  pushl $32
8010541a:	6a 20                	push   $0x20
  jmp alltraps
8010541c:	e9 ac fa ff ff       	jmp    80104ecd <alltraps>

80105421 <vector33>:
.globl vector33
vector33:
  pushl $0
80105421:	6a 00                	push   $0x0
  pushl $33
80105423:	6a 21                	push   $0x21
  jmp alltraps
80105425:	e9 a3 fa ff ff       	jmp    80104ecd <alltraps>

8010542a <vector34>:
.globl vector34
vector34:
  pushl $0
8010542a:	6a 00                	push   $0x0
  pushl $34
8010542c:	6a 22                	push   $0x22
  jmp alltraps
8010542e:	e9 9a fa ff ff       	jmp    80104ecd <alltraps>

80105433 <vector35>:
.globl vector35
vector35:
  pushl $0
80105433:	6a 00                	push   $0x0
  pushl $35
80105435:	6a 23                	push   $0x23
  jmp alltraps
80105437:	e9 91 fa ff ff       	jmp    80104ecd <alltraps>

8010543c <vector36>:
.globl vector36
vector36:
  pushl $0
8010543c:	6a 00                	push   $0x0
  pushl $36
8010543e:	6a 24                	push   $0x24
  jmp alltraps
80105440:	e9 88 fa ff ff       	jmp    80104ecd <alltraps>

80105445 <vector37>:
.globl vector37
vector37:
  pushl $0
80105445:	6a 00                	push   $0x0
  pushl $37
80105447:	6a 25                	push   $0x25
  jmp alltraps
80105449:	e9 7f fa ff ff       	jmp    80104ecd <alltraps>

8010544e <vector38>:
.globl vector38
vector38:
  pushl $0
8010544e:	6a 00                	push   $0x0
  pushl $38
80105450:	6a 26                	push   $0x26
  jmp alltraps
80105452:	e9 76 fa ff ff       	jmp    80104ecd <alltraps>

80105457 <vector39>:
.globl vector39
vector39:
  pushl $0
80105457:	6a 00                	push   $0x0
  pushl $39
80105459:	6a 27                	push   $0x27
  jmp alltraps
8010545b:	e9 6d fa ff ff       	jmp    80104ecd <alltraps>

80105460 <vector40>:
.globl vector40
vector40:
  pushl $0
80105460:	6a 00                	push   $0x0
  pushl $40
80105462:	6a 28                	push   $0x28
  jmp alltraps
80105464:	e9 64 fa ff ff       	jmp    80104ecd <alltraps>

80105469 <vector41>:
.globl vector41
vector41:
  pushl $0
80105469:	6a 00                	push   $0x0
  pushl $41
8010546b:	6a 29                	push   $0x29
  jmp alltraps
8010546d:	e9 5b fa ff ff       	jmp    80104ecd <alltraps>

80105472 <vector42>:
.globl vector42
vector42:
  pushl $0
80105472:	6a 00                	push   $0x0
  pushl $42
80105474:	6a 2a                	push   $0x2a
  jmp alltraps
80105476:	e9 52 fa ff ff       	jmp    80104ecd <alltraps>

8010547b <vector43>:
.globl vector43
vector43:
  pushl $0
8010547b:	6a 00                	push   $0x0
  pushl $43
8010547d:	6a 2b                	push   $0x2b
  jmp alltraps
8010547f:	e9 49 fa ff ff       	jmp    80104ecd <alltraps>

80105484 <vector44>:
.globl vector44
vector44:
  pushl $0
80105484:	6a 00                	push   $0x0
  pushl $44
80105486:	6a 2c                	push   $0x2c
  jmp alltraps
80105488:	e9 40 fa ff ff       	jmp    80104ecd <alltraps>

8010548d <vector45>:
.globl vector45
vector45:
  pushl $0
8010548d:	6a 00                	push   $0x0
  pushl $45
8010548f:	6a 2d                	push   $0x2d
  jmp alltraps
80105491:	e9 37 fa ff ff       	jmp    80104ecd <alltraps>

80105496 <vector46>:
.globl vector46
vector46:
  pushl $0
80105496:	6a 00                	push   $0x0
  pushl $46
80105498:	6a 2e                	push   $0x2e
  jmp alltraps
8010549a:	e9 2e fa ff ff       	jmp    80104ecd <alltraps>

8010549f <vector47>:
.globl vector47
vector47:
  pushl $0
8010549f:	6a 00                	push   $0x0
  pushl $47
801054a1:	6a 2f                	push   $0x2f
  jmp alltraps
801054a3:	e9 25 fa ff ff       	jmp    80104ecd <alltraps>

801054a8 <vector48>:
.globl vector48
vector48:
  pushl $0
801054a8:	6a 00                	push   $0x0
  pushl $48
801054aa:	6a 30                	push   $0x30
  jmp alltraps
801054ac:	e9 1c fa ff ff       	jmp    80104ecd <alltraps>

801054b1 <vector49>:
.globl vector49
vector49:
  pushl $0
801054b1:	6a 00                	push   $0x0
  pushl $49
801054b3:	6a 31                	push   $0x31
  jmp alltraps
801054b5:	e9 13 fa ff ff       	jmp    80104ecd <alltraps>

801054ba <vector50>:
.globl vector50
vector50:
  pushl $0
801054ba:	6a 00                	push   $0x0
  pushl $50
801054bc:	6a 32                	push   $0x32
  jmp alltraps
801054be:	e9 0a fa ff ff       	jmp    80104ecd <alltraps>

801054c3 <vector51>:
.globl vector51
vector51:
  pushl $0
801054c3:	6a 00                	push   $0x0
  pushl $51
801054c5:	6a 33                	push   $0x33
  jmp alltraps
801054c7:	e9 01 fa ff ff       	jmp    80104ecd <alltraps>

801054cc <vector52>:
.globl vector52
vector52:
  pushl $0
801054cc:	6a 00                	push   $0x0
  pushl $52
801054ce:	6a 34                	push   $0x34
  jmp alltraps
801054d0:	e9 f8 f9 ff ff       	jmp    80104ecd <alltraps>

801054d5 <vector53>:
.globl vector53
vector53:
  pushl $0
801054d5:	6a 00                	push   $0x0
  pushl $53
801054d7:	6a 35                	push   $0x35
  jmp alltraps
801054d9:	e9 ef f9 ff ff       	jmp    80104ecd <alltraps>

801054de <vector54>:
.globl vector54
vector54:
  pushl $0
801054de:	6a 00                	push   $0x0
  pushl $54
801054e0:	6a 36                	push   $0x36
  jmp alltraps
801054e2:	e9 e6 f9 ff ff       	jmp    80104ecd <alltraps>

801054e7 <vector55>:
.globl vector55
vector55:
  pushl $0
801054e7:	6a 00                	push   $0x0
  pushl $55
801054e9:	6a 37                	push   $0x37
  jmp alltraps
801054eb:	e9 dd f9 ff ff       	jmp    80104ecd <alltraps>

801054f0 <vector56>:
.globl vector56
vector56:
  pushl $0
801054f0:	6a 00                	push   $0x0
  pushl $56
801054f2:	6a 38                	push   $0x38
  jmp alltraps
801054f4:	e9 d4 f9 ff ff       	jmp    80104ecd <alltraps>

801054f9 <vector57>:
.globl vector57
vector57:
  pushl $0
801054f9:	6a 00                	push   $0x0
  pushl $57
801054fb:	6a 39                	push   $0x39
  jmp alltraps
801054fd:	e9 cb f9 ff ff       	jmp    80104ecd <alltraps>

80105502 <vector58>:
.globl vector58
vector58:
  pushl $0
80105502:	6a 00                	push   $0x0
  pushl $58
80105504:	6a 3a                	push   $0x3a
  jmp alltraps
80105506:	e9 c2 f9 ff ff       	jmp    80104ecd <alltraps>

8010550b <vector59>:
.globl vector59
vector59:
  pushl $0
8010550b:	6a 00                	push   $0x0
  pushl $59
8010550d:	6a 3b                	push   $0x3b
  jmp alltraps
8010550f:	e9 b9 f9 ff ff       	jmp    80104ecd <alltraps>

80105514 <vector60>:
.globl vector60
vector60:
  pushl $0
80105514:	6a 00                	push   $0x0
  pushl $60
80105516:	6a 3c                	push   $0x3c
  jmp alltraps
80105518:	e9 b0 f9 ff ff       	jmp    80104ecd <alltraps>

8010551d <vector61>:
.globl vector61
vector61:
  pushl $0
8010551d:	6a 00                	push   $0x0
  pushl $61
8010551f:	6a 3d                	push   $0x3d
  jmp alltraps
80105521:	e9 a7 f9 ff ff       	jmp    80104ecd <alltraps>

80105526 <vector62>:
.globl vector62
vector62:
  pushl $0
80105526:	6a 00                	push   $0x0
  pushl $62
80105528:	6a 3e                	push   $0x3e
  jmp alltraps
8010552a:	e9 9e f9 ff ff       	jmp    80104ecd <alltraps>

8010552f <vector63>:
.globl vector63
vector63:
  pushl $0
8010552f:	6a 00                	push   $0x0
  pushl $63
80105531:	6a 3f                	push   $0x3f
  jmp alltraps
80105533:	e9 95 f9 ff ff       	jmp    80104ecd <alltraps>

80105538 <vector64>:
.globl vector64
vector64:
  pushl $0
80105538:	6a 00                	push   $0x0
  pushl $64
8010553a:	6a 40                	push   $0x40
  jmp alltraps
8010553c:	e9 8c f9 ff ff       	jmp    80104ecd <alltraps>

80105541 <vector65>:
.globl vector65
vector65:
  pushl $0
80105541:	6a 00                	push   $0x0
  pushl $65
80105543:	6a 41                	push   $0x41
  jmp alltraps
80105545:	e9 83 f9 ff ff       	jmp    80104ecd <alltraps>

8010554a <vector66>:
.globl vector66
vector66:
  pushl $0
8010554a:	6a 00                	push   $0x0
  pushl $66
8010554c:	6a 42                	push   $0x42
  jmp alltraps
8010554e:	e9 7a f9 ff ff       	jmp    80104ecd <alltraps>

80105553 <vector67>:
.globl vector67
vector67:
  pushl $0
80105553:	6a 00                	push   $0x0
  pushl $67
80105555:	6a 43                	push   $0x43
  jmp alltraps
80105557:	e9 71 f9 ff ff       	jmp    80104ecd <alltraps>

8010555c <vector68>:
.globl vector68
vector68:
  pushl $0
8010555c:	6a 00                	push   $0x0
  pushl $68
8010555e:	6a 44                	push   $0x44
  jmp alltraps
80105560:	e9 68 f9 ff ff       	jmp    80104ecd <alltraps>

80105565 <vector69>:
.globl vector69
vector69:
  pushl $0
80105565:	6a 00                	push   $0x0
  pushl $69
80105567:	6a 45                	push   $0x45
  jmp alltraps
80105569:	e9 5f f9 ff ff       	jmp    80104ecd <alltraps>

8010556e <vector70>:
.globl vector70
vector70:
  pushl $0
8010556e:	6a 00                	push   $0x0
  pushl $70
80105570:	6a 46                	push   $0x46
  jmp alltraps
80105572:	e9 56 f9 ff ff       	jmp    80104ecd <alltraps>

80105577 <vector71>:
.globl vector71
vector71:
  pushl $0
80105577:	6a 00                	push   $0x0
  pushl $71
80105579:	6a 47                	push   $0x47
  jmp alltraps
8010557b:	e9 4d f9 ff ff       	jmp    80104ecd <alltraps>

80105580 <vector72>:
.globl vector72
vector72:
  pushl $0
80105580:	6a 00                	push   $0x0
  pushl $72
80105582:	6a 48                	push   $0x48
  jmp alltraps
80105584:	e9 44 f9 ff ff       	jmp    80104ecd <alltraps>

80105589 <vector73>:
.globl vector73
vector73:
  pushl $0
80105589:	6a 00                	push   $0x0
  pushl $73
8010558b:	6a 49                	push   $0x49
  jmp alltraps
8010558d:	e9 3b f9 ff ff       	jmp    80104ecd <alltraps>

80105592 <vector74>:
.globl vector74
vector74:
  pushl $0
80105592:	6a 00                	push   $0x0
  pushl $74
80105594:	6a 4a                	push   $0x4a
  jmp alltraps
80105596:	e9 32 f9 ff ff       	jmp    80104ecd <alltraps>

8010559b <vector75>:
.globl vector75
vector75:
  pushl $0
8010559b:	6a 00                	push   $0x0
  pushl $75
8010559d:	6a 4b                	push   $0x4b
  jmp alltraps
8010559f:	e9 29 f9 ff ff       	jmp    80104ecd <alltraps>

801055a4 <vector76>:
.globl vector76
vector76:
  pushl $0
801055a4:	6a 00                	push   $0x0
  pushl $76
801055a6:	6a 4c                	push   $0x4c
  jmp alltraps
801055a8:	e9 20 f9 ff ff       	jmp    80104ecd <alltraps>

801055ad <vector77>:
.globl vector77
vector77:
  pushl $0
801055ad:	6a 00                	push   $0x0
  pushl $77
801055af:	6a 4d                	push   $0x4d
  jmp alltraps
801055b1:	e9 17 f9 ff ff       	jmp    80104ecd <alltraps>

801055b6 <vector78>:
.globl vector78
vector78:
  pushl $0
801055b6:	6a 00                	push   $0x0
  pushl $78
801055b8:	6a 4e                	push   $0x4e
  jmp alltraps
801055ba:	e9 0e f9 ff ff       	jmp    80104ecd <alltraps>

801055bf <vector79>:
.globl vector79
vector79:
  pushl $0
801055bf:	6a 00                	push   $0x0
  pushl $79
801055c1:	6a 4f                	push   $0x4f
  jmp alltraps
801055c3:	e9 05 f9 ff ff       	jmp    80104ecd <alltraps>

801055c8 <vector80>:
.globl vector80
vector80:
  pushl $0
801055c8:	6a 00                	push   $0x0
  pushl $80
801055ca:	6a 50                	push   $0x50
  jmp alltraps
801055cc:	e9 fc f8 ff ff       	jmp    80104ecd <alltraps>

801055d1 <vector81>:
.globl vector81
vector81:
  pushl $0
801055d1:	6a 00                	push   $0x0
  pushl $81
801055d3:	6a 51                	push   $0x51
  jmp alltraps
801055d5:	e9 f3 f8 ff ff       	jmp    80104ecd <alltraps>

801055da <vector82>:
.globl vector82
vector82:
  pushl $0
801055da:	6a 00                	push   $0x0
  pushl $82
801055dc:	6a 52                	push   $0x52
  jmp alltraps
801055de:	e9 ea f8 ff ff       	jmp    80104ecd <alltraps>

801055e3 <vector83>:
.globl vector83
vector83:
  pushl $0
801055e3:	6a 00                	push   $0x0
  pushl $83
801055e5:	6a 53                	push   $0x53
  jmp alltraps
801055e7:	e9 e1 f8 ff ff       	jmp    80104ecd <alltraps>

801055ec <vector84>:
.globl vector84
vector84:
  pushl $0
801055ec:	6a 00                	push   $0x0
  pushl $84
801055ee:	6a 54                	push   $0x54
  jmp alltraps
801055f0:	e9 d8 f8 ff ff       	jmp    80104ecd <alltraps>

801055f5 <vector85>:
.globl vector85
vector85:
  pushl $0
801055f5:	6a 00                	push   $0x0
  pushl $85
801055f7:	6a 55                	push   $0x55
  jmp alltraps
801055f9:	e9 cf f8 ff ff       	jmp    80104ecd <alltraps>

801055fe <vector86>:
.globl vector86
vector86:
  pushl $0
801055fe:	6a 00                	push   $0x0
  pushl $86
80105600:	6a 56                	push   $0x56
  jmp alltraps
80105602:	e9 c6 f8 ff ff       	jmp    80104ecd <alltraps>

80105607 <vector87>:
.globl vector87
vector87:
  pushl $0
80105607:	6a 00                	push   $0x0
  pushl $87
80105609:	6a 57                	push   $0x57
  jmp alltraps
8010560b:	e9 bd f8 ff ff       	jmp    80104ecd <alltraps>

80105610 <vector88>:
.globl vector88
vector88:
  pushl $0
80105610:	6a 00                	push   $0x0
  pushl $88
80105612:	6a 58                	push   $0x58
  jmp alltraps
80105614:	e9 b4 f8 ff ff       	jmp    80104ecd <alltraps>

80105619 <vector89>:
.globl vector89
vector89:
  pushl $0
80105619:	6a 00                	push   $0x0
  pushl $89
8010561b:	6a 59                	push   $0x59
  jmp alltraps
8010561d:	e9 ab f8 ff ff       	jmp    80104ecd <alltraps>

80105622 <vector90>:
.globl vector90
vector90:
  pushl $0
80105622:	6a 00                	push   $0x0
  pushl $90
80105624:	6a 5a                	push   $0x5a
  jmp alltraps
80105626:	e9 a2 f8 ff ff       	jmp    80104ecd <alltraps>

8010562b <vector91>:
.globl vector91
vector91:
  pushl $0
8010562b:	6a 00                	push   $0x0
  pushl $91
8010562d:	6a 5b                	push   $0x5b
  jmp alltraps
8010562f:	e9 99 f8 ff ff       	jmp    80104ecd <alltraps>

80105634 <vector92>:
.globl vector92
vector92:
  pushl $0
80105634:	6a 00                	push   $0x0
  pushl $92
80105636:	6a 5c                	push   $0x5c
  jmp alltraps
80105638:	e9 90 f8 ff ff       	jmp    80104ecd <alltraps>

8010563d <vector93>:
.globl vector93
vector93:
  pushl $0
8010563d:	6a 00                	push   $0x0
  pushl $93
8010563f:	6a 5d                	push   $0x5d
  jmp alltraps
80105641:	e9 87 f8 ff ff       	jmp    80104ecd <alltraps>

80105646 <vector94>:
.globl vector94
vector94:
  pushl $0
80105646:	6a 00                	push   $0x0
  pushl $94
80105648:	6a 5e                	push   $0x5e
  jmp alltraps
8010564a:	e9 7e f8 ff ff       	jmp    80104ecd <alltraps>

8010564f <vector95>:
.globl vector95
vector95:
  pushl $0
8010564f:	6a 00                	push   $0x0
  pushl $95
80105651:	6a 5f                	push   $0x5f
  jmp alltraps
80105653:	e9 75 f8 ff ff       	jmp    80104ecd <alltraps>

80105658 <vector96>:
.globl vector96
vector96:
  pushl $0
80105658:	6a 00                	push   $0x0
  pushl $96
8010565a:	6a 60                	push   $0x60
  jmp alltraps
8010565c:	e9 6c f8 ff ff       	jmp    80104ecd <alltraps>

80105661 <vector97>:
.globl vector97
vector97:
  pushl $0
80105661:	6a 00                	push   $0x0
  pushl $97
80105663:	6a 61                	push   $0x61
  jmp alltraps
80105665:	e9 63 f8 ff ff       	jmp    80104ecd <alltraps>

8010566a <vector98>:
.globl vector98
vector98:
  pushl $0
8010566a:	6a 00                	push   $0x0
  pushl $98
8010566c:	6a 62                	push   $0x62
  jmp alltraps
8010566e:	e9 5a f8 ff ff       	jmp    80104ecd <alltraps>

80105673 <vector99>:
.globl vector99
vector99:
  pushl $0
80105673:	6a 00                	push   $0x0
  pushl $99
80105675:	6a 63                	push   $0x63
  jmp alltraps
80105677:	e9 51 f8 ff ff       	jmp    80104ecd <alltraps>

8010567c <vector100>:
.globl vector100
vector100:
  pushl $0
8010567c:	6a 00                	push   $0x0
  pushl $100
8010567e:	6a 64                	push   $0x64
  jmp alltraps
80105680:	e9 48 f8 ff ff       	jmp    80104ecd <alltraps>

80105685 <vector101>:
.globl vector101
vector101:
  pushl $0
80105685:	6a 00                	push   $0x0
  pushl $101
80105687:	6a 65                	push   $0x65
  jmp alltraps
80105689:	e9 3f f8 ff ff       	jmp    80104ecd <alltraps>

8010568e <vector102>:
.globl vector102
vector102:
  pushl $0
8010568e:	6a 00                	push   $0x0
  pushl $102
80105690:	6a 66                	push   $0x66
  jmp alltraps
80105692:	e9 36 f8 ff ff       	jmp    80104ecd <alltraps>

80105697 <vector103>:
.globl vector103
vector103:
  pushl $0
80105697:	6a 00                	push   $0x0
  pushl $103
80105699:	6a 67                	push   $0x67
  jmp alltraps
8010569b:	e9 2d f8 ff ff       	jmp    80104ecd <alltraps>

801056a0 <vector104>:
.globl vector104
vector104:
  pushl $0
801056a0:	6a 00                	push   $0x0
  pushl $104
801056a2:	6a 68                	push   $0x68
  jmp alltraps
801056a4:	e9 24 f8 ff ff       	jmp    80104ecd <alltraps>

801056a9 <vector105>:
.globl vector105
vector105:
  pushl $0
801056a9:	6a 00                	push   $0x0
  pushl $105
801056ab:	6a 69                	push   $0x69
  jmp alltraps
801056ad:	e9 1b f8 ff ff       	jmp    80104ecd <alltraps>

801056b2 <vector106>:
.globl vector106
vector106:
  pushl $0
801056b2:	6a 00                	push   $0x0
  pushl $106
801056b4:	6a 6a                	push   $0x6a
  jmp alltraps
801056b6:	e9 12 f8 ff ff       	jmp    80104ecd <alltraps>

801056bb <vector107>:
.globl vector107
vector107:
  pushl $0
801056bb:	6a 00                	push   $0x0
  pushl $107
801056bd:	6a 6b                	push   $0x6b
  jmp alltraps
801056bf:	e9 09 f8 ff ff       	jmp    80104ecd <alltraps>

801056c4 <vector108>:
.globl vector108
vector108:
  pushl $0
801056c4:	6a 00                	push   $0x0
  pushl $108
801056c6:	6a 6c                	push   $0x6c
  jmp alltraps
801056c8:	e9 00 f8 ff ff       	jmp    80104ecd <alltraps>

801056cd <vector109>:
.globl vector109
vector109:
  pushl $0
801056cd:	6a 00                	push   $0x0
  pushl $109
801056cf:	6a 6d                	push   $0x6d
  jmp alltraps
801056d1:	e9 f7 f7 ff ff       	jmp    80104ecd <alltraps>

801056d6 <vector110>:
.globl vector110
vector110:
  pushl $0
801056d6:	6a 00                	push   $0x0
  pushl $110
801056d8:	6a 6e                	push   $0x6e
  jmp alltraps
801056da:	e9 ee f7 ff ff       	jmp    80104ecd <alltraps>

801056df <vector111>:
.globl vector111
vector111:
  pushl $0
801056df:	6a 00                	push   $0x0
  pushl $111
801056e1:	6a 6f                	push   $0x6f
  jmp alltraps
801056e3:	e9 e5 f7 ff ff       	jmp    80104ecd <alltraps>

801056e8 <vector112>:
.globl vector112
vector112:
  pushl $0
801056e8:	6a 00                	push   $0x0
  pushl $112
801056ea:	6a 70                	push   $0x70
  jmp alltraps
801056ec:	e9 dc f7 ff ff       	jmp    80104ecd <alltraps>

801056f1 <vector113>:
.globl vector113
vector113:
  pushl $0
801056f1:	6a 00                	push   $0x0
  pushl $113
801056f3:	6a 71                	push   $0x71
  jmp alltraps
801056f5:	e9 d3 f7 ff ff       	jmp    80104ecd <alltraps>

801056fa <vector114>:
.globl vector114
vector114:
  pushl $0
801056fa:	6a 00                	push   $0x0
  pushl $114
801056fc:	6a 72                	push   $0x72
  jmp alltraps
801056fe:	e9 ca f7 ff ff       	jmp    80104ecd <alltraps>

80105703 <vector115>:
.globl vector115
vector115:
  pushl $0
80105703:	6a 00                	push   $0x0
  pushl $115
80105705:	6a 73                	push   $0x73
  jmp alltraps
80105707:	e9 c1 f7 ff ff       	jmp    80104ecd <alltraps>

8010570c <vector116>:
.globl vector116
vector116:
  pushl $0
8010570c:	6a 00                	push   $0x0
  pushl $116
8010570e:	6a 74                	push   $0x74
  jmp alltraps
80105710:	e9 b8 f7 ff ff       	jmp    80104ecd <alltraps>

80105715 <vector117>:
.globl vector117
vector117:
  pushl $0
80105715:	6a 00                	push   $0x0
  pushl $117
80105717:	6a 75                	push   $0x75
  jmp alltraps
80105719:	e9 af f7 ff ff       	jmp    80104ecd <alltraps>

8010571e <vector118>:
.globl vector118
vector118:
  pushl $0
8010571e:	6a 00                	push   $0x0
  pushl $118
80105720:	6a 76                	push   $0x76
  jmp alltraps
80105722:	e9 a6 f7 ff ff       	jmp    80104ecd <alltraps>

80105727 <vector119>:
.globl vector119
vector119:
  pushl $0
80105727:	6a 00                	push   $0x0
  pushl $119
80105729:	6a 77                	push   $0x77
  jmp alltraps
8010572b:	e9 9d f7 ff ff       	jmp    80104ecd <alltraps>

80105730 <vector120>:
.globl vector120
vector120:
  pushl $0
80105730:	6a 00                	push   $0x0
  pushl $120
80105732:	6a 78                	push   $0x78
  jmp alltraps
80105734:	e9 94 f7 ff ff       	jmp    80104ecd <alltraps>

80105739 <vector121>:
.globl vector121
vector121:
  pushl $0
80105739:	6a 00                	push   $0x0
  pushl $121
8010573b:	6a 79                	push   $0x79
  jmp alltraps
8010573d:	e9 8b f7 ff ff       	jmp    80104ecd <alltraps>

80105742 <vector122>:
.globl vector122
vector122:
  pushl $0
80105742:	6a 00                	push   $0x0
  pushl $122
80105744:	6a 7a                	push   $0x7a
  jmp alltraps
80105746:	e9 82 f7 ff ff       	jmp    80104ecd <alltraps>

8010574b <vector123>:
.globl vector123
vector123:
  pushl $0
8010574b:	6a 00                	push   $0x0
  pushl $123
8010574d:	6a 7b                	push   $0x7b
  jmp alltraps
8010574f:	e9 79 f7 ff ff       	jmp    80104ecd <alltraps>

80105754 <vector124>:
.globl vector124
vector124:
  pushl $0
80105754:	6a 00                	push   $0x0
  pushl $124
80105756:	6a 7c                	push   $0x7c
  jmp alltraps
80105758:	e9 70 f7 ff ff       	jmp    80104ecd <alltraps>

8010575d <vector125>:
.globl vector125
vector125:
  pushl $0
8010575d:	6a 00                	push   $0x0
  pushl $125
8010575f:	6a 7d                	push   $0x7d
  jmp alltraps
80105761:	e9 67 f7 ff ff       	jmp    80104ecd <alltraps>

80105766 <vector126>:
.globl vector126
vector126:
  pushl $0
80105766:	6a 00                	push   $0x0
  pushl $126
80105768:	6a 7e                	push   $0x7e
  jmp alltraps
8010576a:	e9 5e f7 ff ff       	jmp    80104ecd <alltraps>

8010576f <vector127>:
.globl vector127
vector127:
  pushl $0
8010576f:	6a 00                	push   $0x0
  pushl $127
80105771:	6a 7f                	push   $0x7f
  jmp alltraps
80105773:	e9 55 f7 ff ff       	jmp    80104ecd <alltraps>

80105778 <vector128>:
.globl vector128
vector128:
  pushl $0
80105778:	6a 00                	push   $0x0
  pushl $128
8010577a:	68 80 00 00 00       	push   $0x80
  jmp alltraps
8010577f:	e9 49 f7 ff ff       	jmp    80104ecd <alltraps>

80105784 <vector129>:
.globl vector129
vector129:
  pushl $0
80105784:	6a 00                	push   $0x0
  pushl $129
80105786:	68 81 00 00 00       	push   $0x81
  jmp alltraps
8010578b:	e9 3d f7 ff ff       	jmp    80104ecd <alltraps>

80105790 <vector130>:
.globl vector130
vector130:
  pushl $0
80105790:	6a 00                	push   $0x0
  pushl $130
80105792:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80105797:	e9 31 f7 ff ff       	jmp    80104ecd <alltraps>

8010579c <vector131>:
.globl vector131
vector131:
  pushl $0
8010579c:	6a 00                	push   $0x0
  pushl $131
8010579e:	68 83 00 00 00       	push   $0x83
  jmp alltraps
801057a3:	e9 25 f7 ff ff       	jmp    80104ecd <alltraps>

801057a8 <vector132>:
.globl vector132
vector132:
  pushl $0
801057a8:	6a 00                	push   $0x0
  pushl $132
801057aa:	68 84 00 00 00       	push   $0x84
  jmp alltraps
801057af:	e9 19 f7 ff ff       	jmp    80104ecd <alltraps>

801057b4 <vector133>:
.globl vector133
vector133:
  pushl $0
801057b4:	6a 00                	push   $0x0
  pushl $133
801057b6:	68 85 00 00 00       	push   $0x85
  jmp alltraps
801057bb:	e9 0d f7 ff ff       	jmp    80104ecd <alltraps>

801057c0 <vector134>:
.globl vector134
vector134:
  pushl $0
801057c0:	6a 00                	push   $0x0
  pushl $134
801057c2:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801057c7:	e9 01 f7 ff ff       	jmp    80104ecd <alltraps>

801057cc <vector135>:
.globl vector135
vector135:
  pushl $0
801057cc:	6a 00                	push   $0x0
  pushl $135
801057ce:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801057d3:	e9 f5 f6 ff ff       	jmp    80104ecd <alltraps>

801057d8 <vector136>:
.globl vector136
vector136:
  pushl $0
801057d8:	6a 00                	push   $0x0
  pushl $136
801057da:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801057df:	e9 e9 f6 ff ff       	jmp    80104ecd <alltraps>

801057e4 <vector137>:
.globl vector137
vector137:
  pushl $0
801057e4:	6a 00                	push   $0x0
  pushl $137
801057e6:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801057eb:	e9 dd f6 ff ff       	jmp    80104ecd <alltraps>

801057f0 <vector138>:
.globl vector138
vector138:
  pushl $0
801057f0:	6a 00                	push   $0x0
  pushl $138
801057f2:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801057f7:	e9 d1 f6 ff ff       	jmp    80104ecd <alltraps>

801057fc <vector139>:
.globl vector139
vector139:
  pushl $0
801057fc:	6a 00                	push   $0x0
  pushl $139
801057fe:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80105803:	e9 c5 f6 ff ff       	jmp    80104ecd <alltraps>

80105808 <vector140>:
.globl vector140
vector140:
  pushl $0
80105808:	6a 00                	push   $0x0
  pushl $140
8010580a:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
8010580f:	e9 b9 f6 ff ff       	jmp    80104ecd <alltraps>

80105814 <vector141>:
.globl vector141
vector141:
  pushl $0
80105814:	6a 00                	push   $0x0
  pushl $141
80105816:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
8010581b:	e9 ad f6 ff ff       	jmp    80104ecd <alltraps>

80105820 <vector142>:
.globl vector142
vector142:
  pushl $0
80105820:	6a 00                	push   $0x0
  pushl $142
80105822:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80105827:	e9 a1 f6 ff ff       	jmp    80104ecd <alltraps>

8010582c <vector143>:
.globl vector143
vector143:
  pushl $0
8010582c:	6a 00                	push   $0x0
  pushl $143
8010582e:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80105833:	e9 95 f6 ff ff       	jmp    80104ecd <alltraps>

80105838 <vector144>:
.globl vector144
vector144:
  pushl $0
80105838:	6a 00                	push   $0x0
  pushl $144
8010583a:	68 90 00 00 00       	push   $0x90
  jmp alltraps
8010583f:	e9 89 f6 ff ff       	jmp    80104ecd <alltraps>

80105844 <vector145>:
.globl vector145
vector145:
  pushl $0
80105844:	6a 00                	push   $0x0
  pushl $145
80105846:	68 91 00 00 00       	push   $0x91
  jmp alltraps
8010584b:	e9 7d f6 ff ff       	jmp    80104ecd <alltraps>

80105850 <vector146>:
.globl vector146
vector146:
  pushl $0
80105850:	6a 00                	push   $0x0
  pushl $146
80105852:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80105857:	e9 71 f6 ff ff       	jmp    80104ecd <alltraps>

8010585c <vector147>:
.globl vector147
vector147:
  pushl $0
8010585c:	6a 00                	push   $0x0
  pushl $147
8010585e:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80105863:	e9 65 f6 ff ff       	jmp    80104ecd <alltraps>

80105868 <vector148>:
.globl vector148
vector148:
  pushl $0
80105868:	6a 00                	push   $0x0
  pushl $148
8010586a:	68 94 00 00 00       	push   $0x94
  jmp alltraps
8010586f:	e9 59 f6 ff ff       	jmp    80104ecd <alltraps>

80105874 <vector149>:
.globl vector149
vector149:
  pushl $0
80105874:	6a 00                	push   $0x0
  pushl $149
80105876:	68 95 00 00 00       	push   $0x95
  jmp alltraps
8010587b:	e9 4d f6 ff ff       	jmp    80104ecd <alltraps>

80105880 <vector150>:
.globl vector150
vector150:
  pushl $0
80105880:	6a 00                	push   $0x0
  pushl $150
80105882:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80105887:	e9 41 f6 ff ff       	jmp    80104ecd <alltraps>

8010588c <vector151>:
.globl vector151
vector151:
  pushl $0
8010588c:	6a 00                	push   $0x0
  pushl $151
8010588e:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80105893:	e9 35 f6 ff ff       	jmp    80104ecd <alltraps>

80105898 <vector152>:
.globl vector152
vector152:
  pushl $0
80105898:	6a 00                	push   $0x0
  pushl $152
8010589a:	68 98 00 00 00       	push   $0x98
  jmp alltraps
8010589f:	e9 29 f6 ff ff       	jmp    80104ecd <alltraps>

801058a4 <vector153>:
.globl vector153
vector153:
  pushl $0
801058a4:	6a 00                	push   $0x0
  pushl $153
801058a6:	68 99 00 00 00       	push   $0x99
  jmp alltraps
801058ab:	e9 1d f6 ff ff       	jmp    80104ecd <alltraps>

801058b0 <vector154>:
.globl vector154
vector154:
  pushl $0
801058b0:	6a 00                	push   $0x0
  pushl $154
801058b2:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
801058b7:	e9 11 f6 ff ff       	jmp    80104ecd <alltraps>

801058bc <vector155>:
.globl vector155
vector155:
  pushl $0
801058bc:	6a 00                	push   $0x0
  pushl $155
801058be:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
801058c3:	e9 05 f6 ff ff       	jmp    80104ecd <alltraps>

801058c8 <vector156>:
.globl vector156
vector156:
  pushl $0
801058c8:	6a 00                	push   $0x0
  pushl $156
801058ca:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
801058cf:	e9 f9 f5 ff ff       	jmp    80104ecd <alltraps>

801058d4 <vector157>:
.globl vector157
vector157:
  pushl $0
801058d4:	6a 00                	push   $0x0
  pushl $157
801058d6:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
801058db:	e9 ed f5 ff ff       	jmp    80104ecd <alltraps>

801058e0 <vector158>:
.globl vector158
vector158:
  pushl $0
801058e0:	6a 00                	push   $0x0
  pushl $158
801058e2:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
801058e7:	e9 e1 f5 ff ff       	jmp    80104ecd <alltraps>

801058ec <vector159>:
.globl vector159
vector159:
  pushl $0
801058ec:	6a 00                	push   $0x0
  pushl $159
801058ee:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
801058f3:	e9 d5 f5 ff ff       	jmp    80104ecd <alltraps>

801058f8 <vector160>:
.globl vector160
vector160:
  pushl $0
801058f8:	6a 00                	push   $0x0
  pushl $160
801058fa:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
801058ff:	e9 c9 f5 ff ff       	jmp    80104ecd <alltraps>

80105904 <vector161>:
.globl vector161
vector161:
  pushl $0
80105904:	6a 00                	push   $0x0
  pushl $161
80105906:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
8010590b:	e9 bd f5 ff ff       	jmp    80104ecd <alltraps>

80105910 <vector162>:
.globl vector162
vector162:
  pushl $0
80105910:	6a 00                	push   $0x0
  pushl $162
80105912:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80105917:	e9 b1 f5 ff ff       	jmp    80104ecd <alltraps>

8010591c <vector163>:
.globl vector163
vector163:
  pushl $0
8010591c:	6a 00                	push   $0x0
  pushl $163
8010591e:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80105923:	e9 a5 f5 ff ff       	jmp    80104ecd <alltraps>

80105928 <vector164>:
.globl vector164
vector164:
  pushl $0
80105928:	6a 00                	push   $0x0
  pushl $164
8010592a:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
8010592f:	e9 99 f5 ff ff       	jmp    80104ecd <alltraps>

80105934 <vector165>:
.globl vector165
vector165:
  pushl $0
80105934:	6a 00                	push   $0x0
  pushl $165
80105936:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
8010593b:	e9 8d f5 ff ff       	jmp    80104ecd <alltraps>

80105940 <vector166>:
.globl vector166
vector166:
  pushl $0
80105940:	6a 00                	push   $0x0
  pushl $166
80105942:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80105947:	e9 81 f5 ff ff       	jmp    80104ecd <alltraps>

8010594c <vector167>:
.globl vector167
vector167:
  pushl $0
8010594c:	6a 00                	push   $0x0
  pushl $167
8010594e:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80105953:	e9 75 f5 ff ff       	jmp    80104ecd <alltraps>

80105958 <vector168>:
.globl vector168
vector168:
  pushl $0
80105958:	6a 00                	push   $0x0
  pushl $168
8010595a:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
8010595f:	e9 69 f5 ff ff       	jmp    80104ecd <alltraps>

80105964 <vector169>:
.globl vector169
vector169:
  pushl $0
80105964:	6a 00                	push   $0x0
  pushl $169
80105966:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
8010596b:	e9 5d f5 ff ff       	jmp    80104ecd <alltraps>

80105970 <vector170>:
.globl vector170
vector170:
  pushl $0
80105970:	6a 00                	push   $0x0
  pushl $170
80105972:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80105977:	e9 51 f5 ff ff       	jmp    80104ecd <alltraps>

8010597c <vector171>:
.globl vector171
vector171:
  pushl $0
8010597c:	6a 00                	push   $0x0
  pushl $171
8010597e:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80105983:	e9 45 f5 ff ff       	jmp    80104ecd <alltraps>

80105988 <vector172>:
.globl vector172
vector172:
  pushl $0
80105988:	6a 00                	push   $0x0
  pushl $172
8010598a:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
8010598f:	e9 39 f5 ff ff       	jmp    80104ecd <alltraps>

80105994 <vector173>:
.globl vector173
vector173:
  pushl $0
80105994:	6a 00                	push   $0x0
  pushl $173
80105996:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
8010599b:	e9 2d f5 ff ff       	jmp    80104ecd <alltraps>

801059a0 <vector174>:
.globl vector174
vector174:
  pushl $0
801059a0:	6a 00                	push   $0x0
  pushl $174
801059a2:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
801059a7:	e9 21 f5 ff ff       	jmp    80104ecd <alltraps>

801059ac <vector175>:
.globl vector175
vector175:
  pushl $0
801059ac:	6a 00                	push   $0x0
  pushl $175
801059ae:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
801059b3:	e9 15 f5 ff ff       	jmp    80104ecd <alltraps>

801059b8 <vector176>:
.globl vector176
vector176:
  pushl $0
801059b8:	6a 00                	push   $0x0
  pushl $176
801059ba:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
801059bf:	e9 09 f5 ff ff       	jmp    80104ecd <alltraps>

801059c4 <vector177>:
.globl vector177
vector177:
  pushl $0
801059c4:	6a 00                	push   $0x0
  pushl $177
801059c6:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
801059cb:	e9 fd f4 ff ff       	jmp    80104ecd <alltraps>

801059d0 <vector178>:
.globl vector178
vector178:
  pushl $0
801059d0:	6a 00                	push   $0x0
  pushl $178
801059d2:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
801059d7:	e9 f1 f4 ff ff       	jmp    80104ecd <alltraps>

801059dc <vector179>:
.globl vector179
vector179:
  pushl $0
801059dc:	6a 00                	push   $0x0
  pushl $179
801059de:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
801059e3:	e9 e5 f4 ff ff       	jmp    80104ecd <alltraps>

801059e8 <vector180>:
.globl vector180
vector180:
  pushl $0
801059e8:	6a 00                	push   $0x0
  pushl $180
801059ea:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
801059ef:	e9 d9 f4 ff ff       	jmp    80104ecd <alltraps>

801059f4 <vector181>:
.globl vector181
vector181:
  pushl $0
801059f4:	6a 00                	push   $0x0
  pushl $181
801059f6:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
801059fb:	e9 cd f4 ff ff       	jmp    80104ecd <alltraps>

80105a00 <vector182>:
.globl vector182
vector182:
  pushl $0
80105a00:	6a 00                	push   $0x0
  pushl $182
80105a02:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105a07:	e9 c1 f4 ff ff       	jmp    80104ecd <alltraps>

80105a0c <vector183>:
.globl vector183
vector183:
  pushl $0
80105a0c:	6a 00                	push   $0x0
  pushl $183
80105a0e:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105a13:	e9 b5 f4 ff ff       	jmp    80104ecd <alltraps>

80105a18 <vector184>:
.globl vector184
vector184:
  pushl $0
80105a18:	6a 00                	push   $0x0
  pushl $184
80105a1a:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80105a1f:	e9 a9 f4 ff ff       	jmp    80104ecd <alltraps>

80105a24 <vector185>:
.globl vector185
vector185:
  pushl $0
80105a24:	6a 00                	push   $0x0
  pushl $185
80105a26:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105a2b:	e9 9d f4 ff ff       	jmp    80104ecd <alltraps>

80105a30 <vector186>:
.globl vector186
vector186:
  pushl $0
80105a30:	6a 00                	push   $0x0
  pushl $186
80105a32:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105a37:	e9 91 f4 ff ff       	jmp    80104ecd <alltraps>

80105a3c <vector187>:
.globl vector187
vector187:
  pushl $0
80105a3c:	6a 00                	push   $0x0
  pushl $187
80105a3e:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105a43:	e9 85 f4 ff ff       	jmp    80104ecd <alltraps>

80105a48 <vector188>:
.globl vector188
vector188:
  pushl $0
80105a48:	6a 00                	push   $0x0
  pushl $188
80105a4a:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105a4f:	e9 79 f4 ff ff       	jmp    80104ecd <alltraps>

80105a54 <vector189>:
.globl vector189
vector189:
  pushl $0
80105a54:	6a 00                	push   $0x0
  pushl $189
80105a56:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105a5b:	e9 6d f4 ff ff       	jmp    80104ecd <alltraps>

80105a60 <vector190>:
.globl vector190
vector190:
  pushl $0
80105a60:	6a 00                	push   $0x0
  pushl $190
80105a62:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105a67:	e9 61 f4 ff ff       	jmp    80104ecd <alltraps>

80105a6c <vector191>:
.globl vector191
vector191:
  pushl $0
80105a6c:	6a 00                	push   $0x0
  pushl $191
80105a6e:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105a73:	e9 55 f4 ff ff       	jmp    80104ecd <alltraps>

80105a78 <vector192>:
.globl vector192
vector192:
  pushl $0
80105a78:	6a 00                	push   $0x0
  pushl $192
80105a7a:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105a7f:	e9 49 f4 ff ff       	jmp    80104ecd <alltraps>

80105a84 <vector193>:
.globl vector193
vector193:
  pushl $0
80105a84:	6a 00                	push   $0x0
  pushl $193
80105a86:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105a8b:	e9 3d f4 ff ff       	jmp    80104ecd <alltraps>

80105a90 <vector194>:
.globl vector194
vector194:
  pushl $0
80105a90:	6a 00                	push   $0x0
  pushl $194
80105a92:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105a97:	e9 31 f4 ff ff       	jmp    80104ecd <alltraps>

80105a9c <vector195>:
.globl vector195
vector195:
  pushl $0
80105a9c:	6a 00                	push   $0x0
  pushl $195
80105a9e:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105aa3:	e9 25 f4 ff ff       	jmp    80104ecd <alltraps>

80105aa8 <vector196>:
.globl vector196
vector196:
  pushl $0
80105aa8:	6a 00                	push   $0x0
  pushl $196
80105aaa:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105aaf:	e9 19 f4 ff ff       	jmp    80104ecd <alltraps>

80105ab4 <vector197>:
.globl vector197
vector197:
  pushl $0
80105ab4:	6a 00                	push   $0x0
  pushl $197
80105ab6:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105abb:	e9 0d f4 ff ff       	jmp    80104ecd <alltraps>

80105ac0 <vector198>:
.globl vector198
vector198:
  pushl $0
80105ac0:	6a 00                	push   $0x0
  pushl $198
80105ac2:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105ac7:	e9 01 f4 ff ff       	jmp    80104ecd <alltraps>

80105acc <vector199>:
.globl vector199
vector199:
  pushl $0
80105acc:	6a 00                	push   $0x0
  pushl $199
80105ace:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105ad3:	e9 f5 f3 ff ff       	jmp    80104ecd <alltraps>

80105ad8 <vector200>:
.globl vector200
vector200:
  pushl $0
80105ad8:	6a 00                	push   $0x0
  pushl $200
80105ada:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105adf:	e9 e9 f3 ff ff       	jmp    80104ecd <alltraps>

80105ae4 <vector201>:
.globl vector201
vector201:
  pushl $0
80105ae4:	6a 00                	push   $0x0
  pushl $201
80105ae6:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105aeb:	e9 dd f3 ff ff       	jmp    80104ecd <alltraps>

80105af0 <vector202>:
.globl vector202
vector202:
  pushl $0
80105af0:	6a 00                	push   $0x0
  pushl $202
80105af2:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105af7:	e9 d1 f3 ff ff       	jmp    80104ecd <alltraps>

80105afc <vector203>:
.globl vector203
vector203:
  pushl $0
80105afc:	6a 00                	push   $0x0
  pushl $203
80105afe:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105b03:	e9 c5 f3 ff ff       	jmp    80104ecd <alltraps>

80105b08 <vector204>:
.globl vector204
vector204:
  pushl $0
80105b08:	6a 00                	push   $0x0
  pushl $204
80105b0a:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105b0f:	e9 b9 f3 ff ff       	jmp    80104ecd <alltraps>

80105b14 <vector205>:
.globl vector205
vector205:
  pushl $0
80105b14:	6a 00                	push   $0x0
  pushl $205
80105b16:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105b1b:	e9 ad f3 ff ff       	jmp    80104ecd <alltraps>

80105b20 <vector206>:
.globl vector206
vector206:
  pushl $0
80105b20:	6a 00                	push   $0x0
  pushl $206
80105b22:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105b27:	e9 a1 f3 ff ff       	jmp    80104ecd <alltraps>

80105b2c <vector207>:
.globl vector207
vector207:
  pushl $0
80105b2c:	6a 00                	push   $0x0
  pushl $207
80105b2e:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105b33:	e9 95 f3 ff ff       	jmp    80104ecd <alltraps>

80105b38 <vector208>:
.globl vector208
vector208:
  pushl $0
80105b38:	6a 00                	push   $0x0
  pushl $208
80105b3a:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105b3f:	e9 89 f3 ff ff       	jmp    80104ecd <alltraps>

80105b44 <vector209>:
.globl vector209
vector209:
  pushl $0
80105b44:	6a 00                	push   $0x0
  pushl $209
80105b46:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105b4b:	e9 7d f3 ff ff       	jmp    80104ecd <alltraps>

80105b50 <vector210>:
.globl vector210
vector210:
  pushl $0
80105b50:	6a 00                	push   $0x0
  pushl $210
80105b52:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105b57:	e9 71 f3 ff ff       	jmp    80104ecd <alltraps>

80105b5c <vector211>:
.globl vector211
vector211:
  pushl $0
80105b5c:	6a 00                	push   $0x0
  pushl $211
80105b5e:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105b63:	e9 65 f3 ff ff       	jmp    80104ecd <alltraps>

80105b68 <vector212>:
.globl vector212
vector212:
  pushl $0
80105b68:	6a 00                	push   $0x0
  pushl $212
80105b6a:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105b6f:	e9 59 f3 ff ff       	jmp    80104ecd <alltraps>

80105b74 <vector213>:
.globl vector213
vector213:
  pushl $0
80105b74:	6a 00                	push   $0x0
  pushl $213
80105b76:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105b7b:	e9 4d f3 ff ff       	jmp    80104ecd <alltraps>

80105b80 <vector214>:
.globl vector214
vector214:
  pushl $0
80105b80:	6a 00                	push   $0x0
  pushl $214
80105b82:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105b87:	e9 41 f3 ff ff       	jmp    80104ecd <alltraps>

80105b8c <vector215>:
.globl vector215
vector215:
  pushl $0
80105b8c:	6a 00                	push   $0x0
  pushl $215
80105b8e:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105b93:	e9 35 f3 ff ff       	jmp    80104ecd <alltraps>

80105b98 <vector216>:
.globl vector216
vector216:
  pushl $0
80105b98:	6a 00                	push   $0x0
  pushl $216
80105b9a:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105b9f:	e9 29 f3 ff ff       	jmp    80104ecd <alltraps>

80105ba4 <vector217>:
.globl vector217
vector217:
  pushl $0
80105ba4:	6a 00                	push   $0x0
  pushl $217
80105ba6:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105bab:	e9 1d f3 ff ff       	jmp    80104ecd <alltraps>

80105bb0 <vector218>:
.globl vector218
vector218:
  pushl $0
80105bb0:	6a 00                	push   $0x0
  pushl $218
80105bb2:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105bb7:	e9 11 f3 ff ff       	jmp    80104ecd <alltraps>

80105bbc <vector219>:
.globl vector219
vector219:
  pushl $0
80105bbc:	6a 00                	push   $0x0
  pushl $219
80105bbe:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105bc3:	e9 05 f3 ff ff       	jmp    80104ecd <alltraps>

80105bc8 <vector220>:
.globl vector220
vector220:
  pushl $0
80105bc8:	6a 00                	push   $0x0
  pushl $220
80105bca:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105bcf:	e9 f9 f2 ff ff       	jmp    80104ecd <alltraps>

80105bd4 <vector221>:
.globl vector221
vector221:
  pushl $0
80105bd4:	6a 00                	push   $0x0
  pushl $221
80105bd6:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105bdb:	e9 ed f2 ff ff       	jmp    80104ecd <alltraps>

80105be0 <vector222>:
.globl vector222
vector222:
  pushl $0
80105be0:	6a 00                	push   $0x0
  pushl $222
80105be2:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105be7:	e9 e1 f2 ff ff       	jmp    80104ecd <alltraps>

80105bec <vector223>:
.globl vector223
vector223:
  pushl $0
80105bec:	6a 00                	push   $0x0
  pushl $223
80105bee:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105bf3:	e9 d5 f2 ff ff       	jmp    80104ecd <alltraps>

80105bf8 <vector224>:
.globl vector224
vector224:
  pushl $0
80105bf8:	6a 00                	push   $0x0
  pushl $224
80105bfa:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105bff:	e9 c9 f2 ff ff       	jmp    80104ecd <alltraps>

80105c04 <vector225>:
.globl vector225
vector225:
  pushl $0
80105c04:	6a 00                	push   $0x0
  pushl $225
80105c06:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105c0b:	e9 bd f2 ff ff       	jmp    80104ecd <alltraps>

80105c10 <vector226>:
.globl vector226
vector226:
  pushl $0
80105c10:	6a 00                	push   $0x0
  pushl $226
80105c12:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105c17:	e9 b1 f2 ff ff       	jmp    80104ecd <alltraps>

80105c1c <vector227>:
.globl vector227
vector227:
  pushl $0
80105c1c:	6a 00                	push   $0x0
  pushl $227
80105c1e:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105c23:	e9 a5 f2 ff ff       	jmp    80104ecd <alltraps>

80105c28 <vector228>:
.globl vector228
vector228:
  pushl $0
80105c28:	6a 00                	push   $0x0
  pushl $228
80105c2a:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105c2f:	e9 99 f2 ff ff       	jmp    80104ecd <alltraps>

80105c34 <vector229>:
.globl vector229
vector229:
  pushl $0
80105c34:	6a 00                	push   $0x0
  pushl $229
80105c36:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105c3b:	e9 8d f2 ff ff       	jmp    80104ecd <alltraps>

80105c40 <vector230>:
.globl vector230
vector230:
  pushl $0
80105c40:	6a 00                	push   $0x0
  pushl $230
80105c42:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105c47:	e9 81 f2 ff ff       	jmp    80104ecd <alltraps>

80105c4c <vector231>:
.globl vector231
vector231:
  pushl $0
80105c4c:	6a 00                	push   $0x0
  pushl $231
80105c4e:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105c53:	e9 75 f2 ff ff       	jmp    80104ecd <alltraps>

80105c58 <vector232>:
.globl vector232
vector232:
  pushl $0
80105c58:	6a 00                	push   $0x0
  pushl $232
80105c5a:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105c5f:	e9 69 f2 ff ff       	jmp    80104ecd <alltraps>

80105c64 <vector233>:
.globl vector233
vector233:
  pushl $0
80105c64:	6a 00                	push   $0x0
  pushl $233
80105c66:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105c6b:	e9 5d f2 ff ff       	jmp    80104ecd <alltraps>

80105c70 <vector234>:
.globl vector234
vector234:
  pushl $0
80105c70:	6a 00                	push   $0x0
  pushl $234
80105c72:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105c77:	e9 51 f2 ff ff       	jmp    80104ecd <alltraps>

80105c7c <vector235>:
.globl vector235
vector235:
  pushl $0
80105c7c:	6a 00                	push   $0x0
  pushl $235
80105c7e:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105c83:	e9 45 f2 ff ff       	jmp    80104ecd <alltraps>

80105c88 <vector236>:
.globl vector236
vector236:
  pushl $0
80105c88:	6a 00                	push   $0x0
  pushl $236
80105c8a:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105c8f:	e9 39 f2 ff ff       	jmp    80104ecd <alltraps>

80105c94 <vector237>:
.globl vector237
vector237:
  pushl $0
80105c94:	6a 00                	push   $0x0
  pushl $237
80105c96:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105c9b:	e9 2d f2 ff ff       	jmp    80104ecd <alltraps>

80105ca0 <vector238>:
.globl vector238
vector238:
  pushl $0
80105ca0:	6a 00                	push   $0x0
  pushl $238
80105ca2:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105ca7:	e9 21 f2 ff ff       	jmp    80104ecd <alltraps>

80105cac <vector239>:
.globl vector239
vector239:
  pushl $0
80105cac:	6a 00                	push   $0x0
  pushl $239
80105cae:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105cb3:	e9 15 f2 ff ff       	jmp    80104ecd <alltraps>

80105cb8 <vector240>:
.globl vector240
vector240:
  pushl $0
80105cb8:	6a 00                	push   $0x0
  pushl $240
80105cba:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105cbf:	e9 09 f2 ff ff       	jmp    80104ecd <alltraps>

80105cc4 <vector241>:
.globl vector241
vector241:
  pushl $0
80105cc4:	6a 00                	push   $0x0
  pushl $241
80105cc6:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105ccb:	e9 fd f1 ff ff       	jmp    80104ecd <alltraps>

80105cd0 <vector242>:
.globl vector242
vector242:
  pushl $0
80105cd0:	6a 00                	push   $0x0
  pushl $242
80105cd2:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105cd7:	e9 f1 f1 ff ff       	jmp    80104ecd <alltraps>

80105cdc <vector243>:
.globl vector243
vector243:
  pushl $0
80105cdc:	6a 00                	push   $0x0
  pushl $243
80105cde:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105ce3:	e9 e5 f1 ff ff       	jmp    80104ecd <alltraps>

80105ce8 <vector244>:
.globl vector244
vector244:
  pushl $0
80105ce8:	6a 00                	push   $0x0
  pushl $244
80105cea:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105cef:	e9 d9 f1 ff ff       	jmp    80104ecd <alltraps>

80105cf4 <vector245>:
.globl vector245
vector245:
  pushl $0
80105cf4:	6a 00                	push   $0x0
  pushl $245
80105cf6:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105cfb:	e9 cd f1 ff ff       	jmp    80104ecd <alltraps>

80105d00 <vector246>:
.globl vector246
vector246:
  pushl $0
80105d00:	6a 00                	push   $0x0
  pushl $246
80105d02:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105d07:	e9 c1 f1 ff ff       	jmp    80104ecd <alltraps>

80105d0c <vector247>:
.globl vector247
vector247:
  pushl $0
80105d0c:	6a 00                	push   $0x0
  pushl $247
80105d0e:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105d13:	e9 b5 f1 ff ff       	jmp    80104ecd <alltraps>

80105d18 <vector248>:
.globl vector248
vector248:
  pushl $0
80105d18:	6a 00                	push   $0x0
  pushl $248
80105d1a:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105d1f:	e9 a9 f1 ff ff       	jmp    80104ecd <alltraps>

80105d24 <vector249>:
.globl vector249
vector249:
  pushl $0
80105d24:	6a 00                	push   $0x0
  pushl $249
80105d26:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105d2b:	e9 9d f1 ff ff       	jmp    80104ecd <alltraps>

80105d30 <vector250>:
.globl vector250
vector250:
  pushl $0
80105d30:	6a 00                	push   $0x0
  pushl $250
80105d32:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105d37:	e9 91 f1 ff ff       	jmp    80104ecd <alltraps>

80105d3c <vector251>:
.globl vector251
vector251:
  pushl $0
80105d3c:	6a 00                	push   $0x0
  pushl $251
80105d3e:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105d43:	e9 85 f1 ff ff       	jmp    80104ecd <alltraps>

80105d48 <vector252>:
.globl vector252
vector252:
  pushl $0
80105d48:	6a 00                	push   $0x0
  pushl $252
80105d4a:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105d4f:	e9 79 f1 ff ff       	jmp    80104ecd <alltraps>

80105d54 <vector253>:
.globl vector253
vector253:
  pushl $0
80105d54:	6a 00                	push   $0x0
  pushl $253
80105d56:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105d5b:	e9 6d f1 ff ff       	jmp    80104ecd <alltraps>

80105d60 <vector254>:
.globl vector254
vector254:
  pushl $0
80105d60:	6a 00                	push   $0x0
  pushl $254
80105d62:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105d67:	e9 61 f1 ff ff       	jmp    80104ecd <alltraps>

80105d6c <vector255>:
.globl vector255
vector255:
  pushl $0
80105d6c:	6a 00                	push   $0x0
  pushl $255
80105d6e:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105d73:	e9 55 f1 ff ff       	jmp    80104ecd <alltraps>

80105d78 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105d78:	55                   	push   %ebp
80105d79:	89 e5                	mov    %esp,%ebp
80105d7b:	57                   	push   %edi
80105d7c:	56                   	push   %esi
80105d7d:	53                   	push   %ebx
80105d7e:	83 ec 0c             	sub    $0xc,%esp
80105d81:	89 d6                	mov    %edx,%esi
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~inside walkpgdir\n");
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105d83:	c1 ea 16             	shr    $0x16,%edx
80105d86:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105d89:	8b 1f                	mov    (%edi),%ebx
80105d8b:	f6 c3 01             	test   $0x1,%bl
80105d8e:	74 22                	je     80105db2 <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105d90:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80105d96:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105d9c:	c1 ee 0c             	shr    $0xc,%esi
80105d9f:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
80105da5:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80105da8:	89 d8                	mov    %ebx,%eax
80105daa:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105dad:	5b                   	pop    %ebx
80105dae:	5e                   	pop    %esi
80105daf:	5f                   	pop    %edi
80105db0:	5d                   	pop    %ebp
80105db1:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc2(-2)) == 0)
80105db2:	85 c9                	test   %ecx,%ecx
80105db4:	74 33                	je     80105de9 <walkpgdir+0x71>
80105db6:	83 ec 0c             	sub    $0xc,%esp
80105db9:	6a fe                	push   $0xfffffffe
80105dbb:	e8 7b c3 ff ff       	call   8010213b <kalloc2>
80105dc0:	89 c3                	mov    %eax,%ebx
80105dc2:	83 c4 10             	add    $0x10,%esp
80105dc5:	85 c0                	test   %eax,%eax
80105dc7:	74 df                	je     80105da8 <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80105dc9:	83 ec 04             	sub    $0x4,%esp
80105dcc:	68 00 10 00 00       	push   $0x1000
80105dd1:	6a 00                	push   $0x0
80105dd3:	50                   	push   %eax
80105dd4:	e8 f6 df ff ff       	call   80103dcf <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105dd9:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80105ddf:	83 c8 07             	or     $0x7,%eax
80105de2:	89 07                	mov    %eax,(%edi)
80105de4:	83 c4 10             	add    $0x10,%esp
80105de7:	eb b3                	jmp    80105d9c <walkpgdir+0x24>
      return 0;
80105de9:	bb 00 00 00 00       	mov    $0x0,%ebx
80105dee:	eb b8                	jmp    80105da8 <walkpgdir+0x30>

80105df0 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105df0:	55                   	push   %ebp
80105df1:	89 e5                	mov    %esp,%ebp
80105df3:	57                   	push   %edi
80105df4:	56                   	push   %esi
80105df5:	53                   	push   %ebx
80105df6:	83 ec 1c             	sub    $0x1c,%esp
80105df9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105dfc:	8b 75 08             	mov    0x8(%ebp),%esi
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~inside mappages\n");
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80105dff:	89 d3                	mov    %edx,%ebx
80105e01:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105e07:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105e0b:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105e11:	b9 01 00 00 00       	mov    $0x1,%ecx
80105e16:	89 da                	mov    %ebx,%edx
80105e18:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105e1b:	e8 58 ff ff ff       	call   80105d78 <walkpgdir>
80105e20:	85 c0                	test   %eax,%eax
80105e22:	74 2e                	je     80105e52 <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105e24:	f6 00 01             	testb  $0x1,(%eax)
80105e27:	75 1c                	jne    80105e45 <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105e29:	89 f2                	mov    %esi,%edx
80105e2b:	0b 55 0c             	or     0xc(%ebp),%edx
80105e2e:	83 ca 01             	or     $0x1,%edx
80105e31:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105e33:	39 fb                	cmp    %edi,%ebx
80105e35:	74 28                	je     80105e5f <mappages+0x6f>
      break;
    a += PGSIZE;
80105e37:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105e3d:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105e43:	eb cc                	jmp    80105e11 <mappages+0x21>
      panic("remap");
80105e45:	83 ec 0c             	sub    $0xc,%esp
80105e48:	68 2c 6f 10 80       	push   $0x80106f2c
80105e4d:	e8 f6 a4 ff ff       	call   80100348 <panic>
      return -1;
80105e52:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105e57:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105e5a:	5b                   	pop    %ebx
80105e5b:	5e                   	pop    %esi
80105e5c:	5f                   	pop    %edi
80105e5d:	5d                   	pop    %ebp
80105e5e:	c3                   	ret    
  return 0;
80105e5f:	b8 00 00 00 00       	mov    $0x0,%eax
80105e64:	eb f1                	jmp    80105e57 <mappages+0x67>

80105e66 <seginit>:
{
80105e66:	55                   	push   %ebp
80105e67:	89 e5                	mov    %esp,%ebp
80105e69:	53                   	push   %ebx
80105e6a:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80105e6d:	e8 35 d4 ff ff       	call   801032a7 <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80105e72:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80105e78:	66 c7 80 78 d1 16 80 	movw   $0xffff,-0x7fe92e88(%eax)
80105e7f:	ff ff 
80105e81:	66 c7 80 7a d1 16 80 	movw   $0x0,-0x7fe92e86(%eax)
80105e88:	00 00 
80105e8a:	c6 80 7c d1 16 80 00 	movb   $0x0,-0x7fe92e84(%eax)
80105e91:	0f b6 88 7d d1 16 80 	movzbl -0x7fe92e83(%eax),%ecx
80105e98:	83 e1 f0             	and    $0xfffffff0,%ecx
80105e9b:	83 c9 1a             	or     $0x1a,%ecx
80105e9e:	83 e1 9f             	and    $0xffffff9f,%ecx
80105ea1:	83 c9 80             	or     $0xffffff80,%ecx
80105ea4:	88 88 7d d1 16 80    	mov    %cl,-0x7fe92e83(%eax)
80105eaa:	0f b6 88 7e d1 16 80 	movzbl -0x7fe92e82(%eax),%ecx
80105eb1:	83 c9 0f             	or     $0xf,%ecx
80105eb4:	83 e1 cf             	and    $0xffffffcf,%ecx
80105eb7:	83 c9 c0             	or     $0xffffffc0,%ecx
80105eba:	88 88 7e d1 16 80    	mov    %cl,-0x7fe92e82(%eax)
80105ec0:	c6 80 7f d1 16 80 00 	movb   $0x0,-0x7fe92e81(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80105ec7:	66 c7 80 80 d1 16 80 	movw   $0xffff,-0x7fe92e80(%eax)
80105ece:	ff ff 
80105ed0:	66 c7 80 82 d1 16 80 	movw   $0x0,-0x7fe92e7e(%eax)
80105ed7:	00 00 
80105ed9:	c6 80 84 d1 16 80 00 	movb   $0x0,-0x7fe92e7c(%eax)
80105ee0:	0f b6 88 85 d1 16 80 	movzbl -0x7fe92e7b(%eax),%ecx
80105ee7:	83 e1 f0             	and    $0xfffffff0,%ecx
80105eea:	83 c9 12             	or     $0x12,%ecx
80105eed:	83 e1 9f             	and    $0xffffff9f,%ecx
80105ef0:	83 c9 80             	or     $0xffffff80,%ecx
80105ef3:	88 88 85 d1 16 80    	mov    %cl,-0x7fe92e7b(%eax)
80105ef9:	0f b6 88 86 d1 16 80 	movzbl -0x7fe92e7a(%eax),%ecx
80105f00:	83 c9 0f             	or     $0xf,%ecx
80105f03:	83 e1 cf             	and    $0xffffffcf,%ecx
80105f06:	83 c9 c0             	or     $0xffffffc0,%ecx
80105f09:	88 88 86 d1 16 80    	mov    %cl,-0x7fe92e7a(%eax)
80105f0f:	c6 80 87 d1 16 80 00 	movb   $0x0,-0x7fe92e79(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80105f16:	66 c7 80 88 d1 16 80 	movw   $0xffff,-0x7fe92e78(%eax)
80105f1d:	ff ff 
80105f1f:	66 c7 80 8a d1 16 80 	movw   $0x0,-0x7fe92e76(%eax)
80105f26:	00 00 
80105f28:	c6 80 8c d1 16 80 00 	movb   $0x0,-0x7fe92e74(%eax)
80105f2f:	c6 80 8d d1 16 80 fa 	movb   $0xfa,-0x7fe92e73(%eax)
80105f36:	0f b6 88 8e d1 16 80 	movzbl -0x7fe92e72(%eax),%ecx
80105f3d:	83 c9 0f             	or     $0xf,%ecx
80105f40:	83 e1 cf             	and    $0xffffffcf,%ecx
80105f43:	83 c9 c0             	or     $0xffffffc0,%ecx
80105f46:	88 88 8e d1 16 80    	mov    %cl,-0x7fe92e72(%eax)
80105f4c:	c6 80 8f d1 16 80 00 	movb   $0x0,-0x7fe92e71(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80105f53:	66 c7 80 90 d1 16 80 	movw   $0xffff,-0x7fe92e70(%eax)
80105f5a:	ff ff 
80105f5c:	66 c7 80 92 d1 16 80 	movw   $0x0,-0x7fe92e6e(%eax)
80105f63:	00 00 
80105f65:	c6 80 94 d1 16 80 00 	movb   $0x0,-0x7fe92e6c(%eax)
80105f6c:	c6 80 95 d1 16 80 f2 	movb   $0xf2,-0x7fe92e6b(%eax)
80105f73:	0f b6 88 96 d1 16 80 	movzbl -0x7fe92e6a(%eax),%ecx
80105f7a:	83 c9 0f             	or     $0xf,%ecx
80105f7d:	83 e1 cf             	and    $0xffffffcf,%ecx
80105f80:	83 c9 c0             	or     $0xffffffc0,%ecx
80105f83:	88 88 96 d1 16 80    	mov    %cl,-0x7fe92e6a(%eax)
80105f89:	c6 80 97 d1 16 80 00 	movb   $0x0,-0x7fe92e69(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80105f90:	05 70 d1 16 80       	add    $0x8016d170,%eax
  pd[0] = size-1;
80105f95:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
80105f9b:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
80105f9f:	c1 e8 10             	shr    $0x10,%eax
80105fa2:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
80105fa6:	8d 45 f2             	lea    -0xe(%ebp),%eax
80105fa9:	0f 01 10             	lgdtl  (%eax)
}
80105fac:	83 c4 14             	add    $0x14,%esp
80105faf:	5b                   	pop    %ebx
80105fb0:	5d                   	pop    %ebp
80105fb1:	c3                   	ret    

80105fb2 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80105fb2:	55                   	push   %ebp
80105fb3:	89 e5                	mov    %esp,%ebp
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~inside switchkvm\n");
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80105fb5:	a1 24 df 35 80       	mov    0x8035df24,%eax
80105fba:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
80105fbf:	0f 22 d8             	mov    %eax,%cr3
}
80105fc2:	5d                   	pop    %ebp
80105fc3:	c3                   	ret    

80105fc4 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80105fc4:	55                   	push   %ebp
80105fc5:	89 e5                	mov    %esp,%ebp
80105fc7:	57                   	push   %edi
80105fc8:	56                   	push   %esi
80105fc9:	53                   	push   %ebx
80105fca:	83 ec 1c             	sub    $0x1c,%esp
80105fcd:	8b 75 08             	mov    0x8(%ebp),%esi
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~inside switchuvm\n");
  if(p == 0)
80105fd0:	85 f6                	test   %esi,%esi
80105fd2:	0f 84 dd 00 00 00    	je     801060b5 <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
80105fd8:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
80105fdc:	0f 84 e0 00 00 00    	je     801060c2 <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
80105fe2:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
80105fe6:	0f 84 e3 00 00 00    	je     801060cf <switchuvm+0x10b>
    panic("switchuvm: no pgdir");
  pushcli();
80105fec:	e8 55 dc ff ff       	call   80103c46 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80105ff1:	e8 55 d2 ff ff       	call   8010324b <mycpu>
80105ff6:	89 c3                	mov    %eax,%ebx
80105ff8:	e8 4e d2 ff ff       	call   8010324b <mycpu>
80105ffd:	8d 78 08             	lea    0x8(%eax),%edi
80106000:	e8 46 d2 ff ff       	call   8010324b <mycpu>
80106005:	83 c0 08             	add    $0x8,%eax
80106008:	c1 e8 10             	shr    $0x10,%eax
8010600b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010600e:	e8 38 d2 ff ff       	call   8010324b <mycpu>
80106013:	83 c0 08             	add    $0x8,%eax
80106016:	c1 e8 18             	shr    $0x18,%eax
80106019:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80106020:	67 00 
80106022:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
80106029:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
8010602d:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
80106033:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
8010603a:	83 e2 f0             	and    $0xfffffff0,%edx
8010603d:	83 ca 19             	or     $0x19,%edx
80106040:	83 e2 9f             	and    $0xffffff9f,%edx
80106043:	83 ca 80             	or     $0xffffff80,%edx
80106046:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
8010604c:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
80106053:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
80106059:	e8 ed d1 ff ff       	call   8010324b <mycpu>
8010605e:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80106065:	83 e2 ef             	and    $0xffffffef,%edx
80106068:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
8010606e:	e8 d8 d1 ff ff       	call   8010324b <mycpu>
80106073:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
80106079:	8b 5e 08             	mov    0x8(%esi),%ebx
8010607c:	e8 ca d1 ff ff       	call   8010324b <mycpu>
80106081:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106087:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
8010608a:	e8 bc d1 ff ff       	call   8010324b <mycpu>
8010608f:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
80106095:	b8 28 00 00 00       	mov    $0x28,%eax
8010609a:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
8010609d:	8b 46 04             	mov    0x4(%esi),%eax
801060a0:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
801060a5:	0f 22 d8             	mov    %eax,%cr3
  popcli();
801060a8:	e8 d6 db ff ff       	call   80103c83 <popcli>
}
801060ad:	8d 65 f4             	lea    -0xc(%ebp),%esp
801060b0:	5b                   	pop    %ebx
801060b1:	5e                   	pop    %esi
801060b2:	5f                   	pop    %edi
801060b3:	5d                   	pop    %ebp
801060b4:	c3                   	ret    
    panic("switchuvm: no process");
801060b5:	83 ec 0c             	sub    $0xc,%esp
801060b8:	68 32 6f 10 80       	push   $0x80106f32
801060bd:	e8 86 a2 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
801060c2:	83 ec 0c             	sub    $0xc,%esp
801060c5:	68 48 6f 10 80       	push   $0x80106f48
801060ca:	e8 79 a2 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
801060cf:	83 ec 0c             	sub    $0xc,%esp
801060d2:	68 5d 6f 10 80       	push   $0x80106f5d
801060d7:	e8 6c a2 ff ff       	call   80100348 <panic>

801060dc <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801060dc:	55                   	push   %ebp
801060dd:	89 e5                	mov    %esp,%ebp
801060df:	56                   	push   %esi
801060e0:	53                   	push   %ebx
801060e1:	8b 75 10             	mov    0x10(%ebp),%esi
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~inside inituvm\n");
  char *mem;

  if(sz >= PGSIZE)
801060e4:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801060ea:	77 51                	ja     8010613d <inituvm+0x61>
    panic("inituvm: more than a page");
  //cprintf("~~~~~~~~~~inituvm pid: %d", myproc()->pid);
  mem = kalloc2(-2);
801060ec:	83 ec 0c             	sub    $0xc,%esp
801060ef:	6a fe                	push   $0xfffffffe
801060f1:	e8 45 c0 ff ff       	call   8010213b <kalloc2>
801060f6:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
801060f8:	83 c4 0c             	add    $0xc,%esp
801060fb:	68 00 10 00 00       	push   $0x1000
80106100:	6a 00                	push   $0x0
80106102:	50                   	push   %eax
80106103:	e8 c7 dc ff ff       	call   80103dcf <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
80106108:	83 c4 08             	add    $0x8,%esp
8010610b:	6a 06                	push   $0x6
8010610d:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106113:	50                   	push   %eax
80106114:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106119:	ba 00 00 00 00       	mov    $0x0,%edx
8010611e:	8b 45 08             	mov    0x8(%ebp),%eax
80106121:	e8 ca fc ff ff       	call   80105df0 <mappages>
  memmove(mem, init, sz);
80106126:	83 c4 0c             	add    $0xc,%esp
80106129:	56                   	push   %esi
8010612a:	ff 75 0c             	pushl  0xc(%ebp)
8010612d:	53                   	push   %ebx
8010612e:	e8 17 dd ff ff       	call   80103e4a <memmove>
}
80106133:	83 c4 10             	add    $0x10,%esp
80106136:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106139:	5b                   	pop    %ebx
8010613a:	5e                   	pop    %esi
8010613b:	5d                   	pop    %ebp
8010613c:	c3                   	ret    
    panic("inituvm: more than a page");
8010613d:	83 ec 0c             	sub    $0xc,%esp
80106140:	68 71 6f 10 80       	push   $0x80106f71
80106145:	e8 fe a1 ff ff       	call   80100348 <panic>

8010614a <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
8010614a:	55                   	push   %ebp
8010614b:	89 e5                	mov    %esp,%ebp
8010614d:	57                   	push   %edi
8010614e:	56                   	push   %esi
8010614f:	53                   	push   %ebx
80106150:	83 ec 0c             	sub    $0xc,%esp
80106153:	8b 7d 18             	mov    0x18(%ebp),%edi
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~inside loaduvm\n");
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80106156:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
8010615d:	75 07                	jne    80106166 <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
8010615f:	bb 00 00 00 00       	mov    $0x0,%ebx
80106164:	eb 3c                	jmp    801061a2 <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
80106166:	83 ec 0c             	sub    $0xc,%esp
80106169:	68 2c 70 10 80       	push   $0x8010702c
8010616e:	e8 d5 a1 ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
80106173:	83 ec 0c             	sub    $0xc,%esp
80106176:	68 8b 6f 10 80       	push   $0x80106f8b
8010617b:	e8 c8 a1 ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
80106180:	05 00 00 00 80       	add    $0x80000000,%eax
80106185:	56                   	push   %esi
80106186:	89 da                	mov    %ebx,%edx
80106188:	03 55 14             	add    0x14(%ebp),%edx
8010618b:	52                   	push   %edx
8010618c:	50                   	push   %eax
8010618d:	ff 75 10             	pushl  0x10(%ebp)
80106190:	e8 de b5 ff ff       	call   80101773 <readi>
80106195:	83 c4 10             	add    $0x10,%esp
80106198:	39 f0                	cmp    %esi,%eax
8010619a:	75 47                	jne    801061e3 <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
8010619c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801061a2:	39 fb                	cmp    %edi,%ebx
801061a4:	73 30                	jae    801061d6 <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
801061a6:	89 da                	mov    %ebx,%edx
801061a8:	03 55 0c             	add    0xc(%ebp),%edx
801061ab:	b9 00 00 00 00       	mov    $0x0,%ecx
801061b0:	8b 45 08             	mov    0x8(%ebp),%eax
801061b3:	e8 c0 fb ff ff       	call   80105d78 <walkpgdir>
801061b8:	85 c0                	test   %eax,%eax
801061ba:	74 b7                	je     80106173 <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
801061bc:	8b 00                	mov    (%eax),%eax
801061be:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
801061c3:	89 fe                	mov    %edi,%esi
801061c5:	29 de                	sub    %ebx,%esi
801061c7:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801061cd:	76 b1                	jbe    80106180 <loaduvm+0x36>
      n = PGSIZE;
801061cf:	be 00 10 00 00       	mov    $0x1000,%esi
801061d4:	eb aa                	jmp    80106180 <loaduvm+0x36>
      return -1;
  }
  return 0;
801061d6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801061db:	8d 65 f4             	lea    -0xc(%ebp),%esp
801061de:	5b                   	pop    %ebx
801061df:	5e                   	pop    %esi
801061e0:	5f                   	pop    %edi
801061e1:	5d                   	pop    %ebp
801061e2:	c3                   	ret    
      return -1;
801061e3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061e8:	eb f1                	jmp    801061db <loaduvm+0x91>

801061ea <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801061ea:	55                   	push   %ebp
801061eb:	89 e5                	mov    %esp,%ebp
801061ed:	57                   	push   %edi
801061ee:	56                   	push   %esi
801061ef:	53                   	push   %ebx
801061f0:	83 ec 0c             	sub    $0xc,%esp
801061f3:	8b 7d 0c             	mov    0xc(%ebp),%edi
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~inside deallocuvm\n");
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801061f6:	39 7d 10             	cmp    %edi,0x10(%ebp)
801061f9:	73 11                	jae    8010620c <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
801061fb:	8b 45 10             	mov    0x10(%ebp),%eax
801061fe:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80106204:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
8010620a:	eb 19                	jmp    80106225 <deallocuvm+0x3b>
    return oldsz;
8010620c:	89 f8                	mov    %edi,%eax
8010620e:	eb 64                	jmp    80106274 <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
80106210:	c1 eb 16             	shr    $0x16,%ebx
80106213:	83 c3 01             	add    $0x1,%ebx
80106216:	c1 e3 16             	shl    $0x16,%ebx
80106219:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
8010621f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106225:	39 fb                	cmp    %edi,%ebx
80106227:	73 48                	jae    80106271 <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
80106229:	b9 00 00 00 00       	mov    $0x0,%ecx
8010622e:	89 da                	mov    %ebx,%edx
80106230:	8b 45 08             	mov    0x8(%ebp),%eax
80106233:	e8 40 fb ff ff       	call   80105d78 <walkpgdir>
80106238:	89 c6                	mov    %eax,%esi
    if(!pte)
8010623a:	85 c0                	test   %eax,%eax
8010623c:	74 d2                	je     80106210 <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
8010623e:	8b 00                	mov    (%eax),%eax
80106240:	a8 01                	test   $0x1,%al
80106242:	74 db                	je     8010621f <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
80106244:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106249:	74 19                	je     80106264 <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
8010624b:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
80106250:	83 ec 0c             	sub    $0xc,%esp
80106253:	50                   	push   %eax
80106254:	e8 4b bd ff ff       	call   80101fa4 <kfree>
      *pte = 0;
80106259:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
8010625f:	83 c4 10             	add    $0x10,%esp
80106262:	eb bb                	jmp    8010621f <deallocuvm+0x35>
        panic("kfree");
80106264:	83 ec 0c             	sub    $0xc,%esp
80106267:	68 c6 68 10 80       	push   $0x801068c6
8010626c:	e8 d7 a0 ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
80106271:	8b 45 10             	mov    0x10(%ebp),%eax
}
80106274:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106277:	5b                   	pop    %ebx
80106278:	5e                   	pop    %esi
80106279:	5f                   	pop    %edi
8010627a:	5d                   	pop    %ebp
8010627b:	c3                   	ret    

8010627c <allocuvm>:
{
8010627c:	55                   	push   %ebp
8010627d:	89 e5                	mov    %esp,%ebp
8010627f:	57                   	push   %edi
80106280:	56                   	push   %esi
80106281:	53                   	push   %ebx
80106282:	83 ec 1c             	sub    $0x1c,%esp
80106285:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
80106288:	89 7d e4             	mov    %edi,-0x1c(%ebp)
8010628b:	85 ff                	test   %edi,%edi
8010628d:	0f 88 cf 00 00 00    	js     80106362 <allocuvm+0xe6>
  if(newsz < oldsz)
80106293:	3b 7d 0c             	cmp    0xc(%ebp),%edi
80106296:	72 6a                	jb     80106302 <allocuvm+0x86>
  a = PGROUNDUP(oldsz);
80106298:	8b 45 0c             	mov    0xc(%ebp),%eax
8010629b:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801062a1:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
801062a7:	39 fb                	cmp    %edi,%ebx
801062a9:	0f 83 ba 00 00 00    	jae    80106369 <allocuvm+0xed>
    mem = kalloc2(myproc()->pid);
801062af:	e8 0e d0 ff ff       	call   801032c2 <myproc>
801062b4:	83 ec 0c             	sub    $0xc,%esp
801062b7:	ff 70 10             	pushl  0x10(%eax)
801062ba:	e8 7c be ff ff       	call   8010213b <kalloc2>
801062bf:	89 c6                	mov    %eax,%esi
    if(mem == 0){
801062c1:	83 c4 10             	add    $0x10,%esp
801062c4:	85 c0                	test   %eax,%eax
801062c6:	74 42                	je     8010630a <allocuvm+0x8e>
    memset(mem, 0, PGSIZE);
801062c8:	83 ec 04             	sub    $0x4,%esp
801062cb:	68 00 10 00 00       	push   $0x1000
801062d0:	6a 00                	push   $0x0
801062d2:	50                   	push   %eax
801062d3:	e8 f7 da ff ff       	call   80103dcf <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
801062d8:	83 c4 08             	add    $0x8,%esp
801062db:	6a 06                	push   $0x6
801062dd:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
801062e3:	50                   	push   %eax
801062e4:	b9 00 10 00 00       	mov    $0x1000,%ecx
801062e9:	89 da                	mov    %ebx,%edx
801062eb:	8b 45 08             	mov    0x8(%ebp),%eax
801062ee:	e8 fd fa ff ff       	call   80105df0 <mappages>
801062f3:	83 c4 10             	add    $0x10,%esp
801062f6:	85 c0                	test   %eax,%eax
801062f8:	78 38                	js     80106332 <allocuvm+0xb6>
  for(; a < newsz; a += PGSIZE){
801062fa:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106300:	eb a5                	jmp    801062a7 <allocuvm+0x2b>
    return oldsz;
80106302:	8b 45 0c             	mov    0xc(%ebp),%eax
80106305:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106308:	eb 5f                	jmp    80106369 <allocuvm+0xed>
      cprintf("allocuvm out of memory\n");
8010630a:	83 ec 0c             	sub    $0xc,%esp
8010630d:	68 a9 6f 10 80       	push   $0x80106fa9
80106312:	e8 f4 a2 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80106317:	83 c4 0c             	add    $0xc,%esp
8010631a:	ff 75 0c             	pushl  0xc(%ebp)
8010631d:	57                   	push   %edi
8010631e:	ff 75 08             	pushl  0x8(%ebp)
80106321:	e8 c4 fe ff ff       	call   801061ea <deallocuvm>
      return 0;
80106326:	83 c4 10             	add    $0x10,%esp
80106329:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106330:	eb 37                	jmp    80106369 <allocuvm+0xed>
      cprintf("allocuvm out of memory (2)\n");
80106332:	83 ec 0c             	sub    $0xc,%esp
80106335:	68 c1 6f 10 80       	push   $0x80106fc1
8010633a:	e8 cc a2 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010633f:	83 c4 0c             	add    $0xc,%esp
80106342:	ff 75 0c             	pushl  0xc(%ebp)
80106345:	57                   	push   %edi
80106346:	ff 75 08             	pushl  0x8(%ebp)
80106349:	e8 9c fe ff ff       	call   801061ea <deallocuvm>
      kfree(mem);
8010634e:	89 34 24             	mov    %esi,(%esp)
80106351:	e8 4e bc ff ff       	call   80101fa4 <kfree>
      return 0;
80106356:	83 c4 10             	add    $0x10,%esp
80106359:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106360:	eb 07                	jmp    80106369 <allocuvm+0xed>
    return 0;
80106362:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
80106369:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010636c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010636f:	5b                   	pop    %ebx
80106370:	5e                   	pop    %esi
80106371:	5f                   	pop    %edi
80106372:	5d                   	pop    %ebp
80106373:	c3                   	ret    

80106374 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80106374:	55                   	push   %ebp
80106375:	89 e5                	mov    %esp,%ebp
80106377:	56                   	push   %esi
80106378:	53                   	push   %ebx
80106379:	8b 75 08             	mov    0x8(%ebp),%esi
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~inside freevm\n");
  uint i;

  if(pgdir == 0)
8010637c:	85 f6                	test   %esi,%esi
8010637e:	74 1a                	je     8010639a <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
80106380:	83 ec 04             	sub    $0x4,%esp
80106383:	6a 00                	push   $0x0
80106385:	68 00 00 00 80       	push   $0x80000000
8010638a:	56                   	push   %esi
8010638b:	e8 5a fe ff ff       	call   801061ea <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80106390:	83 c4 10             	add    $0x10,%esp
80106393:	bb 00 00 00 00       	mov    $0x0,%ebx
80106398:	eb 10                	jmp    801063aa <freevm+0x36>
    panic("freevm: no pgdir");
8010639a:	83 ec 0c             	sub    $0xc,%esp
8010639d:	68 dd 6f 10 80       	push   $0x80106fdd
801063a2:	e8 a1 9f ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
801063a7:	83 c3 01             	add    $0x1,%ebx
801063aa:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
801063b0:	77 1f                	ja     801063d1 <freevm+0x5d>
    if(pgdir[i] & PTE_P){
801063b2:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
801063b5:	a8 01                	test   $0x1,%al
801063b7:	74 ee                	je     801063a7 <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
801063b9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801063be:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801063c3:	83 ec 0c             	sub    $0xc,%esp
801063c6:	50                   	push   %eax
801063c7:	e8 d8 bb ff ff       	call   80101fa4 <kfree>
801063cc:	83 c4 10             	add    $0x10,%esp
801063cf:	eb d6                	jmp    801063a7 <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
801063d1:	83 ec 0c             	sub    $0xc,%esp
801063d4:	56                   	push   %esi
801063d5:	e8 ca bb ff ff       	call   80101fa4 <kfree>
}
801063da:	83 c4 10             	add    $0x10,%esp
801063dd:	8d 65 f8             	lea    -0x8(%ebp),%esp
801063e0:	5b                   	pop    %ebx
801063e1:	5e                   	pop    %esi
801063e2:	5d                   	pop    %ebp
801063e3:	c3                   	ret    

801063e4 <setupkvm>:
{
801063e4:	55                   	push   %ebp
801063e5:	89 e5                	mov    %esp,%ebp
801063e7:	56                   	push   %esi
801063e8:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc2(-2)) == 0)
801063e9:	83 ec 0c             	sub    $0xc,%esp
801063ec:	6a fe                	push   $0xfffffffe
801063ee:	e8 48 bd ff ff       	call   8010213b <kalloc2>
801063f3:	89 c6                	mov    %eax,%esi
801063f5:	83 c4 10             	add    $0x10,%esp
801063f8:	85 c0                	test   %eax,%eax
801063fa:	74 55                	je     80106451 <setupkvm+0x6d>
  memset(pgdir, 0, PGSIZE);
801063fc:	83 ec 04             	sub    $0x4,%esp
801063ff:	68 00 10 00 00       	push   $0x1000
80106404:	6a 00                	push   $0x0
80106406:	50                   	push   %eax
80106407:	e8 c3 d9 ff ff       	call   80103dcf <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010640c:	83 c4 10             	add    $0x10,%esp
8010640f:	bb 20 a4 10 80       	mov    $0x8010a420,%ebx
80106414:	81 fb 60 a4 10 80    	cmp    $0x8010a460,%ebx
8010641a:	73 35                	jae    80106451 <setupkvm+0x6d>
                (uint)k->phys_start, k->perm) < 0) {
8010641c:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
8010641f:	8b 4b 08             	mov    0x8(%ebx),%ecx
80106422:	29 c1                	sub    %eax,%ecx
80106424:	83 ec 08             	sub    $0x8,%esp
80106427:	ff 73 0c             	pushl  0xc(%ebx)
8010642a:	50                   	push   %eax
8010642b:	8b 13                	mov    (%ebx),%edx
8010642d:	89 f0                	mov    %esi,%eax
8010642f:	e8 bc f9 ff ff       	call   80105df0 <mappages>
80106434:	83 c4 10             	add    $0x10,%esp
80106437:	85 c0                	test   %eax,%eax
80106439:	78 05                	js     80106440 <setupkvm+0x5c>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010643b:	83 c3 10             	add    $0x10,%ebx
8010643e:	eb d4                	jmp    80106414 <setupkvm+0x30>
      freevm(pgdir);
80106440:	83 ec 0c             	sub    $0xc,%esp
80106443:	56                   	push   %esi
80106444:	e8 2b ff ff ff       	call   80106374 <freevm>
      return 0;
80106449:	83 c4 10             	add    $0x10,%esp
8010644c:	be 00 00 00 00       	mov    $0x0,%esi
}
80106451:	89 f0                	mov    %esi,%eax
80106453:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106456:	5b                   	pop    %ebx
80106457:	5e                   	pop    %esi
80106458:	5d                   	pop    %ebp
80106459:	c3                   	ret    

8010645a <kvmalloc>:
{
8010645a:	55                   	push   %ebp
8010645b:	89 e5                	mov    %esp,%ebp
8010645d:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80106460:	e8 7f ff ff ff       	call   801063e4 <setupkvm>
80106465:	a3 24 df 35 80       	mov    %eax,0x8035df24
  switchkvm();
8010646a:	e8 43 fb ff ff       	call   80105fb2 <switchkvm>
}
8010646f:	c9                   	leave  
80106470:	c3                   	ret    

80106471 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80106471:	55                   	push   %ebp
80106472:	89 e5                	mov    %esp,%ebp
80106474:	83 ec 08             	sub    $0x8,%esp
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~inside clearpteu\n");
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80106477:	b9 00 00 00 00       	mov    $0x0,%ecx
8010647c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010647f:	8b 45 08             	mov    0x8(%ebp),%eax
80106482:	e8 f1 f8 ff ff       	call   80105d78 <walkpgdir>
  if(pte == 0)
80106487:	85 c0                	test   %eax,%eax
80106489:	74 05                	je     80106490 <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
8010648b:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
8010648e:	c9                   	leave  
8010648f:	c3                   	ret    
    panic("clearpteu");
80106490:	83 ec 0c             	sub    $0xc,%esp
80106493:	68 ee 6f 10 80       	push   $0x80106fee
80106498:	e8 ab 9e ff ff       	call   80100348 <panic>

8010649d <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
8010649d:	55                   	push   %ebp
8010649e:	89 e5                	mov    %esp,%ebp
801064a0:	57                   	push   %edi
801064a1:	56                   	push   %esi
801064a2:	53                   	push   %ebx
801064a3:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
801064a6:	e8 39 ff ff ff       	call   801063e4 <setupkvm>
801064ab:	89 45 dc             	mov    %eax,-0x24(%ebp)
801064ae:	85 c0                	test   %eax,%eax
801064b0:	0f 84 d2 00 00 00    	je     80106588 <copyuvm+0xeb>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801064b6:	bf 00 00 00 00       	mov    $0x0,%edi
801064bb:	3b 7d 0c             	cmp    0xc(%ebp),%edi
801064be:	0f 83 c4 00 00 00    	jae    80106588 <copyuvm+0xeb>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801064c4:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801064c7:	b9 00 00 00 00       	mov    $0x0,%ecx
801064cc:	89 fa                	mov    %edi,%edx
801064ce:	8b 45 08             	mov    0x8(%ebp),%eax
801064d1:	e8 a2 f8 ff ff       	call   80105d78 <walkpgdir>
801064d6:	85 c0                	test   %eax,%eax
801064d8:	74 73                	je     8010654d <copyuvm+0xb0>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
801064da:	8b 00                	mov    (%eax),%eax
801064dc:	a8 01                	test   $0x1,%al
801064de:	74 7a                	je     8010655a <copyuvm+0xbd>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
801064e0:	89 c6                	mov    %eax,%esi
801064e2:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    flags = PTE_FLAGS(*pte);
801064e8:	25 ff 0f 00 00       	and    $0xfff,%eax
801064ed:	89 45 e0             	mov    %eax,-0x20(%ebp)
    //int pid = -2;
    //cprintf("~~~~~~~~copyuvm, pid: %d\n", myproc()->pid);
    if((mem = kalloc2(myproc()->pid)) == 0)
801064f0:	e8 cd cd ff ff       	call   801032c2 <myproc>
801064f5:	83 ec 0c             	sub    $0xc,%esp
801064f8:	ff 70 10             	pushl  0x10(%eax)
801064fb:	e8 3b bc ff ff       	call   8010213b <kalloc2>
80106500:	89 c3                	mov    %eax,%ebx
80106502:	83 c4 10             	add    $0x10,%esp
80106505:	85 c0                	test   %eax,%eax
80106507:	74 6a                	je     80106573 <copyuvm+0xd6>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
80106509:	81 c6 00 00 00 80    	add    $0x80000000,%esi
8010650f:	83 ec 04             	sub    $0x4,%esp
80106512:	68 00 10 00 00       	push   $0x1000
80106517:	56                   	push   %esi
80106518:	50                   	push   %eax
80106519:	e8 2c d9 ff ff       	call   80103e4a <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
8010651e:	83 c4 08             	add    $0x8,%esp
80106521:	ff 75 e0             	pushl  -0x20(%ebp)
80106524:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
8010652a:	50                   	push   %eax
8010652b:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106530:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80106533:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106536:	e8 b5 f8 ff ff       	call   80105df0 <mappages>
8010653b:	83 c4 10             	add    $0x10,%esp
8010653e:	85 c0                	test   %eax,%eax
80106540:	78 25                	js     80106567 <copyuvm+0xca>
  for(i = 0; i < sz; i += PGSIZE){
80106542:	81 c7 00 10 00 00    	add    $0x1000,%edi
80106548:	e9 6e ff ff ff       	jmp    801064bb <copyuvm+0x1e>
      panic("copyuvm: pte should exist");
8010654d:	83 ec 0c             	sub    $0xc,%esp
80106550:	68 f8 6f 10 80       	push   $0x80106ff8
80106555:	e8 ee 9d ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
8010655a:	83 ec 0c             	sub    $0xc,%esp
8010655d:	68 12 70 10 80       	push   $0x80107012
80106562:	e8 e1 9d ff ff       	call   80100348 <panic>
      kfree(mem);
80106567:	83 ec 0c             	sub    $0xc,%esp
8010656a:	53                   	push   %ebx
8010656b:	e8 34 ba ff ff       	call   80101fa4 <kfree>
      goto bad;
80106570:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
80106573:	83 ec 0c             	sub    $0xc,%esp
80106576:	ff 75 dc             	pushl  -0x24(%ebp)
80106579:	e8 f6 fd ff ff       	call   80106374 <freevm>
  return 0;
8010657e:	83 c4 10             	add    $0x10,%esp
80106581:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
80106588:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010658b:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010658e:	5b                   	pop    %ebx
8010658f:	5e                   	pop    %esi
80106590:	5f                   	pop    %edi
80106591:	5d                   	pop    %ebp
80106592:	c3                   	ret    

80106593 <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80106593:	55                   	push   %ebp
80106594:	89 e5                	mov    %esp,%ebp
80106596:	83 ec 08             	sub    $0x8,%esp
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~inside uva2ka\n");
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80106599:	b9 00 00 00 00       	mov    $0x0,%ecx
8010659e:	8b 55 0c             	mov    0xc(%ebp),%edx
801065a1:	8b 45 08             	mov    0x8(%ebp),%eax
801065a4:	e8 cf f7 ff ff       	call   80105d78 <walkpgdir>
  if((*pte & PTE_P) == 0)
801065a9:	8b 00                	mov    (%eax),%eax
801065ab:	a8 01                	test   $0x1,%al
801065ad:	74 10                	je     801065bf <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
801065af:	a8 04                	test   $0x4,%al
801065b1:	74 13                	je     801065c6 <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
801065b3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801065b8:	05 00 00 00 80       	add    $0x80000000,%eax
}
801065bd:	c9                   	leave  
801065be:	c3                   	ret    
    return 0;
801065bf:	b8 00 00 00 00       	mov    $0x0,%eax
801065c4:	eb f7                	jmp    801065bd <uva2ka+0x2a>
    return 0;
801065c6:	b8 00 00 00 00       	mov    $0x0,%eax
801065cb:	eb f0                	jmp    801065bd <uva2ka+0x2a>

801065cd <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801065cd:	55                   	push   %ebp
801065ce:	89 e5                	mov    %esp,%ebp
801065d0:	57                   	push   %edi
801065d1:	56                   	push   %esi
801065d2:	53                   	push   %ebx
801065d3:	83 ec 0c             	sub    $0xc,%esp
801065d6:	8b 7d 14             	mov    0x14(%ebp),%edi
  //cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~inside copyout\n");
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801065d9:	eb 25                	jmp    80106600 <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
801065db:	8b 55 0c             	mov    0xc(%ebp),%edx
801065de:	29 f2                	sub    %esi,%edx
801065e0:	01 d0                	add    %edx,%eax
801065e2:	83 ec 04             	sub    $0x4,%esp
801065e5:	53                   	push   %ebx
801065e6:	ff 75 10             	pushl  0x10(%ebp)
801065e9:	50                   	push   %eax
801065ea:	e8 5b d8 ff ff       	call   80103e4a <memmove>
    len -= n;
801065ef:	29 df                	sub    %ebx,%edi
    buf += n;
801065f1:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
801065f4:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
801065fa:	89 45 0c             	mov    %eax,0xc(%ebp)
801065fd:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
80106600:	85 ff                	test   %edi,%edi
80106602:	74 2f                	je     80106633 <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
80106604:	8b 75 0c             	mov    0xc(%ebp),%esi
80106607:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
8010660d:	83 ec 08             	sub    $0x8,%esp
80106610:	56                   	push   %esi
80106611:	ff 75 08             	pushl  0x8(%ebp)
80106614:	e8 7a ff ff ff       	call   80106593 <uva2ka>
    if(pa0 == 0)
80106619:	83 c4 10             	add    $0x10,%esp
8010661c:	85 c0                	test   %eax,%eax
8010661e:	74 20                	je     80106640 <copyout+0x73>
    n = PGSIZE - (va - va0);
80106620:	89 f3                	mov    %esi,%ebx
80106622:	2b 5d 0c             	sub    0xc(%ebp),%ebx
80106625:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
8010662b:	39 df                	cmp    %ebx,%edi
8010662d:	73 ac                	jae    801065db <copyout+0xe>
      n = len;
8010662f:	89 fb                	mov    %edi,%ebx
80106631:	eb a8                	jmp    801065db <copyout+0xe>
  }
  return 0;
80106633:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106638:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010663b:	5b                   	pop    %ebx
8010663c:	5e                   	pop    %esi
8010663d:	5f                   	pop    %edi
8010663e:	5d                   	pop    %ebp
8010663f:	c3                   	ret    
      return -1;
80106640:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106645:	eb f1                	jmp    80106638 <copyout+0x6b>
