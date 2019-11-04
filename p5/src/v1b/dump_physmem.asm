
_dump_physmem:     file format elf32-i386


Disassembly of section .text:

00000000 <main>:
#include "param.h"


int
main(int argc, char **argv)
{
   0:	8d 4c 24 04          	lea    0x4(%esp),%ecx
   4:	83 e4 f0             	and    $0xfffffff0,%esp
   7:	ff 71 fc             	pushl  -0x4(%ecx)
   a:	55                   	push   %ebp
   b:	89 e5                	mov    %esp,%ebp
   d:	57                   	push   %edi
   e:	56                   	push   %esi
   f:	53                   	push   %ebx
  10:	51                   	push   %ecx
  11:	81 ec 38 03 00 00    	sub    $0x338,%esp
  int numframes = 200;
  int frames[numframes];
  17:	89 e2                	mov    %esp,%edx
  19:	89 d3                	mov    %edx,%ebx
  int pids[numframes];
  1b:	81 ec 30 03 00 00    	sub    $0x330,%esp
  21:	89 e1                	mov    %esp,%ecx
  23:	89 ce                	mov    %ecx,%esi
  
  for(int i=0; i<numframes; i++){
  25:	b8 00 00 00 00       	mov    $0x0,%eax
  2a:	eb 11                	jmp    3d <main+0x3d>
	  frames[i] = -1;
  2c:	c7 04 83 ff ff ff ff 	movl   $0xffffffff,(%ebx,%eax,4)
	  pids[i] = -1;
  33:	c7 04 86 ff ff ff ff 	movl   $0xffffffff,(%esi,%eax,4)
  for(int i=0; i<numframes; i++){
  3a:	83 c0 01             	add    $0x1,%eax
  3d:	3d c7 00 00 00       	cmp    $0xc7,%eax
  42:	7e e8                	jle    2c <main+0x2c>
  }
  
  int result = dump_physmem(frames, pids, numframes);
  44:	83 ec 04             	sub    $0x4,%esp
  47:	68 c8 00 00 00       	push   $0xc8
  4c:	51                   	push   %ecx
  4d:	52                   	push   %edx
  4e:	e8 29 02 00 00       	call   27c <dump_physmem>
  53:	89 c7                	mov    %eax,%edi
  if(result == 0){
  55:	83 c4 10             	add    $0x10,%esp
  58:	85 c0                	test   %eax,%eax
  5a:	75 47                	jne    a3 <main+0xa3>
	  printf(2, "succeed\n");
  5c:	83 ec 08             	sub    $0x8,%esp
  5f:	68 40 06 00 00       	push   $0x640
  64:	6a 02                	push   $0x2
  66:	e8 1b 03 00 00       	call   386 <printf>
	  for(int i=0; i<numframes; i++){
  6b:	83 c4 10             	add    $0x10,%esp
  6e:	eb 26                	jmp    96 <main+0x96>
	    printf(2, "frames[%d]: %d\n", i,  frames[i]);
  70:	ff 34 bb             	pushl  (%ebx,%edi,4)
  73:	57                   	push   %edi
  74:	68 49 06 00 00       	push   $0x649
  79:	6a 02                	push   $0x2
  7b:	e8 06 03 00 00       	call   386 <printf>
	    printf(2, "pids[%d]: %d\n", i, pids[i]);
  80:	ff 34 be             	pushl  (%esi,%edi,4)
  83:	57                   	push   %edi
  84:	68 59 06 00 00       	push   $0x659
  89:	6a 02                	push   $0x2
  8b:	e8 f6 02 00 00       	call   386 <printf>
	  for(int i=0; i<numframes; i++){
  90:	83 c7 01             	add    $0x1,%edi
  93:	83 c4 20             	add    $0x20,%esp
  96:	81 ff c7 00 00 00    	cmp    $0xc7,%edi
  9c:	7e d2                	jle    70 <main+0x70>
	  }
  }
  else{
	  printf(2, "fail\n");
  }
  exit();
  9e:	e8 a1 01 00 00       	call   244 <exit>
	  printf(2, "fail\n");
  a3:	83 ec 08             	sub    $0x8,%esp
  a6:	68 67 06 00 00       	push   $0x667
  ab:	6a 02                	push   $0x2
  ad:	e8 d4 02 00 00       	call   386 <printf>
  b2:	83 c4 10             	add    $0x10,%esp
  b5:	eb e7                	jmp    9e <main+0x9e>

000000b7 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, const char *t)
{
  b7:	55                   	push   %ebp
  b8:	89 e5                	mov    %esp,%ebp
  ba:	53                   	push   %ebx
  bb:	8b 45 08             	mov    0x8(%ebp),%eax
  be:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  c1:	89 c2                	mov    %eax,%edx
  c3:	0f b6 19             	movzbl (%ecx),%ebx
  c6:	88 1a                	mov    %bl,(%edx)
  c8:	8d 52 01             	lea    0x1(%edx),%edx
  cb:	8d 49 01             	lea    0x1(%ecx),%ecx
  ce:	84 db                	test   %bl,%bl
  d0:	75 f1                	jne    c3 <strcpy+0xc>
    ;
  return os;
}
  d2:	5b                   	pop    %ebx
  d3:	5d                   	pop    %ebp
  d4:	c3                   	ret    

000000d5 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  d5:	55                   	push   %ebp
  d6:	89 e5                	mov    %esp,%ebp
  d8:	8b 4d 08             	mov    0x8(%ebp),%ecx
  db:	8b 55 0c             	mov    0xc(%ebp),%edx
  while(*p && *p == *q)
  de:	eb 06                	jmp    e6 <strcmp+0x11>
    p++, q++;
  e0:	83 c1 01             	add    $0x1,%ecx
  e3:	83 c2 01             	add    $0x1,%edx
  while(*p && *p == *q)
  e6:	0f b6 01             	movzbl (%ecx),%eax
  e9:	84 c0                	test   %al,%al
  eb:	74 04                	je     f1 <strcmp+0x1c>
  ed:	3a 02                	cmp    (%edx),%al
  ef:	74 ef                	je     e0 <strcmp+0xb>
  return (uchar)*p - (uchar)*q;
  f1:	0f b6 c0             	movzbl %al,%eax
  f4:	0f b6 12             	movzbl (%edx),%edx
  f7:	29 d0                	sub    %edx,%eax
}
  f9:	5d                   	pop    %ebp
  fa:	c3                   	ret    

000000fb <strlen>:

uint
strlen(const char *s)
{
  fb:	55                   	push   %ebp
  fc:	89 e5                	mov    %esp,%ebp
  fe:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int n;

  for(n = 0; s[n]; n++)
 101:	ba 00 00 00 00       	mov    $0x0,%edx
 106:	eb 03                	jmp    10b <strlen+0x10>
 108:	83 c2 01             	add    $0x1,%edx
 10b:	89 d0                	mov    %edx,%eax
 10d:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
 111:	75 f5                	jne    108 <strlen+0xd>
    ;
  return n;
}
 113:	5d                   	pop    %ebp
 114:	c3                   	ret    

00000115 <memset>:

void*
memset(void *dst, int c, uint n)
{
 115:	55                   	push   %ebp
 116:	89 e5                	mov    %esp,%ebp
 118:	57                   	push   %edi
 119:	8b 55 08             	mov    0x8(%ebp),%edx
}

static inline void
stosb(void *addr, int data, int cnt)
{
  asm volatile("cld; rep stosb" :
 11c:	89 d7                	mov    %edx,%edi
 11e:	8b 4d 10             	mov    0x10(%ebp),%ecx
 121:	8b 45 0c             	mov    0xc(%ebp),%eax
 124:	fc                   	cld    
 125:	f3 aa                	rep stos %al,%es:(%edi)
  stosb(dst, c, n);
  return dst;
}
 127:	89 d0                	mov    %edx,%eax
 129:	5f                   	pop    %edi
 12a:	5d                   	pop    %ebp
 12b:	c3                   	ret    

0000012c <strchr>:

char*
strchr(const char *s, char c)
{
 12c:	55                   	push   %ebp
 12d:	89 e5                	mov    %esp,%ebp
 12f:	8b 45 08             	mov    0x8(%ebp),%eax
 132:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
  for(; *s; s++)
 136:	0f b6 10             	movzbl (%eax),%edx
 139:	84 d2                	test   %dl,%dl
 13b:	74 09                	je     146 <strchr+0x1a>
    if(*s == c)
 13d:	38 ca                	cmp    %cl,%dl
 13f:	74 0a                	je     14b <strchr+0x1f>
  for(; *s; s++)
 141:	83 c0 01             	add    $0x1,%eax
 144:	eb f0                	jmp    136 <strchr+0xa>
      return (char*)s;
  return 0;
 146:	b8 00 00 00 00       	mov    $0x0,%eax
}
 14b:	5d                   	pop    %ebp
 14c:	c3                   	ret    

0000014d <gets>:

char*
gets(char *buf, int max)
{
 14d:	55                   	push   %ebp
 14e:	89 e5                	mov    %esp,%ebp
 150:	57                   	push   %edi
 151:	56                   	push   %esi
 152:	53                   	push   %ebx
 153:	83 ec 1c             	sub    $0x1c,%esp
 156:	8b 7d 08             	mov    0x8(%ebp),%edi
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 159:	bb 00 00 00 00       	mov    $0x0,%ebx
 15e:	8d 73 01             	lea    0x1(%ebx),%esi
 161:	3b 75 0c             	cmp    0xc(%ebp),%esi
 164:	7d 2e                	jge    194 <gets+0x47>
    cc = read(0, &c, 1);
 166:	83 ec 04             	sub    $0x4,%esp
 169:	6a 01                	push   $0x1
 16b:	8d 45 e7             	lea    -0x19(%ebp),%eax
 16e:	50                   	push   %eax
 16f:	6a 00                	push   $0x0
 171:	e8 e6 00 00 00       	call   25c <read>
    if(cc < 1)
 176:	83 c4 10             	add    $0x10,%esp
 179:	85 c0                	test   %eax,%eax
 17b:	7e 17                	jle    194 <gets+0x47>
      break;
    buf[i++] = c;
 17d:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
 181:	88 04 1f             	mov    %al,(%edi,%ebx,1)
    if(c == '\n' || c == '\r')
 184:	3c 0a                	cmp    $0xa,%al
 186:	0f 94 c2             	sete   %dl
 189:	3c 0d                	cmp    $0xd,%al
 18b:	0f 94 c0             	sete   %al
    buf[i++] = c;
 18e:	89 f3                	mov    %esi,%ebx
    if(c == '\n' || c == '\r')
 190:	08 c2                	or     %al,%dl
 192:	74 ca                	je     15e <gets+0x11>
      break;
  }
  buf[i] = '\0';
 194:	c6 04 1f 00          	movb   $0x0,(%edi,%ebx,1)
  return buf;
}
 198:	89 f8                	mov    %edi,%eax
 19a:	8d 65 f4             	lea    -0xc(%ebp),%esp
 19d:	5b                   	pop    %ebx
 19e:	5e                   	pop    %esi
 19f:	5f                   	pop    %edi
 1a0:	5d                   	pop    %ebp
 1a1:	c3                   	ret    

000001a2 <stat>:

int
stat(const char *n, struct stat *st)
{
 1a2:	55                   	push   %ebp
 1a3:	89 e5                	mov    %esp,%ebp
 1a5:	56                   	push   %esi
 1a6:	53                   	push   %ebx
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1a7:	83 ec 08             	sub    $0x8,%esp
 1aa:	6a 00                	push   $0x0
 1ac:	ff 75 08             	pushl  0x8(%ebp)
 1af:	e8 d8 00 00 00       	call   28c <open>
  if(fd < 0)
 1b4:	83 c4 10             	add    $0x10,%esp
 1b7:	85 c0                	test   %eax,%eax
 1b9:	78 24                	js     1df <stat+0x3d>
 1bb:	89 c3                	mov    %eax,%ebx
    return -1;
  r = fstat(fd, st);
 1bd:	83 ec 08             	sub    $0x8,%esp
 1c0:	ff 75 0c             	pushl  0xc(%ebp)
 1c3:	50                   	push   %eax
 1c4:	e8 db 00 00 00       	call   2a4 <fstat>
 1c9:	89 c6                	mov    %eax,%esi
  close(fd);
 1cb:	89 1c 24             	mov    %ebx,(%esp)
 1ce:	e8 99 00 00 00       	call   26c <close>
  return r;
 1d3:	83 c4 10             	add    $0x10,%esp
}
 1d6:	89 f0                	mov    %esi,%eax
 1d8:	8d 65 f8             	lea    -0x8(%ebp),%esp
 1db:	5b                   	pop    %ebx
 1dc:	5e                   	pop    %esi
 1dd:	5d                   	pop    %ebp
 1de:	c3                   	ret    
    return -1;
 1df:	be ff ff ff ff       	mov    $0xffffffff,%esi
 1e4:	eb f0                	jmp    1d6 <stat+0x34>

000001e6 <atoi>:

int
atoi(const char *s)
{
 1e6:	55                   	push   %ebp
 1e7:	89 e5                	mov    %esp,%ebp
 1e9:	53                   	push   %ebx
 1ea:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int n;

  n = 0;
 1ed:	b8 00 00 00 00       	mov    $0x0,%eax
  while('0' <= *s && *s <= '9')
 1f2:	eb 10                	jmp    204 <atoi+0x1e>
    n = n*10 + *s++ - '0';
 1f4:	8d 1c 80             	lea    (%eax,%eax,4),%ebx
 1f7:	8d 04 1b             	lea    (%ebx,%ebx,1),%eax
 1fa:	83 c1 01             	add    $0x1,%ecx
 1fd:	0f be d2             	movsbl %dl,%edx
 200:	8d 44 02 d0          	lea    -0x30(%edx,%eax,1),%eax
  while('0' <= *s && *s <= '9')
 204:	0f b6 11             	movzbl (%ecx),%edx
 207:	8d 5a d0             	lea    -0x30(%edx),%ebx
 20a:	80 fb 09             	cmp    $0x9,%bl
 20d:	76 e5                	jbe    1f4 <atoi+0xe>
  return n;
}
 20f:	5b                   	pop    %ebx
 210:	5d                   	pop    %ebp
 211:	c3                   	ret    

00000212 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 212:	55                   	push   %ebp
 213:	89 e5                	mov    %esp,%ebp
 215:	56                   	push   %esi
 216:	53                   	push   %ebx
 217:	8b 45 08             	mov    0x8(%ebp),%eax
 21a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
 21d:	8b 55 10             	mov    0x10(%ebp),%edx
  char *dst;
  const char *src;

  dst = vdst;
 220:	89 c1                	mov    %eax,%ecx
  src = vsrc;
  while(n-- > 0)
 222:	eb 0d                	jmp    231 <memmove+0x1f>
    *dst++ = *src++;
 224:	0f b6 13             	movzbl (%ebx),%edx
 227:	88 11                	mov    %dl,(%ecx)
 229:	8d 5b 01             	lea    0x1(%ebx),%ebx
 22c:	8d 49 01             	lea    0x1(%ecx),%ecx
  while(n-- > 0)
 22f:	89 f2                	mov    %esi,%edx
 231:	8d 72 ff             	lea    -0x1(%edx),%esi
 234:	85 d2                	test   %edx,%edx
 236:	7f ec                	jg     224 <memmove+0x12>
  return vdst;
}
 238:	5b                   	pop    %ebx
 239:	5e                   	pop    %esi
 23a:	5d                   	pop    %ebp
 23b:	c3                   	ret    

0000023c <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 23c:	b8 01 00 00 00       	mov    $0x1,%eax
 241:	cd 40                	int    $0x40
 243:	c3                   	ret    

00000244 <exit>:
SYSCALL(exit)
 244:	b8 02 00 00 00       	mov    $0x2,%eax
 249:	cd 40                	int    $0x40
 24b:	c3                   	ret    

0000024c <wait>:
SYSCALL(wait)
 24c:	b8 03 00 00 00       	mov    $0x3,%eax
 251:	cd 40                	int    $0x40
 253:	c3                   	ret    

00000254 <pipe>:
SYSCALL(pipe)
 254:	b8 04 00 00 00       	mov    $0x4,%eax
 259:	cd 40                	int    $0x40
 25b:	c3                   	ret    

0000025c <read>:
SYSCALL(read)
 25c:	b8 05 00 00 00       	mov    $0x5,%eax
 261:	cd 40                	int    $0x40
 263:	c3                   	ret    

00000264 <write>:
SYSCALL(write)
 264:	b8 10 00 00 00       	mov    $0x10,%eax
 269:	cd 40                	int    $0x40
 26b:	c3                   	ret    

0000026c <close>:
SYSCALL(close)
 26c:	b8 15 00 00 00       	mov    $0x15,%eax
 271:	cd 40                	int    $0x40
 273:	c3                   	ret    

00000274 <kill>:
SYSCALL(kill)
 274:	b8 06 00 00 00       	mov    $0x6,%eax
 279:	cd 40                	int    $0x40
 27b:	c3                   	ret    

0000027c <dump_physmem>:
SYSCALL(dump_physmem)
 27c:	b8 16 00 00 00       	mov    $0x16,%eax
 281:	cd 40                	int    $0x40
 283:	c3                   	ret    

00000284 <exec>:
SYSCALL(exec)
 284:	b8 07 00 00 00       	mov    $0x7,%eax
 289:	cd 40                	int    $0x40
 28b:	c3                   	ret    

0000028c <open>:
SYSCALL(open)
 28c:	b8 0f 00 00 00       	mov    $0xf,%eax
 291:	cd 40                	int    $0x40
 293:	c3                   	ret    

00000294 <mknod>:
SYSCALL(mknod)
 294:	b8 11 00 00 00       	mov    $0x11,%eax
 299:	cd 40                	int    $0x40
 29b:	c3                   	ret    

0000029c <unlink>:
SYSCALL(unlink)
 29c:	b8 12 00 00 00       	mov    $0x12,%eax
 2a1:	cd 40                	int    $0x40
 2a3:	c3                   	ret    

000002a4 <fstat>:
SYSCALL(fstat)
 2a4:	b8 08 00 00 00       	mov    $0x8,%eax
 2a9:	cd 40                	int    $0x40
 2ab:	c3                   	ret    

000002ac <link>:
SYSCALL(link)
 2ac:	b8 13 00 00 00       	mov    $0x13,%eax
 2b1:	cd 40                	int    $0x40
 2b3:	c3                   	ret    

000002b4 <mkdir>:
SYSCALL(mkdir)
 2b4:	b8 14 00 00 00       	mov    $0x14,%eax
 2b9:	cd 40                	int    $0x40
 2bb:	c3                   	ret    

000002bc <chdir>:
SYSCALL(chdir)
 2bc:	b8 09 00 00 00       	mov    $0x9,%eax
 2c1:	cd 40                	int    $0x40
 2c3:	c3                   	ret    

000002c4 <dup>:
SYSCALL(dup)
 2c4:	b8 0a 00 00 00       	mov    $0xa,%eax
 2c9:	cd 40                	int    $0x40
 2cb:	c3                   	ret    

000002cc <getpid>:
SYSCALL(getpid)
 2cc:	b8 0b 00 00 00       	mov    $0xb,%eax
 2d1:	cd 40                	int    $0x40
 2d3:	c3                   	ret    

000002d4 <sbrk>:
SYSCALL(sbrk)
 2d4:	b8 0c 00 00 00       	mov    $0xc,%eax
 2d9:	cd 40                	int    $0x40
 2db:	c3                   	ret    

000002dc <sleep>:
SYSCALL(sleep)
 2dc:	b8 0d 00 00 00       	mov    $0xd,%eax
 2e1:	cd 40                	int    $0x40
 2e3:	c3                   	ret    

000002e4 <uptime>:
SYSCALL(uptime)
 2e4:	b8 0e 00 00 00       	mov    $0xe,%eax
 2e9:	cd 40                	int    $0x40
 2eb:	c3                   	ret    

000002ec <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 2ec:	55                   	push   %ebp
 2ed:	89 e5                	mov    %esp,%ebp
 2ef:	83 ec 1c             	sub    $0x1c,%esp
 2f2:	88 55 f4             	mov    %dl,-0xc(%ebp)
  write(fd, &c, 1);
 2f5:	6a 01                	push   $0x1
 2f7:	8d 55 f4             	lea    -0xc(%ebp),%edx
 2fa:	52                   	push   %edx
 2fb:	50                   	push   %eax
 2fc:	e8 63 ff ff ff       	call   264 <write>
}
 301:	83 c4 10             	add    $0x10,%esp
 304:	c9                   	leave  
 305:	c3                   	ret    

00000306 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 306:	55                   	push   %ebp
 307:	89 e5                	mov    %esp,%ebp
 309:	57                   	push   %edi
 30a:	56                   	push   %esi
 30b:	53                   	push   %ebx
 30c:	83 ec 2c             	sub    $0x2c,%esp
 30f:	89 c7                	mov    %eax,%edi
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 311:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
 315:	0f 95 c3             	setne  %bl
 318:	89 d0                	mov    %edx,%eax
 31a:	c1 e8 1f             	shr    $0x1f,%eax
 31d:	84 c3                	test   %al,%bl
 31f:	74 10                	je     331 <printint+0x2b>
    neg = 1;
    x = -xx;
 321:	f7 da                	neg    %edx
    neg = 1;
 323:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
  } else {
    x = xx;
  }

  i = 0;
 32a:	be 00 00 00 00       	mov    $0x0,%esi
 32f:	eb 0b                	jmp    33c <printint+0x36>
  neg = 0;
 331:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
 338:	eb f0                	jmp    32a <printint+0x24>
  do{
    buf[i++] = digits[x % base];
 33a:	89 c6                	mov    %eax,%esi
 33c:	89 d0                	mov    %edx,%eax
 33e:	ba 00 00 00 00       	mov    $0x0,%edx
 343:	f7 f1                	div    %ecx
 345:	89 c3                	mov    %eax,%ebx
 347:	8d 46 01             	lea    0x1(%esi),%eax
 34a:	0f b6 92 74 06 00 00 	movzbl 0x674(%edx),%edx
 351:	88 54 35 d8          	mov    %dl,-0x28(%ebp,%esi,1)
  }while((x /= base) != 0);
 355:	89 da                	mov    %ebx,%edx
 357:	85 db                	test   %ebx,%ebx
 359:	75 df                	jne    33a <printint+0x34>
 35b:	89 c3                	mov    %eax,%ebx
  if(neg)
 35d:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
 361:	74 16                	je     379 <printint+0x73>
    buf[i++] = '-';
 363:	c6 44 05 d8 2d       	movb   $0x2d,-0x28(%ebp,%eax,1)
 368:	8d 5e 02             	lea    0x2(%esi),%ebx
 36b:	eb 0c                	jmp    379 <printint+0x73>

  while(--i >= 0)
    putc(fd, buf[i]);
 36d:	0f be 54 1d d8       	movsbl -0x28(%ebp,%ebx,1),%edx
 372:	89 f8                	mov    %edi,%eax
 374:	e8 73 ff ff ff       	call   2ec <putc>
  while(--i >= 0)
 379:	83 eb 01             	sub    $0x1,%ebx
 37c:	79 ef                	jns    36d <printint+0x67>
}
 37e:	83 c4 2c             	add    $0x2c,%esp
 381:	5b                   	pop    %ebx
 382:	5e                   	pop    %esi
 383:	5f                   	pop    %edi
 384:	5d                   	pop    %ebp
 385:	c3                   	ret    

00000386 <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, const char *fmt, ...)
{
 386:	55                   	push   %ebp
 387:	89 e5                	mov    %esp,%ebp
 389:	57                   	push   %edi
 38a:	56                   	push   %esi
 38b:	53                   	push   %ebx
 38c:	83 ec 1c             	sub    $0x1c,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
 38f:	8d 45 10             	lea    0x10(%ebp),%eax
 392:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  state = 0;
 395:	be 00 00 00 00       	mov    $0x0,%esi
  for(i = 0; fmt[i]; i++){
 39a:	bb 00 00 00 00       	mov    $0x0,%ebx
 39f:	eb 14                	jmp    3b5 <printf+0x2f>
    c = fmt[i] & 0xff;
    if(state == 0){
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
 3a1:	89 fa                	mov    %edi,%edx
 3a3:	8b 45 08             	mov    0x8(%ebp),%eax
 3a6:	e8 41 ff ff ff       	call   2ec <putc>
 3ab:	eb 05                	jmp    3b2 <printf+0x2c>
      }
    } else if(state == '%'){
 3ad:	83 fe 25             	cmp    $0x25,%esi
 3b0:	74 25                	je     3d7 <printf+0x51>
  for(i = 0; fmt[i]; i++){
 3b2:	83 c3 01             	add    $0x1,%ebx
 3b5:	8b 45 0c             	mov    0xc(%ebp),%eax
 3b8:	0f b6 04 18          	movzbl (%eax,%ebx,1),%eax
 3bc:	84 c0                	test   %al,%al
 3be:	0f 84 23 01 00 00    	je     4e7 <printf+0x161>
    c = fmt[i] & 0xff;
 3c4:	0f be f8             	movsbl %al,%edi
 3c7:	0f b6 c0             	movzbl %al,%eax
    if(state == 0){
 3ca:	85 f6                	test   %esi,%esi
 3cc:	75 df                	jne    3ad <printf+0x27>
      if(c == '%'){
 3ce:	83 f8 25             	cmp    $0x25,%eax
 3d1:	75 ce                	jne    3a1 <printf+0x1b>
        state = '%';
 3d3:	89 c6                	mov    %eax,%esi
 3d5:	eb db                	jmp    3b2 <printf+0x2c>
      if(c == 'd'){
 3d7:	83 f8 64             	cmp    $0x64,%eax
 3da:	74 49                	je     425 <printf+0x9f>
        printint(fd, *ap, 10, 1);
        ap++;
      } else if(c == 'x' || c == 'p'){
 3dc:	83 f8 78             	cmp    $0x78,%eax
 3df:	0f 94 c1             	sete   %cl
 3e2:	83 f8 70             	cmp    $0x70,%eax
 3e5:	0f 94 c2             	sete   %dl
 3e8:	08 d1                	or     %dl,%cl
 3ea:	75 63                	jne    44f <printf+0xc9>
        printint(fd, *ap, 16, 0);
        ap++;
      } else if(c == 's'){
 3ec:	83 f8 73             	cmp    $0x73,%eax
 3ef:	0f 84 84 00 00 00    	je     479 <printf+0xf3>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 3f5:	83 f8 63             	cmp    $0x63,%eax
 3f8:	0f 84 b7 00 00 00    	je     4b5 <printf+0x12f>
        putc(fd, *ap);
        ap++;
      } else if(c == '%'){
 3fe:	83 f8 25             	cmp    $0x25,%eax
 401:	0f 84 cc 00 00 00    	je     4d3 <printf+0x14d>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 407:	ba 25 00 00 00       	mov    $0x25,%edx
 40c:	8b 45 08             	mov    0x8(%ebp),%eax
 40f:	e8 d8 fe ff ff       	call   2ec <putc>
        putc(fd, c);
 414:	89 fa                	mov    %edi,%edx
 416:	8b 45 08             	mov    0x8(%ebp),%eax
 419:	e8 ce fe ff ff       	call   2ec <putc>
      }
      state = 0;
 41e:	be 00 00 00 00       	mov    $0x0,%esi
 423:	eb 8d                	jmp    3b2 <printf+0x2c>
        printint(fd, *ap, 10, 1);
 425:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 428:	8b 17                	mov    (%edi),%edx
 42a:	83 ec 0c             	sub    $0xc,%esp
 42d:	6a 01                	push   $0x1
 42f:	b9 0a 00 00 00       	mov    $0xa,%ecx
 434:	8b 45 08             	mov    0x8(%ebp),%eax
 437:	e8 ca fe ff ff       	call   306 <printint>
        ap++;
 43c:	83 c7 04             	add    $0x4,%edi
 43f:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 442:	83 c4 10             	add    $0x10,%esp
      state = 0;
 445:	be 00 00 00 00       	mov    $0x0,%esi
 44a:	e9 63 ff ff ff       	jmp    3b2 <printf+0x2c>
        printint(fd, *ap, 16, 0);
 44f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 452:	8b 17                	mov    (%edi),%edx
 454:	83 ec 0c             	sub    $0xc,%esp
 457:	6a 00                	push   $0x0
 459:	b9 10 00 00 00       	mov    $0x10,%ecx
 45e:	8b 45 08             	mov    0x8(%ebp),%eax
 461:	e8 a0 fe ff ff       	call   306 <printint>
        ap++;
 466:	83 c7 04             	add    $0x4,%edi
 469:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 46c:	83 c4 10             	add    $0x10,%esp
      state = 0;
 46f:	be 00 00 00 00       	mov    $0x0,%esi
 474:	e9 39 ff ff ff       	jmp    3b2 <printf+0x2c>
        s = (char*)*ap;
 479:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 47c:	8b 30                	mov    (%eax),%esi
        ap++;
 47e:	83 c0 04             	add    $0x4,%eax
 481:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        if(s == 0)
 484:	85 f6                	test   %esi,%esi
 486:	75 28                	jne    4b0 <printf+0x12a>
          s = "(null)";
 488:	be 6d 06 00 00       	mov    $0x66d,%esi
 48d:	8b 7d 08             	mov    0x8(%ebp),%edi
 490:	eb 0d                	jmp    49f <printf+0x119>
          putc(fd, *s);
 492:	0f be d2             	movsbl %dl,%edx
 495:	89 f8                	mov    %edi,%eax
 497:	e8 50 fe ff ff       	call   2ec <putc>
          s++;
 49c:	83 c6 01             	add    $0x1,%esi
        while(*s != 0){
 49f:	0f b6 16             	movzbl (%esi),%edx
 4a2:	84 d2                	test   %dl,%dl
 4a4:	75 ec                	jne    492 <printf+0x10c>
      state = 0;
 4a6:	be 00 00 00 00       	mov    $0x0,%esi
 4ab:	e9 02 ff ff ff       	jmp    3b2 <printf+0x2c>
 4b0:	8b 7d 08             	mov    0x8(%ebp),%edi
 4b3:	eb ea                	jmp    49f <printf+0x119>
        putc(fd, *ap);
 4b5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 4b8:	0f be 17             	movsbl (%edi),%edx
 4bb:	8b 45 08             	mov    0x8(%ebp),%eax
 4be:	e8 29 fe ff ff       	call   2ec <putc>
        ap++;
 4c3:	83 c7 04             	add    $0x4,%edi
 4c6:	89 7d e4             	mov    %edi,-0x1c(%ebp)
      state = 0;
 4c9:	be 00 00 00 00       	mov    $0x0,%esi
 4ce:	e9 df fe ff ff       	jmp    3b2 <printf+0x2c>
        putc(fd, c);
 4d3:	89 fa                	mov    %edi,%edx
 4d5:	8b 45 08             	mov    0x8(%ebp),%eax
 4d8:	e8 0f fe ff ff       	call   2ec <putc>
      state = 0;
 4dd:	be 00 00 00 00       	mov    $0x0,%esi
 4e2:	e9 cb fe ff ff       	jmp    3b2 <printf+0x2c>
    }
  }
}
 4e7:	8d 65 f4             	lea    -0xc(%ebp),%esp
 4ea:	5b                   	pop    %ebx
 4eb:	5e                   	pop    %esi
 4ec:	5f                   	pop    %edi
 4ed:	5d                   	pop    %ebp
 4ee:	c3                   	ret    

000004ef <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 4ef:	55                   	push   %ebp
 4f0:	89 e5                	mov    %esp,%ebp
 4f2:	57                   	push   %edi
 4f3:	56                   	push   %esi
 4f4:	53                   	push   %ebx
 4f5:	8b 5d 08             	mov    0x8(%ebp),%ebx
  Header *bp, *p;

  bp = (Header*)ap - 1;
 4f8:	8d 4b f8             	lea    -0x8(%ebx),%ecx
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 4fb:	a1 18 09 00 00       	mov    0x918,%eax
 500:	eb 02                	jmp    504 <free+0x15>
 502:	89 d0                	mov    %edx,%eax
 504:	39 c8                	cmp    %ecx,%eax
 506:	73 04                	jae    50c <free+0x1d>
 508:	39 08                	cmp    %ecx,(%eax)
 50a:	77 12                	ja     51e <free+0x2f>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 50c:	8b 10                	mov    (%eax),%edx
 50e:	39 c2                	cmp    %eax,%edx
 510:	77 f0                	ja     502 <free+0x13>
 512:	39 c8                	cmp    %ecx,%eax
 514:	72 08                	jb     51e <free+0x2f>
 516:	39 ca                	cmp    %ecx,%edx
 518:	77 04                	ja     51e <free+0x2f>
 51a:	89 d0                	mov    %edx,%eax
 51c:	eb e6                	jmp    504 <free+0x15>
      break;
  if(bp + bp->s.size == p->s.ptr){
 51e:	8b 73 fc             	mov    -0x4(%ebx),%esi
 521:	8d 3c f1             	lea    (%ecx,%esi,8),%edi
 524:	8b 10                	mov    (%eax),%edx
 526:	39 d7                	cmp    %edx,%edi
 528:	74 19                	je     543 <free+0x54>
    bp->s.size += p->s.ptr->s.size;
    bp->s.ptr = p->s.ptr->s.ptr;
  } else
    bp->s.ptr = p->s.ptr;
 52a:	89 53 f8             	mov    %edx,-0x8(%ebx)
  if(p + p->s.size == bp){
 52d:	8b 50 04             	mov    0x4(%eax),%edx
 530:	8d 34 d0             	lea    (%eax,%edx,8),%esi
 533:	39 ce                	cmp    %ecx,%esi
 535:	74 1b                	je     552 <free+0x63>
    p->s.size += bp->s.size;
    p->s.ptr = bp->s.ptr;
  } else
    p->s.ptr = bp;
 537:	89 08                	mov    %ecx,(%eax)
  freep = p;
 539:	a3 18 09 00 00       	mov    %eax,0x918
}
 53e:	5b                   	pop    %ebx
 53f:	5e                   	pop    %esi
 540:	5f                   	pop    %edi
 541:	5d                   	pop    %ebp
 542:	c3                   	ret    
    bp->s.size += p->s.ptr->s.size;
 543:	03 72 04             	add    0x4(%edx),%esi
 546:	89 73 fc             	mov    %esi,-0x4(%ebx)
    bp->s.ptr = p->s.ptr->s.ptr;
 549:	8b 10                	mov    (%eax),%edx
 54b:	8b 12                	mov    (%edx),%edx
 54d:	89 53 f8             	mov    %edx,-0x8(%ebx)
 550:	eb db                	jmp    52d <free+0x3e>
    p->s.size += bp->s.size;
 552:	03 53 fc             	add    -0x4(%ebx),%edx
 555:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 558:	8b 53 f8             	mov    -0x8(%ebx),%edx
 55b:	89 10                	mov    %edx,(%eax)
 55d:	eb da                	jmp    539 <free+0x4a>

0000055f <morecore>:

static Header*
morecore(uint nu)
{
 55f:	55                   	push   %ebp
 560:	89 e5                	mov    %esp,%ebp
 562:	53                   	push   %ebx
 563:	83 ec 04             	sub    $0x4,%esp
 566:	89 c3                	mov    %eax,%ebx
  char *p;
  Header *hp;

  if(nu < 4096)
 568:	3d ff 0f 00 00       	cmp    $0xfff,%eax
 56d:	77 05                	ja     574 <morecore+0x15>
    nu = 4096;
 56f:	bb 00 10 00 00       	mov    $0x1000,%ebx
  p = sbrk(nu * sizeof(Header));
 574:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
 57b:	83 ec 0c             	sub    $0xc,%esp
 57e:	50                   	push   %eax
 57f:	e8 50 fd ff ff       	call   2d4 <sbrk>
  if(p == (char*)-1)
 584:	83 c4 10             	add    $0x10,%esp
 587:	83 f8 ff             	cmp    $0xffffffff,%eax
 58a:	74 1c                	je     5a8 <morecore+0x49>
    return 0;
  hp = (Header*)p;
  hp->s.size = nu;
 58c:	89 58 04             	mov    %ebx,0x4(%eax)
  free((void*)(hp + 1));
 58f:	83 c0 08             	add    $0x8,%eax
 592:	83 ec 0c             	sub    $0xc,%esp
 595:	50                   	push   %eax
 596:	e8 54 ff ff ff       	call   4ef <free>
  return freep;
 59b:	a1 18 09 00 00       	mov    0x918,%eax
 5a0:	83 c4 10             	add    $0x10,%esp
}
 5a3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
 5a6:	c9                   	leave  
 5a7:	c3                   	ret    
    return 0;
 5a8:	b8 00 00 00 00       	mov    $0x0,%eax
 5ad:	eb f4                	jmp    5a3 <morecore+0x44>

000005af <malloc>:

void*
malloc(uint nbytes)
{
 5af:	55                   	push   %ebp
 5b0:	89 e5                	mov    %esp,%ebp
 5b2:	53                   	push   %ebx
 5b3:	83 ec 04             	sub    $0x4,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 5b6:	8b 45 08             	mov    0x8(%ebp),%eax
 5b9:	8d 58 07             	lea    0x7(%eax),%ebx
 5bc:	c1 eb 03             	shr    $0x3,%ebx
 5bf:	83 c3 01             	add    $0x1,%ebx
  if((prevp = freep) == 0){
 5c2:	8b 0d 18 09 00 00    	mov    0x918,%ecx
 5c8:	85 c9                	test   %ecx,%ecx
 5ca:	74 04                	je     5d0 <malloc+0x21>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 5cc:	8b 01                	mov    (%ecx),%eax
 5ce:	eb 4d                	jmp    61d <malloc+0x6e>
    base.s.ptr = freep = prevp = &base;
 5d0:	c7 05 18 09 00 00 1c 	movl   $0x91c,0x918
 5d7:	09 00 00 
 5da:	c7 05 1c 09 00 00 1c 	movl   $0x91c,0x91c
 5e1:	09 00 00 
    base.s.size = 0;
 5e4:	c7 05 20 09 00 00 00 	movl   $0x0,0x920
 5eb:	00 00 00 
    base.s.ptr = freep = prevp = &base;
 5ee:	b9 1c 09 00 00       	mov    $0x91c,%ecx
 5f3:	eb d7                	jmp    5cc <malloc+0x1d>
    if(p->s.size >= nunits){
      if(p->s.size == nunits)
 5f5:	39 da                	cmp    %ebx,%edx
 5f7:	74 1a                	je     613 <malloc+0x64>
        prevp->s.ptr = p->s.ptr;
      else {
        p->s.size -= nunits;
 5f9:	29 da                	sub    %ebx,%edx
 5fb:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 5fe:	8d 04 d0             	lea    (%eax,%edx,8),%eax
        p->s.size = nunits;
 601:	89 58 04             	mov    %ebx,0x4(%eax)
      }
      freep = prevp;
 604:	89 0d 18 09 00 00    	mov    %ecx,0x918
      return (void*)(p + 1);
 60a:	83 c0 08             	add    $0x8,%eax
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 60d:	83 c4 04             	add    $0x4,%esp
 610:	5b                   	pop    %ebx
 611:	5d                   	pop    %ebp
 612:	c3                   	ret    
        prevp->s.ptr = p->s.ptr;
 613:	8b 10                	mov    (%eax),%edx
 615:	89 11                	mov    %edx,(%ecx)
 617:	eb eb                	jmp    604 <malloc+0x55>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 619:	89 c1                	mov    %eax,%ecx
 61b:	8b 00                	mov    (%eax),%eax
    if(p->s.size >= nunits){
 61d:	8b 50 04             	mov    0x4(%eax),%edx
 620:	39 da                	cmp    %ebx,%edx
 622:	73 d1                	jae    5f5 <malloc+0x46>
    if(p == freep)
 624:	39 05 18 09 00 00    	cmp    %eax,0x918
 62a:	75 ed                	jne    619 <malloc+0x6a>
      if((p = morecore(nunits)) == 0)
 62c:	89 d8                	mov    %ebx,%eax
 62e:	e8 2c ff ff ff       	call   55f <morecore>
 633:	85 c0                	test   %eax,%eax
 635:	75 e2                	jne    619 <malloc+0x6a>
        return 0;
 637:	b8 00 00 00 00       	mov    $0x0,%eax
 63c:	eb cf                	jmp    60d <malloc+0x5e>
