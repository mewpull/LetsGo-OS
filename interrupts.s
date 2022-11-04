#include "textflag.h"
#include "go_asm.h"

TEXT scheduleStackReturn(SB),NOSPLIT,$0
    CLI
    MOVL 0(SP), AX
    MOVL SP, DX
    CMPL AX, $0x200000
    JG stackFail
    RET
stackFail:
    MOVL $·scheduleThread(SB), BX
    MOVL (thread_kernelStack+stack_hi)(BX), SP
    PUSHL AX
    PUSHL DX
    CALL ·stackFail(SB)
    HLT

TEXT doubleStackReturnWrapper(SB),NOSPLIT,$0
    CLI
    MOVL $·scheduleThread(SB), BX
    MOVL (thread_kernelStack+stack_hi)(BX), SP
    CALL ·doubleStackReturn(SB)
    HLT
 

TEXT ·scheduleStack(SB),NOSPLIT,$0-4
    MOVL fn+0(FP), DI

    // Test if invokation is already in schedule stack
    MOVL $·scheduleThread(SB), AX
    MOVL (thread_kernelStack+stack_lo)(AX), BX
    CMPL SP, BX
    JL normal
    MOVL (thread_kernelStack+stack_hi)(AX), BX
    CMPL SP, BX
    JL already_in_schedule_stack

normal:

    MOVL main·currentThread(SB), AX

    MOVL SP, (thread_kernelInfo+InterruptInfo_ESP)(AX)
    MOVL $scheduleStackReturn(SB), (thread_kernelInfo+InterruptInfo_EIP)(AX)

    MOVL BX, SP

    MOVL DI, DX
    MOVL 0(DI), DI
    CALL DI

    MOVL main·currentThread(SB), AX
    MOVL (thread_kernelInfo+InterruptInfo_ESP)(AX), SP
    MOVL (thread_kernelInfo+InterruptInfo_EIP)(AX), DI
    MOVL $·doubleStackReturn(SB), (thread_kernelInfo+InterruptInfo_EIP)(AX)

    JMP DI

already_in_schedule_stack:
    //MOVL DI, DX
    //MOVL 0(DI), DI
    //CALL DI
    //RET
    MOVL 0(SP), AX
    PUSHL AX
    CALL ·scheduleStackFail(SB)
    HLT

TEXT ·setDS(SB),NOSPLIT,$0
    MOVL ·ds_segment+0(FP), AX
    MOVW AX, DS
    RET

TEXT ·setGS(SB),NOSPLIT,$0
    MOVL ·gs_segment+0(FP), AX
    MOVW AX, GS
    RET


TEXT ·installIDT(SB),NOSPLIT,$0
    MOVL ·descriptor(FP), AX
    LIDT (AX)
	RET

TEXT ·getIDT(SB),NOSPLIT,$0
    SIDT (AX)
    MOVL AX, ret+0(FP)
    RET

TEXT ·isrVector(SB), NOSPLIT,$0
    //"Pushes all general purpose registers onto the stack in the following order: (E)AX, (E)CX, (E)DX, (E)BX, (E)SP, (E)BP, (E)SI, (E)DI. The value of SP is the value before the actual push of SP."
    PUSHAL
    PUSHL DS
    PUSHL ES
    PUSHL FS
    PUSHL GS

    CALL ·do_isr(SB)

    POPL GS
    POPL FS
    POPL ES
    POPL DS
    POPAL
    ADDL $8, SP
    IRETL

TEXT ·EnableInterrupts(SB), NOSPLIT,$0
    STI
    RET

TEXT ·DisableInterrupts(SB), NOSPLIT,$0
    CLI
    RET

#define INT_ENTRY_WITHOUT_ERR_CODE(num) \
    SUBL $8, SP                         \
    MOVL $0, 4(SP)                      \
    MOVL $num, (SP)                     \
    JMP ·isrVector(SB)

#define INT_ENTRY_WITH_ERR_CODE(num) \
    SUBL $4, SP                      \
    MOVL $num, (SP)                  \
    JMP ·isrVector(SB)               \
    MOVL $0, 4(SP) // Make sure both versions are the same lenght (this could maybe break)

TEXT ·isrEntryList(SB), NOSPLIT, $0
    INT_ENTRY_WITHOUT_ERR_CODE(0)
    INT_ENTRY_WITHOUT_ERR_CODE(1)
    INT_ENTRY_WITHOUT_ERR_CODE(2)
    INT_ENTRY_WITHOUT_ERR_CODE(3)
    INT_ENTRY_WITHOUT_ERR_CODE(4)
    INT_ENTRY_WITHOUT_ERR_CODE(5)
    INT_ENTRY_WITHOUT_ERR_CODE(6)
    INT_ENTRY_WITHOUT_ERR_CODE(7)
    INT_ENTRY_WITH_ERR_CODE(8)
    INT_ENTRY_WITHOUT_ERR_CODE(9)
    INT_ENTRY_WITH_ERR_CODE(10)
    INT_ENTRY_WITH_ERR_CODE(11)
    INT_ENTRY_WITH_ERR_CODE(12)
    INT_ENTRY_WITH_ERR_CODE(13)
    INT_ENTRY_WITH_ERR_CODE(14)
    INT_ENTRY_WITHOUT_ERR_CODE(15)
    INT_ENTRY_WITHOUT_ERR_CODE(16)
    INT_ENTRY_WITH_ERR_CODE(17)
    INT_ENTRY_WITHOUT_ERR_CODE(18)
    INT_ENTRY_WITHOUT_ERR_CODE(19)
    INT_ENTRY_WITHOUT_ERR_CODE(20)
    INT_ENTRY_WITHOUT_ERR_CODE(21)
    INT_ENTRY_WITHOUT_ERR_CODE(22)
    INT_ENTRY_WITHOUT_ERR_CODE(23)
    INT_ENTRY_WITHOUT_ERR_CODE(24)
    INT_ENTRY_WITHOUT_ERR_CODE(25)
    INT_ENTRY_WITHOUT_ERR_CODE(26)
    INT_ENTRY_WITHOUT_ERR_CODE(27)
    INT_ENTRY_WITHOUT_ERR_CODE(28)
    INT_ENTRY_WITHOUT_ERR_CODE(29)
    INT_ENTRY_WITH_ERR_CODE(30)
    INT_ENTRY_WITHOUT_ERR_CODE(31)
    INT_ENTRY_WITHOUT_ERR_CODE(32)
    INT_ENTRY_WITHOUT_ERR_CODE(33)
    INT_ENTRY_WITHOUT_ERR_CODE(34)
    INT_ENTRY_WITHOUT_ERR_CODE(35)
    INT_ENTRY_WITHOUT_ERR_CODE(36)
    INT_ENTRY_WITHOUT_ERR_CODE(37)
    INT_ENTRY_WITHOUT_ERR_CODE(38)
    INT_ENTRY_WITHOUT_ERR_CODE(39)
    INT_ENTRY_WITHOUT_ERR_CODE(40)
    INT_ENTRY_WITHOUT_ERR_CODE(41)
    INT_ENTRY_WITHOUT_ERR_CODE(42)
    INT_ENTRY_WITHOUT_ERR_CODE(43)
    INT_ENTRY_WITHOUT_ERR_CODE(44)
    INT_ENTRY_WITHOUT_ERR_CODE(45)
    INT_ENTRY_WITHOUT_ERR_CODE(46)
    INT_ENTRY_WITHOUT_ERR_CODE(47)
    INT_ENTRY_WITHOUT_ERR_CODE(48)
    INT_ENTRY_WITHOUT_ERR_CODE(49)
    INT_ENTRY_WITHOUT_ERR_CODE(50)
    INT_ENTRY_WITHOUT_ERR_CODE(51)
    INT_ENTRY_WITHOUT_ERR_CODE(52)
    INT_ENTRY_WITHOUT_ERR_CODE(53)
    INT_ENTRY_WITHOUT_ERR_CODE(54)
    INT_ENTRY_WITHOUT_ERR_CODE(55)
    INT_ENTRY_WITHOUT_ERR_CODE(56)
    INT_ENTRY_WITHOUT_ERR_CODE(57)
    INT_ENTRY_WITHOUT_ERR_CODE(58)
    INT_ENTRY_WITHOUT_ERR_CODE(59)
    INT_ENTRY_WITHOUT_ERR_CODE(60)
    INT_ENTRY_WITHOUT_ERR_CODE(61)
    INT_ENTRY_WITHOUT_ERR_CODE(62)
    INT_ENTRY_WITHOUT_ERR_CODE(63)
    INT_ENTRY_WITHOUT_ERR_CODE(64)
    INT_ENTRY_WITHOUT_ERR_CODE(65)
    INT_ENTRY_WITHOUT_ERR_CODE(66)
    INT_ENTRY_WITHOUT_ERR_CODE(67)
    INT_ENTRY_WITHOUT_ERR_CODE(68)
    INT_ENTRY_WITHOUT_ERR_CODE(69)
    INT_ENTRY_WITHOUT_ERR_CODE(70)
    INT_ENTRY_WITHOUT_ERR_CODE(71)
    INT_ENTRY_WITHOUT_ERR_CODE(72)
    INT_ENTRY_WITHOUT_ERR_CODE(73)
    INT_ENTRY_WITHOUT_ERR_CODE(74)
    INT_ENTRY_WITHOUT_ERR_CODE(75)
    INT_ENTRY_WITHOUT_ERR_CODE(76)
    INT_ENTRY_WITHOUT_ERR_CODE(77)
    INT_ENTRY_WITHOUT_ERR_CODE(78)
    INT_ENTRY_WITHOUT_ERR_CODE(79)
    INT_ENTRY_WITHOUT_ERR_CODE(80)
    INT_ENTRY_WITHOUT_ERR_CODE(81)
    INT_ENTRY_WITHOUT_ERR_CODE(82)
    INT_ENTRY_WITHOUT_ERR_CODE(83)
    INT_ENTRY_WITHOUT_ERR_CODE(84)
    INT_ENTRY_WITHOUT_ERR_CODE(85)
    INT_ENTRY_WITHOUT_ERR_CODE(86)
    INT_ENTRY_WITHOUT_ERR_CODE(87)
    INT_ENTRY_WITHOUT_ERR_CODE(88)
    INT_ENTRY_WITHOUT_ERR_CODE(89)
    INT_ENTRY_WITHOUT_ERR_CODE(90)
    INT_ENTRY_WITHOUT_ERR_CODE(91)
    INT_ENTRY_WITHOUT_ERR_CODE(92)
    INT_ENTRY_WITHOUT_ERR_CODE(93)
    INT_ENTRY_WITHOUT_ERR_CODE(94)
    INT_ENTRY_WITHOUT_ERR_CODE(95)
    INT_ENTRY_WITHOUT_ERR_CODE(96)
    INT_ENTRY_WITHOUT_ERR_CODE(97)
    INT_ENTRY_WITHOUT_ERR_CODE(98)
    INT_ENTRY_WITHOUT_ERR_CODE(99)
    INT_ENTRY_WITHOUT_ERR_CODE(100)
    INT_ENTRY_WITHOUT_ERR_CODE(101)
    INT_ENTRY_WITHOUT_ERR_CODE(102)
    INT_ENTRY_WITHOUT_ERR_CODE(103)
    INT_ENTRY_WITHOUT_ERR_CODE(104)
    INT_ENTRY_WITHOUT_ERR_CODE(105)
    INT_ENTRY_WITHOUT_ERR_CODE(106)
    INT_ENTRY_WITHOUT_ERR_CODE(107)
    INT_ENTRY_WITHOUT_ERR_CODE(108)
    INT_ENTRY_WITHOUT_ERR_CODE(109)
    INT_ENTRY_WITHOUT_ERR_CODE(110)
    INT_ENTRY_WITHOUT_ERR_CODE(111)
    INT_ENTRY_WITHOUT_ERR_CODE(112)
    INT_ENTRY_WITHOUT_ERR_CODE(113)
    INT_ENTRY_WITHOUT_ERR_CODE(114)
    INT_ENTRY_WITHOUT_ERR_CODE(115)
    INT_ENTRY_WITHOUT_ERR_CODE(116)
    INT_ENTRY_WITHOUT_ERR_CODE(117)
    INT_ENTRY_WITHOUT_ERR_CODE(118)
    INT_ENTRY_WITHOUT_ERR_CODE(119)
    INT_ENTRY_WITHOUT_ERR_CODE(120)
    INT_ENTRY_WITHOUT_ERR_CODE(121)
    INT_ENTRY_WITHOUT_ERR_CODE(122)
    INT_ENTRY_WITHOUT_ERR_CODE(123)
    INT_ENTRY_WITHOUT_ERR_CODE(124)
    INT_ENTRY_WITHOUT_ERR_CODE(125)
    INT_ENTRY_WITHOUT_ERR_CODE(126)
    INT_ENTRY_WITHOUT_ERR_CODE(127)
    INT_ENTRY_WITHOUT_ERR_CODE(128)
    INT_ENTRY_WITHOUT_ERR_CODE(129)
    INT_ENTRY_WITHOUT_ERR_CODE(130)
    INT_ENTRY_WITHOUT_ERR_CODE(131)
    INT_ENTRY_WITHOUT_ERR_CODE(132)
    INT_ENTRY_WITHOUT_ERR_CODE(133)
    INT_ENTRY_WITHOUT_ERR_CODE(134)
    INT_ENTRY_WITHOUT_ERR_CODE(135)
    INT_ENTRY_WITHOUT_ERR_CODE(136)
    INT_ENTRY_WITHOUT_ERR_CODE(137)
    INT_ENTRY_WITHOUT_ERR_CODE(138)
    INT_ENTRY_WITHOUT_ERR_CODE(139)
    INT_ENTRY_WITHOUT_ERR_CODE(140)
    INT_ENTRY_WITHOUT_ERR_CODE(141)
    INT_ENTRY_WITHOUT_ERR_CODE(142)
    INT_ENTRY_WITHOUT_ERR_CODE(143)
    INT_ENTRY_WITHOUT_ERR_CODE(144)
    INT_ENTRY_WITHOUT_ERR_CODE(145)
    INT_ENTRY_WITHOUT_ERR_CODE(146)
    INT_ENTRY_WITHOUT_ERR_CODE(147)
    INT_ENTRY_WITHOUT_ERR_CODE(148)
    INT_ENTRY_WITHOUT_ERR_CODE(149)
    INT_ENTRY_WITHOUT_ERR_CODE(150)
    INT_ENTRY_WITHOUT_ERR_CODE(151)
    INT_ENTRY_WITHOUT_ERR_CODE(152)
    INT_ENTRY_WITHOUT_ERR_CODE(153)
    INT_ENTRY_WITHOUT_ERR_CODE(154)
    INT_ENTRY_WITHOUT_ERR_CODE(155)
    INT_ENTRY_WITHOUT_ERR_CODE(156)
    INT_ENTRY_WITHOUT_ERR_CODE(157)
    INT_ENTRY_WITHOUT_ERR_CODE(158)
    INT_ENTRY_WITHOUT_ERR_CODE(159)
    INT_ENTRY_WITHOUT_ERR_CODE(160)
    INT_ENTRY_WITHOUT_ERR_CODE(161)
    INT_ENTRY_WITHOUT_ERR_CODE(162)
    INT_ENTRY_WITHOUT_ERR_CODE(163)
    INT_ENTRY_WITHOUT_ERR_CODE(164)
    INT_ENTRY_WITHOUT_ERR_CODE(165)
    INT_ENTRY_WITHOUT_ERR_CODE(166)
    INT_ENTRY_WITHOUT_ERR_CODE(167)
    INT_ENTRY_WITHOUT_ERR_CODE(168)
    INT_ENTRY_WITHOUT_ERR_CODE(169)
    INT_ENTRY_WITHOUT_ERR_CODE(170)
    INT_ENTRY_WITHOUT_ERR_CODE(171)
    INT_ENTRY_WITHOUT_ERR_CODE(172)
    INT_ENTRY_WITHOUT_ERR_CODE(173)
    INT_ENTRY_WITHOUT_ERR_CODE(174)
    INT_ENTRY_WITHOUT_ERR_CODE(175)
    INT_ENTRY_WITHOUT_ERR_CODE(176)
    INT_ENTRY_WITHOUT_ERR_CODE(177)
    INT_ENTRY_WITHOUT_ERR_CODE(178)
    INT_ENTRY_WITHOUT_ERR_CODE(179)
    INT_ENTRY_WITHOUT_ERR_CODE(180)
    INT_ENTRY_WITHOUT_ERR_CODE(181)
    INT_ENTRY_WITHOUT_ERR_CODE(182)
    INT_ENTRY_WITHOUT_ERR_CODE(183)
    INT_ENTRY_WITHOUT_ERR_CODE(184)
    INT_ENTRY_WITHOUT_ERR_CODE(185)
    INT_ENTRY_WITHOUT_ERR_CODE(186)
    INT_ENTRY_WITHOUT_ERR_CODE(187)
    INT_ENTRY_WITHOUT_ERR_CODE(188)
    INT_ENTRY_WITHOUT_ERR_CODE(189)
    INT_ENTRY_WITHOUT_ERR_CODE(190)
    INT_ENTRY_WITHOUT_ERR_CODE(191)
    INT_ENTRY_WITHOUT_ERR_CODE(192)
    INT_ENTRY_WITHOUT_ERR_CODE(193)
    INT_ENTRY_WITHOUT_ERR_CODE(194)
    INT_ENTRY_WITHOUT_ERR_CODE(195)
    INT_ENTRY_WITHOUT_ERR_CODE(196)
    INT_ENTRY_WITHOUT_ERR_CODE(197)
    INT_ENTRY_WITHOUT_ERR_CODE(198)
    INT_ENTRY_WITHOUT_ERR_CODE(199)
    INT_ENTRY_WITHOUT_ERR_CODE(200)
    INT_ENTRY_WITHOUT_ERR_CODE(201)
    INT_ENTRY_WITHOUT_ERR_CODE(202)
    INT_ENTRY_WITHOUT_ERR_CODE(203)
    INT_ENTRY_WITHOUT_ERR_CODE(204)
    INT_ENTRY_WITHOUT_ERR_CODE(205)
    INT_ENTRY_WITHOUT_ERR_CODE(206)
    INT_ENTRY_WITHOUT_ERR_CODE(207)
    INT_ENTRY_WITHOUT_ERR_CODE(208)
    INT_ENTRY_WITHOUT_ERR_CODE(209)
    INT_ENTRY_WITHOUT_ERR_CODE(210)
    INT_ENTRY_WITHOUT_ERR_CODE(211)
    INT_ENTRY_WITHOUT_ERR_CODE(212)
    INT_ENTRY_WITHOUT_ERR_CODE(213)
    INT_ENTRY_WITHOUT_ERR_CODE(214)
    INT_ENTRY_WITHOUT_ERR_CODE(215)
    INT_ENTRY_WITHOUT_ERR_CODE(216)
    INT_ENTRY_WITHOUT_ERR_CODE(217)
    INT_ENTRY_WITHOUT_ERR_CODE(218)
    INT_ENTRY_WITHOUT_ERR_CODE(219)
    INT_ENTRY_WITHOUT_ERR_CODE(220)
    INT_ENTRY_WITHOUT_ERR_CODE(221)
    INT_ENTRY_WITHOUT_ERR_CODE(222)
    INT_ENTRY_WITHOUT_ERR_CODE(223)
    INT_ENTRY_WITHOUT_ERR_CODE(224)
    INT_ENTRY_WITHOUT_ERR_CODE(225)
    INT_ENTRY_WITHOUT_ERR_CODE(226)
    INT_ENTRY_WITHOUT_ERR_CODE(227)
    INT_ENTRY_WITHOUT_ERR_CODE(228)
    INT_ENTRY_WITHOUT_ERR_CODE(229)
    INT_ENTRY_WITHOUT_ERR_CODE(230)
    INT_ENTRY_WITHOUT_ERR_CODE(231)
    INT_ENTRY_WITHOUT_ERR_CODE(232)
    INT_ENTRY_WITHOUT_ERR_CODE(233)
    INT_ENTRY_WITHOUT_ERR_CODE(234)
    INT_ENTRY_WITHOUT_ERR_CODE(235)
    INT_ENTRY_WITHOUT_ERR_CODE(236)
    INT_ENTRY_WITHOUT_ERR_CODE(237)
    INT_ENTRY_WITHOUT_ERR_CODE(238)
    INT_ENTRY_WITHOUT_ERR_CODE(239)
    INT_ENTRY_WITHOUT_ERR_CODE(240)
    INT_ENTRY_WITHOUT_ERR_CODE(241)
    INT_ENTRY_WITHOUT_ERR_CODE(242)
    INT_ENTRY_WITHOUT_ERR_CODE(243)
    INT_ENTRY_WITHOUT_ERR_CODE(244)
    INT_ENTRY_WITHOUT_ERR_CODE(245)
    INT_ENTRY_WITHOUT_ERR_CODE(246)
    INT_ENTRY_WITHOUT_ERR_CODE(247)
    INT_ENTRY_WITHOUT_ERR_CODE(248)
    INT_ENTRY_WITHOUT_ERR_CODE(249)
    INT_ENTRY_WITHOUT_ERR_CODE(250)
    INT_ENTRY_WITHOUT_ERR_CODE(251)
    INT_ENTRY_WITHOUT_ERR_CODE(252)
    INT_ENTRY_WITHOUT_ERR_CODE(253)
    INT_ENTRY_WITHOUT_ERR_CODE(254)
    INT_ENTRY_WITHOUT_ERR_CODE(255)

