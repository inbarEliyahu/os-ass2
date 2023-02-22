
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	92013103          	ld	sp,-1760(sp) # 80008920 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	2ec78793          	addi	a5,a5,748 # 80006350 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	e0478793          	addi	a5,a5,-508 # 80000eb2 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	a6a080e7          	jalr	-1430(ra) # 80002b96 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	c18080e7          	jalr	-1000(ra) # 80001ddc <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	4b6080e7          	jalr	1206(ra) # 8000268a <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00003097          	auipc	ra,0x3
    80000214:	930080e7          	jalr	-1744(ra) # 80002b40 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a7e080e7          	jalr	-1410(ra) # 80000caa <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a68080e7          	jalr	-1432(ra) # 80000caa <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00003097          	auipc	ra,0x3
    800002f6:	8fa080e7          	jalr	-1798(ra) # 80002bec <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	9a8080e7          	jalr	-1624(ra) # 80000caa <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	3ec080e7          	jalr	1004(ra) # 80002832 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	84878793          	addi	a5,a5,-1976 # 80021cc0 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b8c50513          	addi	a0,a0,-1140 # 800080f8 <digits+0xb8>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	546080e7          	jalr	1350(ra) # 80000caa <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	41c080e7          	jalr	1052(ra) # 80000c4a <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	f92080e7          	jalr	-110(ra) # 80002832 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	d5e080e7          	jalr	-674(ra) # 8000268a <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	342080e7          	jalr	834(ra) # 80000caa <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2c4080e7          	jalr	708(ra) # 80000caa <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2e0080e7          	jalr	736(ra) # 80000d04 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	260080e7          	jalr	608(ra) # 80000caa <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	18a080e7          	jalr	394(ra) # 80000caa <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1d6080e7          	jalr	470(ra) # 80000d04 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	160080e7          	jalr	352(ra) # 80000caa <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	23a080e7          	jalr	570(ra) # 80001db8 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	208080e7          	jalr	520(ra) # 80001db8 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	1fc080e7          	jalr	508(ra) # 80001db8 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	1e4080e7          	jalr	484(ra) # 80001db8 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk)){
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk)){
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	1a4080e7          	jalr	420(ra) # 80001db8 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    printf("lk is %s\n", lk->name);
    80000c28:	648c                	ld	a1,8(s1)
    80000c2a:	00007517          	auipc	a0,0x7
    80000c2e:	44650513          	addi	a0,a0,1094 # 80008070 <digits+0x30>
    80000c32:	00000097          	auipc	ra,0x0
    80000c36:	956080e7          	jalr	-1706(ra) # 80000588 <printf>
    panic("acquire");
    80000c3a:	00007517          	auipc	a0,0x7
    80000c3e:	44650513          	addi	a0,a0,1094 # 80008080 <digits+0x40>
    80000c42:	00000097          	auipc	ra,0x0
    80000c46:	8fc080e7          	jalr	-1796(ra) # 8000053e <panic>

0000000080000c4a <pop_off>:

void
pop_off(void)
{
    80000c4a:	1141                	addi	sp,sp,-16
    80000c4c:	e406                	sd	ra,8(sp)
    80000c4e:	e022                	sd	s0,0(sp)
    80000c50:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c52:	00001097          	auipc	ra,0x1
    80000c56:	166080e7          	jalr	358(ra) # 80001db8 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c5a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c5e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c60:	e78d                	bnez	a5,80000c8a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1){
    80000c62:	5d3c                	lw	a5,120(a0)
    80000c64:	02f05b63          	blez	a5,80000c9a <pop_off+0x50>
    panic("pop_off");}
  c->noff -= 1;
    80000c68:	37fd                	addiw	a5,a5,-1
    80000c6a:	0007871b          	sext.w	a4,a5
    80000c6e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c70:	eb09                	bnez	a4,80000c82 <pop_off+0x38>
    80000c72:	5d7c                	lw	a5,124(a0)
    80000c74:	c799                	beqz	a5,80000c82 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c76:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c7a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c7e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c82:	60a2                	ld	ra,8(sp)
    80000c84:	6402                	ld	s0,0(sp)
    80000c86:	0141                	addi	sp,sp,16
    80000c88:	8082                	ret
    panic("pop_off - interruptible");
    80000c8a:	00007517          	auipc	a0,0x7
    80000c8e:	3fe50513          	addi	a0,a0,1022 # 80008088 <digits+0x48>
    80000c92:	00000097          	auipc	ra,0x0
    80000c96:	8ac080e7          	jalr	-1876(ra) # 8000053e <panic>
    panic("pop_off");}
    80000c9a:	00007517          	auipc	a0,0x7
    80000c9e:	40650513          	addi	a0,a0,1030 # 800080a0 <digits+0x60>
    80000ca2:	00000097          	auipc	ra,0x0
    80000ca6:	89c080e7          	jalr	-1892(ra) # 8000053e <panic>

0000000080000caa <release>:
{
    80000caa:	1101                	addi	sp,sp,-32
    80000cac:	ec06                	sd	ra,24(sp)
    80000cae:	e822                	sd	s0,16(sp)
    80000cb0:	e426                	sd	s1,8(sp)
    80000cb2:	1000                	addi	s0,sp,32
    80000cb4:	84aa                	mv	s1,a0
  if(!holding(lk)){
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	eb4080e7          	jalr	-332(ra) # 80000b6a <holding>
    80000cbe:	c115                	beqz	a0,80000ce2 <release+0x38>
  lk->cpu = 0;
    80000cc0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cc4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cc8:	0f50000f          	fence	iorw,ow
    80000ccc:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	f7a080e7          	jalr	-134(ra) # 80000c4a <pop_off>
}
    80000cd8:	60e2                	ld	ra,24(sp)
    80000cda:	6442                	ld	s0,16(sp)
    80000cdc:	64a2                	ld	s1,8(sp)
    80000cde:	6105                	addi	sp,sp,32
    80000ce0:	8082                	ret
    printf("the paniced lock is r %s\n", lk->name);
    80000ce2:	648c                	ld	a1,8(s1)
    80000ce4:	00007517          	auipc	a0,0x7
    80000ce8:	3c450513          	addi	a0,a0,964 # 800080a8 <digits+0x68>
    80000cec:	00000097          	auipc	ra,0x0
    80000cf0:	89c080e7          	jalr	-1892(ra) # 80000588 <printf>
    panic("release");
    80000cf4:	00007517          	auipc	a0,0x7
    80000cf8:	3d450513          	addi	a0,a0,980 # 800080c8 <digits+0x88>
    80000cfc:	00000097          	auipc	ra,0x0
    80000d00:	842080e7          	jalr	-1982(ra) # 8000053e <panic>

0000000080000d04 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d04:	1141                	addi	sp,sp,-16
    80000d06:	e422                	sd	s0,8(sp)
    80000d08:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d0a:	ce09                	beqz	a2,80000d24 <memset+0x20>
    80000d0c:	87aa                	mv	a5,a0
    80000d0e:	fff6071b          	addiw	a4,a2,-1
    80000d12:	1702                	slli	a4,a4,0x20
    80000d14:	9301                	srli	a4,a4,0x20
    80000d16:	0705                	addi	a4,a4,1
    80000d18:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d1a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d1e:	0785                	addi	a5,a5,1
    80000d20:	fee79de3          	bne	a5,a4,80000d1a <memset+0x16>
  }
  return dst;
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret

0000000080000d2a <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d2a:	1141                	addi	sp,sp,-16
    80000d2c:	e422                	sd	s0,8(sp)
    80000d2e:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d30:	ca05                	beqz	a2,80000d60 <memcmp+0x36>
    80000d32:	fff6069b          	addiw	a3,a2,-1
    80000d36:	1682                	slli	a3,a3,0x20
    80000d38:	9281                	srli	a3,a3,0x20
    80000d3a:	0685                	addi	a3,a3,1
    80000d3c:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d3e:	00054783          	lbu	a5,0(a0)
    80000d42:	0005c703          	lbu	a4,0(a1)
    80000d46:	00e79863          	bne	a5,a4,80000d56 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d4a:	0505                	addi	a0,a0,1
    80000d4c:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d4e:	fed518e3          	bne	a0,a3,80000d3e <memcmp+0x14>
  }

  return 0;
    80000d52:	4501                	li	a0,0
    80000d54:	a019                	j	80000d5a <memcmp+0x30>
      return *s1 - *s2;
    80000d56:	40e7853b          	subw	a0,a5,a4
}
    80000d5a:	6422                	ld	s0,8(sp)
    80000d5c:	0141                	addi	sp,sp,16
    80000d5e:	8082                	ret
  return 0;
    80000d60:	4501                	li	a0,0
    80000d62:	bfe5                	j	80000d5a <memcmp+0x30>

0000000080000d64 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d64:	1141                	addi	sp,sp,-16
    80000d66:	e422                	sd	s0,8(sp)
    80000d68:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d6a:	ca0d                	beqz	a2,80000d9c <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d6c:	00a5f963          	bgeu	a1,a0,80000d7e <memmove+0x1a>
    80000d70:	02061693          	slli	a3,a2,0x20
    80000d74:	9281                	srli	a3,a3,0x20
    80000d76:	00d58733          	add	a4,a1,a3
    80000d7a:	02e56463          	bltu	a0,a4,80000da2 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d7e:	fff6079b          	addiw	a5,a2,-1
    80000d82:	1782                	slli	a5,a5,0x20
    80000d84:	9381                	srli	a5,a5,0x20
    80000d86:	0785                	addi	a5,a5,1
    80000d88:	97ae                	add	a5,a5,a1
    80000d8a:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d8c:	0585                	addi	a1,a1,1
    80000d8e:	0705                	addi	a4,a4,1
    80000d90:	fff5c683          	lbu	a3,-1(a1)
    80000d94:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d98:	fef59ae3          	bne	a1,a5,80000d8c <memmove+0x28>

  return dst;
}
    80000d9c:	6422                	ld	s0,8(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret
    d += n;
    80000da2:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000da4:	fff6079b          	addiw	a5,a2,-1
    80000da8:	1782                	slli	a5,a5,0x20
    80000daa:	9381                	srli	a5,a5,0x20
    80000dac:	fff7c793          	not	a5,a5
    80000db0:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000db2:	177d                	addi	a4,a4,-1
    80000db4:	16fd                	addi	a3,a3,-1
    80000db6:	00074603          	lbu	a2,0(a4)
    80000dba:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000dbe:	fef71ae3          	bne	a4,a5,80000db2 <memmove+0x4e>
    80000dc2:	bfe9                	j	80000d9c <memmove+0x38>

0000000080000dc4 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dc4:	1141                	addi	sp,sp,-16
    80000dc6:	e406                	sd	ra,8(sp)
    80000dc8:	e022                	sd	s0,0(sp)
    80000dca:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dcc:	00000097          	auipc	ra,0x0
    80000dd0:	f98080e7          	jalr	-104(ra) # 80000d64 <memmove>
}
    80000dd4:	60a2                	ld	ra,8(sp)
    80000dd6:	6402                	ld	s0,0(sp)
    80000dd8:	0141                	addi	sp,sp,16
    80000dda:	8082                	ret

0000000080000ddc <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000ddc:	1141                	addi	sp,sp,-16
    80000dde:	e422                	sd	s0,8(sp)
    80000de0:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000de2:	ce11                	beqz	a2,80000dfe <strncmp+0x22>
    80000de4:	00054783          	lbu	a5,0(a0)
    80000de8:	cf89                	beqz	a5,80000e02 <strncmp+0x26>
    80000dea:	0005c703          	lbu	a4,0(a1)
    80000dee:	00f71a63          	bne	a4,a5,80000e02 <strncmp+0x26>
    n--, p++, q++;
    80000df2:	367d                	addiw	a2,a2,-1
    80000df4:	0505                	addi	a0,a0,1
    80000df6:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000df8:	f675                	bnez	a2,80000de4 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dfa:	4501                	li	a0,0
    80000dfc:	a809                	j	80000e0e <strncmp+0x32>
    80000dfe:	4501                	li	a0,0
    80000e00:	a039                	j	80000e0e <strncmp+0x32>
  if(n == 0)
    80000e02:	ca09                	beqz	a2,80000e14 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e04:	00054503          	lbu	a0,0(a0)
    80000e08:	0005c783          	lbu	a5,0(a1)
    80000e0c:	9d1d                	subw	a0,a0,a5
}
    80000e0e:	6422                	ld	s0,8(sp)
    80000e10:	0141                	addi	sp,sp,16
    80000e12:	8082                	ret
    return 0;
    80000e14:	4501                	li	a0,0
    80000e16:	bfe5                	j	80000e0e <strncmp+0x32>

0000000080000e18 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e18:	1141                	addi	sp,sp,-16
    80000e1a:	e422                	sd	s0,8(sp)
    80000e1c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e1e:	872a                	mv	a4,a0
    80000e20:	8832                	mv	a6,a2
    80000e22:	367d                	addiw	a2,a2,-1
    80000e24:	01005963          	blez	a6,80000e36 <strncpy+0x1e>
    80000e28:	0705                	addi	a4,a4,1
    80000e2a:	0005c783          	lbu	a5,0(a1)
    80000e2e:	fef70fa3          	sb	a5,-1(a4)
    80000e32:	0585                	addi	a1,a1,1
    80000e34:	f7f5                	bnez	a5,80000e20 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e36:	00c05d63          	blez	a2,80000e50 <strncpy+0x38>
    80000e3a:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e3c:	0685                	addi	a3,a3,1
    80000e3e:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e42:	fff6c793          	not	a5,a3
    80000e46:	9fb9                	addw	a5,a5,a4
    80000e48:	010787bb          	addw	a5,a5,a6
    80000e4c:	fef048e3          	bgtz	a5,80000e3c <strncpy+0x24>
  return os;
}
    80000e50:	6422                	ld	s0,8(sp)
    80000e52:	0141                	addi	sp,sp,16
    80000e54:	8082                	ret

0000000080000e56 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e56:	1141                	addi	sp,sp,-16
    80000e58:	e422                	sd	s0,8(sp)
    80000e5a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e5c:	02c05363          	blez	a2,80000e82 <safestrcpy+0x2c>
    80000e60:	fff6069b          	addiw	a3,a2,-1
    80000e64:	1682                	slli	a3,a3,0x20
    80000e66:	9281                	srli	a3,a3,0x20
    80000e68:	96ae                	add	a3,a3,a1
    80000e6a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e6c:	00d58963          	beq	a1,a3,80000e7e <safestrcpy+0x28>
    80000e70:	0585                	addi	a1,a1,1
    80000e72:	0785                	addi	a5,a5,1
    80000e74:	fff5c703          	lbu	a4,-1(a1)
    80000e78:	fee78fa3          	sb	a4,-1(a5)
    80000e7c:	fb65                	bnez	a4,80000e6c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e7e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e82:	6422                	ld	s0,8(sp)
    80000e84:	0141                	addi	sp,sp,16
    80000e86:	8082                	ret

0000000080000e88 <strlen>:

int
strlen(const char *s)
{
    80000e88:	1141                	addi	sp,sp,-16
    80000e8a:	e422                	sd	s0,8(sp)
    80000e8c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e8e:	00054783          	lbu	a5,0(a0)
    80000e92:	cf91                	beqz	a5,80000eae <strlen+0x26>
    80000e94:	0505                	addi	a0,a0,1
    80000e96:	87aa                	mv	a5,a0
    80000e98:	4685                	li	a3,1
    80000e9a:	9e89                	subw	a3,a3,a0
    80000e9c:	00f6853b          	addw	a0,a3,a5
    80000ea0:	0785                	addi	a5,a5,1
    80000ea2:	fff7c703          	lbu	a4,-1(a5)
    80000ea6:	fb7d                	bnez	a4,80000e9c <strlen+0x14>
    ;
  return n;
}
    80000ea8:	6422                	ld	s0,8(sp)
    80000eaa:	0141                	addi	sp,sp,16
    80000eac:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eae:	4501                	li	a0,0
    80000eb0:	bfe5                	j	80000ea8 <strlen+0x20>

0000000080000eb2 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000eb2:	1141                	addi	sp,sp,-16
    80000eb4:	e406                	sd	ra,8(sp)
    80000eb6:	e022                	sd	s0,0(sp)
    80000eb8:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eba:	00001097          	auipc	ra,0x1
    80000ebe:	eee080e7          	jalr	-274(ra) # 80001da8 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ec2:	00008717          	auipc	a4,0x8
    80000ec6:	15670713          	addi	a4,a4,342 # 80009018 <started>
  if(cpuid() == 0){
    80000eca:	c139                	beqz	a0,80000f10 <main+0x5e>
    while(started == 0)
    80000ecc:	431c                	lw	a5,0(a4)
    80000ece:	2781                	sext.w	a5,a5
    80000ed0:	dff5                	beqz	a5,80000ecc <main+0x1a>
      ;
    __sync_synchronize();
    80000ed2:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ed6:	00001097          	auipc	ra,0x1
    80000eda:	ed2080e7          	jalr	-302(ra) # 80001da8 <cpuid>
    80000ede:	85aa                	mv	a1,a0
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	20850513          	addi	a0,a0,520 # 800080e8 <digits+0xa8>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	6a0080e7          	jalr	1696(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ef0:	00000097          	auipc	ra,0x0
    80000ef4:	0d8080e7          	jalr	216(ra) # 80000fc8 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ef8:	00002097          	auipc	ra,0x2
    80000efc:	ec8080e7          	jalr	-312(ra) # 80002dc0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f00:	00005097          	auipc	ra,0x5
    80000f04:	490080e7          	jalr	1168(ra) # 80006390 <plicinithart>
  }

  scheduler();        
    80000f08:	00001097          	auipc	ra,0x1
    80000f0c:	50e080e7          	jalr	1294(ra) # 80002416 <scheduler>
    consoleinit();
    80000f10:	fffff097          	auipc	ra,0xfffff
    80000f14:	540080e7          	jalr	1344(ra) # 80000450 <consoleinit>
    printfinit();
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	856080e7          	jalr	-1962(ra) # 8000076e <printfinit>
    printf("\n");
    80000f20:	00007517          	auipc	a0,0x7
    80000f24:	1d850513          	addi	a0,a0,472 # 800080f8 <digits+0xb8>
    80000f28:	fffff097          	auipc	ra,0xfffff
    80000f2c:	660080e7          	jalr	1632(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f30:	00007517          	auipc	a0,0x7
    80000f34:	1a050513          	addi	a0,a0,416 # 800080d0 <digits+0x90>
    80000f38:	fffff097          	auipc	ra,0xfffff
    80000f3c:	650080e7          	jalr	1616(ra) # 80000588 <printf>
    printf("\n");
    80000f40:	00007517          	auipc	a0,0x7
    80000f44:	1b850513          	addi	a0,a0,440 # 800080f8 <digits+0xb8>
    80000f48:	fffff097          	auipc	ra,0xfffff
    80000f4c:	640080e7          	jalr	1600(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f50:	00000097          	auipc	ra,0x0
    80000f54:	b68080e7          	jalr	-1176(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f58:	00000097          	auipc	ra,0x0
    80000f5c:	322080e7          	jalr	802(ra) # 8000127a <kvminit>
    kvminithart();   // turn on paging
    80000f60:	00000097          	auipc	ra,0x0
    80000f64:	068080e7          	jalr	104(ra) # 80000fc8 <kvminithart>
    procinit();      // process table
    80000f68:	00001097          	auipc	ra,0x1
    80000f6c:	cd0080e7          	jalr	-816(ra) # 80001c38 <procinit>
    trapinit();      // trap vectors
    80000f70:	00002097          	auipc	ra,0x2
    80000f74:	e28080e7          	jalr	-472(ra) # 80002d98 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f78:	00002097          	auipc	ra,0x2
    80000f7c:	e48080e7          	jalr	-440(ra) # 80002dc0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f80:	00005097          	auipc	ra,0x5
    80000f84:	3fa080e7          	jalr	1018(ra) # 8000637a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f88:	00005097          	auipc	ra,0x5
    80000f8c:	408080e7          	jalr	1032(ra) # 80006390 <plicinithart>
    binit();         // buffer cache
    80000f90:	00002097          	auipc	ra,0x2
    80000f94:	5ee080e7          	jalr	1518(ra) # 8000357e <binit>
    iinit();         // inode table
    80000f98:	00003097          	auipc	ra,0x3
    80000f9c:	c7e080e7          	jalr	-898(ra) # 80003c16 <iinit>
    fileinit();      // file table
    80000fa0:	00004097          	auipc	ra,0x4
    80000fa4:	c28080e7          	jalr	-984(ra) # 80004bc8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa8:	00005097          	auipc	ra,0x5
    80000fac:	50a080e7          	jalr	1290(ra) # 800064b2 <virtio_disk_init>
    userinit();      // first user process
    80000fb0:	00001097          	auipc	ra,0x1
    80000fb4:	1ca080e7          	jalr	458(ra) # 8000217a <userinit>
    __sync_synchronize();
    80000fb8:	0ff0000f          	fence
    started = 1;
    80000fbc:	4785                	li	a5,1
    80000fbe:	00008717          	auipc	a4,0x8
    80000fc2:	04f72d23          	sw	a5,90(a4) # 80009018 <started>
    80000fc6:	b789                	j	80000f08 <main+0x56>

0000000080000fc8 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fc8:	1141                	addi	sp,sp,-16
    80000fca:	e422                	sd	s0,8(sp)
    80000fcc:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fce:	00008797          	auipc	a5,0x8
    80000fd2:	0527b783          	ld	a5,82(a5) # 80009020 <kernel_pagetable>
    80000fd6:	83b1                	srli	a5,a5,0xc
    80000fd8:	577d                	li	a4,-1
    80000fda:	177e                	slli	a4,a4,0x3f
    80000fdc:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fde:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fe2:	12000073          	sfence.vma
  sfence_vma();
}
    80000fe6:	6422                	ld	s0,8(sp)
    80000fe8:	0141                	addi	sp,sp,16
    80000fea:	8082                	ret

0000000080000fec <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fec:	7139                	addi	sp,sp,-64
    80000fee:	fc06                	sd	ra,56(sp)
    80000ff0:	f822                	sd	s0,48(sp)
    80000ff2:	f426                	sd	s1,40(sp)
    80000ff4:	f04a                	sd	s2,32(sp)
    80000ff6:	ec4e                	sd	s3,24(sp)
    80000ff8:	e852                	sd	s4,16(sp)
    80000ffa:	e456                	sd	s5,8(sp)
    80000ffc:	e05a                	sd	s6,0(sp)
    80000ffe:	0080                	addi	s0,sp,64
    80001000:	84aa                	mv	s1,a0
    80001002:	89ae                	mv	s3,a1
    80001004:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001006:	57fd                	li	a5,-1
    80001008:	83e9                	srli	a5,a5,0x1a
    8000100a:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000100c:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000100e:	04b7f263          	bgeu	a5,a1,80001052 <walk+0x66>
    panic("walk");
    80001012:	00007517          	auipc	a0,0x7
    80001016:	0ee50513          	addi	a0,a0,238 # 80008100 <digits+0xc0>
    8000101a:	fffff097          	auipc	ra,0xfffff
    8000101e:	524080e7          	jalr	1316(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001022:	060a8663          	beqz	s5,8000108e <walk+0xa2>
    80001026:	00000097          	auipc	ra,0x0
    8000102a:	ace080e7          	jalr	-1330(ra) # 80000af4 <kalloc>
    8000102e:	84aa                	mv	s1,a0
    80001030:	c529                	beqz	a0,8000107a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001032:	6605                	lui	a2,0x1
    80001034:	4581                	li	a1,0
    80001036:	00000097          	auipc	ra,0x0
    8000103a:	cce080e7          	jalr	-818(ra) # 80000d04 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000103e:	00c4d793          	srli	a5,s1,0xc
    80001042:	07aa                	slli	a5,a5,0xa
    80001044:	0017e793          	ori	a5,a5,1
    80001048:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000104c:	3a5d                	addiw	s4,s4,-9
    8000104e:	036a0063          	beq	s4,s6,8000106e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001052:	0149d933          	srl	s2,s3,s4
    80001056:	1ff97913          	andi	s2,s2,511
    8000105a:	090e                	slli	s2,s2,0x3
    8000105c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000105e:	00093483          	ld	s1,0(s2)
    80001062:	0014f793          	andi	a5,s1,1
    80001066:	dfd5                	beqz	a5,80001022 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001068:	80a9                	srli	s1,s1,0xa
    8000106a:	04b2                	slli	s1,s1,0xc
    8000106c:	b7c5                	j	8000104c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000106e:	00c9d513          	srli	a0,s3,0xc
    80001072:	1ff57513          	andi	a0,a0,511
    80001076:	050e                	slli	a0,a0,0x3
    80001078:	9526                	add	a0,a0,s1
}
    8000107a:	70e2                	ld	ra,56(sp)
    8000107c:	7442                	ld	s0,48(sp)
    8000107e:	74a2                	ld	s1,40(sp)
    80001080:	7902                	ld	s2,32(sp)
    80001082:	69e2                	ld	s3,24(sp)
    80001084:	6a42                	ld	s4,16(sp)
    80001086:	6aa2                	ld	s5,8(sp)
    80001088:	6b02                	ld	s6,0(sp)
    8000108a:	6121                	addi	sp,sp,64
    8000108c:	8082                	ret
        return 0;
    8000108e:	4501                	li	a0,0
    80001090:	b7ed                	j	8000107a <walk+0x8e>

0000000080001092 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001092:	57fd                	li	a5,-1
    80001094:	83e9                	srli	a5,a5,0x1a
    80001096:	00b7f463          	bgeu	a5,a1,8000109e <walkaddr+0xc>
    return 0;
    8000109a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000109c:	8082                	ret
{
    8000109e:	1141                	addi	sp,sp,-16
    800010a0:	e406                	sd	ra,8(sp)
    800010a2:	e022                	sd	s0,0(sp)
    800010a4:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010a6:	4601                	li	a2,0
    800010a8:	00000097          	auipc	ra,0x0
    800010ac:	f44080e7          	jalr	-188(ra) # 80000fec <walk>
  if(pte == 0)
    800010b0:	c105                	beqz	a0,800010d0 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010b2:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010b4:	0117f693          	andi	a3,a5,17
    800010b8:	4745                	li	a4,17
    return 0;
    800010ba:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010bc:	00e68663          	beq	a3,a4,800010c8 <walkaddr+0x36>
}
    800010c0:	60a2                	ld	ra,8(sp)
    800010c2:	6402                	ld	s0,0(sp)
    800010c4:	0141                	addi	sp,sp,16
    800010c6:	8082                	ret
  pa = PTE2PA(*pte);
    800010c8:	00a7d513          	srli	a0,a5,0xa
    800010cc:	0532                	slli	a0,a0,0xc
  return pa;
    800010ce:	bfcd                	j	800010c0 <walkaddr+0x2e>
    return 0;
    800010d0:	4501                	li	a0,0
    800010d2:	b7fd                	j	800010c0 <walkaddr+0x2e>

00000000800010d4 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010d4:	715d                	addi	sp,sp,-80
    800010d6:	e486                	sd	ra,72(sp)
    800010d8:	e0a2                	sd	s0,64(sp)
    800010da:	fc26                	sd	s1,56(sp)
    800010dc:	f84a                	sd	s2,48(sp)
    800010de:	f44e                	sd	s3,40(sp)
    800010e0:	f052                	sd	s4,32(sp)
    800010e2:	ec56                	sd	s5,24(sp)
    800010e4:	e85a                	sd	s6,16(sp)
    800010e6:	e45e                	sd	s7,8(sp)
    800010e8:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010ea:	c205                	beqz	a2,8000110a <mappages+0x36>
    800010ec:	8aaa                	mv	s5,a0
    800010ee:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010f0:	77fd                	lui	a5,0xfffff
    800010f2:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010f6:	15fd                	addi	a1,a1,-1
    800010f8:	00c589b3          	add	s3,a1,a2
    800010fc:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    80001100:	8952                	mv	s2,s4
    80001102:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001106:	6b85                	lui	s7,0x1
    80001108:	a015                	j	8000112c <mappages+0x58>
    panic("mappages: size");
    8000110a:	00007517          	auipc	a0,0x7
    8000110e:	ffe50513          	addi	a0,a0,-2 # 80008108 <digits+0xc8>
    80001112:	fffff097          	auipc	ra,0xfffff
    80001116:	42c080e7          	jalr	1068(ra) # 8000053e <panic>
      panic("mappages: remap");
    8000111a:	00007517          	auipc	a0,0x7
    8000111e:	ffe50513          	addi	a0,a0,-2 # 80008118 <digits+0xd8>
    80001122:	fffff097          	auipc	ra,0xfffff
    80001126:	41c080e7          	jalr	1052(ra) # 8000053e <panic>
    a += PGSIZE;
    8000112a:	995e                	add	s2,s2,s7
  for(;;){
    8000112c:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001130:	4605                	li	a2,1
    80001132:	85ca                	mv	a1,s2
    80001134:	8556                	mv	a0,s5
    80001136:	00000097          	auipc	ra,0x0
    8000113a:	eb6080e7          	jalr	-330(ra) # 80000fec <walk>
    8000113e:	cd19                	beqz	a0,8000115c <mappages+0x88>
    if(*pte & PTE_V)
    80001140:	611c                	ld	a5,0(a0)
    80001142:	8b85                	andi	a5,a5,1
    80001144:	fbf9                	bnez	a5,8000111a <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001146:	80b1                	srli	s1,s1,0xc
    80001148:	04aa                	slli	s1,s1,0xa
    8000114a:	0164e4b3          	or	s1,s1,s6
    8000114e:	0014e493          	ori	s1,s1,1
    80001152:	e104                	sd	s1,0(a0)
    if(a == last)
    80001154:	fd391be3          	bne	s2,s3,8000112a <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001158:	4501                	li	a0,0
    8000115a:	a011                	j	8000115e <mappages+0x8a>
      return -1;
    8000115c:	557d                	li	a0,-1
}
    8000115e:	60a6                	ld	ra,72(sp)
    80001160:	6406                	ld	s0,64(sp)
    80001162:	74e2                	ld	s1,56(sp)
    80001164:	7942                	ld	s2,48(sp)
    80001166:	79a2                	ld	s3,40(sp)
    80001168:	7a02                	ld	s4,32(sp)
    8000116a:	6ae2                	ld	s5,24(sp)
    8000116c:	6b42                	ld	s6,16(sp)
    8000116e:	6ba2                	ld	s7,8(sp)
    80001170:	6161                	addi	sp,sp,80
    80001172:	8082                	ret

0000000080001174 <kvmmap>:
{
    80001174:	1141                	addi	sp,sp,-16
    80001176:	e406                	sd	ra,8(sp)
    80001178:	e022                	sd	s0,0(sp)
    8000117a:	0800                	addi	s0,sp,16
    8000117c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000117e:	86b2                	mv	a3,a2
    80001180:	863e                	mv	a2,a5
    80001182:	00000097          	auipc	ra,0x0
    80001186:	f52080e7          	jalr	-174(ra) # 800010d4 <mappages>
    8000118a:	e509                	bnez	a0,80001194 <kvmmap+0x20>
}
    8000118c:	60a2                	ld	ra,8(sp)
    8000118e:	6402                	ld	s0,0(sp)
    80001190:	0141                	addi	sp,sp,16
    80001192:	8082                	ret
    panic("kvmmap");
    80001194:	00007517          	auipc	a0,0x7
    80001198:	f9450513          	addi	a0,a0,-108 # 80008128 <digits+0xe8>
    8000119c:	fffff097          	auipc	ra,0xfffff
    800011a0:	3a2080e7          	jalr	930(ra) # 8000053e <panic>

00000000800011a4 <kvmmake>:
{
    800011a4:	1101                	addi	sp,sp,-32
    800011a6:	ec06                	sd	ra,24(sp)
    800011a8:	e822                	sd	s0,16(sp)
    800011aa:	e426                	sd	s1,8(sp)
    800011ac:	e04a                	sd	s2,0(sp)
    800011ae:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	944080e7          	jalr	-1724(ra) # 80000af4 <kalloc>
    800011b8:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011ba:	6605                	lui	a2,0x1
    800011bc:	4581                	li	a1,0
    800011be:	00000097          	auipc	ra,0x0
    800011c2:	b46080e7          	jalr	-1210(ra) # 80000d04 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011c6:	4719                	li	a4,6
    800011c8:	6685                	lui	a3,0x1
    800011ca:	10000637          	lui	a2,0x10000
    800011ce:	100005b7          	lui	a1,0x10000
    800011d2:	8526                	mv	a0,s1
    800011d4:	00000097          	auipc	ra,0x0
    800011d8:	fa0080e7          	jalr	-96(ra) # 80001174 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011dc:	4719                	li	a4,6
    800011de:	6685                	lui	a3,0x1
    800011e0:	10001637          	lui	a2,0x10001
    800011e4:	100015b7          	lui	a1,0x10001
    800011e8:	8526                	mv	a0,s1
    800011ea:	00000097          	auipc	ra,0x0
    800011ee:	f8a080e7          	jalr	-118(ra) # 80001174 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011f2:	4719                	li	a4,6
    800011f4:	004006b7          	lui	a3,0x400
    800011f8:	0c000637          	lui	a2,0xc000
    800011fc:	0c0005b7          	lui	a1,0xc000
    80001200:	8526                	mv	a0,s1
    80001202:	00000097          	auipc	ra,0x0
    80001206:	f72080e7          	jalr	-142(ra) # 80001174 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000120a:	00007917          	auipc	s2,0x7
    8000120e:	df690913          	addi	s2,s2,-522 # 80008000 <etext>
    80001212:	4729                	li	a4,10
    80001214:	80007697          	auipc	a3,0x80007
    80001218:	dec68693          	addi	a3,a3,-532 # 8000 <_entry-0x7fff8000>
    8000121c:	4605                	li	a2,1
    8000121e:	067e                	slli	a2,a2,0x1f
    80001220:	85b2                	mv	a1,a2
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f50080e7          	jalr	-176(ra) # 80001174 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000122c:	4719                	li	a4,6
    8000122e:	46c5                	li	a3,17
    80001230:	06ee                	slli	a3,a3,0x1b
    80001232:	412686b3          	sub	a3,a3,s2
    80001236:	864a                	mv	a2,s2
    80001238:	85ca                	mv	a1,s2
    8000123a:	8526                	mv	a0,s1
    8000123c:	00000097          	auipc	ra,0x0
    80001240:	f38080e7          	jalr	-200(ra) # 80001174 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001244:	4729                	li	a4,10
    80001246:	6685                	lui	a3,0x1
    80001248:	00006617          	auipc	a2,0x6
    8000124c:	db860613          	addi	a2,a2,-584 # 80007000 <_trampoline>
    80001250:	040005b7          	lui	a1,0x4000
    80001254:	15fd                	addi	a1,a1,-1
    80001256:	05b2                	slli	a1,a1,0xc
    80001258:	8526                	mv	a0,s1
    8000125a:	00000097          	auipc	ra,0x0
    8000125e:	f1a080e7          	jalr	-230(ra) # 80001174 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001262:	8526                	mv	a0,s1
    80001264:	00001097          	auipc	ra,0x1
    80001268:	93e080e7          	jalr	-1730(ra) # 80001ba2 <proc_mapstacks>
}
    8000126c:	8526                	mv	a0,s1
    8000126e:	60e2                	ld	ra,24(sp)
    80001270:	6442                	ld	s0,16(sp)
    80001272:	64a2                	ld	s1,8(sp)
    80001274:	6902                	ld	s2,0(sp)
    80001276:	6105                	addi	sp,sp,32
    80001278:	8082                	ret

000000008000127a <kvminit>:
{
    8000127a:	1141                	addi	sp,sp,-16
    8000127c:	e406                	sd	ra,8(sp)
    8000127e:	e022                	sd	s0,0(sp)
    80001280:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001282:	00000097          	auipc	ra,0x0
    80001286:	f22080e7          	jalr	-222(ra) # 800011a4 <kvmmake>
    8000128a:	00008797          	auipc	a5,0x8
    8000128e:	d8a7bb23          	sd	a0,-618(a5) # 80009020 <kernel_pagetable>
}
    80001292:	60a2                	ld	ra,8(sp)
    80001294:	6402                	ld	s0,0(sp)
    80001296:	0141                	addi	sp,sp,16
    80001298:	8082                	ret

000000008000129a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000129a:	715d                	addi	sp,sp,-80
    8000129c:	e486                	sd	ra,72(sp)
    8000129e:	e0a2                	sd	s0,64(sp)
    800012a0:	fc26                	sd	s1,56(sp)
    800012a2:	f84a                	sd	s2,48(sp)
    800012a4:	f44e                	sd	s3,40(sp)
    800012a6:	f052                	sd	s4,32(sp)
    800012a8:	ec56                	sd	s5,24(sp)
    800012aa:	e85a                	sd	s6,16(sp)
    800012ac:	e45e                	sd	s7,8(sp)
    800012ae:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012b0:	03459793          	slli	a5,a1,0x34
    800012b4:	e795                	bnez	a5,800012e0 <uvmunmap+0x46>
    800012b6:	8a2a                	mv	s4,a0
    800012b8:	892e                	mv	s2,a1
    800012ba:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012bc:	0632                	slli	a2,a2,0xc
    800012be:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012c2:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012c4:	6b05                	lui	s6,0x1
    800012c6:	0735e863          	bltu	a1,s3,80001336 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012ca:	60a6                	ld	ra,72(sp)
    800012cc:	6406                	ld	s0,64(sp)
    800012ce:	74e2                	ld	s1,56(sp)
    800012d0:	7942                	ld	s2,48(sp)
    800012d2:	79a2                	ld	s3,40(sp)
    800012d4:	7a02                	ld	s4,32(sp)
    800012d6:	6ae2                	ld	s5,24(sp)
    800012d8:	6b42                	ld	s6,16(sp)
    800012da:	6ba2                	ld	s7,8(sp)
    800012dc:	6161                	addi	sp,sp,80
    800012de:	8082                	ret
    panic("uvmunmap: not aligned");
    800012e0:	00007517          	auipc	a0,0x7
    800012e4:	e5050513          	addi	a0,a0,-432 # 80008130 <digits+0xf0>
    800012e8:	fffff097          	auipc	ra,0xfffff
    800012ec:	256080e7          	jalr	598(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012f0:	00007517          	auipc	a0,0x7
    800012f4:	e5850513          	addi	a0,a0,-424 # 80008148 <digits+0x108>
    800012f8:	fffff097          	auipc	ra,0xfffff
    800012fc:	246080e7          	jalr	582(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    80001300:	00007517          	auipc	a0,0x7
    80001304:	e5850513          	addi	a0,a0,-424 # 80008158 <digits+0x118>
    80001308:	fffff097          	auipc	ra,0xfffff
    8000130c:	236080e7          	jalr	566(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    80001310:	00007517          	auipc	a0,0x7
    80001314:	e6050513          	addi	a0,a0,-416 # 80008170 <digits+0x130>
    80001318:	fffff097          	auipc	ra,0xfffff
    8000131c:	226080e7          	jalr	550(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    80001320:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001322:	0532                	slli	a0,a0,0xc
    80001324:	fffff097          	auipc	ra,0xfffff
    80001328:	6d4080e7          	jalr	1748(ra) # 800009f8 <kfree>
    *pte = 0;
    8000132c:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001330:	995a                	add	s2,s2,s6
    80001332:	f9397ce3          	bgeu	s2,s3,800012ca <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001336:	4601                	li	a2,0
    80001338:	85ca                	mv	a1,s2
    8000133a:	8552                	mv	a0,s4
    8000133c:	00000097          	auipc	ra,0x0
    80001340:	cb0080e7          	jalr	-848(ra) # 80000fec <walk>
    80001344:	84aa                	mv	s1,a0
    80001346:	d54d                	beqz	a0,800012f0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001348:	6108                	ld	a0,0(a0)
    8000134a:	00157793          	andi	a5,a0,1
    8000134e:	dbcd                	beqz	a5,80001300 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001350:	3ff57793          	andi	a5,a0,1023
    80001354:	fb778ee3          	beq	a5,s7,80001310 <uvmunmap+0x76>
    if(do_free){
    80001358:	fc0a8ae3          	beqz	s5,8000132c <uvmunmap+0x92>
    8000135c:	b7d1                	j	80001320 <uvmunmap+0x86>

000000008000135e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000135e:	1101                	addi	sp,sp,-32
    80001360:	ec06                	sd	ra,24(sp)
    80001362:	e822                	sd	s0,16(sp)
    80001364:	e426                	sd	s1,8(sp)
    80001366:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	78c080e7          	jalr	1932(ra) # 80000af4 <kalloc>
    80001370:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001372:	c519                	beqz	a0,80001380 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001374:	6605                	lui	a2,0x1
    80001376:	4581                	li	a1,0
    80001378:	00000097          	auipc	ra,0x0
    8000137c:	98c080e7          	jalr	-1652(ra) # 80000d04 <memset>
  return pagetable;
}
    80001380:	8526                	mv	a0,s1
    80001382:	60e2                	ld	ra,24(sp)
    80001384:	6442                	ld	s0,16(sp)
    80001386:	64a2                	ld	s1,8(sp)
    80001388:	6105                	addi	sp,sp,32
    8000138a:	8082                	ret

000000008000138c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000138c:	7179                	addi	sp,sp,-48
    8000138e:	f406                	sd	ra,40(sp)
    80001390:	f022                	sd	s0,32(sp)
    80001392:	ec26                	sd	s1,24(sp)
    80001394:	e84a                	sd	s2,16(sp)
    80001396:	e44e                	sd	s3,8(sp)
    80001398:	e052                	sd	s4,0(sp)
    8000139a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000139c:	6785                	lui	a5,0x1
    8000139e:	04f67863          	bgeu	a2,a5,800013ee <uvminit+0x62>
    800013a2:	8a2a                	mv	s4,a0
    800013a4:	89ae                	mv	s3,a1
    800013a6:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013a8:	fffff097          	auipc	ra,0xfffff
    800013ac:	74c080e7          	jalr	1868(ra) # 80000af4 <kalloc>
    800013b0:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013b2:	6605                	lui	a2,0x1
    800013b4:	4581                	li	a1,0
    800013b6:	00000097          	auipc	ra,0x0
    800013ba:	94e080e7          	jalr	-1714(ra) # 80000d04 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013be:	4779                	li	a4,30
    800013c0:	86ca                	mv	a3,s2
    800013c2:	6605                	lui	a2,0x1
    800013c4:	4581                	li	a1,0
    800013c6:	8552                	mv	a0,s4
    800013c8:	00000097          	auipc	ra,0x0
    800013cc:	d0c080e7          	jalr	-756(ra) # 800010d4 <mappages>
  memmove(mem, src, sz);
    800013d0:	8626                	mv	a2,s1
    800013d2:	85ce                	mv	a1,s3
    800013d4:	854a                	mv	a0,s2
    800013d6:	00000097          	auipc	ra,0x0
    800013da:	98e080e7          	jalr	-1650(ra) # 80000d64 <memmove>
}
    800013de:	70a2                	ld	ra,40(sp)
    800013e0:	7402                	ld	s0,32(sp)
    800013e2:	64e2                	ld	s1,24(sp)
    800013e4:	6942                	ld	s2,16(sp)
    800013e6:	69a2                	ld	s3,8(sp)
    800013e8:	6a02                	ld	s4,0(sp)
    800013ea:	6145                	addi	sp,sp,48
    800013ec:	8082                	ret
    panic("inituvm: more than a page");
    800013ee:	00007517          	auipc	a0,0x7
    800013f2:	d9a50513          	addi	a0,a0,-614 # 80008188 <digits+0x148>
    800013f6:	fffff097          	auipc	ra,0xfffff
    800013fa:	148080e7          	jalr	328(ra) # 8000053e <panic>

00000000800013fe <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013fe:	1101                	addi	sp,sp,-32
    80001400:	ec06                	sd	ra,24(sp)
    80001402:	e822                	sd	s0,16(sp)
    80001404:	e426                	sd	s1,8(sp)
    80001406:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001408:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000140a:	00b67d63          	bgeu	a2,a1,80001424 <uvmdealloc+0x26>
    8000140e:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001410:	6785                	lui	a5,0x1
    80001412:	17fd                	addi	a5,a5,-1
    80001414:	00f60733          	add	a4,a2,a5
    80001418:	767d                	lui	a2,0xfffff
    8000141a:	8f71                	and	a4,a4,a2
    8000141c:	97ae                	add	a5,a5,a1
    8000141e:	8ff1                	and	a5,a5,a2
    80001420:	00f76863          	bltu	a4,a5,80001430 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001424:	8526                	mv	a0,s1
    80001426:	60e2                	ld	ra,24(sp)
    80001428:	6442                	ld	s0,16(sp)
    8000142a:	64a2                	ld	s1,8(sp)
    8000142c:	6105                	addi	sp,sp,32
    8000142e:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001430:	8f99                	sub	a5,a5,a4
    80001432:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001434:	4685                	li	a3,1
    80001436:	0007861b          	sext.w	a2,a5
    8000143a:	85ba                	mv	a1,a4
    8000143c:	00000097          	auipc	ra,0x0
    80001440:	e5e080e7          	jalr	-418(ra) # 8000129a <uvmunmap>
    80001444:	b7c5                	j	80001424 <uvmdealloc+0x26>

0000000080001446 <uvmalloc>:
  if(newsz < oldsz)
    80001446:	0ab66163          	bltu	a2,a1,800014e8 <uvmalloc+0xa2>
{
    8000144a:	7139                	addi	sp,sp,-64
    8000144c:	fc06                	sd	ra,56(sp)
    8000144e:	f822                	sd	s0,48(sp)
    80001450:	f426                	sd	s1,40(sp)
    80001452:	f04a                	sd	s2,32(sp)
    80001454:	ec4e                	sd	s3,24(sp)
    80001456:	e852                	sd	s4,16(sp)
    80001458:	e456                	sd	s5,8(sp)
    8000145a:	0080                	addi	s0,sp,64
    8000145c:	8aaa                	mv	s5,a0
    8000145e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001460:	6985                	lui	s3,0x1
    80001462:	19fd                	addi	s3,s3,-1
    80001464:	95ce                	add	a1,a1,s3
    80001466:	79fd                	lui	s3,0xfffff
    80001468:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146c:	08c9f063          	bgeu	s3,a2,800014ec <uvmalloc+0xa6>
    80001470:	894e                	mv	s2,s3
    mem = kalloc();
    80001472:	fffff097          	auipc	ra,0xfffff
    80001476:	682080e7          	jalr	1666(ra) # 80000af4 <kalloc>
    8000147a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000147c:	c51d                	beqz	a0,800014aa <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000147e:	6605                	lui	a2,0x1
    80001480:	4581                	li	a1,0
    80001482:	00000097          	auipc	ra,0x0
    80001486:	882080e7          	jalr	-1918(ra) # 80000d04 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000148a:	4779                	li	a4,30
    8000148c:	86a6                	mv	a3,s1
    8000148e:	6605                	lui	a2,0x1
    80001490:	85ca                	mv	a1,s2
    80001492:	8556                	mv	a0,s5
    80001494:	00000097          	auipc	ra,0x0
    80001498:	c40080e7          	jalr	-960(ra) # 800010d4 <mappages>
    8000149c:	e905                	bnez	a0,800014cc <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000149e:	6785                	lui	a5,0x1
    800014a0:	993e                	add	s2,s2,a5
    800014a2:	fd4968e3          	bltu	s2,s4,80001472 <uvmalloc+0x2c>
  return newsz;
    800014a6:	8552                	mv	a0,s4
    800014a8:	a809                	j	800014ba <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014aa:	864e                	mv	a2,s3
    800014ac:	85ca                	mv	a1,s2
    800014ae:	8556                	mv	a0,s5
    800014b0:	00000097          	auipc	ra,0x0
    800014b4:	f4e080e7          	jalr	-178(ra) # 800013fe <uvmdealloc>
      return 0;
    800014b8:	4501                	li	a0,0
}
    800014ba:	70e2                	ld	ra,56(sp)
    800014bc:	7442                	ld	s0,48(sp)
    800014be:	74a2                	ld	s1,40(sp)
    800014c0:	7902                	ld	s2,32(sp)
    800014c2:	69e2                	ld	s3,24(sp)
    800014c4:	6a42                	ld	s4,16(sp)
    800014c6:	6aa2                	ld	s5,8(sp)
    800014c8:	6121                	addi	sp,sp,64
    800014ca:	8082                	ret
      kfree(mem);
    800014cc:	8526                	mv	a0,s1
    800014ce:	fffff097          	auipc	ra,0xfffff
    800014d2:	52a080e7          	jalr	1322(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014d6:	864e                	mv	a2,s3
    800014d8:	85ca                	mv	a1,s2
    800014da:	8556                	mv	a0,s5
    800014dc:	00000097          	auipc	ra,0x0
    800014e0:	f22080e7          	jalr	-222(ra) # 800013fe <uvmdealloc>
      return 0;
    800014e4:	4501                	li	a0,0
    800014e6:	bfd1                	j	800014ba <uvmalloc+0x74>
    return oldsz;
    800014e8:	852e                	mv	a0,a1
}
    800014ea:	8082                	ret
  return newsz;
    800014ec:	8532                	mv	a0,a2
    800014ee:	b7f1                	j	800014ba <uvmalloc+0x74>

00000000800014f0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014f0:	7179                	addi	sp,sp,-48
    800014f2:	f406                	sd	ra,40(sp)
    800014f4:	f022                	sd	s0,32(sp)
    800014f6:	ec26                	sd	s1,24(sp)
    800014f8:	e84a                	sd	s2,16(sp)
    800014fa:	e44e                	sd	s3,8(sp)
    800014fc:	e052                	sd	s4,0(sp)
    800014fe:	1800                	addi	s0,sp,48
    80001500:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001502:	84aa                	mv	s1,a0
    80001504:	6905                	lui	s2,0x1
    80001506:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001508:	4985                	li	s3,1
    8000150a:	a821                	j	80001522 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000150c:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000150e:	0532                	slli	a0,a0,0xc
    80001510:	00000097          	auipc	ra,0x0
    80001514:	fe0080e7          	jalr	-32(ra) # 800014f0 <freewalk>
      pagetable[i] = 0;
    80001518:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000151c:	04a1                	addi	s1,s1,8
    8000151e:	03248163          	beq	s1,s2,80001540 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001522:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001524:	00f57793          	andi	a5,a0,15
    80001528:	ff3782e3          	beq	a5,s3,8000150c <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000152c:	8905                	andi	a0,a0,1
    8000152e:	d57d                	beqz	a0,8000151c <freewalk+0x2c>
      panic("freewalk: leaf");
    80001530:	00007517          	auipc	a0,0x7
    80001534:	c7850513          	addi	a0,a0,-904 # 800081a8 <digits+0x168>
    80001538:	fffff097          	auipc	ra,0xfffff
    8000153c:	006080e7          	jalr	6(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001540:	8552                	mv	a0,s4
    80001542:	fffff097          	auipc	ra,0xfffff
    80001546:	4b6080e7          	jalr	1206(ra) # 800009f8 <kfree>
}
    8000154a:	70a2                	ld	ra,40(sp)
    8000154c:	7402                	ld	s0,32(sp)
    8000154e:	64e2                	ld	s1,24(sp)
    80001550:	6942                	ld	s2,16(sp)
    80001552:	69a2                	ld	s3,8(sp)
    80001554:	6a02                	ld	s4,0(sp)
    80001556:	6145                	addi	sp,sp,48
    80001558:	8082                	ret

000000008000155a <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000155a:	1101                	addi	sp,sp,-32
    8000155c:	ec06                	sd	ra,24(sp)
    8000155e:	e822                	sd	s0,16(sp)
    80001560:	e426                	sd	s1,8(sp)
    80001562:	1000                	addi	s0,sp,32
    80001564:	84aa                	mv	s1,a0
  if(sz > 0)
    80001566:	e999                	bnez	a1,8000157c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001568:	8526                	mv	a0,s1
    8000156a:	00000097          	auipc	ra,0x0
    8000156e:	f86080e7          	jalr	-122(ra) # 800014f0 <freewalk>
}
    80001572:	60e2                	ld	ra,24(sp)
    80001574:	6442                	ld	s0,16(sp)
    80001576:	64a2                	ld	s1,8(sp)
    80001578:	6105                	addi	sp,sp,32
    8000157a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000157c:	6605                	lui	a2,0x1
    8000157e:	167d                	addi	a2,a2,-1
    80001580:	962e                	add	a2,a2,a1
    80001582:	4685                	li	a3,1
    80001584:	8231                	srli	a2,a2,0xc
    80001586:	4581                	li	a1,0
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	d12080e7          	jalr	-750(ra) # 8000129a <uvmunmap>
    80001590:	bfe1                	j	80001568 <uvmfree+0xe>

0000000080001592 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001592:	c679                	beqz	a2,80001660 <uvmcopy+0xce>
{
    80001594:	715d                	addi	sp,sp,-80
    80001596:	e486                	sd	ra,72(sp)
    80001598:	e0a2                	sd	s0,64(sp)
    8000159a:	fc26                	sd	s1,56(sp)
    8000159c:	f84a                	sd	s2,48(sp)
    8000159e:	f44e                	sd	s3,40(sp)
    800015a0:	f052                	sd	s4,32(sp)
    800015a2:	ec56                	sd	s5,24(sp)
    800015a4:	e85a                	sd	s6,16(sp)
    800015a6:	e45e                	sd	s7,8(sp)
    800015a8:	0880                	addi	s0,sp,80
    800015aa:	8b2a                	mv	s6,a0
    800015ac:	8aae                	mv	s5,a1
    800015ae:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015b0:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015b2:	4601                	li	a2,0
    800015b4:	85ce                	mv	a1,s3
    800015b6:	855a                	mv	a0,s6
    800015b8:	00000097          	auipc	ra,0x0
    800015bc:	a34080e7          	jalr	-1484(ra) # 80000fec <walk>
    800015c0:	c531                	beqz	a0,8000160c <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015c2:	6118                	ld	a4,0(a0)
    800015c4:	00177793          	andi	a5,a4,1
    800015c8:	cbb1                	beqz	a5,8000161c <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015ca:	00a75593          	srli	a1,a4,0xa
    800015ce:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015d2:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015d6:	fffff097          	auipc	ra,0xfffff
    800015da:	51e080e7          	jalr	1310(ra) # 80000af4 <kalloc>
    800015de:	892a                	mv	s2,a0
    800015e0:	c939                	beqz	a0,80001636 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015e2:	6605                	lui	a2,0x1
    800015e4:	85de                	mv	a1,s7
    800015e6:	fffff097          	auipc	ra,0xfffff
    800015ea:	77e080e7          	jalr	1918(ra) # 80000d64 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ee:	8726                	mv	a4,s1
    800015f0:	86ca                	mv	a3,s2
    800015f2:	6605                	lui	a2,0x1
    800015f4:	85ce                	mv	a1,s3
    800015f6:	8556                	mv	a0,s5
    800015f8:	00000097          	auipc	ra,0x0
    800015fc:	adc080e7          	jalr	-1316(ra) # 800010d4 <mappages>
    80001600:	e515                	bnez	a0,8000162c <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001602:	6785                	lui	a5,0x1
    80001604:	99be                	add	s3,s3,a5
    80001606:	fb49e6e3          	bltu	s3,s4,800015b2 <uvmcopy+0x20>
    8000160a:	a081                	j	8000164a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000160c:	00007517          	auipc	a0,0x7
    80001610:	bac50513          	addi	a0,a0,-1108 # 800081b8 <digits+0x178>
    80001614:	fffff097          	auipc	ra,0xfffff
    80001618:	f2a080e7          	jalr	-214(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    8000161c:	00007517          	auipc	a0,0x7
    80001620:	bbc50513          	addi	a0,a0,-1092 # 800081d8 <digits+0x198>
    80001624:	fffff097          	auipc	ra,0xfffff
    80001628:	f1a080e7          	jalr	-230(ra) # 8000053e <panic>
      kfree(mem);
    8000162c:	854a                	mv	a0,s2
    8000162e:	fffff097          	auipc	ra,0xfffff
    80001632:	3ca080e7          	jalr	970(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001636:	4685                	li	a3,1
    80001638:	00c9d613          	srli	a2,s3,0xc
    8000163c:	4581                	li	a1,0
    8000163e:	8556                	mv	a0,s5
    80001640:	00000097          	auipc	ra,0x0
    80001644:	c5a080e7          	jalr	-934(ra) # 8000129a <uvmunmap>
  return -1;
    80001648:	557d                	li	a0,-1
}
    8000164a:	60a6                	ld	ra,72(sp)
    8000164c:	6406                	ld	s0,64(sp)
    8000164e:	74e2                	ld	s1,56(sp)
    80001650:	7942                	ld	s2,48(sp)
    80001652:	79a2                	ld	s3,40(sp)
    80001654:	7a02                	ld	s4,32(sp)
    80001656:	6ae2                	ld	s5,24(sp)
    80001658:	6b42                	ld	s6,16(sp)
    8000165a:	6ba2                	ld	s7,8(sp)
    8000165c:	6161                	addi	sp,sp,80
    8000165e:	8082                	ret
  return 0;
    80001660:	4501                	li	a0,0
}
    80001662:	8082                	ret

0000000080001664 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001664:	1141                	addi	sp,sp,-16
    80001666:	e406                	sd	ra,8(sp)
    80001668:	e022                	sd	s0,0(sp)
    8000166a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000166c:	4601                	li	a2,0
    8000166e:	00000097          	auipc	ra,0x0
    80001672:	97e080e7          	jalr	-1666(ra) # 80000fec <walk>
  if(pte == 0)
    80001676:	c901                	beqz	a0,80001686 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001678:	611c                	ld	a5,0(a0)
    8000167a:	9bbd                	andi	a5,a5,-17
    8000167c:	e11c                	sd	a5,0(a0)
}
    8000167e:	60a2                	ld	ra,8(sp)
    80001680:	6402                	ld	s0,0(sp)
    80001682:	0141                	addi	sp,sp,16
    80001684:	8082                	ret
    panic("uvmclear");
    80001686:	00007517          	auipc	a0,0x7
    8000168a:	b7250513          	addi	a0,a0,-1166 # 800081f8 <digits+0x1b8>
    8000168e:	fffff097          	auipc	ra,0xfffff
    80001692:	eb0080e7          	jalr	-336(ra) # 8000053e <panic>

0000000080001696 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001696:	c6bd                	beqz	a3,80001704 <copyout+0x6e>
{
    80001698:	715d                	addi	sp,sp,-80
    8000169a:	e486                	sd	ra,72(sp)
    8000169c:	e0a2                	sd	s0,64(sp)
    8000169e:	fc26                	sd	s1,56(sp)
    800016a0:	f84a                	sd	s2,48(sp)
    800016a2:	f44e                	sd	s3,40(sp)
    800016a4:	f052                	sd	s4,32(sp)
    800016a6:	ec56                	sd	s5,24(sp)
    800016a8:	e85a                	sd	s6,16(sp)
    800016aa:	e45e                	sd	s7,8(sp)
    800016ac:	e062                	sd	s8,0(sp)
    800016ae:	0880                	addi	s0,sp,80
    800016b0:	8b2a                	mv	s6,a0
    800016b2:	8c2e                	mv	s8,a1
    800016b4:	8a32                	mv	s4,a2
    800016b6:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016b8:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016ba:	6a85                	lui	s5,0x1
    800016bc:	a015                	j	800016e0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016be:	9562                	add	a0,a0,s8
    800016c0:	0004861b          	sext.w	a2,s1
    800016c4:	85d2                	mv	a1,s4
    800016c6:	41250533          	sub	a0,a0,s2
    800016ca:	fffff097          	auipc	ra,0xfffff
    800016ce:	69a080e7          	jalr	1690(ra) # 80000d64 <memmove>

    len -= n;
    800016d2:	409989b3          	sub	s3,s3,s1
    src += n;
    800016d6:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016d8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016dc:	02098263          	beqz	s3,80001700 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016e0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016e4:	85ca                	mv	a1,s2
    800016e6:	855a                	mv	a0,s6
    800016e8:	00000097          	auipc	ra,0x0
    800016ec:	9aa080e7          	jalr	-1622(ra) # 80001092 <walkaddr>
    if(pa0 == 0)
    800016f0:	cd01                	beqz	a0,80001708 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016f2:	418904b3          	sub	s1,s2,s8
    800016f6:	94d6                	add	s1,s1,s5
    if(n > len)
    800016f8:	fc99f3e3          	bgeu	s3,s1,800016be <copyout+0x28>
    800016fc:	84ce                	mv	s1,s3
    800016fe:	b7c1                	j	800016be <copyout+0x28>
  }
  return 0;
    80001700:	4501                	li	a0,0
    80001702:	a021                	j	8000170a <copyout+0x74>
    80001704:	4501                	li	a0,0
}
    80001706:	8082                	ret
      return -1;
    80001708:	557d                	li	a0,-1
}
    8000170a:	60a6                	ld	ra,72(sp)
    8000170c:	6406                	ld	s0,64(sp)
    8000170e:	74e2                	ld	s1,56(sp)
    80001710:	7942                	ld	s2,48(sp)
    80001712:	79a2                	ld	s3,40(sp)
    80001714:	7a02                	ld	s4,32(sp)
    80001716:	6ae2                	ld	s5,24(sp)
    80001718:	6b42                	ld	s6,16(sp)
    8000171a:	6ba2                	ld	s7,8(sp)
    8000171c:	6c02                	ld	s8,0(sp)
    8000171e:	6161                	addi	sp,sp,80
    80001720:	8082                	ret

0000000080001722 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001722:	c6bd                	beqz	a3,80001790 <copyin+0x6e>
{
    80001724:	715d                	addi	sp,sp,-80
    80001726:	e486                	sd	ra,72(sp)
    80001728:	e0a2                	sd	s0,64(sp)
    8000172a:	fc26                	sd	s1,56(sp)
    8000172c:	f84a                	sd	s2,48(sp)
    8000172e:	f44e                	sd	s3,40(sp)
    80001730:	f052                	sd	s4,32(sp)
    80001732:	ec56                	sd	s5,24(sp)
    80001734:	e85a                	sd	s6,16(sp)
    80001736:	e45e                	sd	s7,8(sp)
    80001738:	e062                	sd	s8,0(sp)
    8000173a:	0880                	addi	s0,sp,80
    8000173c:	8b2a                	mv	s6,a0
    8000173e:	8a2e                	mv	s4,a1
    80001740:	8c32                	mv	s8,a2
    80001742:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001744:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001746:	6a85                	lui	s5,0x1
    80001748:	a015                	j	8000176c <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000174a:	9562                	add	a0,a0,s8
    8000174c:	0004861b          	sext.w	a2,s1
    80001750:	412505b3          	sub	a1,a0,s2
    80001754:	8552                	mv	a0,s4
    80001756:	fffff097          	auipc	ra,0xfffff
    8000175a:	60e080e7          	jalr	1550(ra) # 80000d64 <memmove>

    len -= n;
    8000175e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001762:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001764:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001768:	02098263          	beqz	s3,8000178c <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000176c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001770:	85ca                	mv	a1,s2
    80001772:	855a                	mv	a0,s6
    80001774:	00000097          	auipc	ra,0x0
    80001778:	91e080e7          	jalr	-1762(ra) # 80001092 <walkaddr>
    if(pa0 == 0)
    8000177c:	cd01                	beqz	a0,80001794 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000177e:	418904b3          	sub	s1,s2,s8
    80001782:	94d6                	add	s1,s1,s5
    if(n > len)
    80001784:	fc99f3e3          	bgeu	s3,s1,8000174a <copyin+0x28>
    80001788:	84ce                	mv	s1,s3
    8000178a:	b7c1                	j	8000174a <copyin+0x28>
  }
  return 0;
    8000178c:	4501                	li	a0,0
    8000178e:	a021                	j	80001796 <copyin+0x74>
    80001790:	4501                	li	a0,0
}
    80001792:	8082                	ret
      return -1;
    80001794:	557d                	li	a0,-1
}
    80001796:	60a6                	ld	ra,72(sp)
    80001798:	6406                	ld	s0,64(sp)
    8000179a:	74e2                	ld	s1,56(sp)
    8000179c:	7942                	ld	s2,48(sp)
    8000179e:	79a2                	ld	s3,40(sp)
    800017a0:	7a02                	ld	s4,32(sp)
    800017a2:	6ae2                	ld	s5,24(sp)
    800017a4:	6b42                	ld	s6,16(sp)
    800017a6:	6ba2                	ld	s7,8(sp)
    800017a8:	6c02                	ld	s8,0(sp)
    800017aa:	6161                	addi	sp,sp,80
    800017ac:	8082                	ret

00000000800017ae <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017ae:	c6c5                	beqz	a3,80001856 <copyinstr+0xa8>
{
    800017b0:	715d                	addi	sp,sp,-80
    800017b2:	e486                	sd	ra,72(sp)
    800017b4:	e0a2                	sd	s0,64(sp)
    800017b6:	fc26                	sd	s1,56(sp)
    800017b8:	f84a                	sd	s2,48(sp)
    800017ba:	f44e                	sd	s3,40(sp)
    800017bc:	f052                	sd	s4,32(sp)
    800017be:	ec56                	sd	s5,24(sp)
    800017c0:	e85a                	sd	s6,16(sp)
    800017c2:	e45e                	sd	s7,8(sp)
    800017c4:	0880                	addi	s0,sp,80
    800017c6:	8a2a                	mv	s4,a0
    800017c8:	8b2e                	mv	s6,a1
    800017ca:	8bb2                	mv	s7,a2
    800017cc:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017ce:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017d0:	6985                	lui	s3,0x1
    800017d2:	a035                	j	800017fe <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017d4:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017d8:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017da:	0017b793          	seqz	a5,a5
    800017de:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017e2:	60a6                	ld	ra,72(sp)
    800017e4:	6406                	ld	s0,64(sp)
    800017e6:	74e2                	ld	s1,56(sp)
    800017e8:	7942                	ld	s2,48(sp)
    800017ea:	79a2                	ld	s3,40(sp)
    800017ec:	7a02                	ld	s4,32(sp)
    800017ee:	6ae2                	ld	s5,24(sp)
    800017f0:	6b42                	ld	s6,16(sp)
    800017f2:	6ba2                	ld	s7,8(sp)
    800017f4:	6161                	addi	sp,sp,80
    800017f6:	8082                	ret
    srcva = va0 + PGSIZE;
    800017f8:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017fc:	c8a9                	beqz	s1,8000184e <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017fe:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001802:	85ca                	mv	a1,s2
    80001804:	8552                	mv	a0,s4
    80001806:	00000097          	auipc	ra,0x0
    8000180a:	88c080e7          	jalr	-1908(ra) # 80001092 <walkaddr>
    if(pa0 == 0)
    8000180e:	c131                	beqz	a0,80001852 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001810:	41790833          	sub	a6,s2,s7
    80001814:	984e                	add	a6,a6,s3
    if(n > max)
    80001816:	0104f363          	bgeu	s1,a6,8000181c <copyinstr+0x6e>
    8000181a:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000181c:	955e                	add	a0,a0,s7
    8000181e:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001822:	fc080be3          	beqz	a6,800017f8 <copyinstr+0x4a>
    80001826:	985a                	add	a6,a6,s6
    80001828:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000182a:	41650633          	sub	a2,a0,s6
    8000182e:	14fd                	addi	s1,s1,-1
    80001830:	9b26                	add	s6,s6,s1
    80001832:	00f60733          	add	a4,a2,a5
    80001836:	00074703          	lbu	a4,0(a4)
    8000183a:	df49                	beqz	a4,800017d4 <copyinstr+0x26>
        *dst = *p;
    8000183c:	00e78023          	sb	a4,0(a5)
      --max;
    80001840:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001844:	0785                	addi	a5,a5,1
    while(n > 0){
    80001846:	ff0796e3          	bne	a5,a6,80001832 <copyinstr+0x84>
      dst++;
    8000184a:	8b42                	mv	s6,a6
    8000184c:	b775                	j	800017f8 <copyinstr+0x4a>
    8000184e:	4781                	li	a5,0
    80001850:	b769                	j	800017da <copyinstr+0x2c>
      return -1;
    80001852:	557d                	li	a0,-1
    80001854:	b779                	j	800017e2 <copyinstr+0x34>
  int got_null = 0;
    80001856:	4781                	li	a5,0
  if(got_null){
    80001858:	0017b793          	seqz	a5,a5
    8000185c:	40f00533          	neg	a0,a5
}
    80001860:	8082                	ret

0000000080001862 <leastUsedCPU>:
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

int leastUsedCPU(){ // get the CPU with least amount of processes
    80001862:	1141                	addi	sp,sp,-16
    80001864:	e422                	sd	s0,8(sp)
    80001866:	0800                	addi	s0,sp,16
  uint64 min = cpus[0].admittedProcs;
    80001868:	00010797          	auipc	a5,0x10
    8000186c:	a3878793          	addi	a5,a5,-1480 # 800112a0 <cpus>
    80001870:	63d4                	ld	a3,128(a5)
  int idMin = 0;
    80001872:	4501                	li	a0,0
  for (struct cpu * c = cpus; c < &cpus[CPUS]; c++){
    80001874:	00010617          	auipc	a2,0x10
    80001878:	e6c60613          	addi	a2,a2,-404 # 800116e0 <cpus_ll>
    uint64 procsNum = c->admittedProcs;
    if (procsNum < min){
      min = procsNum;
      idMin = c-cpus;
    8000187c:	883e                	mv	a6,a5
    8000187e:	00006597          	auipc	a1,0x6
    80001882:	78258593          	addi	a1,a1,1922 # 80008000 <etext>
  for (struct cpu * c = cpus; c < &cpus[CPUS]; c++){
    80001886:	08878793          	addi	a5,a5,136
    8000188a:	00c78d63          	beq	a5,a2,800018a4 <leastUsedCPU+0x42>
    uint64 procsNum = c->admittedProcs;
    8000188e:	63d8                	ld	a4,128(a5)
    if (procsNum < min){
    80001890:	fed77be3          	bgeu	a4,a3,80001886 <leastUsedCPU+0x24>
      idMin = c-cpus;
    80001894:	41078533          	sub	a0,a5,a6
    80001898:	850d                	srai	a0,a0,0x3
    8000189a:	6194                	ld	a3,0(a1)
    8000189c:	02d5053b          	mulw	a0,a0,a3
    uint64 procsNum = c->admittedProcs;
    800018a0:	86ba                	mv	a3,a4
    800018a2:	b7d5                	j	80001886 <leastUsedCPU+0x24>
    }     
  }
  return idMin;
  ;
}
    800018a4:	6422                	ld	s0,8(sp)
    800018a6:	0141                	addi	sp,sp,16
    800018a8:	8082                	ret

00000000800018aa <remove_from_list>:


int
remove_from_list(int p_index, int *list, struct spinlock *linked_list_lock){
    800018aa:	7159                	addi	sp,sp,-112
    800018ac:	f486                	sd	ra,104(sp)
    800018ae:	f0a2                	sd	s0,96(sp)
    800018b0:	eca6                	sd	s1,88(sp)
    800018b2:	e8ca                	sd	s2,80(sp)
    800018b4:	e4ce                	sd	s3,72(sp)
    800018b6:	e0d2                	sd	s4,64(sp)
    800018b8:	fc56                	sd	s5,56(sp)
    800018ba:	f85a                	sd	s6,48(sp)
    800018bc:	f45e                	sd	s7,40(sp)
    800018be:	f062                	sd	s8,32(sp)
    800018c0:	ec66                	sd	s9,24(sp)
    800018c2:	e86a                	sd	s10,16(sp)
    800018c4:	e46e                	sd	s11,8(sp)
    800018c6:	1880                	addi	s0,sp,112
    800018c8:	89aa                	mv	s3,a0
    800018ca:	8a2e                	mv	s4,a1
    800018cc:	84b2                	mv	s1,a2
  acquire(linked_list_lock);
    800018ce:	8532                	mv	a0,a2
    800018d0:	fffff097          	auipc	ra,0xfffff
    800018d4:	314080e7          	jalr	788(ra) # 80000be4 <acquire>
  if(*list == -1){
    800018d8:	000a2903          	lw	s2,0(s4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800018dc:	57fd                	li	a5,-1
    800018de:	06f90663          	beq	s2,a5,8000194a <remove_from_list+0xa0>
    release(linked_list_lock);
    return -1;
  }
  struct proc *p = 0;
  if(*list == p_index){
    800018e2:	07390b63          	beq	s2,s3,80001958 <remove_from_list+0xae>
    *list = p->next;
    release(&p->linked_list_lock);
    release(linked_list_lock);
    return 0;
  }
  release(linked_list_lock);
    800018e6:	8526                	mv	a0,s1
    800018e8:	fffff097          	auipc	ra,0xfffff
    800018ec:	3c2080e7          	jalr	962(ra) # 80000caa <release>
  int inList = 0;
  struct proc *pred_proc = &proc[*list];
    800018f0:	000a2503          	lw	a0,0(s4)
    800018f4:	18800493          	li	s1,392
    800018f8:	02950533          	mul	a0,a0,s1
    800018fc:	00010917          	auipc	s2,0x10
    80001900:	f7c90913          	addi	s2,s2,-132 # 80011878 <proc>
    80001904:	01250db3          	add	s11,a0,s2
  acquire(&pred_proc->linked_list_lock);
    80001908:	04050513          	addi	a0,a0,64
    8000190c:	954a                	add	a0,a0,s2
    8000190e:	fffff097          	auipc	ra,0xfffff
    80001912:	2d6080e7          	jalr	726(ra) # 80000be4 <acquire>
  p = &proc[pred_proc->next];
    80001916:	03cda503          	lw	a0,60(s11)
    8000191a:	2501                	sext.w	a0,a0
    8000191c:	02950533          	mul	a0,a0,s1
    80001920:	012504b3          	add	s1,a0,s2
  acquire(&p->linked_list_lock);
    80001924:	04050513          	addi	a0,a0,64
    80001928:	954a                	add	a0,a0,s2
    8000192a:	fffff097          	auipc	ra,0xfffff
    8000192e:	2ba080e7          	jalr	698(ra) # 80000be4 <acquire>
  int done = 0;
    80001932:	4901                	li	s2,0
  int inList = 0;
    80001934:	4d01                	li	s10,0
  while(!done){
    if (pred_proc->next == -1){
    80001936:	5afd                	li	s5,-1
      done = 1;
    80001938:	4c85                	li	s9,1
    8000193a:	8c66                	mv	s8,s9
    8000193c:	18800b93          	li	s7,392
      pred_proc->next = p->next;
      continue;
    }
    release(&pred_proc->linked_list_lock);
    pred_proc = p;
    p = &proc[p->next];
    80001940:	00010a17          	auipc	s4,0x10
    80001944:	f38a0a13          	addi	s4,s4,-200 # 80011878 <proc>
  while(!done){
    80001948:	a8b5                	j	800019c4 <remove_from_list+0x11a>
    release(linked_list_lock);
    8000194a:	8526                	mv	a0,s1
    8000194c:	fffff097          	auipc	ra,0xfffff
    80001950:	35e080e7          	jalr	862(ra) # 80000caa <release>
    return -1;
    80001954:	89ca                	mv	s3,s2
    80001956:	a845                	j	80001a06 <remove_from_list+0x15c>
    acquire(&p->linked_list_lock);
    80001958:	18800a93          	li	s5,392
    8000195c:	035989b3          	mul	s3,s3,s5
    80001960:	04098913          	addi	s2,s3,64 # 1040 <_entry-0x7fffefc0>
    80001964:	00010a97          	auipc	s5,0x10
    80001968:	f14a8a93          	addi	s5,s5,-236 # 80011878 <proc>
    8000196c:	9956                	add	s2,s2,s5
    8000196e:	854a                	mv	a0,s2
    80001970:	fffff097          	auipc	ra,0xfffff
    80001974:	274080e7          	jalr	628(ra) # 80000be4 <acquire>
    *list = p->next;
    80001978:	9ace                	add	s5,s5,s3
    8000197a:	03caa783          	lw	a5,60(s5)
    8000197e:	00fa2023          	sw	a5,0(s4)
    release(&p->linked_list_lock);
    80001982:	854a                	mv	a0,s2
    80001984:	fffff097          	auipc	ra,0xfffff
    80001988:	326080e7          	jalr	806(ra) # 80000caa <release>
    release(linked_list_lock);
    8000198c:	8526                	mv	a0,s1
    8000198e:	fffff097          	auipc	ra,0xfffff
    80001992:	31c080e7          	jalr	796(ra) # 80000caa <release>
    return 0;
    80001996:	4981                	li	s3,0
    80001998:	a0bd                	j	80001a06 <remove_from_list+0x15c>
    release(&pred_proc->linked_list_lock);
    8000199a:	040d8513          	addi	a0,s11,64
    8000199e:	fffff097          	auipc	ra,0xfffff
    800019a2:	30c080e7          	jalr	780(ra) # 80000caa <release>
    p = &proc[p->next];
    800019a6:	5cdc                	lw	a5,60(s1)
    800019a8:	2781                	sext.w	a5,a5
    800019aa:	037787b3          	mul	a5,a5,s7
    800019ae:	01478b33          	add	s6,a5,s4
    acquire(&p->linked_list_lock);
    800019b2:	04078513          	addi	a0,a5,64
    800019b6:	9552                	add	a0,a0,s4
    800019b8:	fffff097          	auipc	ra,0xfffff
    800019bc:	22c080e7          	jalr	556(ra) # 80000be4 <acquire>
    800019c0:	8da6                	mv	s11,s1
    p = &proc[p->next];
    800019c2:	84da                	mv	s1,s6
  while(!done){
    800019c4:	02091363          	bnez	s2,800019ea <remove_from_list+0x140>
    if (pred_proc->next == -1){
    800019c8:	03cda783          	lw	a5,60(s11)
    800019cc:	2781                	sext.w	a5,a5
    800019ce:	01578b63          	beq	a5,s5,800019e4 <remove_from_list+0x13a>
    if(p->index == p_index){
    800019d2:	5c9c                	lw	a5,56(s1)
    800019d4:	fd3793e3          	bne	a5,s3,8000199a <remove_from_list+0xf0>
      pred_proc->next = p->next;
    800019d8:	5cdc                	lw	a5,60(s1)
    800019da:	2781                	sext.w	a5,a5
    800019dc:	02fdae23          	sw	a5,60(s11)
      done = 1;
    800019e0:	8966                	mv	s2,s9
      continue;
    800019e2:	b7cd                	j	800019c4 <remove_from_list+0x11a>
      done = 1;
    800019e4:	8962                	mv	s2,s8
      inList = 1;
    800019e6:	8d62                	mv	s10,s8
    800019e8:	bff1                	j	800019c4 <remove_from_list+0x11a>
  }
  release(&p->linked_list_lock);
    800019ea:	04048513          	addi	a0,s1,64
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	2bc080e7          	jalr	700(ra) # 80000caa <release>
  release(&pred_proc->linked_list_lock); 
    800019f6:	040d8513          	addi	a0,s11,64
    800019fa:	fffff097          	auipc	ra,0xfffff
    800019fe:	2b0080e7          	jalr	688(ra) # 80000caa <release>
  if (inList)
    80001a02:	020d1263          	bnez	s10,80001a26 <remove_from_list+0x17c>
    return -1;
  return p_index;
}
    80001a06:	854e                	mv	a0,s3
    80001a08:	70a6                	ld	ra,104(sp)
    80001a0a:	7406                	ld	s0,96(sp)
    80001a0c:	64e6                	ld	s1,88(sp)
    80001a0e:	6946                	ld	s2,80(sp)
    80001a10:	69a6                	ld	s3,72(sp)
    80001a12:	6a06                	ld	s4,64(sp)
    80001a14:	7ae2                	ld	s5,56(sp)
    80001a16:	7b42                	ld	s6,48(sp)
    80001a18:	7ba2                	ld	s7,40(sp)
    80001a1a:	7c02                	ld	s8,32(sp)
    80001a1c:	6ce2                	ld	s9,24(sp)
    80001a1e:	6d42                	ld	s10,16(sp)
    80001a20:	6da2                	ld	s11,8(sp)
    80001a22:	6165                	addi	sp,sp,112
    80001a24:	8082                	ret
    return -1;
    80001a26:	59fd                	li	s3,-1
    80001a28:	bff9                	j	80001a06 <remove_from_list+0x15c>

0000000080001a2a <insert_cs>:

int
insert_cs(struct proc *pred, struct proc *p){  //created
    80001a2a:	7139                	addi	sp,sp,-64
    80001a2c:	fc06                	sd	ra,56(sp)
    80001a2e:	f822                	sd	s0,48(sp)
    80001a30:	f426                	sd	s1,40(sp)
    80001a32:	f04a                	sd	s2,32(sp)
    80001a34:	ec4e                	sd	s3,24(sp)
    80001a36:	e852                	sd	s4,16(sp)
    80001a38:	e456                	sd	s5,8(sp)
    80001a3a:	e05a                	sd	s6,0(sp)
    80001a3c:	0080                	addi	s0,sp,64
    80001a3e:	892a                	mv	s2,a0
    80001a40:	8aae                	mv	s5,a1
  int curr = pred->index; 
  struct spinlock *pred_lock;
  while (curr != -1) {
    80001a42:	5d18                	lw	a4,56(a0)
    80001a44:	57fd                	li	a5,-1
    80001a46:	04f70a63          	beq	a4,a5,80001a9a <insert_cs+0x70>
    //printf("the index of pred is %d ,its state is:%d, its cpu_num is %d\n ",pred->index,pred->state,pred->cpu_num);
    if(pred->next!=-1){
    80001a4a:	59fd                	li	s3,-1
    80001a4c:	18800b13          	li	s6,392
      pred_lock=&pred->linked_list_lock; // caller acquired
      pred = &proc[pred->next];
    80001a50:	00010a17          	auipc	s4,0x10
    80001a54:	e28a0a13          	addi	s4,s4,-472 # 80011878 <proc>
    80001a58:	a81d                	j	80001a8e <insert_cs+0x64>
      pred_lock=&pred->linked_list_lock; // caller acquired
    80001a5a:	04090513          	addi	a0,s2,64
      pred = &proc[pred->next];
    80001a5e:	03c92483          	lw	s1,60(s2)
    80001a62:	2481                	sext.w	s1,s1
    80001a64:	036484b3          	mul	s1,s1,s6
    80001a68:	01448933          	add	s2,s1,s4
      release(pred_lock);
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	23e080e7          	jalr	574(ra) # 80000caa <release>
      acquire(&pred->linked_list_lock);
    80001a74:	04048493          	addi	s1,s1,64
    80001a78:	009a0533          	add	a0,s4,s1
    80001a7c:	fffff097          	auipc	ra,0xfffff
    80001a80:	168080e7          	jalr	360(ra) # 80000be4 <acquire>
    }
    curr = pred->next;
    80001a84:	03c92783          	lw	a5,60(s2)
    80001a88:	2781                	sext.w	a5,a5
  while (curr != -1) {
    80001a8a:	01378863          	beq	a5,s3,80001a9a <insert_cs+0x70>
    if(pred->next!=-1){
    80001a8e:	03c92783          	lw	a5,60(s2)
    80001a92:	2781                	sext.w	a5,a5
    80001a94:	ff3788e3          	beq	a5,s3,80001a84 <insert_cs+0x5a>
    80001a98:	b7c9                	j	80001a5a <insert_cs+0x30>
    }
    pred->next = p->index;
    80001a9a:	038aa783          	lw	a5,56(s5)
    80001a9e:	02f92e23          	sw	a5,60(s2)
    release(&pred->linked_list_lock);      
    80001aa2:	04090513          	addi	a0,s2,64
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	204080e7          	jalr	516(ra) # 80000caa <release>
    p->next=-1;
    80001aae:	57fd                	li	a5,-1
    80001ab0:	02faae23          	sw	a5,60(s5)
    return p->index;
}
    80001ab4:	038aa503          	lw	a0,56(s5)
    80001ab8:	70e2                	ld	ra,56(sp)
    80001aba:	7442                	ld	s0,48(sp)
    80001abc:	74a2                	ld	s1,40(sp)
    80001abe:	7902                	ld	s2,32(sp)
    80001ac0:	69e2                	ld	s3,24(sp)
    80001ac2:	6a42                	ld	s4,16(sp)
    80001ac4:	6aa2                	ld	s5,8(sp)
    80001ac6:	6b02                	ld	s6,0(sp)
    80001ac8:	6121                	addi	sp,sp,64
    80001aca:	8082                	ret

0000000080001acc <insert_to_list>:

int
insert_to_list(int p_index, int *list,struct spinlock *lock_list){;
    80001acc:	7139                	addi	sp,sp,-64
    80001ace:	fc06                	sd	ra,56(sp)
    80001ad0:	f822                	sd	s0,48(sp)
    80001ad2:	f426                	sd	s1,40(sp)
    80001ad4:	f04a                	sd	s2,32(sp)
    80001ad6:	ec4e                	sd	s3,24(sp)
    80001ad8:	e852                	sd	s4,16(sp)
    80001ada:	e456                	sd	s5,8(sp)
    80001adc:	0080                	addi	s0,sp,64
    80001ade:	84aa                	mv	s1,a0
    80001ae0:	892e                	mv	s2,a1
    80001ae2:	89b2                	mv	s3,a2
  int ret=-1;
  acquire(lock_list);
    80001ae4:	8532                	mv	a0,a2
    80001ae6:	fffff097          	auipc	ra,0xfffff
    80001aea:	0fe080e7          	jalr	254(ra) # 80000be4 <acquire>
  if(*list==-1){
    80001aee:	00092703          	lw	a4,0(s2)
    80001af2:	57fd                	li	a5,-1
    80001af4:	04f70d63          	beq	a4,a5,80001b4e <insert_to_list+0x82>
    release(&proc[p_index].linked_list_lock);
    ret = p_index;
    release(lock_list);
  }
  else{
    release(lock_list);
    80001af8:	854e                	mv	a0,s3
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	1b0080e7          	jalr	432(ra) # 80000caa <release>
    struct proc *pred;
    pred=&proc[*list];
    80001b02:	00092903          	lw	s2,0(s2)
    80001b06:	18800a13          	li	s4,392
    80001b0a:	03490933          	mul	s2,s2,s4
    acquire(&pred->linked_list_lock);
    80001b0e:	04090513          	addi	a0,s2,64
    80001b12:	00010997          	auipc	s3,0x10
    80001b16:	d6698993          	addi	s3,s3,-666 # 80011878 <proc>
    80001b1a:	954e                	add	a0,a0,s3
    80001b1c:	fffff097          	auipc	ra,0xfffff
    80001b20:	0c8080e7          	jalr	200(ra) # 80000be4 <acquire>
    ret = insert_cs(pred, &proc[p_index]);
    80001b24:	034485b3          	mul	a1,s1,s4
    80001b28:	95ce                	add	a1,a1,s3
    80001b2a:	01298533          	add	a0,s3,s2
    80001b2e:	00000097          	auipc	ra,0x0
    80001b32:	efc080e7          	jalr	-260(ra) # 80001a2a <insert_cs>
  }
if(ret == -1){
    80001b36:	57fd                	li	a5,-1
    80001b38:	04f50d63          	beq	a0,a5,80001b92 <insert_to_list+0xc6>
  panic("insert is failed");
}
return ret;
}
    80001b3c:	70e2                	ld	ra,56(sp)
    80001b3e:	7442                	ld	s0,48(sp)
    80001b40:	74a2                	ld	s1,40(sp)
    80001b42:	7902                	ld	s2,32(sp)
    80001b44:	69e2                	ld	s3,24(sp)
    80001b46:	6a42                	ld	s4,16(sp)
    80001b48:	6aa2                	ld	s5,8(sp)
    80001b4a:	6121                	addi	sp,sp,64
    80001b4c:	8082                	ret
    *list=p_index;
    80001b4e:	00992023          	sw	s1,0(s2)
    acquire(&proc[p_index].linked_list_lock);
    80001b52:	18800a13          	li	s4,392
    80001b56:	03448ab3          	mul	s5,s1,s4
    80001b5a:	040a8913          	addi	s2,s5,64
    80001b5e:	00010a17          	auipc	s4,0x10
    80001b62:	d1aa0a13          	addi	s4,s4,-742 # 80011878 <proc>
    80001b66:	9952                	add	s2,s2,s4
    80001b68:	854a                	mv	a0,s2
    80001b6a:	fffff097          	auipc	ra,0xfffff
    80001b6e:	07a080e7          	jalr	122(ra) # 80000be4 <acquire>
    proc[p_index].next=-1;
    80001b72:	9a56                	add	s4,s4,s5
    80001b74:	57fd                	li	a5,-1
    80001b76:	02fa2e23          	sw	a5,60(s4)
    release(&proc[p_index].linked_list_lock);
    80001b7a:	854a                	mv	a0,s2
    80001b7c:	fffff097          	auipc	ra,0xfffff
    80001b80:	12e080e7          	jalr	302(ra) # 80000caa <release>
    release(lock_list);
    80001b84:	854e                	mv	a0,s3
    80001b86:	fffff097          	auipc	ra,0xfffff
    80001b8a:	124080e7          	jalr	292(ra) # 80000caa <release>
    ret = p_index;
    80001b8e:	8526                	mv	a0,s1
    80001b90:	b75d                	j	80001b36 <insert_to_list+0x6a>
  panic("insert is failed");
    80001b92:	00006517          	auipc	a0,0x6
    80001b96:	67650513          	addi	a0,a0,1654 # 80008208 <digits+0x1c8>
    80001b9a:	fffff097          	auipc	ra,0xfffff
    80001b9e:	9a4080e7          	jalr	-1628(ra) # 8000053e <panic>

0000000080001ba2 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001ba2:	7139                	addi	sp,sp,-64
    80001ba4:	fc06                	sd	ra,56(sp)
    80001ba6:	f822                	sd	s0,48(sp)
    80001ba8:	f426                	sd	s1,40(sp)
    80001baa:	f04a                	sd	s2,32(sp)
    80001bac:	ec4e                	sd	s3,24(sp)
    80001bae:	e852                	sd	s4,16(sp)
    80001bb0:	e456                	sd	s5,8(sp)
    80001bb2:	e05a                	sd	s6,0(sp)
    80001bb4:	0080                	addi	s0,sp,64
    80001bb6:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bb8:	00010497          	auipc	s1,0x10
    80001bbc:	cc048493          	addi	s1,s1,-832 # 80011878 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001bc0:	8b26                	mv	s6,s1
    80001bc2:	00006a97          	auipc	s5,0x6
    80001bc6:	446a8a93          	addi	s5,s5,1094 # 80008008 <etext+0x8>
    80001bca:	04000937          	lui	s2,0x4000
    80001bce:	197d                	addi	s2,s2,-1
    80001bd0:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd2:	00016a17          	auipc	s4,0x16
    80001bd6:	ea6a0a13          	addi	s4,s4,-346 # 80017a78 <tickslock>
    char *pa = kalloc();
    80001bda:	fffff097          	auipc	ra,0xfffff
    80001bde:	f1a080e7          	jalr	-230(ra) # 80000af4 <kalloc>
    80001be2:	862a                	mv	a2,a0
    if(pa == 0)
    80001be4:	c131                	beqz	a0,80001c28 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001be6:	416485b3          	sub	a1,s1,s6
    80001bea:	858d                	srai	a1,a1,0x3
    80001bec:	000ab783          	ld	a5,0(s5)
    80001bf0:	02f585b3          	mul	a1,a1,a5
    80001bf4:	2585                	addiw	a1,a1,1
    80001bf6:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001bfa:	4719                	li	a4,6
    80001bfc:	6685                	lui	a3,0x1
    80001bfe:	40b905b3          	sub	a1,s2,a1
    80001c02:	854e                	mv	a0,s3
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	570080e7          	jalr	1392(ra) # 80001174 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c0c:	18848493          	addi	s1,s1,392
    80001c10:	fd4495e3          	bne	s1,s4,80001bda <proc_mapstacks+0x38>
  }
}
    80001c14:	70e2                	ld	ra,56(sp)
    80001c16:	7442                	ld	s0,48(sp)
    80001c18:	74a2                	ld	s1,40(sp)
    80001c1a:	7902                	ld	s2,32(sp)
    80001c1c:	69e2                	ld	s3,24(sp)
    80001c1e:	6a42                	ld	s4,16(sp)
    80001c20:	6aa2                	ld	s5,8(sp)
    80001c22:	6b02                	ld	s6,0(sp)
    80001c24:	6121                	addi	sp,sp,64
    80001c26:	8082                	ret
      panic("kalloc");
    80001c28:	00006517          	auipc	a0,0x6
    80001c2c:	5f850513          	addi	a0,a0,1528 # 80008220 <digits+0x1e0>
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080001c38 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001c38:	711d                	addi	sp,sp,-96
    80001c3a:	ec86                	sd	ra,88(sp)
    80001c3c:	e8a2                	sd	s0,80(sp)
    80001c3e:	e4a6                	sd	s1,72(sp)
    80001c40:	e0ca                	sd	s2,64(sp)
    80001c42:	fc4e                	sd	s3,56(sp)
    80001c44:	f852                	sd	s4,48(sp)
    80001c46:	f456                	sd	s5,40(sp)
    80001c48:	f05a                	sd	s6,32(sp)
    80001c4a:	ec5e                	sd	s7,24(sp)
    80001c4c:	e862                	sd	s8,16(sp)
    80001c4e:	e466                	sd	s9,8(sp)
    80001c50:	e06a                	sd	s10,0(sp)
    80001c52:	1080                	addi	s0,sp,96
  struct proc *p;

  for (int i = 0; i<CPUS; i++){
    80001c54:	00010717          	auipc	a4,0x10
    80001c58:	a8c70713          	addi	a4,a4,-1396 # 800116e0 <cpus_ll>
    80001c5c:	0000f797          	auipc	a5,0xf
    80001c60:	64478793          	addi	a5,a5,1604 # 800112a0 <cpus>
    80001c64:	863a                	mv	a2,a4
    cpus_ll[i] = -1;
    80001c66:	56fd                	li	a3,-1
    80001c68:	c314                	sw	a3,0(a4)
    cpus[i].admittedProcs = 0; // set initial cpu's admitted to 0
    80001c6a:	0807b023          	sd	zero,128(a5)
  for (int i = 0; i<CPUS; i++){
    80001c6e:	0711                	addi	a4,a4,4
    80001c70:	08878793          	addi	a5,a5,136
    80001c74:	fec79ae3          	bne	a5,a2,80001c68 <procinit+0x30>
}
  initlock(&pid_lock, "nextpid");
    80001c78:	00006597          	auipc	a1,0x6
    80001c7c:	5b058593          	addi	a1,a1,1456 # 80008228 <digits+0x1e8>
    80001c80:	00010517          	auipc	a0,0x10
    80001c84:	a8050513          	addi	a0,a0,-1408 # 80011700 <pid_lock>
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	ecc080e7          	jalr	-308(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001c90:	00006597          	auipc	a1,0x6
    80001c94:	5a058593          	addi	a1,a1,1440 # 80008230 <digits+0x1f0>
    80001c98:	00010517          	auipc	a0,0x10
    80001c9c:	a8050513          	addi	a0,a0,-1408 # 80011718 <wait_lock>
    80001ca0:	fffff097          	auipc	ra,0xfffff
    80001ca4:	eb4080e7          	jalr	-332(ra) # 80000b54 <initlock>
  initlock(&sleeping_head,"sleeping head");
    80001ca8:	00006597          	auipc	a1,0x6
    80001cac:	59858593          	addi	a1,a1,1432 # 80008240 <digits+0x200>
    80001cb0:	00010517          	auipc	a0,0x10
    80001cb4:	a8050513          	addi	a0,a0,-1408 # 80011730 <sleeping_head>
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	e9c080e7          	jalr	-356(ra) # 80000b54 <initlock>
  initlock(&zombie_head,"zombie head");
    80001cc0:	00006597          	auipc	a1,0x6
    80001cc4:	59058593          	addi	a1,a1,1424 # 80008250 <digits+0x210>
    80001cc8:	00010517          	auipc	a0,0x10
    80001ccc:	a8050513          	addi	a0,a0,-1408 # 80011748 <zombie_head>
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	e84080e7          	jalr	-380(ra) # 80000b54 <initlock>
  initlock(&unused_head,"unused head");
    80001cd8:	00006597          	auipc	a1,0x6
    80001cdc:	58858593          	addi	a1,a1,1416 # 80008260 <digits+0x220>
    80001ce0:	00010517          	auipc	a0,0x10
    80001ce4:	a8050513          	addi	a0,a0,-1408 # 80011760 <unused_head>
    80001ce8:	fffff097          	auipc	ra,0xfffff
    80001cec:	e6c080e7          	jalr	-404(ra) # 80000b54 <initlock>
  
  int i=0;
    80001cf0:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cf2:	00010497          	auipc	s1,0x10
    80001cf6:	b8648493          	addi	s1,s1,-1146 # 80011878 <proc>
      p->kstack = KSTACK((int) (p - proc));
    80001cfa:	8d26                	mv	s10,s1
    80001cfc:	00006c97          	auipc	s9,0x6
    80001d00:	30ccbc83          	ld	s9,780(s9) # 80008008 <etext+0x8>
    80001d04:	040009b7          	lui	s3,0x4000
    80001d08:	19fd                	addi	s3,s3,-1
    80001d0a:	09b2                	slli	s3,s3,0xc

      p->state = UNUSED; 
      p->index = i;
      p->next = -1;
    80001d0c:	5c7d                	li	s8,-1
      p->cpu_num = 0;
      initlock(&p->lock, "proc");
    80001d0e:	00006b97          	auipc	s7,0x6
    80001d12:	562b8b93          	addi	s7,s7,1378 # 80008270 <digits+0x230>
     // char name[1] ;
      char * name = "inbar";
      initlock(&p->linked_list_lock, name);
    80001d16:	00006b17          	auipc	s6,0x6
    80001d1a:	562b0b13          	addi	s6,s6,1378 # 80008278 <digits+0x238>
      i++;
      insert_to_list(p->index, &unused, &unused_head);
    80001d1e:	00010a97          	auipc	s5,0x10
    80001d22:	a42a8a93          	addi	s5,s5,-1470 # 80011760 <unused_head>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d26:	00016a17          	auipc	s4,0x16
    80001d2a:	d52a0a13          	addi	s4,s4,-686 # 80017a78 <tickslock>
      p->kstack = KSTACK((int) (p - proc));
    80001d2e:	41a487b3          	sub	a5,s1,s10
    80001d32:	878d                	srai	a5,a5,0x3
    80001d34:	039787b3          	mul	a5,a5,s9
    80001d38:	2785                	addiw	a5,a5,1
    80001d3a:	00d7979b          	slliw	a5,a5,0xd
    80001d3e:	40f987b3          	sub	a5,s3,a5
    80001d42:	f0bc                	sd	a5,96(s1)
      p->state = UNUSED; 
    80001d44:	0004ac23          	sw	zero,24(s1)
      p->index = i;
    80001d48:	0324ac23          	sw	s2,56(s1)
      p->next = -1;
    80001d4c:	0384ae23          	sw	s8,60(s1)
      p->cpu_num = 0;
    80001d50:	0204aa23          	sw	zero,52(s1)
      initlock(&p->lock, "proc");
    80001d54:	85de                	mv	a1,s7
    80001d56:	8526                	mv	a0,s1
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	dfc080e7          	jalr	-516(ra) # 80000b54 <initlock>
      initlock(&p->linked_list_lock, name);
    80001d60:	85da                	mv	a1,s6
    80001d62:	04048513          	addi	a0,s1,64
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	dee080e7          	jalr	-530(ra) # 80000b54 <initlock>
      i++;
    80001d6e:	2905                	addiw	s2,s2,1
      insert_to_list(p->index, &unused, &unused_head);
    80001d70:	8656                	mv	a2,s5
    80001d72:	00007597          	auipc	a1,0x7
    80001d76:	b5258593          	addi	a1,a1,-1198 # 800088c4 <unused>
    80001d7a:	5c88                	lw	a0,56(s1)
    80001d7c:	00000097          	auipc	ra,0x0
    80001d80:	d50080e7          	jalr	-688(ra) # 80001acc <insert_to_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d84:	18848493          	addi	s1,s1,392
    80001d88:	fb4493e3          	bne	s1,s4,80001d2e <procinit+0xf6>
  }
}
    80001d8c:	60e6                	ld	ra,88(sp)
    80001d8e:	6446                	ld	s0,80(sp)
    80001d90:	64a6                	ld	s1,72(sp)
    80001d92:	6906                	ld	s2,64(sp)
    80001d94:	79e2                	ld	s3,56(sp)
    80001d96:	7a42                	ld	s4,48(sp)
    80001d98:	7aa2                	ld	s5,40(sp)
    80001d9a:	7b02                	ld	s6,32(sp)
    80001d9c:	6be2                	ld	s7,24(sp)
    80001d9e:	6c42                	ld	s8,16(sp)
    80001da0:	6ca2                	ld	s9,8(sp)
    80001da2:	6d02                	ld	s10,0(sp)
    80001da4:	6125                	addi	sp,sp,96
    80001da6:	8082                	ret

0000000080001da8 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001da8:	1141                	addi	sp,sp,-16
    80001daa:	e422                	sd	s0,8(sp)
    80001dac:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001dae:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001db0:	2501                	sext.w	a0,a0
    80001db2:	6422                	ld	s0,8(sp)
    80001db4:	0141                	addi	sp,sp,16
    80001db6:	8082                	ret

0000000080001db8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) { 
    80001db8:	1141                	addi	sp,sp,-16
    80001dba:	e422                	sd	s0,8(sp)
    80001dbc:	0800                	addi	s0,sp,16
    80001dbe:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001dc0:	0007851b          	sext.w	a0,a5
    80001dc4:	00451793          	slli	a5,a0,0x4
    80001dc8:	97aa                	add	a5,a5,a0
    80001dca:	078e                	slli	a5,a5,0x3
  return c;
}
    80001dcc:	0000f517          	auipc	a0,0xf
    80001dd0:	4d450513          	addi	a0,a0,1236 # 800112a0 <cpus>
    80001dd4:	953e                	add	a0,a0,a5
    80001dd6:	6422                	ld	s0,8(sp)
    80001dd8:	0141                	addi	sp,sp,16
    80001dda:	8082                	ret

0000000080001ddc <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001ddc:	1101                	addi	sp,sp,-32
    80001dde:	ec06                	sd	ra,24(sp)
    80001de0:	e822                	sd	s0,16(sp)
    80001de2:	e426                	sd	s1,8(sp)
    80001de4:	1000                	addi	s0,sp,32
  push_off();
    80001de6:	fffff097          	auipc	ra,0xfffff
    80001dea:	db2080e7          	jalr	-590(ra) # 80000b98 <push_off>
    80001dee:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001df0:	0007871b          	sext.w	a4,a5
    80001df4:	00471793          	slli	a5,a4,0x4
    80001df8:	97ba                	add	a5,a5,a4
    80001dfa:	078e                	slli	a5,a5,0x3
    80001dfc:	0000f717          	auipc	a4,0xf
    80001e00:	4a470713          	addi	a4,a4,1188 # 800112a0 <cpus>
    80001e04:	97ba                	add	a5,a5,a4
    80001e06:	6384                	ld	s1,0(a5)
  pop_off();
    80001e08:	fffff097          	auipc	ra,0xfffff
    80001e0c:	e42080e7          	jalr	-446(ra) # 80000c4a <pop_off>
  return p;
}
    80001e10:	8526                	mv	a0,s1
    80001e12:	60e2                	ld	ra,24(sp)
    80001e14:	6442                	ld	s0,16(sp)
    80001e16:	64a2                	ld	s1,8(sp)
    80001e18:	6105                	addi	sp,sp,32
    80001e1a:	8082                	ret

0000000080001e1c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001e1c:	1141                	addi	sp,sp,-16
    80001e1e:	e406                	sd	ra,8(sp)
    80001e20:	e022                	sd	s0,0(sp)
    80001e22:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001e24:	00000097          	auipc	ra,0x0
    80001e28:	fb8080e7          	jalr	-72(ra) # 80001ddc <myproc>
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	e7e080e7          	jalr	-386(ra) # 80000caa <release>


  if (first) {
    80001e34:	00007797          	auipc	a5,0x7
    80001e38:	a8c7a783          	lw	a5,-1396(a5) # 800088c0 <first.1746>
    80001e3c:	eb89                	bnez	a5,80001e4e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001e3e:	00001097          	auipc	ra,0x1
    80001e42:	f9a080e7          	jalr	-102(ra) # 80002dd8 <usertrapret>
}
    80001e46:	60a2                	ld	ra,8(sp)
    80001e48:	6402                	ld	s0,0(sp)
    80001e4a:	0141                	addi	sp,sp,16
    80001e4c:	8082                	ret
    first = 0;
    80001e4e:	00007797          	auipc	a5,0x7
    80001e52:	a607a923          	sw	zero,-1422(a5) # 800088c0 <first.1746>
    fsinit(ROOTDEV);
    80001e56:	4505                	li	a0,1
    80001e58:	00002097          	auipc	ra,0x2
    80001e5c:	d3e080e7          	jalr	-706(ra) # 80003b96 <fsinit>
    80001e60:	bff9                	j	80001e3e <forkret+0x22>

0000000080001e62 <inc_cpu_usage>:
inc_cpu_usage(int cpu_num){
    80001e62:	1101                	addi	sp,sp,-32
    80001e64:	ec06                	sd	ra,24(sp)
    80001e66:	e822                	sd	s0,16(sp)
    80001e68:	e426                	sd	s1,8(sp)
    80001e6a:	e04a                	sd	s2,0(sp)
    80001e6c:	1000                	addi	s0,sp,32
  } while (cas(&c->admittedProcs, usage, usage + 1));
    80001e6e:	00451493          	slli	s1,a0,0x4
    80001e72:	94aa                	add	s1,s1,a0
    80001e74:	048e                	slli	s1,s1,0x3
    80001e76:	0000f797          	auipc	a5,0xf
    80001e7a:	4aa78793          	addi	a5,a5,1194 # 80011320 <cpus+0x80>
    80001e7e:	94be                	add	s1,s1,a5
    usage = c->admittedProcs;
    80001e80:	00451913          	slli	s2,a0,0x4
    80001e84:	954a                	add	a0,a0,s2
    80001e86:	050e                	slli	a0,a0,0x3
    80001e88:	0000f917          	auipc	s2,0xf
    80001e8c:	41890913          	addi	s2,s2,1048 # 800112a0 <cpus>
    80001e90:	992a                	add	s2,s2,a0
    80001e92:	08093583          	ld	a1,128(s2)
  } while (cas(&c->admittedProcs, usage, usage + 1));
    80001e96:	0015861b          	addiw	a2,a1,1
    80001e9a:	2581                	sext.w	a1,a1
    80001e9c:	8526                	mv	a0,s1
    80001e9e:	00005097          	auipc	ra,0x5
    80001ea2:	af8080e7          	jalr	-1288(ra) # 80006996 <cas>
    80001ea6:	f575                	bnez	a0,80001e92 <inc_cpu_usage+0x30>
}
    80001ea8:	60e2                	ld	ra,24(sp)
    80001eaa:	6442                	ld	s0,16(sp)
    80001eac:	64a2                	ld	s1,8(sp)
    80001eae:	6902                	ld	s2,0(sp)
    80001eb0:	6105                	addi	sp,sp,32
    80001eb2:	8082                	ret

0000000080001eb4 <allocpid>:
allocpid() {
    80001eb4:	1101                	addi	sp,sp,-32
    80001eb6:	ec06                	sd	ra,24(sp)
    80001eb8:	e822                	sd	s0,16(sp)
    80001eba:	e426                	sd	s1,8(sp)
    80001ebc:	e04a                	sd	s2,0(sp)
    80001ebe:	1000                	addi	s0,sp,32
      pid = nextpid;
    80001ec0:	00007917          	auipc	s2,0x7
    80001ec4:	a1090913          	addi	s2,s2,-1520 # 800088d0 <nextpid>
    80001ec8:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, pid+1));
    80001ecc:	0014861b          	addiw	a2,s1,1
    80001ed0:	85a6                	mv	a1,s1
    80001ed2:	854a                	mv	a0,s2
    80001ed4:	00005097          	auipc	ra,0x5
    80001ed8:	ac2080e7          	jalr	-1342(ra) # 80006996 <cas>
    80001edc:	f575                	bnez	a0,80001ec8 <allocpid+0x14>
}
    80001ede:	8526                	mv	a0,s1
    80001ee0:	60e2                	ld	ra,24(sp)
    80001ee2:	6442                	ld	s0,16(sp)
    80001ee4:	64a2                	ld	s1,8(sp)
    80001ee6:	6902                	ld	s2,0(sp)
    80001ee8:	6105                	addi	sp,sp,32
    80001eea:	8082                	ret

0000000080001eec <proc_pagetable>:
{
    80001eec:	1101                	addi	sp,sp,-32
    80001eee:	ec06                	sd	ra,24(sp)
    80001ef0:	e822                	sd	s0,16(sp)
    80001ef2:	e426                	sd	s1,8(sp)
    80001ef4:	e04a                	sd	s2,0(sp)
    80001ef6:	1000                	addi	s0,sp,32
    80001ef8:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001efa:	fffff097          	auipc	ra,0xfffff
    80001efe:	464080e7          	jalr	1124(ra) # 8000135e <uvmcreate>
    80001f02:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001f04:	c121                	beqz	a0,80001f44 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001f06:	4729                	li	a4,10
    80001f08:	00005697          	auipc	a3,0x5
    80001f0c:	0f868693          	addi	a3,a3,248 # 80007000 <_trampoline>
    80001f10:	6605                	lui	a2,0x1
    80001f12:	040005b7          	lui	a1,0x4000
    80001f16:	15fd                	addi	a1,a1,-1
    80001f18:	05b2                	slli	a1,a1,0xc
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	1ba080e7          	jalr	442(ra) # 800010d4 <mappages>
    80001f22:	02054863          	bltz	a0,80001f52 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001f26:	4719                	li	a4,6
    80001f28:	07893683          	ld	a3,120(s2)
    80001f2c:	6605                	lui	a2,0x1
    80001f2e:	020005b7          	lui	a1,0x2000
    80001f32:	15fd                	addi	a1,a1,-1
    80001f34:	05b6                	slli	a1,a1,0xd
    80001f36:	8526                	mv	a0,s1
    80001f38:	fffff097          	auipc	ra,0xfffff
    80001f3c:	19c080e7          	jalr	412(ra) # 800010d4 <mappages>
    80001f40:	02054163          	bltz	a0,80001f62 <proc_pagetable+0x76>
}
    80001f44:	8526                	mv	a0,s1
    80001f46:	60e2                	ld	ra,24(sp)
    80001f48:	6442                	ld	s0,16(sp)
    80001f4a:	64a2                	ld	s1,8(sp)
    80001f4c:	6902                	ld	s2,0(sp)
    80001f4e:	6105                	addi	sp,sp,32
    80001f50:	8082                	ret
    uvmfree(pagetable, 0);
    80001f52:	4581                	li	a1,0
    80001f54:	8526                	mv	a0,s1
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	604080e7          	jalr	1540(ra) # 8000155a <uvmfree>
    return 0;
    80001f5e:	4481                	li	s1,0
    80001f60:	b7d5                	j	80001f44 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f62:	4681                	li	a3,0
    80001f64:	4605                	li	a2,1
    80001f66:	040005b7          	lui	a1,0x4000
    80001f6a:	15fd                	addi	a1,a1,-1
    80001f6c:	05b2                	slli	a1,a1,0xc
    80001f6e:	8526                	mv	a0,s1
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	32a080e7          	jalr	810(ra) # 8000129a <uvmunmap>
    uvmfree(pagetable, 0);
    80001f78:	4581                	li	a1,0
    80001f7a:	8526                	mv	a0,s1
    80001f7c:	fffff097          	auipc	ra,0xfffff
    80001f80:	5de080e7          	jalr	1502(ra) # 8000155a <uvmfree>
    return 0;
    80001f84:	4481                	li	s1,0
    80001f86:	bf7d                	j	80001f44 <proc_pagetable+0x58>

0000000080001f88 <proc_freepagetable>:
{
    80001f88:	1101                	addi	sp,sp,-32
    80001f8a:	ec06                	sd	ra,24(sp)
    80001f8c:	e822                	sd	s0,16(sp)
    80001f8e:	e426                	sd	s1,8(sp)
    80001f90:	e04a                	sd	s2,0(sp)
    80001f92:	1000                	addi	s0,sp,32
    80001f94:	84aa                	mv	s1,a0
    80001f96:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f98:	4681                	li	a3,0
    80001f9a:	4605                	li	a2,1
    80001f9c:	040005b7          	lui	a1,0x4000
    80001fa0:	15fd                	addi	a1,a1,-1
    80001fa2:	05b2                	slli	a1,a1,0xc
    80001fa4:	fffff097          	auipc	ra,0xfffff
    80001fa8:	2f6080e7          	jalr	758(ra) # 8000129a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001fac:	4681                	li	a3,0
    80001fae:	4605                	li	a2,1
    80001fb0:	020005b7          	lui	a1,0x2000
    80001fb4:	15fd                	addi	a1,a1,-1
    80001fb6:	05b6                	slli	a1,a1,0xd
    80001fb8:	8526                	mv	a0,s1
    80001fba:	fffff097          	auipc	ra,0xfffff
    80001fbe:	2e0080e7          	jalr	736(ra) # 8000129a <uvmunmap>
  uvmfree(pagetable, sz);
    80001fc2:	85ca                	mv	a1,s2
    80001fc4:	8526                	mv	a0,s1
    80001fc6:	fffff097          	auipc	ra,0xfffff
    80001fca:	594080e7          	jalr	1428(ra) # 8000155a <uvmfree>
}
    80001fce:	60e2                	ld	ra,24(sp)
    80001fd0:	6442                	ld	s0,16(sp)
    80001fd2:	64a2                	ld	s1,8(sp)
    80001fd4:	6902                	ld	s2,0(sp)
    80001fd6:	6105                	addi	sp,sp,32
    80001fd8:	8082                	ret

0000000080001fda <freeproc>:
{
    80001fda:	1101                	addi	sp,sp,-32
    80001fdc:	ec06                	sd	ra,24(sp)
    80001fde:	e822                	sd	s0,16(sp)
    80001fe0:	e426                	sd	s1,8(sp)
    80001fe2:	1000                	addi	s0,sp,32
    80001fe4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001fe6:	7d28                	ld	a0,120(a0)
    80001fe8:	c509                	beqz	a0,80001ff2 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001fea:	fffff097          	auipc	ra,0xfffff
    80001fee:	a0e080e7          	jalr	-1522(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001ff2:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    80001ff6:	78a8                	ld	a0,112(s1)
    80001ff8:	c511                	beqz	a0,80002004 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ffa:	74ac                	ld	a1,104(s1)
    80001ffc:	00000097          	auipc	ra,0x0
    80002000:	f8c080e7          	jalr	-116(ra) # 80001f88 <proc_freepagetable>
  p->pagetable = 0;
    80002004:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80002008:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    8000200c:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80002010:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    80002014:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    80002018:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    8000201c:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80002020:	0204a623          	sw	zero,44(s1)
 remove_from_list(p->index, &zombie, &zombie_head);
    80002024:	0000f617          	auipc	a2,0xf
    80002028:	72460613          	addi	a2,a2,1828 # 80011748 <zombie_head>
    8000202c:	00007597          	auipc	a1,0x7
    80002030:	89c58593          	addi	a1,a1,-1892 # 800088c8 <zombie>
    80002034:	5c88                	lw	a0,56(s1)
    80002036:	00000097          	auipc	ra,0x0
    8000203a:	874080e7          	jalr	-1932(ra) # 800018aa <remove_from_list>
  p->state = UNUSED;
    8000203e:	0004ac23          	sw	zero,24(s1)
  insert_to_list(p->index, &unused, &unused_head);
    80002042:	0000f617          	auipc	a2,0xf
    80002046:	71e60613          	addi	a2,a2,1822 # 80011760 <unused_head>
    8000204a:	00007597          	auipc	a1,0x7
    8000204e:	87a58593          	addi	a1,a1,-1926 # 800088c4 <unused>
    80002052:	5c88                	lw	a0,56(s1)
    80002054:	00000097          	auipc	ra,0x0
    80002058:	a78080e7          	jalr	-1416(ra) # 80001acc <insert_to_list>
}
    8000205c:	60e2                	ld	ra,24(sp)
    8000205e:	6442                	ld	s0,16(sp)
    80002060:	64a2                	ld	s1,8(sp)
    80002062:	6105                	addi	sp,sp,32
    80002064:	8082                	ret

0000000080002066 <allocproc>:
{
    80002066:	7179                	addi	sp,sp,-48
    80002068:	f406                	sd	ra,40(sp)
    8000206a:	f022                	sd	s0,32(sp)
    8000206c:	ec26                	sd	s1,24(sp)
    8000206e:	e84a                	sd	s2,16(sp)
    80002070:	e44e                	sd	s3,8(sp)
    80002072:	e052                	sd	s4,0(sp)
    80002074:	1800                	addi	s0,sp,48
  if(unused != -1){
    80002076:	00007917          	auipc	s2,0x7
    8000207a:	84e92903          	lw	s2,-1970(s2) # 800088c4 <unused>
    8000207e:	57fd                	li	a5,-1
  return 0;
    80002080:	4481                	li	s1,0
  if(unused != -1){
    80002082:	0af90b63          	beq	s2,a5,80002138 <allocproc+0xd2>
    p = &proc[unused];
    80002086:	18800993          	li	s3,392
    8000208a:	033909b3          	mul	s3,s2,s3
    8000208e:	0000f497          	auipc	s1,0xf
    80002092:	7ea48493          	addi	s1,s1,2026 # 80011878 <proc>
    80002096:	94ce                	add	s1,s1,s3
    remove_from_list(p->index,&unused, &unused_head);
    80002098:	0000f617          	auipc	a2,0xf
    8000209c:	6c860613          	addi	a2,a2,1736 # 80011760 <unused_head>
    800020a0:	00007597          	auipc	a1,0x7
    800020a4:	82458593          	addi	a1,a1,-2012 # 800088c4 <unused>
    800020a8:	5c88                	lw	a0,56(s1)
    800020aa:	00000097          	auipc	ra,0x0
    800020ae:	800080e7          	jalr	-2048(ra) # 800018aa <remove_from_list>
    acquire(&p->lock);
    800020b2:	8526                	mv	a0,s1
    800020b4:	fffff097          	auipc	ra,0xfffff
    800020b8:	b30080e7          	jalr	-1232(ra) # 80000be4 <acquire>
  p->pid = allocpid();
    800020bc:	00000097          	auipc	ra,0x0
    800020c0:	df8080e7          	jalr	-520(ra) # 80001eb4 <allocpid>
    800020c4:	d888                	sw	a0,48(s1)
  p->state = USED;
    800020c6:	4785                	li	a5,1
    800020c8:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800020ca:	fffff097          	auipc	ra,0xfffff
    800020ce:	a2a080e7          	jalr	-1494(ra) # 80000af4 <kalloc>
    800020d2:	8a2a                	mv	s4,a0
    800020d4:	fca8                	sd	a0,120(s1)
    800020d6:	c935                	beqz	a0,8000214a <allocproc+0xe4>
  p->pagetable = proc_pagetable(p);
    800020d8:	8526                	mv	a0,s1
    800020da:	00000097          	auipc	ra,0x0
    800020de:	e12080e7          	jalr	-494(ra) # 80001eec <proc_pagetable>
    800020e2:	8a2a                	mv	s4,a0
    800020e4:	18800793          	li	a5,392
    800020e8:	02f90733          	mul	a4,s2,a5
    800020ec:	0000f797          	auipc	a5,0xf
    800020f0:	78c78793          	addi	a5,a5,1932 # 80011878 <proc>
    800020f4:	97ba                	add	a5,a5,a4
    800020f6:	fba8                	sd	a0,112(a5)
  if(p->pagetable == 0){
    800020f8:	c52d                	beqz	a0,80002162 <allocproc+0xfc>
  memset(&p->context, 0, sizeof(p->context));
    800020fa:	08098513          	addi	a0,s3,128 # 4000080 <_entry-0x7bffff80>
    800020fe:	0000fa17          	auipc	s4,0xf
    80002102:	77aa0a13          	addi	s4,s4,1914 # 80011878 <proc>
    80002106:	07000613          	li	a2,112
    8000210a:	4581                	li	a1,0
    8000210c:	9552                	add	a0,a0,s4
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	bf6080e7          	jalr	-1034(ra) # 80000d04 <memset>
  p->context.ra = (uint64)forkret;
    80002116:	18800793          	li	a5,392
    8000211a:	02f90933          	mul	s2,s2,a5
    8000211e:	9952                	add	s2,s2,s4
    80002120:	00000797          	auipc	a5,0x0
    80002124:	cfc78793          	addi	a5,a5,-772 # 80001e1c <forkret>
    80002128:	08f93023          	sd	a5,128(s2)
  p->context.sp = p->kstack + PGSIZE;
    8000212c:	06093783          	ld	a5,96(s2)
    80002130:	6705                	lui	a4,0x1
    80002132:	97ba                	add	a5,a5,a4
    80002134:	08f93423          	sd	a5,136(s2)
}
    80002138:	8526                	mv	a0,s1
    8000213a:	70a2                	ld	ra,40(sp)
    8000213c:	7402                	ld	s0,32(sp)
    8000213e:	64e2                	ld	s1,24(sp)
    80002140:	6942                	ld	s2,16(sp)
    80002142:	69a2                	ld	s3,8(sp)
    80002144:	6a02                	ld	s4,0(sp)
    80002146:	6145                	addi	sp,sp,48
    80002148:	8082                	ret
    freeproc(p);
    8000214a:	8526                	mv	a0,s1
    8000214c:	00000097          	auipc	ra,0x0
    80002150:	e8e080e7          	jalr	-370(ra) # 80001fda <freeproc>
    release(&p->lock);
    80002154:	8526                	mv	a0,s1
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	b54080e7          	jalr	-1196(ra) # 80000caa <release>
    return 0;
    8000215e:	84d2                	mv	s1,s4
    80002160:	bfe1                	j	80002138 <allocproc+0xd2>
    freeproc(p);
    80002162:	8526                	mv	a0,s1
    80002164:	00000097          	auipc	ra,0x0
    80002168:	e76080e7          	jalr	-394(ra) # 80001fda <freeproc>
    release(&p->lock);
    8000216c:	8526                	mv	a0,s1
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	b3c080e7          	jalr	-1220(ra) # 80000caa <release>
    return 0;
    80002176:	84d2                	mv	s1,s4
    80002178:	b7c1                	j	80002138 <allocproc+0xd2>

000000008000217a <userinit>:
{
    8000217a:	1101                	addi	sp,sp,-32
    8000217c:	ec06                	sd	ra,24(sp)
    8000217e:	e822                	sd	s0,16(sp)
    80002180:	e426                	sd	s1,8(sp)
    80002182:	1000                	addi	s0,sp,32
  p = allocproc();
    80002184:	00000097          	auipc	ra,0x0
    80002188:	ee2080e7          	jalr	-286(ra) # 80002066 <allocproc>
    8000218c:	84aa                	mv	s1,a0
  initproc = p;
    8000218e:	00007797          	auipc	a5,0x7
    80002192:	e8a7bd23          	sd	a0,-358(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002196:	03400613          	li	a2,52
    8000219a:	00006597          	auipc	a1,0x6
    8000219e:	74658593          	addi	a1,a1,1862 # 800088e0 <initcode>
    800021a2:	7928                	ld	a0,112(a0)
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	1e8080e7          	jalr	488(ra) # 8000138c <uvminit>
  p->sz = PGSIZE;
    800021ac:	6785                	lui	a5,0x1
    800021ae:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    800021b0:	7cb8                	ld	a4,120(s1)
    800021b2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800021b6:	7cb8                	ld	a4,120(s1)
    800021b8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800021ba:	4641                	li	a2,16
    800021bc:	00006597          	auipc	a1,0x6
    800021c0:	0c458593          	addi	a1,a1,196 # 80008280 <digits+0x240>
    800021c4:	17848513          	addi	a0,s1,376
    800021c8:	fffff097          	auipc	ra,0xfffff
    800021cc:	c8e080e7          	jalr	-882(ra) # 80000e56 <safestrcpy>
  p->cwd = namei("/");
    800021d0:	00006517          	auipc	a0,0x6
    800021d4:	0c050513          	addi	a0,a0,192 # 80008290 <digits+0x250>
    800021d8:	00002097          	auipc	ra,0x2
    800021dc:	3ec080e7          	jalr	1004(ra) # 800045c4 <namei>
    800021e0:	16a4b823          	sd	a0,368(s1)
  insert_to_list(p->index, &cpus_ll[0], &cpus_head[0]);
    800021e4:	0000f617          	auipc	a2,0xf
    800021e8:	59460613          	addi	a2,a2,1428 # 80011778 <cpus_head>
    800021ec:	0000f597          	auipc	a1,0xf
    800021f0:	4f458593          	addi	a1,a1,1268 # 800116e0 <cpus_ll>
    800021f4:	5c88                	lw	a0,56(s1)
    800021f6:	00000097          	auipc	ra,0x0
    800021fa:	8d6080e7          	jalr	-1834(ra) # 80001acc <insert_to_list>
  inc_cpu_usage(0);
    800021fe:	4501                	li	a0,0
    80002200:	00000097          	auipc	ra,0x0
    80002204:	c62080e7          	jalr	-926(ra) # 80001e62 <inc_cpu_usage>
  p->state = RUNNABLE;
    80002208:	478d                	li	a5,3
    8000220a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    8000220c:	8526                	mv	a0,s1
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	a9c080e7          	jalr	-1380(ra) # 80000caa <release>
}
    80002216:	60e2                	ld	ra,24(sp)
    80002218:	6442                	ld	s0,16(sp)
    8000221a:	64a2                	ld	s1,8(sp)
    8000221c:	6105                	addi	sp,sp,32
    8000221e:	8082                	ret

0000000080002220 <growproc>:
{
    80002220:	1101                	addi	sp,sp,-32
    80002222:	ec06                	sd	ra,24(sp)
    80002224:	e822                	sd	s0,16(sp)
    80002226:	e426                	sd	s1,8(sp)
    80002228:	e04a                	sd	s2,0(sp)
    8000222a:	1000                	addi	s0,sp,32
    8000222c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000222e:	00000097          	auipc	ra,0x0
    80002232:	bae080e7          	jalr	-1106(ra) # 80001ddc <myproc>
    80002236:	892a                	mv	s2,a0
  sz = p->sz;
    80002238:	752c                	ld	a1,104(a0)
    8000223a:	0005861b          	sext.w	a2,a1
  if(n > 0){
    8000223e:	00904f63          	bgtz	s1,8000225c <growproc+0x3c>
  } else if(n < 0){
    80002242:	0204cc63          	bltz	s1,8000227a <growproc+0x5a>
  p->sz = sz;
    80002246:	1602                	slli	a2,a2,0x20
    80002248:	9201                	srli	a2,a2,0x20
    8000224a:	06c93423          	sd	a2,104(s2)
  return 0;
    8000224e:	4501                	li	a0,0
}
    80002250:	60e2                	ld	ra,24(sp)
    80002252:	6442                	ld	s0,16(sp)
    80002254:	64a2                	ld	s1,8(sp)
    80002256:	6902                	ld	s2,0(sp)
    80002258:	6105                	addi	sp,sp,32
    8000225a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000225c:	9e25                	addw	a2,a2,s1
    8000225e:	1602                	slli	a2,a2,0x20
    80002260:	9201                	srli	a2,a2,0x20
    80002262:	1582                	slli	a1,a1,0x20
    80002264:	9181                	srli	a1,a1,0x20
    80002266:	7928                	ld	a0,112(a0)
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	1de080e7          	jalr	478(ra) # 80001446 <uvmalloc>
    80002270:	0005061b          	sext.w	a2,a0
    80002274:	fa69                	bnez	a2,80002246 <growproc+0x26>
      return -1;
    80002276:	557d                	li	a0,-1
    80002278:	bfe1                	j	80002250 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000227a:	9e25                	addw	a2,a2,s1
    8000227c:	1602                	slli	a2,a2,0x20
    8000227e:	9201                	srli	a2,a2,0x20
    80002280:	1582                	slli	a1,a1,0x20
    80002282:	9181                	srli	a1,a1,0x20
    80002284:	7928                	ld	a0,112(a0)
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	178080e7          	jalr	376(ra) # 800013fe <uvmdealloc>
    8000228e:	0005061b          	sext.w	a2,a0
    80002292:	bf55                	j	80002246 <growproc+0x26>

0000000080002294 <fork>:
{
    80002294:	7179                	addi	sp,sp,-48
    80002296:	f406                	sd	ra,40(sp)
    80002298:	f022                	sd	s0,32(sp)
    8000229a:	ec26                	sd	s1,24(sp)
    8000229c:	e84a                	sd	s2,16(sp)
    8000229e:	e44e                	sd	s3,8(sp)
    800022a0:	e052                	sd	s4,0(sp)
    800022a2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800022a4:	00000097          	auipc	ra,0x0
    800022a8:	b38080e7          	jalr	-1224(ra) # 80001ddc <myproc>
    800022ac:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    800022ae:	00000097          	auipc	ra,0x0
    800022b2:	db8080e7          	jalr	-584(ra) # 80002066 <allocproc>
    800022b6:	14050e63          	beqz	a0,80002412 <fork+0x17e>
    800022ba:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800022bc:	0689b603          	ld	a2,104(s3)
    800022c0:	792c                	ld	a1,112(a0)
    800022c2:	0709b503          	ld	a0,112(s3)
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	2cc080e7          	jalr	716(ra) # 80001592 <uvmcopy>
    800022ce:	04054663          	bltz	a0,8000231a <fork+0x86>
  np->sz = p->sz;
    800022d2:	0689b783          	ld	a5,104(s3)
    800022d6:	06f93423          	sd	a5,104(s2)
  *(np->trapframe) = *(p->trapframe);
    800022da:	0789b683          	ld	a3,120(s3)
    800022de:	87b6                	mv	a5,a3
    800022e0:	07893703          	ld	a4,120(s2)
    800022e4:	12068693          	addi	a3,a3,288
    800022e8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800022ec:	6788                	ld	a0,8(a5)
    800022ee:	6b8c                	ld	a1,16(a5)
    800022f0:	6f90                	ld	a2,24(a5)
    800022f2:	01073023          	sd	a6,0(a4)
    800022f6:	e708                	sd	a0,8(a4)
    800022f8:	eb0c                	sd	a1,16(a4)
    800022fa:	ef10                	sd	a2,24(a4)
    800022fc:	02078793          	addi	a5,a5,32
    80002300:	02070713          	addi	a4,a4,32
    80002304:	fed792e3          	bne	a5,a3,800022e8 <fork+0x54>
  np->trapframe->a0 = 0;
    80002308:	07893783          	ld	a5,120(s2)
    8000230c:	0607b823          	sd	zero,112(a5)
    80002310:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    80002314:	17000a13          	li	s4,368
    80002318:	a03d                	j	80002346 <fork+0xb2>
    freeproc(np);
    8000231a:	854a                	mv	a0,s2
    8000231c:	00000097          	auipc	ra,0x0
    80002320:	cbe080e7          	jalr	-834(ra) # 80001fda <freeproc>
    release(&np->lock);
    80002324:	854a                	mv	a0,s2
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	984080e7          	jalr	-1660(ra) # 80000caa <release>
    return -1;
    8000232e:	5a7d                	li	s4,-1
    80002330:	a8c1                	j	80002400 <fork+0x16c>
      np->ofile[i] = filedup(p->ofile[i]);
    80002332:	00003097          	auipc	ra,0x3
    80002336:	928080e7          	jalr	-1752(ra) # 80004c5a <filedup>
    8000233a:	009907b3          	add	a5,s2,s1
    8000233e:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002340:	04a1                	addi	s1,s1,8
    80002342:	01448763          	beq	s1,s4,80002350 <fork+0xbc>
    if(p->ofile[i])
    80002346:	009987b3          	add	a5,s3,s1
    8000234a:	6388                	ld	a0,0(a5)
    8000234c:	f17d                	bnez	a0,80002332 <fork+0x9e>
    8000234e:	bfcd                	j	80002340 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002350:	1709b503          	ld	a0,368(s3)
    80002354:	00002097          	auipc	ra,0x2
    80002358:	a7c080e7          	jalr	-1412(ra) # 80003dd0 <idup>
    8000235c:	16a93823          	sd	a0,368(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002360:	17890493          	addi	s1,s2,376
    80002364:	4641                	li	a2,16
    80002366:	17898593          	addi	a1,s3,376
    8000236a:	8526                	mv	a0,s1
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	aea080e7          	jalr	-1302(ra) # 80000e56 <safestrcpy>
  pid = np->pid;
    80002374:	03092a03          	lw	s4,48(s2)
  np->cpu_num = p->cpu_num; //giving the child it's parent's cpu_num
    80002378:	0349a783          	lw	a5,52(s3)
    8000237c:	02f92a23          	sw	a5,52(s2)
  initlock(&np->linked_list_lock, np->name);
    80002380:	85a6                	mv	a1,s1
    80002382:	04090513          	addi	a0,s2,64
    80002386:	ffffe097          	auipc	ra,0xffffe
    8000238a:	7ce080e7          	jalr	1998(ra) # 80000b54 <initlock>
  release(&np->lock);
    8000238e:	854a                	mv	a0,s2
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	91a080e7          	jalr	-1766(ra) # 80000caa <release>
  acquire(&wait_lock);
    80002398:	0000f497          	auipc	s1,0xf
    8000239c:	38048493          	addi	s1,s1,896 # 80011718 <wait_lock>
    800023a0:	8526                	mv	a0,s1
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	842080e7          	jalr	-1982(ra) # 80000be4 <acquire>
  np->parent = p;
    800023aa:	05393c23          	sd	s3,88(s2)
  release(&wait_lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8fa080e7          	jalr	-1798(ra) # 80000caa <release>
  acquire(&np->lock);
    800023b8:	854a                	mv	a0,s2
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	82a080e7          	jalr	-2006(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800023c2:	478d                	li	a5,3
    800023c4:	00f92c23          	sw	a5,24(s2)
  insert_to_list(np->index, &cpus_ll[np->cpu_num], &cpus_head[np->cpu_num]);
    800023c8:	03492583          	lw	a1,52(s2)
    800023cc:	00159793          	slli	a5,a1,0x1
    800023d0:	97ae                	add	a5,a5,a1
    800023d2:	078e                	slli	a5,a5,0x3
    800023d4:	058a                	slli	a1,a1,0x2
    800023d6:	0000f617          	auipc	a2,0xf
    800023da:	3a260613          	addi	a2,a2,930 # 80011778 <cpus_head>
    800023de:	963e                	add	a2,a2,a5
    800023e0:	0000f797          	auipc	a5,0xf
    800023e4:	30078793          	addi	a5,a5,768 # 800116e0 <cpus_ll>
    800023e8:	95be                	add	a1,a1,a5
    800023ea:	03892503          	lw	a0,56(s2)
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	6de080e7          	jalr	1758(ra) # 80001acc <insert_to_list>
  release(&np->lock);
    800023f6:	854a                	mv	a0,s2
    800023f8:	fffff097          	auipc	ra,0xfffff
    800023fc:	8b2080e7          	jalr	-1870(ra) # 80000caa <release>
}
    80002400:	8552                	mv	a0,s4
    80002402:	70a2                	ld	ra,40(sp)
    80002404:	7402                	ld	s0,32(sp)
    80002406:	64e2                	ld	s1,24(sp)
    80002408:	6942                	ld	s2,16(sp)
    8000240a:	69a2                	ld	s3,8(sp)
    8000240c:	6a02                	ld	s4,0(sp)
    8000240e:	6145                	addi	sp,sp,48
    80002410:	8082                	ret
    return -1;
    80002412:	5a7d                	li	s4,-1
    80002414:	b7f5                	j	80002400 <fork+0x16c>

0000000080002416 <scheduler>:
{
    80002416:	711d                	addi	sp,sp,-96
    80002418:	ec86                	sd	ra,88(sp)
    8000241a:	e8a2                	sd	s0,80(sp)
    8000241c:	e4a6                	sd	s1,72(sp)
    8000241e:	e0ca                	sd	s2,64(sp)
    80002420:	fc4e                	sd	s3,56(sp)
    80002422:	f852                	sd	s4,48(sp)
    80002424:	f456                	sd	s5,40(sp)
    80002426:	f05a                	sd	s6,32(sp)
    80002428:	ec5e                	sd	s7,24(sp)
    8000242a:	e862                	sd	s8,16(sp)
    8000242c:	e466                	sd	s9,8(sp)
    8000242e:	1080                	addi	s0,sp,96
    80002430:	8712                	mv	a4,tp
  int id = r_tp();
    80002432:	2701                	sext.w	a4,a4
  c->proc = 0;
    80002434:	0000fa17          	auipc	s4,0xf
    80002438:	e6ca0a13          	addi	s4,s4,-404 # 800112a0 <cpus>
    8000243c:	00471793          	slli	a5,a4,0x4
    80002440:	00e786b3          	add	a3,a5,a4
    80002444:	068e                	slli	a3,a3,0x3
    80002446:	96d2                	add	a3,a3,s4
    80002448:	0006b023          	sd	zero,0(a3)
      swtch(&c->context, &p->context);
    8000244c:	97ba                	add	a5,a5,a4
    8000244e:	078e                	slli	a5,a5,0x3
    80002450:	07a1                	addi	a5,a5,8
    80002452:	9a3e                	add	s4,s4,a5
    while (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
    80002454:	0000f997          	auipc	s3,0xf
    80002458:	e4c98993          	addi	s3,s3,-436 # 800112a0 <cpus>
      p = &proc[cpus_ll[cpuid()]];
    8000245c:	0000f497          	auipc	s1,0xf
    80002460:	41c48493          	addi	s1,s1,1052 # 80011878 <proc>
      c->proc = p;
    80002464:	8936                	mv	s2,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002466:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000246a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000246e:	10079073          	csrw	sstatus,a5
  asm volatile("mv %0, tp" : "=r" (x) );
    80002472:	8792                	mv	a5,tp
    while (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
    80002474:	2781                	sext.w	a5,a5
    80002476:	078a                	slli	a5,a5,0x2
    80002478:	97ce                	add	a5,a5,s3
    8000247a:	4407a703          	lw	a4,1088(a5)
    8000247e:	57fd                	li	a5,-1
    80002480:	fef703e3          	beq	a4,a5,80002466 <scheduler+0x50>
      int removed = remove_from_list(p->index, &cpus_ll[cpuid()], &cpus_head[cpuid()]);
    80002484:	0000fb17          	auipc	s6,0xf
    80002488:	2f4b0b13          	addi	s6,s6,756 # 80011778 <cpus_head>
    8000248c:	0000fa97          	auipc	s5,0xf
    80002490:	254a8a93          	addi	s5,s5,596 # 800116e0 <cpus_ll>
    80002494:	8792                	mv	a5,tp
      p = &proc[cpus_ll[cpuid()]];
    80002496:	2781                	sext.w	a5,a5
    80002498:	078a                	slli	a5,a5,0x2
    8000249a:	97ce                	add	a5,a5,s3
    8000249c:	4407ac03          	lw	s8,1088(a5)
    800024a0:	18800b93          	li	s7,392
    800024a4:	037c0bb3          	mul	s7,s8,s7
    800024a8:	009b8cb3          	add	s9,s7,s1
      acquire(&p->lock);
    800024ac:	8566                	mv	a0,s9
    800024ae:	ffffe097          	auipc	ra,0xffffe
    800024b2:	736080e7          	jalr	1846(ra) # 80000be4 <acquire>
    800024b6:	8592                	mv	a1,tp
    800024b8:	8612                	mv	a2,tp
      int removed = remove_from_list(p->index, &cpus_ll[cpuid()], &cpus_head[cpuid()]);
    800024ba:	0006079b          	sext.w	a5,a2
    800024be:	00179613          	slli	a2,a5,0x1
    800024c2:	963e                	add	a2,a2,a5
    800024c4:	060e                	slli	a2,a2,0x3
    800024c6:	2581                	sext.w	a1,a1
    800024c8:	058a                	slli	a1,a1,0x2
    800024ca:	965a                	add	a2,a2,s6
    800024cc:	95d6                	add	a1,a1,s5
    800024ce:	038ca503          	lw	a0,56(s9)
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	3d8080e7          	jalr	984(ra) # 800018aa <remove_from_list>
      if(removed == -1)
    800024da:	57fd                	li	a5,-1
    800024dc:	04f50563          	beq	a0,a5,80002526 <scheduler+0x110>
      p->state = RUNNING;
    800024e0:	18800793          	li	a5,392
    800024e4:	02fc0c33          	mul	s8,s8,a5
    800024e8:	9c26                	add	s8,s8,s1
    800024ea:	4791                	li	a5,4
    800024ec:	00fc2c23          	sw	a5,24(s8)
      c->proc = p;
    800024f0:	01993023          	sd	s9,0(s2)
      swtch(&c->context, &p->context);
    800024f4:	080b8593          	addi	a1,s7,128
    800024f8:	95a6                	add	a1,a1,s1
    800024fa:	8552                	mv	a0,s4
    800024fc:	00001097          	auipc	ra,0x1
    80002500:	832080e7          	jalr	-1998(ra) # 80002d2e <swtch>
      c->proc = 0;
    80002504:	00093023          	sd	zero,0(s2)
      release(&p->lock);
    80002508:	8566                	mv	a0,s9
    8000250a:	ffffe097          	auipc	ra,0xffffe
    8000250e:	7a0080e7          	jalr	1952(ra) # 80000caa <release>
    80002512:	8792                	mv	a5,tp
    while (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
    80002514:	2781                	sext.w	a5,a5
    80002516:	078a                	slli	a5,a5,0x2
    80002518:	97ce                	add	a5,a5,s3
    8000251a:	4407a703          	lw	a4,1088(a5)
    8000251e:	57fd                	li	a5,-1
    80002520:	f6f71ae3          	bne	a4,a5,80002494 <scheduler+0x7e>
    80002524:	b789                	j	80002466 <scheduler+0x50>
        panic("could not remove");
    80002526:	00006517          	auipc	a0,0x6
    8000252a:	d7250513          	addi	a0,a0,-654 # 80008298 <digits+0x258>
    8000252e:	ffffe097          	auipc	ra,0xffffe
    80002532:	010080e7          	jalr	16(ra) # 8000053e <panic>

0000000080002536 <sched>:
{
    80002536:	7179                	addi	sp,sp,-48
    80002538:	f406                	sd	ra,40(sp)
    8000253a:	f022                	sd	s0,32(sp)
    8000253c:	ec26                	sd	s1,24(sp)
    8000253e:	e84a                	sd	s2,16(sp)
    80002540:	e44e                	sd	s3,8(sp)
    80002542:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002544:	00000097          	auipc	ra,0x0
    80002548:	898080e7          	jalr	-1896(ra) # 80001ddc <myproc>
    8000254c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000254e:	ffffe097          	auipc	ra,0xffffe
    80002552:	61c080e7          	jalr	1564(ra) # 80000b6a <holding>
    80002556:	c559                	beqz	a0,800025e4 <sched+0xae>
    80002558:	8792                	mv	a5,tp
  if(mycpu()->noff != 1){
    8000255a:	0007871b          	sext.w	a4,a5
    8000255e:	00471793          	slli	a5,a4,0x4
    80002562:	97ba                	add	a5,a5,a4
    80002564:	078e                	slli	a5,a5,0x3
    80002566:	0000f717          	auipc	a4,0xf
    8000256a:	d3a70713          	addi	a4,a4,-710 # 800112a0 <cpus>
    8000256e:	97ba                	add	a5,a5,a4
    80002570:	5fb8                	lw	a4,120(a5)
    80002572:	4785                	li	a5,1
    80002574:	08f71063          	bne	a4,a5,800025f4 <sched+0xbe>
  if(p->state == RUNNING)
    80002578:	4c98                	lw	a4,24(s1)
    8000257a:	4791                	li	a5,4
    8000257c:	08f70463          	beq	a4,a5,80002604 <sched+0xce>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002580:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002584:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002586:	e7d9                	bnez	a5,80002614 <sched+0xde>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002588:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000258a:	0000f917          	auipc	s2,0xf
    8000258e:	d1690913          	addi	s2,s2,-746 # 800112a0 <cpus>
    80002592:	0007871b          	sext.w	a4,a5
    80002596:	00471793          	slli	a5,a4,0x4
    8000259a:	97ba                	add	a5,a5,a4
    8000259c:	078e                	slli	a5,a5,0x3
    8000259e:	97ca                	add	a5,a5,s2
    800025a0:	07c7a983          	lw	s3,124(a5)
    800025a4:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    800025a6:	0005879b          	sext.w	a5,a1
    800025aa:	00479593          	slli	a1,a5,0x4
    800025ae:	95be                	add	a1,a1,a5
    800025b0:	058e                	slli	a1,a1,0x3
    800025b2:	05a1                	addi	a1,a1,8
    800025b4:	95ca                	add	a1,a1,s2
    800025b6:	08048513          	addi	a0,s1,128
    800025ba:	00000097          	auipc	ra,0x0
    800025be:	774080e7          	jalr	1908(ra) # 80002d2e <swtch>
    800025c2:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800025c4:	0007871b          	sext.w	a4,a5
    800025c8:	00471793          	slli	a5,a4,0x4
    800025cc:	97ba                	add	a5,a5,a4
    800025ce:	078e                	slli	a5,a5,0x3
    800025d0:	993e                	add	s2,s2,a5
    800025d2:	07392e23          	sw	s3,124(s2)
}
    800025d6:	70a2                	ld	ra,40(sp)
    800025d8:	7402                	ld	s0,32(sp)
    800025da:	64e2                	ld	s1,24(sp)
    800025dc:	6942                	ld	s2,16(sp)
    800025de:	69a2                	ld	s3,8(sp)
    800025e0:	6145                	addi	sp,sp,48
    800025e2:	8082                	ret
    panic("sched p->lock");
    800025e4:	00006517          	auipc	a0,0x6
    800025e8:	ccc50513          	addi	a0,a0,-820 # 800082b0 <digits+0x270>
    800025ec:	ffffe097          	auipc	ra,0xffffe
    800025f0:	f52080e7          	jalr	-174(ra) # 8000053e <panic>
    panic("sched locks");
    800025f4:	00006517          	auipc	a0,0x6
    800025f8:	ccc50513          	addi	a0,a0,-820 # 800082c0 <digits+0x280>
    800025fc:	ffffe097          	auipc	ra,0xffffe
    80002600:	f42080e7          	jalr	-190(ra) # 8000053e <panic>
    panic("sched running");
    80002604:	00006517          	auipc	a0,0x6
    80002608:	ccc50513          	addi	a0,a0,-820 # 800082d0 <digits+0x290>
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	f32080e7          	jalr	-206(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002614:	00006517          	auipc	a0,0x6
    80002618:	ccc50513          	addi	a0,a0,-820 # 800082e0 <digits+0x2a0>
    8000261c:	ffffe097          	auipc	ra,0xffffe
    80002620:	f22080e7          	jalr	-222(ra) # 8000053e <panic>

0000000080002624 <yield>:
{
    80002624:	1101                	addi	sp,sp,-32
    80002626:	ec06                	sd	ra,24(sp)
    80002628:	e822                	sd	s0,16(sp)
    8000262a:	e426                	sd	s1,8(sp)
    8000262c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000262e:	fffff097          	auipc	ra,0xfffff
    80002632:	7ae080e7          	jalr	1966(ra) # 80001ddc <myproc>
    80002636:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	5ac080e7          	jalr	1452(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002640:	478d                	li	a5,3
    80002642:	cc9c                	sw	a5,24(s1)
  insert_to_list(p->index, &cpus_ll[p->cpu_num], &cpus_head[p->cpu_num]);
    80002644:	58cc                	lw	a1,52(s1)
    80002646:	00159793          	slli	a5,a1,0x1
    8000264a:	97ae                	add	a5,a5,a1
    8000264c:	078e                	slli	a5,a5,0x3
    8000264e:	058a                	slli	a1,a1,0x2
    80002650:	0000f617          	auipc	a2,0xf
    80002654:	12860613          	addi	a2,a2,296 # 80011778 <cpus_head>
    80002658:	963e                	add	a2,a2,a5
    8000265a:	0000f797          	auipc	a5,0xf
    8000265e:	08678793          	addi	a5,a5,134 # 800116e0 <cpus_ll>
    80002662:	95be                	add	a1,a1,a5
    80002664:	5c88                	lw	a0,56(s1)
    80002666:	fffff097          	auipc	ra,0xfffff
    8000266a:	466080e7          	jalr	1126(ra) # 80001acc <insert_to_list>
  sched();
    8000266e:	00000097          	auipc	ra,0x0
    80002672:	ec8080e7          	jalr	-312(ra) # 80002536 <sched>
  release(&p->lock);
    80002676:	8526                	mv	a0,s1
    80002678:	ffffe097          	auipc	ra,0xffffe
    8000267c:	632080e7          	jalr	1586(ra) # 80000caa <release>
}
    80002680:	60e2                	ld	ra,24(sp)
    80002682:	6442                	ld	s0,16(sp)
    80002684:	64a2                	ld	s1,8(sp)
    80002686:	6105                	addi	sp,sp,32
    80002688:	8082                	ret

000000008000268a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000268a:	7179                	addi	sp,sp,-48
    8000268c:	f406                	sd	ra,40(sp)
    8000268e:	f022                	sd	s0,32(sp)
    80002690:	ec26                	sd	s1,24(sp)
    80002692:	e84a                	sd	s2,16(sp)
    80002694:	e44e                	sd	s3,8(sp)
    80002696:	1800                	addi	s0,sp,48
    80002698:	89aa                	mv	s3,a0
    8000269a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000269c:	fffff097          	auipc	ra,0xfffff
    800026a0:	740080e7          	jalr	1856(ra) # 80001ddc <myproc>
    800026a4:	84aa                	mv	s1,a0
  // Must acquire p->lock in order to change p->state and then call sched.
  // Once we hold p->lock, we can be guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock), so it's okay to release lk.
  // Go to sleep.
  // cas(&p->state, RUNNING, SLEEPING);
  insert_to_list(p->index, &sleeping, &sleeping_head);
    800026a6:	0000f617          	auipc	a2,0xf
    800026aa:	08a60613          	addi	a2,a2,138 # 80011730 <sleeping_head>
    800026ae:	00006597          	auipc	a1,0x6
    800026b2:	21e58593          	addi	a1,a1,542 # 800088cc <sleeping>
    800026b6:	5d08                	lw	a0,56(a0)
    800026b8:	fffff097          	auipc	ra,0xfffff
    800026bc:	414080e7          	jalr	1044(ra) # 80001acc <insert_to_list>
  p->chan = chan;
    800026c0:	0334b023          	sd	s3,32(s1)
  acquire(&p->lock);  //DOC: sleeplock1
    800026c4:	8526                	mv	a0,s1
    800026c6:	ffffe097          	auipc	ra,0xffffe
    800026ca:	51e080e7          	jalr	1310(ra) # 80000be4 <acquire>
  p->state = SLEEPING;
    800026ce:	4789                	li	a5,2
    800026d0:	cc9c                	sw	a5,24(s1)
  release(lk);
    800026d2:	854a                	mv	a0,s2
    800026d4:	ffffe097          	auipc	ra,0xffffe
    800026d8:	5d6080e7          	jalr	1494(ra) # 80000caa <release>
  sched();
    800026dc:	00000097          	auipc	ra,0x0
    800026e0:	e5a080e7          	jalr	-422(ra) # 80002536 <sched>
  // Tidy up.
  p->chan = 0;
    800026e4:	0204b023          	sd	zero,32(s1)
  // Reacquire original lock.
  release(&p->lock);
    800026e8:	8526                	mv	a0,s1
    800026ea:	ffffe097          	auipc	ra,0xffffe
    800026ee:	5c0080e7          	jalr	1472(ra) # 80000caa <release>
  acquire(lk);
    800026f2:	854a                	mv	a0,s2
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	4f0080e7          	jalr	1264(ra) # 80000be4 <acquire>

}
    800026fc:	70a2                	ld	ra,40(sp)
    800026fe:	7402                	ld	s0,32(sp)
    80002700:	64e2                	ld	s1,24(sp)
    80002702:	6942                	ld	s2,16(sp)
    80002704:	69a2                	ld	s3,8(sp)
    80002706:	6145                	addi	sp,sp,48
    80002708:	8082                	ret

000000008000270a <wait>:
{
    8000270a:	715d                	addi	sp,sp,-80
    8000270c:	e486                	sd	ra,72(sp)
    8000270e:	e0a2                	sd	s0,64(sp)
    80002710:	fc26                	sd	s1,56(sp)
    80002712:	f84a                	sd	s2,48(sp)
    80002714:	f44e                	sd	s3,40(sp)
    80002716:	f052                	sd	s4,32(sp)
    80002718:	ec56                	sd	s5,24(sp)
    8000271a:	e85a                	sd	s6,16(sp)
    8000271c:	e45e                	sd	s7,8(sp)
    8000271e:	e062                	sd	s8,0(sp)
    80002720:	0880                	addi	s0,sp,80
    80002722:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002724:	fffff097          	auipc	ra,0xfffff
    80002728:	6b8080e7          	jalr	1720(ra) # 80001ddc <myproc>
    8000272c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000272e:	0000f517          	auipc	a0,0xf
    80002732:	fea50513          	addi	a0,a0,-22 # 80011718 <wait_lock>
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	4ae080e7          	jalr	1198(ra) # 80000be4 <acquire>
    havekids = 0;
    8000273e:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002740:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002742:	00015997          	auipc	s3,0x15
    80002746:	33698993          	addi	s3,s3,822 # 80017a78 <tickslock>
        havekids = 1;
    8000274a:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000274c:	0000fc17          	auipc	s8,0xf
    80002750:	fccc0c13          	addi	s8,s8,-52 # 80011718 <wait_lock>
    havekids = 0;
    80002754:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002756:	0000f497          	auipc	s1,0xf
    8000275a:	12248493          	addi	s1,s1,290 # 80011878 <proc>
    8000275e:	a0bd                	j	800027cc <wait+0xc2>
          pid = np->pid;
    80002760:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002764:	000b0e63          	beqz	s6,80002780 <wait+0x76>
    80002768:	4691                	li	a3,4
    8000276a:	02c48613          	addi	a2,s1,44
    8000276e:	85da                	mv	a1,s6
    80002770:	07093503          	ld	a0,112(s2)
    80002774:	fffff097          	auipc	ra,0xfffff
    80002778:	f22080e7          	jalr	-222(ra) # 80001696 <copyout>
    8000277c:	02054563          	bltz	a0,800027a6 <wait+0x9c>
          freeproc(np);
    80002780:	8526                	mv	a0,s1
    80002782:	00000097          	auipc	ra,0x0
    80002786:	858080e7          	jalr	-1960(ra) # 80001fda <freeproc>
          release(&np->lock);
    8000278a:	8526                	mv	a0,s1
    8000278c:	ffffe097          	auipc	ra,0xffffe
    80002790:	51e080e7          	jalr	1310(ra) # 80000caa <release>
          release(&wait_lock);
    80002794:	0000f517          	auipc	a0,0xf
    80002798:	f8450513          	addi	a0,a0,-124 # 80011718 <wait_lock>
    8000279c:	ffffe097          	auipc	ra,0xffffe
    800027a0:	50e080e7          	jalr	1294(ra) # 80000caa <release>
          return pid;
    800027a4:	a09d                	j	8000280a <wait+0x100>
            release(&np->lock);
    800027a6:	8526                	mv	a0,s1
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	502080e7          	jalr	1282(ra) # 80000caa <release>
            release(&wait_lock);
    800027b0:	0000f517          	auipc	a0,0xf
    800027b4:	f6850513          	addi	a0,a0,-152 # 80011718 <wait_lock>
    800027b8:	ffffe097          	auipc	ra,0xffffe
    800027bc:	4f2080e7          	jalr	1266(ra) # 80000caa <release>
            return -1;
    800027c0:	59fd                	li	s3,-1
    800027c2:	a0a1                	j	8000280a <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800027c4:	18848493          	addi	s1,s1,392
    800027c8:	03348463          	beq	s1,s3,800027f0 <wait+0xe6>
      if(np->parent == p){
    800027cc:	6cbc                	ld	a5,88(s1)
    800027ce:	ff279be3          	bne	a5,s2,800027c4 <wait+0xba>
        acquire(&np->lock);
    800027d2:	8526                	mv	a0,s1
    800027d4:	ffffe097          	auipc	ra,0xffffe
    800027d8:	410080e7          	jalr	1040(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800027dc:	4c9c                	lw	a5,24(s1)
    800027de:	f94781e3          	beq	a5,s4,80002760 <wait+0x56>
        release(&np->lock);
    800027e2:	8526                	mv	a0,s1
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	4c6080e7          	jalr	1222(ra) # 80000caa <release>
        havekids = 1;
    800027ec:	8756                	mv	a4,s5
    800027ee:	bfd9                	j	800027c4 <wait+0xba>
    if(!havekids || p->killed){
    800027f0:	c701                	beqz	a4,800027f8 <wait+0xee>
    800027f2:	02892783          	lw	a5,40(s2)
    800027f6:	c79d                	beqz	a5,80002824 <wait+0x11a>
      release(&wait_lock);
    800027f8:	0000f517          	auipc	a0,0xf
    800027fc:	f2050513          	addi	a0,a0,-224 # 80011718 <wait_lock>
    80002800:	ffffe097          	auipc	ra,0xffffe
    80002804:	4aa080e7          	jalr	1194(ra) # 80000caa <release>
      return -1;
    80002808:	59fd                	li	s3,-1
}
    8000280a:	854e                	mv	a0,s3
    8000280c:	60a6                	ld	ra,72(sp)
    8000280e:	6406                	ld	s0,64(sp)
    80002810:	74e2                	ld	s1,56(sp)
    80002812:	7942                	ld	s2,48(sp)
    80002814:	79a2                	ld	s3,40(sp)
    80002816:	7a02                	ld	s4,32(sp)
    80002818:	6ae2                	ld	s5,24(sp)
    8000281a:	6b42                	ld	s6,16(sp)
    8000281c:	6ba2                	ld	s7,8(sp)
    8000281e:	6c02                	ld	s8,0(sp)
    80002820:	6161                	addi	sp,sp,80
    80002822:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002824:	85e2                	mv	a1,s8
    80002826:	854a                	mv	a0,s2
    80002828:	00000097          	auipc	ra,0x0
    8000282c:	e62080e7          	jalr	-414(ra) # 8000268a <sleep>
    havekids = 0;
    80002830:	b715                	j	80002754 <wait+0x4a>

0000000080002832 <wakeup>:

void
wakeup(void * chan){
  struct proc *p;
  int index = sleeping;
    80002832:	00006797          	auipc	a5,0x6
    80002836:	09a7a783          	lw	a5,154(a5) # 800088cc <sleeping>
  int pred, next = -1;
  if (index == -1)
    8000283a:	577d                	li	a4,-1
    8000283c:	10e78063          	beq	a5,a4,8000293c <wakeup+0x10a>
wakeup(void * chan){
    80002840:	7119                	addi	sp,sp,-128
    80002842:	fc86                	sd	ra,120(sp)
    80002844:	f8a2                	sd	s0,112(sp)
    80002846:	f4a6                	sd	s1,104(sp)
    80002848:	f0ca                	sd	s2,96(sp)
    8000284a:	ecce                	sd	s3,88(sp)
    8000284c:	e8d2                	sd	s4,80(sp)
    8000284e:	e4d6                	sd	s5,72(sp)
    80002850:	e0da                	sd	s6,64(sp)
    80002852:	fc5e                	sd	s7,56(sp)
    80002854:	f862                	sd	s8,48(sp)
    80002856:	f466                	sd	s9,40(sp)
    80002858:	f06a                	sd	s10,32(sp)
    8000285a:	ec6e                	sd	s11,24(sp)
    8000285c:	0100                	addi	s0,sp,128
    8000285e:	8b2a                	mv	s6,a0
  int index = sleeping;
    80002860:	f8f42623          	sw	a5,-116(s0)
  int pred, next = -1;
    80002864:	597d                	li	s2,-1
    return;
  
  do {
    p = &proc[index];
    80002866:	18800a93          	li	s5,392
    8000286a:	0000fa17          	auipc	s4,0xf
    8000286e:	00ea0a13          	addi	s4,s4,14 # 80011878 <proc>
    if (p != myproc()) {
      acquire(&p->lock);
      next = p->next;
      if(p->chan == chan && p->state == SLEEPING){
    80002872:	4b89                	li	s7,2
        p->chan = 0;
        p->state = RUNNABLE;
    80002874:	4d8d                	li	s11,3
        // release(&p->lock);
        remove_from_list(p->index, &sleeping, &sleeping_head);
    80002876:	0000fd17          	auipc	s10,0xf
    8000287a:	ebad0d13          	addi	s10,s10,-326 # 80011730 <sleeping_head>
         #ifdef ON
          int cpui = leastUsedCPU();
          p->cpu_num = cpui;
          inc_cpu_usage(cpui);
          #endif
        insert_to_list(p->index,&cpus_ll[p->cpu_num],&cpus_head[p->cpu_num]);
    8000287e:	0000fc97          	auipc	s9,0xf
    80002882:	efac8c93          	addi	s9,s9,-262 # 80011778 <cpus_head>
    80002886:	0000fc17          	auipc	s8,0xf
    8000288a:	e5ac0c13          	addi	s8,s8,-422 # 800116e0 <cpus_ll>
    8000288e:	a8b1                	j	800028ea <wakeup+0xb8>
        p->chan = 0;
    80002890:	0204b023          	sd	zero,32(s1)
        p->state = RUNNABLE;
    80002894:	01b4ac23          	sw	s11,24(s1)
        remove_from_list(p->index, &sleeping, &sleeping_head);
    80002898:	866a                	mv	a2,s10
    8000289a:	00006597          	auipc	a1,0x6
    8000289e:	03258593          	addi	a1,a1,50 # 800088cc <sleeping>
    800028a2:	5c88                	lw	a0,56(s1)
    800028a4:	fffff097          	auipc	ra,0xfffff
    800028a8:	006080e7          	jalr	6(ra) # 800018aa <remove_from_list>
        insert_to_list(p->index,&cpus_ll[p->cpu_num],&cpus_head[p->cpu_num]);
    800028ac:	58cc                	lw	a1,52(s1)
    800028ae:	00159613          	slli	a2,a1,0x1
    800028b2:	962e                	add	a2,a2,a1
    800028b4:	060e                	slli	a2,a2,0x3
    800028b6:	058a                	slli	a1,a1,0x2
    800028b8:	9666                	add	a2,a2,s9
    800028ba:	95e2                	add	a1,a1,s8
    800028bc:	5c88                	lw	a0,56(s1)
    800028be:	fffff097          	auipc	ra,0xfffff
    800028c2:	20e080e7          	jalr	526(ra) # 80001acc <insert_to_list>
        // acquire(&p->lock);
      }
    release(&p->lock);
    800028c6:	8526                	mv	a0,s1
    800028c8:	ffffe097          	auipc	ra,0xffffe
    800028cc:	3e2080e7          	jalr	994(ra) # 80000caa <release>
    }
    pred = index;
    } while(!cas(&index, pred, next) && next != -1);
    800028d0:	864a                	mv	a2,s2
    800028d2:	f8c42583          	lw	a1,-116(s0)
    800028d6:	f8c40513          	addi	a0,s0,-116
    800028da:	00004097          	auipc	ra,0x4
    800028de:	0bc080e7          	jalr	188(ra) # 80006996 <cas>
    800028e2:	ed15                	bnez	a0,8000291e <wakeup+0xec>
    800028e4:	57fd                	li	a5,-1
    800028e6:	02f90c63          	beq	s2,a5,8000291e <wakeup+0xec>
    p = &proc[index];
    800028ea:	f8c42983          	lw	s3,-116(s0)
    800028ee:	035984b3          	mul	s1,s3,s5
    800028f2:	94d2                	add	s1,s1,s4
    if (p != myproc()) {
    800028f4:	fffff097          	auipc	ra,0xfffff
    800028f8:	4e8080e7          	jalr	1256(ra) # 80001ddc <myproc>
    800028fc:	fca48ae3          	beq	s1,a0,800028d0 <wakeup+0x9e>
      acquire(&p->lock);
    80002900:	8526                	mv	a0,s1
    80002902:	ffffe097          	auipc	ra,0xffffe
    80002906:	2e2080e7          	jalr	738(ra) # 80000be4 <acquire>
      next = p->next;
    8000290a:	03c4a903          	lw	s2,60(s1)
    8000290e:	2901                	sext.w	s2,s2
      if(p->chan == chan && p->state == SLEEPING){
    80002910:	709c                	ld	a5,32(s1)
    80002912:	fb679ae3          	bne	a5,s6,800028c6 <wakeup+0x94>
    80002916:	4c9c                	lw	a5,24(s1)
    80002918:	fb7797e3          	bne	a5,s7,800028c6 <wakeup+0x94>
    8000291c:	bf95                	j	80002890 <wakeup+0x5e>
  }
    8000291e:	70e6                	ld	ra,120(sp)
    80002920:	7446                	ld	s0,112(sp)
    80002922:	74a6                	ld	s1,104(sp)
    80002924:	7906                	ld	s2,96(sp)
    80002926:	69e6                	ld	s3,88(sp)
    80002928:	6a46                	ld	s4,80(sp)
    8000292a:	6aa6                	ld	s5,72(sp)
    8000292c:	6b06                	ld	s6,64(sp)
    8000292e:	7be2                	ld	s7,56(sp)
    80002930:	7c42                	ld	s8,48(sp)
    80002932:	7ca2                	ld	s9,40(sp)
    80002934:	7d02                	ld	s10,32(sp)
    80002936:	6de2                	ld	s11,24(sp)
    80002938:	6109                	addi	sp,sp,128
    8000293a:	8082                	ret
    8000293c:	8082                	ret

000000008000293e <reparent>:
{
    8000293e:	7179                	addi	sp,sp,-48
    80002940:	f406                	sd	ra,40(sp)
    80002942:	f022                	sd	s0,32(sp)
    80002944:	ec26                	sd	s1,24(sp)
    80002946:	e84a                	sd	s2,16(sp)
    80002948:	e44e                	sd	s3,8(sp)
    8000294a:	e052                	sd	s4,0(sp)
    8000294c:	1800                	addi	s0,sp,48
    8000294e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002950:	0000f497          	auipc	s1,0xf
    80002954:	f2848493          	addi	s1,s1,-216 # 80011878 <proc>
      pp->parent = initproc;
    80002958:	00006a17          	auipc	s4,0x6
    8000295c:	6d0a0a13          	addi	s4,s4,1744 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002960:	00015997          	auipc	s3,0x15
    80002964:	11898993          	addi	s3,s3,280 # 80017a78 <tickslock>
    80002968:	a029                	j	80002972 <reparent+0x34>
    8000296a:	18848493          	addi	s1,s1,392
    8000296e:	01348d63          	beq	s1,s3,80002988 <reparent+0x4a>
    if(pp->parent == p){
    80002972:	6cbc                	ld	a5,88(s1)
    80002974:	ff279be3          	bne	a5,s2,8000296a <reparent+0x2c>
      pp->parent = initproc;
    80002978:	000a3503          	ld	a0,0(s4)
    8000297c:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    8000297e:	00000097          	auipc	ra,0x0
    80002982:	eb4080e7          	jalr	-332(ra) # 80002832 <wakeup>
    80002986:	b7d5                	j	8000296a <reparent+0x2c>
}
    80002988:	70a2                	ld	ra,40(sp)
    8000298a:	7402                	ld	s0,32(sp)
    8000298c:	64e2                	ld	s1,24(sp)
    8000298e:	6942                	ld	s2,16(sp)
    80002990:	69a2                	ld	s3,8(sp)
    80002992:	6a02                	ld	s4,0(sp)
    80002994:	6145                	addi	sp,sp,48
    80002996:	8082                	ret

0000000080002998 <exit>:
{
    80002998:	7179                	addi	sp,sp,-48
    8000299a:	f406                	sd	ra,40(sp)
    8000299c:	f022                	sd	s0,32(sp)
    8000299e:	ec26                	sd	s1,24(sp)
    800029a0:	e84a                	sd	s2,16(sp)
    800029a2:	e44e                	sd	s3,8(sp)
    800029a4:	e052                	sd	s4,0(sp)
    800029a6:	1800                	addi	s0,sp,48
    800029a8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800029aa:	fffff097          	auipc	ra,0xfffff
    800029ae:	432080e7          	jalr	1074(ra) # 80001ddc <myproc>
    800029b2:	89aa                	mv	s3,a0
  if(p == initproc)
    800029b4:	00006797          	auipc	a5,0x6
    800029b8:	6747b783          	ld	a5,1652(a5) # 80009028 <initproc>
    800029bc:	0f050493          	addi	s1,a0,240
    800029c0:	17050913          	addi	s2,a0,368
    800029c4:	02a79363          	bne	a5,a0,800029ea <exit+0x52>
    panic("init exiting");
    800029c8:	00006517          	auipc	a0,0x6
    800029cc:	93050513          	addi	a0,a0,-1744 # 800082f8 <digits+0x2b8>
    800029d0:	ffffe097          	auipc	ra,0xffffe
    800029d4:	b6e080e7          	jalr	-1170(ra) # 8000053e <panic>
      fileclose(f);
    800029d8:	00002097          	auipc	ra,0x2
    800029dc:	2d4080e7          	jalr	724(ra) # 80004cac <fileclose>
      p->ofile[fd] = 0;
    800029e0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800029e4:	04a1                	addi	s1,s1,8
    800029e6:	01248563          	beq	s1,s2,800029f0 <exit+0x58>
    if(p->ofile[fd]){
    800029ea:	6088                	ld	a0,0(s1)
    800029ec:	f575                	bnez	a0,800029d8 <exit+0x40>
    800029ee:	bfdd                	j	800029e4 <exit+0x4c>
  begin_op();
    800029f0:	00002097          	auipc	ra,0x2
    800029f4:	df0080e7          	jalr	-528(ra) # 800047e0 <begin_op>
  iput(p->cwd);
    800029f8:	1709b503          	ld	a0,368(s3)
    800029fc:	00001097          	auipc	ra,0x1
    80002a00:	5cc080e7          	jalr	1484(ra) # 80003fc8 <iput>
  end_op();
    80002a04:	00002097          	auipc	ra,0x2
    80002a08:	e5c080e7          	jalr	-420(ra) # 80004860 <end_op>
  p->cwd = 0;
    80002a0c:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    80002a10:	0000f497          	auipc	s1,0xf
    80002a14:	d0848493          	addi	s1,s1,-760 # 80011718 <wait_lock>
    80002a18:	8526                	mv	a0,s1
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	1ca080e7          	jalr	458(ra) # 80000be4 <acquire>
  reparent(p);
    80002a22:	854e                	mv	a0,s3
    80002a24:	00000097          	auipc	ra,0x0
    80002a28:	f1a080e7          	jalr	-230(ra) # 8000293e <reparent>
  wakeup(p->parent);
    80002a2c:	0589b503          	ld	a0,88(s3)
    80002a30:	00000097          	auipc	ra,0x0
    80002a34:	e02080e7          	jalr	-510(ra) # 80002832 <wakeup>
  acquire(&p->lock);
    80002a38:	854e                	mv	a0,s3
    80002a3a:	ffffe097          	auipc	ra,0xffffe
    80002a3e:	1aa080e7          	jalr	426(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002a42:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002a46:	4795                	li	a5,5
    80002a48:	00f9ac23          	sw	a5,24(s3)
  insert_to_list(p->index, &zombie, &zombie_head);
    80002a4c:	0000f617          	auipc	a2,0xf
    80002a50:	cfc60613          	addi	a2,a2,-772 # 80011748 <zombie_head>
    80002a54:	00006597          	auipc	a1,0x6
    80002a58:	e7458593          	addi	a1,a1,-396 # 800088c8 <zombie>
    80002a5c:	0389a503          	lw	a0,56(s3)
    80002a60:	fffff097          	auipc	ra,0xfffff
    80002a64:	06c080e7          	jalr	108(ra) # 80001acc <insert_to_list>
  release(&wait_lock);
    80002a68:	8526                	mv	a0,s1
    80002a6a:	ffffe097          	auipc	ra,0xffffe
    80002a6e:	240080e7          	jalr	576(ra) # 80000caa <release>
  sched();
    80002a72:	00000097          	auipc	ra,0x0
    80002a76:	ac4080e7          	jalr	-1340(ra) # 80002536 <sched>
  panic("zombie exit");
    80002a7a:	00006517          	auipc	a0,0x6
    80002a7e:	88e50513          	addi	a0,a0,-1906 # 80008308 <digits+0x2c8>
    80002a82:	ffffe097          	auipc	ra,0xffffe
    80002a86:	abc080e7          	jalr	-1348(ra) # 8000053e <panic>

0000000080002a8a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002a8a:	7179                	addi	sp,sp,-48
    80002a8c:	f406                	sd	ra,40(sp)
    80002a8e:	f022                	sd	s0,32(sp)
    80002a90:	ec26                	sd	s1,24(sp)
    80002a92:	e84a                	sd	s2,16(sp)
    80002a94:	e44e                	sd	s3,8(sp)
    80002a96:	1800                	addi	s0,sp,48
    80002a98:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002a9a:	0000f497          	auipc	s1,0xf
    80002a9e:	dde48493          	addi	s1,s1,-546 # 80011878 <proc>
    80002aa2:	00015997          	auipc	s3,0x15
    80002aa6:	fd698993          	addi	s3,s3,-42 # 80017a78 <tickslock>
    acquire(&p->lock);
    80002aaa:	8526                	mv	a0,s1
    80002aac:	ffffe097          	auipc	ra,0xffffe
    80002ab0:	138080e7          	jalr	312(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002ab4:	589c                	lw	a5,48(s1)
    80002ab6:	01278d63          	beq	a5,s2,80002ad0 <kill+0x46>
      insert_to_list(p->index, &cpus_ll[p->cpu_num], &cpus_head[p->cpu_num]);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002aba:	8526                	mv	a0,s1
    80002abc:	ffffe097          	auipc	ra,0xffffe
    80002ac0:	1ee080e7          	jalr	494(ra) # 80000caa <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ac4:	18848493          	addi	s1,s1,392
    80002ac8:	ff3491e3          	bne	s1,s3,80002aaa <kill+0x20>
  }
  return -1;
    80002acc:	557d                	li	a0,-1
    80002ace:	a829                	j	80002ae8 <kill+0x5e>
      p->killed = 1;
    80002ad0:	4785                	li	a5,1
    80002ad2:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002ad4:	4c98                	lw	a4,24(s1)
    80002ad6:	4789                	li	a5,2
    80002ad8:	00f70f63          	beq	a4,a5,80002af6 <kill+0x6c>
      release(&p->lock);
    80002adc:	8526                	mv	a0,s1
    80002ade:	ffffe097          	auipc	ra,0xffffe
    80002ae2:	1cc080e7          	jalr	460(ra) # 80000caa <release>
      return 0;
    80002ae6:	4501                	li	a0,0
}
    80002ae8:	70a2                	ld	ra,40(sp)
    80002aea:	7402                	ld	s0,32(sp)
    80002aec:	64e2                	ld	s1,24(sp)
    80002aee:	6942                	ld	s2,16(sp)
    80002af0:	69a2                	ld	s3,8(sp)
    80002af2:	6145                	addi	sp,sp,48
    80002af4:	8082                	ret
        remove_from_list(p->index, &sleeping, &sleeping_head);
    80002af6:	0000f617          	auipc	a2,0xf
    80002afa:	c3a60613          	addi	a2,a2,-966 # 80011730 <sleeping_head>
    80002afe:	00006597          	auipc	a1,0x6
    80002b02:	dce58593          	addi	a1,a1,-562 # 800088cc <sleeping>
    80002b06:	5c88                	lw	a0,56(s1)
    80002b08:	fffff097          	auipc	ra,0xfffff
    80002b0c:	da2080e7          	jalr	-606(ra) # 800018aa <remove_from_list>
        p->state = RUNNABLE;
    80002b10:	478d                	li	a5,3
    80002b12:	cc9c                	sw	a5,24(s1)
      insert_to_list(p->index, &cpus_ll[p->cpu_num], &cpus_head[p->cpu_num]);
    80002b14:	58dc                	lw	a5,52(s1)
    80002b16:	00179713          	slli	a4,a5,0x1
    80002b1a:	973e                	add	a4,a4,a5
    80002b1c:	070e                	slli	a4,a4,0x3
    80002b1e:	078a                	slli	a5,a5,0x2
    80002b20:	0000f617          	auipc	a2,0xf
    80002b24:	c5860613          	addi	a2,a2,-936 # 80011778 <cpus_head>
    80002b28:	963a                	add	a2,a2,a4
    80002b2a:	0000f597          	auipc	a1,0xf
    80002b2e:	bb658593          	addi	a1,a1,-1098 # 800116e0 <cpus_ll>
    80002b32:	95be                	add	a1,a1,a5
    80002b34:	5c88                	lw	a0,56(s1)
    80002b36:	fffff097          	auipc	ra,0xfffff
    80002b3a:	f96080e7          	jalr	-106(ra) # 80001acc <insert_to_list>
    80002b3e:	bf79                	j	80002adc <kill+0x52>

0000000080002b40 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len){
    80002b40:	7179                	addi	sp,sp,-48
    80002b42:	f406                	sd	ra,40(sp)
    80002b44:	f022                	sd	s0,32(sp)
    80002b46:	ec26                	sd	s1,24(sp)
    80002b48:	e84a                	sd	s2,16(sp)
    80002b4a:	e44e                	sd	s3,8(sp)
    80002b4c:	e052                	sd	s4,0(sp)
    80002b4e:	1800                	addi	s0,sp,48
    80002b50:	84aa                	mv	s1,a0
    80002b52:	892e                	mv	s2,a1
    80002b54:	89b2                	mv	s3,a2
    80002b56:	8a36                	mv	s4,a3

  struct proc *p = myproc();
    80002b58:	fffff097          	auipc	ra,0xfffff
    80002b5c:	284080e7          	jalr	644(ra) # 80001ddc <myproc>
  if(user_dst){
    80002b60:	c08d                	beqz	s1,80002b82 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002b62:	86d2                	mv	a3,s4
    80002b64:	864e                	mv	a2,s3
    80002b66:	85ca                	mv	a1,s2
    80002b68:	7928                	ld	a0,112(a0)
    80002b6a:	fffff097          	auipc	ra,0xfffff
    80002b6e:	b2c080e7          	jalr	-1236(ra) # 80001696 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002b72:	70a2                	ld	ra,40(sp)
    80002b74:	7402                	ld	s0,32(sp)
    80002b76:	64e2                	ld	s1,24(sp)
    80002b78:	6942                	ld	s2,16(sp)
    80002b7a:	69a2                	ld	s3,8(sp)
    80002b7c:	6a02                	ld	s4,0(sp)
    80002b7e:	6145                	addi	sp,sp,48
    80002b80:	8082                	ret
    memmove((char *)dst, src, len);
    80002b82:	000a061b          	sext.w	a2,s4
    80002b86:	85ce                	mv	a1,s3
    80002b88:	854a                	mv	a0,s2
    80002b8a:	ffffe097          	auipc	ra,0xffffe
    80002b8e:	1da080e7          	jalr	474(ra) # 80000d64 <memmove>
    return 0;
    80002b92:	8526                	mv	a0,s1
    80002b94:	bff9                	j	80002b72 <either_copyout+0x32>

0000000080002b96 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002b96:	7179                	addi	sp,sp,-48
    80002b98:	f406                	sd	ra,40(sp)
    80002b9a:	f022                	sd	s0,32(sp)
    80002b9c:	ec26                	sd	s1,24(sp)
    80002b9e:	e84a                	sd	s2,16(sp)
    80002ba0:	e44e                	sd	s3,8(sp)
    80002ba2:	e052                	sd	s4,0(sp)
    80002ba4:	1800                	addi	s0,sp,48
    80002ba6:	892a                	mv	s2,a0
    80002ba8:	84ae                	mv	s1,a1
    80002baa:	89b2                	mv	s3,a2
    80002bac:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002bae:	fffff097          	auipc	ra,0xfffff
    80002bb2:	22e080e7          	jalr	558(ra) # 80001ddc <myproc>
  if(user_src){
    80002bb6:	c08d                	beqz	s1,80002bd8 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002bb8:	86d2                	mv	a3,s4
    80002bba:	864e                	mv	a2,s3
    80002bbc:	85ca                	mv	a1,s2
    80002bbe:	7928                	ld	a0,112(a0)
    80002bc0:	fffff097          	auipc	ra,0xfffff
    80002bc4:	b62080e7          	jalr	-1182(ra) # 80001722 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002bc8:	70a2                	ld	ra,40(sp)
    80002bca:	7402                	ld	s0,32(sp)
    80002bcc:	64e2                	ld	s1,24(sp)
    80002bce:	6942                	ld	s2,16(sp)
    80002bd0:	69a2                	ld	s3,8(sp)
    80002bd2:	6a02                	ld	s4,0(sp)
    80002bd4:	6145                	addi	sp,sp,48
    80002bd6:	8082                	ret
    memmove(dst, (char*)src, len);
    80002bd8:	000a061b          	sext.w	a2,s4
    80002bdc:	85ce                	mv	a1,s3
    80002bde:	854a                	mv	a0,s2
    80002be0:	ffffe097          	auipc	ra,0xffffe
    80002be4:	184080e7          	jalr	388(ra) # 80000d64 <memmove>
    return 0;
    80002be8:	8526                	mv	a0,s1
    80002bea:	bff9                	j	80002bc8 <either_copyin+0x32>

0000000080002bec <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002bec:	715d                	addi	sp,sp,-80
    80002bee:	e486                	sd	ra,72(sp)
    80002bf0:	e0a2                	sd	s0,64(sp)
    80002bf2:	fc26                	sd	s1,56(sp)
    80002bf4:	f84a                	sd	s2,48(sp)
    80002bf6:	f44e                	sd	s3,40(sp)
    80002bf8:	f052                	sd	s4,32(sp)
    80002bfa:	ec56                	sd	s5,24(sp)
    80002bfc:	e85a                	sd	s6,16(sp)
    80002bfe:	e45e                	sd	s7,8(sp)
    80002c00:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002c02:	00005517          	auipc	a0,0x5
    80002c06:	4f650513          	addi	a0,a0,1270 # 800080f8 <digits+0xb8>
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	97e080e7          	jalr	-1666(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002c12:	0000f497          	auipc	s1,0xf
    80002c16:	dde48493          	addi	s1,s1,-546 # 800119f0 <proc+0x178>
    80002c1a:	00015917          	auipc	s2,0x15
    80002c1e:	fd690913          	addi	s2,s2,-42 # 80017bf0 <bcache+0x160>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002c22:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002c24:	00005997          	auipc	s3,0x5
    80002c28:	6f498993          	addi	s3,s3,1780 # 80008318 <digits+0x2d8>
    printf("%d %s %s %d", p->pid, state, p->name, p->cpu_num);
    80002c2c:	00005a97          	auipc	s5,0x5
    80002c30:	6f4a8a93          	addi	s5,s5,1780 # 80008320 <digits+0x2e0>
    printf("\n");
    80002c34:	00005a17          	auipc	s4,0x5
    80002c38:	4c4a0a13          	addi	s4,s4,1220 # 800080f8 <digits+0xb8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002c3c:	00005b97          	auipc	s7,0x5
    80002c40:	71cb8b93          	addi	s7,s7,1820 # 80008358 <states.1785>
    80002c44:	a01d                	j	80002c6a <procdump+0x7e>
    printf("%d %s %s %d", p->pid, state, p->name, p->cpu_num);
    80002c46:	ebc6a703          	lw	a4,-324(a3)
    80002c4a:	eb86a583          	lw	a1,-328(a3)
    80002c4e:	8556                	mv	a0,s5
    80002c50:	ffffe097          	auipc	ra,0xffffe
    80002c54:	938080e7          	jalr	-1736(ra) # 80000588 <printf>
    printf("\n");
    80002c58:	8552                	mv	a0,s4
    80002c5a:	ffffe097          	auipc	ra,0xffffe
    80002c5e:	92e080e7          	jalr	-1746(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002c62:	18848493          	addi	s1,s1,392
    80002c66:	03248163          	beq	s1,s2,80002c88 <procdump+0x9c>
    if(p->state == UNUSED)
    80002c6a:	86a6                	mv	a3,s1
    80002c6c:	ea04a783          	lw	a5,-352(s1)
    80002c70:	dbed                	beqz	a5,80002c62 <procdump+0x76>
      state = "???";
    80002c72:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002c74:	fcfb69e3          	bltu	s6,a5,80002c46 <procdump+0x5a>
    80002c78:	1782                	slli	a5,a5,0x20
    80002c7a:	9381                	srli	a5,a5,0x20
    80002c7c:	078e                	slli	a5,a5,0x3
    80002c7e:	97de                	add	a5,a5,s7
    80002c80:	6390                	ld	a2,0(a5)
    80002c82:	f271                	bnez	a2,80002c46 <procdump+0x5a>
      state = "???";
    80002c84:	864e                	mv	a2,s3
    80002c86:	b7c1                	j	80002c46 <procdump+0x5a>
  }
}
    80002c88:	60a6                	ld	ra,72(sp)
    80002c8a:	6406                	ld	s0,64(sp)
    80002c8c:	74e2                	ld	s1,56(sp)
    80002c8e:	7942                	ld	s2,48(sp)
    80002c90:	79a2                	ld	s3,40(sp)
    80002c92:	7a02                	ld	s4,32(sp)
    80002c94:	6ae2                	ld	s5,24(sp)
    80002c96:	6b42                	ld	s6,16(sp)
    80002c98:	6ba2                	ld	s7,8(sp)
    80002c9a:	6161                	addi	sp,sp,80
    80002c9c:	8082                	ret

0000000080002c9e <set_cpu>:


int set_cpu(int cpu_num){ //added as orderd
    80002c9e:	1101                	addi	sp,sp,-32
    80002ca0:	ec06                	sd	ra,24(sp)
    80002ca2:	e822                	sd	s0,16(sp)
    80002ca4:	e426                	sd	s1,8(sp)
    80002ca6:	1000                	addi	s0,sp,32
    80002ca8:	84aa                	mv	s1,a0
// printf("%d\n", 12);
  struct proc *p= myproc();  
    80002caa:	fffff097          	auipc	ra,0xfffff
    80002cae:	132080e7          	jalr	306(ra) # 80001ddc <myproc>
  if(cas(&p->cpu_num, p->cpu_num, cpu_num)){
    80002cb2:	8626                	mv	a2,s1
    80002cb4:	594c                	lw	a1,52(a0)
    80002cb6:	03450513          	addi	a0,a0,52
    80002cba:	00004097          	auipc	ra,0x4
    80002cbe:	cdc080e7          	jalr	-804(ra) # 80006996 <cas>
    80002cc2:	e519                	bnez	a0,80002cd0 <set_cpu+0x32>
    yield();
    return cpu_num;
  }
  return 0;
    80002cc4:	4501                	li	a0,0
}
    80002cc6:	60e2                	ld	ra,24(sp)
    80002cc8:	6442                	ld	s0,16(sp)
    80002cca:	64a2                	ld	s1,8(sp)
    80002ccc:	6105                	addi	sp,sp,32
    80002cce:	8082                	ret
    yield();
    80002cd0:	00000097          	auipc	ra,0x0
    80002cd4:	954080e7          	jalr	-1708(ra) # 80002624 <yield>
    return cpu_num;
    80002cd8:	8526                	mv	a0,s1
    80002cda:	b7f5                	j	80002cc6 <set_cpu+0x28>

0000000080002cdc <get_cpu>:

int get_cpu(){ //added as orderd
    80002cdc:	1101                	addi	sp,sp,-32
    80002cde:	ec06                	sd	ra,24(sp)
    80002ce0:	e822                	sd	s0,16(sp)
    80002ce2:	1000                	addi	s0,sp,32
// printf("%d\n", 13);
  struct proc *p = myproc();
    80002ce4:	fffff097          	auipc	ra,0xfffff
    80002ce8:	0f8080e7          	jalr	248(ra) # 80001ddc <myproc>
  int ans=0;
    80002cec:	fe042623          	sw	zero,-20(s0)
  cas(&ans, ans, p->cpu_num);
    80002cf0:	5950                	lw	a2,52(a0)
    80002cf2:	4581                	li	a1,0
    80002cf4:	fec40513          	addi	a0,s0,-20
    80002cf8:	00004097          	auipc	ra,0x4
    80002cfc:	c9e080e7          	jalr	-866(ra) # 80006996 <cas>
    return ans;
}
    80002d00:	fec42503          	lw	a0,-20(s0)
    80002d04:	60e2                	ld	ra,24(sp)
    80002d06:	6442                	ld	s0,16(sp)
    80002d08:	6105                	addi	sp,sp,32
    80002d0a:	8082                	ret

0000000080002d0c <cpu_process_count>:

// int cpu_process_count (int cpu_num){
//   return cpu_usage[cpu_num];
// }
int cpu_process_count(int cpu_num){
    80002d0c:	1141                	addi	sp,sp,-16
    80002d0e:	e422                	sd	s0,8(sp)
    80002d10:	0800                	addi	s0,sp,16
  struct cpu* c = &cpus[cpu_num];
  uint64 procsNum = c->admittedProcs;
    80002d12:	00451793          	slli	a5,a0,0x4
    80002d16:	97aa                	add	a5,a5,a0
    80002d18:	078e                	slli	a5,a5,0x3
    80002d1a:	0000e517          	auipc	a0,0xe
    80002d1e:	58650513          	addi	a0,a0,1414 # 800112a0 <cpus>
    80002d22:	97aa                	add	a5,a5,a0
  return procsNum;
}
    80002d24:	0807a503          	lw	a0,128(a5)
    80002d28:	6422                	ld	s0,8(sp)
    80002d2a:	0141                	addi	sp,sp,16
    80002d2c:	8082                	ret

0000000080002d2e <swtch>:
    80002d2e:	00153023          	sd	ra,0(a0)
    80002d32:	00253423          	sd	sp,8(a0)
    80002d36:	e900                	sd	s0,16(a0)
    80002d38:	ed04                	sd	s1,24(a0)
    80002d3a:	03253023          	sd	s2,32(a0)
    80002d3e:	03353423          	sd	s3,40(a0)
    80002d42:	03453823          	sd	s4,48(a0)
    80002d46:	03553c23          	sd	s5,56(a0)
    80002d4a:	05653023          	sd	s6,64(a0)
    80002d4e:	05753423          	sd	s7,72(a0)
    80002d52:	05853823          	sd	s8,80(a0)
    80002d56:	05953c23          	sd	s9,88(a0)
    80002d5a:	07a53023          	sd	s10,96(a0)
    80002d5e:	07b53423          	sd	s11,104(a0)
    80002d62:	0005b083          	ld	ra,0(a1)
    80002d66:	0085b103          	ld	sp,8(a1)
    80002d6a:	6980                	ld	s0,16(a1)
    80002d6c:	6d84                	ld	s1,24(a1)
    80002d6e:	0205b903          	ld	s2,32(a1)
    80002d72:	0285b983          	ld	s3,40(a1)
    80002d76:	0305ba03          	ld	s4,48(a1)
    80002d7a:	0385ba83          	ld	s5,56(a1)
    80002d7e:	0405bb03          	ld	s6,64(a1)
    80002d82:	0485bb83          	ld	s7,72(a1)
    80002d86:	0505bc03          	ld	s8,80(a1)
    80002d8a:	0585bc83          	ld	s9,88(a1)
    80002d8e:	0605bd03          	ld	s10,96(a1)
    80002d92:	0685bd83          	ld	s11,104(a1)
    80002d96:	8082                	ret

0000000080002d98 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002d98:	1141                	addi	sp,sp,-16
    80002d9a:	e406                	sd	ra,8(sp)
    80002d9c:	e022                	sd	s0,0(sp)
    80002d9e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002da0:	00005597          	auipc	a1,0x5
    80002da4:	5e858593          	addi	a1,a1,1512 # 80008388 <states.1785+0x30>
    80002da8:	00015517          	auipc	a0,0x15
    80002dac:	cd050513          	addi	a0,a0,-816 # 80017a78 <tickslock>
    80002db0:	ffffe097          	auipc	ra,0xffffe
    80002db4:	da4080e7          	jalr	-604(ra) # 80000b54 <initlock>
}
    80002db8:	60a2                	ld	ra,8(sp)
    80002dba:	6402                	ld	s0,0(sp)
    80002dbc:	0141                	addi	sp,sp,16
    80002dbe:	8082                	ret

0000000080002dc0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002dc0:	1141                	addi	sp,sp,-16
    80002dc2:	e422                	sd	s0,8(sp)
    80002dc4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002dc6:	00003797          	auipc	a5,0x3
    80002dca:	4fa78793          	addi	a5,a5,1274 # 800062c0 <kernelvec>
    80002dce:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002dd2:	6422                	ld	s0,8(sp)
    80002dd4:	0141                	addi	sp,sp,16
    80002dd6:	8082                	ret

0000000080002dd8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002dd8:	1141                	addi	sp,sp,-16
    80002dda:	e406                	sd	ra,8(sp)
    80002ddc:	e022                	sd	s0,0(sp)
    80002dde:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002de0:	fffff097          	auipc	ra,0xfffff
    80002de4:	ffc080e7          	jalr	-4(ra) # 80001ddc <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002de8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002dec:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dee:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002df2:	00004617          	auipc	a2,0x4
    80002df6:	20e60613          	addi	a2,a2,526 # 80007000 <_trampoline>
    80002dfa:	00004697          	auipc	a3,0x4
    80002dfe:	20668693          	addi	a3,a3,518 # 80007000 <_trampoline>
    80002e02:	8e91                	sub	a3,a3,a2
    80002e04:	040007b7          	lui	a5,0x4000
    80002e08:	17fd                	addi	a5,a5,-1
    80002e0a:	07b2                	slli	a5,a5,0xc
    80002e0c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e0e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002e12:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002e14:	180026f3          	csrr	a3,satp
    80002e18:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002e1a:	7d38                	ld	a4,120(a0)
    80002e1c:	7134                	ld	a3,96(a0)
    80002e1e:	6585                	lui	a1,0x1
    80002e20:	96ae                	add	a3,a3,a1
    80002e22:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002e24:	7d38                	ld	a4,120(a0)
    80002e26:	00000697          	auipc	a3,0x0
    80002e2a:	13868693          	addi	a3,a3,312 # 80002f5e <usertrap>
    80002e2e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002e30:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002e32:	8692                	mv	a3,tp
    80002e34:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e36:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002e3a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002e3e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e42:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002e46:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e48:	6f18                	ld	a4,24(a4)
    80002e4a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002e4e:	792c                	ld	a1,112(a0)
    80002e50:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002e52:	00004717          	auipc	a4,0x4
    80002e56:	23e70713          	addi	a4,a4,574 # 80007090 <userret>
    80002e5a:	8f11                	sub	a4,a4,a2
    80002e5c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002e5e:	577d                	li	a4,-1
    80002e60:	177e                	slli	a4,a4,0x3f
    80002e62:	8dd9                	or	a1,a1,a4
    80002e64:	02000537          	lui	a0,0x2000
    80002e68:	157d                	addi	a0,a0,-1
    80002e6a:	0536                	slli	a0,a0,0xd
    80002e6c:	9782                	jalr	a5
}
    80002e6e:	60a2                	ld	ra,8(sp)
    80002e70:	6402                	ld	s0,0(sp)
    80002e72:	0141                	addi	sp,sp,16
    80002e74:	8082                	ret

0000000080002e76 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002e76:	1101                	addi	sp,sp,-32
    80002e78:	ec06                	sd	ra,24(sp)
    80002e7a:	e822                	sd	s0,16(sp)
    80002e7c:	e426                	sd	s1,8(sp)
    80002e7e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002e80:	00015497          	auipc	s1,0x15
    80002e84:	bf848493          	addi	s1,s1,-1032 # 80017a78 <tickslock>
    80002e88:	8526                	mv	a0,s1
    80002e8a:	ffffe097          	auipc	ra,0xffffe
    80002e8e:	d5a080e7          	jalr	-678(ra) # 80000be4 <acquire>
  ticks++;
    80002e92:	00006517          	auipc	a0,0x6
    80002e96:	19e50513          	addi	a0,a0,414 # 80009030 <ticks>
    80002e9a:	411c                	lw	a5,0(a0)
    80002e9c:	2785                	addiw	a5,a5,1
    80002e9e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002ea0:	00000097          	auipc	ra,0x0
    80002ea4:	992080e7          	jalr	-1646(ra) # 80002832 <wakeup>
  release(&tickslock);
    80002ea8:	8526                	mv	a0,s1
    80002eaa:	ffffe097          	auipc	ra,0xffffe
    80002eae:	e00080e7          	jalr	-512(ra) # 80000caa <release>
}
    80002eb2:	60e2                	ld	ra,24(sp)
    80002eb4:	6442                	ld	s0,16(sp)
    80002eb6:	64a2                	ld	s1,8(sp)
    80002eb8:	6105                	addi	sp,sp,32
    80002eba:	8082                	ret

0000000080002ebc <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002ebc:	1101                	addi	sp,sp,-32
    80002ebe:	ec06                	sd	ra,24(sp)
    80002ec0:	e822                	sd	s0,16(sp)
    80002ec2:	e426                	sd	s1,8(sp)
    80002ec4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ec6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002eca:	00074d63          	bltz	a4,80002ee4 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002ece:	57fd                	li	a5,-1
    80002ed0:	17fe                	slli	a5,a5,0x3f
    80002ed2:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002ed4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002ed6:	06f70363          	beq	a4,a5,80002f3c <devintr+0x80>
  }
}
    80002eda:	60e2                	ld	ra,24(sp)
    80002edc:	6442                	ld	s0,16(sp)
    80002ede:	64a2                	ld	s1,8(sp)
    80002ee0:	6105                	addi	sp,sp,32
    80002ee2:	8082                	ret
     (scause & 0xff) == 9){
    80002ee4:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002ee8:	46a5                	li	a3,9
    80002eea:	fed792e3          	bne	a5,a3,80002ece <devintr+0x12>
    int irq = plic_claim();
    80002eee:	00003097          	auipc	ra,0x3
    80002ef2:	4da080e7          	jalr	1242(ra) # 800063c8 <plic_claim>
    80002ef6:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ef8:	47a9                	li	a5,10
    80002efa:	02f50763          	beq	a0,a5,80002f28 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002efe:	4785                	li	a5,1
    80002f00:	02f50963          	beq	a0,a5,80002f32 <devintr+0x76>
    return 1;
    80002f04:	4505                	li	a0,1
    } else if(irq){
    80002f06:	d8f1                	beqz	s1,80002eda <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002f08:	85a6                	mv	a1,s1
    80002f0a:	00005517          	auipc	a0,0x5
    80002f0e:	48650513          	addi	a0,a0,1158 # 80008390 <states.1785+0x38>
    80002f12:	ffffd097          	auipc	ra,0xffffd
    80002f16:	676080e7          	jalr	1654(ra) # 80000588 <printf>
      plic_complete(irq);
    80002f1a:	8526                	mv	a0,s1
    80002f1c:	00003097          	auipc	ra,0x3
    80002f20:	4d0080e7          	jalr	1232(ra) # 800063ec <plic_complete>
    return 1;
    80002f24:	4505                	li	a0,1
    80002f26:	bf55                	j	80002eda <devintr+0x1e>
      uartintr();
    80002f28:	ffffe097          	auipc	ra,0xffffe
    80002f2c:	a80080e7          	jalr	-1408(ra) # 800009a8 <uartintr>
    80002f30:	b7ed                	j	80002f1a <devintr+0x5e>
      virtio_disk_intr();
    80002f32:	00004097          	auipc	ra,0x4
    80002f36:	99a080e7          	jalr	-1638(ra) # 800068cc <virtio_disk_intr>
    80002f3a:	b7c5                	j	80002f1a <devintr+0x5e>
    if(cpuid() == 0){
    80002f3c:	fffff097          	auipc	ra,0xfffff
    80002f40:	e6c080e7          	jalr	-404(ra) # 80001da8 <cpuid>
    80002f44:	c901                	beqz	a0,80002f54 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002f46:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002f4a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002f4c:	14479073          	csrw	sip,a5
    return 2;
    80002f50:	4509                	li	a0,2
    80002f52:	b761                	j	80002eda <devintr+0x1e>
      clockintr();
    80002f54:	00000097          	auipc	ra,0x0
    80002f58:	f22080e7          	jalr	-222(ra) # 80002e76 <clockintr>
    80002f5c:	b7ed                	j	80002f46 <devintr+0x8a>

0000000080002f5e <usertrap>:
{
    80002f5e:	1101                	addi	sp,sp,-32
    80002f60:	ec06                	sd	ra,24(sp)
    80002f62:	e822                	sd	s0,16(sp)
    80002f64:	e426                	sd	s1,8(sp)
    80002f66:	e04a                	sd	s2,0(sp)
    80002f68:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f6a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002f6e:	1007f793          	andi	a5,a5,256
    80002f72:	e3ad                	bnez	a5,80002fd4 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f74:	00003797          	auipc	a5,0x3
    80002f78:	34c78793          	addi	a5,a5,844 # 800062c0 <kernelvec>
    80002f7c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002f80:	fffff097          	auipc	ra,0xfffff
    80002f84:	e5c080e7          	jalr	-420(ra) # 80001ddc <myproc>
    80002f88:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002f8a:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f8c:	14102773          	csrr	a4,sepc
    80002f90:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f92:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002f96:	47a1                	li	a5,8
    80002f98:	04f71c63          	bne	a4,a5,80002ff0 <usertrap+0x92>
    if(p->killed)
    80002f9c:	551c                	lw	a5,40(a0)
    80002f9e:	e3b9                	bnez	a5,80002fe4 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002fa0:	7cb8                	ld	a4,120(s1)
    80002fa2:	6f1c                	ld	a5,24(a4)
    80002fa4:	0791                	addi	a5,a5,4
    80002fa6:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fa8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002fac:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fb0:	10079073          	csrw	sstatus,a5
    syscall();
    80002fb4:	00000097          	auipc	ra,0x0
    80002fb8:	2e0080e7          	jalr	736(ra) # 80003294 <syscall>
  if(p->killed)
    80002fbc:	549c                	lw	a5,40(s1)
    80002fbe:	ebc1                	bnez	a5,8000304e <usertrap+0xf0>
  usertrapret();
    80002fc0:	00000097          	auipc	ra,0x0
    80002fc4:	e18080e7          	jalr	-488(ra) # 80002dd8 <usertrapret>
}
    80002fc8:	60e2                	ld	ra,24(sp)
    80002fca:	6442                	ld	s0,16(sp)
    80002fcc:	64a2                	ld	s1,8(sp)
    80002fce:	6902                	ld	s2,0(sp)
    80002fd0:	6105                	addi	sp,sp,32
    80002fd2:	8082                	ret
    panic("usertrap: not from user mode");
    80002fd4:	00005517          	auipc	a0,0x5
    80002fd8:	3dc50513          	addi	a0,a0,988 # 800083b0 <states.1785+0x58>
    80002fdc:	ffffd097          	auipc	ra,0xffffd
    80002fe0:	562080e7          	jalr	1378(ra) # 8000053e <panic>
      exit(-1);
    80002fe4:	557d                	li	a0,-1
    80002fe6:	00000097          	auipc	ra,0x0
    80002fea:	9b2080e7          	jalr	-1614(ra) # 80002998 <exit>
    80002fee:	bf4d                	j	80002fa0 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002ff0:	00000097          	auipc	ra,0x0
    80002ff4:	ecc080e7          	jalr	-308(ra) # 80002ebc <devintr>
    80002ff8:	892a                	mv	s2,a0
    80002ffa:	c501                	beqz	a0,80003002 <usertrap+0xa4>
  if(p->killed)
    80002ffc:	549c                	lw	a5,40(s1)
    80002ffe:	c3a1                	beqz	a5,8000303e <usertrap+0xe0>
    80003000:	a815                	j	80003034 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003002:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003006:	5890                	lw	a2,48(s1)
    80003008:	00005517          	auipc	a0,0x5
    8000300c:	3c850513          	addi	a0,a0,968 # 800083d0 <states.1785+0x78>
    80003010:	ffffd097          	auipc	ra,0xffffd
    80003014:	578080e7          	jalr	1400(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003018:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000301c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003020:	00005517          	auipc	a0,0x5
    80003024:	3e050513          	addi	a0,a0,992 # 80008400 <states.1785+0xa8>
    80003028:	ffffd097          	auipc	ra,0xffffd
    8000302c:	560080e7          	jalr	1376(ra) # 80000588 <printf>
    p->killed = 1;
    80003030:	4785                	li	a5,1
    80003032:	d49c                	sw	a5,40(s1)
    exit(-1);
    80003034:	557d                	li	a0,-1
    80003036:	00000097          	auipc	ra,0x0
    8000303a:	962080e7          	jalr	-1694(ra) # 80002998 <exit>
  if(which_dev == 2)
    8000303e:	4789                	li	a5,2
    80003040:	f8f910e3          	bne	s2,a5,80002fc0 <usertrap+0x62>
    yield();
    80003044:	fffff097          	auipc	ra,0xfffff
    80003048:	5e0080e7          	jalr	1504(ra) # 80002624 <yield>
    8000304c:	bf95                	j	80002fc0 <usertrap+0x62>
  int which_dev = 0;
    8000304e:	4901                	li	s2,0
    80003050:	b7d5                	j	80003034 <usertrap+0xd6>

0000000080003052 <kerneltrap>:
{
    80003052:	7179                	addi	sp,sp,-48
    80003054:	f406                	sd	ra,40(sp)
    80003056:	f022                	sd	s0,32(sp)
    80003058:	ec26                	sd	s1,24(sp)
    8000305a:	e84a                	sd	s2,16(sp)
    8000305c:	e44e                	sd	s3,8(sp)
    8000305e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003060:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003064:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003068:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000306c:	1004f793          	andi	a5,s1,256
    80003070:	cb85                	beqz	a5,800030a0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003072:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003076:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003078:	ef85                	bnez	a5,800030b0 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000307a:	00000097          	auipc	ra,0x0
    8000307e:	e42080e7          	jalr	-446(ra) # 80002ebc <devintr>
    80003082:	cd1d                	beqz	a0,800030c0 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003084:	4789                	li	a5,2
    80003086:	06f50a63          	beq	a0,a5,800030fa <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000308a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000308e:	10049073          	csrw	sstatus,s1
}
    80003092:	70a2                	ld	ra,40(sp)
    80003094:	7402                	ld	s0,32(sp)
    80003096:	64e2                	ld	s1,24(sp)
    80003098:	6942                	ld	s2,16(sp)
    8000309a:	69a2                	ld	s3,8(sp)
    8000309c:	6145                	addi	sp,sp,48
    8000309e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800030a0:	00005517          	auipc	a0,0x5
    800030a4:	38050513          	addi	a0,a0,896 # 80008420 <states.1785+0xc8>
    800030a8:	ffffd097          	auipc	ra,0xffffd
    800030ac:	496080e7          	jalr	1174(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800030b0:	00005517          	auipc	a0,0x5
    800030b4:	39850513          	addi	a0,a0,920 # 80008448 <states.1785+0xf0>
    800030b8:	ffffd097          	auipc	ra,0xffffd
    800030bc:	486080e7          	jalr	1158(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800030c0:	85ce                	mv	a1,s3
    800030c2:	00005517          	auipc	a0,0x5
    800030c6:	3a650513          	addi	a0,a0,934 # 80008468 <states.1785+0x110>
    800030ca:	ffffd097          	auipc	ra,0xffffd
    800030ce:	4be080e7          	jalr	1214(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030d2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800030d6:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800030da:	00005517          	auipc	a0,0x5
    800030de:	39e50513          	addi	a0,a0,926 # 80008478 <states.1785+0x120>
    800030e2:	ffffd097          	auipc	ra,0xffffd
    800030e6:	4a6080e7          	jalr	1190(ra) # 80000588 <printf>
    panic("kerneltrap");
    800030ea:	00005517          	auipc	a0,0x5
    800030ee:	3a650513          	addi	a0,a0,934 # 80008490 <states.1785+0x138>
    800030f2:	ffffd097          	auipc	ra,0xffffd
    800030f6:	44c080e7          	jalr	1100(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800030fa:	fffff097          	auipc	ra,0xfffff
    800030fe:	ce2080e7          	jalr	-798(ra) # 80001ddc <myproc>
    80003102:	d541                	beqz	a0,8000308a <kerneltrap+0x38>
    80003104:	fffff097          	auipc	ra,0xfffff
    80003108:	cd8080e7          	jalr	-808(ra) # 80001ddc <myproc>
    8000310c:	4d18                	lw	a4,24(a0)
    8000310e:	4791                	li	a5,4
    80003110:	f6f71de3          	bne	a4,a5,8000308a <kerneltrap+0x38>
    yield();
    80003114:	fffff097          	auipc	ra,0xfffff
    80003118:	510080e7          	jalr	1296(ra) # 80002624 <yield>
    8000311c:	b7bd                	j	8000308a <kerneltrap+0x38>

000000008000311e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000311e:	1101                	addi	sp,sp,-32
    80003120:	ec06                	sd	ra,24(sp)
    80003122:	e822                	sd	s0,16(sp)
    80003124:	e426                	sd	s1,8(sp)
    80003126:	1000                	addi	s0,sp,32
    80003128:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000312a:	fffff097          	auipc	ra,0xfffff
    8000312e:	cb2080e7          	jalr	-846(ra) # 80001ddc <myproc>
  switch (n) {
    80003132:	4795                	li	a5,5
    80003134:	0497e163          	bltu	a5,s1,80003176 <argraw+0x58>
    80003138:	048a                	slli	s1,s1,0x2
    8000313a:	00005717          	auipc	a4,0x5
    8000313e:	38e70713          	addi	a4,a4,910 # 800084c8 <states.1785+0x170>
    80003142:	94ba                	add	s1,s1,a4
    80003144:	409c                	lw	a5,0(s1)
    80003146:	97ba                	add	a5,a5,a4
    80003148:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000314a:	7d3c                	ld	a5,120(a0)
    8000314c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000314e:	60e2                	ld	ra,24(sp)
    80003150:	6442                	ld	s0,16(sp)
    80003152:	64a2                	ld	s1,8(sp)
    80003154:	6105                	addi	sp,sp,32
    80003156:	8082                	ret
    return p->trapframe->a1;
    80003158:	7d3c                	ld	a5,120(a0)
    8000315a:	7fa8                	ld	a0,120(a5)
    8000315c:	bfcd                	j	8000314e <argraw+0x30>
    return p->trapframe->a2;
    8000315e:	7d3c                	ld	a5,120(a0)
    80003160:	63c8                	ld	a0,128(a5)
    80003162:	b7f5                	j	8000314e <argraw+0x30>
    return p->trapframe->a3;
    80003164:	7d3c                	ld	a5,120(a0)
    80003166:	67c8                	ld	a0,136(a5)
    80003168:	b7dd                	j	8000314e <argraw+0x30>
    return p->trapframe->a4;
    8000316a:	7d3c                	ld	a5,120(a0)
    8000316c:	6bc8                	ld	a0,144(a5)
    8000316e:	b7c5                	j	8000314e <argraw+0x30>
    return p->trapframe->a5;
    80003170:	7d3c                	ld	a5,120(a0)
    80003172:	6fc8                	ld	a0,152(a5)
    80003174:	bfe9                	j	8000314e <argraw+0x30>
  panic("argraw");
    80003176:	00005517          	auipc	a0,0x5
    8000317a:	32a50513          	addi	a0,a0,810 # 800084a0 <states.1785+0x148>
    8000317e:	ffffd097          	auipc	ra,0xffffd
    80003182:	3c0080e7          	jalr	960(ra) # 8000053e <panic>

0000000080003186 <fetchaddr>:
{
    80003186:	1101                	addi	sp,sp,-32
    80003188:	ec06                	sd	ra,24(sp)
    8000318a:	e822                	sd	s0,16(sp)
    8000318c:	e426                	sd	s1,8(sp)
    8000318e:	e04a                	sd	s2,0(sp)
    80003190:	1000                	addi	s0,sp,32
    80003192:	84aa                	mv	s1,a0
    80003194:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003196:	fffff097          	auipc	ra,0xfffff
    8000319a:	c46080e7          	jalr	-954(ra) # 80001ddc <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    8000319e:	753c                	ld	a5,104(a0)
    800031a0:	02f4f863          	bgeu	s1,a5,800031d0 <fetchaddr+0x4a>
    800031a4:	00848713          	addi	a4,s1,8
    800031a8:	02e7e663          	bltu	a5,a4,800031d4 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800031ac:	46a1                	li	a3,8
    800031ae:	8626                	mv	a2,s1
    800031b0:	85ca                	mv	a1,s2
    800031b2:	7928                	ld	a0,112(a0)
    800031b4:	ffffe097          	auipc	ra,0xffffe
    800031b8:	56e080e7          	jalr	1390(ra) # 80001722 <copyin>
    800031bc:	00a03533          	snez	a0,a0
    800031c0:	40a00533          	neg	a0,a0
}
    800031c4:	60e2                	ld	ra,24(sp)
    800031c6:	6442                	ld	s0,16(sp)
    800031c8:	64a2                	ld	s1,8(sp)
    800031ca:	6902                	ld	s2,0(sp)
    800031cc:	6105                	addi	sp,sp,32
    800031ce:	8082                	ret
    return -1;
    800031d0:	557d                	li	a0,-1
    800031d2:	bfcd                	j	800031c4 <fetchaddr+0x3e>
    800031d4:	557d                	li	a0,-1
    800031d6:	b7fd                	j	800031c4 <fetchaddr+0x3e>

00000000800031d8 <fetchstr>:
{
    800031d8:	7179                	addi	sp,sp,-48
    800031da:	f406                	sd	ra,40(sp)
    800031dc:	f022                	sd	s0,32(sp)
    800031de:	ec26                	sd	s1,24(sp)
    800031e0:	e84a                	sd	s2,16(sp)
    800031e2:	e44e                	sd	s3,8(sp)
    800031e4:	1800                	addi	s0,sp,48
    800031e6:	892a                	mv	s2,a0
    800031e8:	84ae                	mv	s1,a1
    800031ea:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800031ec:	fffff097          	auipc	ra,0xfffff
    800031f0:	bf0080e7          	jalr	-1040(ra) # 80001ddc <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800031f4:	86ce                	mv	a3,s3
    800031f6:	864a                	mv	a2,s2
    800031f8:	85a6                	mv	a1,s1
    800031fa:	7928                	ld	a0,112(a0)
    800031fc:	ffffe097          	auipc	ra,0xffffe
    80003200:	5b2080e7          	jalr	1458(ra) # 800017ae <copyinstr>
  if(err < 0)
    80003204:	00054763          	bltz	a0,80003212 <fetchstr+0x3a>
  return strlen(buf);
    80003208:	8526                	mv	a0,s1
    8000320a:	ffffe097          	auipc	ra,0xffffe
    8000320e:	c7e080e7          	jalr	-898(ra) # 80000e88 <strlen>
}
    80003212:	70a2                	ld	ra,40(sp)
    80003214:	7402                	ld	s0,32(sp)
    80003216:	64e2                	ld	s1,24(sp)
    80003218:	6942                	ld	s2,16(sp)
    8000321a:	69a2                	ld	s3,8(sp)
    8000321c:	6145                	addi	sp,sp,48
    8000321e:	8082                	ret

0000000080003220 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003220:	1101                	addi	sp,sp,-32
    80003222:	ec06                	sd	ra,24(sp)
    80003224:	e822                	sd	s0,16(sp)
    80003226:	e426                	sd	s1,8(sp)
    80003228:	1000                	addi	s0,sp,32
    8000322a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000322c:	00000097          	auipc	ra,0x0
    80003230:	ef2080e7          	jalr	-270(ra) # 8000311e <argraw>
    80003234:	c088                	sw	a0,0(s1)
  return 0;
}
    80003236:	4501                	li	a0,0
    80003238:	60e2                	ld	ra,24(sp)
    8000323a:	6442                	ld	s0,16(sp)
    8000323c:	64a2                	ld	s1,8(sp)
    8000323e:	6105                	addi	sp,sp,32
    80003240:	8082                	ret

0000000080003242 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003242:	1101                	addi	sp,sp,-32
    80003244:	ec06                	sd	ra,24(sp)
    80003246:	e822                	sd	s0,16(sp)
    80003248:	e426                	sd	s1,8(sp)
    8000324a:	1000                	addi	s0,sp,32
    8000324c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000324e:	00000097          	auipc	ra,0x0
    80003252:	ed0080e7          	jalr	-304(ra) # 8000311e <argraw>
    80003256:	e088                	sd	a0,0(s1)
  return 0;
}
    80003258:	4501                	li	a0,0
    8000325a:	60e2                	ld	ra,24(sp)
    8000325c:	6442                	ld	s0,16(sp)
    8000325e:	64a2                	ld	s1,8(sp)
    80003260:	6105                	addi	sp,sp,32
    80003262:	8082                	ret

0000000080003264 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003264:	1101                	addi	sp,sp,-32
    80003266:	ec06                	sd	ra,24(sp)
    80003268:	e822                	sd	s0,16(sp)
    8000326a:	e426                	sd	s1,8(sp)
    8000326c:	e04a                	sd	s2,0(sp)
    8000326e:	1000                	addi	s0,sp,32
    80003270:	84ae                	mv	s1,a1
    80003272:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003274:	00000097          	auipc	ra,0x0
    80003278:	eaa080e7          	jalr	-342(ra) # 8000311e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    8000327c:	864a                	mv	a2,s2
    8000327e:	85a6                	mv	a1,s1
    80003280:	00000097          	auipc	ra,0x0
    80003284:	f58080e7          	jalr	-168(ra) # 800031d8 <fetchstr>
}
    80003288:	60e2                	ld	ra,24(sp)
    8000328a:	6442                	ld	s0,16(sp)
    8000328c:	64a2                	ld	s1,8(sp)
    8000328e:	6902                	ld	s2,0(sp)
    80003290:	6105                	addi	sp,sp,32
    80003292:	8082                	ret

0000000080003294 <syscall>:
[SYS_cpu_process_count] sys_cpu_process_count,
};

void
syscall(void)
{
    80003294:	1101                	addi	sp,sp,-32
    80003296:	ec06                	sd	ra,24(sp)
    80003298:	e822                	sd	s0,16(sp)
    8000329a:	e426                	sd	s1,8(sp)
    8000329c:	e04a                	sd	s2,0(sp)
    8000329e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800032a0:	fffff097          	auipc	ra,0xfffff
    800032a4:	b3c080e7          	jalr	-1220(ra) # 80001ddc <myproc>
    800032a8:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800032aa:	07853903          	ld	s2,120(a0)
    800032ae:	0a893783          	ld	a5,168(s2)
    800032b2:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800032b6:	37fd                	addiw	a5,a5,-1
    800032b8:	475d                	li	a4,23
    800032ba:	00f76f63          	bltu	a4,a5,800032d8 <syscall+0x44>
    800032be:	00369713          	slli	a4,a3,0x3
    800032c2:	00005797          	auipc	a5,0x5
    800032c6:	21e78793          	addi	a5,a5,542 # 800084e0 <syscalls>
    800032ca:	97ba                	add	a5,a5,a4
    800032cc:	639c                	ld	a5,0(a5)
    800032ce:	c789                	beqz	a5,800032d8 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800032d0:	9782                	jalr	a5
    800032d2:	06a93823          	sd	a0,112(s2)
    800032d6:	a839                	j	800032f4 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800032d8:	17848613          	addi	a2,s1,376
    800032dc:	588c                	lw	a1,48(s1)
    800032de:	00005517          	auipc	a0,0x5
    800032e2:	1ca50513          	addi	a0,a0,458 # 800084a8 <states.1785+0x150>
    800032e6:	ffffd097          	auipc	ra,0xffffd
    800032ea:	2a2080e7          	jalr	674(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800032ee:	7cbc                	ld	a5,120(s1)
    800032f0:	577d                	li	a4,-1
    800032f2:	fbb8                	sd	a4,112(a5)
  }
}
    800032f4:	60e2                	ld	ra,24(sp)
    800032f6:	6442                	ld	s0,16(sp)
    800032f8:	64a2                	ld	s1,8(sp)
    800032fa:	6902                	ld	s2,0(sp)
    800032fc:	6105                	addi	sp,sp,32
    800032fe:	8082                	ret

0000000080003300 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003300:	1101                	addi	sp,sp,-32
    80003302:	ec06                	sd	ra,24(sp)
    80003304:	e822                	sd	s0,16(sp)
    80003306:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003308:	fec40593          	addi	a1,s0,-20
    8000330c:	4501                	li	a0,0
    8000330e:	00000097          	auipc	ra,0x0
    80003312:	f12080e7          	jalr	-238(ra) # 80003220 <argint>
    return -1;
    80003316:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003318:	00054963          	bltz	a0,8000332a <sys_exit+0x2a>
  exit(n);
    8000331c:	fec42503          	lw	a0,-20(s0)
    80003320:	fffff097          	auipc	ra,0xfffff
    80003324:	678080e7          	jalr	1656(ra) # 80002998 <exit>
  return 0;  // not reached
    80003328:	4781                	li	a5,0
}
    8000332a:	853e                	mv	a0,a5
    8000332c:	60e2                	ld	ra,24(sp)
    8000332e:	6442                	ld	s0,16(sp)
    80003330:	6105                	addi	sp,sp,32
    80003332:	8082                	ret

0000000080003334 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003334:	1141                	addi	sp,sp,-16
    80003336:	e406                	sd	ra,8(sp)
    80003338:	e022                	sd	s0,0(sp)
    8000333a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000333c:	fffff097          	auipc	ra,0xfffff
    80003340:	aa0080e7          	jalr	-1376(ra) # 80001ddc <myproc>
}
    80003344:	5908                	lw	a0,48(a0)
    80003346:	60a2                	ld	ra,8(sp)
    80003348:	6402                	ld	s0,0(sp)
    8000334a:	0141                	addi	sp,sp,16
    8000334c:	8082                	ret

000000008000334e <sys_fork>:

uint64
sys_fork(void)
{
    8000334e:	1141                	addi	sp,sp,-16
    80003350:	e406                	sd	ra,8(sp)
    80003352:	e022                	sd	s0,0(sp)
    80003354:	0800                	addi	s0,sp,16
  return fork();
    80003356:	fffff097          	auipc	ra,0xfffff
    8000335a:	f3e080e7          	jalr	-194(ra) # 80002294 <fork>
}
    8000335e:	60a2                	ld	ra,8(sp)
    80003360:	6402                	ld	s0,0(sp)
    80003362:	0141                	addi	sp,sp,16
    80003364:	8082                	ret

0000000080003366 <sys_wait>:

uint64
sys_wait(void)
{
    80003366:	1101                	addi	sp,sp,-32
    80003368:	ec06                	sd	ra,24(sp)
    8000336a:	e822                	sd	s0,16(sp)
    8000336c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000336e:	fe840593          	addi	a1,s0,-24
    80003372:	4501                	li	a0,0
    80003374:	00000097          	auipc	ra,0x0
    80003378:	ece080e7          	jalr	-306(ra) # 80003242 <argaddr>
    8000337c:	87aa                	mv	a5,a0
    return -1;
    8000337e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003380:	0007c863          	bltz	a5,80003390 <sys_wait+0x2a>
  return wait(p);
    80003384:	fe843503          	ld	a0,-24(s0)
    80003388:	fffff097          	auipc	ra,0xfffff
    8000338c:	382080e7          	jalr	898(ra) # 8000270a <wait>
}
    80003390:	60e2                	ld	ra,24(sp)
    80003392:	6442                	ld	s0,16(sp)
    80003394:	6105                	addi	sp,sp,32
    80003396:	8082                	ret

0000000080003398 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003398:	7179                	addi	sp,sp,-48
    8000339a:	f406                	sd	ra,40(sp)
    8000339c:	f022                	sd	s0,32(sp)
    8000339e:	ec26                	sd	s1,24(sp)
    800033a0:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800033a2:	fdc40593          	addi	a1,s0,-36
    800033a6:	4501                	li	a0,0
    800033a8:	00000097          	auipc	ra,0x0
    800033ac:	e78080e7          	jalr	-392(ra) # 80003220 <argint>
    800033b0:	87aa                	mv	a5,a0
    return -1;
    800033b2:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800033b4:	0207c063          	bltz	a5,800033d4 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800033b8:	fffff097          	auipc	ra,0xfffff
    800033bc:	a24080e7          	jalr	-1500(ra) # 80001ddc <myproc>
    800033c0:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    800033c2:	fdc42503          	lw	a0,-36(s0)
    800033c6:	fffff097          	auipc	ra,0xfffff
    800033ca:	e5a080e7          	jalr	-422(ra) # 80002220 <growproc>
    800033ce:	00054863          	bltz	a0,800033de <sys_sbrk+0x46>
    return -1;
  return addr;
    800033d2:	8526                	mv	a0,s1
}
    800033d4:	70a2                	ld	ra,40(sp)
    800033d6:	7402                	ld	s0,32(sp)
    800033d8:	64e2                	ld	s1,24(sp)
    800033da:	6145                	addi	sp,sp,48
    800033dc:	8082                	ret
    return -1;
    800033de:	557d                	li	a0,-1
    800033e0:	bfd5                	j	800033d4 <sys_sbrk+0x3c>

00000000800033e2 <sys_sleep>:

uint64
sys_sleep(void)
{
    800033e2:	7139                	addi	sp,sp,-64
    800033e4:	fc06                	sd	ra,56(sp)
    800033e6:	f822                	sd	s0,48(sp)
    800033e8:	f426                	sd	s1,40(sp)
    800033ea:	f04a                	sd	s2,32(sp)
    800033ec:	ec4e                	sd	s3,24(sp)
    800033ee:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800033f0:	fcc40593          	addi	a1,s0,-52
    800033f4:	4501                	li	a0,0
    800033f6:	00000097          	auipc	ra,0x0
    800033fa:	e2a080e7          	jalr	-470(ra) # 80003220 <argint>
    return -1;
    800033fe:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003400:	06054563          	bltz	a0,8000346a <sys_sleep+0x88>
  acquire(&tickslock);
    80003404:	00014517          	auipc	a0,0x14
    80003408:	67450513          	addi	a0,a0,1652 # 80017a78 <tickslock>
    8000340c:	ffffd097          	auipc	ra,0xffffd
    80003410:	7d8080e7          	jalr	2008(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003414:	00006917          	auipc	s2,0x6
    80003418:	c1c92903          	lw	s2,-996(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000341c:	fcc42783          	lw	a5,-52(s0)
    80003420:	cf85                	beqz	a5,80003458 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003422:	00014997          	auipc	s3,0x14
    80003426:	65698993          	addi	s3,s3,1622 # 80017a78 <tickslock>
    8000342a:	00006497          	auipc	s1,0x6
    8000342e:	c0648493          	addi	s1,s1,-1018 # 80009030 <ticks>
    if(myproc()->killed){
    80003432:	fffff097          	auipc	ra,0xfffff
    80003436:	9aa080e7          	jalr	-1622(ra) # 80001ddc <myproc>
    8000343a:	551c                	lw	a5,40(a0)
    8000343c:	ef9d                	bnez	a5,8000347a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000343e:	85ce                	mv	a1,s3
    80003440:	8526                	mv	a0,s1
    80003442:	fffff097          	auipc	ra,0xfffff
    80003446:	248080e7          	jalr	584(ra) # 8000268a <sleep>
  while(ticks - ticks0 < n){
    8000344a:	409c                	lw	a5,0(s1)
    8000344c:	412787bb          	subw	a5,a5,s2
    80003450:	fcc42703          	lw	a4,-52(s0)
    80003454:	fce7efe3          	bltu	a5,a4,80003432 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003458:	00014517          	auipc	a0,0x14
    8000345c:	62050513          	addi	a0,a0,1568 # 80017a78 <tickslock>
    80003460:	ffffe097          	auipc	ra,0xffffe
    80003464:	84a080e7          	jalr	-1974(ra) # 80000caa <release>
  return 0;
    80003468:	4781                	li	a5,0
}
    8000346a:	853e                	mv	a0,a5
    8000346c:	70e2                	ld	ra,56(sp)
    8000346e:	7442                	ld	s0,48(sp)
    80003470:	74a2                	ld	s1,40(sp)
    80003472:	7902                	ld	s2,32(sp)
    80003474:	69e2                	ld	s3,24(sp)
    80003476:	6121                	addi	sp,sp,64
    80003478:	8082                	ret
      release(&tickslock);
    8000347a:	00014517          	auipc	a0,0x14
    8000347e:	5fe50513          	addi	a0,a0,1534 # 80017a78 <tickslock>
    80003482:	ffffe097          	auipc	ra,0xffffe
    80003486:	828080e7          	jalr	-2008(ra) # 80000caa <release>
      return -1;
    8000348a:	57fd                	li	a5,-1
    8000348c:	bff9                	j	8000346a <sys_sleep+0x88>

000000008000348e <sys_kill>:

uint64
sys_kill(void)
{
    8000348e:	1101                	addi	sp,sp,-32
    80003490:	ec06                	sd	ra,24(sp)
    80003492:	e822                	sd	s0,16(sp)
    80003494:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003496:	fec40593          	addi	a1,s0,-20
    8000349a:	4501                	li	a0,0
    8000349c:	00000097          	auipc	ra,0x0
    800034a0:	d84080e7          	jalr	-636(ra) # 80003220 <argint>
    800034a4:	87aa                	mv	a5,a0
    return -1;
    800034a6:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800034a8:	0007c863          	bltz	a5,800034b8 <sys_kill+0x2a>
  return kill(pid);
    800034ac:	fec42503          	lw	a0,-20(s0)
    800034b0:	fffff097          	auipc	ra,0xfffff
    800034b4:	5da080e7          	jalr	1498(ra) # 80002a8a <kill>
}
    800034b8:	60e2                	ld	ra,24(sp)
    800034ba:	6442                	ld	s0,16(sp)
    800034bc:	6105                	addi	sp,sp,32
    800034be:	8082                	ret

00000000800034c0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800034c0:	1101                	addi	sp,sp,-32
    800034c2:	ec06                	sd	ra,24(sp)
    800034c4:	e822                	sd	s0,16(sp)
    800034c6:	e426                	sd	s1,8(sp)
    800034c8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800034ca:	00014517          	auipc	a0,0x14
    800034ce:	5ae50513          	addi	a0,a0,1454 # 80017a78 <tickslock>
    800034d2:	ffffd097          	auipc	ra,0xffffd
    800034d6:	712080e7          	jalr	1810(ra) # 80000be4 <acquire>
  xticks = ticks;
    800034da:	00006497          	auipc	s1,0x6
    800034de:	b564a483          	lw	s1,-1194(s1) # 80009030 <ticks>
  release(&tickslock);
    800034e2:	00014517          	auipc	a0,0x14
    800034e6:	59650513          	addi	a0,a0,1430 # 80017a78 <tickslock>
    800034ea:	ffffd097          	auipc	ra,0xffffd
    800034ee:	7c0080e7          	jalr	1984(ra) # 80000caa <release>
  return xticks;
}
    800034f2:	02049513          	slli	a0,s1,0x20
    800034f6:	9101                	srli	a0,a0,0x20
    800034f8:	60e2                	ld	ra,24(sp)
    800034fa:	6442                	ld	s0,16(sp)
    800034fc:	64a2                	ld	s1,8(sp)
    800034fe:	6105                	addi	sp,sp,32
    80003500:	8082                	ret

0000000080003502 <sys_get_cpu>:

uint64
sys_get_cpu(void){
    80003502:	1141                	addi	sp,sp,-16
    80003504:	e406                	sd	ra,8(sp)
    80003506:	e022                	sd	s0,0(sp)
    80003508:	0800                	addi	s0,sp,16
  return get_cpu();
    8000350a:	fffff097          	auipc	ra,0xfffff
    8000350e:	7d2080e7          	jalr	2002(ra) # 80002cdc <get_cpu>
}
    80003512:	60a2                	ld	ra,8(sp)
    80003514:	6402                	ld	s0,0(sp)
    80003516:	0141                	addi	sp,sp,16
    80003518:	8082                	ret

000000008000351a <sys_set_cpu>:

uint64
sys_set_cpu(void){
    8000351a:	1101                	addi	sp,sp,-32
    8000351c:	ec06                	sd	ra,24(sp)
    8000351e:	e822                	sd	s0,16(sp)
    80003520:	1000                	addi	s0,sp,32
  int cpu_num;

  if(argint(0, &cpu_num) < 0)
    80003522:	fec40593          	addi	a1,s0,-20
    80003526:	4501                	li	a0,0
    80003528:	00000097          	auipc	ra,0x0
    8000352c:	cf8080e7          	jalr	-776(ra) # 80003220 <argint>
    80003530:	87aa                	mv	a5,a0
    return -1;
    80003532:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    80003534:	0007c863          	bltz	a5,80003544 <sys_set_cpu+0x2a>
  return set_cpu(cpu_num);
    80003538:	fec42503          	lw	a0,-20(s0)
    8000353c:	fffff097          	auipc	ra,0xfffff
    80003540:	762080e7          	jalr	1890(ra) # 80002c9e <set_cpu>
}
    80003544:	60e2                	ld	ra,24(sp)
    80003546:	6442                	ld	s0,16(sp)
    80003548:	6105                	addi	sp,sp,32
    8000354a:	8082                	ret

000000008000354c <sys_cpu_process_count>:

uint64
sys_cpu_process_count(void){
    8000354c:	1101                	addi	sp,sp,-32
    8000354e:	ec06                	sd	ra,24(sp)
    80003550:	e822                	sd	s0,16(sp)
    80003552:	1000                	addi	s0,sp,32
  int cpu_num;

  if(argint(0, &cpu_num) < 0)
    80003554:	fec40593          	addi	a1,s0,-20
    80003558:	4501                	li	a0,0
    8000355a:	00000097          	auipc	ra,0x0
    8000355e:	cc6080e7          	jalr	-826(ra) # 80003220 <argint>
    80003562:	87aa                	mv	a5,a0
    return -1;
    80003564:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    80003566:	0007c863          	bltz	a5,80003576 <sys_cpu_process_count+0x2a>
  return cpu_process_count(cpu_num);
    8000356a:	fec42503          	lw	a0,-20(s0)
    8000356e:	fffff097          	auipc	ra,0xfffff
    80003572:	79e080e7          	jalr	1950(ra) # 80002d0c <cpu_process_count>
}
    80003576:	60e2                	ld	ra,24(sp)
    80003578:	6442                	ld	s0,16(sp)
    8000357a:	6105                	addi	sp,sp,32
    8000357c:	8082                	ret

000000008000357e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000357e:	7179                	addi	sp,sp,-48
    80003580:	f406                	sd	ra,40(sp)
    80003582:	f022                	sd	s0,32(sp)
    80003584:	ec26                	sd	s1,24(sp)
    80003586:	e84a                	sd	s2,16(sp)
    80003588:	e44e                	sd	s3,8(sp)
    8000358a:	e052                	sd	s4,0(sp)
    8000358c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000358e:	00005597          	auipc	a1,0x5
    80003592:	01a58593          	addi	a1,a1,26 # 800085a8 <syscalls+0xc8>
    80003596:	00014517          	auipc	a0,0x14
    8000359a:	4fa50513          	addi	a0,a0,1274 # 80017a90 <bcache>
    8000359e:	ffffd097          	auipc	ra,0xffffd
    800035a2:	5b6080e7          	jalr	1462(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800035a6:	0001c797          	auipc	a5,0x1c
    800035aa:	4ea78793          	addi	a5,a5,1258 # 8001fa90 <bcache+0x8000>
    800035ae:	0001c717          	auipc	a4,0x1c
    800035b2:	74a70713          	addi	a4,a4,1866 # 8001fcf8 <bcache+0x8268>
    800035b6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800035ba:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035be:	00014497          	auipc	s1,0x14
    800035c2:	4ea48493          	addi	s1,s1,1258 # 80017aa8 <bcache+0x18>
    b->next = bcache.head.next;
    800035c6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800035c8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800035ca:	00005a17          	auipc	s4,0x5
    800035ce:	fe6a0a13          	addi	s4,s4,-26 # 800085b0 <syscalls+0xd0>
    b->next = bcache.head.next;
    800035d2:	2b893783          	ld	a5,696(s2)
    800035d6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800035d8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800035dc:	85d2                	mv	a1,s4
    800035de:	01048513          	addi	a0,s1,16
    800035e2:	00001097          	auipc	ra,0x1
    800035e6:	4bc080e7          	jalr	1212(ra) # 80004a9e <initsleeplock>
    bcache.head.next->prev = b;
    800035ea:	2b893783          	ld	a5,696(s2)
    800035ee:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800035f0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035f4:	45848493          	addi	s1,s1,1112
    800035f8:	fd349de3          	bne	s1,s3,800035d2 <binit+0x54>
  }
}
    800035fc:	70a2                	ld	ra,40(sp)
    800035fe:	7402                	ld	s0,32(sp)
    80003600:	64e2                	ld	s1,24(sp)
    80003602:	6942                	ld	s2,16(sp)
    80003604:	69a2                	ld	s3,8(sp)
    80003606:	6a02                	ld	s4,0(sp)
    80003608:	6145                	addi	sp,sp,48
    8000360a:	8082                	ret

000000008000360c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000360c:	7179                	addi	sp,sp,-48
    8000360e:	f406                	sd	ra,40(sp)
    80003610:	f022                	sd	s0,32(sp)
    80003612:	ec26                	sd	s1,24(sp)
    80003614:	e84a                	sd	s2,16(sp)
    80003616:	e44e                	sd	s3,8(sp)
    80003618:	1800                	addi	s0,sp,48
    8000361a:	89aa                	mv	s3,a0
    8000361c:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000361e:	00014517          	auipc	a0,0x14
    80003622:	47250513          	addi	a0,a0,1138 # 80017a90 <bcache>
    80003626:	ffffd097          	auipc	ra,0xffffd
    8000362a:	5be080e7          	jalr	1470(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000362e:	0001c497          	auipc	s1,0x1c
    80003632:	71a4b483          	ld	s1,1818(s1) # 8001fd48 <bcache+0x82b8>
    80003636:	0001c797          	auipc	a5,0x1c
    8000363a:	6c278793          	addi	a5,a5,1730 # 8001fcf8 <bcache+0x8268>
    8000363e:	02f48f63          	beq	s1,a5,8000367c <bread+0x70>
    80003642:	873e                	mv	a4,a5
    80003644:	a021                	j	8000364c <bread+0x40>
    80003646:	68a4                	ld	s1,80(s1)
    80003648:	02e48a63          	beq	s1,a4,8000367c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000364c:	449c                	lw	a5,8(s1)
    8000364e:	ff379ce3          	bne	a5,s3,80003646 <bread+0x3a>
    80003652:	44dc                	lw	a5,12(s1)
    80003654:	ff2799e3          	bne	a5,s2,80003646 <bread+0x3a>
      b->refcnt++;
    80003658:	40bc                	lw	a5,64(s1)
    8000365a:	2785                	addiw	a5,a5,1
    8000365c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000365e:	00014517          	auipc	a0,0x14
    80003662:	43250513          	addi	a0,a0,1074 # 80017a90 <bcache>
    80003666:	ffffd097          	auipc	ra,0xffffd
    8000366a:	644080e7          	jalr	1604(ra) # 80000caa <release>
      acquiresleep(&b->lock);
    8000366e:	01048513          	addi	a0,s1,16
    80003672:	00001097          	auipc	ra,0x1
    80003676:	466080e7          	jalr	1126(ra) # 80004ad8 <acquiresleep>
      return b;
    8000367a:	a8b9                	j	800036d8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000367c:	0001c497          	auipc	s1,0x1c
    80003680:	6c44b483          	ld	s1,1732(s1) # 8001fd40 <bcache+0x82b0>
    80003684:	0001c797          	auipc	a5,0x1c
    80003688:	67478793          	addi	a5,a5,1652 # 8001fcf8 <bcache+0x8268>
    8000368c:	00f48863          	beq	s1,a5,8000369c <bread+0x90>
    80003690:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003692:	40bc                	lw	a5,64(s1)
    80003694:	cf81                	beqz	a5,800036ac <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003696:	64a4                	ld	s1,72(s1)
    80003698:	fee49de3          	bne	s1,a4,80003692 <bread+0x86>
  panic("bget: no buffers");
    8000369c:	00005517          	auipc	a0,0x5
    800036a0:	f1c50513          	addi	a0,a0,-228 # 800085b8 <syscalls+0xd8>
    800036a4:	ffffd097          	auipc	ra,0xffffd
    800036a8:	e9a080e7          	jalr	-358(ra) # 8000053e <panic>
      b->dev = dev;
    800036ac:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800036b0:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800036b4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800036b8:	4785                	li	a5,1
    800036ba:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800036bc:	00014517          	auipc	a0,0x14
    800036c0:	3d450513          	addi	a0,a0,980 # 80017a90 <bcache>
    800036c4:	ffffd097          	auipc	ra,0xffffd
    800036c8:	5e6080e7          	jalr	1510(ra) # 80000caa <release>
      acquiresleep(&b->lock);
    800036cc:	01048513          	addi	a0,s1,16
    800036d0:	00001097          	auipc	ra,0x1
    800036d4:	408080e7          	jalr	1032(ra) # 80004ad8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800036d8:	409c                	lw	a5,0(s1)
    800036da:	cb89                	beqz	a5,800036ec <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800036dc:	8526                	mv	a0,s1
    800036de:	70a2                	ld	ra,40(sp)
    800036e0:	7402                	ld	s0,32(sp)
    800036e2:	64e2                	ld	s1,24(sp)
    800036e4:	6942                	ld	s2,16(sp)
    800036e6:	69a2                	ld	s3,8(sp)
    800036e8:	6145                	addi	sp,sp,48
    800036ea:	8082                	ret
    virtio_disk_rw(b, 0);
    800036ec:	4581                	li	a1,0
    800036ee:	8526                	mv	a0,s1
    800036f0:	00003097          	auipc	ra,0x3
    800036f4:	f06080e7          	jalr	-250(ra) # 800065f6 <virtio_disk_rw>
    b->valid = 1;
    800036f8:	4785                	li	a5,1
    800036fa:	c09c                	sw	a5,0(s1)
  return b;
    800036fc:	b7c5                	j	800036dc <bread+0xd0>

00000000800036fe <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800036fe:	1101                	addi	sp,sp,-32
    80003700:	ec06                	sd	ra,24(sp)
    80003702:	e822                	sd	s0,16(sp)
    80003704:	e426                	sd	s1,8(sp)
    80003706:	1000                	addi	s0,sp,32
    80003708:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000370a:	0541                	addi	a0,a0,16
    8000370c:	00001097          	auipc	ra,0x1
    80003710:	466080e7          	jalr	1126(ra) # 80004b72 <holdingsleep>
    80003714:	cd01                	beqz	a0,8000372c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003716:	4585                	li	a1,1
    80003718:	8526                	mv	a0,s1
    8000371a:	00003097          	auipc	ra,0x3
    8000371e:	edc080e7          	jalr	-292(ra) # 800065f6 <virtio_disk_rw>
}
    80003722:	60e2                	ld	ra,24(sp)
    80003724:	6442                	ld	s0,16(sp)
    80003726:	64a2                	ld	s1,8(sp)
    80003728:	6105                	addi	sp,sp,32
    8000372a:	8082                	ret
    panic("bwrite");
    8000372c:	00005517          	auipc	a0,0x5
    80003730:	ea450513          	addi	a0,a0,-348 # 800085d0 <syscalls+0xf0>
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	e0a080e7          	jalr	-502(ra) # 8000053e <panic>

000000008000373c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000373c:	1101                	addi	sp,sp,-32
    8000373e:	ec06                	sd	ra,24(sp)
    80003740:	e822                	sd	s0,16(sp)
    80003742:	e426                	sd	s1,8(sp)
    80003744:	e04a                	sd	s2,0(sp)
    80003746:	1000                	addi	s0,sp,32
    80003748:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000374a:	01050913          	addi	s2,a0,16
    8000374e:	854a                	mv	a0,s2
    80003750:	00001097          	auipc	ra,0x1
    80003754:	422080e7          	jalr	1058(ra) # 80004b72 <holdingsleep>
    80003758:	c92d                	beqz	a0,800037ca <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000375a:	854a                	mv	a0,s2
    8000375c:	00001097          	auipc	ra,0x1
    80003760:	3d2080e7          	jalr	978(ra) # 80004b2e <releasesleep>

  acquire(&bcache.lock);
    80003764:	00014517          	auipc	a0,0x14
    80003768:	32c50513          	addi	a0,a0,812 # 80017a90 <bcache>
    8000376c:	ffffd097          	auipc	ra,0xffffd
    80003770:	478080e7          	jalr	1144(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003774:	40bc                	lw	a5,64(s1)
    80003776:	37fd                	addiw	a5,a5,-1
    80003778:	0007871b          	sext.w	a4,a5
    8000377c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000377e:	eb05                	bnez	a4,800037ae <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003780:	68bc                	ld	a5,80(s1)
    80003782:	64b8                	ld	a4,72(s1)
    80003784:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003786:	64bc                	ld	a5,72(s1)
    80003788:	68b8                	ld	a4,80(s1)
    8000378a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000378c:	0001c797          	auipc	a5,0x1c
    80003790:	30478793          	addi	a5,a5,772 # 8001fa90 <bcache+0x8000>
    80003794:	2b87b703          	ld	a4,696(a5)
    80003798:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000379a:	0001c717          	auipc	a4,0x1c
    8000379e:	55e70713          	addi	a4,a4,1374 # 8001fcf8 <bcache+0x8268>
    800037a2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800037a4:	2b87b703          	ld	a4,696(a5)
    800037a8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800037aa:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800037ae:	00014517          	auipc	a0,0x14
    800037b2:	2e250513          	addi	a0,a0,738 # 80017a90 <bcache>
    800037b6:	ffffd097          	auipc	ra,0xffffd
    800037ba:	4f4080e7          	jalr	1268(ra) # 80000caa <release>
}
    800037be:	60e2                	ld	ra,24(sp)
    800037c0:	6442                	ld	s0,16(sp)
    800037c2:	64a2                	ld	s1,8(sp)
    800037c4:	6902                	ld	s2,0(sp)
    800037c6:	6105                	addi	sp,sp,32
    800037c8:	8082                	ret
    panic("brelse");
    800037ca:	00005517          	auipc	a0,0x5
    800037ce:	e0e50513          	addi	a0,a0,-498 # 800085d8 <syscalls+0xf8>
    800037d2:	ffffd097          	auipc	ra,0xffffd
    800037d6:	d6c080e7          	jalr	-660(ra) # 8000053e <panic>

00000000800037da <bpin>:

void
bpin(struct buf *b) {
    800037da:	1101                	addi	sp,sp,-32
    800037dc:	ec06                	sd	ra,24(sp)
    800037de:	e822                	sd	s0,16(sp)
    800037e0:	e426                	sd	s1,8(sp)
    800037e2:	1000                	addi	s0,sp,32
    800037e4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037e6:	00014517          	auipc	a0,0x14
    800037ea:	2aa50513          	addi	a0,a0,682 # 80017a90 <bcache>
    800037ee:	ffffd097          	auipc	ra,0xffffd
    800037f2:	3f6080e7          	jalr	1014(ra) # 80000be4 <acquire>
  b->refcnt++;
    800037f6:	40bc                	lw	a5,64(s1)
    800037f8:	2785                	addiw	a5,a5,1
    800037fa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037fc:	00014517          	auipc	a0,0x14
    80003800:	29450513          	addi	a0,a0,660 # 80017a90 <bcache>
    80003804:	ffffd097          	auipc	ra,0xffffd
    80003808:	4a6080e7          	jalr	1190(ra) # 80000caa <release>
}
    8000380c:	60e2                	ld	ra,24(sp)
    8000380e:	6442                	ld	s0,16(sp)
    80003810:	64a2                	ld	s1,8(sp)
    80003812:	6105                	addi	sp,sp,32
    80003814:	8082                	ret

0000000080003816 <bunpin>:

void
bunpin(struct buf *b) {
    80003816:	1101                	addi	sp,sp,-32
    80003818:	ec06                	sd	ra,24(sp)
    8000381a:	e822                	sd	s0,16(sp)
    8000381c:	e426                	sd	s1,8(sp)
    8000381e:	1000                	addi	s0,sp,32
    80003820:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003822:	00014517          	auipc	a0,0x14
    80003826:	26e50513          	addi	a0,a0,622 # 80017a90 <bcache>
    8000382a:	ffffd097          	auipc	ra,0xffffd
    8000382e:	3ba080e7          	jalr	954(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003832:	40bc                	lw	a5,64(s1)
    80003834:	37fd                	addiw	a5,a5,-1
    80003836:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003838:	00014517          	auipc	a0,0x14
    8000383c:	25850513          	addi	a0,a0,600 # 80017a90 <bcache>
    80003840:	ffffd097          	auipc	ra,0xffffd
    80003844:	46a080e7          	jalr	1130(ra) # 80000caa <release>
}
    80003848:	60e2                	ld	ra,24(sp)
    8000384a:	6442                	ld	s0,16(sp)
    8000384c:	64a2                	ld	s1,8(sp)
    8000384e:	6105                	addi	sp,sp,32
    80003850:	8082                	ret

0000000080003852 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003852:	1101                	addi	sp,sp,-32
    80003854:	ec06                	sd	ra,24(sp)
    80003856:	e822                	sd	s0,16(sp)
    80003858:	e426                	sd	s1,8(sp)
    8000385a:	e04a                	sd	s2,0(sp)
    8000385c:	1000                	addi	s0,sp,32
    8000385e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003860:	00d5d59b          	srliw	a1,a1,0xd
    80003864:	0001d797          	auipc	a5,0x1d
    80003868:	9087a783          	lw	a5,-1784(a5) # 8002016c <sb+0x1c>
    8000386c:	9dbd                	addw	a1,a1,a5
    8000386e:	00000097          	auipc	ra,0x0
    80003872:	d9e080e7          	jalr	-610(ra) # 8000360c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003876:	0074f713          	andi	a4,s1,7
    8000387a:	4785                	li	a5,1
    8000387c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003880:	14ce                	slli	s1,s1,0x33
    80003882:	90d9                	srli	s1,s1,0x36
    80003884:	00950733          	add	a4,a0,s1
    80003888:	05874703          	lbu	a4,88(a4)
    8000388c:	00e7f6b3          	and	a3,a5,a4
    80003890:	c69d                	beqz	a3,800038be <bfree+0x6c>
    80003892:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003894:	94aa                	add	s1,s1,a0
    80003896:	fff7c793          	not	a5,a5
    8000389a:	8ff9                	and	a5,a5,a4
    8000389c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800038a0:	00001097          	auipc	ra,0x1
    800038a4:	118080e7          	jalr	280(ra) # 800049b8 <log_write>
  brelse(bp);
    800038a8:	854a                	mv	a0,s2
    800038aa:	00000097          	auipc	ra,0x0
    800038ae:	e92080e7          	jalr	-366(ra) # 8000373c <brelse>
}
    800038b2:	60e2                	ld	ra,24(sp)
    800038b4:	6442                	ld	s0,16(sp)
    800038b6:	64a2                	ld	s1,8(sp)
    800038b8:	6902                	ld	s2,0(sp)
    800038ba:	6105                	addi	sp,sp,32
    800038bc:	8082                	ret
    panic("freeing free block");
    800038be:	00005517          	auipc	a0,0x5
    800038c2:	d2250513          	addi	a0,a0,-734 # 800085e0 <syscalls+0x100>
    800038c6:	ffffd097          	auipc	ra,0xffffd
    800038ca:	c78080e7          	jalr	-904(ra) # 8000053e <panic>

00000000800038ce <balloc>:
{
    800038ce:	711d                	addi	sp,sp,-96
    800038d0:	ec86                	sd	ra,88(sp)
    800038d2:	e8a2                	sd	s0,80(sp)
    800038d4:	e4a6                	sd	s1,72(sp)
    800038d6:	e0ca                	sd	s2,64(sp)
    800038d8:	fc4e                	sd	s3,56(sp)
    800038da:	f852                	sd	s4,48(sp)
    800038dc:	f456                	sd	s5,40(sp)
    800038de:	f05a                	sd	s6,32(sp)
    800038e0:	ec5e                	sd	s7,24(sp)
    800038e2:	e862                	sd	s8,16(sp)
    800038e4:	e466                	sd	s9,8(sp)
    800038e6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800038e8:	0001d797          	auipc	a5,0x1d
    800038ec:	86c7a783          	lw	a5,-1940(a5) # 80020154 <sb+0x4>
    800038f0:	cbd1                	beqz	a5,80003984 <balloc+0xb6>
    800038f2:	8baa                	mv	s7,a0
    800038f4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800038f6:	0001db17          	auipc	s6,0x1d
    800038fa:	85ab0b13          	addi	s6,s6,-1958 # 80020150 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038fe:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003900:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003902:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003904:	6c89                	lui	s9,0x2
    80003906:	a831                	j	80003922 <balloc+0x54>
    brelse(bp);
    80003908:	854a                	mv	a0,s2
    8000390a:	00000097          	auipc	ra,0x0
    8000390e:	e32080e7          	jalr	-462(ra) # 8000373c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003912:	015c87bb          	addw	a5,s9,s5
    80003916:	00078a9b          	sext.w	s5,a5
    8000391a:	004b2703          	lw	a4,4(s6)
    8000391e:	06eaf363          	bgeu	s5,a4,80003984 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003922:	41fad79b          	sraiw	a5,s5,0x1f
    80003926:	0137d79b          	srliw	a5,a5,0x13
    8000392a:	015787bb          	addw	a5,a5,s5
    8000392e:	40d7d79b          	sraiw	a5,a5,0xd
    80003932:	01cb2583          	lw	a1,28(s6)
    80003936:	9dbd                	addw	a1,a1,a5
    80003938:	855e                	mv	a0,s7
    8000393a:	00000097          	auipc	ra,0x0
    8000393e:	cd2080e7          	jalr	-814(ra) # 8000360c <bread>
    80003942:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003944:	004b2503          	lw	a0,4(s6)
    80003948:	000a849b          	sext.w	s1,s5
    8000394c:	8662                	mv	a2,s8
    8000394e:	faa4fde3          	bgeu	s1,a0,80003908 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003952:	41f6579b          	sraiw	a5,a2,0x1f
    80003956:	01d7d69b          	srliw	a3,a5,0x1d
    8000395a:	00c6873b          	addw	a4,a3,a2
    8000395e:	00777793          	andi	a5,a4,7
    80003962:	9f95                	subw	a5,a5,a3
    80003964:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003968:	4037571b          	sraiw	a4,a4,0x3
    8000396c:	00e906b3          	add	a3,s2,a4
    80003970:	0586c683          	lbu	a3,88(a3)
    80003974:	00d7f5b3          	and	a1,a5,a3
    80003978:	cd91                	beqz	a1,80003994 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000397a:	2605                	addiw	a2,a2,1
    8000397c:	2485                	addiw	s1,s1,1
    8000397e:	fd4618e3          	bne	a2,s4,8000394e <balloc+0x80>
    80003982:	b759                	j	80003908 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003984:	00005517          	auipc	a0,0x5
    80003988:	c7450513          	addi	a0,a0,-908 # 800085f8 <syscalls+0x118>
    8000398c:	ffffd097          	auipc	ra,0xffffd
    80003990:	bb2080e7          	jalr	-1102(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003994:	974a                	add	a4,a4,s2
    80003996:	8fd5                	or	a5,a5,a3
    80003998:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000399c:	854a                	mv	a0,s2
    8000399e:	00001097          	auipc	ra,0x1
    800039a2:	01a080e7          	jalr	26(ra) # 800049b8 <log_write>
        brelse(bp);
    800039a6:	854a                	mv	a0,s2
    800039a8:	00000097          	auipc	ra,0x0
    800039ac:	d94080e7          	jalr	-620(ra) # 8000373c <brelse>
  bp = bread(dev, bno);
    800039b0:	85a6                	mv	a1,s1
    800039b2:	855e                	mv	a0,s7
    800039b4:	00000097          	auipc	ra,0x0
    800039b8:	c58080e7          	jalr	-936(ra) # 8000360c <bread>
    800039bc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800039be:	40000613          	li	a2,1024
    800039c2:	4581                	li	a1,0
    800039c4:	05850513          	addi	a0,a0,88
    800039c8:	ffffd097          	auipc	ra,0xffffd
    800039cc:	33c080e7          	jalr	828(ra) # 80000d04 <memset>
  log_write(bp);
    800039d0:	854a                	mv	a0,s2
    800039d2:	00001097          	auipc	ra,0x1
    800039d6:	fe6080e7          	jalr	-26(ra) # 800049b8 <log_write>
  brelse(bp);
    800039da:	854a                	mv	a0,s2
    800039dc:	00000097          	auipc	ra,0x0
    800039e0:	d60080e7          	jalr	-672(ra) # 8000373c <brelse>
}
    800039e4:	8526                	mv	a0,s1
    800039e6:	60e6                	ld	ra,88(sp)
    800039e8:	6446                	ld	s0,80(sp)
    800039ea:	64a6                	ld	s1,72(sp)
    800039ec:	6906                	ld	s2,64(sp)
    800039ee:	79e2                	ld	s3,56(sp)
    800039f0:	7a42                	ld	s4,48(sp)
    800039f2:	7aa2                	ld	s5,40(sp)
    800039f4:	7b02                	ld	s6,32(sp)
    800039f6:	6be2                	ld	s7,24(sp)
    800039f8:	6c42                	ld	s8,16(sp)
    800039fa:	6ca2                	ld	s9,8(sp)
    800039fc:	6125                	addi	sp,sp,96
    800039fe:	8082                	ret

0000000080003a00 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003a00:	7179                	addi	sp,sp,-48
    80003a02:	f406                	sd	ra,40(sp)
    80003a04:	f022                	sd	s0,32(sp)
    80003a06:	ec26                	sd	s1,24(sp)
    80003a08:	e84a                	sd	s2,16(sp)
    80003a0a:	e44e                	sd	s3,8(sp)
    80003a0c:	e052                	sd	s4,0(sp)
    80003a0e:	1800                	addi	s0,sp,48
    80003a10:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003a12:	47ad                	li	a5,11
    80003a14:	04b7fe63          	bgeu	a5,a1,80003a70 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003a18:	ff45849b          	addiw	s1,a1,-12
    80003a1c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003a20:	0ff00793          	li	a5,255
    80003a24:	0ae7e363          	bltu	a5,a4,80003aca <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003a28:	08052583          	lw	a1,128(a0)
    80003a2c:	c5ad                	beqz	a1,80003a96 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003a2e:	00092503          	lw	a0,0(s2)
    80003a32:	00000097          	auipc	ra,0x0
    80003a36:	bda080e7          	jalr	-1062(ra) # 8000360c <bread>
    80003a3a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a3c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a40:	02049593          	slli	a1,s1,0x20
    80003a44:	9181                	srli	a1,a1,0x20
    80003a46:	058a                	slli	a1,a1,0x2
    80003a48:	00b784b3          	add	s1,a5,a1
    80003a4c:	0004a983          	lw	s3,0(s1)
    80003a50:	04098d63          	beqz	s3,80003aaa <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003a54:	8552                	mv	a0,s4
    80003a56:	00000097          	auipc	ra,0x0
    80003a5a:	ce6080e7          	jalr	-794(ra) # 8000373c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a5e:	854e                	mv	a0,s3
    80003a60:	70a2                	ld	ra,40(sp)
    80003a62:	7402                	ld	s0,32(sp)
    80003a64:	64e2                	ld	s1,24(sp)
    80003a66:	6942                	ld	s2,16(sp)
    80003a68:	69a2                	ld	s3,8(sp)
    80003a6a:	6a02                	ld	s4,0(sp)
    80003a6c:	6145                	addi	sp,sp,48
    80003a6e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003a70:	02059493          	slli	s1,a1,0x20
    80003a74:	9081                	srli	s1,s1,0x20
    80003a76:	048a                	slli	s1,s1,0x2
    80003a78:	94aa                	add	s1,s1,a0
    80003a7a:	0504a983          	lw	s3,80(s1)
    80003a7e:	fe0990e3          	bnez	s3,80003a5e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003a82:	4108                	lw	a0,0(a0)
    80003a84:	00000097          	auipc	ra,0x0
    80003a88:	e4a080e7          	jalr	-438(ra) # 800038ce <balloc>
    80003a8c:	0005099b          	sext.w	s3,a0
    80003a90:	0534a823          	sw	s3,80(s1)
    80003a94:	b7e9                	j	80003a5e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003a96:	4108                	lw	a0,0(a0)
    80003a98:	00000097          	auipc	ra,0x0
    80003a9c:	e36080e7          	jalr	-458(ra) # 800038ce <balloc>
    80003aa0:	0005059b          	sext.w	a1,a0
    80003aa4:	08b92023          	sw	a1,128(s2)
    80003aa8:	b759                	j	80003a2e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003aaa:	00092503          	lw	a0,0(s2)
    80003aae:	00000097          	auipc	ra,0x0
    80003ab2:	e20080e7          	jalr	-480(ra) # 800038ce <balloc>
    80003ab6:	0005099b          	sext.w	s3,a0
    80003aba:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003abe:	8552                	mv	a0,s4
    80003ac0:	00001097          	auipc	ra,0x1
    80003ac4:	ef8080e7          	jalr	-264(ra) # 800049b8 <log_write>
    80003ac8:	b771                	j	80003a54 <bmap+0x54>
  panic("bmap: out of range");
    80003aca:	00005517          	auipc	a0,0x5
    80003ace:	b4650513          	addi	a0,a0,-1210 # 80008610 <syscalls+0x130>
    80003ad2:	ffffd097          	auipc	ra,0xffffd
    80003ad6:	a6c080e7          	jalr	-1428(ra) # 8000053e <panic>

0000000080003ada <iget>:
{
    80003ada:	7179                	addi	sp,sp,-48
    80003adc:	f406                	sd	ra,40(sp)
    80003ade:	f022                	sd	s0,32(sp)
    80003ae0:	ec26                	sd	s1,24(sp)
    80003ae2:	e84a                	sd	s2,16(sp)
    80003ae4:	e44e                	sd	s3,8(sp)
    80003ae6:	e052                	sd	s4,0(sp)
    80003ae8:	1800                	addi	s0,sp,48
    80003aea:	89aa                	mv	s3,a0
    80003aec:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003aee:	0001c517          	auipc	a0,0x1c
    80003af2:	68250513          	addi	a0,a0,1666 # 80020170 <itable>
    80003af6:	ffffd097          	auipc	ra,0xffffd
    80003afa:	0ee080e7          	jalr	238(ra) # 80000be4 <acquire>
  empty = 0;
    80003afe:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b00:	0001c497          	auipc	s1,0x1c
    80003b04:	68848493          	addi	s1,s1,1672 # 80020188 <itable+0x18>
    80003b08:	0001e697          	auipc	a3,0x1e
    80003b0c:	11068693          	addi	a3,a3,272 # 80021c18 <log>
    80003b10:	a039                	j	80003b1e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b12:	02090b63          	beqz	s2,80003b48 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b16:	08848493          	addi	s1,s1,136
    80003b1a:	02d48a63          	beq	s1,a3,80003b4e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003b1e:	449c                	lw	a5,8(s1)
    80003b20:	fef059e3          	blez	a5,80003b12 <iget+0x38>
    80003b24:	4098                	lw	a4,0(s1)
    80003b26:	ff3716e3          	bne	a4,s3,80003b12 <iget+0x38>
    80003b2a:	40d8                	lw	a4,4(s1)
    80003b2c:	ff4713e3          	bne	a4,s4,80003b12 <iget+0x38>
      ip->ref++;
    80003b30:	2785                	addiw	a5,a5,1
    80003b32:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003b34:	0001c517          	auipc	a0,0x1c
    80003b38:	63c50513          	addi	a0,a0,1596 # 80020170 <itable>
    80003b3c:	ffffd097          	auipc	ra,0xffffd
    80003b40:	16e080e7          	jalr	366(ra) # 80000caa <release>
      return ip;
    80003b44:	8926                	mv	s2,s1
    80003b46:	a03d                	j	80003b74 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b48:	f7f9                	bnez	a5,80003b16 <iget+0x3c>
    80003b4a:	8926                	mv	s2,s1
    80003b4c:	b7e9                	j	80003b16 <iget+0x3c>
  if(empty == 0)
    80003b4e:	02090c63          	beqz	s2,80003b86 <iget+0xac>
  ip->dev = dev;
    80003b52:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b56:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b5a:	4785                	li	a5,1
    80003b5c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b60:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b64:	0001c517          	auipc	a0,0x1c
    80003b68:	60c50513          	addi	a0,a0,1548 # 80020170 <itable>
    80003b6c:	ffffd097          	auipc	ra,0xffffd
    80003b70:	13e080e7          	jalr	318(ra) # 80000caa <release>
}
    80003b74:	854a                	mv	a0,s2
    80003b76:	70a2                	ld	ra,40(sp)
    80003b78:	7402                	ld	s0,32(sp)
    80003b7a:	64e2                	ld	s1,24(sp)
    80003b7c:	6942                	ld	s2,16(sp)
    80003b7e:	69a2                	ld	s3,8(sp)
    80003b80:	6a02                	ld	s4,0(sp)
    80003b82:	6145                	addi	sp,sp,48
    80003b84:	8082                	ret
    panic("iget: no inodes");
    80003b86:	00005517          	auipc	a0,0x5
    80003b8a:	aa250513          	addi	a0,a0,-1374 # 80008628 <syscalls+0x148>
    80003b8e:	ffffd097          	auipc	ra,0xffffd
    80003b92:	9b0080e7          	jalr	-1616(ra) # 8000053e <panic>

0000000080003b96 <fsinit>:
fsinit(int dev) {
    80003b96:	7179                	addi	sp,sp,-48
    80003b98:	f406                	sd	ra,40(sp)
    80003b9a:	f022                	sd	s0,32(sp)
    80003b9c:	ec26                	sd	s1,24(sp)
    80003b9e:	e84a                	sd	s2,16(sp)
    80003ba0:	e44e                	sd	s3,8(sp)
    80003ba2:	1800                	addi	s0,sp,48
    80003ba4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003ba6:	4585                	li	a1,1
    80003ba8:	00000097          	auipc	ra,0x0
    80003bac:	a64080e7          	jalr	-1436(ra) # 8000360c <bread>
    80003bb0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003bb2:	0001c997          	auipc	s3,0x1c
    80003bb6:	59e98993          	addi	s3,s3,1438 # 80020150 <sb>
    80003bba:	02000613          	li	a2,32
    80003bbe:	05850593          	addi	a1,a0,88
    80003bc2:	854e                	mv	a0,s3
    80003bc4:	ffffd097          	auipc	ra,0xffffd
    80003bc8:	1a0080e7          	jalr	416(ra) # 80000d64 <memmove>
  brelse(bp);
    80003bcc:	8526                	mv	a0,s1
    80003bce:	00000097          	auipc	ra,0x0
    80003bd2:	b6e080e7          	jalr	-1170(ra) # 8000373c <brelse>
  if(sb.magic != FSMAGIC)
    80003bd6:	0009a703          	lw	a4,0(s3)
    80003bda:	102037b7          	lui	a5,0x10203
    80003bde:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003be2:	02f71263          	bne	a4,a5,80003c06 <fsinit+0x70>
  initlog(dev, &sb);
    80003be6:	0001c597          	auipc	a1,0x1c
    80003bea:	56a58593          	addi	a1,a1,1386 # 80020150 <sb>
    80003bee:	854a                	mv	a0,s2
    80003bf0:	00001097          	auipc	ra,0x1
    80003bf4:	b4c080e7          	jalr	-1204(ra) # 8000473c <initlog>
}
    80003bf8:	70a2                	ld	ra,40(sp)
    80003bfa:	7402                	ld	s0,32(sp)
    80003bfc:	64e2                	ld	s1,24(sp)
    80003bfe:	6942                	ld	s2,16(sp)
    80003c00:	69a2                	ld	s3,8(sp)
    80003c02:	6145                	addi	sp,sp,48
    80003c04:	8082                	ret
    panic("invalid file system");
    80003c06:	00005517          	auipc	a0,0x5
    80003c0a:	a3250513          	addi	a0,a0,-1486 # 80008638 <syscalls+0x158>
    80003c0e:	ffffd097          	auipc	ra,0xffffd
    80003c12:	930080e7          	jalr	-1744(ra) # 8000053e <panic>

0000000080003c16 <iinit>:
{
    80003c16:	7179                	addi	sp,sp,-48
    80003c18:	f406                	sd	ra,40(sp)
    80003c1a:	f022                	sd	s0,32(sp)
    80003c1c:	ec26                	sd	s1,24(sp)
    80003c1e:	e84a                	sd	s2,16(sp)
    80003c20:	e44e                	sd	s3,8(sp)
    80003c22:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003c24:	00005597          	auipc	a1,0x5
    80003c28:	a2c58593          	addi	a1,a1,-1492 # 80008650 <syscalls+0x170>
    80003c2c:	0001c517          	auipc	a0,0x1c
    80003c30:	54450513          	addi	a0,a0,1348 # 80020170 <itable>
    80003c34:	ffffd097          	auipc	ra,0xffffd
    80003c38:	f20080e7          	jalr	-224(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c3c:	0001c497          	auipc	s1,0x1c
    80003c40:	55c48493          	addi	s1,s1,1372 # 80020198 <itable+0x28>
    80003c44:	0001e997          	auipc	s3,0x1e
    80003c48:	fe498993          	addi	s3,s3,-28 # 80021c28 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c4c:	00005917          	auipc	s2,0x5
    80003c50:	a0c90913          	addi	s2,s2,-1524 # 80008658 <syscalls+0x178>
    80003c54:	85ca                	mv	a1,s2
    80003c56:	8526                	mv	a0,s1
    80003c58:	00001097          	auipc	ra,0x1
    80003c5c:	e46080e7          	jalr	-442(ra) # 80004a9e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c60:	08848493          	addi	s1,s1,136
    80003c64:	ff3498e3          	bne	s1,s3,80003c54 <iinit+0x3e>
}
    80003c68:	70a2                	ld	ra,40(sp)
    80003c6a:	7402                	ld	s0,32(sp)
    80003c6c:	64e2                	ld	s1,24(sp)
    80003c6e:	6942                	ld	s2,16(sp)
    80003c70:	69a2                	ld	s3,8(sp)
    80003c72:	6145                	addi	sp,sp,48
    80003c74:	8082                	ret

0000000080003c76 <ialloc>:
{
    80003c76:	715d                	addi	sp,sp,-80
    80003c78:	e486                	sd	ra,72(sp)
    80003c7a:	e0a2                	sd	s0,64(sp)
    80003c7c:	fc26                	sd	s1,56(sp)
    80003c7e:	f84a                	sd	s2,48(sp)
    80003c80:	f44e                	sd	s3,40(sp)
    80003c82:	f052                	sd	s4,32(sp)
    80003c84:	ec56                	sd	s5,24(sp)
    80003c86:	e85a                	sd	s6,16(sp)
    80003c88:	e45e                	sd	s7,8(sp)
    80003c8a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c8c:	0001c717          	auipc	a4,0x1c
    80003c90:	4d072703          	lw	a4,1232(a4) # 8002015c <sb+0xc>
    80003c94:	4785                	li	a5,1
    80003c96:	04e7fa63          	bgeu	a5,a4,80003cea <ialloc+0x74>
    80003c9a:	8aaa                	mv	s5,a0
    80003c9c:	8bae                	mv	s7,a1
    80003c9e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003ca0:	0001ca17          	auipc	s4,0x1c
    80003ca4:	4b0a0a13          	addi	s4,s4,1200 # 80020150 <sb>
    80003ca8:	00048b1b          	sext.w	s6,s1
    80003cac:	0044d593          	srli	a1,s1,0x4
    80003cb0:	018a2783          	lw	a5,24(s4)
    80003cb4:	9dbd                	addw	a1,a1,a5
    80003cb6:	8556                	mv	a0,s5
    80003cb8:	00000097          	auipc	ra,0x0
    80003cbc:	954080e7          	jalr	-1708(ra) # 8000360c <bread>
    80003cc0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003cc2:	05850993          	addi	s3,a0,88
    80003cc6:	00f4f793          	andi	a5,s1,15
    80003cca:	079a                	slli	a5,a5,0x6
    80003ccc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003cce:	00099783          	lh	a5,0(s3)
    80003cd2:	c785                	beqz	a5,80003cfa <ialloc+0x84>
    brelse(bp);
    80003cd4:	00000097          	auipc	ra,0x0
    80003cd8:	a68080e7          	jalr	-1432(ra) # 8000373c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003cdc:	0485                	addi	s1,s1,1
    80003cde:	00ca2703          	lw	a4,12(s4)
    80003ce2:	0004879b          	sext.w	a5,s1
    80003ce6:	fce7e1e3          	bltu	a5,a4,80003ca8 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003cea:	00005517          	auipc	a0,0x5
    80003cee:	97650513          	addi	a0,a0,-1674 # 80008660 <syscalls+0x180>
    80003cf2:	ffffd097          	auipc	ra,0xffffd
    80003cf6:	84c080e7          	jalr	-1972(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003cfa:	04000613          	li	a2,64
    80003cfe:	4581                	li	a1,0
    80003d00:	854e                	mv	a0,s3
    80003d02:	ffffd097          	auipc	ra,0xffffd
    80003d06:	002080e7          	jalr	2(ra) # 80000d04 <memset>
      dip->type = type;
    80003d0a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003d0e:	854a                	mv	a0,s2
    80003d10:	00001097          	auipc	ra,0x1
    80003d14:	ca8080e7          	jalr	-856(ra) # 800049b8 <log_write>
      brelse(bp);
    80003d18:	854a                	mv	a0,s2
    80003d1a:	00000097          	auipc	ra,0x0
    80003d1e:	a22080e7          	jalr	-1502(ra) # 8000373c <brelse>
      return iget(dev, inum);
    80003d22:	85da                	mv	a1,s6
    80003d24:	8556                	mv	a0,s5
    80003d26:	00000097          	auipc	ra,0x0
    80003d2a:	db4080e7          	jalr	-588(ra) # 80003ada <iget>
}
    80003d2e:	60a6                	ld	ra,72(sp)
    80003d30:	6406                	ld	s0,64(sp)
    80003d32:	74e2                	ld	s1,56(sp)
    80003d34:	7942                	ld	s2,48(sp)
    80003d36:	79a2                	ld	s3,40(sp)
    80003d38:	7a02                	ld	s4,32(sp)
    80003d3a:	6ae2                	ld	s5,24(sp)
    80003d3c:	6b42                	ld	s6,16(sp)
    80003d3e:	6ba2                	ld	s7,8(sp)
    80003d40:	6161                	addi	sp,sp,80
    80003d42:	8082                	ret

0000000080003d44 <iupdate>:
{
    80003d44:	1101                	addi	sp,sp,-32
    80003d46:	ec06                	sd	ra,24(sp)
    80003d48:	e822                	sd	s0,16(sp)
    80003d4a:	e426                	sd	s1,8(sp)
    80003d4c:	e04a                	sd	s2,0(sp)
    80003d4e:	1000                	addi	s0,sp,32
    80003d50:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d52:	415c                	lw	a5,4(a0)
    80003d54:	0047d79b          	srliw	a5,a5,0x4
    80003d58:	0001c597          	auipc	a1,0x1c
    80003d5c:	4105a583          	lw	a1,1040(a1) # 80020168 <sb+0x18>
    80003d60:	9dbd                	addw	a1,a1,a5
    80003d62:	4108                	lw	a0,0(a0)
    80003d64:	00000097          	auipc	ra,0x0
    80003d68:	8a8080e7          	jalr	-1880(ra) # 8000360c <bread>
    80003d6c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d6e:	05850793          	addi	a5,a0,88
    80003d72:	40c8                	lw	a0,4(s1)
    80003d74:	893d                	andi	a0,a0,15
    80003d76:	051a                	slli	a0,a0,0x6
    80003d78:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003d7a:	04449703          	lh	a4,68(s1)
    80003d7e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003d82:	04649703          	lh	a4,70(s1)
    80003d86:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003d8a:	04849703          	lh	a4,72(s1)
    80003d8e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003d92:	04a49703          	lh	a4,74(s1)
    80003d96:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003d9a:	44f8                	lw	a4,76(s1)
    80003d9c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d9e:	03400613          	li	a2,52
    80003da2:	05048593          	addi	a1,s1,80
    80003da6:	0531                	addi	a0,a0,12
    80003da8:	ffffd097          	auipc	ra,0xffffd
    80003dac:	fbc080e7          	jalr	-68(ra) # 80000d64 <memmove>
  log_write(bp);
    80003db0:	854a                	mv	a0,s2
    80003db2:	00001097          	auipc	ra,0x1
    80003db6:	c06080e7          	jalr	-1018(ra) # 800049b8 <log_write>
  brelse(bp);
    80003dba:	854a                	mv	a0,s2
    80003dbc:	00000097          	auipc	ra,0x0
    80003dc0:	980080e7          	jalr	-1664(ra) # 8000373c <brelse>
}
    80003dc4:	60e2                	ld	ra,24(sp)
    80003dc6:	6442                	ld	s0,16(sp)
    80003dc8:	64a2                	ld	s1,8(sp)
    80003dca:	6902                	ld	s2,0(sp)
    80003dcc:	6105                	addi	sp,sp,32
    80003dce:	8082                	ret

0000000080003dd0 <idup>:
{
    80003dd0:	1101                	addi	sp,sp,-32
    80003dd2:	ec06                	sd	ra,24(sp)
    80003dd4:	e822                	sd	s0,16(sp)
    80003dd6:	e426                	sd	s1,8(sp)
    80003dd8:	1000                	addi	s0,sp,32
    80003dda:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ddc:	0001c517          	auipc	a0,0x1c
    80003de0:	39450513          	addi	a0,a0,916 # 80020170 <itable>
    80003de4:	ffffd097          	auipc	ra,0xffffd
    80003de8:	e00080e7          	jalr	-512(ra) # 80000be4 <acquire>
  ip->ref++;
    80003dec:	449c                	lw	a5,8(s1)
    80003dee:	2785                	addiw	a5,a5,1
    80003df0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003df2:	0001c517          	auipc	a0,0x1c
    80003df6:	37e50513          	addi	a0,a0,894 # 80020170 <itable>
    80003dfa:	ffffd097          	auipc	ra,0xffffd
    80003dfe:	eb0080e7          	jalr	-336(ra) # 80000caa <release>
}
    80003e02:	8526                	mv	a0,s1
    80003e04:	60e2                	ld	ra,24(sp)
    80003e06:	6442                	ld	s0,16(sp)
    80003e08:	64a2                	ld	s1,8(sp)
    80003e0a:	6105                	addi	sp,sp,32
    80003e0c:	8082                	ret

0000000080003e0e <ilock>:
{
    80003e0e:	1101                	addi	sp,sp,-32
    80003e10:	ec06                	sd	ra,24(sp)
    80003e12:	e822                	sd	s0,16(sp)
    80003e14:	e426                	sd	s1,8(sp)
    80003e16:	e04a                	sd	s2,0(sp)
    80003e18:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003e1a:	c115                	beqz	a0,80003e3e <ilock+0x30>
    80003e1c:	84aa                	mv	s1,a0
    80003e1e:	451c                	lw	a5,8(a0)
    80003e20:	00f05f63          	blez	a5,80003e3e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003e24:	0541                	addi	a0,a0,16
    80003e26:	00001097          	auipc	ra,0x1
    80003e2a:	cb2080e7          	jalr	-846(ra) # 80004ad8 <acquiresleep>
  if(ip->valid == 0){
    80003e2e:	40bc                	lw	a5,64(s1)
    80003e30:	cf99                	beqz	a5,80003e4e <ilock+0x40>
}
    80003e32:	60e2                	ld	ra,24(sp)
    80003e34:	6442                	ld	s0,16(sp)
    80003e36:	64a2                	ld	s1,8(sp)
    80003e38:	6902                	ld	s2,0(sp)
    80003e3a:	6105                	addi	sp,sp,32
    80003e3c:	8082                	ret
    panic("ilock");
    80003e3e:	00005517          	auipc	a0,0x5
    80003e42:	83a50513          	addi	a0,a0,-1990 # 80008678 <syscalls+0x198>
    80003e46:	ffffc097          	auipc	ra,0xffffc
    80003e4a:	6f8080e7          	jalr	1784(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e4e:	40dc                	lw	a5,4(s1)
    80003e50:	0047d79b          	srliw	a5,a5,0x4
    80003e54:	0001c597          	auipc	a1,0x1c
    80003e58:	3145a583          	lw	a1,788(a1) # 80020168 <sb+0x18>
    80003e5c:	9dbd                	addw	a1,a1,a5
    80003e5e:	4088                	lw	a0,0(s1)
    80003e60:	fffff097          	auipc	ra,0xfffff
    80003e64:	7ac080e7          	jalr	1964(ra) # 8000360c <bread>
    80003e68:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e6a:	05850593          	addi	a1,a0,88
    80003e6e:	40dc                	lw	a5,4(s1)
    80003e70:	8bbd                	andi	a5,a5,15
    80003e72:	079a                	slli	a5,a5,0x6
    80003e74:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e76:	00059783          	lh	a5,0(a1)
    80003e7a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e7e:	00259783          	lh	a5,2(a1)
    80003e82:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e86:	00459783          	lh	a5,4(a1)
    80003e8a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e8e:	00659783          	lh	a5,6(a1)
    80003e92:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e96:	459c                	lw	a5,8(a1)
    80003e98:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e9a:	03400613          	li	a2,52
    80003e9e:	05b1                	addi	a1,a1,12
    80003ea0:	05048513          	addi	a0,s1,80
    80003ea4:	ffffd097          	auipc	ra,0xffffd
    80003ea8:	ec0080e7          	jalr	-320(ra) # 80000d64 <memmove>
    brelse(bp);
    80003eac:	854a                	mv	a0,s2
    80003eae:	00000097          	auipc	ra,0x0
    80003eb2:	88e080e7          	jalr	-1906(ra) # 8000373c <brelse>
    ip->valid = 1;
    80003eb6:	4785                	li	a5,1
    80003eb8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003eba:	04449783          	lh	a5,68(s1)
    80003ebe:	fbb5                	bnez	a5,80003e32 <ilock+0x24>
      panic("ilock: no type");
    80003ec0:	00004517          	auipc	a0,0x4
    80003ec4:	7c050513          	addi	a0,a0,1984 # 80008680 <syscalls+0x1a0>
    80003ec8:	ffffc097          	auipc	ra,0xffffc
    80003ecc:	676080e7          	jalr	1654(ra) # 8000053e <panic>

0000000080003ed0 <iunlock>:
{
    80003ed0:	1101                	addi	sp,sp,-32
    80003ed2:	ec06                	sd	ra,24(sp)
    80003ed4:	e822                	sd	s0,16(sp)
    80003ed6:	e426                	sd	s1,8(sp)
    80003ed8:	e04a                	sd	s2,0(sp)
    80003eda:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003edc:	c905                	beqz	a0,80003f0c <iunlock+0x3c>
    80003ede:	84aa                	mv	s1,a0
    80003ee0:	01050913          	addi	s2,a0,16
    80003ee4:	854a                	mv	a0,s2
    80003ee6:	00001097          	auipc	ra,0x1
    80003eea:	c8c080e7          	jalr	-884(ra) # 80004b72 <holdingsleep>
    80003eee:	cd19                	beqz	a0,80003f0c <iunlock+0x3c>
    80003ef0:	449c                	lw	a5,8(s1)
    80003ef2:	00f05d63          	blez	a5,80003f0c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ef6:	854a                	mv	a0,s2
    80003ef8:	00001097          	auipc	ra,0x1
    80003efc:	c36080e7          	jalr	-970(ra) # 80004b2e <releasesleep>
}
    80003f00:	60e2                	ld	ra,24(sp)
    80003f02:	6442                	ld	s0,16(sp)
    80003f04:	64a2                	ld	s1,8(sp)
    80003f06:	6902                	ld	s2,0(sp)
    80003f08:	6105                	addi	sp,sp,32
    80003f0a:	8082                	ret
    panic("iunlock");
    80003f0c:	00004517          	auipc	a0,0x4
    80003f10:	78450513          	addi	a0,a0,1924 # 80008690 <syscalls+0x1b0>
    80003f14:	ffffc097          	auipc	ra,0xffffc
    80003f18:	62a080e7          	jalr	1578(ra) # 8000053e <panic>

0000000080003f1c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003f1c:	7179                	addi	sp,sp,-48
    80003f1e:	f406                	sd	ra,40(sp)
    80003f20:	f022                	sd	s0,32(sp)
    80003f22:	ec26                	sd	s1,24(sp)
    80003f24:	e84a                	sd	s2,16(sp)
    80003f26:	e44e                	sd	s3,8(sp)
    80003f28:	e052                	sd	s4,0(sp)
    80003f2a:	1800                	addi	s0,sp,48
    80003f2c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003f2e:	05050493          	addi	s1,a0,80
    80003f32:	08050913          	addi	s2,a0,128
    80003f36:	a021                	j	80003f3e <itrunc+0x22>
    80003f38:	0491                	addi	s1,s1,4
    80003f3a:	01248d63          	beq	s1,s2,80003f54 <itrunc+0x38>
    if(ip->addrs[i]){
    80003f3e:	408c                	lw	a1,0(s1)
    80003f40:	dde5                	beqz	a1,80003f38 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f42:	0009a503          	lw	a0,0(s3)
    80003f46:	00000097          	auipc	ra,0x0
    80003f4a:	90c080e7          	jalr	-1780(ra) # 80003852 <bfree>
      ip->addrs[i] = 0;
    80003f4e:	0004a023          	sw	zero,0(s1)
    80003f52:	b7dd                	j	80003f38 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f54:	0809a583          	lw	a1,128(s3)
    80003f58:	e185                	bnez	a1,80003f78 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f5a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f5e:	854e                	mv	a0,s3
    80003f60:	00000097          	auipc	ra,0x0
    80003f64:	de4080e7          	jalr	-540(ra) # 80003d44 <iupdate>
}
    80003f68:	70a2                	ld	ra,40(sp)
    80003f6a:	7402                	ld	s0,32(sp)
    80003f6c:	64e2                	ld	s1,24(sp)
    80003f6e:	6942                	ld	s2,16(sp)
    80003f70:	69a2                	ld	s3,8(sp)
    80003f72:	6a02                	ld	s4,0(sp)
    80003f74:	6145                	addi	sp,sp,48
    80003f76:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f78:	0009a503          	lw	a0,0(s3)
    80003f7c:	fffff097          	auipc	ra,0xfffff
    80003f80:	690080e7          	jalr	1680(ra) # 8000360c <bread>
    80003f84:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f86:	05850493          	addi	s1,a0,88
    80003f8a:	45850913          	addi	s2,a0,1112
    80003f8e:	a811                	j	80003fa2 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003f90:	0009a503          	lw	a0,0(s3)
    80003f94:	00000097          	auipc	ra,0x0
    80003f98:	8be080e7          	jalr	-1858(ra) # 80003852 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003f9c:	0491                	addi	s1,s1,4
    80003f9e:	01248563          	beq	s1,s2,80003fa8 <itrunc+0x8c>
      if(a[j])
    80003fa2:	408c                	lw	a1,0(s1)
    80003fa4:	dde5                	beqz	a1,80003f9c <itrunc+0x80>
    80003fa6:	b7ed                	j	80003f90 <itrunc+0x74>
    brelse(bp);
    80003fa8:	8552                	mv	a0,s4
    80003faa:	fffff097          	auipc	ra,0xfffff
    80003fae:	792080e7          	jalr	1938(ra) # 8000373c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003fb2:	0809a583          	lw	a1,128(s3)
    80003fb6:	0009a503          	lw	a0,0(s3)
    80003fba:	00000097          	auipc	ra,0x0
    80003fbe:	898080e7          	jalr	-1896(ra) # 80003852 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003fc2:	0809a023          	sw	zero,128(s3)
    80003fc6:	bf51                	j	80003f5a <itrunc+0x3e>

0000000080003fc8 <iput>:
{
    80003fc8:	1101                	addi	sp,sp,-32
    80003fca:	ec06                	sd	ra,24(sp)
    80003fcc:	e822                	sd	s0,16(sp)
    80003fce:	e426                	sd	s1,8(sp)
    80003fd0:	e04a                	sd	s2,0(sp)
    80003fd2:	1000                	addi	s0,sp,32
    80003fd4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003fd6:	0001c517          	auipc	a0,0x1c
    80003fda:	19a50513          	addi	a0,a0,410 # 80020170 <itable>
    80003fde:	ffffd097          	auipc	ra,0xffffd
    80003fe2:	c06080e7          	jalr	-1018(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fe6:	4498                	lw	a4,8(s1)
    80003fe8:	4785                	li	a5,1
    80003fea:	02f70363          	beq	a4,a5,80004010 <iput+0x48>
  ip->ref--;
    80003fee:	449c                	lw	a5,8(s1)
    80003ff0:	37fd                	addiw	a5,a5,-1
    80003ff2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ff4:	0001c517          	auipc	a0,0x1c
    80003ff8:	17c50513          	addi	a0,a0,380 # 80020170 <itable>
    80003ffc:	ffffd097          	auipc	ra,0xffffd
    80004000:	cae080e7          	jalr	-850(ra) # 80000caa <release>
}
    80004004:	60e2                	ld	ra,24(sp)
    80004006:	6442                	ld	s0,16(sp)
    80004008:	64a2                	ld	s1,8(sp)
    8000400a:	6902                	ld	s2,0(sp)
    8000400c:	6105                	addi	sp,sp,32
    8000400e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004010:	40bc                	lw	a5,64(s1)
    80004012:	dff1                	beqz	a5,80003fee <iput+0x26>
    80004014:	04a49783          	lh	a5,74(s1)
    80004018:	fbf9                	bnez	a5,80003fee <iput+0x26>
    acquiresleep(&ip->lock);
    8000401a:	01048913          	addi	s2,s1,16
    8000401e:	854a                	mv	a0,s2
    80004020:	00001097          	auipc	ra,0x1
    80004024:	ab8080e7          	jalr	-1352(ra) # 80004ad8 <acquiresleep>
    release(&itable.lock);
    80004028:	0001c517          	auipc	a0,0x1c
    8000402c:	14850513          	addi	a0,a0,328 # 80020170 <itable>
    80004030:	ffffd097          	auipc	ra,0xffffd
    80004034:	c7a080e7          	jalr	-902(ra) # 80000caa <release>
    itrunc(ip);
    80004038:	8526                	mv	a0,s1
    8000403a:	00000097          	auipc	ra,0x0
    8000403e:	ee2080e7          	jalr	-286(ra) # 80003f1c <itrunc>
    ip->type = 0;
    80004042:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004046:	8526                	mv	a0,s1
    80004048:	00000097          	auipc	ra,0x0
    8000404c:	cfc080e7          	jalr	-772(ra) # 80003d44 <iupdate>
    ip->valid = 0;
    80004050:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004054:	854a                	mv	a0,s2
    80004056:	00001097          	auipc	ra,0x1
    8000405a:	ad8080e7          	jalr	-1320(ra) # 80004b2e <releasesleep>
    acquire(&itable.lock);
    8000405e:	0001c517          	auipc	a0,0x1c
    80004062:	11250513          	addi	a0,a0,274 # 80020170 <itable>
    80004066:	ffffd097          	auipc	ra,0xffffd
    8000406a:	b7e080e7          	jalr	-1154(ra) # 80000be4 <acquire>
    8000406e:	b741                	j	80003fee <iput+0x26>

0000000080004070 <iunlockput>:
{
    80004070:	1101                	addi	sp,sp,-32
    80004072:	ec06                	sd	ra,24(sp)
    80004074:	e822                	sd	s0,16(sp)
    80004076:	e426                	sd	s1,8(sp)
    80004078:	1000                	addi	s0,sp,32
    8000407a:	84aa                	mv	s1,a0
  iunlock(ip);
    8000407c:	00000097          	auipc	ra,0x0
    80004080:	e54080e7          	jalr	-428(ra) # 80003ed0 <iunlock>
  iput(ip);
    80004084:	8526                	mv	a0,s1
    80004086:	00000097          	auipc	ra,0x0
    8000408a:	f42080e7          	jalr	-190(ra) # 80003fc8 <iput>
}
    8000408e:	60e2                	ld	ra,24(sp)
    80004090:	6442                	ld	s0,16(sp)
    80004092:	64a2                	ld	s1,8(sp)
    80004094:	6105                	addi	sp,sp,32
    80004096:	8082                	ret

0000000080004098 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004098:	1141                	addi	sp,sp,-16
    8000409a:	e422                	sd	s0,8(sp)
    8000409c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000409e:	411c                	lw	a5,0(a0)
    800040a0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800040a2:	415c                	lw	a5,4(a0)
    800040a4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800040a6:	04451783          	lh	a5,68(a0)
    800040aa:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800040ae:	04a51783          	lh	a5,74(a0)
    800040b2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800040b6:	04c56783          	lwu	a5,76(a0)
    800040ba:	e99c                	sd	a5,16(a1)
}
    800040bc:	6422                	ld	s0,8(sp)
    800040be:	0141                	addi	sp,sp,16
    800040c0:	8082                	ret

00000000800040c2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040c2:	457c                	lw	a5,76(a0)
    800040c4:	0ed7e963          	bltu	a5,a3,800041b6 <readi+0xf4>
{
    800040c8:	7159                	addi	sp,sp,-112
    800040ca:	f486                	sd	ra,104(sp)
    800040cc:	f0a2                	sd	s0,96(sp)
    800040ce:	eca6                	sd	s1,88(sp)
    800040d0:	e8ca                	sd	s2,80(sp)
    800040d2:	e4ce                	sd	s3,72(sp)
    800040d4:	e0d2                	sd	s4,64(sp)
    800040d6:	fc56                	sd	s5,56(sp)
    800040d8:	f85a                	sd	s6,48(sp)
    800040da:	f45e                	sd	s7,40(sp)
    800040dc:	f062                	sd	s8,32(sp)
    800040de:	ec66                	sd	s9,24(sp)
    800040e0:	e86a                	sd	s10,16(sp)
    800040e2:	e46e                	sd	s11,8(sp)
    800040e4:	1880                	addi	s0,sp,112
    800040e6:	8baa                	mv	s7,a0
    800040e8:	8c2e                	mv	s8,a1
    800040ea:	8ab2                	mv	s5,a2
    800040ec:	84b6                	mv	s1,a3
    800040ee:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800040f0:	9f35                	addw	a4,a4,a3
    return 0;
    800040f2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800040f4:	0ad76063          	bltu	a4,a3,80004194 <readi+0xd2>
  if(off + n > ip->size)
    800040f8:	00e7f463          	bgeu	a5,a4,80004100 <readi+0x3e>
    n = ip->size - off;
    800040fc:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004100:	0a0b0963          	beqz	s6,800041b2 <readi+0xf0>
    80004104:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004106:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000410a:	5cfd                	li	s9,-1
    8000410c:	a82d                	j	80004146 <readi+0x84>
    8000410e:	020a1d93          	slli	s11,s4,0x20
    80004112:	020ddd93          	srli	s11,s11,0x20
    80004116:	05890613          	addi	a2,s2,88
    8000411a:	86ee                	mv	a3,s11
    8000411c:	963a                	add	a2,a2,a4
    8000411e:	85d6                	mv	a1,s5
    80004120:	8562                	mv	a0,s8
    80004122:	fffff097          	auipc	ra,0xfffff
    80004126:	a1e080e7          	jalr	-1506(ra) # 80002b40 <either_copyout>
    8000412a:	05950d63          	beq	a0,s9,80004184 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000412e:	854a                	mv	a0,s2
    80004130:	fffff097          	auipc	ra,0xfffff
    80004134:	60c080e7          	jalr	1548(ra) # 8000373c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004138:	013a09bb          	addw	s3,s4,s3
    8000413c:	009a04bb          	addw	s1,s4,s1
    80004140:	9aee                	add	s5,s5,s11
    80004142:	0569f763          	bgeu	s3,s6,80004190 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004146:	000ba903          	lw	s2,0(s7)
    8000414a:	00a4d59b          	srliw	a1,s1,0xa
    8000414e:	855e                	mv	a0,s7
    80004150:	00000097          	auipc	ra,0x0
    80004154:	8b0080e7          	jalr	-1872(ra) # 80003a00 <bmap>
    80004158:	0005059b          	sext.w	a1,a0
    8000415c:	854a                	mv	a0,s2
    8000415e:	fffff097          	auipc	ra,0xfffff
    80004162:	4ae080e7          	jalr	1198(ra) # 8000360c <bread>
    80004166:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004168:	3ff4f713          	andi	a4,s1,1023
    8000416c:	40ed07bb          	subw	a5,s10,a4
    80004170:	413b06bb          	subw	a3,s6,s3
    80004174:	8a3e                	mv	s4,a5
    80004176:	2781                	sext.w	a5,a5
    80004178:	0006861b          	sext.w	a2,a3
    8000417c:	f8f679e3          	bgeu	a2,a5,8000410e <readi+0x4c>
    80004180:	8a36                	mv	s4,a3
    80004182:	b771                	j	8000410e <readi+0x4c>
      brelse(bp);
    80004184:	854a                	mv	a0,s2
    80004186:	fffff097          	auipc	ra,0xfffff
    8000418a:	5b6080e7          	jalr	1462(ra) # 8000373c <brelse>
      tot = -1;
    8000418e:	59fd                	li	s3,-1
  }
  return tot;
    80004190:	0009851b          	sext.w	a0,s3
}
    80004194:	70a6                	ld	ra,104(sp)
    80004196:	7406                	ld	s0,96(sp)
    80004198:	64e6                	ld	s1,88(sp)
    8000419a:	6946                	ld	s2,80(sp)
    8000419c:	69a6                	ld	s3,72(sp)
    8000419e:	6a06                	ld	s4,64(sp)
    800041a0:	7ae2                	ld	s5,56(sp)
    800041a2:	7b42                	ld	s6,48(sp)
    800041a4:	7ba2                	ld	s7,40(sp)
    800041a6:	7c02                	ld	s8,32(sp)
    800041a8:	6ce2                	ld	s9,24(sp)
    800041aa:	6d42                	ld	s10,16(sp)
    800041ac:	6da2                	ld	s11,8(sp)
    800041ae:	6165                	addi	sp,sp,112
    800041b0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041b2:	89da                	mv	s3,s6
    800041b4:	bff1                	j	80004190 <readi+0xce>
    return 0;
    800041b6:	4501                	li	a0,0
}
    800041b8:	8082                	ret

00000000800041ba <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041ba:	457c                	lw	a5,76(a0)
    800041bc:	10d7e863          	bltu	a5,a3,800042cc <writei+0x112>
{
    800041c0:	7159                	addi	sp,sp,-112
    800041c2:	f486                	sd	ra,104(sp)
    800041c4:	f0a2                	sd	s0,96(sp)
    800041c6:	eca6                	sd	s1,88(sp)
    800041c8:	e8ca                	sd	s2,80(sp)
    800041ca:	e4ce                	sd	s3,72(sp)
    800041cc:	e0d2                	sd	s4,64(sp)
    800041ce:	fc56                	sd	s5,56(sp)
    800041d0:	f85a                	sd	s6,48(sp)
    800041d2:	f45e                	sd	s7,40(sp)
    800041d4:	f062                	sd	s8,32(sp)
    800041d6:	ec66                	sd	s9,24(sp)
    800041d8:	e86a                	sd	s10,16(sp)
    800041da:	e46e                	sd	s11,8(sp)
    800041dc:	1880                	addi	s0,sp,112
    800041de:	8b2a                	mv	s6,a0
    800041e0:	8c2e                	mv	s8,a1
    800041e2:	8ab2                	mv	s5,a2
    800041e4:	8936                	mv	s2,a3
    800041e6:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800041e8:	00e687bb          	addw	a5,a3,a4
    800041ec:	0ed7e263          	bltu	a5,a3,800042d0 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800041f0:	00043737          	lui	a4,0x43
    800041f4:	0ef76063          	bltu	a4,a5,800042d4 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041f8:	0c0b8863          	beqz	s7,800042c8 <writei+0x10e>
    800041fc:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800041fe:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004202:	5cfd                	li	s9,-1
    80004204:	a091                	j	80004248 <writei+0x8e>
    80004206:	02099d93          	slli	s11,s3,0x20
    8000420a:	020ddd93          	srli	s11,s11,0x20
    8000420e:	05848513          	addi	a0,s1,88
    80004212:	86ee                	mv	a3,s11
    80004214:	8656                	mv	a2,s5
    80004216:	85e2                	mv	a1,s8
    80004218:	953a                	add	a0,a0,a4
    8000421a:	fffff097          	auipc	ra,0xfffff
    8000421e:	97c080e7          	jalr	-1668(ra) # 80002b96 <either_copyin>
    80004222:	07950263          	beq	a0,s9,80004286 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004226:	8526                	mv	a0,s1
    80004228:	00000097          	auipc	ra,0x0
    8000422c:	790080e7          	jalr	1936(ra) # 800049b8 <log_write>
    brelse(bp);
    80004230:	8526                	mv	a0,s1
    80004232:	fffff097          	auipc	ra,0xfffff
    80004236:	50a080e7          	jalr	1290(ra) # 8000373c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000423a:	01498a3b          	addw	s4,s3,s4
    8000423e:	0129893b          	addw	s2,s3,s2
    80004242:	9aee                	add	s5,s5,s11
    80004244:	057a7663          	bgeu	s4,s7,80004290 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004248:	000b2483          	lw	s1,0(s6)
    8000424c:	00a9559b          	srliw	a1,s2,0xa
    80004250:	855a                	mv	a0,s6
    80004252:	fffff097          	auipc	ra,0xfffff
    80004256:	7ae080e7          	jalr	1966(ra) # 80003a00 <bmap>
    8000425a:	0005059b          	sext.w	a1,a0
    8000425e:	8526                	mv	a0,s1
    80004260:	fffff097          	auipc	ra,0xfffff
    80004264:	3ac080e7          	jalr	940(ra) # 8000360c <bread>
    80004268:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000426a:	3ff97713          	andi	a4,s2,1023
    8000426e:	40ed07bb          	subw	a5,s10,a4
    80004272:	414b86bb          	subw	a3,s7,s4
    80004276:	89be                	mv	s3,a5
    80004278:	2781                	sext.w	a5,a5
    8000427a:	0006861b          	sext.w	a2,a3
    8000427e:	f8f674e3          	bgeu	a2,a5,80004206 <writei+0x4c>
    80004282:	89b6                	mv	s3,a3
    80004284:	b749                	j	80004206 <writei+0x4c>
      brelse(bp);
    80004286:	8526                	mv	a0,s1
    80004288:	fffff097          	auipc	ra,0xfffff
    8000428c:	4b4080e7          	jalr	1204(ra) # 8000373c <brelse>
  }

  if(off > ip->size)
    80004290:	04cb2783          	lw	a5,76(s6)
    80004294:	0127f463          	bgeu	a5,s2,8000429c <writei+0xe2>
    ip->size = off;
    80004298:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000429c:	855a                	mv	a0,s6
    8000429e:	00000097          	auipc	ra,0x0
    800042a2:	aa6080e7          	jalr	-1370(ra) # 80003d44 <iupdate>

  return tot;
    800042a6:	000a051b          	sext.w	a0,s4
}
    800042aa:	70a6                	ld	ra,104(sp)
    800042ac:	7406                	ld	s0,96(sp)
    800042ae:	64e6                	ld	s1,88(sp)
    800042b0:	6946                	ld	s2,80(sp)
    800042b2:	69a6                	ld	s3,72(sp)
    800042b4:	6a06                	ld	s4,64(sp)
    800042b6:	7ae2                	ld	s5,56(sp)
    800042b8:	7b42                	ld	s6,48(sp)
    800042ba:	7ba2                	ld	s7,40(sp)
    800042bc:	7c02                	ld	s8,32(sp)
    800042be:	6ce2                	ld	s9,24(sp)
    800042c0:	6d42                	ld	s10,16(sp)
    800042c2:	6da2                	ld	s11,8(sp)
    800042c4:	6165                	addi	sp,sp,112
    800042c6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042c8:	8a5e                	mv	s4,s7
    800042ca:	bfc9                	j	8000429c <writei+0xe2>
    return -1;
    800042cc:	557d                	li	a0,-1
}
    800042ce:	8082                	ret
    return -1;
    800042d0:	557d                	li	a0,-1
    800042d2:	bfe1                	j	800042aa <writei+0xf0>
    return -1;
    800042d4:	557d                	li	a0,-1
    800042d6:	bfd1                	j	800042aa <writei+0xf0>

00000000800042d8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800042d8:	1141                	addi	sp,sp,-16
    800042da:	e406                	sd	ra,8(sp)
    800042dc:	e022                	sd	s0,0(sp)
    800042de:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800042e0:	4639                	li	a2,14
    800042e2:	ffffd097          	auipc	ra,0xffffd
    800042e6:	afa080e7          	jalr	-1286(ra) # 80000ddc <strncmp>
}
    800042ea:	60a2                	ld	ra,8(sp)
    800042ec:	6402                	ld	s0,0(sp)
    800042ee:	0141                	addi	sp,sp,16
    800042f0:	8082                	ret

00000000800042f2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800042f2:	7139                	addi	sp,sp,-64
    800042f4:	fc06                	sd	ra,56(sp)
    800042f6:	f822                	sd	s0,48(sp)
    800042f8:	f426                	sd	s1,40(sp)
    800042fa:	f04a                	sd	s2,32(sp)
    800042fc:	ec4e                	sd	s3,24(sp)
    800042fe:	e852                	sd	s4,16(sp)
    80004300:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004302:	04451703          	lh	a4,68(a0)
    80004306:	4785                	li	a5,1
    80004308:	00f71a63          	bne	a4,a5,8000431c <dirlookup+0x2a>
    8000430c:	892a                	mv	s2,a0
    8000430e:	89ae                	mv	s3,a1
    80004310:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004312:	457c                	lw	a5,76(a0)
    80004314:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004316:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004318:	e79d                	bnez	a5,80004346 <dirlookup+0x54>
    8000431a:	a8a5                	j	80004392 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000431c:	00004517          	auipc	a0,0x4
    80004320:	37c50513          	addi	a0,a0,892 # 80008698 <syscalls+0x1b8>
    80004324:	ffffc097          	auipc	ra,0xffffc
    80004328:	21a080e7          	jalr	538(ra) # 8000053e <panic>
      panic("dirlookup read");
    8000432c:	00004517          	auipc	a0,0x4
    80004330:	38450513          	addi	a0,a0,900 # 800086b0 <syscalls+0x1d0>
    80004334:	ffffc097          	auipc	ra,0xffffc
    80004338:	20a080e7          	jalr	522(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000433c:	24c1                	addiw	s1,s1,16
    8000433e:	04c92783          	lw	a5,76(s2)
    80004342:	04f4f763          	bgeu	s1,a5,80004390 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004346:	4741                	li	a4,16
    80004348:	86a6                	mv	a3,s1
    8000434a:	fc040613          	addi	a2,s0,-64
    8000434e:	4581                	li	a1,0
    80004350:	854a                	mv	a0,s2
    80004352:	00000097          	auipc	ra,0x0
    80004356:	d70080e7          	jalr	-656(ra) # 800040c2 <readi>
    8000435a:	47c1                	li	a5,16
    8000435c:	fcf518e3          	bne	a0,a5,8000432c <dirlookup+0x3a>
    if(de.inum == 0)
    80004360:	fc045783          	lhu	a5,-64(s0)
    80004364:	dfe1                	beqz	a5,8000433c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004366:	fc240593          	addi	a1,s0,-62
    8000436a:	854e                	mv	a0,s3
    8000436c:	00000097          	auipc	ra,0x0
    80004370:	f6c080e7          	jalr	-148(ra) # 800042d8 <namecmp>
    80004374:	f561                	bnez	a0,8000433c <dirlookup+0x4a>
      if(poff)
    80004376:	000a0463          	beqz	s4,8000437e <dirlookup+0x8c>
        *poff = off;
    8000437a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000437e:	fc045583          	lhu	a1,-64(s0)
    80004382:	00092503          	lw	a0,0(s2)
    80004386:	fffff097          	auipc	ra,0xfffff
    8000438a:	754080e7          	jalr	1876(ra) # 80003ada <iget>
    8000438e:	a011                	j	80004392 <dirlookup+0xa0>
  return 0;
    80004390:	4501                	li	a0,0
}
    80004392:	70e2                	ld	ra,56(sp)
    80004394:	7442                	ld	s0,48(sp)
    80004396:	74a2                	ld	s1,40(sp)
    80004398:	7902                	ld	s2,32(sp)
    8000439a:	69e2                	ld	s3,24(sp)
    8000439c:	6a42                	ld	s4,16(sp)
    8000439e:	6121                	addi	sp,sp,64
    800043a0:	8082                	ret

00000000800043a2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800043a2:	711d                	addi	sp,sp,-96
    800043a4:	ec86                	sd	ra,88(sp)
    800043a6:	e8a2                	sd	s0,80(sp)
    800043a8:	e4a6                	sd	s1,72(sp)
    800043aa:	e0ca                	sd	s2,64(sp)
    800043ac:	fc4e                	sd	s3,56(sp)
    800043ae:	f852                	sd	s4,48(sp)
    800043b0:	f456                	sd	s5,40(sp)
    800043b2:	f05a                	sd	s6,32(sp)
    800043b4:	ec5e                	sd	s7,24(sp)
    800043b6:	e862                	sd	s8,16(sp)
    800043b8:	e466                	sd	s9,8(sp)
    800043ba:	1080                	addi	s0,sp,96
    800043bc:	84aa                	mv	s1,a0
    800043be:	8b2e                	mv	s6,a1
    800043c0:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800043c2:	00054703          	lbu	a4,0(a0)
    800043c6:	02f00793          	li	a5,47
    800043ca:	02f70363          	beq	a4,a5,800043f0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800043ce:	ffffe097          	auipc	ra,0xffffe
    800043d2:	a0e080e7          	jalr	-1522(ra) # 80001ddc <myproc>
    800043d6:	17053503          	ld	a0,368(a0)
    800043da:	00000097          	auipc	ra,0x0
    800043de:	9f6080e7          	jalr	-1546(ra) # 80003dd0 <idup>
    800043e2:	89aa                	mv	s3,a0
  while(*path == '/')
    800043e4:	02f00913          	li	s2,47
  len = path - s;
    800043e8:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800043ea:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800043ec:	4c05                	li	s8,1
    800043ee:	a865                	j	800044a6 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800043f0:	4585                	li	a1,1
    800043f2:	4505                	li	a0,1
    800043f4:	fffff097          	auipc	ra,0xfffff
    800043f8:	6e6080e7          	jalr	1766(ra) # 80003ada <iget>
    800043fc:	89aa                	mv	s3,a0
    800043fe:	b7dd                	j	800043e4 <namex+0x42>
      iunlockput(ip);
    80004400:	854e                	mv	a0,s3
    80004402:	00000097          	auipc	ra,0x0
    80004406:	c6e080e7          	jalr	-914(ra) # 80004070 <iunlockput>
      return 0;
    8000440a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000440c:	854e                	mv	a0,s3
    8000440e:	60e6                	ld	ra,88(sp)
    80004410:	6446                	ld	s0,80(sp)
    80004412:	64a6                	ld	s1,72(sp)
    80004414:	6906                	ld	s2,64(sp)
    80004416:	79e2                	ld	s3,56(sp)
    80004418:	7a42                	ld	s4,48(sp)
    8000441a:	7aa2                	ld	s5,40(sp)
    8000441c:	7b02                	ld	s6,32(sp)
    8000441e:	6be2                	ld	s7,24(sp)
    80004420:	6c42                	ld	s8,16(sp)
    80004422:	6ca2                	ld	s9,8(sp)
    80004424:	6125                	addi	sp,sp,96
    80004426:	8082                	ret
      iunlock(ip);
    80004428:	854e                	mv	a0,s3
    8000442a:	00000097          	auipc	ra,0x0
    8000442e:	aa6080e7          	jalr	-1370(ra) # 80003ed0 <iunlock>
      return ip;
    80004432:	bfe9                	j	8000440c <namex+0x6a>
      iunlockput(ip);
    80004434:	854e                	mv	a0,s3
    80004436:	00000097          	auipc	ra,0x0
    8000443a:	c3a080e7          	jalr	-966(ra) # 80004070 <iunlockput>
      return 0;
    8000443e:	89d2                	mv	s3,s4
    80004440:	b7f1                	j	8000440c <namex+0x6a>
  len = path - s;
    80004442:	40b48633          	sub	a2,s1,a1
    80004446:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000444a:	094cd463          	bge	s9,s4,800044d2 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000444e:	4639                	li	a2,14
    80004450:	8556                	mv	a0,s5
    80004452:	ffffd097          	auipc	ra,0xffffd
    80004456:	912080e7          	jalr	-1774(ra) # 80000d64 <memmove>
  while(*path == '/')
    8000445a:	0004c783          	lbu	a5,0(s1)
    8000445e:	01279763          	bne	a5,s2,8000446c <namex+0xca>
    path++;
    80004462:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004464:	0004c783          	lbu	a5,0(s1)
    80004468:	ff278de3          	beq	a5,s2,80004462 <namex+0xc0>
    ilock(ip);
    8000446c:	854e                	mv	a0,s3
    8000446e:	00000097          	auipc	ra,0x0
    80004472:	9a0080e7          	jalr	-1632(ra) # 80003e0e <ilock>
    if(ip->type != T_DIR){
    80004476:	04499783          	lh	a5,68(s3)
    8000447a:	f98793e3          	bne	a5,s8,80004400 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000447e:	000b0563          	beqz	s6,80004488 <namex+0xe6>
    80004482:	0004c783          	lbu	a5,0(s1)
    80004486:	d3cd                	beqz	a5,80004428 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004488:	865e                	mv	a2,s7
    8000448a:	85d6                	mv	a1,s5
    8000448c:	854e                	mv	a0,s3
    8000448e:	00000097          	auipc	ra,0x0
    80004492:	e64080e7          	jalr	-412(ra) # 800042f2 <dirlookup>
    80004496:	8a2a                	mv	s4,a0
    80004498:	dd51                	beqz	a0,80004434 <namex+0x92>
    iunlockput(ip);
    8000449a:	854e                	mv	a0,s3
    8000449c:	00000097          	auipc	ra,0x0
    800044a0:	bd4080e7          	jalr	-1068(ra) # 80004070 <iunlockput>
    ip = next;
    800044a4:	89d2                	mv	s3,s4
  while(*path == '/')
    800044a6:	0004c783          	lbu	a5,0(s1)
    800044aa:	05279763          	bne	a5,s2,800044f8 <namex+0x156>
    path++;
    800044ae:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044b0:	0004c783          	lbu	a5,0(s1)
    800044b4:	ff278de3          	beq	a5,s2,800044ae <namex+0x10c>
  if(*path == 0)
    800044b8:	c79d                	beqz	a5,800044e6 <namex+0x144>
    path++;
    800044ba:	85a6                	mv	a1,s1
  len = path - s;
    800044bc:	8a5e                	mv	s4,s7
    800044be:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800044c0:	01278963          	beq	a5,s2,800044d2 <namex+0x130>
    800044c4:	dfbd                	beqz	a5,80004442 <namex+0xa0>
    path++;
    800044c6:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800044c8:	0004c783          	lbu	a5,0(s1)
    800044cc:	ff279ce3          	bne	a5,s2,800044c4 <namex+0x122>
    800044d0:	bf8d                	j	80004442 <namex+0xa0>
    memmove(name, s, len);
    800044d2:	2601                	sext.w	a2,a2
    800044d4:	8556                	mv	a0,s5
    800044d6:	ffffd097          	auipc	ra,0xffffd
    800044da:	88e080e7          	jalr	-1906(ra) # 80000d64 <memmove>
    name[len] = 0;
    800044de:	9a56                	add	s4,s4,s5
    800044e0:	000a0023          	sb	zero,0(s4)
    800044e4:	bf9d                	j	8000445a <namex+0xb8>
  if(nameiparent){
    800044e6:	f20b03e3          	beqz	s6,8000440c <namex+0x6a>
    iput(ip);
    800044ea:	854e                	mv	a0,s3
    800044ec:	00000097          	auipc	ra,0x0
    800044f0:	adc080e7          	jalr	-1316(ra) # 80003fc8 <iput>
    return 0;
    800044f4:	4981                	li	s3,0
    800044f6:	bf19                	j	8000440c <namex+0x6a>
  if(*path == 0)
    800044f8:	d7fd                	beqz	a5,800044e6 <namex+0x144>
  while(*path != '/' && *path != 0)
    800044fa:	0004c783          	lbu	a5,0(s1)
    800044fe:	85a6                	mv	a1,s1
    80004500:	b7d1                	j	800044c4 <namex+0x122>

0000000080004502 <dirlink>:
{
    80004502:	7139                	addi	sp,sp,-64
    80004504:	fc06                	sd	ra,56(sp)
    80004506:	f822                	sd	s0,48(sp)
    80004508:	f426                	sd	s1,40(sp)
    8000450a:	f04a                	sd	s2,32(sp)
    8000450c:	ec4e                	sd	s3,24(sp)
    8000450e:	e852                	sd	s4,16(sp)
    80004510:	0080                	addi	s0,sp,64
    80004512:	892a                	mv	s2,a0
    80004514:	8a2e                	mv	s4,a1
    80004516:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004518:	4601                	li	a2,0
    8000451a:	00000097          	auipc	ra,0x0
    8000451e:	dd8080e7          	jalr	-552(ra) # 800042f2 <dirlookup>
    80004522:	e93d                	bnez	a0,80004598 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004524:	04c92483          	lw	s1,76(s2)
    80004528:	c49d                	beqz	s1,80004556 <dirlink+0x54>
    8000452a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000452c:	4741                	li	a4,16
    8000452e:	86a6                	mv	a3,s1
    80004530:	fc040613          	addi	a2,s0,-64
    80004534:	4581                	li	a1,0
    80004536:	854a                	mv	a0,s2
    80004538:	00000097          	auipc	ra,0x0
    8000453c:	b8a080e7          	jalr	-1142(ra) # 800040c2 <readi>
    80004540:	47c1                	li	a5,16
    80004542:	06f51163          	bne	a0,a5,800045a4 <dirlink+0xa2>
    if(de.inum == 0)
    80004546:	fc045783          	lhu	a5,-64(s0)
    8000454a:	c791                	beqz	a5,80004556 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000454c:	24c1                	addiw	s1,s1,16
    8000454e:	04c92783          	lw	a5,76(s2)
    80004552:	fcf4ede3          	bltu	s1,a5,8000452c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004556:	4639                	li	a2,14
    80004558:	85d2                	mv	a1,s4
    8000455a:	fc240513          	addi	a0,s0,-62
    8000455e:	ffffd097          	auipc	ra,0xffffd
    80004562:	8ba080e7          	jalr	-1862(ra) # 80000e18 <strncpy>
  de.inum = inum;
    80004566:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000456a:	4741                	li	a4,16
    8000456c:	86a6                	mv	a3,s1
    8000456e:	fc040613          	addi	a2,s0,-64
    80004572:	4581                	li	a1,0
    80004574:	854a                	mv	a0,s2
    80004576:	00000097          	auipc	ra,0x0
    8000457a:	c44080e7          	jalr	-956(ra) # 800041ba <writei>
    8000457e:	872a                	mv	a4,a0
    80004580:	47c1                	li	a5,16
  return 0;
    80004582:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004584:	02f71863          	bne	a4,a5,800045b4 <dirlink+0xb2>
}
    80004588:	70e2                	ld	ra,56(sp)
    8000458a:	7442                	ld	s0,48(sp)
    8000458c:	74a2                	ld	s1,40(sp)
    8000458e:	7902                	ld	s2,32(sp)
    80004590:	69e2                	ld	s3,24(sp)
    80004592:	6a42                	ld	s4,16(sp)
    80004594:	6121                	addi	sp,sp,64
    80004596:	8082                	ret
    iput(ip);
    80004598:	00000097          	auipc	ra,0x0
    8000459c:	a30080e7          	jalr	-1488(ra) # 80003fc8 <iput>
    return -1;
    800045a0:	557d                	li	a0,-1
    800045a2:	b7dd                	j	80004588 <dirlink+0x86>
      panic("dirlink read");
    800045a4:	00004517          	auipc	a0,0x4
    800045a8:	11c50513          	addi	a0,a0,284 # 800086c0 <syscalls+0x1e0>
    800045ac:	ffffc097          	auipc	ra,0xffffc
    800045b0:	f92080e7          	jalr	-110(ra) # 8000053e <panic>
    panic("dirlink");
    800045b4:	00004517          	auipc	a0,0x4
    800045b8:	21c50513          	addi	a0,a0,540 # 800087d0 <syscalls+0x2f0>
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	f82080e7          	jalr	-126(ra) # 8000053e <panic>

00000000800045c4 <namei>:

struct inode*
namei(char *path)
{
    800045c4:	1101                	addi	sp,sp,-32
    800045c6:	ec06                	sd	ra,24(sp)
    800045c8:	e822                	sd	s0,16(sp)
    800045ca:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800045cc:	fe040613          	addi	a2,s0,-32
    800045d0:	4581                	li	a1,0
    800045d2:	00000097          	auipc	ra,0x0
    800045d6:	dd0080e7          	jalr	-560(ra) # 800043a2 <namex>
}
    800045da:	60e2                	ld	ra,24(sp)
    800045dc:	6442                	ld	s0,16(sp)
    800045de:	6105                	addi	sp,sp,32
    800045e0:	8082                	ret

00000000800045e2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800045e2:	1141                	addi	sp,sp,-16
    800045e4:	e406                	sd	ra,8(sp)
    800045e6:	e022                	sd	s0,0(sp)
    800045e8:	0800                	addi	s0,sp,16
    800045ea:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800045ec:	4585                	li	a1,1
    800045ee:	00000097          	auipc	ra,0x0
    800045f2:	db4080e7          	jalr	-588(ra) # 800043a2 <namex>
}
    800045f6:	60a2                	ld	ra,8(sp)
    800045f8:	6402                	ld	s0,0(sp)
    800045fa:	0141                	addi	sp,sp,16
    800045fc:	8082                	ret

00000000800045fe <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800045fe:	1101                	addi	sp,sp,-32
    80004600:	ec06                	sd	ra,24(sp)
    80004602:	e822                	sd	s0,16(sp)
    80004604:	e426                	sd	s1,8(sp)
    80004606:	e04a                	sd	s2,0(sp)
    80004608:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000460a:	0001d917          	auipc	s2,0x1d
    8000460e:	60e90913          	addi	s2,s2,1550 # 80021c18 <log>
    80004612:	01892583          	lw	a1,24(s2)
    80004616:	02892503          	lw	a0,40(s2)
    8000461a:	fffff097          	auipc	ra,0xfffff
    8000461e:	ff2080e7          	jalr	-14(ra) # 8000360c <bread>
    80004622:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004624:	02c92683          	lw	a3,44(s2)
    80004628:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000462a:	02d05763          	blez	a3,80004658 <write_head+0x5a>
    8000462e:	0001d797          	auipc	a5,0x1d
    80004632:	61a78793          	addi	a5,a5,1562 # 80021c48 <log+0x30>
    80004636:	05c50713          	addi	a4,a0,92
    8000463a:	36fd                	addiw	a3,a3,-1
    8000463c:	1682                	slli	a3,a3,0x20
    8000463e:	9281                	srli	a3,a3,0x20
    80004640:	068a                	slli	a3,a3,0x2
    80004642:	0001d617          	auipc	a2,0x1d
    80004646:	60a60613          	addi	a2,a2,1546 # 80021c4c <log+0x34>
    8000464a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000464c:	4390                	lw	a2,0(a5)
    8000464e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004650:	0791                	addi	a5,a5,4
    80004652:	0711                	addi	a4,a4,4
    80004654:	fed79ce3          	bne	a5,a3,8000464c <write_head+0x4e>
  }
  bwrite(buf);
    80004658:	8526                	mv	a0,s1
    8000465a:	fffff097          	auipc	ra,0xfffff
    8000465e:	0a4080e7          	jalr	164(ra) # 800036fe <bwrite>
  brelse(buf);
    80004662:	8526                	mv	a0,s1
    80004664:	fffff097          	auipc	ra,0xfffff
    80004668:	0d8080e7          	jalr	216(ra) # 8000373c <brelse>
}
    8000466c:	60e2                	ld	ra,24(sp)
    8000466e:	6442                	ld	s0,16(sp)
    80004670:	64a2                	ld	s1,8(sp)
    80004672:	6902                	ld	s2,0(sp)
    80004674:	6105                	addi	sp,sp,32
    80004676:	8082                	ret

0000000080004678 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004678:	0001d797          	auipc	a5,0x1d
    8000467c:	5cc7a783          	lw	a5,1484(a5) # 80021c44 <log+0x2c>
    80004680:	0af05d63          	blez	a5,8000473a <install_trans+0xc2>
{
    80004684:	7139                	addi	sp,sp,-64
    80004686:	fc06                	sd	ra,56(sp)
    80004688:	f822                	sd	s0,48(sp)
    8000468a:	f426                	sd	s1,40(sp)
    8000468c:	f04a                	sd	s2,32(sp)
    8000468e:	ec4e                	sd	s3,24(sp)
    80004690:	e852                	sd	s4,16(sp)
    80004692:	e456                	sd	s5,8(sp)
    80004694:	e05a                	sd	s6,0(sp)
    80004696:	0080                	addi	s0,sp,64
    80004698:	8b2a                	mv	s6,a0
    8000469a:	0001da97          	auipc	s5,0x1d
    8000469e:	5aea8a93          	addi	s5,s5,1454 # 80021c48 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046a2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046a4:	0001d997          	auipc	s3,0x1d
    800046a8:	57498993          	addi	s3,s3,1396 # 80021c18 <log>
    800046ac:	a035                	j	800046d8 <install_trans+0x60>
      bunpin(dbuf);
    800046ae:	8526                	mv	a0,s1
    800046b0:	fffff097          	auipc	ra,0xfffff
    800046b4:	166080e7          	jalr	358(ra) # 80003816 <bunpin>
    brelse(lbuf);
    800046b8:	854a                	mv	a0,s2
    800046ba:	fffff097          	auipc	ra,0xfffff
    800046be:	082080e7          	jalr	130(ra) # 8000373c <brelse>
    brelse(dbuf);
    800046c2:	8526                	mv	a0,s1
    800046c4:	fffff097          	auipc	ra,0xfffff
    800046c8:	078080e7          	jalr	120(ra) # 8000373c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046cc:	2a05                	addiw	s4,s4,1
    800046ce:	0a91                	addi	s5,s5,4
    800046d0:	02c9a783          	lw	a5,44(s3)
    800046d4:	04fa5963          	bge	s4,a5,80004726 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046d8:	0189a583          	lw	a1,24(s3)
    800046dc:	014585bb          	addw	a1,a1,s4
    800046e0:	2585                	addiw	a1,a1,1
    800046e2:	0289a503          	lw	a0,40(s3)
    800046e6:	fffff097          	auipc	ra,0xfffff
    800046ea:	f26080e7          	jalr	-218(ra) # 8000360c <bread>
    800046ee:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800046f0:	000aa583          	lw	a1,0(s5)
    800046f4:	0289a503          	lw	a0,40(s3)
    800046f8:	fffff097          	auipc	ra,0xfffff
    800046fc:	f14080e7          	jalr	-236(ra) # 8000360c <bread>
    80004700:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004702:	40000613          	li	a2,1024
    80004706:	05890593          	addi	a1,s2,88
    8000470a:	05850513          	addi	a0,a0,88
    8000470e:	ffffc097          	auipc	ra,0xffffc
    80004712:	656080e7          	jalr	1622(ra) # 80000d64 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004716:	8526                	mv	a0,s1
    80004718:	fffff097          	auipc	ra,0xfffff
    8000471c:	fe6080e7          	jalr	-26(ra) # 800036fe <bwrite>
    if(recovering == 0)
    80004720:	f80b1ce3          	bnez	s6,800046b8 <install_trans+0x40>
    80004724:	b769                	j	800046ae <install_trans+0x36>
}
    80004726:	70e2                	ld	ra,56(sp)
    80004728:	7442                	ld	s0,48(sp)
    8000472a:	74a2                	ld	s1,40(sp)
    8000472c:	7902                	ld	s2,32(sp)
    8000472e:	69e2                	ld	s3,24(sp)
    80004730:	6a42                	ld	s4,16(sp)
    80004732:	6aa2                	ld	s5,8(sp)
    80004734:	6b02                	ld	s6,0(sp)
    80004736:	6121                	addi	sp,sp,64
    80004738:	8082                	ret
    8000473a:	8082                	ret

000000008000473c <initlog>:
{
    8000473c:	7179                	addi	sp,sp,-48
    8000473e:	f406                	sd	ra,40(sp)
    80004740:	f022                	sd	s0,32(sp)
    80004742:	ec26                	sd	s1,24(sp)
    80004744:	e84a                	sd	s2,16(sp)
    80004746:	e44e                	sd	s3,8(sp)
    80004748:	1800                	addi	s0,sp,48
    8000474a:	892a                	mv	s2,a0
    8000474c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000474e:	0001d497          	auipc	s1,0x1d
    80004752:	4ca48493          	addi	s1,s1,1226 # 80021c18 <log>
    80004756:	00004597          	auipc	a1,0x4
    8000475a:	f7a58593          	addi	a1,a1,-134 # 800086d0 <syscalls+0x1f0>
    8000475e:	8526                	mv	a0,s1
    80004760:	ffffc097          	auipc	ra,0xffffc
    80004764:	3f4080e7          	jalr	1012(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004768:	0149a583          	lw	a1,20(s3)
    8000476c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000476e:	0109a783          	lw	a5,16(s3)
    80004772:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004774:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004778:	854a                	mv	a0,s2
    8000477a:	fffff097          	auipc	ra,0xfffff
    8000477e:	e92080e7          	jalr	-366(ra) # 8000360c <bread>
  log.lh.n = lh->n;
    80004782:	4d3c                	lw	a5,88(a0)
    80004784:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004786:	02f05563          	blez	a5,800047b0 <initlog+0x74>
    8000478a:	05c50713          	addi	a4,a0,92
    8000478e:	0001d697          	auipc	a3,0x1d
    80004792:	4ba68693          	addi	a3,a3,1210 # 80021c48 <log+0x30>
    80004796:	37fd                	addiw	a5,a5,-1
    80004798:	1782                	slli	a5,a5,0x20
    8000479a:	9381                	srli	a5,a5,0x20
    8000479c:	078a                	slli	a5,a5,0x2
    8000479e:	06050613          	addi	a2,a0,96
    800047a2:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800047a4:	4310                	lw	a2,0(a4)
    800047a6:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800047a8:	0711                	addi	a4,a4,4
    800047aa:	0691                	addi	a3,a3,4
    800047ac:	fef71ce3          	bne	a4,a5,800047a4 <initlog+0x68>
  brelse(buf);
    800047b0:	fffff097          	auipc	ra,0xfffff
    800047b4:	f8c080e7          	jalr	-116(ra) # 8000373c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800047b8:	4505                	li	a0,1
    800047ba:	00000097          	auipc	ra,0x0
    800047be:	ebe080e7          	jalr	-322(ra) # 80004678 <install_trans>
  log.lh.n = 0;
    800047c2:	0001d797          	auipc	a5,0x1d
    800047c6:	4807a123          	sw	zero,1154(a5) # 80021c44 <log+0x2c>
  write_head(); // clear the log
    800047ca:	00000097          	auipc	ra,0x0
    800047ce:	e34080e7          	jalr	-460(ra) # 800045fe <write_head>
}
    800047d2:	70a2                	ld	ra,40(sp)
    800047d4:	7402                	ld	s0,32(sp)
    800047d6:	64e2                	ld	s1,24(sp)
    800047d8:	6942                	ld	s2,16(sp)
    800047da:	69a2                	ld	s3,8(sp)
    800047dc:	6145                	addi	sp,sp,48
    800047de:	8082                	ret

00000000800047e0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800047e0:	1101                	addi	sp,sp,-32
    800047e2:	ec06                	sd	ra,24(sp)
    800047e4:	e822                	sd	s0,16(sp)
    800047e6:	e426                	sd	s1,8(sp)
    800047e8:	e04a                	sd	s2,0(sp)
    800047ea:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800047ec:	0001d517          	auipc	a0,0x1d
    800047f0:	42c50513          	addi	a0,a0,1068 # 80021c18 <log>
    800047f4:	ffffc097          	auipc	ra,0xffffc
    800047f8:	3f0080e7          	jalr	1008(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800047fc:	0001d497          	auipc	s1,0x1d
    80004800:	41c48493          	addi	s1,s1,1052 # 80021c18 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004804:	4979                	li	s2,30
    80004806:	a039                	j	80004814 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004808:	85a6                	mv	a1,s1
    8000480a:	8526                	mv	a0,s1
    8000480c:	ffffe097          	auipc	ra,0xffffe
    80004810:	e7e080e7          	jalr	-386(ra) # 8000268a <sleep>
    if(log.committing){
    80004814:	50dc                	lw	a5,36(s1)
    80004816:	fbed                	bnez	a5,80004808 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004818:	509c                	lw	a5,32(s1)
    8000481a:	0017871b          	addiw	a4,a5,1
    8000481e:	0007069b          	sext.w	a3,a4
    80004822:	0027179b          	slliw	a5,a4,0x2
    80004826:	9fb9                	addw	a5,a5,a4
    80004828:	0017979b          	slliw	a5,a5,0x1
    8000482c:	54d8                	lw	a4,44(s1)
    8000482e:	9fb9                	addw	a5,a5,a4
    80004830:	00f95963          	bge	s2,a5,80004842 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004834:	85a6                	mv	a1,s1
    80004836:	8526                	mv	a0,s1
    80004838:	ffffe097          	auipc	ra,0xffffe
    8000483c:	e52080e7          	jalr	-430(ra) # 8000268a <sleep>
    80004840:	bfd1                	j	80004814 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004842:	0001d517          	auipc	a0,0x1d
    80004846:	3d650513          	addi	a0,a0,982 # 80021c18 <log>
    8000484a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000484c:	ffffc097          	auipc	ra,0xffffc
    80004850:	45e080e7          	jalr	1118(ra) # 80000caa <release>
      break;
    }
  }
}
    80004854:	60e2                	ld	ra,24(sp)
    80004856:	6442                	ld	s0,16(sp)
    80004858:	64a2                	ld	s1,8(sp)
    8000485a:	6902                	ld	s2,0(sp)
    8000485c:	6105                	addi	sp,sp,32
    8000485e:	8082                	ret

0000000080004860 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004860:	7139                	addi	sp,sp,-64
    80004862:	fc06                	sd	ra,56(sp)
    80004864:	f822                	sd	s0,48(sp)
    80004866:	f426                	sd	s1,40(sp)
    80004868:	f04a                	sd	s2,32(sp)
    8000486a:	ec4e                	sd	s3,24(sp)
    8000486c:	e852                	sd	s4,16(sp)
    8000486e:	e456                	sd	s5,8(sp)
    80004870:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004872:	0001d497          	auipc	s1,0x1d
    80004876:	3a648493          	addi	s1,s1,934 # 80021c18 <log>
    8000487a:	8526                	mv	a0,s1
    8000487c:	ffffc097          	auipc	ra,0xffffc
    80004880:	368080e7          	jalr	872(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004884:	509c                	lw	a5,32(s1)
    80004886:	37fd                	addiw	a5,a5,-1
    80004888:	0007891b          	sext.w	s2,a5
    8000488c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000488e:	50dc                	lw	a5,36(s1)
    80004890:	efb9                	bnez	a5,800048ee <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004892:	06091663          	bnez	s2,800048fe <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004896:	0001d497          	auipc	s1,0x1d
    8000489a:	38248493          	addi	s1,s1,898 # 80021c18 <log>
    8000489e:	4785                	li	a5,1
    800048a0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800048a2:	8526                	mv	a0,s1
    800048a4:	ffffc097          	auipc	ra,0xffffc
    800048a8:	406080e7          	jalr	1030(ra) # 80000caa <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800048ac:	54dc                	lw	a5,44(s1)
    800048ae:	06f04763          	bgtz	a5,8000491c <end_op+0xbc>
    acquire(&log.lock);
    800048b2:	0001d497          	auipc	s1,0x1d
    800048b6:	36648493          	addi	s1,s1,870 # 80021c18 <log>
    800048ba:	8526                	mv	a0,s1
    800048bc:	ffffc097          	auipc	ra,0xffffc
    800048c0:	328080e7          	jalr	808(ra) # 80000be4 <acquire>
    log.committing = 0;
    800048c4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800048c8:	8526                	mv	a0,s1
    800048ca:	ffffe097          	auipc	ra,0xffffe
    800048ce:	f68080e7          	jalr	-152(ra) # 80002832 <wakeup>
    release(&log.lock);
    800048d2:	8526                	mv	a0,s1
    800048d4:	ffffc097          	auipc	ra,0xffffc
    800048d8:	3d6080e7          	jalr	982(ra) # 80000caa <release>
}
    800048dc:	70e2                	ld	ra,56(sp)
    800048de:	7442                	ld	s0,48(sp)
    800048e0:	74a2                	ld	s1,40(sp)
    800048e2:	7902                	ld	s2,32(sp)
    800048e4:	69e2                	ld	s3,24(sp)
    800048e6:	6a42                	ld	s4,16(sp)
    800048e8:	6aa2                	ld	s5,8(sp)
    800048ea:	6121                	addi	sp,sp,64
    800048ec:	8082                	ret
    panic("log.committing");
    800048ee:	00004517          	auipc	a0,0x4
    800048f2:	dea50513          	addi	a0,a0,-534 # 800086d8 <syscalls+0x1f8>
    800048f6:	ffffc097          	auipc	ra,0xffffc
    800048fa:	c48080e7          	jalr	-952(ra) # 8000053e <panic>
    wakeup(&log);
    800048fe:	0001d497          	auipc	s1,0x1d
    80004902:	31a48493          	addi	s1,s1,794 # 80021c18 <log>
    80004906:	8526                	mv	a0,s1
    80004908:	ffffe097          	auipc	ra,0xffffe
    8000490c:	f2a080e7          	jalr	-214(ra) # 80002832 <wakeup>
  release(&log.lock);
    80004910:	8526                	mv	a0,s1
    80004912:	ffffc097          	auipc	ra,0xffffc
    80004916:	398080e7          	jalr	920(ra) # 80000caa <release>
  if(do_commit){
    8000491a:	b7c9                	j	800048dc <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000491c:	0001da97          	auipc	s5,0x1d
    80004920:	32ca8a93          	addi	s5,s5,812 # 80021c48 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004924:	0001da17          	auipc	s4,0x1d
    80004928:	2f4a0a13          	addi	s4,s4,756 # 80021c18 <log>
    8000492c:	018a2583          	lw	a1,24(s4)
    80004930:	012585bb          	addw	a1,a1,s2
    80004934:	2585                	addiw	a1,a1,1
    80004936:	028a2503          	lw	a0,40(s4)
    8000493a:	fffff097          	auipc	ra,0xfffff
    8000493e:	cd2080e7          	jalr	-814(ra) # 8000360c <bread>
    80004942:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004944:	000aa583          	lw	a1,0(s5)
    80004948:	028a2503          	lw	a0,40(s4)
    8000494c:	fffff097          	auipc	ra,0xfffff
    80004950:	cc0080e7          	jalr	-832(ra) # 8000360c <bread>
    80004954:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004956:	40000613          	li	a2,1024
    8000495a:	05850593          	addi	a1,a0,88
    8000495e:	05848513          	addi	a0,s1,88
    80004962:	ffffc097          	auipc	ra,0xffffc
    80004966:	402080e7          	jalr	1026(ra) # 80000d64 <memmove>
    bwrite(to);  // write the log
    8000496a:	8526                	mv	a0,s1
    8000496c:	fffff097          	auipc	ra,0xfffff
    80004970:	d92080e7          	jalr	-622(ra) # 800036fe <bwrite>
    brelse(from);
    80004974:	854e                	mv	a0,s3
    80004976:	fffff097          	auipc	ra,0xfffff
    8000497a:	dc6080e7          	jalr	-570(ra) # 8000373c <brelse>
    brelse(to);
    8000497e:	8526                	mv	a0,s1
    80004980:	fffff097          	auipc	ra,0xfffff
    80004984:	dbc080e7          	jalr	-580(ra) # 8000373c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004988:	2905                	addiw	s2,s2,1
    8000498a:	0a91                	addi	s5,s5,4
    8000498c:	02ca2783          	lw	a5,44(s4)
    80004990:	f8f94ee3          	blt	s2,a5,8000492c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004994:	00000097          	auipc	ra,0x0
    80004998:	c6a080e7          	jalr	-918(ra) # 800045fe <write_head>
    install_trans(0); // Now install writes to home locations
    8000499c:	4501                	li	a0,0
    8000499e:	00000097          	auipc	ra,0x0
    800049a2:	cda080e7          	jalr	-806(ra) # 80004678 <install_trans>
    log.lh.n = 0;
    800049a6:	0001d797          	auipc	a5,0x1d
    800049aa:	2807af23          	sw	zero,670(a5) # 80021c44 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800049ae:	00000097          	auipc	ra,0x0
    800049b2:	c50080e7          	jalr	-944(ra) # 800045fe <write_head>
    800049b6:	bdf5                	j	800048b2 <end_op+0x52>

00000000800049b8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800049b8:	1101                	addi	sp,sp,-32
    800049ba:	ec06                	sd	ra,24(sp)
    800049bc:	e822                	sd	s0,16(sp)
    800049be:	e426                	sd	s1,8(sp)
    800049c0:	e04a                	sd	s2,0(sp)
    800049c2:	1000                	addi	s0,sp,32
    800049c4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800049c6:	0001d917          	auipc	s2,0x1d
    800049ca:	25290913          	addi	s2,s2,594 # 80021c18 <log>
    800049ce:	854a                	mv	a0,s2
    800049d0:	ffffc097          	auipc	ra,0xffffc
    800049d4:	214080e7          	jalr	532(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800049d8:	02c92603          	lw	a2,44(s2)
    800049dc:	47f5                	li	a5,29
    800049de:	06c7c563          	blt	a5,a2,80004a48 <log_write+0x90>
    800049e2:	0001d797          	auipc	a5,0x1d
    800049e6:	2527a783          	lw	a5,594(a5) # 80021c34 <log+0x1c>
    800049ea:	37fd                	addiw	a5,a5,-1
    800049ec:	04f65e63          	bge	a2,a5,80004a48 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800049f0:	0001d797          	auipc	a5,0x1d
    800049f4:	2487a783          	lw	a5,584(a5) # 80021c38 <log+0x20>
    800049f8:	06f05063          	blez	a5,80004a58 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800049fc:	4781                	li	a5,0
    800049fe:	06c05563          	blez	a2,80004a68 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a02:	44cc                	lw	a1,12(s1)
    80004a04:	0001d717          	auipc	a4,0x1d
    80004a08:	24470713          	addi	a4,a4,580 # 80021c48 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004a0c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a0e:	4314                	lw	a3,0(a4)
    80004a10:	04b68c63          	beq	a3,a1,80004a68 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004a14:	2785                	addiw	a5,a5,1
    80004a16:	0711                	addi	a4,a4,4
    80004a18:	fef61be3          	bne	a2,a5,80004a0e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004a1c:	0621                	addi	a2,a2,8
    80004a1e:	060a                	slli	a2,a2,0x2
    80004a20:	0001d797          	auipc	a5,0x1d
    80004a24:	1f878793          	addi	a5,a5,504 # 80021c18 <log>
    80004a28:	963e                	add	a2,a2,a5
    80004a2a:	44dc                	lw	a5,12(s1)
    80004a2c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004a2e:	8526                	mv	a0,s1
    80004a30:	fffff097          	auipc	ra,0xfffff
    80004a34:	daa080e7          	jalr	-598(ra) # 800037da <bpin>
    log.lh.n++;
    80004a38:	0001d717          	auipc	a4,0x1d
    80004a3c:	1e070713          	addi	a4,a4,480 # 80021c18 <log>
    80004a40:	575c                	lw	a5,44(a4)
    80004a42:	2785                	addiw	a5,a5,1
    80004a44:	d75c                	sw	a5,44(a4)
    80004a46:	a835                	j	80004a82 <log_write+0xca>
    panic("too big a transaction");
    80004a48:	00004517          	auipc	a0,0x4
    80004a4c:	ca050513          	addi	a0,a0,-864 # 800086e8 <syscalls+0x208>
    80004a50:	ffffc097          	auipc	ra,0xffffc
    80004a54:	aee080e7          	jalr	-1298(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004a58:	00004517          	auipc	a0,0x4
    80004a5c:	ca850513          	addi	a0,a0,-856 # 80008700 <syscalls+0x220>
    80004a60:	ffffc097          	auipc	ra,0xffffc
    80004a64:	ade080e7          	jalr	-1314(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004a68:	00878713          	addi	a4,a5,8
    80004a6c:	00271693          	slli	a3,a4,0x2
    80004a70:	0001d717          	auipc	a4,0x1d
    80004a74:	1a870713          	addi	a4,a4,424 # 80021c18 <log>
    80004a78:	9736                	add	a4,a4,a3
    80004a7a:	44d4                	lw	a3,12(s1)
    80004a7c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004a7e:	faf608e3          	beq	a2,a5,80004a2e <log_write+0x76>
  }
  release(&log.lock);
    80004a82:	0001d517          	auipc	a0,0x1d
    80004a86:	19650513          	addi	a0,a0,406 # 80021c18 <log>
    80004a8a:	ffffc097          	auipc	ra,0xffffc
    80004a8e:	220080e7          	jalr	544(ra) # 80000caa <release>
}
    80004a92:	60e2                	ld	ra,24(sp)
    80004a94:	6442                	ld	s0,16(sp)
    80004a96:	64a2                	ld	s1,8(sp)
    80004a98:	6902                	ld	s2,0(sp)
    80004a9a:	6105                	addi	sp,sp,32
    80004a9c:	8082                	ret

0000000080004a9e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004a9e:	1101                	addi	sp,sp,-32
    80004aa0:	ec06                	sd	ra,24(sp)
    80004aa2:	e822                	sd	s0,16(sp)
    80004aa4:	e426                	sd	s1,8(sp)
    80004aa6:	e04a                	sd	s2,0(sp)
    80004aa8:	1000                	addi	s0,sp,32
    80004aaa:	84aa                	mv	s1,a0
    80004aac:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004aae:	00004597          	auipc	a1,0x4
    80004ab2:	c7258593          	addi	a1,a1,-910 # 80008720 <syscalls+0x240>
    80004ab6:	0521                	addi	a0,a0,8
    80004ab8:	ffffc097          	auipc	ra,0xffffc
    80004abc:	09c080e7          	jalr	156(ra) # 80000b54 <initlock>
  lk->name = name;
    80004ac0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004ac4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004ac8:	0204a423          	sw	zero,40(s1)
}
    80004acc:	60e2                	ld	ra,24(sp)
    80004ace:	6442                	ld	s0,16(sp)
    80004ad0:	64a2                	ld	s1,8(sp)
    80004ad2:	6902                	ld	s2,0(sp)
    80004ad4:	6105                	addi	sp,sp,32
    80004ad6:	8082                	ret

0000000080004ad8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004ad8:	1101                	addi	sp,sp,-32
    80004ada:	ec06                	sd	ra,24(sp)
    80004adc:	e822                	sd	s0,16(sp)
    80004ade:	e426                	sd	s1,8(sp)
    80004ae0:	e04a                	sd	s2,0(sp)
    80004ae2:	1000                	addi	s0,sp,32
    80004ae4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ae6:	00850913          	addi	s2,a0,8
    80004aea:	854a                	mv	a0,s2
    80004aec:	ffffc097          	auipc	ra,0xffffc
    80004af0:	0f8080e7          	jalr	248(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004af4:	409c                	lw	a5,0(s1)
    80004af6:	cb89                	beqz	a5,80004b08 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004af8:	85ca                	mv	a1,s2
    80004afa:	8526                	mv	a0,s1
    80004afc:	ffffe097          	auipc	ra,0xffffe
    80004b00:	b8e080e7          	jalr	-1138(ra) # 8000268a <sleep>
  while (lk->locked) {
    80004b04:	409c                	lw	a5,0(s1)
    80004b06:	fbed                	bnez	a5,80004af8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004b08:	4785                	li	a5,1
    80004b0a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004b0c:	ffffd097          	auipc	ra,0xffffd
    80004b10:	2d0080e7          	jalr	720(ra) # 80001ddc <myproc>
    80004b14:	591c                	lw	a5,48(a0)
    80004b16:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004b18:	854a                	mv	a0,s2
    80004b1a:	ffffc097          	auipc	ra,0xffffc
    80004b1e:	190080e7          	jalr	400(ra) # 80000caa <release>
}
    80004b22:	60e2                	ld	ra,24(sp)
    80004b24:	6442                	ld	s0,16(sp)
    80004b26:	64a2                	ld	s1,8(sp)
    80004b28:	6902                	ld	s2,0(sp)
    80004b2a:	6105                	addi	sp,sp,32
    80004b2c:	8082                	ret

0000000080004b2e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004b2e:	1101                	addi	sp,sp,-32
    80004b30:	ec06                	sd	ra,24(sp)
    80004b32:	e822                	sd	s0,16(sp)
    80004b34:	e426                	sd	s1,8(sp)
    80004b36:	e04a                	sd	s2,0(sp)
    80004b38:	1000                	addi	s0,sp,32
    80004b3a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b3c:	00850913          	addi	s2,a0,8
    80004b40:	854a                	mv	a0,s2
    80004b42:	ffffc097          	auipc	ra,0xffffc
    80004b46:	0a2080e7          	jalr	162(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004b4a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b4e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b52:	8526                	mv	a0,s1
    80004b54:	ffffe097          	auipc	ra,0xffffe
    80004b58:	cde080e7          	jalr	-802(ra) # 80002832 <wakeup>
  release(&lk->lk);
    80004b5c:	854a                	mv	a0,s2
    80004b5e:	ffffc097          	auipc	ra,0xffffc
    80004b62:	14c080e7          	jalr	332(ra) # 80000caa <release>
}
    80004b66:	60e2                	ld	ra,24(sp)
    80004b68:	6442                	ld	s0,16(sp)
    80004b6a:	64a2                	ld	s1,8(sp)
    80004b6c:	6902                	ld	s2,0(sp)
    80004b6e:	6105                	addi	sp,sp,32
    80004b70:	8082                	ret

0000000080004b72 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b72:	7179                	addi	sp,sp,-48
    80004b74:	f406                	sd	ra,40(sp)
    80004b76:	f022                	sd	s0,32(sp)
    80004b78:	ec26                	sd	s1,24(sp)
    80004b7a:	e84a                	sd	s2,16(sp)
    80004b7c:	e44e                	sd	s3,8(sp)
    80004b7e:	1800                	addi	s0,sp,48
    80004b80:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004b82:	00850913          	addi	s2,a0,8
    80004b86:	854a                	mv	a0,s2
    80004b88:	ffffc097          	auipc	ra,0xffffc
    80004b8c:	05c080e7          	jalr	92(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b90:	409c                	lw	a5,0(s1)
    80004b92:	ef99                	bnez	a5,80004bb0 <holdingsleep+0x3e>
    80004b94:	4481                	li	s1,0
  release(&lk->lk);
    80004b96:	854a                	mv	a0,s2
    80004b98:	ffffc097          	auipc	ra,0xffffc
    80004b9c:	112080e7          	jalr	274(ra) # 80000caa <release>
  return r;
}
    80004ba0:	8526                	mv	a0,s1
    80004ba2:	70a2                	ld	ra,40(sp)
    80004ba4:	7402                	ld	s0,32(sp)
    80004ba6:	64e2                	ld	s1,24(sp)
    80004ba8:	6942                	ld	s2,16(sp)
    80004baa:	69a2                	ld	s3,8(sp)
    80004bac:	6145                	addi	sp,sp,48
    80004bae:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004bb0:	0284a983          	lw	s3,40(s1)
    80004bb4:	ffffd097          	auipc	ra,0xffffd
    80004bb8:	228080e7          	jalr	552(ra) # 80001ddc <myproc>
    80004bbc:	5904                	lw	s1,48(a0)
    80004bbe:	413484b3          	sub	s1,s1,s3
    80004bc2:	0014b493          	seqz	s1,s1
    80004bc6:	bfc1                	j	80004b96 <holdingsleep+0x24>

0000000080004bc8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004bc8:	1141                	addi	sp,sp,-16
    80004bca:	e406                	sd	ra,8(sp)
    80004bcc:	e022                	sd	s0,0(sp)
    80004bce:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004bd0:	00004597          	auipc	a1,0x4
    80004bd4:	b6058593          	addi	a1,a1,-1184 # 80008730 <syscalls+0x250>
    80004bd8:	0001d517          	auipc	a0,0x1d
    80004bdc:	18850513          	addi	a0,a0,392 # 80021d60 <ftable>
    80004be0:	ffffc097          	auipc	ra,0xffffc
    80004be4:	f74080e7          	jalr	-140(ra) # 80000b54 <initlock>
}
    80004be8:	60a2                	ld	ra,8(sp)
    80004bea:	6402                	ld	s0,0(sp)
    80004bec:	0141                	addi	sp,sp,16
    80004bee:	8082                	ret

0000000080004bf0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004bf0:	1101                	addi	sp,sp,-32
    80004bf2:	ec06                	sd	ra,24(sp)
    80004bf4:	e822                	sd	s0,16(sp)
    80004bf6:	e426                	sd	s1,8(sp)
    80004bf8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004bfa:	0001d517          	auipc	a0,0x1d
    80004bfe:	16650513          	addi	a0,a0,358 # 80021d60 <ftable>
    80004c02:	ffffc097          	auipc	ra,0xffffc
    80004c06:	fe2080e7          	jalr	-30(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c0a:	0001d497          	auipc	s1,0x1d
    80004c0e:	16e48493          	addi	s1,s1,366 # 80021d78 <ftable+0x18>
    80004c12:	0001e717          	auipc	a4,0x1e
    80004c16:	10670713          	addi	a4,a4,262 # 80022d18 <ftable+0xfb8>
    if(f->ref == 0){
    80004c1a:	40dc                	lw	a5,4(s1)
    80004c1c:	cf99                	beqz	a5,80004c3a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c1e:	02848493          	addi	s1,s1,40
    80004c22:	fee49ce3          	bne	s1,a4,80004c1a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004c26:	0001d517          	auipc	a0,0x1d
    80004c2a:	13a50513          	addi	a0,a0,314 # 80021d60 <ftable>
    80004c2e:	ffffc097          	auipc	ra,0xffffc
    80004c32:	07c080e7          	jalr	124(ra) # 80000caa <release>
  return 0;
    80004c36:	4481                	li	s1,0
    80004c38:	a819                	j	80004c4e <filealloc+0x5e>
      f->ref = 1;
    80004c3a:	4785                	li	a5,1
    80004c3c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c3e:	0001d517          	auipc	a0,0x1d
    80004c42:	12250513          	addi	a0,a0,290 # 80021d60 <ftable>
    80004c46:	ffffc097          	auipc	ra,0xffffc
    80004c4a:	064080e7          	jalr	100(ra) # 80000caa <release>
}
    80004c4e:	8526                	mv	a0,s1
    80004c50:	60e2                	ld	ra,24(sp)
    80004c52:	6442                	ld	s0,16(sp)
    80004c54:	64a2                	ld	s1,8(sp)
    80004c56:	6105                	addi	sp,sp,32
    80004c58:	8082                	ret

0000000080004c5a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c5a:	1101                	addi	sp,sp,-32
    80004c5c:	ec06                	sd	ra,24(sp)
    80004c5e:	e822                	sd	s0,16(sp)
    80004c60:	e426                	sd	s1,8(sp)
    80004c62:	1000                	addi	s0,sp,32
    80004c64:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c66:	0001d517          	auipc	a0,0x1d
    80004c6a:	0fa50513          	addi	a0,a0,250 # 80021d60 <ftable>
    80004c6e:	ffffc097          	auipc	ra,0xffffc
    80004c72:	f76080e7          	jalr	-138(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004c76:	40dc                	lw	a5,4(s1)
    80004c78:	02f05263          	blez	a5,80004c9c <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004c7c:	2785                	addiw	a5,a5,1
    80004c7e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004c80:	0001d517          	auipc	a0,0x1d
    80004c84:	0e050513          	addi	a0,a0,224 # 80021d60 <ftable>
    80004c88:	ffffc097          	auipc	ra,0xffffc
    80004c8c:	022080e7          	jalr	34(ra) # 80000caa <release>
  return f;
}
    80004c90:	8526                	mv	a0,s1
    80004c92:	60e2                	ld	ra,24(sp)
    80004c94:	6442                	ld	s0,16(sp)
    80004c96:	64a2                	ld	s1,8(sp)
    80004c98:	6105                	addi	sp,sp,32
    80004c9a:	8082                	ret
    panic("filedup");
    80004c9c:	00004517          	auipc	a0,0x4
    80004ca0:	a9c50513          	addi	a0,a0,-1380 # 80008738 <syscalls+0x258>
    80004ca4:	ffffc097          	auipc	ra,0xffffc
    80004ca8:	89a080e7          	jalr	-1894(ra) # 8000053e <panic>

0000000080004cac <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004cac:	7139                	addi	sp,sp,-64
    80004cae:	fc06                	sd	ra,56(sp)
    80004cb0:	f822                	sd	s0,48(sp)
    80004cb2:	f426                	sd	s1,40(sp)
    80004cb4:	f04a                	sd	s2,32(sp)
    80004cb6:	ec4e                	sd	s3,24(sp)
    80004cb8:	e852                	sd	s4,16(sp)
    80004cba:	e456                	sd	s5,8(sp)
    80004cbc:	0080                	addi	s0,sp,64
    80004cbe:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004cc0:	0001d517          	auipc	a0,0x1d
    80004cc4:	0a050513          	addi	a0,a0,160 # 80021d60 <ftable>
    80004cc8:	ffffc097          	auipc	ra,0xffffc
    80004ccc:	f1c080e7          	jalr	-228(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004cd0:	40dc                	lw	a5,4(s1)
    80004cd2:	06f05163          	blez	a5,80004d34 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004cd6:	37fd                	addiw	a5,a5,-1
    80004cd8:	0007871b          	sext.w	a4,a5
    80004cdc:	c0dc                	sw	a5,4(s1)
    80004cde:	06e04363          	bgtz	a4,80004d44 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004ce2:	0004a903          	lw	s2,0(s1)
    80004ce6:	0094ca83          	lbu	s5,9(s1)
    80004cea:	0104ba03          	ld	s4,16(s1)
    80004cee:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004cf2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004cf6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004cfa:	0001d517          	auipc	a0,0x1d
    80004cfe:	06650513          	addi	a0,a0,102 # 80021d60 <ftable>
    80004d02:	ffffc097          	auipc	ra,0xffffc
    80004d06:	fa8080e7          	jalr	-88(ra) # 80000caa <release>

  if(ff.type == FD_PIPE){
    80004d0a:	4785                	li	a5,1
    80004d0c:	04f90d63          	beq	s2,a5,80004d66 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004d10:	3979                	addiw	s2,s2,-2
    80004d12:	4785                	li	a5,1
    80004d14:	0527e063          	bltu	a5,s2,80004d54 <fileclose+0xa8>
    begin_op();
    80004d18:	00000097          	auipc	ra,0x0
    80004d1c:	ac8080e7          	jalr	-1336(ra) # 800047e0 <begin_op>
    iput(ff.ip);
    80004d20:	854e                	mv	a0,s3
    80004d22:	fffff097          	auipc	ra,0xfffff
    80004d26:	2a6080e7          	jalr	678(ra) # 80003fc8 <iput>
    end_op();
    80004d2a:	00000097          	auipc	ra,0x0
    80004d2e:	b36080e7          	jalr	-1226(ra) # 80004860 <end_op>
    80004d32:	a00d                	j	80004d54 <fileclose+0xa8>
    panic("fileclose");
    80004d34:	00004517          	auipc	a0,0x4
    80004d38:	a0c50513          	addi	a0,a0,-1524 # 80008740 <syscalls+0x260>
    80004d3c:	ffffc097          	auipc	ra,0xffffc
    80004d40:	802080e7          	jalr	-2046(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004d44:	0001d517          	auipc	a0,0x1d
    80004d48:	01c50513          	addi	a0,a0,28 # 80021d60 <ftable>
    80004d4c:	ffffc097          	auipc	ra,0xffffc
    80004d50:	f5e080e7          	jalr	-162(ra) # 80000caa <release>
  }
}
    80004d54:	70e2                	ld	ra,56(sp)
    80004d56:	7442                	ld	s0,48(sp)
    80004d58:	74a2                	ld	s1,40(sp)
    80004d5a:	7902                	ld	s2,32(sp)
    80004d5c:	69e2                	ld	s3,24(sp)
    80004d5e:	6a42                	ld	s4,16(sp)
    80004d60:	6aa2                	ld	s5,8(sp)
    80004d62:	6121                	addi	sp,sp,64
    80004d64:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d66:	85d6                	mv	a1,s5
    80004d68:	8552                	mv	a0,s4
    80004d6a:	00000097          	auipc	ra,0x0
    80004d6e:	34c080e7          	jalr	844(ra) # 800050b6 <pipeclose>
    80004d72:	b7cd                	j	80004d54 <fileclose+0xa8>

0000000080004d74 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d74:	715d                	addi	sp,sp,-80
    80004d76:	e486                	sd	ra,72(sp)
    80004d78:	e0a2                	sd	s0,64(sp)
    80004d7a:	fc26                	sd	s1,56(sp)
    80004d7c:	f84a                	sd	s2,48(sp)
    80004d7e:	f44e                	sd	s3,40(sp)
    80004d80:	0880                	addi	s0,sp,80
    80004d82:	84aa                	mv	s1,a0
    80004d84:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004d86:	ffffd097          	auipc	ra,0xffffd
    80004d8a:	056080e7          	jalr	86(ra) # 80001ddc <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d8e:	409c                	lw	a5,0(s1)
    80004d90:	37f9                	addiw	a5,a5,-2
    80004d92:	4705                	li	a4,1
    80004d94:	04f76763          	bltu	a4,a5,80004de2 <filestat+0x6e>
    80004d98:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d9a:	6c88                	ld	a0,24(s1)
    80004d9c:	fffff097          	auipc	ra,0xfffff
    80004da0:	072080e7          	jalr	114(ra) # 80003e0e <ilock>
    stati(f->ip, &st);
    80004da4:	fb840593          	addi	a1,s0,-72
    80004da8:	6c88                	ld	a0,24(s1)
    80004daa:	fffff097          	auipc	ra,0xfffff
    80004dae:	2ee080e7          	jalr	750(ra) # 80004098 <stati>
    iunlock(f->ip);
    80004db2:	6c88                	ld	a0,24(s1)
    80004db4:	fffff097          	auipc	ra,0xfffff
    80004db8:	11c080e7          	jalr	284(ra) # 80003ed0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004dbc:	46e1                	li	a3,24
    80004dbe:	fb840613          	addi	a2,s0,-72
    80004dc2:	85ce                	mv	a1,s3
    80004dc4:	07093503          	ld	a0,112(s2)
    80004dc8:	ffffd097          	auipc	ra,0xffffd
    80004dcc:	8ce080e7          	jalr	-1842(ra) # 80001696 <copyout>
    80004dd0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004dd4:	60a6                	ld	ra,72(sp)
    80004dd6:	6406                	ld	s0,64(sp)
    80004dd8:	74e2                	ld	s1,56(sp)
    80004dda:	7942                	ld	s2,48(sp)
    80004ddc:	79a2                	ld	s3,40(sp)
    80004dde:	6161                	addi	sp,sp,80
    80004de0:	8082                	ret
  return -1;
    80004de2:	557d                	li	a0,-1
    80004de4:	bfc5                	j	80004dd4 <filestat+0x60>

0000000080004de6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004de6:	7179                	addi	sp,sp,-48
    80004de8:	f406                	sd	ra,40(sp)
    80004dea:	f022                	sd	s0,32(sp)
    80004dec:	ec26                	sd	s1,24(sp)
    80004dee:	e84a                	sd	s2,16(sp)
    80004df0:	e44e                	sd	s3,8(sp)
    80004df2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004df4:	00854783          	lbu	a5,8(a0)
    80004df8:	c3d5                	beqz	a5,80004e9c <fileread+0xb6>
    80004dfa:	84aa                	mv	s1,a0
    80004dfc:	89ae                	mv	s3,a1
    80004dfe:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e00:	411c                	lw	a5,0(a0)
    80004e02:	4705                	li	a4,1
    80004e04:	04e78963          	beq	a5,a4,80004e56 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e08:	470d                	li	a4,3
    80004e0a:	04e78d63          	beq	a5,a4,80004e64 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e0e:	4709                	li	a4,2
    80004e10:	06e79e63          	bne	a5,a4,80004e8c <fileread+0xa6>
    ilock(f->ip);
    80004e14:	6d08                	ld	a0,24(a0)
    80004e16:	fffff097          	auipc	ra,0xfffff
    80004e1a:	ff8080e7          	jalr	-8(ra) # 80003e0e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004e1e:	874a                	mv	a4,s2
    80004e20:	5094                	lw	a3,32(s1)
    80004e22:	864e                	mv	a2,s3
    80004e24:	4585                	li	a1,1
    80004e26:	6c88                	ld	a0,24(s1)
    80004e28:	fffff097          	auipc	ra,0xfffff
    80004e2c:	29a080e7          	jalr	666(ra) # 800040c2 <readi>
    80004e30:	892a                	mv	s2,a0
    80004e32:	00a05563          	blez	a0,80004e3c <fileread+0x56>
      f->off += r;
    80004e36:	509c                	lw	a5,32(s1)
    80004e38:	9fa9                	addw	a5,a5,a0
    80004e3a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004e3c:	6c88                	ld	a0,24(s1)
    80004e3e:	fffff097          	auipc	ra,0xfffff
    80004e42:	092080e7          	jalr	146(ra) # 80003ed0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e46:	854a                	mv	a0,s2
    80004e48:	70a2                	ld	ra,40(sp)
    80004e4a:	7402                	ld	s0,32(sp)
    80004e4c:	64e2                	ld	s1,24(sp)
    80004e4e:	6942                	ld	s2,16(sp)
    80004e50:	69a2                	ld	s3,8(sp)
    80004e52:	6145                	addi	sp,sp,48
    80004e54:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e56:	6908                	ld	a0,16(a0)
    80004e58:	00000097          	auipc	ra,0x0
    80004e5c:	3c8080e7          	jalr	968(ra) # 80005220 <piperead>
    80004e60:	892a                	mv	s2,a0
    80004e62:	b7d5                	j	80004e46 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e64:	02451783          	lh	a5,36(a0)
    80004e68:	03079693          	slli	a3,a5,0x30
    80004e6c:	92c1                	srli	a3,a3,0x30
    80004e6e:	4725                	li	a4,9
    80004e70:	02d76863          	bltu	a4,a3,80004ea0 <fileread+0xba>
    80004e74:	0792                	slli	a5,a5,0x4
    80004e76:	0001d717          	auipc	a4,0x1d
    80004e7a:	e4a70713          	addi	a4,a4,-438 # 80021cc0 <devsw>
    80004e7e:	97ba                	add	a5,a5,a4
    80004e80:	639c                	ld	a5,0(a5)
    80004e82:	c38d                	beqz	a5,80004ea4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e84:	4505                	li	a0,1
    80004e86:	9782                	jalr	a5
    80004e88:	892a                	mv	s2,a0
    80004e8a:	bf75                	j	80004e46 <fileread+0x60>
    panic("fileread");
    80004e8c:	00004517          	auipc	a0,0x4
    80004e90:	8c450513          	addi	a0,a0,-1852 # 80008750 <syscalls+0x270>
    80004e94:	ffffb097          	auipc	ra,0xffffb
    80004e98:	6aa080e7          	jalr	1706(ra) # 8000053e <panic>
    return -1;
    80004e9c:	597d                	li	s2,-1
    80004e9e:	b765                	j	80004e46 <fileread+0x60>
      return -1;
    80004ea0:	597d                	li	s2,-1
    80004ea2:	b755                	j	80004e46 <fileread+0x60>
    80004ea4:	597d                	li	s2,-1
    80004ea6:	b745                	j	80004e46 <fileread+0x60>

0000000080004ea8 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004ea8:	715d                	addi	sp,sp,-80
    80004eaa:	e486                	sd	ra,72(sp)
    80004eac:	e0a2                	sd	s0,64(sp)
    80004eae:	fc26                	sd	s1,56(sp)
    80004eb0:	f84a                	sd	s2,48(sp)
    80004eb2:	f44e                	sd	s3,40(sp)
    80004eb4:	f052                	sd	s4,32(sp)
    80004eb6:	ec56                	sd	s5,24(sp)
    80004eb8:	e85a                	sd	s6,16(sp)
    80004eba:	e45e                	sd	s7,8(sp)
    80004ebc:	e062                	sd	s8,0(sp)
    80004ebe:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004ec0:	00954783          	lbu	a5,9(a0)
    80004ec4:	10078663          	beqz	a5,80004fd0 <filewrite+0x128>
    80004ec8:	892a                	mv	s2,a0
    80004eca:	8aae                	mv	s5,a1
    80004ecc:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ece:	411c                	lw	a5,0(a0)
    80004ed0:	4705                	li	a4,1
    80004ed2:	02e78263          	beq	a5,a4,80004ef6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ed6:	470d                	li	a4,3
    80004ed8:	02e78663          	beq	a5,a4,80004f04 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004edc:	4709                	li	a4,2
    80004ede:	0ee79163          	bne	a5,a4,80004fc0 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ee2:	0ac05d63          	blez	a2,80004f9c <filewrite+0xf4>
    int i = 0;
    80004ee6:	4981                	li	s3,0
    80004ee8:	6b05                	lui	s6,0x1
    80004eea:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004eee:	6b85                	lui	s7,0x1
    80004ef0:	c00b8b9b          	addiw	s7,s7,-1024
    80004ef4:	a861                	j	80004f8c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004ef6:	6908                	ld	a0,16(a0)
    80004ef8:	00000097          	auipc	ra,0x0
    80004efc:	22e080e7          	jalr	558(ra) # 80005126 <pipewrite>
    80004f00:	8a2a                	mv	s4,a0
    80004f02:	a045                	j	80004fa2 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004f04:	02451783          	lh	a5,36(a0)
    80004f08:	03079693          	slli	a3,a5,0x30
    80004f0c:	92c1                	srli	a3,a3,0x30
    80004f0e:	4725                	li	a4,9
    80004f10:	0cd76263          	bltu	a4,a3,80004fd4 <filewrite+0x12c>
    80004f14:	0792                	slli	a5,a5,0x4
    80004f16:	0001d717          	auipc	a4,0x1d
    80004f1a:	daa70713          	addi	a4,a4,-598 # 80021cc0 <devsw>
    80004f1e:	97ba                	add	a5,a5,a4
    80004f20:	679c                	ld	a5,8(a5)
    80004f22:	cbdd                	beqz	a5,80004fd8 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004f24:	4505                	li	a0,1
    80004f26:	9782                	jalr	a5
    80004f28:	8a2a                	mv	s4,a0
    80004f2a:	a8a5                	j	80004fa2 <filewrite+0xfa>
    80004f2c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004f30:	00000097          	auipc	ra,0x0
    80004f34:	8b0080e7          	jalr	-1872(ra) # 800047e0 <begin_op>
      ilock(f->ip);
    80004f38:	01893503          	ld	a0,24(s2)
    80004f3c:	fffff097          	auipc	ra,0xfffff
    80004f40:	ed2080e7          	jalr	-302(ra) # 80003e0e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f44:	8762                	mv	a4,s8
    80004f46:	02092683          	lw	a3,32(s2)
    80004f4a:	01598633          	add	a2,s3,s5
    80004f4e:	4585                	li	a1,1
    80004f50:	01893503          	ld	a0,24(s2)
    80004f54:	fffff097          	auipc	ra,0xfffff
    80004f58:	266080e7          	jalr	614(ra) # 800041ba <writei>
    80004f5c:	84aa                	mv	s1,a0
    80004f5e:	00a05763          	blez	a0,80004f6c <filewrite+0xc4>
        f->off += r;
    80004f62:	02092783          	lw	a5,32(s2)
    80004f66:	9fa9                	addw	a5,a5,a0
    80004f68:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f6c:	01893503          	ld	a0,24(s2)
    80004f70:	fffff097          	auipc	ra,0xfffff
    80004f74:	f60080e7          	jalr	-160(ra) # 80003ed0 <iunlock>
      end_op();
    80004f78:	00000097          	auipc	ra,0x0
    80004f7c:	8e8080e7          	jalr	-1816(ra) # 80004860 <end_op>

      if(r != n1){
    80004f80:	009c1f63          	bne	s8,s1,80004f9e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004f84:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f88:	0149db63          	bge	s3,s4,80004f9e <filewrite+0xf6>
      int n1 = n - i;
    80004f8c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004f90:	84be                	mv	s1,a5
    80004f92:	2781                	sext.w	a5,a5
    80004f94:	f8fb5ce3          	bge	s6,a5,80004f2c <filewrite+0x84>
    80004f98:	84de                	mv	s1,s7
    80004f9a:	bf49                	j	80004f2c <filewrite+0x84>
    int i = 0;
    80004f9c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004f9e:	013a1f63          	bne	s4,s3,80004fbc <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004fa2:	8552                	mv	a0,s4
    80004fa4:	60a6                	ld	ra,72(sp)
    80004fa6:	6406                	ld	s0,64(sp)
    80004fa8:	74e2                	ld	s1,56(sp)
    80004faa:	7942                	ld	s2,48(sp)
    80004fac:	79a2                	ld	s3,40(sp)
    80004fae:	7a02                	ld	s4,32(sp)
    80004fb0:	6ae2                	ld	s5,24(sp)
    80004fb2:	6b42                	ld	s6,16(sp)
    80004fb4:	6ba2                	ld	s7,8(sp)
    80004fb6:	6c02                	ld	s8,0(sp)
    80004fb8:	6161                	addi	sp,sp,80
    80004fba:	8082                	ret
    ret = (i == n ? n : -1);
    80004fbc:	5a7d                	li	s4,-1
    80004fbe:	b7d5                	j	80004fa2 <filewrite+0xfa>
    panic("filewrite");
    80004fc0:	00003517          	auipc	a0,0x3
    80004fc4:	7a050513          	addi	a0,a0,1952 # 80008760 <syscalls+0x280>
    80004fc8:	ffffb097          	auipc	ra,0xffffb
    80004fcc:	576080e7          	jalr	1398(ra) # 8000053e <panic>
    return -1;
    80004fd0:	5a7d                	li	s4,-1
    80004fd2:	bfc1                	j	80004fa2 <filewrite+0xfa>
      return -1;
    80004fd4:	5a7d                	li	s4,-1
    80004fd6:	b7f1                	j	80004fa2 <filewrite+0xfa>
    80004fd8:	5a7d                	li	s4,-1
    80004fda:	b7e1                	j	80004fa2 <filewrite+0xfa>

0000000080004fdc <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004fdc:	7179                	addi	sp,sp,-48
    80004fde:	f406                	sd	ra,40(sp)
    80004fe0:	f022                	sd	s0,32(sp)
    80004fe2:	ec26                	sd	s1,24(sp)
    80004fe4:	e84a                	sd	s2,16(sp)
    80004fe6:	e44e                	sd	s3,8(sp)
    80004fe8:	e052                	sd	s4,0(sp)
    80004fea:	1800                	addi	s0,sp,48
    80004fec:	84aa                	mv	s1,a0
    80004fee:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ff0:	0005b023          	sd	zero,0(a1)
    80004ff4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ff8:	00000097          	auipc	ra,0x0
    80004ffc:	bf8080e7          	jalr	-1032(ra) # 80004bf0 <filealloc>
    80005000:	e088                	sd	a0,0(s1)
    80005002:	c551                	beqz	a0,8000508e <pipealloc+0xb2>
    80005004:	00000097          	auipc	ra,0x0
    80005008:	bec080e7          	jalr	-1044(ra) # 80004bf0 <filealloc>
    8000500c:	00aa3023          	sd	a0,0(s4)
    80005010:	c92d                	beqz	a0,80005082 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005012:	ffffc097          	auipc	ra,0xffffc
    80005016:	ae2080e7          	jalr	-1310(ra) # 80000af4 <kalloc>
    8000501a:	892a                	mv	s2,a0
    8000501c:	c125                	beqz	a0,8000507c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000501e:	4985                	li	s3,1
    80005020:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005024:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005028:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000502c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005030:	00003597          	auipc	a1,0x3
    80005034:	74058593          	addi	a1,a1,1856 # 80008770 <syscalls+0x290>
    80005038:	ffffc097          	auipc	ra,0xffffc
    8000503c:	b1c080e7          	jalr	-1252(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80005040:	609c                	ld	a5,0(s1)
    80005042:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005046:	609c                	ld	a5,0(s1)
    80005048:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000504c:	609c                	ld	a5,0(s1)
    8000504e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005052:	609c                	ld	a5,0(s1)
    80005054:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005058:	000a3783          	ld	a5,0(s4)
    8000505c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005060:	000a3783          	ld	a5,0(s4)
    80005064:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005068:	000a3783          	ld	a5,0(s4)
    8000506c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005070:	000a3783          	ld	a5,0(s4)
    80005074:	0127b823          	sd	s2,16(a5)
  return 0;
    80005078:	4501                	li	a0,0
    8000507a:	a025                	j	800050a2 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000507c:	6088                	ld	a0,0(s1)
    8000507e:	e501                	bnez	a0,80005086 <pipealloc+0xaa>
    80005080:	a039                	j	8000508e <pipealloc+0xb2>
    80005082:	6088                	ld	a0,0(s1)
    80005084:	c51d                	beqz	a0,800050b2 <pipealloc+0xd6>
    fileclose(*f0);
    80005086:	00000097          	auipc	ra,0x0
    8000508a:	c26080e7          	jalr	-986(ra) # 80004cac <fileclose>
  if(*f1)
    8000508e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005092:	557d                	li	a0,-1
  if(*f1)
    80005094:	c799                	beqz	a5,800050a2 <pipealloc+0xc6>
    fileclose(*f1);
    80005096:	853e                	mv	a0,a5
    80005098:	00000097          	auipc	ra,0x0
    8000509c:	c14080e7          	jalr	-1004(ra) # 80004cac <fileclose>
  return -1;
    800050a0:	557d                	li	a0,-1
}
    800050a2:	70a2                	ld	ra,40(sp)
    800050a4:	7402                	ld	s0,32(sp)
    800050a6:	64e2                	ld	s1,24(sp)
    800050a8:	6942                	ld	s2,16(sp)
    800050aa:	69a2                	ld	s3,8(sp)
    800050ac:	6a02                	ld	s4,0(sp)
    800050ae:	6145                	addi	sp,sp,48
    800050b0:	8082                	ret
  return -1;
    800050b2:	557d                	li	a0,-1
    800050b4:	b7fd                	j	800050a2 <pipealloc+0xc6>

00000000800050b6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800050b6:	1101                	addi	sp,sp,-32
    800050b8:	ec06                	sd	ra,24(sp)
    800050ba:	e822                	sd	s0,16(sp)
    800050bc:	e426                	sd	s1,8(sp)
    800050be:	e04a                	sd	s2,0(sp)
    800050c0:	1000                	addi	s0,sp,32
    800050c2:	84aa                	mv	s1,a0
    800050c4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800050c6:	ffffc097          	auipc	ra,0xffffc
    800050ca:	b1e080e7          	jalr	-1250(ra) # 80000be4 <acquire>
  if(writable){
    800050ce:	02090d63          	beqz	s2,80005108 <pipeclose+0x52>
    pi->writeopen = 0;
    800050d2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800050d6:	21848513          	addi	a0,s1,536
    800050da:	ffffd097          	auipc	ra,0xffffd
    800050de:	758080e7          	jalr	1880(ra) # 80002832 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800050e2:	2204b783          	ld	a5,544(s1)
    800050e6:	eb95                	bnez	a5,8000511a <pipeclose+0x64>
    release(&pi->lock);
    800050e8:	8526                	mv	a0,s1
    800050ea:	ffffc097          	auipc	ra,0xffffc
    800050ee:	bc0080e7          	jalr	-1088(ra) # 80000caa <release>
    kfree((char*)pi);
    800050f2:	8526                	mv	a0,s1
    800050f4:	ffffc097          	auipc	ra,0xffffc
    800050f8:	904080e7          	jalr	-1788(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800050fc:	60e2                	ld	ra,24(sp)
    800050fe:	6442                	ld	s0,16(sp)
    80005100:	64a2                	ld	s1,8(sp)
    80005102:	6902                	ld	s2,0(sp)
    80005104:	6105                	addi	sp,sp,32
    80005106:	8082                	ret
    pi->readopen = 0;
    80005108:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000510c:	21c48513          	addi	a0,s1,540
    80005110:	ffffd097          	auipc	ra,0xffffd
    80005114:	722080e7          	jalr	1826(ra) # 80002832 <wakeup>
    80005118:	b7e9                	j	800050e2 <pipeclose+0x2c>
    release(&pi->lock);
    8000511a:	8526                	mv	a0,s1
    8000511c:	ffffc097          	auipc	ra,0xffffc
    80005120:	b8e080e7          	jalr	-1138(ra) # 80000caa <release>
}
    80005124:	bfe1                	j	800050fc <pipeclose+0x46>

0000000080005126 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005126:	7159                	addi	sp,sp,-112
    80005128:	f486                	sd	ra,104(sp)
    8000512a:	f0a2                	sd	s0,96(sp)
    8000512c:	eca6                	sd	s1,88(sp)
    8000512e:	e8ca                	sd	s2,80(sp)
    80005130:	e4ce                	sd	s3,72(sp)
    80005132:	e0d2                	sd	s4,64(sp)
    80005134:	fc56                	sd	s5,56(sp)
    80005136:	f85a                	sd	s6,48(sp)
    80005138:	f45e                	sd	s7,40(sp)
    8000513a:	f062                	sd	s8,32(sp)
    8000513c:	ec66                	sd	s9,24(sp)
    8000513e:	1880                	addi	s0,sp,112
    80005140:	84aa                	mv	s1,a0
    80005142:	8aae                	mv	s5,a1
    80005144:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005146:	ffffd097          	auipc	ra,0xffffd
    8000514a:	c96080e7          	jalr	-874(ra) # 80001ddc <myproc>
    8000514e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005150:	8526                	mv	a0,s1
    80005152:	ffffc097          	auipc	ra,0xffffc
    80005156:	a92080e7          	jalr	-1390(ra) # 80000be4 <acquire>
  while(i < n){
    8000515a:	0d405163          	blez	s4,8000521c <pipewrite+0xf6>
    8000515e:	8ba6                	mv	s7,s1
  int i = 0;
    80005160:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005162:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005164:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005168:	21c48c13          	addi	s8,s1,540
    8000516c:	a08d                	j	800051ce <pipewrite+0xa8>
      release(&pi->lock);
    8000516e:	8526                	mv	a0,s1
    80005170:	ffffc097          	auipc	ra,0xffffc
    80005174:	b3a080e7          	jalr	-1222(ra) # 80000caa <release>
      return -1;
    80005178:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000517a:	854a                	mv	a0,s2
    8000517c:	70a6                	ld	ra,104(sp)
    8000517e:	7406                	ld	s0,96(sp)
    80005180:	64e6                	ld	s1,88(sp)
    80005182:	6946                	ld	s2,80(sp)
    80005184:	69a6                	ld	s3,72(sp)
    80005186:	6a06                	ld	s4,64(sp)
    80005188:	7ae2                	ld	s5,56(sp)
    8000518a:	7b42                	ld	s6,48(sp)
    8000518c:	7ba2                	ld	s7,40(sp)
    8000518e:	7c02                	ld	s8,32(sp)
    80005190:	6ce2                	ld	s9,24(sp)
    80005192:	6165                	addi	sp,sp,112
    80005194:	8082                	ret
      wakeup(&pi->nread);
    80005196:	8566                	mv	a0,s9
    80005198:	ffffd097          	auipc	ra,0xffffd
    8000519c:	69a080e7          	jalr	1690(ra) # 80002832 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800051a0:	85de                	mv	a1,s7
    800051a2:	8562                	mv	a0,s8
    800051a4:	ffffd097          	auipc	ra,0xffffd
    800051a8:	4e6080e7          	jalr	1254(ra) # 8000268a <sleep>
    800051ac:	a839                	j	800051ca <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800051ae:	21c4a783          	lw	a5,540(s1)
    800051b2:	0017871b          	addiw	a4,a5,1
    800051b6:	20e4ae23          	sw	a4,540(s1)
    800051ba:	1ff7f793          	andi	a5,a5,511
    800051be:	97a6                	add	a5,a5,s1
    800051c0:	f9f44703          	lbu	a4,-97(s0)
    800051c4:	00e78c23          	sb	a4,24(a5)
      i++;
    800051c8:	2905                	addiw	s2,s2,1
  while(i < n){
    800051ca:	03495d63          	bge	s2,s4,80005204 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800051ce:	2204a783          	lw	a5,544(s1)
    800051d2:	dfd1                	beqz	a5,8000516e <pipewrite+0x48>
    800051d4:	0289a783          	lw	a5,40(s3)
    800051d8:	fbd9                	bnez	a5,8000516e <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800051da:	2184a783          	lw	a5,536(s1)
    800051de:	21c4a703          	lw	a4,540(s1)
    800051e2:	2007879b          	addiw	a5,a5,512
    800051e6:	faf708e3          	beq	a4,a5,80005196 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051ea:	4685                	li	a3,1
    800051ec:	01590633          	add	a2,s2,s5
    800051f0:	f9f40593          	addi	a1,s0,-97
    800051f4:	0709b503          	ld	a0,112(s3)
    800051f8:	ffffc097          	auipc	ra,0xffffc
    800051fc:	52a080e7          	jalr	1322(ra) # 80001722 <copyin>
    80005200:	fb6517e3          	bne	a0,s6,800051ae <pipewrite+0x88>
  wakeup(&pi->nread);
    80005204:	21848513          	addi	a0,s1,536
    80005208:	ffffd097          	auipc	ra,0xffffd
    8000520c:	62a080e7          	jalr	1578(ra) # 80002832 <wakeup>
  release(&pi->lock);
    80005210:	8526                	mv	a0,s1
    80005212:	ffffc097          	auipc	ra,0xffffc
    80005216:	a98080e7          	jalr	-1384(ra) # 80000caa <release>
  return i;
    8000521a:	b785                	j	8000517a <pipewrite+0x54>
  int i = 0;
    8000521c:	4901                	li	s2,0
    8000521e:	b7dd                	j	80005204 <pipewrite+0xde>

0000000080005220 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005220:	715d                	addi	sp,sp,-80
    80005222:	e486                	sd	ra,72(sp)
    80005224:	e0a2                	sd	s0,64(sp)
    80005226:	fc26                	sd	s1,56(sp)
    80005228:	f84a                	sd	s2,48(sp)
    8000522a:	f44e                	sd	s3,40(sp)
    8000522c:	f052                	sd	s4,32(sp)
    8000522e:	ec56                	sd	s5,24(sp)
    80005230:	e85a                	sd	s6,16(sp)
    80005232:	0880                	addi	s0,sp,80
    80005234:	84aa                	mv	s1,a0
    80005236:	892e                	mv	s2,a1
    80005238:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000523a:	ffffd097          	auipc	ra,0xffffd
    8000523e:	ba2080e7          	jalr	-1118(ra) # 80001ddc <myproc>
    80005242:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005244:	8b26                	mv	s6,s1
    80005246:	8526                	mv	a0,s1
    80005248:	ffffc097          	auipc	ra,0xffffc
    8000524c:	99c080e7          	jalr	-1636(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005250:	2184a703          	lw	a4,536(s1)
    80005254:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005258:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000525c:	02f71463          	bne	a4,a5,80005284 <piperead+0x64>
    80005260:	2244a783          	lw	a5,548(s1)
    80005264:	c385                	beqz	a5,80005284 <piperead+0x64>
    if(pr->killed){
    80005266:	028a2783          	lw	a5,40(s4)
    8000526a:	ebc1                	bnez	a5,800052fa <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000526c:	85da                	mv	a1,s6
    8000526e:	854e                	mv	a0,s3
    80005270:	ffffd097          	auipc	ra,0xffffd
    80005274:	41a080e7          	jalr	1050(ra) # 8000268a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005278:	2184a703          	lw	a4,536(s1)
    8000527c:	21c4a783          	lw	a5,540(s1)
    80005280:	fef700e3          	beq	a4,a5,80005260 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005284:	09505263          	blez	s5,80005308 <piperead+0xe8>
    80005288:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000528a:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000528c:	2184a783          	lw	a5,536(s1)
    80005290:	21c4a703          	lw	a4,540(s1)
    80005294:	02f70d63          	beq	a4,a5,800052ce <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005298:	0017871b          	addiw	a4,a5,1
    8000529c:	20e4ac23          	sw	a4,536(s1)
    800052a0:	1ff7f793          	andi	a5,a5,511
    800052a4:	97a6                	add	a5,a5,s1
    800052a6:	0187c783          	lbu	a5,24(a5)
    800052aa:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052ae:	4685                	li	a3,1
    800052b0:	fbf40613          	addi	a2,s0,-65
    800052b4:	85ca                	mv	a1,s2
    800052b6:	070a3503          	ld	a0,112(s4)
    800052ba:	ffffc097          	auipc	ra,0xffffc
    800052be:	3dc080e7          	jalr	988(ra) # 80001696 <copyout>
    800052c2:	01650663          	beq	a0,s6,800052ce <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052c6:	2985                	addiw	s3,s3,1
    800052c8:	0905                	addi	s2,s2,1
    800052ca:	fd3a91e3          	bne	s5,s3,8000528c <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800052ce:	21c48513          	addi	a0,s1,540
    800052d2:	ffffd097          	auipc	ra,0xffffd
    800052d6:	560080e7          	jalr	1376(ra) # 80002832 <wakeup>
  release(&pi->lock);
    800052da:	8526                	mv	a0,s1
    800052dc:	ffffc097          	auipc	ra,0xffffc
    800052e0:	9ce080e7          	jalr	-1586(ra) # 80000caa <release>
  return i;
}
    800052e4:	854e                	mv	a0,s3
    800052e6:	60a6                	ld	ra,72(sp)
    800052e8:	6406                	ld	s0,64(sp)
    800052ea:	74e2                	ld	s1,56(sp)
    800052ec:	7942                	ld	s2,48(sp)
    800052ee:	79a2                	ld	s3,40(sp)
    800052f0:	7a02                	ld	s4,32(sp)
    800052f2:	6ae2                	ld	s5,24(sp)
    800052f4:	6b42                	ld	s6,16(sp)
    800052f6:	6161                	addi	sp,sp,80
    800052f8:	8082                	ret
      release(&pi->lock);
    800052fa:	8526                	mv	a0,s1
    800052fc:	ffffc097          	auipc	ra,0xffffc
    80005300:	9ae080e7          	jalr	-1618(ra) # 80000caa <release>
      return -1;
    80005304:	59fd                	li	s3,-1
    80005306:	bff9                	j	800052e4 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005308:	4981                	li	s3,0
    8000530a:	b7d1                	j	800052ce <piperead+0xae>

000000008000530c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000530c:	df010113          	addi	sp,sp,-528
    80005310:	20113423          	sd	ra,520(sp)
    80005314:	20813023          	sd	s0,512(sp)
    80005318:	ffa6                	sd	s1,504(sp)
    8000531a:	fbca                	sd	s2,496(sp)
    8000531c:	f7ce                	sd	s3,488(sp)
    8000531e:	f3d2                	sd	s4,480(sp)
    80005320:	efd6                	sd	s5,472(sp)
    80005322:	ebda                	sd	s6,464(sp)
    80005324:	e7de                	sd	s7,456(sp)
    80005326:	e3e2                	sd	s8,448(sp)
    80005328:	ff66                	sd	s9,440(sp)
    8000532a:	fb6a                	sd	s10,432(sp)
    8000532c:	f76e                	sd	s11,424(sp)
    8000532e:	0c00                	addi	s0,sp,528
    80005330:	84aa                	mv	s1,a0
    80005332:	dea43c23          	sd	a0,-520(s0)
    80005336:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000533a:	ffffd097          	auipc	ra,0xffffd
    8000533e:	aa2080e7          	jalr	-1374(ra) # 80001ddc <myproc>
    80005342:	892a                	mv	s2,a0

  begin_op();
    80005344:	fffff097          	auipc	ra,0xfffff
    80005348:	49c080e7          	jalr	1180(ra) # 800047e0 <begin_op>

  if((ip = namei(path)) == 0){
    8000534c:	8526                	mv	a0,s1
    8000534e:	fffff097          	auipc	ra,0xfffff
    80005352:	276080e7          	jalr	630(ra) # 800045c4 <namei>
    80005356:	c92d                	beqz	a0,800053c8 <exec+0xbc>
    80005358:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000535a:	fffff097          	auipc	ra,0xfffff
    8000535e:	ab4080e7          	jalr	-1356(ra) # 80003e0e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005362:	04000713          	li	a4,64
    80005366:	4681                	li	a3,0
    80005368:	e5040613          	addi	a2,s0,-432
    8000536c:	4581                	li	a1,0
    8000536e:	8526                	mv	a0,s1
    80005370:	fffff097          	auipc	ra,0xfffff
    80005374:	d52080e7          	jalr	-686(ra) # 800040c2 <readi>
    80005378:	04000793          	li	a5,64
    8000537c:	00f51a63          	bne	a0,a5,80005390 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005380:	e5042703          	lw	a4,-432(s0)
    80005384:	464c47b7          	lui	a5,0x464c4
    80005388:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000538c:	04f70463          	beq	a4,a5,800053d4 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005390:	8526                	mv	a0,s1
    80005392:	fffff097          	auipc	ra,0xfffff
    80005396:	cde080e7          	jalr	-802(ra) # 80004070 <iunlockput>
    end_op();
    8000539a:	fffff097          	auipc	ra,0xfffff
    8000539e:	4c6080e7          	jalr	1222(ra) # 80004860 <end_op>
  }
  return -1;
    800053a2:	557d                	li	a0,-1
}
    800053a4:	20813083          	ld	ra,520(sp)
    800053a8:	20013403          	ld	s0,512(sp)
    800053ac:	74fe                	ld	s1,504(sp)
    800053ae:	795e                	ld	s2,496(sp)
    800053b0:	79be                	ld	s3,488(sp)
    800053b2:	7a1e                	ld	s4,480(sp)
    800053b4:	6afe                	ld	s5,472(sp)
    800053b6:	6b5e                	ld	s6,464(sp)
    800053b8:	6bbe                	ld	s7,456(sp)
    800053ba:	6c1e                	ld	s8,448(sp)
    800053bc:	7cfa                	ld	s9,440(sp)
    800053be:	7d5a                	ld	s10,432(sp)
    800053c0:	7dba                	ld	s11,424(sp)
    800053c2:	21010113          	addi	sp,sp,528
    800053c6:	8082                	ret
    end_op();
    800053c8:	fffff097          	auipc	ra,0xfffff
    800053cc:	498080e7          	jalr	1176(ra) # 80004860 <end_op>
    return -1;
    800053d0:	557d                	li	a0,-1
    800053d2:	bfc9                	j	800053a4 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800053d4:	854a                	mv	a0,s2
    800053d6:	ffffd097          	auipc	ra,0xffffd
    800053da:	b16080e7          	jalr	-1258(ra) # 80001eec <proc_pagetable>
    800053de:	8baa                	mv	s7,a0
    800053e0:	d945                	beqz	a0,80005390 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053e2:	e7042983          	lw	s3,-400(s0)
    800053e6:	e8845783          	lhu	a5,-376(s0)
    800053ea:	c7ad                	beqz	a5,80005454 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053ec:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053ee:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800053f0:	6c85                	lui	s9,0x1
    800053f2:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800053f6:	def43823          	sd	a5,-528(s0)
    800053fa:	a42d                	j	80005624 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800053fc:	00003517          	auipc	a0,0x3
    80005400:	37c50513          	addi	a0,a0,892 # 80008778 <syscalls+0x298>
    80005404:	ffffb097          	auipc	ra,0xffffb
    80005408:	13a080e7          	jalr	314(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000540c:	8756                	mv	a4,s5
    8000540e:	012d86bb          	addw	a3,s11,s2
    80005412:	4581                	li	a1,0
    80005414:	8526                	mv	a0,s1
    80005416:	fffff097          	auipc	ra,0xfffff
    8000541a:	cac080e7          	jalr	-852(ra) # 800040c2 <readi>
    8000541e:	2501                	sext.w	a0,a0
    80005420:	1aaa9963          	bne	s5,a0,800055d2 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005424:	6785                	lui	a5,0x1
    80005426:	0127893b          	addw	s2,a5,s2
    8000542a:	77fd                	lui	a5,0xfffff
    8000542c:	01478a3b          	addw	s4,a5,s4
    80005430:	1f897163          	bgeu	s2,s8,80005612 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005434:	02091593          	slli	a1,s2,0x20
    80005438:	9181                	srli	a1,a1,0x20
    8000543a:	95ea                	add	a1,a1,s10
    8000543c:	855e                	mv	a0,s7
    8000543e:	ffffc097          	auipc	ra,0xffffc
    80005442:	c54080e7          	jalr	-940(ra) # 80001092 <walkaddr>
    80005446:	862a                	mv	a2,a0
    if(pa == 0)
    80005448:	d955                	beqz	a0,800053fc <exec+0xf0>
      n = PGSIZE;
    8000544a:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000544c:	fd9a70e3          	bgeu	s4,s9,8000540c <exec+0x100>
      n = sz - i;
    80005450:	8ad2                	mv	s5,s4
    80005452:	bf6d                	j	8000540c <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005454:	4901                	li	s2,0
  iunlockput(ip);
    80005456:	8526                	mv	a0,s1
    80005458:	fffff097          	auipc	ra,0xfffff
    8000545c:	c18080e7          	jalr	-1000(ra) # 80004070 <iunlockput>
  end_op();
    80005460:	fffff097          	auipc	ra,0xfffff
    80005464:	400080e7          	jalr	1024(ra) # 80004860 <end_op>
  p = myproc();
    80005468:	ffffd097          	auipc	ra,0xffffd
    8000546c:	974080e7          	jalr	-1676(ra) # 80001ddc <myproc>
    80005470:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005472:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    80005476:	6785                	lui	a5,0x1
    80005478:	17fd                	addi	a5,a5,-1
    8000547a:	993e                	add	s2,s2,a5
    8000547c:	757d                	lui	a0,0xfffff
    8000547e:	00a977b3          	and	a5,s2,a0
    80005482:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005486:	6609                	lui	a2,0x2
    80005488:	963e                	add	a2,a2,a5
    8000548a:	85be                	mv	a1,a5
    8000548c:	855e                	mv	a0,s7
    8000548e:	ffffc097          	auipc	ra,0xffffc
    80005492:	fb8080e7          	jalr	-72(ra) # 80001446 <uvmalloc>
    80005496:	8b2a                	mv	s6,a0
  ip = 0;
    80005498:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000549a:	12050c63          	beqz	a0,800055d2 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000549e:	75f9                	lui	a1,0xffffe
    800054a0:	95aa                	add	a1,a1,a0
    800054a2:	855e                	mv	a0,s7
    800054a4:	ffffc097          	auipc	ra,0xffffc
    800054a8:	1c0080e7          	jalr	448(ra) # 80001664 <uvmclear>
  stackbase = sp - PGSIZE;
    800054ac:	7c7d                	lui	s8,0xfffff
    800054ae:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800054b0:	e0043783          	ld	a5,-512(s0)
    800054b4:	6388                	ld	a0,0(a5)
    800054b6:	c535                	beqz	a0,80005522 <exec+0x216>
    800054b8:	e9040993          	addi	s3,s0,-368
    800054bc:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800054c0:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800054c2:	ffffc097          	auipc	ra,0xffffc
    800054c6:	9c6080e7          	jalr	-1594(ra) # 80000e88 <strlen>
    800054ca:	2505                	addiw	a0,a0,1
    800054cc:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800054d0:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800054d4:	13896363          	bltu	s2,s8,800055fa <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800054d8:	e0043d83          	ld	s11,-512(s0)
    800054dc:	000dba03          	ld	s4,0(s11)
    800054e0:	8552                	mv	a0,s4
    800054e2:	ffffc097          	auipc	ra,0xffffc
    800054e6:	9a6080e7          	jalr	-1626(ra) # 80000e88 <strlen>
    800054ea:	0015069b          	addiw	a3,a0,1
    800054ee:	8652                	mv	a2,s4
    800054f0:	85ca                	mv	a1,s2
    800054f2:	855e                	mv	a0,s7
    800054f4:	ffffc097          	auipc	ra,0xffffc
    800054f8:	1a2080e7          	jalr	418(ra) # 80001696 <copyout>
    800054fc:	10054363          	bltz	a0,80005602 <exec+0x2f6>
    ustack[argc] = sp;
    80005500:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005504:	0485                	addi	s1,s1,1
    80005506:	008d8793          	addi	a5,s11,8
    8000550a:	e0f43023          	sd	a5,-512(s0)
    8000550e:	008db503          	ld	a0,8(s11)
    80005512:	c911                	beqz	a0,80005526 <exec+0x21a>
    if(argc >= MAXARG)
    80005514:	09a1                	addi	s3,s3,8
    80005516:	fb3c96e3          	bne	s9,s3,800054c2 <exec+0x1b6>
  sz = sz1;
    8000551a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000551e:	4481                	li	s1,0
    80005520:	a84d                	j	800055d2 <exec+0x2c6>
  sp = sz;
    80005522:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005524:	4481                	li	s1,0
  ustack[argc] = 0;
    80005526:	00349793          	slli	a5,s1,0x3
    8000552a:	f9040713          	addi	a4,s0,-112
    8000552e:	97ba                	add	a5,a5,a4
    80005530:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005534:	00148693          	addi	a3,s1,1
    80005538:	068e                	slli	a3,a3,0x3
    8000553a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000553e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005542:	01897663          	bgeu	s2,s8,8000554e <exec+0x242>
  sz = sz1;
    80005546:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000554a:	4481                	li	s1,0
    8000554c:	a059                	j	800055d2 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000554e:	e9040613          	addi	a2,s0,-368
    80005552:	85ca                	mv	a1,s2
    80005554:	855e                	mv	a0,s7
    80005556:	ffffc097          	auipc	ra,0xffffc
    8000555a:	140080e7          	jalr	320(ra) # 80001696 <copyout>
    8000555e:	0a054663          	bltz	a0,8000560a <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005562:	078ab783          	ld	a5,120(s5)
    80005566:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000556a:	df843783          	ld	a5,-520(s0)
    8000556e:	0007c703          	lbu	a4,0(a5)
    80005572:	cf11                	beqz	a4,8000558e <exec+0x282>
    80005574:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005576:	02f00693          	li	a3,47
    8000557a:	a039                	j	80005588 <exec+0x27c>
      last = s+1;
    8000557c:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005580:	0785                	addi	a5,a5,1
    80005582:	fff7c703          	lbu	a4,-1(a5)
    80005586:	c701                	beqz	a4,8000558e <exec+0x282>
    if(*s == '/')
    80005588:	fed71ce3          	bne	a4,a3,80005580 <exec+0x274>
    8000558c:	bfc5                	j	8000557c <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000558e:	4641                	li	a2,16
    80005590:	df843583          	ld	a1,-520(s0)
    80005594:	178a8513          	addi	a0,s5,376
    80005598:	ffffc097          	auipc	ra,0xffffc
    8000559c:	8be080e7          	jalr	-1858(ra) # 80000e56 <safestrcpy>
  oldpagetable = p->pagetable;
    800055a0:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    800055a4:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    800055a8:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800055ac:	078ab783          	ld	a5,120(s5)
    800055b0:	e6843703          	ld	a4,-408(s0)
    800055b4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800055b6:	078ab783          	ld	a5,120(s5)
    800055ba:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800055be:	85ea                	mv	a1,s10
    800055c0:	ffffd097          	auipc	ra,0xffffd
    800055c4:	9c8080e7          	jalr	-1592(ra) # 80001f88 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800055c8:	0004851b          	sext.w	a0,s1
    800055cc:	bbe1                	j	800053a4 <exec+0x98>
    800055ce:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800055d2:	e0843583          	ld	a1,-504(s0)
    800055d6:	855e                	mv	a0,s7
    800055d8:	ffffd097          	auipc	ra,0xffffd
    800055dc:	9b0080e7          	jalr	-1616(ra) # 80001f88 <proc_freepagetable>
  if(ip){
    800055e0:	da0498e3          	bnez	s1,80005390 <exec+0x84>
  return -1;
    800055e4:	557d                	li	a0,-1
    800055e6:	bb7d                	j	800053a4 <exec+0x98>
    800055e8:	e1243423          	sd	s2,-504(s0)
    800055ec:	b7dd                	j	800055d2 <exec+0x2c6>
    800055ee:	e1243423          	sd	s2,-504(s0)
    800055f2:	b7c5                	j	800055d2 <exec+0x2c6>
    800055f4:	e1243423          	sd	s2,-504(s0)
    800055f8:	bfe9                	j	800055d2 <exec+0x2c6>
  sz = sz1;
    800055fa:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055fe:	4481                	li	s1,0
    80005600:	bfc9                	j	800055d2 <exec+0x2c6>
  sz = sz1;
    80005602:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005606:	4481                	li	s1,0
    80005608:	b7e9                	j	800055d2 <exec+0x2c6>
  sz = sz1;
    8000560a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000560e:	4481                	li	s1,0
    80005610:	b7c9                	j	800055d2 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005612:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005616:	2b05                	addiw	s6,s6,1
    80005618:	0389899b          	addiw	s3,s3,56
    8000561c:	e8845783          	lhu	a5,-376(s0)
    80005620:	e2fb5be3          	bge	s6,a5,80005456 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005624:	2981                	sext.w	s3,s3
    80005626:	03800713          	li	a4,56
    8000562a:	86ce                	mv	a3,s3
    8000562c:	e1840613          	addi	a2,s0,-488
    80005630:	4581                	li	a1,0
    80005632:	8526                	mv	a0,s1
    80005634:	fffff097          	auipc	ra,0xfffff
    80005638:	a8e080e7          	jalr	-1394(ra) # 800040c2 <readi>
    8000563c:	03800793          	li	a5,56
    80005640:	f8f517e3          	bne	a0,a5,800055ce <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005644:	e1842783          	lw	a5,-488(s0)
    80005648:	4705                	li	a4,1
    8000564a:	fce796e3          	bne	a5,a4,80005616 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000564e:	e4043603          	ld	a2,-448(s0)
    80005652:	e3843783          	ld	a5,-456(s0)
    80005656:	f8f669e3          	bltu	a2,a5,800055e8 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000565a:	e2843783          	ld	a5,-472(s0)
    8000565e:	963e                	add	a2,a2,a5
    80005660:	f8f667e3          	bltu	a2,a5,800055ee <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005664:	85ca                	mv	a1,s2
    80005666:	855e                	mv	a0,s7
    80005668:	ffffc097          	auipc	ra,0xffffc
    8000566c:	dde080e7          	jalr	-546(ra) # 80001446 <uvmalloc>
    80005670:	e0a43423          	sd	a0,-504(s0)
    80005674:	d141                	beqz	a0,800055f4 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005676:	e2843d03          	ld	s10,-472(s0)
    8000567a:	df043783          	ld	a5,-528(s0)
    8000567e:	00fd77b3          	and	a5,s10,a5
    80005682:	fba1                	bnez	a5,800055d2 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005684:	e2042d83          	lw	s11,-480(s0)
    80005688:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000568c:	f80c03e3          	beqz	s8,80005612 <exec+0x306>
    80005690:	8a62                	mv	s4,s8
    80005692:	4901                	li	s2,0
    80005694:	b345                	j	80005434 <exec+0x128>

0000000080005696 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005696:	7179                	addi	sp,sp,-48
    80005698:	f406                	sd	ra,40(sp)
    8000569a:	f022                	sd	s0,32(sp)
    8000569c:	ec26                	sd	s1,24(sp)
    8000569e:	e84a                	sd	s2,16(sp)
    800056a0:	1800                	addi	s0,sp,48
    800056a2:	892e                	mv	s2,a1
    800056a4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800056a6:	fdc40593          	addi	a1,s0,-36
    800056aa:	ffffe097          	auipc	ra,0xffffe
    800056ae:	b76080e7          	jalr	-1162(ra) # 80003220 <argint>
    800056b2:	04054063          	bltz	a0,800056f2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800056b6:	fdc42703          	lw	a4,-36(s0)
    800056ba:	47bd                	li	a5,15
    800056bc:	02e7ed63          	bltu	a5,a4,800056f6 <argfd+0x60>
    800056c0:	ffffc097          	auipc	ra,0xffffc
    800056c4:	71c080e7          	jalr	1820(ra) # 80001ddc <myproc>
    800056c8:	fdc42703          	lw	a4,-36(s0)
    800056cc:	01e70793          	addi	a5,a4,30
    800056d0:	078e                	slli	a5,a5,0x3
    800056d2:	953e                	add	a0,a0,a5
    800056d4:	611c                	ld	a5,0(a0)
    800056d6:	c395                	beqz	a5,800056fa <argfd+0x64>
    return -1;
  if(pfd)
    800056d8:	00090463          	beqz	s2,800056e0 <argfd+0x4a>
    *pfd = fd;
    800056dc:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800056e0:	4501                	li	a0,0
  if(pf)
    800056e2:	c091                	beqz	s1,800056e6 <argfd+0x50>
    *pf = f;
    800056e4:	e09c                	sd	a5,0(s1)
}
    800056e6:	70a2                	ld	ra,40(sp)
    800056e8:	7402                	ld	s0,32(sp)
    800056ea:	64e2                	ld	s1,24(sp)
    800056ec:	6942                	ld	s2,16(sp)
    800056ee:	6145                	addi	sp,sp,48
    800056f0:	8082                	ret
    return -1;
    800056f2:	557d                	li	a0,-1
    800056f4:	bfcd                	j	800056e6 <argfd+0x50>
    return -1;
    800056f6:	557d                	li	a0,-1
    800056f8:	b7fd                	j	800056e6 <argfd+0x50>
    800056fa:	557d                	li	a0,-1
    800056fc:	b7ed                	j	800056e6 <argfd+0x50>

00000000800056fe <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800056fe:	1101                	addi	sp,sp,-32
    80005700:	ec06                	sd	ra,24(sp)
    80005702:	e822                	sd	s0,16(sp)
    80005704:	e426                	sd	s1,8(sp)
    80005706:	1000                	addi	s0,sp,32
    80005708:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000570a:	ffffc097          	auipc	ra,0xffffc
    8000570e:	6d2080e7          	jalr	1746(ra) # 80001ddc <myproc>
    80005712:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005714:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    80005718:	4501                	li	a0,0
    8000571a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000571c:	6398                	ld	a4,0(a5)
    8000571e:	cb19                	beqz	a4,80005734 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005720:	2505                	addiw	a0,a0,1
    80005722:	07a1                	addi	a5,a5,8
    80005724:	fed51ce3          	bne	a0,a3,8000571c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005728:	557d                	li	a0,-1
}
    8000572a:	60e2                	ld	ra,24(sp)
    8000572c:	6442                	ld	s0,16(sp)
    8000572e:	64a2                	ld	s1,8(sp)
    80005730:	6105                	addi	sp,sp,32
    80005732:	8082                	ret
      p->ofile[fd] = f;
    80005734:	01e50793          	addi	a5,a0,30
    80005738:	078e                	slli	a5,a5,0x3
    8000573a:	963e                	add	a2,a2,a5
    8000573c:	e204                	sd	s1,0(a2)
      return fd;
    8000573e:	b7f5                	j	8000572a <fdalloc+0x2c>

0000000080005740 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005740:	715d                	addi	sp,sp,-80
    80005742:	e486                	sd	ra,72(sp)
    80005744:	e0a2                	sd	s0,64(sp)
    80005746:	fc26                	sd	s1,56(sp)
    80005748:	f84a                	sd	s2,48(sp)
    8000574a:	f44e                	sd	s3,40(sp)
    8000574c:	f052                	sd	s4,32(sp)
    8000574e:	ec56                	sd	s5,24(sp)
    80005750:	0880                	addi	s0,sp,80
    80005752:	89ae                	mv	s3,a1
    80005754:	8ab2                	mv	s5,a2
    80005756:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005758:	fb040593          	addi	a1,s0,-80
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	e86080e7          	jalr	-378(ra) # 800045e2 <nameiparent>
    80005764:	892a                	mv	s2,a0
    80005766:	12050f63          	beqz	a0,800058a4 <create+0x164>
    return 0;

  ilock(dp);
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	6a4080e7          	jalr	1700(ra) # 80003e0e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005772:	4601                	li	a2,0
    80005774:	fb040593          	addi	a1,s0,-80
    80005778:	854a                	mv	a0,s2
    8000577a:	fffff097          	auipc	ra,0xfffff
    8000577e:	b78080e7          	jalr	-1160(ra) # 800042f2 <dirlookup>
    80005782:	84aa                	mv	s1,a0
    80005784:	c921                	beqz	a0,800057d4 <create+0x94>
    iunlockput(dp);
    80005786:	854a                	mv	a0,s2
    80005788:	fffff097          	auipc	ra,0xfffff
    8000578c:	8e8080e7          	jalr	-1816(ra) # 80004070 <iunlockput>
    ilock(ip);
    80005790:	8526                	mv	a0,s1
    80005792:	ffffe097          	auipc	ra,0xffffe
    80005796:	67c080e7          	jalr	1660(ra) # 80003e0e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000579a:	2981                	sext.w	s3,s3
    8000579c:	4789                	li	a5,2
    8000579e:	02f99463          	bne	s3,a5,800057c6 <create+0x86>
    800057a2:	0444d783          	lhu	a5,68(s1)
    800057a6:	37f9                	addiw	a5,a5,-2
    800057a8:	17c2                	slli	a5,a5,0x30
    800057aa:	93c1                	srli	a5,a5,0x30
    800057ac:	4705                	li	a4,1
    800057ae:	00f76c63          	bltu	a4,a5,800057c6 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800057b2:	8526                	mv	a0,s1
    800057b4:	60a6                	ld	ra,72(sp)
    800057b6:	6406                	ld	s0,64(sp)
    800057b8:	74e2                	ld	s1,56(sp)
    800057ba:	7942                	ld	s2,48(sp)
    800057bc:	79a2                	ld	s3,40(sp)
    800057be:	7a02                	ld	s4,32(sp)
    800057c0:	6ae2                	ld	s5,24(sp)
    800057c2:	6161                	addi	sp,sp,80
    800057c4:	8082                	ret
    iunlockput(ip);
    800057c6:	8526                	mv	a0,s1
    800057c8:	fffff097          	auipc	ra,0xfffff
    800057cc:	8a8080e7          	jalr	-1880(ra) # 80004070 <iunlockput>
    return 0;
    800057d0:	4481                	li	s1,0
    800057d2:	b7c5                	j	800057b2 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800057d4:	85ce                	mv	a1,s3
    800057d6:	00092503          	lw	a0,0(s2)
    800057da:	ffffe097          	auipc	ra,0xffffe
    800057de:	49c080e7          	jalr	1180(ra) # 80003c76 <ialloc>
    800057e2:	84aa                	mv	s1,a0
    800057e4:	c529                	beqz	a0,8000582e <create+0xee>
  ilock(ip);
    800057e6:	ffffe097          	auipc	ra,0xffffe
    800057ea:	628080e7          	jalr	1576(ra) # 80003e0e <ilock>
  ip->major = major;
    800057ee:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800057f2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800057f6:	4785                	li	a5,1
    800057f8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057fc:	8526                	mv	a0,s1
    800057fe:	ffffe097          	auipc	ra,0xffffe
    80005802:	546080e7          	jalr	1350(ra) # 80003d44 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005806:	2981                	sext.w	s3,s3
    80005808:	4785                	li	a5,1
    8000580a:	02f98a63          	beq	s3,a5,8000583e <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000580e:	40d0                	lw	a2,4(s1)
    80005810:	fb040593          	addi	a1,s0,-80
    80005814:	854a                	mv	a0,s2
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	cec080e7          	jalr	-788(ra) # 80004502 <dirlink>
    8000581e:	06054b63          	bltz	a0,80005894 <create+0x154>
  iunlockput(dp);
    80005822:	854a                	mv	a0,s2
    80005824:	fffff097          	auipc	ra,0xfffff
    80005828:	84c080e7          	jalr	-1972(ra) # 80004070 <iunlockput>
  return ip;
    8000582c:	b759                	j	800057b2 <create+0x72>
    panic("create: ialloc");
    8000582e:	00003517          	auipc	a0,0x3
    80005832:	f6a50513          	addi	a0,a0,-150 # 80008798 <syscalls+0x2b8>
    80005836:	ffffb097          	auipc	ra,0xffffb
    8000583a:	d08080e7          	jalr	-760(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000583e:	04a95783          	lhu	a5,74(s2)
    80005842:	2785                	addiw	a5,a5,1
    80005844:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005848:	854a                	mv	a0,s2
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	4fa080e7          	jalr	1274(ra) # 80003d44 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005852:	40d0                	lw	a2,4(s1)
    80005854:	00003597          	auipc	a1,0x3
    80005858:	f5458593          	addi	a1,a1,-172 # 800087a8 <syscalls+0x2c8>
    8000585c:	8526                	mv	a0,s1
    8000585e:	fffff097          	auipc	ra,0xfffff
    80005862:	ca4080e7          	jalr	-860(ra) # 80004502 <dirlink>
    80005866:	00054f63          	bltz	a0,80005884 <create+0x144>
    8000586a:	00492603          	lw	a2,4(s2)
    8000586e:	00003597          	auipc	a1,0x3
    80005872:	f4258593          	addi	a1,a1,-190 # 800087b0 <syscalls+0x2d0>
    80005876:	8526                	mv	a0,s1
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	c8a080e7          	jalr	-886(ra) # 80004502 <dirlink>
    80005880:	f80557e3          	bgez	a0,8000580e <create+0xce>
      panic("create dots");
    80005884:	00003517          	auipc	a0,0x3
    80005888:	f3450513          	addi	a0,a0,-204 # 800087b8 <syscalls+0x2d8>
    8000588c:	ffffb097          	auipc	ra,0xffffb
    80005890:	cb2080e7          	jalr	-846(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005894:	00003517          	auipc	a0,0x3
    80005898:	f3450513          	addi	a0,a0,-204 # 800087c8 <syscalls+0x2e8>
    8000589c:	ffffb097          	auipc	ra,0xffffb
    800058a0:	ca2080e7          	jalr	-862(ra) # 8000053e <panic>
    return 0;
    800058a4:	84aa                	mv	s1,a0
    800058a6:	b731                	j	800057b2 <create+0x72>

00000000800058a8 <sys_dup>:
{
    800058a8:	7179                	addi	sp,sp,-48
    800058aa:	f406                	sd	ra,40(sp)
    800058ac:	f022                	sd	s0,32(sp)
    800058ae:	ec26                	sd	s1,24(sp)
    800058b0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800058b2:	fd840613          	addi	a2,s0,-40
    800058b6:	4581                	li	a1,0
    800058b8:	4501                	li	a0,0
    800058ba:	00000097          	auipc	ra,0x0
    800058be:	ddc080e7          	jalr	-548(ra) # 80005696 <argfd>
    return -1;
    800058c2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800058c4:	02054363          	bltz	a0,800058ea <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800058c8:	fd843503          	ld	a0,-40(s0)
    800058cc:	00000097          	auipc	ra,0x0
    800058d0:	e32080e7          	jalr	-462(ra) # 800056fe <fdalloc>
    800058d4:	84aa                	mv	s1,a0
    return -1;
    800058d6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800058d8:	00054963          	bltz	a0,800058ea <sys_dup+0x42>
  filedup(f);
    800058dc:	fd843503          	ld	a0,-40(s0)
    800058e0:	fffff097          	auipc	ra,0xfffff
    800058e4:	37a080e7          	jalr	890(ra) # 80004c5a <filedup>
  return fd;
    800058e8:	87a6                	mv	a5,s1
}
    800058ea:	853e                	mv	a0,a5
    800058ec:	70a2                	ld	ra,40(sp)
    800058ee:	7402                	ld	s0,32(sp)
    800058f0:	64e2                	ld	s1,24(sp)
    800058f2:	6145                	addi	sp,sp,48
    800058f4:	8082                	ret

00000000800058f6 <sys_read>:
{
    800058f6:	7179                	addi	sp,sp,-48
    800058f8:	f406                	sd	ra,40(sp)
    800058fa:	f022                	sd	s0,32(sp)
    800058fc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058fe:	fe840613          	addi	a2,s0,-24
    80005902:	4581                	li	a1,0
    80005904:	4501                	li	a0,0
    80005906:	00000097          	auipc	ra,0x0
    8000590a:	d90080e7          	jalr	-624(ra) # 80005696 <argfd>
    return -1;
    8000590e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005910:	04054163          	bltz	a0,80005952 <sys_read+0x5c>
    80005914:	fe440593          	addi	a1,s0,-28
    80005918:	4509                	li	a0,2
    8000591a:	ffffe097          	auipc	ra,0xffffe
    8000591e:	906080e7          	jalr	-1786(ra) # 80003220 <argint>
    return -1;
    80005922:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005924:	02054763          	bltz	a0,80005952 <sys_read+0x5c>
    80005928:	fd840593          	addi	a1,s0,-40
    8000592c:	4505                	li	a0,1
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	914080e7          	jalr	-1772(ra) # 80003242 <argaddr>
    return -1;
    80005936:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005938:	00054d63          	bltz	a0,80005952 <sys_read+0x5c>
  return fileread(f, p, n);
    8000593c:	fe442603          	lw	a2,-28(s0)
    80005940:	fd843583          	ld	a1,-40(s0)
    80005944:	fe843503          	ld	a0,-24(s0)
    80005948:	fffff097          	auipc	ra,0xfffff
    8000594c:	49e080e7          	jalr	1182(ra) # 80004de6 <fileread>
    80005950:	87aa                	mv	a5,a0
}
    80005952:	853e                	mv	a0,a5
    80005954:	70a2                	ld	ra,40(sp)
    80005956:	7402                	ld	s0,32(sp)
    80005958:	6145                	addi	sp,sp,48
    8000595a:	8082                	ret

000000008000595c <sys_write>:
{
    8000595c:	7179                	addi	sp,sp,-48
    8000595e:	f406                	sd	ra,40(sp)
    80005960:	f022                	sd	s0,32(sp)
    80005962:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005964:	fe840613          	addi	a2,s0,-24
    80005968:	4581                	li	a1,0
    8000596a:	4501                	li	a0,0
    8000596c:	00000097          	auipc	ra,0x0
    80005970:	d2a080e7          	jalr	-726(ra) # 80005696 <argfd>
    return -1;
    80005974:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005976:	04054163          	bltz	a0,800059b8 <sys_write+0x5c>
    8000597a:	fe440593          	addi	a1,s0,-28
    8000597e:	4509                	li	a0,2
    80005980:	ffffe097          	auipc	ra,0xffffe
    80005984:	8a0080e7          	jalr	-1888(ra) # 80003220 <argint>
    return -1;
    80005988:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000598a:	02054763          	bltz	a0,800059b8 <sys_write+0x5c>
    8000598e:	fd840593          	addi	a1,s0,-40
    80005992:	4505                	li	a0,1
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	8ae080e7          	jalr	-1874(ra) # 80003242 <argaddr>
    return -1;
    8000599c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000599e:	00054d63          	bltz	a0,800059b8 <sys_write+0x5c>
  return filewrite(f, p, n);
    800059a2:	fe442603          	lw	a2,-28(s0)
    800059a6:	fd843583          	ld	a1,-40(s0)
    800059aa:	fe843503          	ld	a0,-24(s0)
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	4fa080e7          	jalr	1274(ra) # 80004ea8 <filewrite>
    800059b6:	87aa                	mv	a5,a0
}
    800059b8:	853e                	mv	a0,a5
    800059ba:	70a2                	ld	ra,40(sp)
    800059bc:	7402                	ld	s0,32(sp)
    800059be:	6145                	addi	sp,sp,48
    800059c0:	8082                	ret

00000000800059c2 <sys_close>:
{
    800059c2:	1101                	addi	sp,sp,-32
    800059c4:	ec06                	sd	ra,24(sp)
    800059c6:	e822                	sd	s0,16(sp)
    800059c8:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800059ca:	fe040613          	addi	a2,s0,-32
    800059ce:	fec40593          	addi	a1,s0,-20
    800059d2:	4501                	li	a0,0
    800059d4:	00000097          	auipc	ra,0x0
    800059d8:	cc2080e7          	jalr	-830(ra) # 80005696 <argfd>
    return -1;
    800059dc:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800059de:	02054463          	bltz	a0,80005a06 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800059e2:	ffffc097          	auipc	ra,0xffffc
    800059e6:	3fa080e7          	jalr	1018(ra) # 80001ddc <myproc>
    800059ea:	fec42783          	lw	a5,-20(s0)
    800059ee:	07f9                	addi	a5,a5,30
    800059f0:	078e                	slli	a5,a5,0x3
    800059f2:	97aa                	add	a5,a5,a0
    800059f4:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800059f8:	fe043503          	ld	a0,-32(s0)
    800059fc:	fffff097          	auipc	ra,0xfffff
    80005a00:	2b0080e7          	jalr	688(ra) # 80004cac <fileclose>
  return 0;
    80005a04:	4781                	li	a5,0
}
    80005a06:	853e                	mv	a0,a5
    80005a08:	60e2                	ld	ra,24(sp)
    80005a0a:	6442                	ld	s0,16(sp)
    80005a0c:	6105                	addi	sp,sp,32
    80005a0e:	8082                	ret

0000000080005a10 <sys_fstat>:
{
    80005a10:	1101                	addi	sp,sp,-32
    80005a12:	ec06                	sd	ra,24(sp)
    80005a14:	e822                	sd	s0,16(sp)
    80005a16:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a18:	fe840613          	addi	a2,s0,-24
    80005a1c:	4581                	li	a1,0
    80005a1e:	4501                	li	a0,0
    80005a20:	00000097          	auipc	ra,0x0
    80005a24:	c76080e7          	jalr	-906(ra) # 80005696 <argfd>
    return -1;
    80005a28:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a2a:	02054563          	bltz	a0,80005a54 <sys_fstat+0x44>
    80005a2e:	fe040593          	addi	a1,s0,-32
    80005a32:	4505                	li	a0,1
    80005a34:	ffffe097          	auipc	ra,0xffffe
    80005a38:	80e080e7          	jalr	-2034(ra) # 80003242 <argaddr>
    return -1;
    80005a3c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a3e:	00054b63          	bltz	a0,80005a54 <sys_fstat+0x44>
  return filestat(f, st);
    80005a42:	fe043583          	ld	a1,-32(s0)
    80005a46:	fe843503          	ld	a0,-24(s0)
    80005a4a:	fffff097          	auipc	ra,0xfffff
    80005a4e:	32a080e7          	jalr	810(ra) # 80004d74 <filestat>
    80005a52:	87aa                	mv	a5,a0
}
    80005a54:	853e                	mv	a0,a5
    80005a56:	60e2                	ld	ra,24(sp)
    80005a58:	6442                	ld	s0,16(sp)
    80005a5a:	6105                	addi	sp,sp,32
    80005a5c:	8082                	ret

0000000080005a5e <sys_link>:
{
    80005a5e:	7169                	addi	sp,sp,-304
    80005a60:	f606                	sd	ra,296(sp)
    80005a62:	f222                	sd	s0,288(sp)
    80005a64:	ee26                	sd	s1,280(sp)
    80005a66:	ea4a                	sd	s2,272(sp)
    80005a68:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a6a:	08000613          	li	a2,128
    80005a6e:	ed040593          	addi	a1,s0,-304
    80005a72:	4501                	li	a0,0
    80005a74:	ffffd097          	auipc	ra,0xffffd
    80005a78:	7f0080e7          	jalr	2032(ra) # 80003264 <argstr>
    return -1;
    80005a7c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a7e:	10054e63          	bltz	a0,80005b9a <sys_link+0x13c>
    80005a82:	08000613          	li	a2,128
    80005a86:	f5040593          	addi	a1,s0,-176
    80005a8a:	4505                	li	a0,1
    80005a8c:	ffffd097          	auipc	ra,0xffffd
    80005a90:	7d8080e7          	jalr	2008(ra) # 80003264 <argstr>
    return -1;
    80005a94:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a96:	10054263          	bltz	a0,80005b9a <sys_link+0x13c>
  begin_op();
    80005a9a:	fffff097          	auipc	ra,0xfffff
    80005a9e:	d46080e7          	jalr	-698(ra) # 800047e0 <begin_op>
  if((ip = namei(old)) == 0){
    80005aa2:	ed040513          	addi	a0,s0,-304
    80005aa6:	fffff097          	auipc	ra,0xfffff
    80005aaa:	b1e080e7          	jalr	-1250(ra) # 800045c4 <namei>
    80005aae:	84aa                	mv	s1,a0
    80005ab0:	c551                	beqz	a0,80005b3c <sys_link+0xde>
  ilock(ip);
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	35c080e7          	jalr	860(ra) # 80003e0e <ilock>
  if(ip->type == T_DIR){
    80005aba:	04449703          	lh	a4,68(s1)
    80005abe:	4785                	li	a5,1
    80005ac0:	08f70463          	beq	a4,a5,80005b48 <sys_link+0xea>
  ip->nlink++;
    80005ac4:	04a4d783          	lhu	a5,74(s1)
    80005ac8:	2785                	addiw	a5,a5,1
    80005aca:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005ace:	8526                	mv	a0,s1
    80005ad0:	ffffe097          	auipc	ra,0xffffe
    80005ad4:	274080e7          	jalr	628(ra) # 80003d44 <iupdate>
  iunlock(ip);
    80005ad8:	8526                	mv	a0,s1
    80005ada:	ffffe097          	auipc	ra,0xffffe
    80005ade:	3f6080e7          	jalr	1014(ra) # 80003ed0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005ae2:	fd040593          	addi	a1,s0,-48
    80005ae6:	f5040513          	addi	a0,s0,-176
    80005aea:	fffff097          	auipc	ra,0xfffff
    80005aee:	af8080e7          	jalr	-1288(ra) # 800045e2 <nameiparent>
    80005af2:	892a                	mv	s2,a0
    80005af4:	c935                	beqz	a0,80005b68 <sys_link+0x10a>
  ilock(dp);
    80005af6:	ffffe097          	auipc	ra,0xffffe
    80005afa:	318080e7          	jalr	792(ra) # 80003e0e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005afe:	00092703          	lw	a4,0(s2)
    80005b02:	409c                	lw	a5,0(s1)
    80005b04:	04f71d63          	bne	a4,a5,80005b5e <sys_link+0x100>
    80005b08:	40d0                	lw	a2,4(s1)
    80005b0a:	fd040593          	addi	a1,s0,-48
    80005b0e:	854a                	mv	a0,s2
    80005b10:	fffff097          	auipc	ra,0xfffff
    80005b14:	9f2080e7          	jalr	-1550(ra) # 80004502 <dirlink>
    80005b18:	04054363          	bltz	a0,80005b5e <sys_link+0x100>
  iunlockput(dp);
    80005b1c:	854a                	mv	a0,s2
    80005b1e:	ffffe097          	auipc	ra,0xffffe
    80005b22:	552080e7          	jalr	1362(ra) # 80004070 <iunlockput>
  iput(ip);
    80005b26:	8526                	mv	a0,s1
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	4a0080e7          	jalr	1184(ra) # 80003fc8 <iput>
  end_op();
    80005b30:	fffff097          	auipc	ra,0xfffff
    80005b34:	d30080e7          	jalr	-720(ra) # 80004860 <end_op>
  return 0;
    80005b38:	4781                	li	a5,0
    80005b3a:	a085                	j	80005b9a <sys_link+0x13c>
    end_op();
    80005b3c:	fffff097          	auipc	ra,0xfffff
    80005b40:	d24080e7          	jalr	-732(ra) # 80004860 <end_op>
    return -1;
    80005b44:	57fd                	li	a5,-1
    80005b46:	a891                	j	80005b9a <sys_link+0x13c>
    iunlockput(ip);
    80005b48:	8526                	mv	a0,s1
    80005b4a:	ffffe097          	auipc	ra,0xffffe
    80005b4e:	526080e7          	jalr	1318(ra) # 80004070 <iunlockput>
    end_op();
    80005b52:	fffff097          	auipc	ra,0xfffff
    80005b56:	d0e080e7          	jalr	-754(ra) # 80004860 <end_op>
    return -1;
    80005b5a:	57fd                	li	a5,-1
    80005b5c:	a83d                	j	80005b9a <sys_link+0x13c>
    iunlockput(dp);
    80005b5e:	854a                	mv	a0,s2
    80005b60:	ffffe097          	auipc	ra,0xffffe
    80005b64:	510080e7          	jalr	1296(ra) # 80004070 <iunlockput>
  ilock(ip);
    80005b68:	8526                	mv	a0,s1
    80005b6a:	ffffe097          	auipc	ra,0xffffe
    80005b6e:	2a4080e7          	jalr	676(ra) # 80003e0e <ilock>
  ip->nlink--;
    80005b72:	04a4d783          	lhu	a5,74(s1)
    80005b76:	37fd                	addiw	a5,a5,-1
    80005b78:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b7c:	8526                	mv	a0,s1
    80005b7e:	ffffe097          	auipc	ra,0xffffe
    80005b82:	1c6080e7          	jalr	454(ra) # 80003d44 <iupdate>
  iunlockput(ip);
    80005b86:	8526                	mv	a0,s1
    80005b88:	ffffe097          	auipc	ra,0xffffe
    80005b8c:	4e8080e7          	jalr	1256(ra) # 80004070 <iunlockput>
  end_op();
    80005b90:	fffff097          	auipc	ra,0xfffff
    80005b94:	cd0080e7          	jalr	-816(ra) # 80004860 <end_op>
  return -1;
    80005b98:	57fd                	li	a5,-1
}
    80005b9a:	853e                	mv	a0,a5
    80005b9c:	70b2                	ld	ra,296(sp)
    80005b9e:	7412                	ld	s0,288(sp)
    80005ba0:	64f2                	ld	s1,280(sp)
    80005ba2:	6952                	ld	s2,272(sp)
    80005ba4:	6155                	addi	sp,sp,304
    80005ba6:	8082                	ret

0000000080005ba8 <sys_unlink>:
{
    80005ba8:	7151                	addi	sp,sp,-240
    80005baa:	f586                	sd	ra,232(sp)
    80005bac:	f1a2                	sd	s0,224(sp)
    80005bae:	eda6                	sd	s1,216(sp)
    80005bb0:	e9ca                	sd	s2,208(sp)
    80005bb2:	e5ce                	sd	s3,200(sp)
    80005bb4:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005bb6:	08000613          	li	a2,128
    80005bba:	f3040593          	addi	a1,s0,-208
    80005bbe:	4501                	li	a0,0
    80005bc0:	ffffd097          	auipc	ra,0xffffd
    80005bc4:	6a4080e7          	jalr	1700(ra) # 80003264 <argstr>
    80005bc8:	18054163          	bltz	a0,80005d4a <sys_unlink+0x1a2>
  begin_op();
    80005bcc:	fffff097          	auipc	ra,0xfffff
    80005bd0:	c14080e7          	jalr	-1004(ra) # 800047e0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005bd4:	fb040593          	addi	a1,s0,-80
    80005bd8:	f3040513          	addi	a0,s0,-208
    80005bdc:	fffff097          	auipc	ra,0xfffff
    80005be0:	a06080e7          	jalr	-1530(ra) # 800045e2 <nameiparent>
    80005be4:	84aa                	mv	s1,a0
    80005be6:	c979                	beqz	a0,80005cbc <sys_unlink+0x114>
  ilock(dp);
    80005be8:	ffffe097          	auipc	ra,0xffffe
    80005bec:	226080e7          	jalr	550(ra) # 80003e0e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005bf0:	00003597          	auipc	a1,0x3
    80005bf4:	bb858593          	addi	a1,a1,-1096 # 800087a8 <syscalls+0x2c8>
    80005bf8:	fb040513          	addi	a0,s0,-80
    80005bfc:	ffffe097          	auipc	ra,0xffffe
    80005c00:	6dc080e7          	jalr	1756(ra) # 800042d8 <namecmp>
    80005c04:	14050a63          	beqz	a0,80005d58 <sys_unlink+0x1b0>
    80005c08:	00003597          	auipc	a1,0x3
    80005c0c:	ba858593          	addi	a1,a1,-1112 # 800087b0 <syscalls+0x2d0>
    80005c10:	fb040513          	addi	a0,s0,-80
    80005c14:	ffffe097          	auipc	ra,0xffffe
    80005c18:	6c4080e7          	jalr	1732(ra) # 800042d8 <namecmp>
    80005c1c:	12050e63          	beqz	a0,80005d58 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005c20:	f2c40613          	addi	a2,s0,-212
    80005c24:	fb040593          	addi	a1,s0,-80
    80005c28:	8526                	mv	a0,s1
    80005c2a:	ffffe097          	auipc	ra,0xffffe
    80005c2e:	6c8080e7          	jalr	1736(ra) # 800042f2 <dirlookup>
    80005c32:	892a                	mv	s2,a0
    80005c34:	12050263          	beqz	a0,80005d58 <sys_unlink+0x1b0>
  ilock(ip);
    80005c38:	ffffe097          	auipc	ra,0xffffe
    80005c3c:	1d6080e7          	jalr	470(ra) # 80003e0e <ilock>
  if(ip->nlink < 1)
    80005c40:	04a91783          	lh	a5,74(s2)
    80005c44:	08f05263          	blez	a5,80005cc8 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c48:	04491703          	lh	a4,68(s2)
    80005c4c:	4785                	li	a5,1
    80005c4e:	08f70563          	beq	a4,a5,80005cd8 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c52:	4641                	li	a2,16
    80005c54:	4581                	li	a1,0
    80005c56:	fc040513          	addi	a0,s0,-64
    80005c5a:	ffffb097          	auipc	ra,0xffffb
    80005c5e:	0aa080e7          	jalr	170(ra) # 80000d04 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c62:	4741                	li	a4,16
    80005c64:	f2c42683          	lw	a3,-212(s0)
    80005c68:	fc040613          	addi	a2,s0,-64
    80005c6c:	4581                	li	a1,0
    80005c6e:	8526                	mv	a0,s1
    80005c70:	ffffe097          	auipc	ra,0xffffe
    80005c74:	54a080e7          	jalr	1354(ra) # 800041ba <writei>
    80005c78:	47c1                	li	a5,16
    80005c7a:	0af51563          	bne	a0,a5,80005d24 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005c7e:	04491703          	lh	a4,68(s2)
    80005c82:	4785                	li	a5,1
    80005c84:	0af70863          	beq	a4,a5,80005d34 <sys_unlink+0x18c>
  iunlockput(dp);
    80005c88:	8526                	mv	a0,s1
    80005c8a:	ffffe097          	auipc	ra,0xffffe
    80005c8e:	3e6080e7          	jalr	998(ra) # 80004070 <iunlockput>
  ip->nlink--;
    80005c92:	04a95783          	lhu	a5,74(s2)
    80005c96:	37fd                	addiw	a5,a5,-1
    80005c98:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c9c:	854a                	mv	a0,s2
    80005c9e:	ffffe097          	auipc	ra,0xffffe
    80005ca2:	0a6080e7          	jalr	166(ra) # 80003d44 <iupdate>
  iunlockput(ip);
    80005ca6:	854a                	mv	a0,s2
    80005ca8:	ffffe097          	auipc	ra,0xffffe
    80005cac:	3c8080e7          	jalr	968(ra) # 80004070 <iunlockput>
  end_op();
    80005cb0:	fffff097          	auipc	ra,0xfffff
    80005cb4:	bb0080e7          	jalr	-1104(ra) # 80004860 <end_op>
  return 0;
    80005cb8:	4501                	li	a0,0
    80005cba:	a84d                	j	80005d6c <sys_unlink+0x1c4>
    end_op();
    80005cbc:	fffff097          	auipc	ra,0xfffff
    80005cc0:	ba4080e7          	jalr	-1116(ra) # 80004860 <end_op>
    return -1;
    80005cc4:	557d                	li	a0,-1
    80005cc6:	a05d                	j	80005d6c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005cc8:	00003517          	auipc	a0,0x3
    80005ccc:	b1050513          	addi	a0,a0,-1264 # 800087d8 <syscalls+0x2f8>
    80005cd0:	ffffb097          	auipc	ra,0xffffb
    80005cd4:	86e080e7          	jalr	-1938(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005cd8:	04c92703          	lw	a4,76(s2)
    80005cdc:	02000793          	li	a5,32
    80005ce0:	f6e7f9e3          	bgeu	a5,a4,80005c52 <sys_unlink+0xaa>
    80005ce4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ce8:	4741                	li	a4,16
    80005cea:	86ce                	mv	a3,s3
    80005cec:	f1840613          	addi	a2,s0,-232
    80005cf0:	4581                	li	a1,0
    80005cf2:	854a                	mv	a0,s2
    80005cf4:	ffffe097          	auipc	ra,0xffffe
    80005cf8:	3ce080e7          	jalr	974(ra) # 800040c2 <readi>
    80005cfc:	47c1                	li	a5,16
    80005cfe:	00f51b63          	bne	a0,a5,80005d14 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005d02:	f1845783          	lhu	a5,-232(s0)
    80005d06:	e7a1                	bnez	a5,80005d4e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d08:	29c1                	addiw	s3,s3,16
    80005d0a:	04c92783          	lw	a5,76(s2)
    80005d0e:	fcf9ede3          	bltu	s3,a5,80005ce8 <sys_unlink+0x140>
    80005d12:	b781                	j	80005c52 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005d14:	00003517          	auipc	a0,0x3
    80005d18:	adc50513          	addi	a0,a0,-1316 # 800087f0 <syscalls+0x310>
    80005d1c:	ffffb097          	auipc	ra,0xffffb
    80005d20:	822080e7          	jalr	-2014(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005d24:	00003517          	auipc	a0,0x3
    80005d28:	ae450513          	addi	a0,a0,-1308 # 80008808 <syscalls+0x328>
    80005d2c:	ffffb097          	auipc	ra,0xffffb
    80005d30:	812080e7          	jalr	-2030(ra) # 8000053e <panic>
    dp->nlink--;
    80005d34:	04a4d783          	lhu	a5,74(s1)
    80005d38:	37fd                	addiw	a5,a5,-1
    80005d3a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d3e:	8526                	mv	a0,s1
    80005d40:	ffffe097          	auipc	ra,0xffffe
    80005d44:	004080e7          	jalr	4(ra) # 80003d44 <iupdate>
    80005d48:	b781                	j	80005c88 <sys_unlink+0xe0>
    return -1;
    80005d4a:	557d                	li	a0,-1
    80005d4c:	a005                	j	80005d6c <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d4e:	854a                	mv	a0,s2
    80005d50:	ffffe097          	auipc	ra,0xffffe
    80005d54:	320080e7          	jalr	800(ra) # 80004070 <iunlockput>
  iunlockput(dp);
    80005d58:	8526                	mv	a0,s1
    80005d5a:	ffffe097          	auipc	ra,0xffffe
    80005d5e:	316080e7          	jalr	790(ra) # 80004070 <iunlockput>
  end_op();
    80005d62:	fffff097          	auipc	ra,0xfffff
    80005d66:	afe080e7          	jalr	-1282(ra) # 80004860 <end_op>
  return -1;
    80005d6a:	557d                	li	a0,-1
}
    80005d6c:	70ae                	ld	ra,232(sp)
    80005d6e:	740e                	ld	s0,224(sp)
    80005d70:	64ee                	ld	s1,216(sp)
    80005d72:	694e                	ld	s2,208(sp)
    80005d74:	69ae                	ld	s3,200(sp)
    80005d76:	616d                	addi	sp,sp,240
    80005d78:	8082                	ret

0000000080005d7a <sys_open>:

uint64
sys_open(void)
{
    80005d7a:	7131                	addi	sp,sp,-192
    80005d7c:	fd06                	sd	ra,184(sp)
    80005d7e:	f922                	sd	s0,176(sp)
    80005d80:	f526                	sd	s1,168(sp)
    80005d82:	f14a                	sd	s2,160(sp)
    80005d84:	ed4e                	sd	s3,152(sp)
    80005d86:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d88:	08000613          	li	a2,128
    80005d8c:	f5040593          	addi	a1,s0,-176
    80005d90:	4501                	li	a0,0
    80005d92:	ffffd097          	auipc	ra,0xffffd
    80005d96:	4d2080e7          	jalr	1234(ra) # 80003264 <argstr>
    return -1;
    80005d9a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d9c:	0c054163          	bltz	a0,80005e5e <sys_open+0xe4>
    80005da0:	f4c40593          	addi	a1,s0,-180
    80005da4:	4505                	li	a0,1
    80005da6:	ffffd097          	auipc	ra,0xffffd
    80005daa:	47a080e7          	jalr	1146(ra) # 80003220 <argint>
    80005dae:	0a054863          	bltz	a0,80005e5e <sys_open+0xe4>

  begin_op();
    80005db2:	fffff097          	auipc	ra,0xfffff
    80005db6:	a2e080e7          	jalr	-1490(ra) # 800047e0 <begin_op>

  if(omode & O_CREATE){
    80005dba:	f4c42783          	lw	a5,-180(s0)
    80005dbe:	2007f793          	andi	a5,a5,512
    80005dc2:	cbdd                	beqz	a5,80005e78 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005dc4:	4681                	li	a3,0
    80005dc6:	4601                	li	a2,0
    80005dc8:	4589                	li	a1,2
    80005dca:	f5040513          	addi	a0,s0,-176
    80005dce:	00000097          	auipc	ra,0x0
    80005dd2:	972080e7          	jalr	-1678(ra) # 80005740 <create>
    80005dd6:	892a                	mv	s2,a0
    if(ip == 0){
    80005dd8:	c959                	beqz	a0,80005e6e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005dda:	04491703          	lh	a4,68(s2)
    80005dde:	478d                	li	a5,3
    80005de0:	00f71763          	bne	a4,a5,80005dee <sys_open+0x74>
    80005de4:	04695703          	lhu	a4,70(s2)
    80005de8:	47a5                	li	a5,9
    80005dea:	0ce7ec63          	bltu	a5,a4,80005ec2 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005dee:	fffff097          	auipc	ra,0xfffff
    80005df2:	e02080e7          	jalr	-510(ra) # 80004bf0 <filealloc>
    80005df6:	89aa                	mv	s3,a0
    80005df8:	10050263          	beqz	a0,80005efc <sys_open+0x182>
    80005dfc:	00000097          	auipc	ra,0x0
    80005e00:	902080e7          	jalr	-1790(ra) # 800056fe <fdalloc>
    80005e04:	84aa                	mv	s1,a0
    80005e06:	0e054663          	bltz	a0,80005ef2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005e0a:	04491703          	lh	a4,68(s2)
    80005e0e:	478d                	li	a5,3
    80005e10:	0cf70463          	beq	a4,a5,80005ed8 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005e14:	4789                	li	a5,2
    80005e16:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005e1a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005e1e:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005e22:	f4c42783          	lw	a5,-180(s0)
    80005e26:	0017c713          	xori	a4,a5,1
    80005e2a:	8b05                	andi	a4,a4,1
    80005e2c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e30:	0037f713          	andi	a4,a5,3
    80005e34:	00e03733          	snez	a4,a4
    80005e38:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e3c:	4007f793          	andi	a5,a5,1024
    80005e40:	c791                	beqz	a5,80005e4c <sys_open+0xd2>
    80005e42:	04491703          	lh	a4,68(s2)
    80005e46:	4789                	li	a5,2
    80005e48:	08f70f63          	beq	a4,a5,80005ee6 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e4c:	854a                	mv	a0,s2
    80005e4e:	ffffe097          	auipc	ra,0xffffe
    80005e52:	082080e7          	jalr	130(ra) # 80003ed0 <iunlock>
  end_op();
    80005e56:	fffff097          	auipc	ra,0xfffff
    80005e5a:	a0a080e7          	jalr	-1526(ra) # 80004860 <end_op>

  return fd;
}
    80005e5e:	8526                	mv	a0,s1
    80005e60:	70ea                	ld	ra,184(sp)
    80005e62:	744a                	ld	s0,176(sp)
    80005e64:	74aa                	ld	s1,168(sp)
    80005e66:	790a                	ld	s2,160(sp)
    80005e68:	69ea                	ld	s3,152(sp)
    80005e6a:	6129                	addi	sp,sp,192
    80005e6c:	8082                	ret
      end_op();
    80005e6e:	fffff097          	auipc	ra,0xfffff
    80005e72:	9f2080e7          	jalr	-1550(ra) # 80004860 <end_op>
      return -1;
    80005e76:	b7e5                	j	80005e5e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005e78:	f5040513          	addi	a0,s0,-176
    80005e7c:	ffffe097          	auipc	ra,0xffffe
    80005e80:	748080e7          	jalr	1864(ra) # 800045c4 <namei>
    80005e84:	892a                	mv	s2,a0
    80005e86:	c905                	beqz	a0,80005eb6 <sys_open+0x13c>
    ilock(ip);
    80005e88:	ffffe097          	auipc	ra,0xffffe
    80005e8c:	f86080e7          	jalr	-122(ra) # 80003e0e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e90:	04491703          	lh	a4,68(s2)
    80005e94:	4785                	li	a5,1
    80005e96:	f4f712e3          	bne	a4,a5,80005dda <sys_open+0x60>
    80005e9a:	f4c42783          	lw	a5,-180(s0)
    80005e9e:	dba1                	beqz	a5,80005dee <sys_open+0x74>
      iunlockput(ip);
    80005ea0:	854a                	mv	a0,s2
    80005ea2:	ffffe097          	auipc	ra,0xffffe
    80005ea6:	1ce080e7          	jalr	462(ra) # 80004070 <iunlockput>
      end_op();
    80005eaa:	fffff097          	auipc	ra,0xfffff
    80005eae:	9b6080e7          	jalr	-1610(ra) # 80004860 <end_op>
      return -1;
    80005eb2:	54fd                	li	s1,-1
    80005eb4:	b76d                	j	80005e5e <sys_open+0xe4>
      end_op();
    80005eb6:	fffff097          	auipc	ra,0xfffff
    80005eba:	9aa080e7          	jalr	-1622(ra) # 80004860 <end_op>
      return -1;
    80005ebe:	54fd                	li	s1,-1
    80005ec0:	bf79                	j	80005e5e <sys_open+0xe4>
    iunlockput(ip);
    80005ec2:	854a                	mv	a0,s2
    80005ec4:	ffffe097          	auipc	ra,0xffffe
    80005ec8:	1ac080e7          	jalr	428(ra) # 80004070 <iunlockput>
    end_op();
    80005ecc:	fffff097          	auipc	ra,0xfffff
    80005ed0:	994080e7          	jalr	-1644(ra) # 80004860 <end_op>
    return -1;
    80005ed4:	54fd                	li	s1,-1
    80005ed6:	b761                	j	80005e5e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005ed8:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005edc:	04691783          	lh	a5,70(s2)
    80005ee0:	02f99223          	sh	a5,36(s3)
    80005ee4:	bf2d                	j	80005e1e <sys_open+0xa4>
    itrunc(ip);
    80005ee6:	854a                	mv	a0,s2
    80005ee8:	ffffe097          	auipc	ra,0xffffe
    80005eec:	034080e7          	jalr	52(ra) # 80003f1c <itrunc>
    80005ef0:	bfb1                	j	80005e4c <sys_open+0xd2>
      fileclose(f);
    80005ef2:	854e                	mv	a0,s3
    80005ef4:	fffff097          	auipc	ra,0xfffff
    80005ef8:	db8080e7          	jalr	-584(ra) # 80004cac <fileclose>
    iunlockput(ip);
    80005efc:	854a                	mv	a0,s2
    80005efe:	ffffe097          	auipc	ra,0xffffe
    80005f02:	172080e7          	jalr	370(ra) # 80004070 <iunlockput>
    end_op();
    80005f06:	fffff097          	auipc	ra,0xfffff
    80005f0a:	95a080e7          	jalr	-1702(ra) # 80004860 <end_op>
    return -1;
    80005f0e:	54fd                	li	s1,-1
    80005f10:	b7b9                	j	80005e5e <sys_open+0xe4>

0000000080005f12 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005f12:	7175                	addi	sp,sp,-144
    80005f14:	e506                	sd	ra,136(sp)
    80005f16:	e122                	sd	s0,128(sp)
    80005f18:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005f1a:	fffff097          	auipc	ra,0xfffff
    80005f1e:	8c6080e7          	jalr	-1850(ra) # 800047e0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005f22:	08000613          	li	a2,128
    80005f26:	f7040593          	addi	a1,s0,-144
    80005f2a:	4501                	li	a0,0
    80005f2c:	ffffd097          	auipc	ra,0xffffd
    80005f30:	338080e7          	jalr	824(ra) # 80003264 <argstr>
    80005f34:	02054963          	bltz	a0,80005f66 <sys_mkdir+0x54>
    80005f38:	4681                	li	a3,0
    80005f3a:	4601                	li	a2,0
    80005f3c:	4585                	li	a1,1
    80005f3e:	f7040513          	addi	a0,s0,-144
    80005f42:	fffff097          	auipc	ra,0xfffff
    80005f46:	7fe080e7          	jalr	2046(ra) # 80005740 <create>
    80005f4a:	cd11                	beqz	a0,80005f66 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f4c:	ffffe097          	auipc	ra,0xffffe
    80005f50:	124080e7          	jalr	292(ra) # 80004070 <iunlockput>
  end_op();
    80005f54:	fffff097          	auipc	ra,0xfffff
    80005f58:	90c080e7          	jalr	-1780(ra) # 80004860 <end_op>
  return 0;
    80005f5c:	4501                	li	a0,0
}
    80005f5e:	60aa                	ld	ra,136(sp)
    80005f60:	640a                	ld	s0,128(sp)
    80005f62:	6149                	addi	sp,sp,144
    80005f64:	8082                	ret
    end_op();
    80005f66:	fffff097          	auipc	ra,0xfffff
    80005f6a:	8fa080e7          	jalr	-1798(ra) # 80004860 <end_op>
    return -1;
    80005f6e:	557d                	li	a0,-1
    80005f70:	b7fd                	j	80005f5e <sys_mkdir+0x4c>

0000000080005f72 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f72:	7135                	addi	sp,sp,-160
    80005f74:	ed06                	sd	ra,152(sp)
    80005f76:	e922                	sd	s0,144(sp)
    80005f78:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f7a:	fffff097          	auipc	ra,0xfffff
    80005f7e:	866080e7          	jalr	-1946(ra) # 800047e0 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f82:	08000613          	li	a2,128
    80005f86:	f7040593          	addi	a1,s0,-144
    80005f8a:	4501                	li	a0,0
    80005f8c:	ffffd097          	auipc	ra,0xffffd
    80005f90:	2d8080e7          	jalr	728(ra) # 80003264 <argstr>
    80005f94:	04054a63          	bltz	a0,80005fe8 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005f98:	f6c40593          	addi	a1,s0,-148
    80005f9c:	4505                	li	a0,1
    80005f9e:	ffffd097          	auipc	ra,0xffffd
    80005fa2:	282080e7          	jalr	642(ra) # 80003220 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fa6:	04054163          	bltz	a0,80005fe8 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005faa:	f6840593          	addi	a1,s0,-152
    80005fae:	4509                	li	a0,2
    80005fb0:	ffffd097          	auipc	ra,0xffffd
    80005fb4:	270080e7          	jalr	624(ra) # 80003220 <argint>
     argint(1, &major) < 0 ||
    80005fb8:	02054863          	bltz	a0,80005fe8 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005fbc:	f6841683          	lh	a3,-152(s0)
    80005fc0:	f6c41603          	lh	a2,-148(s0)
    80005fc4:	458d                	li	a1,3
    80005fc6:	f7040513          	addi	a0,s0,-144
    80005fca:	fffff097          	auipc	ra,0xfffff
    80005fce:	776080e7          	jalr	1910(ra) # 80005740 <create>
     argint(2, &minor) < 0 ||
    80005fd2:	c919                	beqz	a0,80005fe8 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005fd4:	ffffe097          	auipc	ra,0xffffe
    80005fd8:	09c080e7          	jalr	156(ra) # 80004070 <iunlockput>
  end_op();
    80005fdc:	fffff097          	auipc	ra,0xfffff
    80005fe0:	884080e7          	jalr	-1916(ra) # 80004860 <end_op>
  return 0;
    80005fe4:	4501                	li	a0,0
    80005fe6:	a031                	j	80005ff2 <sys_mknod+0x80>
    end_op();
    80005fe8:	fffff097          	auipc	ra,0xfffff
    80005fec:	878080e7          	jalr	-1928(ra) # 80004860 <end_op>
    return -1;
    80005ff0:	557d                	li	a0,-1
}
    80005ff2:	60ea                	ld	ra,152(sp)
    80005ff4:	644a                	ld	s0,144(sp)
    80005ff6:	610d                	addi	sp,sp,160
    80005ff8:	8082                	ret

0000000080005ffa <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ffa:	7135                	addi	sp,sp,-160
    80005ffc:	ed06                	sd	ra,152(sp)
    80005ffe:	e922                	sd	s0,144(sp)
    80006000:	e526                	sd	s1,136(sp)
    80006002:	e14a                	sd	s2,128(sp)
    80006004:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006006:	ffffc097          	auipc	ra,0xffffc
    8000600a:	dd6080e7          	jalr	-554(ra) # 80001ddc <myproc>
    8000600e:	892a                	mv	s2,a0
  
  begin_op();
    80006010:	ffffe097          	auipc	ra,0xffffe
    80006014:	7d0080e7          	jalr	2000(ra) # 800047e0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006018:	08000613          	li	a2,128
    8000601c:	f6040593          	addi	a1,s0,-160
    80006020:	4501                	li	a0,0
    80006022:	ffffd097          	auipc	ra,0xffffd
    80006026:	242080e7          	jalr	578(ra) # 80003264 <argstr>
    8000602a:	04054b63          	bltz	a0,80006080 <sys_chdir+0x86>
    8000602e:	f6040513          	addi	a0,s0,-160
    80006032:	ffffe097          	auipc	ra,0xffffe
    80006036:	592080e7          	jalr	1426(ra) # 800045c4 <namei>
    8000603a:	84aa                	mv	s1,a0
    8000603c:	c131                	beqz	a0,80006080 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000603e:	ffffe097          	auipc	ra,0xffffe
    80006042:	dd0080e7          	jalr	-560(ra) # 80003e0e <ilock>
  if(ip->type != T_DIR){
    80006046:	04449703          	lh	a4,68(s1)
    8000604a:	4785                	li	a5,1
    8000604c:	04f71063          	bne	a4,a5,8000608c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006050:	8526                	mv	a0,s1
    80006052:	ffffe097          	auipc	ra,0xffffe
    80006056:	e7e080e7          	jalr	-386(ra) # 80003ed0 <iunlock>
  iput(p->cwd);
    8000605a:	17093503          	ld	a0,368(s2)
    8000605e:	ffffe097          	auipc	ra,0xffffe
    80006062:	f6a080e7          	jalr	-150(ra) # 80003fc8 <iput>
  end_op();
    80006066:	ffffe097          	auipc	ra,0xffffe
    8000606a:	7fa080e7          	jalr	2042(ra) # 80004860 <end_op>
  p->cwd = ip;
    8000606e:	16993823          	sd	s1,368(s2)
  return 0;
    80006072:	4501                	li	a0,0
}
    80006074:	60ea                	ld	ra,152(sp)
    80006076:	644a                	ld	s0,144(sp)
    80006078:	64aa                	ld	s1,136(sp)
    8000607a:	690a                	ld	s2,128(sp)
    8000607c:	610d                	addi	sp,sp,160
    8000607e:	8082                	ret
    end_op();
    80006080:	ffffe097          	auipc	ra,0xffffe
    80006084:	7e0080e7          	jalr	2016(ra) # 80004860 <end_op>
    return -1;
    80006088:	557d                	li	a0,-1
    8000608a:	b7ed                	j	80006074 <sys_chdir+0x7a>
    iunlockput(ip);
    8000608c:	8526                	mv	a0,s1
    8000608e:	ffffe097          	auipc	ra,0xffffe
    80006092:	fe2080e7          	jalr	-30(ra) # 80004070 <iunlockput>
    end_op();
    80006096:	ffffe097          	auipc	ra,0xffffe
    8000609a:	7ca080e7          	jalr	1994(ra) # 80004860 <end_op>
    return -1;
    8000609e:	557d                	li	a0,-1
    800060a0:	bfd1                	j	80006074 <sys_chdir+0x7a>

00000000800060a2 <sys_exec>:

uint64
sys_exec(void)
{
    800060a2:	7145                	addi	sp,sp,-464
    800060a4:	e786                	sd	ra,456(sp)
    800060a6:	e3a2                	sd	s0,448(sp)
    800060a8:	ff26                	sd	s1,440(sp)
    800060aa:	fb4a                	sd	s2,432(sp)
    800060ac:	f74e                	sd	s3,424(sp)
    800060ae:	f352                	sd	s4,416(sp)
    800060b0:	ef56                	sd	s5,408(sp)
    800060b2:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800060b4:	08000613          	li	a2,128
    800060b8:	f4040593          	addi	a1,s0,-192
    800060bc:	4501                	li	a0,0
    800060be:	ffffd097          	auipc	ra,0xffffd
    800060c2:	1a6080e7          	jalr	422(ra) # 80003264 <argstr>
    return -1;
    800060c6:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800060c8:	0c054a63          	bltz	a0,8000619c <sys_exec+0xfa>
    800060cc:	e3840593          	addi	a1,s0,-456
    800060d0:	4505                	li	a0,1
    800060d2:	ffffd097          	auipc	ra,0xffffd
    800060d6:	170080e7          	jalr	368(ra) # 80003242 <argaddr>
    800060da:	0c054163          	bltz	a0,8000619c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800060de:	10000613          	li	a2,256
    800060e2:	4581                	li	a1,0
    800060e4:	e4040513          	addi	a0,s0,-448
    800060e8:	ffffb097          	auipc	ra,0xffffb
    800060ec:	c1c080e7          	jalr	-996(ra) # 80000d04 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800060f0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800060f4:	89a6                	mv	s3,s1
    800060f6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800060f8:	02000a13          	li	s4,32
    800060fc:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006100:	00391513          	slli	a0,s2,0x3
    80006104:	e3040593          	addi	a1,s0,-464
    80006108:	e3843783          	ld	a5,-456(s0)
    8000610c:	953e                	add	a0,a0,a5
    8000610e:	ffffd097          	auipc	ra,0xffffd
    80006112:	078080e7          	jalr	120(ra) # 80003186 <fetchaddr>
    80006116:	02054a63          	bltz	a0,8000614a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000611a:	e3043783          	ld	a5,-464(s0)
    8000611e:	c3b9                	beqz	a5,80006164 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006120:	ffffb097          	auipc	ra,0xffffb
    80006124:	9d4080e7          	jalr	-1580(ra) # 80000af4 <kalloc>
    80006128:	85aa                	mv	a1,a0
    8000612a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000612e:	cd11                	beqz	a0,8000614a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006130:	6605                	lui	a2,0x1
    80006132:	e3043503          	ld	a0,-464(s0)
    80006136:	ffffd097          	auipc	ra,0xffffd
    8000613a:	0a2080e7          	jalr	162(ra) # 800031d8 <fetchstr>
    8000613e:	00054663          	bltz	a0,8000614a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006142:	0905                	addi	s2,s2,1
    80006144:	09a1                	addi	s3,s3,8
    80006146:	fb491be3          	bne	s2,s4,800060fc <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000614a:	10048913          	addi	s2,s1,256
    8000614e:	6088                	ld	a0,0(s1)
    80006150:	c529                	beqz	a0,8000619a <sys_exec+0xf8>
    kfree(argv[i]);
    80006152:	ffffb097          	auipc	ra,0xffffb
    80006156:	8a6080e7          	jalr	-1882(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000615a:	04a1                	addi	s1,s1,8
    8000615c:	ff2499e3          	bne	s1,s2,8000614e <sys_exec+0xac>
  return -1;
    80006160:	597d                	li	s2,-1
    80006162:	a82d                	j	8000619c <sys_exec+0xfa>
      argv[i] = 0;
    80006164:	0a8e                	slli	s5,s5,0x3
    80006166:	fc040793          	addi	a5,s0,-64
    8000616a:	9abe                	add	s5,s5,a5
    8000616c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006170:	e4040593          	addi	a1,s0,-448
    80006174:	f4040513          	addi	a0,s0,-192
    80006178:	fffff097          	auipc	ra,0xfffff
    8000617c:	194080e7          	jalr	404(ra) # 8000530c <exec>
    80006180:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006182:	10048993          	addi	s3,s1,256
    80006186:	6088                	ld	a0,0(s1)
    80006188:	c911                	beqz	a0,8000619c <sys_exec+0xfa>
    kfree(argv[i]);
    8000618a:	ffffb097          	auipc	ra,0xffffb
    8000618e:	86e080e7          	jalr	-1938(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006192:	04a1                	addi	s1,s1,8
    80006194:	ff3499e3          	bne	s1,s3,80006186 <sys_exec+0xe4>
    80006198:	a011                	j	8000619c <sys_exec+0xfa>
  return -1;
    8000619a:	597d                	li	s2,-1
}
    8000619c:	854a                	mv	a0,s2
    8000619e:	60be                	ld	ra,456(sp)
    800061a0:	641e                	ld	s0,448(sp)
    800061a2:	74fa                	ld	s1,440(sp)
    800061a4:	795a                	ld	s2,432(sp)
    800061a6:	79ba                	ld	s3,424(sp)
    800061a8:	7a1a                	ld	s4,416(sp)
    800061aa:	6afa                	ld	s5,408(sp)
    800061ac:	6179                	addi	sp,sp,464
    800061ae:	8082                	ret

00000000800061b0 <sys_pipe>:

uint64
sys_pipe(void)
{
    800061b0:	7139                	addi	sp,sp,-64
    800061b2:	fc06                	sd	ra,56(sp)
    800061b4:	f822                	sd	s0,48(sp)
    800061b6:	f426                	sd	s1,40(sp)
    800061b8:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800061ba:	ffffc097          	auipc	ra,0xffffc
    800061be:	c22080e7          	jalr	-990(ra) # 80001ddc <myproc>
    800061c2:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800061c4:	fd840593          	addi	a1,s0,-40
    800061c8:	4501                	li	a0,0
    800061ca:	ffffd097          	auipc	ra,0xffffd
    800061ce:	078080e7          	jalr	120(ra) # 80003242 <argaddr>
    return -1;
    800061d2:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800061d4:	0e054063          	bltz	a0,800062b4 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800061d8:	fc840593          	addi	a1,s0,-56
    800061dc:	fd040513          	addi	a0,s0,-48
    800061e0:	fffff097          	auipc	ra,0xfffff
    800061e4:	dfc080e7          	jalr	-516(ra) # 80004fdc <pipealloc>
    return -1;
    800061e8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800061ea:	0c054563          	bltz	a0,800062b4 <sys_pipe+0x104>
  fd0 = -1;
    800061ee:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800061f2:	fd043503          	ld	a0,-48(s0)
    800061f6:	fffff097          	auipc	ra,0xfffff
    800061fa:	508080e7          	jalr	1288(ra) # 800056fe <fdalloc>
    800061fe:	fca42223          	sw	a0,-60(s0)
    80006202:	08054c63          	bltz	a0,8000629a <sys_pipe+0xea>
    80006206:	fc843503          	ld	a0,-56(s0)
    8000620a:	fffff097          	auipc	ra,0xfffff
    8000620e:	4f4080e7          	jalr	1268(ra) # 800056fe <fdalloc>
    80006212:	fca42023          	sw	a0,-64(s0)
    80006216:	06054863          	bltz	a0,80006286 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000621a:	4691                	li	a3,4
    8000621c:	fc440613          	addi	a2,s0,-60
    80006220:	fd843583          	ld	a1,-40(s0)
    80006224:	78a8                	ld	a0,112(s1)
    80006226:	ffffb097          	auipc	ra,0xffffb
    8000622a:	470080e7          	jalr	1136(ra) # 80001696 <copyout>
    8000622e:	02054063          	bltz	a0,8000624e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006232:	4691                	li	a3,4
    80006234:	fc040613          	addi	a2,s0,-64
    80006238:	fd843583          	ld	a1,-40(s0)
    8000623c:	0591                	addi	a1,a1,4
    8000623e:	78a8                	ld	a0,112(s1)
    80006240:	ffffb097          	auipc	ra,0xffffb
    80006244:	456080e7          	jalr	1110(ra) # 80001696 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006248:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000624a:	06055563          	bgez	a0,800062b4 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000624e:	fc442783          	lw	a5,-60(s0)
    80006252:	07f9                	addi	a5,a5,30
    80006254:	078e                	slli	a5,a5,0x3
    80006256:	97a6                	add	a5,a5,s1
    80006258:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000625c:	fc042503          	lw	a0,-64(s0)
    80006260:	0579                	addi	a0,a0,30
    80006262:	050e                	slli	a0,a0,0x3
    80006264:	9526                	add	a0,a0,s1
    80006266:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000626a:	fd043503          	ld	a0,-48(s0)
    8000626e:	fffff097          	auipc	ra,0xfffff
    80006272:	a3e080e7          	jalr	-1474(ra) # 80004cac <fileclose>
    fileclose(wf);
    80006276:	fc843503          	ld	a0,-56(s0)
    8000627a:	fffff097          	auipc	ra,0xfffff
    8000627e:	a32080e7          	jalr	-1486(ra) # 80004cac <fileclose>
    return -1;
    80006282:	57fd                	li	a5,-1
    80006284:	a805                	j	800062b4 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006286:	fc442783          	lw	a5,-60(s0)
    8000628a:	0007c863          	bltz	a5,8000629a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000628e:	01e78513          	addi	a0,a5,30
    80006292:	050e                	slli	a0,a0,0x3
    80006294:	9526                	add	a0,a0,s1
    80006296:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000629a:	fd043503          	ld	a0,-48(s0)
    8000629e:	fffff097          	auipc	ra,0xfffff
    800062a2:	a0e080e7          	jalr	-1522(ra) # 80004cac <fileclose>
    fileclose(wf);
    800062a6:	fc843503          	ld	a0,-56(s0)
    800062aa:	fffff097          	auipc	ra,0xfffff
    800062ae:	a02080e7          	jalr	-1534(ra) # 80004cac <fileclose>
    return -1;
    800062b2:	57fd                	li	a5,-1
}
    800062b4:	853e                	mv	a0,a5
    800062b6:	70e2                	ld	ra,56(sp)
    800062b8:	7442                	ld	s0,48(sp)
    800062ba:	74a2                	ld	s1,40(sp)
    800062bc:	6121                	addi	sp,sp,64
    800062be:	8082                	ret

00000000800062c0 <kernelvec>:
    800062c0:	7111                	addi	sp,sp,-256
    800062c2:	e006                	sd	ra,0(sp)
    800062c4:	e40a                	sd	sp,8(sp)
    800062c6:	e80e                	sd	gp,16(sp)
    800062c8:	ec12                	sd	tp,24(sp)
    800062ca:	f016                	sd	t0,32(sp)
    800062cc:	f41a                	sd	t1,40(sp)
    800062ce:	f81e                	sd	t2,48(sp)
    800062d0:	fc22                	sd	s0,56(sp)
    800062d2:	e0a6                	sd	s1,64(sp)
    800062d4:	e4aa                	sd	a0,72(sp)
    800062d6:	e8ae                	sd	a1,80(sp)
    800062d8:	ecb2                	sd	a2,88(sp)
    800062da:	f0b6                	sd	a3,96(sp)
    800062dc:	f4ba                	sd	a4,104(sp)
    800062de:	f8be                	sd	a5,112(sp)
    800062e0:	fcc2                	sd	a6,120(sp)
    800062e2:	e146                	sd	a7,128(sp)
    800062e4:	e54a                	sd	s2,136(sp)
    800062e6:	e94e                	sd	s3,144(sp)
    800062e8:	ed52                	sd	s4,152(sp)
    800062ea:	f156                	sd	s5,160(sp)
    800062ec:	f55a                	sd	s6,168(sp)
    800062ee:	f95e                	sd	s7,176(sp)
    800062f0:	fd62                	sd	s8,184(sp)
    800062f2:	e1e6                	sd	s9,192(sp)
    800062f4:	e5ea                	sd	s10,200(sp)
    800062f6:	e9ee                	sd	s11,208(sp)
    800062f8:	edf2                	sd	t3,216(sp)
    800062fa:	f1f6                	sd	t4,224(sp)
    800062fc:	f5fa                	sd	t5,232(sp)
    800062fe:	f9fe                	sd	t6,240(sp)
    80006300:	d53fc0ef          	jal	ra,80003052 <kerneltrap>
    80006304:	6082                	ld	ra,0(sp)
    80006306:	6122                	ld	sp,8(sp)
    80006308:	61c2                	ld	gp,16(sp)
    8000630a:	7282                	ld	t0,32(sp)
    8000630c:	7322                	ld	t1,40(sp)
    8000630e:	73c2                	ld	t2,48(sp)
    80006310:	7462                	ld	s0,56(sp)
    80006312:	6486                	ld	s1,64(sp)
    80006314:	6526                	ld	a0,72(sp)
    80006316:	65c6                	ld	a1,80(sp)
    80006318:	6666                	ld	a2,88(sp)
    8000631a:	7686                	ld	a3,96(sp)
    8000631c:	7726                	ld	a4,104(sp)
    8000631e:	77c6                	ld	a5,112(sp)
    80006320:	7866                	ld	a6,120(sp)
    80006322:	688a                	ld	a7,128(sp)
    80006324:	692a                	ld	s2,136(sp)
    80006326:	69ca                	ld	s3,144(sp)
    80006328:	6a6a                	ld	s4,152(sp)
    8000632a:	7a8a                	ld	s5,160(sp)
    8000632c:	7b2a                	ld	s6,168(sp)
    8000632e:	7bca                	ld	s7,176(sp)
    80006330:	7c6a                	ld	s8,184(sp)
    80006332:	6c8e                	ld	s9,192(sp)
    80006334:	6d2e                	ld	s10,200(sp)
    80006336:	6dce                	ld	s11,208(sp)
    80006338:	6e6e                	ld	t3,216(sp)
    8000633a:	7e8e                	ld	t4,224(sp)
    8000633c:	7f2e                	ld	t5,232(sp)
    8000633e:	7fce                	ld	t6,240(sp)
    80006340:	6111                	addi	sp,sp,256
    80006342:	10200073          	sret
    80006346:	00000013          	nop
    8000634a:	00000013          	nop
    8000634e:	0001                	nop

0000000080006350 <timervec>:
    80006350:	34051573          	csrrw	a0,mscratch,a0
    80006354:	e10c                	sd	a1,0(a0)
    80006356:	e510                	sd	a2,8(a0)
    80006358:	e914                	sd	a3,16(a0)
    8000635a:	6d0c                	ld	a1,24(a0)
    8000635c:	7110                	ld	a2,32(a0)
    8000635e:	6194                	ld	a3,0(a1)
    80006360:	96b2                	add	a3,a3,a2
    80006362:	e194                	sd	a3,0(a1)
    80006364:	4589                	li	a1,2
    80006366:	14459073          	csrw	sip,a1
    8000636a:	6914                	ld	a3,16(a0)
    8000636c:	6510                	ld	a2,8(a0)
    8000636e:	610c                	ld	a1,0(a0)
    80006370:	34051573          	csrrw	a0,mscratch,a0
    80006374:	30200073          	mret
	...

000000008000637a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000637a:	1141                	addi	sp,sp,-16
    8000637c:	e422                	sd	s0,8(sp)
    8000637e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006380:	0c0007b7          	lui	a5,0xc000
    80006384:	4705                	li	a4,1
    80006386:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006388:	c3d8                	sw	a4,4(a5)
}
    8000638a:	6422                	ld	s0,8(sp)
    8000638c:	0141                	addi	sp,sp,16
    8000638e:	8082                	ret

0000000080006390 <plicinithart>:

void
plicinithart(void)
{
    80006390:	1141                	addi	sp,sp,-16
    80006392:	e406                	sd	ra,8(sp)
    80006394:	e022                	sd	s0,0(sp)
    80006396:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006398:	ffffc097          	auipc	ra,0xffffc
    8000639c:	a10080e7          	jalr	-1520(ra) # 80001da8 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800063a0:	0085171b          	slliw	a4,a0,0x8
    800063a4:	0c0027b7          	lui	a5,0xc002
    800063a8:	97ba                	add	a5,a5,a4
    800063aa:	40200713          	li	a4,1026
    800063ae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800063b2:	00d5151b          	slliw	a0,a0,0xd
    800063b6:	0c2017b7          	lui	a5,0xc201
    800063ba:	953e                	add	a0,a0,a5
    800063bc:	00052023          	sw	zero,0(a0)
}
    800063c0:	60a2                	ld	ra,8(sp)
    800063c2:	6402                	ld	s0,0(sp)
    800063c4:	0141                	addi	sp,sp,16
    800063c6:	8082                	ret

00000000800063c8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800063c8:	1141                	addi	sp,sp,-16
    800063ca:	e406                	sd	ra,8(sp)
    800063cc:	e022                	sd	s0,0(sp)
    800063ce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063d0:	ffffc097          	auipc	ra,0xffffc
    800063d4:	9d8080e7          	jalr	-1576(ra) # 80001da8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800063d8:	00d5179b          	slliw	a5,a0,0xd
    800063dc:	0c201537          	lui	a0,0xc201
    800063e0:	953e                	add	a0,a0,a5
  return irq;
}
    800063e2:	4148                	lw	a0,4(a0)
    800063e4:	60a2                	ld	ra,8(sp)
    800063e6:	6402                	ld	s0,0(sp)
    800063e8:	0141                	addi	sp,sp,16
    800063ea:	8082                	ret

00000000800063ec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800063ec:	1101                	addi	sp,sp,-32
    800063ee:	ec06                	sd	ra,24(sp)
    800063f0:	e822                	sd	s0,16(sp)
    800063f2:	e426                	sd	s1,8(sp)
    800063f4:	1000                	addi	s0,sp,32
    800063f6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800063f8:	ffffc097          	auipc	ra,0xffffc
    800063fc:	9b0080e7          	jalr	-1616(ra) # 80001da8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006400:	00d5151b          	slliw	a0,a0,0xd
    80006404:	0c2017b7          	lui	a5,0xc201
    80006408:	97aa                	add	a5,a5,a0
    8000640a:	c3c4                	sw	s1,4(a5)
}
    8000640c:	60e2                	ld	ra,24(sp)
    8000640e:	6442                	ld	s0,16(sp)
    80006410:	64a2                	ld	s1,8(sp)
    80006412:	6105                	addi	sp,sp,32
    80006414:	8082                	ret

0000000080006416 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006416:	1141                	addi	sp,sp,-16
    80006418:	e406                	sd	ra,8(sp)
    8000641a:	e022                	sd	s0,0(sp)
    8000641c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000641e:	479d                	li	a5,7
    80006420:	06a7c963          	blt	a5,a0,80006492 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006424:	0001d797          	auipc	a5,0x1d
    80006428:	bdc78793          	addi	a5,a5,-1060 # 80023000 <disk>
    8000642c:	00a78733          	add	a4,a5,a0
    80006430:	6789                	lui	a5,0x2
    80006432:	97ba                	add	a5,a5,a4
    80006434:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006438:	e7ad                	bnez	a5,800064a2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000643a:	00451793          	slli	a5,a0,0x4
    8000643e:	0001f717          	auipc	a4,0x1f
    80006442:	bc270713          	addi	a4,a4,-1086 # 80025000 <disk+0x2000>
    80006446:	6314                	ld	a3,0(a4)
    80006448:	96be                	add	a3,a3,a5
    8000644a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000644e:	6314                	ld	a3,0(a4)
    80006450:	96be                	add	a3,a3,a5
    80006452:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006456:	6314                	ld	a3,0(a4)
    80006458:	96be                	add	a3,a3,a5
    8000645a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000645e:	6318                	ld	a4,0(a4)
    80006460:	97ba                	add	a5,a5,a4
    80006462:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006466:	0001d797          	auipc	a5,0x1d
    8000646a:	b9a78793          	addi	a5,a5,-1126 # 80023000 <disk>
    8000646e:	97aa                	add	a5,a5,a0
    80006470:	6509                	lui	a0,0x2
    80006472:	953e                	add	a0,a0,a5
    80006474:	4785                	li	a5,1
    80006476:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000647a:	0001f517          	auipc	a0,0x1f
    8000647e:	b9e50513          	addi	a0,a0,-1122 # 80025018 <disk+0x2018>
    80006482:	ffffc097          	auipc	ra,0xffffc
    80006486:	3b0080e7          	jalr	944(ra) # 80002832 <wakeup>
}
    8000648a:	60a2                	ld	ra,8(sp)
    8000648c:	6402                	ld	s0,0(sp)
    8000648e:	0141                	addi	sp,sp,16
    80006490:	8082                	ret
    panic("free_desc 1");
    80006492:	00002517          	auipc	a0,0x2
    80006496:	38650513          	addi	a0,a0,902 # 80008818 <syscalls+0x338>
    8000649a:	ffffa097          	auipc	ra,0xffffa
    8000649e:	0a4080e7          	jalr	164(ra) # 8000053e <panic>
    panic("free_desc 2");
    800064a2:	00002517          	auipc	a0,0x2
    800064a6:	38650513          	addi	a0,a0,902 # 80008828 <syscalls+0x348>
    800064aa:	ffffa097          	auipc	ra,0xffffa
    800064ae:	094080e7          	jalr	148(ra) # 8000053e <panic>

00000000800064b2 <virtio_disk_init>:
{
    800064b2:	1101                	addi	sp,sp,-32
    800064b4:	ec06                	sd	ra,24(sp)
    800064b6:	e822                	sd	s0,16(sp)
    800064b8:	e426                	sd	s1,8(sp)
    800064ba:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800064bc:	00002597          	auipc	a1,0x2
    800064c0:	37c58593          	addi	a1,a1,892 # 80008838 <syscalls+0x358>
    800064c4:	0001f517          	auipc	a0,0x1f
    800064c8:	c6450513          	addi	a0,a0,-924 # 80025128 <disk+0x2128>
    800064cc:	ffffa097          	auipc	ra,0xffffa
    800064d0:	688080e7          	jalr	1672(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064d4:	100017b7          	lui	a5,0x10001
    800064d8:	4398                	lw	a4,0(a5)
    800064da:	2701                	sext.w	a4,a4
    800064dc:	747277b7          	lui	a5,0x74727
    800064e0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800064e4:	0ef71163          	bne	a4,a5,800065c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064e8:	100017b7          	lui	a5,0x10001
    800064ec:	43dc                	lw	a5,4(a5)
    800064ee:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064f0:	4705                	li	a4,1
    800064f2:	0ce79a63          	bne	a5,a4,800065c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064f6:	100017b7          	lui	a5,0x10001
    800064fa:	479c                	lw	a5,8(a5)
    800064fc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064fe:	4709                	li	a4,2
    80006500:	0ce79363          	bne	a5,a4,800065c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006504:	100017b7          	lui	a5,0x10001
    80006508:	47d8                	lw	a4,12(a5)
    8000650a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000650c:	554d47b7          	lui	a5,0x554d4
    80006510:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006514:	0af71963          	bne	a4,a5,800065c6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006518:	100017b7          	lui	a5,0x10001
    8000651c:	4705                	li	a4,1
    8000651e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006520:	470d                	li	a4,3
    80006522:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006524:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006526:	c7ffe737          	lui	a4,0xc7ffe
    8000652a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000652e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006530:	2701                	sext.w	a4,a4
    80006532:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006534:	472d                	li	a4,11
    80006536:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006538:	473d                	li	a4,15
    8000653a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000653c:	6705                	lui	a4,0x1
    8000653e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006540:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006544:	5bdc                	lw	a5,52(a5)
    80006546:	2781                	sext.w	a5,a5
  if(max == 0)
    80006548:	c7d9                	beqz	a5,800065d6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000654a:	471d                	li	a4,7
    8000654c:	08f77d63          	bgeu	a4,a5,800065e6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006550:	100014b7          	lui	s1,0x10001
    80006554:	47a1                	li	a5,8
    80006556:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006558:	6609                	lui	a2,0x2
    8000655a:	4581                	li	a1,0
    8000655c:	0001d517          	auipc	a0,0x1d
    80006560:	aa450513          	addi	a0,a0,-1372 # 80023000 <disk>
    80006564:	ffffa097          	auipc	ra,0xffffa
    80006568:	7a0080e7          	jalr	1952(ra) # 80000d04 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000656c:	0001d717          	auipc	a4,0x1d
    80006570:	a9470713          	addi	a4,a4,-1388 # 80023000 <disk>
    80006574:	00c75793          	srli	a5,a4,0xc
    80006578:	2781                	sext.w	a5,a5
    8000657a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000657c:	0001f797          	auipc	a5,0x1f
    80006580:	a8478793          	addi	a5,a5,-1404 # 80025000 <disk+0x2000>
    80006584:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006586:	0001d717          	auipc	a4,0x1d
    8000658a:	afa70713          	addi	a4,a4,-1286 # 80023080 <disk+0x80>
    8000658e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006590:	0001e717          	auipc	a4,0x1e
    80006594:	a7070713          	addi	a4,a4,-1424 # 80024000 <disk+0x1000>
    80006598:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000659a:	4705                	li	a4,1
    8000659c:	00e78c23          	sb	a4,24(a5)
    800065a0:	00e78ca3          	sb	a4,25(a5)
    800065a4:	00e78d23          	sb	a4,26(a5)
    800065a8:	00e78da3          	sb	a4,27(a5)
    800065ac:	00e78e23          	sb	a4,28(a5)
    800065b0:	00e78ea3          	sb	a4,29(a5)
    800065b4:	00e78f23          	sb	a4,30(a5)
    800065b8:	00e78fa3          	sb	a4,31(a5)
}
    800065bc:	60e2                	ld	ra,24(sp)
    800065be:	6442                	ld	s0,16(sp)
    800065c0:	64a2                	ld	s1,8(sp)
    800065c2:	6105                	addi	sp,sp,32
    800065c4:	8082                	ret
    panic("could not find virtio disk");
    800065c6:	00002517          	auipc	a0,0x2
    800065ca:	28250513          	addi	a0,a0,642 # 80008848 <syscalls+0x368>
    800065ce:	ffffa097          	auipc	ra,0xffffa
    800065d2:	f70080e7          	jalr	-144(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800065d6:	00002517          	auipc	a0,0x2
    800065da:	29250513          	addi	a0,a0,658 # 80008868 <syscalls+0x388>
    800065de:	ffffa097          	auipc	ra,0xffffa
    800065e2:	f60080e7          	jalr	-160(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800065e6:	00002517          	auipc	a0,0x2
    800065ea:	2a250513          	addi	a0,a0,674 # 80008888 <syscalls+0x3a8>
    800065ee:	ffffa097          	auipc	ra,0xffffa
    800065f2:	f50080e7          	jalr	-176(ra) # 8000053e <panic>

00000000800065f6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800065f6:	7159                	addi	sp,sp,-112
    800065f8:	f486                	sd	ra,104(sp)
    800065fa:	f0a2                	sd	s0,96(sp)
    800065fc:	eca6                	sd	s1,88(sp)
    800065fe:	e8ca                	sd	s2,80(sp)
    80006600:	e4ce                	sd	s3,72(sp)
    80006602:	e0d2                	sd	s4,64(sp)
    80006604:	fc56                	sd	s5,56(sp)
    80006606:	f85a                	sd	s6,48(sp)
    80006608:	f45e                	sd	s7,40(sp)
    8000660a:	f062                	sd	s8,32(sp)
    8000660c:	ec66                	sd	s9,24(sp)
    8000660e:	e86a                	sd	s10,16(sp)
    80006610:	1880                	addi	s0,sp,112
    80006612:	892a                	mv	s2,a0
    80006614:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006616:	00c52c83          	lw	s9,12(a0)
    8000661a:	001c9c9b          	slliw	s9,s9,0x1
    8000661e:	1c82                	slli	s9,s9,0x20
    80006620:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006624:	0001f517          	auipc	a0,0x1f
    80006628:	b0450513          	addi	a0,a0,-1276 # 80025128 <disk+0x2128>
    8000662c:	ffffa097          	auipc	ra,0xffffa
    80006630:	5b8080e7          	jalr	1464(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006634:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006636:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006638:	0001db97          	auipc	s7,0x1d
    8000663c:	9c8b8b93          	addi	s7,s7,-1592 # 80023000 <disk>
    80006640:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006642:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006644:	8a4e                	mv	s4,s3
    80006646:	a051                	j	800066ca <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006648:	00fb86b3          	add	a3,s7,a5
    8000664c:	96da                	add	a3,a3,s6
    8000664e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006652:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006654:	0207c563          	bltz	a5,8000667e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006658:	2485                	addiw	s1,s1,1
    8000665a:	0711                	addi	a4,a4,4
    8000665c:	25548063          	beq	s1,s5,8000689c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006660:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006662:	0001f697          	auipc	a3,0x1f
    80006666:	9b668693          	addi	a3,a3,-1610 # 80025018 <disk+0x2018>
    8000666a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000666c:	0006c583          	lbu	a1,0(a3)
    80006670:	fde1                	bnez	a1,80006648 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006672:	2785                	addiw	a5,a5,1
    80006674:	0685                	addi	a3,a3,1
    80006676:	ff879be3          	bne	a5,s8,8000666c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000667a:	57fd                	li	a5,-1
    8000667c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000667e:	02905a63          	blez	s1,800066b2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006682:	f9042503          	lw	a0,-112(s0)
    80006686:	00000097          	auipc	ra,0x0
    8000668a:	d90080e7          	jalr	-624(ra) # 80006416 <free_desc>
      for(int j = 0; j < i; j++)
    8000668e:	4785                	li	a5,1
    80006690:	0297d163          	bge	a5,s1,800066b2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006694:	f9442503          	lw	a0,-108(s0)
    80006698:	00000097          	auipc	ra,0x0
    8000669c:	d7e080e7          	jalr	-642(ra) # 80006416 <free_desc>
      for(int j = 0; j < i; j++)
    800066a0:	4789                	li	a5,2
    800066a2:	0097d863          	bge	a5,s1,800066b2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800066a6:	f9842503          	lw	a0,-104(s0)
    800066aa:	00000097          	auipc	ra,0x0
    800066ae:	d6c080e7          	jalr	-660(ra) # 80006416 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800066b2:	0001f597          	auipc	a1,0x1f
    800066b6:	a7658593          	addi	a1,a1,-1418 # 80025128 <disk+0x2128>
    800066ba:	0001f517          	auipc	a0,0x1f
    800066be:	95e50513          	addi	a0,a0,-1698 # 80025018 <disk+0x2018>
    800066c2:	ffffc097          	auipc	ra,0xffffc
    800066c6:	fc8080e7          	jalr	-56(ra) # 8000268a <sleep>
  for(int i = 0; i < 3; i++){
    800066ca:	f9040713          	addi	a4,s0,-112
    800066ce:	84ce                	mv	s1,s3
    800066d0:	bf41                	j	80006660 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800066d2:	20058713          	addi	a4,a1,512
    800066d6:	00471693          	slli	a3,a4,0x4
    800066da:	0001d717          	auipc	a4,0x1d
    800066de:	92670713          	addi	a4,a4,-1754 # 80023000 <disk>
    800066e2:	9736                	add	a4,a4,a3
    800066e4:	4685                	li	a3,1
    800066e6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800066ea:	20058713          	addi	a4,a1,512
    800066ee:	00471693          	slli	a3,a4,0x4
    800066f2:	0001d717          	auipc	a4,0x1d
    800066f6:	90e70713          	addi	a4,a4,-1778 # 80023000 <disk>
    800066fa:	9736                	add	a4,a4,a3
    800066fc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006700:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006704:	7679                	lui	a2,0xffffe
    80006706:	963e                	add	a2,a2,a5
    80006708:	0001f697          	auipc	a3,0x1f
    8000670c:	8f868693          	addi	a3,a3,-1800 # 80025000 <disk+0x2000>
    80006710:	6298                	ld	a4,0(a3)
    80006712:	9732                	add	a4,a4,a2
    80006714:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006716:	6298                	ld	a4,0(a3)
    80006718:	9732                	add	a4,a4,a2
    8000671a:	4541                	li	a0,16
    8000671c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000671e:	6298                	ld	a4,0(a3)
    80006720:	9732                	add	a4,a4,a2
    80006722:	4505                	li	a0,1
    80006724:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006728:	f9442703          	lw	a4,-108(s0)
    8000672c:	6288                	ld	a0,0(a3)
    8000672e:	962a                	add	a2,a2,a0
    80006730:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006734:	0712                	slli	a4,a4,0x4
    80006736:	6290                	ld	a2,0(a3)
    80006738:	963a                	add	a2,a2,a4
    8000673a:	05890513          	addi	a0,s2,88
    8000673e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006740:	6294                	ld	a3,0(a3)
    80006742:	96ba                	add	a3,a3,a4
    80006744:	40000613          	li	a2,1024
    80006748:	c690                	sw	a2,8(a3)
  if(write)
    8000674a:	140d0063          	beqz	s10,8000688a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000674e:	0001f697          	auipc	a3,0x1f
    80006752:	8b26b683          	ld	a3,-1870(a3) # 80025000 <disk+0x2000>
    80006756:	96ba                	add	a3,a3,a4
    80006758:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000675c:	0001d817          	auipc	a6,0x1d
    80006760:	8a480813          	addi	a6,a6,-1884 # 80023000 <disk>
    80006764:	0001f517          	auipc	a0,0x1f
    80006768:	89c50513          	addi	a0,a0,-1892 # 80025000 <disk+0x2000>
    8000676c:	6114                	ld	a3,0(a0)
    8000676e:	96ba                	add	a3,a3,a4
    80006770:	00c6d603          	lhu	a2,12(a3)
    80006774:	00166613          	ori	a2,a2,1
    80006778:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000677c:	f9842683          	lw	a3,-104(s0)
    80006780:	6110                	ld	a2,0(a0)
    80006782:	9732                	add	a4,a4,a2
    80006784:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006788:	20058613          	addi	a2,a1,512
    8000678c:	0612                	slli	a2,a2,0x4
    8000678e:	9642                	add	a2,a2,a6
    80006790:	577d                	li	a4,-1
    80006792:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006796:	00469713          	slli	a4,a3,0x4
    8000679a:	6114                	ld	a3,0(a0)
    8000679c:	96ba                	add	a3,a3,a4
    8000679e:	03078793          	addi	a5,a5,48
    800067a2:	97c2                	add	a5,a5,a6
    800067a4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800067a6:	611c                	ld	a5,0(a0)
    800067a8:	97ba                	add	a5,a5,a4
    800067aa:	4685                	li	a3,1
    800067ac:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800067ae:	611c                	ld	a5,0(a0)
    800067b0:	97ba                	add	a5,a5,a4
    800067b2:	4809                	li	a6,2
    800067b4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800067b8:	611c                	ld	a5,0(a0)
    800067ba:	973e                	add	a4,a4,a5
    800067bc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800067c0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800067c4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800067c8:	6518                	ld	a4,8(a0)
    800067ca:	00275783          	lhu	a5,2(a4)
    800067ce:	8b9d                	andi	a5,a5,7
    800067d0:	0786                	slli	a5,a5,0x1
    800067d2:	97ba                	add	a5,a5,a4
    800067d4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800067d8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800067dc:	6518                	ld	a4,8(a0)
    800067de:	00275783          	lhu	a5,2(a4)
    800067e2:	2785                	addiw	a5,a5,1
    800067e4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800067e8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800067ec:	100017b7          	lui	a5,0x10001
    800067f0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800067f4:	00492703          	lw	a4,4(s2)
    800067f8:	4785                	li	a5,1
    800067fa:	02f71163          	bne	a4,a5,8000681c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800067fe:	0001f997          	auipc	s3,0x1f
    80006802:	92a98993          	addi	s3,s3,-1750 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006806:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006808:	85ce                	mv	a1,s3
    8000680a:	854a                	mv	a0,s2
    8000680c:	ffffc097          	auipc	ra,0xffffc
    80006810:	e7e080e7          	jalr	-386(ra) # 8000268a <sleep>
  while(b->disk == 1) {
    80006814:	00492783          	lw	a5,4(s2)
    80006818:	fe9788e3          	beq	a5,s1,80006808 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000681c:	f9042903          	lw	s2,-112(s0)
    80006820:	20090793          	addi	a5,s2,512
    80006824:	00479713          	slli	a4,a5,0x4
    80006828:	0001c797          	auipc	a5,0x1c
    8000682c:	7d878793          	addi	a5,a5,2008 # 80023000 <disk>
    80006830:	97ba                	add	a5,a5,a4
    80006832:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006836:	0001e997          	auipc	s3,0x1e
    8000683a:	7ca98993          	addi	s3,s3,1994 # 80025000 <disk+0x2000>
    8000683e:	00491713          	slli	a4,s2,0x4
    80006842:	0009b783          	ld	a5,0(s3)
    80006846:	97ba                	add	a5,a5,a4
    80006848:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000684c:	854a                	mv	a0,s2
    8000684e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006852:	00000097          	auipc	ra,0x0
    80006856:	bc4080e7          	jalr	-1084(ra) # 80006416 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000685a:	8885                	andi	s1,s1,1
    8000685c:	f0ed                	bnez	s1,8000683e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000685e:	0001f517          	auipc	a0,0x1f
    80006862:	8ca50513          	addi	a0,a0,-1846 # 80025128 <disk+0x2128>
    80006866:	ffffa097          	auipc	ra,0xffffa
    8000686a:	444080e7          	jalr	1092(ra) # 80000caa <release>
}
    8000686e:	70a6                	ld	ra,104(sp)
    80006870:	7406                	ld	s0,96(sp)
    80006872:	64e6                	ld	s1,88(sp)
    80006874:	6946                	ld	s2,80(sp)
    80006876:	69a6                	ld	s3,72(sp)
    80006878:	6a06                	ld	s4,64(sp)
    8000687a:	7ae2                	ld	s5,56(sp)
    8000687c:	7b42                	ld	s6,48(sp)
    8000687e:	7ba2                	ld	s7,40(sp)
    80006880:	7c02                	ld	s8,32(sp)
    80006882:	6ce2                	ld	s9,24(sp)
    80006884:	6d42                	ld	s10,16(sp)
    80006886:	6165                	addi	sp,sp,112
    80006888:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000688a:	0001e697          	auipc	a3,0x1e
    8000688e:	7766b683          	ld	a3,1910(a3) # 80025000 <disk+0x2000>
    80006892:	96ba                	add	a3,a3,a4
    80006894:	4609                	li	a2,2
    80006896:	00c69623          	sh	a2,12(a3)
    8000689a:	b5c9                	j	8000675c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000689c:	f9042583          	lw	a1,-112(s0)
    800068a0:	20058793          	addi	a5,a1,512
    800068a4:	0792                	slli	a5,a5,0x4
    800068a6:	0001d517          	auipc	a0,0x1d
    800068aa:	80250513          	addi	a0,a0,-2046 # 800230a8 <disk+0xa8>
    800068ae:	953e                	add	a0,a0,a5
  if(write)
    800068b0:	e20d11e3          	bnez	s10,800066d2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800068b4:	20058713          	addi	a4,a1,512
    800068b8:	00471693          	slli	a3,a4,0x4
    800068bc:	0001c717          	auipc	a4,0x1c
    800068c0:	74470713          	addi	a4,a4,1860 # 80023000 <disk>
    800068c4:	9736                	add	a4,a4,a3
    800068c6:	0a072423          	sw	zero,168(a4)
    800068ca:	b505                	j	800066ea <virtio_disk_rw+0xf4>

00000000800068cc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800068cc:	1101                	addi	sp,sp,-32
    800068ce:	ec06                	sd	ra,24(sp)
    800068d0:	e822                	sd	s0,16(sp)
    800068d2:	e426                	sd	s1,8(sp)
    800068d4:	e04a                	sd	s2,0(sp)
    800068d6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800068d8:	0001f517          	auipc	a0,0x1f
    800068dc:	85050513          	addi	a0,a0,-1968 # 80025128 <disk+0x2128>
    800068e0:	ffffa097          	auipc	ra,0xffffa
    800068e4:	304080e7          	jalr	772(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800068e8:	10001737          	lui	a4,0x10001
    800068ec:	533c                	lw	a5,96(a4)
    800068ee:	8b8d                	andi	a5,a5,3
    800068f0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800068f2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800068f6:	0001e797          	auipc	a5,0x1e
    800068fa:	70a78793          	addi	a5,a5,1802 # 80025000 <disk+0x2000>
    800068fe:	6b94                	ld	a3,16(a5)
    80006900:	0207d703          	lhu	a4,32(a5)
    80006904:	0026d783          	lhu	a5,2(a3)
    80006908:	06f70163          	beq	a4,a5,8000696a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000690c:	0001c917          	auipc	s2,0x1c
    80006910:	6f490913          	addi	s2,s2,1780 # 80023000 <disk>
    80006914:	0001e497          	auipc	s1,0x1e
    80006918:	6ec48493          	addi	s1,s1,1772 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000691c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006920:	6898                	ld	a4,16(s1)
    80006922:	0204d783          	lhu	a5,32(s1)
    80006926:	8b9d                	andi	a5,a5,7
    80006928:	078e                	slli	a5,a5,0x3
    8000692a:	97ba                	add	a5,a5,a4
    8000692c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000692e:	20078713          	addi	a4,a5,512
    80006932:	0712                	slli	a4,a4,0x4
    80006934:	974a                	add	a4,a4,s2
    80006936:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000693a:	e731                	bnez	a4,80006986 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000693c:	20078793          	addi	a5,a5,512
    80006940:	0792                	slli	a5,a5,0x4
    80006942:	97ca                	add	a5,a5,s2
    80006944:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006946:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000694a:	ffffc097          	auipc	ra,0xffffc
    8000694e:	ee8080e7          	jalr	-280(ra) # 80002832 <wakeup>

    disk.used_idx += 1;
    80006952:	0204d783          	lhu	a5,32(s1)
    80006956:	2785                	addiw	a5,a5,1
    80006958:	17c2                	slli	a5,a5,0x30
    8000695a:	93c1                	srli	a5,a5,0x30
    8000695c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006960:	6898                	ld	a4,16(s1)
    80006962:	00275703          	lhu	a4,2(a4)
    80006966:	faf71be3          	bne	a4,a5,8000691c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000696a:	0001e517          	auipc	a0,0x1e
    8000696e:	7be50513          	addi	a0,a0,1982 # 80025128 <disk+0x2128>
    80006972:	ffffa097          	auipc	ra,0xffffa
    80006976:	338080e7          	jalr	824(ra) # 80000caa <release>
}
    8000697a:	60e2                	ld	ra,24(sp)
    8000697c:	6442                	ld	s0,16(sp)
    8000697e:	64a2                	ld	s1,8(sp)
    80006980:	6902                	ld	s2,0(sp)
    80006982:	6105                	addi	sp,sp,32
    80006984:	8082                	ret
      panic("virtio_disk_intr status");
    80006986:	00002517          	auipc	a0,0x2
    8000698a:	f2250513          	addi	a0,a0,-222 # 800088a8 <syscalls+0x3c8>
    8000698e:	ffffa097          	auipc	ra,0xffffa
    80006992:	bb0080e7          	jalr	-1104(ra) # 8000053e <panic>

0000000080006996 <cas>:
    80006996:	100522af          	lr.w	t0,(a0)
    8000699a:	00b29563          	bne	t0,a1,800069a4 <fail>
    8000699e:	18c5252f          	sc.w	a0,a2,(a0)
    800069a2:	8082                	ret

00000000800069a4 <fail>:
    800069a4:	4505                	li	a0,1
    800069a6:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
