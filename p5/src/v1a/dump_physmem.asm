
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
  11:	81 ec a8 01 00 00    	sub    $0x1a8,%esp
  int numframes = 100;
  int frames[numframes];
  17:	89 e2                	mov    %esp,%edx
  19:	89 d3                	mov    %edx,%ebx
  int pids[numframes];
  1b:	81 ec a0 01 00 00    	sub    $0x1a0,%esp
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
  3d:	83 f8 63             	cmp    $0x63,%eax
  40:	7e ea                	jle    2c <main+0x2c>
  }
  
  int result = dump_physmem(frames, pids, numframes);
  42:	83 ec 04             	sub    $0x4,%esp
  45:	6a 64                	push   $0x64
  47:	51                   	push   %ecx
  48:	52                   	push   %edx
  49:	e8 26 02 00 00       	call   274 <dump_physmem>
  4e:	89 c7                	mov    %eax,%edi
  if(result == 0){
  50:	83 c4 10             	add    $0x10,%esp
  53:	85 c0                	test   %eax,%eax
  55:	75 44                	jne    9b <main+0x9b>
	  printf(2, "succeed\n");
  57:	83 ec 08             	sub    $0x8,%esp
  5a:	68 38 06 00 00       	push   $0x638
  5f:	6a 02                	push   $0x2
  61:	e8 18 03 00 00       	call   37e <printf>
	  for(int i=0; i<numframes; i++){
  66:	83 c4 10             	add    $0x10,%esp
  69:	eb 26                	jmp    91 <main+0x91>
	    printf(2, "frames[%d]: %d\n", i,  frames[i]);
  6b:	ff 34 bb             	pushl  (%ebx,%edi,4)
  6e:	57                   	push   %edi
  6f:	68 41 06 00 00       	push   $0x641
  74:	6a 02                	push   $0x2
  76:	e8 03 03 00 00       	call   37e <printf>
	    printf(2, "pids[%d]: %d\n", i, pids[i]);
  7b:	ff 34 be             	pushl  (%esi,%edi,4)
  7e:	57                   	push   %edi
  7f:	68 51 06 00 00       	push   $0x651
  84:	6a 02                	push   $0x2
  86:	e8 f3 02 00 00       	call   37e <printf>
	  for(int i=0; i<numframes; i++){
  8b:	83 c7 01             	add    $0x1,%edi
  8e:	83 c4 20             	add    $0x20,%esp
  91:	83 ff 63             	cmp    $0x63,%edi
  94:	7e d5                	jle    6b <main+0x6b>
	  }
  }
  else{
	  printf(2, "fail\n");
  }
  exit();
  96:	e8 a1 01 00 00       	call   23c <exit>
	  printf(2, "fail\n");
  9b:	83 ec 08             	sub    $0x8,%esp
  9e:	68 5f 06 00 00       	push   $0x65f
  a3:	6a 02                	push   $0x2
  a5:	e8 d4 02 00 00       	call   37e <printf>
  aa:	83 c4 10             	add    $0x10,%esp
  ad:	eb e7                	jmp    96 <main+0x96>

000000af <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, const char *t)
{
  af:	55                   	push   %ebp
  b0:	89 e5                	mov    %esp,%ebp
  b2:	53                   	push   %ebx
  b3:	8b 45 08             	mov    0x8(%ebp),%eax
  b6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  b9:	89 c2                	mov    %eax,%edx
  bb:	0f b6 19             	movzbl (%ecx),%ebx
  be:	88 1a                	mov    %bl,(%edx)
  c0:	8d 52 01             	lea    0x1(%edx),%edx
  c3:	8d 49 01             	lea    0x1(%ecx),%ecx
  c6:	84 db                	test   %bl,%bl
  c8:	75 f1                	jne    bb <strcpy+0xc>
    ;
  return os;
}
  ca:	5b                   	pop    %ebx
  cb:	5d                   	pop    %ebp
  cc:	c3                   	ret    

000000cd <strcmp>:

int
strcmp(const char *p, const char *q)
{
  cd:	55                   	push   %ebp
  ce:	89 e5                	mov    %esp,%ebp
  d0:	8b 4d 08             	mov    0x8(%ebp),%ecx
  d3:	8b 55 0c             	mov    0xc(%ebp),%edx
  while(*p && *p == *q)
  d6:	eb 06                	jmp    de <strcmp+0x11>
    p++, q++;
  d8:	83 c1 01             	add    $0x1,%ecx
  db:	83 c2 01             	add    $0x1,%edx
  while(*p && *p == *q)
  de:	0f b6 01             	movzbl (%ecx),%eax
  e1:	84 c0                	test   %al,%al
  e3:	74 04                	je     e9 <strcmp+0x1c>
  e5:	3a 02                	cmp    (%edx),%al
  e7:	74 ef                	je     d8 <strcmp+0xb>
  return (uchar)*p - (uchar)*q;
  e9:	0f b6 c0             	movzbl %al,%eax
  ec:	0f b6 12             	movzbl (%edx),%edx
  ef:	29 d0                	sub    %edx,%eax
}
  f1:	5d                   	pop    %ebp
  f2:	c3                   	ret    

000000f3 <strlen>:

uint
strlen(const char *s)
{
  f3:	55                   	push   %ebp
  f4:	89 e5                	mov    %esp,%ebp
  f6:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int n;

  for(n = 0; s[n]; n++)
  f9:	ba 00 00 00 00       	mov    $0x0,%edx
  fe:	eb 03                	jmp    103 <strlen+0x10>
 100:	83 c2 01             	add    $0x1,%edx
 103:	89 d0                	mov    %edx,%eax
 105:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
 109:	75 f5                	jne    100 <strlen+0xd>
    ;
  return n;
}
 10b:	5d                   	pop    %ebp
 10c:	c3                   	ret    

0000010d <memset>:

void*
memset(void *dst, int c, uint n)
{
 10d:	55                   	push   %ebp
 10e:	89 e5                	mov    %esp,%ebp
 110:	57                   	push   %edi
 111:	8b 55 08             	mov    0x8(%ebp),%edx
}

static inline void
stosb(void *addr, int data, int cnt)
{
  asm volatile("cld; rep stosb" :
 114:	89 d7                	mov    %edx,%edi
 116:	8b 4d 10             	mov    0x10(%ebp),%ecx
 119:	8b 45 0c             	mov    0xc(%ebp),%eax
 11c:	fc                   	cld    
 11d:	f3 aa                	rep stos %al,%es:(%edi)
  stosb(dst, c, n);
  return dst;
}
 11f:	89 d0                	mov    %edx,%eax
 121:	5f                   	pop    %edi
 122:	5d                   	pop    %ebp
 123:	c3                   	ret    

00000124 <strchr>:

char*
strchr(const char *s, char c)
{
 124:	55                   	push   %ebp
 125:	89 e5                	mov    %esp,%ebp
 127:	8b 45 08             	mov    0x8(%ebp),%eax
 12a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
  for(; *s; s++)
 12e:	0f b6 10             	movzbl (%eax),%edx
 131:	84 d2                	test   %dl,%dl
 133:	74 09                	je     13e <strchr+0x1a>
    if(*s == c)
 135:	38 ca                	cmp    %cl,%dl
 137:	74 0a                	je     143 <strchr+0x1f>
  for(; *s; s++)
 139:	83 c0 01             	add    $0x1,%eax
 13c:	eb f0                	jmp    12e <strchr+0xa>
      return (char*)s;
  return 0;
 13e:	b8 00 00 00 00       	mov    $0x0,%eax
}
 143:	5d                   	pop    %ebp
 144:	c3                   	ret    

00000145 <gets>:

char*
gets(char *buf, int max)
{
 145:	55                   	push   %ebp
 146:	89 e5                	mov    %esp,%ebp
 148:	57                   	push   %edi
 149:	56                   	push   %esi
 14a:	53                   	push   %ebx
 14b:	83 ec 1c             	sub    $0x1c,%esp
 14e:	8b 7d 08             	mov    0x8(%ebp),%edi
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 151:	bb 00 00 00 00       	mov    $0x0,%ebx
 156:	8d 73 01             	lea    0x1(%ebx),%esi
 159:	3b 75 0c             	cmp    0xc(%ebp),%esi
 15c:	7d 2e                	jge    18c <gets+0x47>
    cc = read(0, &c, 1);
 15e:	83 ec 04             	sub    $0x4,%esp
 161:	6a 01                	push   $0x1
 163:	8d 45 e7             	lea    -0x19(%ebp),%eax
 166:	50                   	push   %eax
 167:	6a 00                	push   $0x0
 169:	e8 e6 00 00 00       	call   254 <read>
    if(cc < 1)
 16e:	83 c4 10             	add    $0x10,%esp
 171:	85 c0                	test   %eax,%eax
 173:	7e 17                	jle    18c <gets+0x47>
      break;
    buf[i++] = c;
 175:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
 179:	88 04 1f             	mov    %al,(%edi,%ebx,1)
    if(c == '\n' || c == '\r')
 17c:	3c 0a                	cmp    $0xa,%al
 17e:	0f 94 c2             	sete   %dl
 181:	3c 0d                	cmp    $0xd,%al
 183:	0f 94 c0             	sete   %al
    buf[i++] = c;
 186:	89 f3                	mov    %esi,%ebx
    if(c == '\n' || c == '\r')
 188:	08 c2                	or     %al,%dl
 18a:	74 ca                	je     156 <gets+0x11>
      break;
  }
  buf[i] = '\0';
 18c:	c6 04 1f 00          	movb   $0x0,(%edi,%ebx,1)
  return buf;
}
 190:	89 f8                	mov    %edi,%eax
 192:	8d 65 f4             	lea    -0xc(%ebp),%esp
 195:	5b                   	pop    %ebx
 196:	5e                   	pop    %esi
 197:	5f                   	pop    %edi
 198:	5d                   	pop    %ebp
 199:	c3                   	ret    

0000019a <stat>:

int
stat(const char *n, struct stat *st)
{
 19a:	55                   	push   %ebp
 19b:	89 e5                	mov    %esp,%ebp
 19d:	56                   	push   %esi
 19e:	53                   	push   %ebx
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 19f:	83 ec 08             	sub    $0x8,%esp
 1a2:	6a 00                	push   $0x0
 1a4:	ff 75 08             	pushl  0x8(%ebp)
 1a7:	e8 d8 00 00 00       	call   284 <open>
  if(fd < 0)
 1ac:	83 c4 10             	add    $0x10,%esp
 1af:	85 c0                	test   %eax,%eax
 1b1:	78 24                	js     1d7 <stat+0x3d>
 1b3:	89 c3                	mov    %eax,%ebx
    return -1;
  r = fstat(fd, st);
 1b5:	83 ec 08             	sub    $0x8,%esp
 1b8:	ff 75 0c             	pushl  0xc(%ebp)
 1bb:	50                   	push   %eax
 1bc:	e8 db 00 00 00       	call   29c <fstat>
 1c1:	89 c6                	mov    %eax,%esi
  close(fd);
 1c3:	89 1c 24             	mov    %ebx,(%esp)
 1c6:	e8 99 00 00 00       	call   264 <close>
  return r;
 1cb:	83 c4 10             	add    $0x10,%esp
}
 1ce:	89 f0                	mov    %esi,%eax
 1d0:	8d 65 f8             	lea    -0x8(%ebp),%esp
 1d3:	5b                   	pop    %ebx
 1d4:	5e                   	pop    %esi
 1d5:	5d                   	pop    %ebp
 1d6:	c3                   	ret    
    return -1;
 1d7:	be ff ff ff ff       	mov    $0xffffffff,%esi
 1dc:	eb f0                	jmp    1ce <stat+0x34>

000001de <atoi>:

int
atoi(const char *s)
{
 1de:	55                   	push   %ebp
 1df:	89 e5                	mov    %esp,%ebp
 1e1:	53                   	push   %ebx
 1e2:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int n;

  n = 0;
 1e5:	b8 00 00 00 00       	mov    $0x0,%eax
  while('0' <= *s && *s <= '9')
 1ea:	eb 10                	jmp    1fc <atoi+0x1e>
    n = n*10 + *s++ - '0';
 1ec:	8d 1c 80             	lea    (%eax,%eax,4),%ebx
 1ef:	8d 04 1b             	lea    (%ebx,%ebx,1),%eax
 1f2:	83 c1 01             	add    $0x1,%ecx
 1f5:	0f be d2             	movsbl %dl,%edx
 1f8:	8d 44 02 d0          	lea    -0x30(%edx,%eax,1),%eax
  while('0' <= *s && *s <= '9')
 1fc:	0f b6 11             	movzbl (%ecx),%edx
 1ff:	8d 5a d0             	lea    -0x30(%edx),%ebx
 202:	80 fb 09             	cmp    $0x9,%bl
 205:	76 e5                	jbe    1ec <atoi+0xe>
  return n;
}
 207:	5b                   	pop    %ebx
 208:	5d                   	pop    %ebp
 209:	c3                   	ret    

0000020a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 20a:	55                   	push   %ebp
 20b:	89 e5                	mov    %esp,%ebp
 20d:	56                   	push   %esi
 20e:	53                   	push   %ebx
 20f:	8b 45 08             	mov    0x8(%ebp),%eax
 212:	8b 5d 0c             	mov    0xc(%ebp),%ebx
 215:	8b 55 10             	mov    0x10(%ebp),%edx
  char *dst;
  const char *src;

  dst = vdst;
 218:	89 c1                	mov    %eax,%ecx
  src = vsrc;
  while(n-- > 0)
 21a:	eb 0d                	jmp    229 <memmove+0x1f>
    *dst++ = *src++;
 21c:	0f b6 13             	movzbl (%ebx),%edx
 21f:	88 11                	mov    %dl,(%ecx)
 221:	8d 5b 01             	lea    0x1(%ebx),%ebx
 224:	8d 49 01             	lea    0x1(%ecx),%ecx
  while(n-- > 0)
 227:	89 f2                	mov    %esi,%edx
 229:	8d 72 ff             	lea    -0x1(%edx),%esi
 22c:	85 d2                	test   %edx,%edx
 22e:	7f ec                	jg     21c <memmove+0x12>
  return vdst;
}
 230:	5b                   	pop    %ebx
 231:	5e                   	pop    %esi
 232:	5d                   	pop    %ebp
 233:	c3                   	ret    

00000234 <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 234:	b8 01 00 00 00       	mov    $0x1,%eax
 239:	cd 40                	int    $0x40
 23b:	c3                   	ret    

0000023c <exit>:
SYSCALL(exit)
 23c:	b8 02 00 00 00       	mov    $0x2,%eax
 241:	cd 40                	int    $0x40
 243:	c3                   	ret    

00000244 <wait>:
SYSCALL(wait)
 244:	b8 03 00 00 00       	mov    $0x3,%eax
 249:	cd 40                	int    $0x40
 24b:	c3                   	ret    

0000024c <pipe>:
SYSCALL(pipe)
 24c:	b8 04 00 00 00       	mov    $0x4,%eax
 251:	cd 40                	int    $0x40
 253:	c3                   	ret    

00000254 <read>:
SYSCALL(read)
 254:	b8 05 00 00 00       	mov    $0x5,%eax
 259:	cd 40                	int    $0x40
 25b:	c3                   	ret    

0000025c <write>:
SYSCALL(write)
 25c:	b8 10 00 00 00       	mov    $0x10,%eax
 261:	cd 40                	int    $0x40
 263:	c3                   	ret    

00000264 <close>:
SYSCALL(close)
 264:	b8 15 00 00 00       	mov    $0x15,%eax
 269:	cd 40                	int    $0x40
 26b:	c3                   	ret    

0000026c <kill>:
SYSCALL(kill)
 26c:	b8 06 00 00 00       	mov    $0x6,%eax
 271:	cd 40                	int    $0x40
 273:	c3                   	ret    

00000274 <dump_physmem>:
SYSCALL(dump_physmem)
 274:	b8 16 00 00 00       	mov    $0x16,%eax
 279:	cd 40                	int    $0x40
 27b:	c3                   	ret    

0000027c <exec>:
SYSCALL(exec)
 27c:	b8 07 00 00 00       	mov    $0x7,%eax
 281:	cd 40                	int    $0x40
 283:	c3                   	ret    

00000284 <open>:
SYSCALL(open)
 284:	b8 0f 00 00 00       	mov    $0xf,%eax
 289:	cd 40                	int    $0x40
 28b:	c3                   	ret    

0000028c <mknod>:
SYSCALL(mknod)
 28c:	b8 11 00 00 00       	mov    $0x11,%eax
 291:	cd 40                	int    $0x40
 293:	c3                   	ret    

00000294 <unlink>:
SYSCALL(unlink)
 294:	b8 12 00 00 00       	mov    $0x12,%eax
 299:	cd 40                	int    $0x40
 29b:	c3                   	ret    

0000029c <fstat>:
SYSCALL(fstat)
 29c:	b8 08 00 00 00       	mov    $0x8,%eax
 2a1:	cd 40                	int    $0x40
 2a3:	c3                   	ret    

000002a4 <link>:
SYSCALL(link)
 2a4:	b8 13 00 00 00       	mov    $0x13,%eax
 2a9:	cd 40                	int    $0x40
 2ab:	c3                   	ret    

000002ac <mkdir>:
SYSCALL(mkdir)
 2ac:	b8 14 00 00 00       	mov    $0x14,%eax
 2b1:	cd 40                	int    $0x40
 2b3:	c3                   	ret    

000002b4 <chdir>:
SYSCALL(chdir)
 2b4:	b8 09 00 00 00       	mov    $0x9,%eax
 2b9:	cd 40                	int    $0x40
 2bb:	c3                   	ret    

000002bc <dup>:
SYSCALL(dup)
 2bc:	b8 0a 00 00 00       	mov    $0xa,%eax
 2c1:	cd 40                	int    $0x40
 2c3:	c3                   	ret    

000002c4 <getpid>:
SYSCALL(getpid)
 2c4:	b8 0b 00 00 00       	mov    $0xb,%eax
 2c9:	cd 40                	int    $0x40
 2cb:	c3                   	ret    

000002cc <sbrk>:
SYSCALL(sbrk)
 2cc:	b8 0c 00 00 00       	mov    $0xc,%eax
 2d1:	cd 40                	int    $0x40
 2d3:	c3                   	ret    

000002d4 <sleep>:
SYSCALL(sleep)
 2d4:	b8 0d 00 00 00       	mov    $0xd,%eax
 2d9:	cd 40                	int    $0x40
 2db:	c3                   	ret    

000002dc <uptime>:
SYSCALL(uptime)
 2dc:	b8 0e 00 00 00       	mov    $0xe,%eax
 2e1:	cd 40                	int    $0x40
 2e3:	c3                   	ret    

000002e4 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 2e4:	55                   	push   %ebp
 2e5:	89 e5                	mov    %esp,%ebp
 2e7:	83 ec 1c             	sub    $0x1c,%esp
 2ea:	88 55 f4             	mov    %dl,-0xc(%ebp)
  write(fd, &c, 1);
 2ed:	6a 01                	push   $0x1
 2ef:	8d 55 f4             	lea    -0xc(%ebp),%edx
 2f2:	52                   	push   %edx
 2f3:	50                   	push   %eax
 2f4:	e8 63 ff ff ff       	call   25c <write>
}
 2f9:	83 c4 10             	add    $0x10,%esp
 2fc:	c9                   	leave  
 2fd:	c3                   	ret    

000002fe <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 2fe:	55                   	push   %ebp
 2ff:	89 e5                	mov    %esp,%ebp
 301:	57                   	push   %edi
 302:	56                   	push   %esi
 303:	53                   	push   %ebx
 304:	83 ec 2c             	sub    $0x2c,%esp
 307:	89 c7                	mov    %eax,%edi
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 309:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
 30d:	0f 95 c3             	setne  %bl
 310:	89 d0                	mov    %edx,%eax
 312:	c1 e8 1f             	shr    $0x1f,%eax
 315:	84 c3                	test   %al,%bl
 317:	74 10                	je     329 <printint+0x2b>
    neg = 1;
    x = -xx;
 319:	f7 da                	neg    %edx
    neg = 1;
 31b:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
  } else {
    x = xx;
  }

  i = 0;
 322:	be 00 00 00 00       	mov    $0x0,%esi
 327:	eb 0b                	jmp    334 <printint+0x36>
  neg = 0;
 329:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
 330:	eb f0                	jmp    322 <printint+0x24>
  do{
    buf[i++] = digits[x % base];
 332:	89 c6                	mov    %eax,%esi
 334:	89 d0                	mov    %edx,%eax
 336:	ba 00 00 00 00       	mov    $0x0,%edx
 33b:	f7 f1                	div    %ecx
 33d:	89 c3                	mov    %eax,%ebx
 33f:	8d 46 01             	lea    0x1(%esi),%eax
 342:	0f b6 92 6c 06 00 00 	movzbl 0x66c(%edx),%edx
 349:	88 54 35 d8          	mov    %dl,-0x28(%ebp,%esi,1)
  }while((x /= base) != 0);
 34d:	89 da                	mov    %ebx,%edx
 34f:	85 db                	test   %ebx,%ebx
 351:	75 df                	jne    332 <printint+0x34>
 353:	89 c3                	mov    %eax,%ebx
  if(neg)
 355:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
 359:	74 16                	je     371 <printint+0x73>
    buf[i++] = '-';
 35b:	c6 44 05 d8 2d       	movb   $0x2d,-0x28(%ebp,%eax,1)
 360:	8d 5e 02             	lea    0x2(%esi),%ebx
 363:	eb 0c                	jmp    371 <printint+0x73>

  while(--i >= 0)
    putc(fd, buf[i]);
 365:	0f be 54 1d d8       	movsbl -0x28(%ebp,%ebx,1),%edx
 36a:	89 f8                	mov    %edi,%eax
 36c:	e8 73 ff ff ff       	call   2e4 <putc>
  while(--i >= 0)
 371:	83 eb 01             	sub    $0x1,%ebx
 374:	79 ef                	jns    365 <printint+0x67>
}
 376:	83 c4 2c             	add    $0x2c,%esp
 379:	5b                   	pop    %ebx
 37a:	5e                   	pop    %esi
 37b:	5f                   	pop    %edi
 37c:	5d                   	pop    %ebp
 37d:	c3                   	ret    

0000037e <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, const char *fmt, ...)
{
 37e:	55                   	push   %ebp
 37f:	89 e5                	mov    %esp,%ebp
 381:	57                   	push   %edi
 382:	56                   	push   %esi
 383:	53                   	push   %ebx
 384:	83 ec 1c             	sub    $0x1c,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
 387:	8d 45 10             	lea    0x10(%ebp),%eax
 38a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  state = 0;
 38d:	be 00 00 00 00       	mov    $0x0,%esi
  for(i = 0; fmt[i]; i++){
 392:	bb 00 00 00 00       	mov    $0x0,%ebx
 397:	eb 14                	jmp    3ad <printf+0x2f>
    c = fmt[i] & 0xff;
    if(state == 0){
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
 399:	89 fa                	mov    %edi,%edx
 39b:	8b 45 08             	mov    0x8(%ebp),%eax
 39e:	e8 41 ff ff ff       	call   2e4 <putc>
 3a3:	eb 05                	jmp    3aa <printf+0x2c>
      }
    } else if(state == '%'){
 3a5:	83 fe 25             	cmp    $0x25,%esi
 3a8:	74 25                	je     3cf <printf+0x51>
  for(i = 0; fmt[i]; i++){
 3aa:	83 c3 01             	add    $0x1,%ebx
 3ad:	8b 45 0c             	mov    0xc(%ebp),%eax
 3b0:	0f b6 04 18          	movzbl (%eax,%ebx,1),%eax
 3b4:	84 c0                	test   %al,%al
 3b6:	0f 84 23 01 00 00    	je     4df <printf+0x161>
    c = fmt[i] & 0xff;
 3bc:	0f be f8             	movsbl %al,%edi
 3bf:	0f b6 c0             	movzbl %al,%eax
    if(state == 0){
 3c2:	85 f6                	test   %esi,%esi
 3c4:	75 df                	jne    3a5 <printf+0x27>
      if(c == '%'){
 3c6:	83 f8 25             	cmp    $0x25,%eax
 3c9:	75 ce                	jne    399 <printf+0x1b>
        state = '%';
 3cb:	89 c6                	mov    %eax,%esi
 3cd:	eb db                	jmp    3aa <printf+0x2c>
      if(c == 'd'){
 3cf:	83 f8 64             	cmp    $0x64,%eax
 3d2:	74 49                	je     41d <printf+0x9f>
        printint(fd, *ap, 10, 1);
        ap++;
      } else if(c == 'x' || c == 'p'){
 3d4:	83 f8 78             	cmp    $0x78,%eax
 3d7:	0f 94 c1             	sete   %cl
 3da:	83 f8 70             	cmp    $0x70,%eax
 3dd:	0f 94 c2             	sete   %dl
 3e0:	08 d1                	or     %dl,%cl
 3e2:	75 63                	jne    447 <printf+0xc9>
        printint(fd, *ap, 16, 0);
        ap++;
      } else if(c == 's'){
 3e4:	83 f8 73             	cmp    $0x73,%eax
 3e7:	0f 84 84 00 00 00    	je     471 <printf+0xf3>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 3ed:	83 f8 63             	cmp    $0x63,%eax
 3f0:	0f 84 b7 00 00 00    	je     4ad <printf+0x12f>
        putc(fd, *ap);
        ap++;
      } else if(c == '%'){
 3f6:	83 f8 25             	cmp    $0x25,%eax
 3f9:	0f 84 cc 00 00 00    	je     4cb <printf+0x14d>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 3ff:	ba 25 00 00 00       	mov    $0x25,%edx
 404:	8b 45 08             	mov    0x8(%ebp),%eax
 407:	e8 d8 fe ff ff       	call   2e4 <putc>
        putc(fd, c);
 40c:	89 fa                	mov    %edi,%edx
 40e:	8b 45 08             	mov    0x8(%ebp),%eax
 411:	e8 ce fe ff ff       	call   2e4 <putc>
      }
      state = 0;
 416:	be 00 00 00 00       	mov    $0x0,%esi
 41b:	eb 8d                	jmp    3aa <printf+0x2c>
        printint(fd, *ap, 10, 1);
 41d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 420:	8b 17                	mov    (%edi),%edx
 422:	83 ec 0c             	sub    $0xc,%esp
 425:	6a 01                	push   $0x1
 427:	b9 0a 00 00 00       	mov    $0xa,%ecx
 42c:	8b 45 08             	mov    0x8(%ebp),%eax
 42f:	e8 ca fe ff ff       	call   2fe <printint>
        ap++;
 434:	83 c7 04             	add    $0x4,%edi
 437:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 43a:	83 c4 10             	add    $0x10,%esp
      state = 0;
 43d:	be 00 00 00 00       	mov    $0x0,%esi
 442:	e9 63 ff ff ff       	jmp    3aa <printf+0x2c>
        printint(fd, *ap, 16, 0);
 447:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 44a:	8b 17                	mov    (%edi),%edx
 44c:	83 ec 0c             	sub    $0xc,%esp
 44f:	6a 00                	push   $0x0
 451:	b9 10 00 00 00       	mov    $0x10,%ecx
 456:	8b 45 08             	mov    0x8(%ebp),%eax
 459:	e8 a0 fe ff ff       	call   2fe <printint>
        ap++;
 45e:	83 c7 04             	add    $0x4,%edi
 461:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 464:	83 c4 10             	add    $0x10,%esp
      state = 0;
 467:	be 00 00 00 00       	mov    $0x0,%esi
 46c:	e9 39 ff ff ff       	jmp    3aa <printf+0x2c>
        s = (char*)*ap;
 471:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 474:	8b 30                	mov    (%eax),%esi
        ap++;
 476:	83 c0 04             	add    $0x4,%eax
 479:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        if(s == 0)
 47c:	85 f6                	test   %esi,%esi
 47e:	75 28                	jne    4a8 <printf+0x12a>
          s = "(null)";
 480:	be 65 06 00 00       	mov    $0x665,%esi
 485:	8b 7d 08             	mov    0x8(%ebp),%edi
 488:	eb 0d                	jmp    497 <printf+0x119>
          putc(fd, *s);
 48a:	0f be d2             	movsbl %dl,%edx
 48d:	89 f8                	mov    %edi,%eax
 48f:	e8 50 fe ff ff       	call   2e4 <putc>
          s++;
 494:	83 c6 01             	add    $0x1,%esi
        while(*s != 0){
 497:	0f b6 16             	movzbl (%esi),%edx
 49a:	84 d2                	test   %dl,%dl
 49c:	75 ec                	jne    48a <printf+0x10c>
      state = 0;
 49e:	be 00 00 00 00       	mov    $0x0,%esi
 4a3:	e9 02 ff ff ff       	jmp    3aa <printf+0x2c>
 4a8:	8b 7d 08             	mov    0x8(%ebp),%edi
 4ab:	eb ea                	jmp    497 <printf+0x119>
        putc(fd, *ap);
 4ad:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 4b0:	0f be 17             	movsbl (%edi),%edx
 4b3:	8b 45 08             	mov    0x8(%ebp),%eax
 4b6:	e8 29 fe ff ff       	call   2e4 <putc>
        ap++;
 4bb:	83 c7 04             	add    $0x4,%edi
 4be:	89 7d e4             	mov    %edi,-0x1c(%ebp)
      state = 0;
 4c1:	be 00 00 00 00       	mov    $0x0,%esi
 4c6:	e9 df fe ff ff       	jmp    3aa <printf+0x2c>
        putc(fd, c);
 4cb:	89 fa                	mov    %edi,%edx
 4cd:	8b 45 08             	mov    0x8(%ebp),%eax
 4d0:	e8 0f fe ff ff       	call   2e4 <putc>
      state = 0;
 4d5:	be 00 00 00 00       	mov    $0x0,%esi
 4da:	e9 cb fe ff ff       	jmp    3aa <printf+0x2c>
    }
  }
}
 4df:	8d 65 f4             	lea    -0xc(%ebp),%esp
 4e2:	5b                   	pop    %ebx
 4e3:	5e                   	pop    %esi
 4e4:	5f                   	pop    %edi
 4e5:	5d                   	pop    %ebp
 4e6:	c3                   	ret    

000004e7 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 4e7:	55                   	push   %ebp
 4e8:	89 e5                	mov    %esp,%ebp
 4ea:	57                   	push   %edi
 4eb:	56                   	push   %esi
 4ec:	53                   	push   %ebx
 4ed:	8b 5d 08             	mov    0x8(%ebp),%ebx
  Header *bp, *p;

  bp = (Header*)ap - 1;
 4f0:	8d 4b f8             	lea    -0x8(%ebx),%ecx
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 4f3:	a1 10 09 00 00       	mov    0x910,%eax
 4f8:	eb 02                	jmp    4fc <free+0x15>
 4fa:	89 d0                	mov    %edx,%eax
 4fc:	39 c8                	cmp    %ecx,%eax
 4fe:	73 04                	jae    504 <free+0x1d>
 500:	39 08                	cmp    %ecx,(%eax)
 502:	77 12                	ja     516 <free+0x2f>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 504:	8b 10                	mov    (%eax),%edx
 506:	39 c2                	cmp    %eax,%edx
 508:	77 f0                	ja     4fa <free+0x13>
 50a:	39 c8                	cmp    %ecx,%eax
 50c:	72 08                	jb     516 <free+0x2f>
 50e:	39 ca                	cmp    %ecx,%edx
 510:	77 04                	ja     516 <free+0x2f>
 512:	89 d0                	mov    %edx,%eax
 514:	eb e6                	jmp    4fc <free+0x15>
      break;
  if(bp + bp->s.size == p->s.ptr){
 516:	8b 73 fc             	mov    -0x4(%ebx),%esi
 519:	8d 3c f1             	lea    (%ecx,%esi,8),%edi
 51c:	8b 10                	mov    (%eax),%edx
 51e:	39 d7                	cmp    %edx,%edi
 520:	74 19                	je     53b <free+0x54>
    bp->s.size += p->s.ptr->s.size;
    bp->s.ptr = p->s.ptr->s.ptr;
  } else
    bp->s.ptr = p->s.ptr;
 522:	89 53 f8             	mov    %edx,-0x8(%ebx)
  if(p + p->s.size == bp){
 525:	8b 50 04             	mov    0x4(%eax),%edx
 528:	8d 34 d0             	lea    (%eax,%edx,8),%esi
 52b:	39 ce                	cmp    %ecx,%esi
 52d:	74 1b                	je     54a <free+0x63>
    p->s.size += bp->s.size;
    p->s.ptr = bp->s.ptr;
  } else
    p->s.ptr = bp;
 52f:	89 08                	mov    %ecx,(%eax)
  freep = p;
 531:	a3 10 09 00 00       	mov    %eax,0x910
}
 536:	5b                   	pop    %ebx
 537:	5e                   	pop    %esi
 538:	5f                   	pop    %edi
 539:	5d                   	pop    %ebp
 53a:	c3                   	ret    
    bp->s.size += p->s.ptr->s.size;
 53b:	03 72 04             	add    0x4(%edx),%esi
 53e:	89 73 fc             	mov    %esi,-0x4(%ebx)
    bp->s.ptr = p->s.ptr->s.ptr;
 541:	8b 10                	mov    (%eax),%edx
 543:	8b 12                	mov    (%edx),%edx
 545:	89 53 f8             	mov    %edx,-0x8(%ebx)
 548:	eb db                	jmp    525 <free+0x3e>
    p->s.size += bp->s.size;
 54a:	03 53 fc             	add    -0x4(%ebx),%edx
 54d:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 550:	8b 53 f8             	mov    -0x8(%ebx),%edx
 553:	89 10                	mov    %edx,(%eax)
 555:	eb da                	jmp    531 <free+0x4a>

00000557 <morecore>:

static Header*
morecore(uint nu)
{
 557:	55                   	push   %ebp
 558:	89 e5                	mov    %esp,%ebp
 55a:	53                   	push   %ebx
 55b:	83 ec 04             	sub    $0x4,%esp
 55e:	89 c3                	mov    %eax,%ebx
  char *p;
  Header *hp;

  if(nu < 4096)
 560:	3d ff 0f 00 00       	cmp    $0xfff,%eax
 565:	77 05                	ja     56c <morecore+0x15>
    nu = 4096;
 567:	bb 00 10 00 00       	mov    $0x1000,%ebx
  p = sbrk(nu * sizeof(Header));
 56c:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
 573:	83 ec 0c             	sub    $0xc,%esp
 576:	50                   	push   %eax
 577:	e8 50 fd ff ff       	call   2cc <sbrk>
  if(p == (char*)-1)
 57c:	83 c4 10             	add    $0x10,%esp
 57f:	83 f8 ff             	cmp    $0xffffffff,%eax
 582:	74 1c                	je     5a0 <morecore+0x49>
    return 0;
  hp = (Header*)p;
  hp->s.size = nu;
 584:	89 58 04             	mov    %ebx,0x4(%eax)
  free((void*)(hp + 1));
 587:	83 c0 08             	add    $0x8,%eax
 58a:	83 ec 0c             	sub    $0xc,%esp
 58d:	50                   	push   %eax
 58e:	e8 54 ff ff ff       	call   4e7 <free>
  return freep;
 593:	a1 10 09 00 00       	mov    0x910,%eax
 598:	83 c4 10             	add    $0x10,%esp
}
 59b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
 59e:	c9                   	leave  
 59f:	c3                   	ret    
    return 0;
 5a0:	b8 00 00 00 00       	mov    $0x0,%eax
 5a5:	eb f4                	jmp    59b <morecore+0x44>

000005a7 <malloc>:

void*
malloc(uint nbytes)
{
 5a7:	55                   	push   %ebp
 5a8:	89 e5                	mov    %esp,%ebp
 5aa:	53                   	push   %ebx
 5ab:	83 ec 04             	sub    $0x4,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 5ae:	8b 45 08             	mov    0x8(%ebp),%eax
 5b1:	8d 58 07             	lea    0x7(%eax),%ebx
 5b4:	c1 eb 03             	shr    $0x3,%ebx
 5b7:	83 c3 01             	add    $0x1,%ebx
  if((prevp = freep) == 0){
 5ba:	8b 0d 10 09 00 00    	mov    0x910,%ecx
 5c0:	85 c9                	test   %ecx,%ecx
 5c2:	74 04                	je     5c8 <malloc+0x21>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 5c4:	8b 01                	mov    (%ecx),%eax
 5c6:	eb 4d                	jmp    615 <malloc+0x6e>
    base.s.ptr = freep = prevp = &base;
 5c8:	c7 05 10 09 00 00 14 	movl   $0x914,0x910
 5cf:	09 00 00 
 5d2:	c7 05 14 09 00 00 14 	movl   $0x914,0x914
 5d9:	09 00 00 
    base.s.size = 0;
 5dc:	c7 05 18 09 00 00 00 	movl   $0x0,0x918
 5e3:	00 00 00 
    base.s.ptr = freep = prevp = &base;
 5e6:	b9 14 09 00 00       	mov    $0x914,%ecx
 5eb:	eb d7                	jmp    5c4 <malloc+0x1d>
    if(p->s.size >= nunits){
      if(p->s.size == nunits)
 5ed:	39 da                	cmp    %ebx,%edx
 5ef:	74 1a                	je     60b <malloc+0x64>
        prevp->s.ptr = p->s.ptr;
      else {
        p->s.size -= nunits;
 5f1:	29 da                	sub    %ebx,%edx
 5f3:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 5f6:	8d 04 d0             	lea    (%eax,%edx,8),%eax
        p->s.size = nunits;
 5f9:	89 58 04             	mov    %ebx,0x4(%eax)
      }
      freep = prevp;
 5fc:	89 0d 10 09 00 00    	mov    %ecx,0x910
      return (void*)(p + 1);
 602:	83 c0 08             	add    $0x8,%eax
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 605:	83 c4 04             	add    $0x4,%esp
 608:	5b                   	pop    %ebx
 609:	5d                   	pop    %ebp
 60a:	c3                   	ret    
        prevp->s.ptr = p->s.ptr;
 60b:	8b 10                	mov    (%eax),%edx
 60d:	89 11                	mov    %edx,(%ecx)
 60f:	eb eb                	jmp    5fc <malloc+0x55>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 611:	89 c1                	mov    %eax,%ecx
 613:	8b 00                	mov    (%eax),%eax
    if(p->s.size >= nunits){
 615:	8b 50 04             	mov    0x4(%eax),%edx
 618:	39 da                	cmp    %ebx,%edx
 61a:	73 d1                	jae    5ed <malloc+0x46>
    if(p == freep)
 61c:	39 05 10 09 00 00    	cmp    %eax,0x910
 622:	75 ed                	jne    611 <malloc+0x6a>
      if((p = morecore(nunits)) == 0)
 624:	89 d8                	mov    %ebx,%eax
 626:	e8 2c ff ff ff       	call   557 <morecore>
 62b:	85 c0                	test   %eax,%eax
 62d:	75 e2                	jne    611 <malloc+0x6a>
        return 0;
 62f:	b8 00 00 00 00       	mov    $0x0,%eax
 634:	eb cf                	jmp    605 <malloc+0x5e>
