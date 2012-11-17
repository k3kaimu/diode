/*                                                                            |
 * Distributed by IVI Foundation Inc.                                         |
 *                                                                            |
 * Do not modify the contents of this file.                                   |
 *                                                                            |
 *                                                                            |
 * Title   : VISATYPE.H                                                       |
 * Date    : 04-14-2006                                                       |
 * Purpose : Fundamental VISA data types and macro definitions                |
 *                                                                            |
 */


module diode.c.visa.visatype;

import std.bitmanip : bitfields;

enum _VI_ERROR = -2147483647L-1;  /* 0x80000000 */

/*- VISA Types --------------------------------------------------------------*/


alias ulong  ViUInt64;
alias long  ViInt64;

alias ViUInt64*     ViPUInt64;
alias ViUInt64*     ViAUInt64;
alias ViInt64*      ViPInt64;
alias ViInt64*      ViAInt64;

alias uint          ViUInt32;
alias int           ViInt32;


alias ViUInt32*     ViPUInt32;
alias ViUInt32*     ViAUInt32;
alias ViInt32*      ViPInt32;
alias ViInt32*      ViAInt32;

alias ushort        ViUInt16;
alias ViUInt16*     ViPUInt16;
alias ViUInt16*     ViAUInt16;

alias short         ViInt16;
alias ViInt16*      ViPInt16;
alias ViInt16*      ViAInt16;

alias ubyte         ViUInt8;
alias ViUInt8*      ViPUInt8;
alias ViUInt8*      ViAUInt8;

alias byte          ViInt8;
alias ViInt8*       ViPInt8;
alias ViInt8*       ViAInt8;

alias char          ViChar;
alias ViChar*       ViPChar;
alias ViChar*       ViAChar;

alias ubyte         ViByte;
alias ViByte*       ViPByte;
alias ViByte*       ViAByte;

alias void*         ViAddr;
alias ViAddr*       ViPAddr;
alias ViAddr*       ViAAddr;

alias float         ViReal32;
alias ViReal32*     ViPReal32;
alias ViReal32*     ViAReal32;

alias double        ViReal64;
alias ViReal64*     ViPReal64;
alias ViReal64*     ViAReal64;

alias ViPByte       ViBuf;
alias ViPByte       ViPBuf;
alias ViPByte*      ViABuf;

alias ViPChar       ViString;
alias ViPChar       ViPString;
alias ViPChar*      ViAString;

alias ViString      ViRsrc;
alias ViString      ViPRsrc;
alias ViString*     ViARsrc;

/*
alias ViUInt16      ViBoolean;*/

struct ViBoolean{
    mixin(bitfields!(bool, "flag", 1, ushort, "_nothing", 15));
    
    alias flag this;
}
unittest{
    ViBoolean b;
    b = true;
    assert(b.flag && !b._nothing);
    assert(b);
}

alias ViBoolean*    ViPBoolean;
alias ViBoolean*    ViABoolean;

alias ViInt32       ViStatus;
alias ViStatus*     ViPStatus;
alias ViStatus*     ViAStatus;

alias ViUInt32      ViVersion;
alias ViVersion*    ViPVersion;
alias ViVersion*    ViAVersion;

alias ViUInt32      ViObject;
alias ViObject*     ViPObject;
alias ViObject*     ViAObject;

alias ViObject      ViSession;
alias ViSession*    ViPSession;
alias ViSession*    ViASession;

alias ViUInt32      ViAttr;

alias const(ViChar)* ViConstString;

/*- Completion and Error Codes ----------------------------------------------*/

enum VI_SUCCESS = 0;

/*- Other VISA Definitions --------------------------------------------------*/

enum VI_NULL =  0;
enum VI_TRUE =  1;
enum VI_FALSE = 0;
