/*
 * Distributed by IVI Foundation Inc.                                         |
 * Contains National Instruments extensions.                                  |
 * Do not modify the contents of this file.                                   |
 *--------------------------------------------------------------------------- |
 *                                                                            |
 * Title   : VISA.H                                                           |
 * Date    : 02-09-2012                                                       |
 * Purpose : Include file for the VISA Library 5.1 specification              |
 *                                                                            |
 *--------------------------------------------------------------------------- |
 * When using NI-VISA extensions, you must link with the VISA library that    |
 * comes with NI-VISA.  Currently, the extensions provided by NI-VISA are:    |
 *                                                                            |
 * PXI (Compact PCI eXtensions for Instrumentation) and PCI support.  To use  |
 * this, you must define the macro NIVISA_PXI before including this header.   |
 * You must also create an INF file with the VISA Driver Development Wizard.  |
 *                                                                            |
 * A fast set of macros for viPeekXX/viPokeXX that guarantees binary          |
 * compatibility with other implementations of VISA.  To use this, you must   |
 * define the macro NIVISA_PEEKPOKE before including this header.             |
 *                                                                            |
 * Support for USB devices that do not conform to a specific class.  To use   |
 * this, you must define the macro NIVISA_USB before including this header.   |
 *  You must also create an INF file with the VISA Driver Development Wizard. 
 */

module diode.c.visa.visa;

public import diode.c.visa.visatype;

/*- VISA Types --------------------------------------------------------------*/

alias ViObject              ViEvent;
alias ViEvent*              ViPEvent;
alias ViObject              ViFindList;
alias ViFindList*           ViPFindList;


version(D_LP64){    //if 64bit system
    alias ViUInt64             ViBusAddress;
    alias ViUInt64             ViBusSize;
    alias ViUInt64             ViAttrState;
}else{
    alias ViUInt32             ViBusAddress;
    alias ViUInt32             ViBusSize;
    alias ViUInt32             ViAttrState;
}

alias ViUInt64              ViBusAddress64;
alias ViBusAddress64*       ViPBusAddress64;

alias ViUInt32              ViEventType;
alias ViEventType*          ViPEventType;
alias ViEventType*          ViAEventType;
alias void*                 ViPAttrState;
alias ViAttr*               ViPAttr;
alias ViAttr*               ViAAttr;

alias ViString              ViKeyId;
alias ViPString             ViPKeyId;
alias ViUInt32              ViJobId;
alias ViJobId*              ViPJobId;
alias ViUInt32              ViAccessMode;
alias ViAccessMode*         ViPAccessMode;
alias ViBusAddress*         ViPBusAddress;
alias ViUInt32              ViEventFilter;

import std.c.stdarg : va_list;
alias va_list               ViVAList;
   
alias ViStatus function(ViSession vi, ViEventType eventType, ViEvent event, ViAddr userHandle) ViHndlr; 


/*- Resource Manager Functions and Operations -------------------------------*/

extern(Windows) ViStatus  viOpenDefaultRM (ViPSession vi);
extern(Windows) ViStatus  viFindRsrc      (ViSession sesn, ViString expr, ViPFindList vi,
                                    ViPUInt32 retCnt, ViChar [] desc);
extern(Windows) ViStatus  viFindNext      (ViFindList vi, ViChar[] desc);
extern(Windows) ViStatus  viParseRsrc     (ViSession rmSesn, ViRsrc rsrcName,
                                    ViPUInt16 intfType, ViPUInt16 intfNum);
extern(Windows) ViStatus  viParseRsrcEx   (ViSession rmSesn, ViRsrc rsrcName, ViPUInt16 intfType,
                                    ViPUInt16 intfNum, ViChar[] rsrcClass,
                                    ViChar[] expandedUnaliasedName,
                                    ViChar[]  aliasIfExists);
extern(Windows) ViStatus  viOpen          (ViSession sesn, ViRsrc name, ViAccessMode mode,
                                    ViUInt32 timeout, ViPSession vi);

/*- Resource Template Operations --------------------------------------------*/

extern(Windows) ViStatus  viClose         (ViObject vi);
extern(Windows) ViStatus  viSetAttribute  (ViObject vi, ViAttr attrName, ViAttrState attrValue);
extern(Windows) ViStatus  viGetAttribute  (ViObject vi, ViAttr attrName, void* attrValue);
extern(Windows) ViStatus  viStatusDesc    (ViObject vi, ViStatus status, ViChar  desc[]);
extern(Windows) ViStatus  viTerminate     (ViObject vi, ViUInt16 degree, ViJobId jobId);

extern(Windows) ViStatus  viLock          (ViSession vi, ViAccessMode lockType, ViUInt32 timeout,
                                    ViKeyId requestedKey, ViChar  accessKey[]);
extern(Windows) ViStatus  viUnlock        (ViSession vi);
extern(Windows) ViStatus  viEnableEvent   (ViSession vi, ViEventType eventType, ViUInt16 mechanism,
                                    ViEventFilter context);
extern(Windows) ViStatus  viDisableEvent  (ViSession vi, ViEventType eventType, ViUInt16 mechanism);
extern(Windows) ViStatus  viDiscardEvents (ViSession vi, ViEventType eventType, ViUInt16 mechanism);
extern(Windows) ViStatus  viWaitOnEvent   (ViSession vi, ViEventType inEventType, ViUInt32 timeout,
                                    ViPEventType outEventType, ViPEvent outContext);
extern(Windows) ViStatus  viInstallHandler(ViSession vi, ViEventType eventType, ViHndlr handler,
                                    ViAddr userHandle);
extern(Windows) ViStatus  viUninstallHandler(ViSession vi, ViEventType eventType, ViHndlr handler,
                                      ViAddr userHandle);

/*- Basic I/O Operations ----------------------------------------------------*/

extern(Windows) ViStatus  viRead          (ViSession vi, ViPBuf buf, ViUInt32 cnt, ViPUInt32 retCnt);
extern(Windows) ViStatus  viReadAsync     (ViSession vi, ViPBuf buf, ViUInt32 cnt, ViPJobId  jobId);
extern(Windows) ViStatus  viReadToFile    (ViSession vi, ViConstString filename, ViUInt32 cnt,
                                    ViPUInt32 retCnt);
extern(Windows) ViStatus  viWrite         (ViSession vi, ViBuf  buf, ViUInt32 cnt, ViPUInt32 retCnt);
extern(Windows) ViStatus  viWriteAsync    (ViSession vi, ViBuf  buf, ViUInt32 cnt, ViPJobId  jobId);
extern(Windows) ViStatus  viWriteFromFile (ViSession vi, ViConstString filename, ViUInt32 cnt,
                                    ViPUInt32 retCnt);
extern(Windows) ViStatus  viAssertTrigger (ViSession vi, ViUInt16 protocol);
extern(Windows) ViStatus  viReadSTB       (ViSession vi, ViPUInt16 status);
extern(Windows) ViStatus  viClear         (ViSession vi);

/*- Formatted and Buffered I/O Operations -----------------------------------*/

extern(Windows) ViStatus  viSetBuf        (ViSession vi, ViUInt16 mask, ViUInt32 size);
extern(Windows) ViStatus  viFlush         (ViSession vi, ViUInt16 mask);

extern(Windows) ViStatus  viBufWrite      (ViSession vi, ViBuf  buf, ViUInt32 cnt, ViPUInt32 retCnt);
extern(Windows) ViStatus  viBufRead       (ViSession vi, ViPBuf buf, ViUInt32 cnt, ViPUInt32 retCnt);

extern(C) ViStatus viPrintf        (ViSession vi, ViString writeFmt, ...);
extern(Windows) ViStatus  viVPrintf       (ViSession vi, ViString writeFmt, ViVAList params);
extern(C) ViStatus viSPrintf       (ViSession vi, ViPBuf buf, ViString writeFmt, ...);
extern(Windows) ViStatus  viVSPrintf      (ViSession vi, ViPBuf buf, ViString writeFmt,
                                    ViVAList parms);

extern(C) ViStatus viScanf         (ViSession vi, ViString readFmt, ...);
extern(Windows) ViStatus  viVScanf        (ViSession vi, ViString readFmt, ViVAList params);
extern(C) ViStatus viSScanf        (ViSession vi, ViBuf buf, ViString readFmt, ...);
extern(Windows) ViStatus  viVSScanf       (ViSession vi, ViBuf buf, ViString readFmt,
                                    ViVAList parms);

extern(C) ViStatus viQueryf        (ViSession vi, ViString writeFmt, ViString readFmt, ...);
extern(Windows) ViStatus  viVQueryf       (ViSession vi, ViString writeFmt, ViString readFmt, 
                                    ViVAList params);

/*- Memory I/O Operations ---------------------------------------------------*/

extern(Windows) ViStatus  viIn8           (ViSession vi, ViUInt16 space,
                                    ViBusAddress offset, ViPUInt8  val8);
extern(Windows) ViStatus  viOut8          (ViSession vi, ViUInt16 space,
                                    ViBusAddress offset, ViUInt8   val8);
extern(Windows) ViStatus  viIn16          (ViSession vi, ViUInt16 space,
                                    ViBusAddress offset, ViPUInt16 val16);
extern(Windows) ViStatus  viOut16         (ViSession vi, ViUInt16 space,
                                    ViBusAddress offset, ViUInt16  val16);
extern(Windows) ViStatus  viIn32          (ViSession vi, ViUInt16 space,
                                    ViBusAddress offset, ViPUInt32 val32);
extern(Windows) ViStatus  viOut32         (ViSession vi, ViUInt16 space,
                                    ViBusAddress offset, ViUInt32  val32);

extern(Windows) ViStatus  viIn64          (ViSession vi, ViUInt16 space,
                                    ViBusAddress offset, ViPUInt64 val64);
extern(Windows) ViStatus  viOut64         (ViSession vi, ViUInt16 space,
                                    ViBusAddress offset, ViUInt64  val64);

extern(Windows) ViStatus  viIn8Ex         (ViSession vi, ViUInt16 space,
                                    ViBusAddress64 offset, ViPUInt8  val8);
extern(Windows) ViStatus  viOut8Ex        (ViSession vi, ViUInt16 space,
                                    ViBusAddress64 offset, ViUInt8   val8);
extern(Windows) ViStatus  viIn16Ex        (ViSession vi, ViUInt16 space,
                                    ViBusAddress64 offset, ViPUInt16 val16);
extern(Windows) ViStatus  viOut16Ex       (ViSession vi, ViUInt16 space,
                                    ViBusAddress64 offset, ViUInt16  val16);
extern(Windows) ViStatus  viIn32Ex        (ViSession vi, ViUInt16 space,
                                    ViBusAddress64 offset, ViPUInt32 val32);
extern(Windows) ViStatus  viOut32Ex       (ViSession vi, ViUInt16 space,
                                    ViBusAddress64 offset, ViUInt32  val32);
extern(Windows) ViStatus  viIn64Ex        (ViSession vi, ViUInt16 space,
                                    ViBusAddress64 offset, ViPUInt64 val64);
extern(Windows) ViStatus  viOut64Ex       (ViSession vi, ViUInt16 space,
                                    ViBusAddress64 offset, ViUInt64  val64);

extern(Windows) ViStatus  viMoveIn8       (ViSession vi, ViUInt16 space, ViBusAddress offset,
                                    ViBusSize length, ViAUInt8  buf8);
extern(Windows) ViStatus  viMoveOut8      (ViSession vi, ViUInt16 space, ViBusAddress offset,
                                    ViBusSize length, ViAUInt8  buf8);
extern(Windows) ViStatus  viMoveIn16      (ViSession vi, ViUInt16 space, ViBusAddress offset,
                                    ViBusSize length, ViAUInt16 buf16);
extern(Windows) ViStatus  viMoveOut16     (ViSession vi, ViUInt16 space, ViBusAddress offset,
                                    ViBusSize length, ViAUInt16 buf16);
extern(Windows) ViStatus  viMoveIn32      (ViSession vi, ViUInt16 space, ViBusAddress offset,
                                    ViBusSize length, ViAUInt32 buf32);
extern(Windows) ViStatus  viMoveOut32     (ViSession vi, ViUInt16 space, ViBusAddress offset,
                                    ViBusSize length, ViAUInt32 buf32);

extern(Windows) ViStatus  viMoveIn64      (ViSession vi, ViUInt16 space, ViBusAddress offset,
                                    ViBusSize length, ViAUInt64 buf64);
extern(Windows) ViStatus  viMoveOut64     (ViSession vi, ViUInt16 space, ViBusAddress offset,
                                    ViBusSize length, ViAUInt64 buf64);

extern(Windows) ViStatus  viMoveIn8Ex     (ViSession vi, ViUInt16 space, ViBusAddress64 offset,
                                    ViBusSize length, ViAUInt8  buf8);
extern(Windows) ViStatus  viMoveOut8Ex    (ViSession vi, ViUInt16 space, ViBusAddress64 offset,
                                    ViBusSize length, ViAUInt8  buf8);
extern(Windows) ViStatus  viMoveIn16Ex    (ViSession vi, ViUInt16 space, ViBusAddress64 offset,
                                    ViBusSize length, ViAUInt16 buf16);
extern(Windows) ViStatus  viMoveOut16Ex   (ViSession vi, ViUInt16 space, ViBusAddress64 offset,
                                    ViBusSize length, ViAUInt16 buf16);
extern(Windows) ViStatus  viMoveIn32Ex    (ViSession vi, ViUInt16 space, ViBusAddress64 offset,
                                    ViBusSize length, ViAUInt32 buf32);
extern(Windows) ViStatus  viMoveOut32Ex   (ViSession vi, ViUInt16 space, ViBusAddress64 offset,
                                    ViBusSize length, ViAUInt32 buf32);
extern(Windows) ViStatus  viMoveIn64Ex    (ViSession vi, ViUInt16 space, ViBusAddress64 offset,
                                    ViBusSize length, ViAUInt64 buf64);
extern(Windows) ViStatus  viMoveOut64Ex   (ViSession vi, ViUInt16 space, ViBusAddress64 offset,
                                    ViBusSize length, ViAUInt64 buf64);

extern(Windows) ViStatus  viMove          (ViSession vi, ViUInt16 srcSpace, ViBusAddress srcOffset,
                                    ViUInt16 srcWidth, ViUInt16 destSpace, 
                                    ViBusAddress destOffset, ViUInt16 destWidth, 
                                    ViBusSize srcLength); 
extern(Windows) ViStatus  viMoveAsync     (ViSession vi, ViUInt16 srcSpace, ViBusAddress srcOffset,
                                    ViUInt16 srcWidth, ViUInt16 destSpace, 
                                    ViBusAddress destOffset, ViUInt16 destWidth, 
                                    ViBusSize srcLength, ViPJobId jobId);

extern(Windows) ViStatus  viMoveEx        (ViSession vi, ViUInt16 srcSpace, ViBusAddress64 srcOffset,
                                    ViUInt16 srcWidth, ViUInt16 destSpace, 
                                    ViBusAddress64 destOffset, ViUInt16 destWidth, 
                                    ViBusSize srcLength); 
extern(Windows) ViStatus  viMoveAsyncEx   (ViSession vi, ViUInt16 srcSpace, ViBusAddress64 srcOffset,
                                    ViUInt16 srcWidth, ViUInt16 destSpace, 
                                    ViBusAddress64 destOffset, ViUInt16 destWidth, 
                                    ViBusSize srcLength, ViPJobId jobId);

extern(Windows) ViStatus  viMapAddress    (ViSession vi, ViUInt16 mapSpace, ViBusAddress mapOffset,
                                    ViBusSize mapSize, ViBoolean access,
                                    ViAddr suggested, ViPAddr address);
extern(Windows) ViStatus  viUnmapAddress  (ViSession vi);

extern(Windows) ViStatus  viMapAddressEx  (ViSession vi, ViUInt16 mapSpace, ViBusAddress64 mapOffset,
                                    ViBusSize mapSize, ViBoolean access,
                                    ViAddr suggested, ViPAddr address);

extern(Windows) void  viPeek8         (ViSession vi, ViAddr address, ViPUInt8  val8);
extern(Windows) void  viPoke8         (ViSession vi, ViAddr address, ViUInt8   val8);
extern(Windows) void  viPeek16        (ViSession vi, ViAddr address, ViPUInt16 val16);
extern(Windows) void  viPoke16        (ViSession vi, ViAddr address, ViUInt16  val16);
extern(Windows) void  viPeek32        (ViSession vi, ViAddr address, ViPUInt32 val32);
extern(Windows) void  viPoke32        (ViSession vi, ViAddr address, ViUInt32  val32);

extern(Windows) void  viPeek64        (ViSession vi, ViAddr address, ViPUInt64 val64);
extern(Windows) void  viPoke64        (ViSession vi, ViAddr address, ViUInt64  val64);

/*- Shared Memory Operations ------------------------------------------------*/

extern(Windows) ViStatus  viMemAlloc      (ViSession vi, ViBusSize size, ViPBusAddress offset);
extern(Windows) ViStatus  viMemFree       (ViSession vi, ViBusAddress offset);

extern(Windows) ViStatus  viMemAllocEx    (ViSession vi, ViBusSize size, ViPBusAddress64 offset);
extern(Windows) ViStatus  viMemFreeEx     (ViSession vi, ViBusAddress64 offset);

/*- Interface Specific Operations -------------------------------------------*/

extern(Windows) ViStatus  viGpibControlREN(ViSession vi, ViUInt16 mode);
extern(Windows) ViStatus  viGpibControlATN(ViSession vi, ViUInt16 mode);
extern(Windows) ViStatus  viGpibSendIFC   (ViSession vi);
extern(Windows) ViStatus  viGpibCommand   (ViSession vi, ViBuf cmd, ViUInt32 cnt, ViPUInt32 retCnt);
extern(Windows) ViStatus  viGpibPassControl(ViSession vi, ViUInt16 primAddr, ViUInt16 secAddr);

extern(Windows) ViStatus  viVxiCommandQuery(ViSession vi, ViUInt16 mode, ViUInt32 cmd,
                                     ViPUInt32 response);
extern(Windows) ViStatus  viAssertUtilSignal(ViSession vi, ViUInt16 line);
extern(Windows) ViStatus  viAssertIntrSignal(ViSession vi, ViInt16 mode, ViUInt32 statusID);
extern(Windows) ViStatus  viMapTrigger    (ViSession vi, ViInt16 trigSrc, ViInt16 trigDest, 
                                    ViUInt16 mode);
extern(Windows) ViStatus  viUnmapTrigger  (ViSession vi, ViInt16 trigSrc, ViInt16 trigDest);
extern(Windows) ViStatus  viUsbControlOut (ViSession vi, ViInt16 bmRequestType, ViInt16 bRequest,
                                    ViUInt16 wValue, ViUInt16 wIndex, ViUInt16 wLength,
                                    ViBuf buf);
extern(Windows) ViStatus  viUsbControlIn  (ViSession vi, ViInt16 bmRequestType, ViInt16 bRequest,
                                    ViUInt16 wValue, ViUInt16 wIndex, ViUInt16 wLength,
                                    ViPBuf buf, ViPUInt16 retCnt);
extern(Windows) ViStatus  viPxiReserveTriggers(ViSession vi, ViInt16 cnt, ViAInt16 trigBuses,
                                    ViAInt16 trigLines, ViPInt16 failureIndex);

/*- Attributes (platform independent size) ----------------------------------*/

enum VI_ATTR_RSRC_CLASS                    = 0xBFFF0001U;
enum VI_ATTR_RSRC_NAME                     = 0xBFFF0002U;
enum VI_ATTR_RSRC_IMPL_VERSION             = 0x3FFF0003U;
enum VI_ATTR_RSRC_LOCK_STATE               = 0x3FFF0004U;
enum VI_ATTR_MAX_QUEUE_LENGTH              = 0x3FFF0005U;
enum VI_ATTR_USER_DATA_32                  = 0x3FFF0007U;
enum VI_ATTR_FDC_CHNL                      = 0x3FFF000DU;
enum VI_ATTR_FDC_MODE                      = 0x3FFF000FU;
enum VI_ATTR_FDC_GEN_SIGNAL_EN             = 0x3FFF0011U;
enum VI_ATTR_FDC_USE_PAIR                  = 0x3FFF0013U;
enum VI_ATTR_SEND_END_EN                   = 0x3FFF0016U;
enum VI_ATTR_TERMCHAR                      = 0x3FFF0018U;
enum VI_ATTR_TMO_VALUE                     = 0x3FFF001AU;
enum VI_ATTR_GPIB_READDR_EN                = 0x3FFF001BU;
enum VI_ATTR_IO_PROT                       = 0x3FFF001CU;
enum VI_ATTR_DMA_ALLOW_EN                  = 0x3FFF001EU;
enum VI_ATTR_ASRL_BAUD                     = 0x3FFF0021U;
enum VI_ATTR_ASRL_DATA_BITS                = 0x3FFF0022U;
enum VI_ATTR_ASRL_PARITY                   = 0x3FFF0023U;
enum VI_ATTR_ASRL_STOP_BITS                = 0x3FFF0024U;
enum VI_ATTR_ASRL_FLOW_CNTRL               = 0x3FFF0025U;
enum VI_ATTR_RD_BUF_OPER_MODE              = 0x3FFF002AU;
enum VI_ATTR_RD_BUF_SIZE                   = 0x3FFF002BU;
enum VI_ATTR_WR_BUF_OPER_MODE              = 0x3FFF002DU;
enum VI_ATTR_WR_BUF_SIZE                   = 0x3FFF002EU;
enum VI_ATTR_SUPPRESS_END_EN               = 0x3FFF0036U;
enum VI_ATTR_TERMCHAR_EN                   = 0x3FFF0038U;
enum VI_ATTR_DEST_ACCESS_PRIV              = 0x3FFF0039U;
enum VI_ATTR_DEST_BYTE_ORDER               = 0x3FFF003AU;
enum VI_ATTR_SRC_ACCESS_PRIV               = 0x3FFF003CU;
enum VI_ATTR_SRC_BYTE_ORDER                = 0x3FFF003DU;
enum VI_ATTR_SRC_INCREMENT                 = 0x3FFF0040U;
enum VI_ATTR_DEST_INCREMENT                = 0x3FFF0041U;
enum VI_ATTR_WIN_ACCESS_PRIV               = 0x3FFF0045U;
enum VI_ATTR_WIN_BYTE_ORDER                = 0x3FFF0047U;
enum VI_ATTR_GPIB_ATN_STATE                = 0x3FFF0057U;
enum VI_ATTR_GPIB_ADDR_STATE               = 0x3FFF005CU;
enum VI_ATTR_GPIB_CIC_STATE                = 0x3FFF005EU;
enum VI_ATTR_GPIB_NDAC_STATE               = 0x3FFF0062U;
enum VI_ATTR_GPIB_SRQ_STATE                = 0x3FFF0067U;
enum VI_ATTR_GPIB_SYS_CNTRL_STATE          = 0x3FFF0068U;
enum VI_ATTR_GPIB_HS488_CBL_LEN            = 0x3FFF0069U;
enum VI_ATTR_CMDR_LA                       = 0x3FFF006BU;
enum VI_ATTR_VXI_DEV_CLASS                 = 0x3FFF006CU;
enum VI_ATTR_MAINFRAME_LA                  = 0x3FFF0070U;
enum VI_ATTR_MANF_NAME                     = 0xBFFF0072U;
enum VI_ATTR_MODEL_NAME                    = 0xBFFF0077U;
enum VI_ATTR_VXI_VME_INTR_STATUS           = 0x3FFF008BU;
enum VI_ATTR_VXI_TRIG_STATUS               = 0x3FFF008DU;
enum VI_ATTR_VXI_VME_SYSFAIL_STATE         = 0x3FFF0094U;
enum VI_ATTR_WIN_BASE_ADDR_32              = 0x3FFF0098U;
enum VI_ATTR_WIN_SIZE_32                   = 0x3FFF009AU;
enum VI_ATTR_ASRL_AVAIL_NUM                = 0x3FFF00ACU;
enum VI_ATTR_MEM_BASE_32                   = 0x3FFF00ADU;
enum VI_ATTR_ASRL_CTS_STATE                = 0x3FFF00AEU;
enum VI_ATTR_ASRL_DCD_STATE                = 0x3FFF00AFU;
enum VI_ATTR_ASRL_DSR_STATE                = 0x3FFF00B1U;
enum VI_ATTR_ASRL_DTR_STATE                = 0x3FFF00B2U;
enum VI_ATTR_ASRL_END_IN                   = 0x3FFF00B3U;
enum VI_ATTR_ASRL_END_OUT                  = 0x3FFF00B4U;
enum VI_ATTR_ASRL_REPLACE_CHAR             = 0x3FFF00BEU;
enum VI_ATTR_ASRL_RI_STATE                 = 0x3FFF00BFU;
enum VI_ATTR_ASRL_RTS_STATE                = 0x3FFF00C0U;
enum VI_ATTR_ASRL_XON_CHAR                 = 0x3FFF00C1U;
enum VI_ATTR_ASRL_XOFF_CHAR                = 0x3FFF00C2U;
enum VI_ATTR_WIN_ACCESS                    = 0x3FFF00C3U;
enum VI_ATTR_RM_SESSION                    = 0x3FFF00C4U;
enum VI_ATTR_VXI_LA                        = 0x3FFF00D5U;
enum VI_ATTR_MANF_ID                       = 0x3FFF00D9U;
enum VI_ATTR_MEM_SIZE_32                   = 0x3FFF00DDU;
enum VI_ATTR_MEM_SPACE                     = 0x3FFF00DEU;
enum VI_ATTR_MODEL_CODE                    = 0x3FFF00DFU;
enum VI_ATTR_SLOT                          = 0x3FFF00E8U;
enum VI_ATTR_INTF_INST_NAME                = 0xBFFF00E9U;
enum VI_ATTR_IMMEDIATE_SERV                = 0x3FFF0100U;
enum VI_ATTR_INTF_PARENT_NUM               = 0x3FFF0101U;
enum VI_ATTR_RSRC_SPEC_VERSION             = 0x3FFF0170U;
enum VI_ATTR_INTF_TYPE                     = 0x3FFF0171U;
enum VI_ATTR_GPIB_PRIMARY_ADDR             = 0x3FFF0172U;
enum VI_ATTR_GPIB_SECONDARY_ADDR           = 0x3FFF0173U;
enum VI_ATTR_RSRC_MANF_NAME                = 0xBFFF0174U;
enum VI_ATTR_RSRC_MANF_ID                  = 0x3FFF0175U;
enum VI_ATTR_INTF_NUM                      = 0x3FFF0176U;
enum VI_ATTR_TRIG_ID                       = 0x3FFF0177U;
enum VI_ATTR_GPIB_REN_STATE                = 0x3FFF0181U;
enum VI_ATTR_GPIB_UNADDR_EN                = 0x3FFF0184U;
enum VI_ATTR_DEV_STATUS_BYTE               = 0x3FFF0189U;
enum VI_ATTR_FILE_APPEND_EN                = 0x3FFF0192U;
enum VI_ATTR_VXI_TRIG_SUPPORT              = 0x3FFF0194U;
enum VI_ATTR_TCPIP_ADDR                    = 0xBFFF0195U;
enum VI_ATTR_TCPIP_HOSTNAME                = 0xBFFF0196U;
enum VI_ATTR_TCPIP_PORT                    = 0x3FFF0197U;
enum VI_ATTR_TCPIP_DEVICE_NAME             = 0xBFFF0199U;
enum VI_ATTR_TCPIP_NODELAY                 = 0x3FFF019AU;
enum VI_ATTR_TCPIP_KEEPALIVE               = 0x3FFF019BU;
enum VI_ATTR_4882_COMPLIANT                = 0x3FFF019FU;
enum VI_ATTR_USB_SERIAL_NUM                = 0xBFFF01A0U;
enum VI_ATTR_USB_INTFC_NUM                 = 0x3FFF01A1U;
enum VI_ATTR_USB_PROTOCOL                  = 0x3FFF01A7U;
enum VI_ATTR_USB_MAX_INTR_SIZE             = 0x3FFF01AFU;
enum VI_ATTR_PXI_DEV_NUM                   = 0x3FFF0201U;
enum VI_ATTR_PXI_FUNC_NUM                  = 0x3FFF0202U;
enum VI_ATTR_PXI_BUS_NUM                   = 0x3FFF0205U;
enum VI_ATTR_PXI_CHASSIS                   = 0x3FFF0206U;
enum VI_ATTR_PXI_SLOTPATH                  = 0xBFFF0207U;
enum VI_ATTR_PXI_SLOT_LBUS_LEFT            = 0x3FFF0208U;
enum VI_ATTR_PXI_SLOT_LBUS_RIGHT           = 0x3FFF0209U;
enum VI_ATTR_PXI_TRIG_BUS                  = 0x3FFF020AU;
enum VI_ATTR_PXI_STAR_TRIG_BUS             = 0x3FFF020BU;
enum VI_ATTR_PXI_STAR_TRIG_LINE            = 0x3FFF020CU;
enum VI_ATTR_PXI_SRC_TRIG_BUS              = 0x3FFF020DU;
enum VI_ATTR_PXI_DEST_TRIG_BUS             = 0x3FFF020EU;
enum VI_ATTR_PXI_MEM_TYPE_BAR0             = 0x3FFF0211U;
enum VI_ATTR_PXI_MEM_TYPE_BAR1             = 0x3FFF0212U;
enum VI_ATTR_PXI_MEM_TYPE_BAR2             = 0x3FFF0213U;
enum VI_ATTR_PXI_MEM_TYPE_BAR3             = 0x3FFF0214U;
enum VI_ATTR_PXI_MEM_TYPE_BAR4             = 0x3FFF0215U;
enum VI_ATTR_PXI_MEM_TYPE_BAR5             = 0x3FFF0216U;
enum VI_ATTR_PXI_MEM_BASE_BAR0_32          = 0x3FFF0221U;
enum VI_ATTR_PXI_MEM_BASE_BAR1_32          = 0x3FFF0222U;
enum VI_ATTR_PXI_MEM_BASE_BAR2_32          = 0x3FFF0223U;
enum VI_ATTR_PXI_MEM_BASE_BAR3_32          = 0x3FFF0224U;
enum VI_ATTR_PXI_MEM_BASE_BAR4_32          = 0x3FFF0225U;
enum VI_ATTR_PXI_MEM_BASE_BAR5_32          = 0x3FFF0226U;
enum VI_ATTR_PXI_MEM_BASE_BAR0_64          = 0x3FFF0228U;
enum VI_ATTR_PXI_MEM_BASE_BAR1_64          = 0x3FFF0229U;
enum VI_ATTR_PXI_MEM_BASE_BAR2_64          = 0x3FFF022AU;
enum VI_ATTR_PXI_MEM_BASE_BAR3_64          = 0x3FFF022BU;
enum VI_ATTR_PXI_MEM_BASE_BAR4_64          = 0x3FFF022CU;
enum VI_ATTR_PXI_MEM_BASE_BAR5_64          = 0x3FFF022DU;
enum VI_ATTR_PXI_MEM_SIZE_BAR0_32          = 0x3FFF0231U;
enum VI_ATTR_PXI_MEM_SIZE_BAR1_32          = 0x3FFF0232U;
enum VI_ATTR_PXI_MEM_SIZE_BAR2_32          = 0x3FFF0233U;
enum VI_ATTR_PXI_MEM_SIZE_BAR3_32          = 0x3FFF0234U;
enum VI_ATTR_PXI_MEM_SIZE_BAR4_32          = 0x3FFF0235U;
enum VI_ATTR_PXI_MEM_SIZE_BAR5_32          = 0x3FFF0236U;
enum VI_ATTR_PXI_MEM_SIZE_BAR0_64          = 0x3FFF0238U;
enum VI_ATTR_PXI_MEM_SIZE_BAR1_64          = 0x3FFF0239U;
enum VI_ATTR_PXI_MEM_SIZE_BAR2_64          = 0x3FFF023AU;
enum VI_ATTR_PXI_MEM_SIZE_BAR3_64          = 0x3FFF023BU;
enum VI_ATTR_PXI_MEM_SIZE_BAR4_64          = 0x3FFF023CU;
enum VI_ATTR_PXI_MEM_SIZE_BAR5_64          = 0x3FFF023DU;
enum VI_ATTR_PXI_IS_EXPRESS                = 0x3FFF0240U;
enum VI_ATTR_PXI_SLOT_LWIDTH               = 0x3FFF0241U;
enum VI_ATTR_PXI_MAX_LWIDTH                = 0x3FFF0242U;
enum VI_ATTR_PXI_ACTUAL_LWIDTH             = 0x3FFF0243U;
enum VI_ATTR_PXI_DSTAR_BUS                 = 0x3FFF0244U;
enum VI_ATTR_PXI_DSTAR_SET                 = 0x3FFF0245U;
enum VI_ATTR_PXI_ALLOW_WRITE_COMBINE       = 0x3FFF0246U;
enum VI_ATTR_TCPIP_HISLIP_OVERLAP_EN       = 0x3FFF0300U;
enum VI_ATTR_TCPIP_HISLIP_VERSION          = 0x3FFF0301U;
enum VI_ATTR_TCPIP_HISLIP_MAX_MESSAGE_KB   = 0x3FFF0302U;

enum VI_ATTR_JOB_ID                        = 0x3FFF4006U;
enum VI_ATTR_EVENT_TYPE                    = 0x3FFF4010U;
enum VI_ATTR_SIGP_STATUS_ID                = 0x3FFF4011U;
enum VI_ATTR_RECV_TRIG_ID                  = 0x3FFF4012U;
enum VI_ATTR_INTR_STATUS_ID                = 0x3FFF4023U;
enum VI_ATTR_STATUS                        = 0x3FFF4025U;
enum VI_ATTR_RET_COUNT_32                  = 0x3FFF4026U;
enum VI_ATTR_BUFFER                        = 0x3FFF4027U;
enum VI_ATTR_RECV_INTR_LEVEL               = 0x3FFF4041U;
enum VI_ATTR_OPER_NAME                     = 0xBFFF4042U;
enum VI_ATTR_GPIB_RECV_CIC_STATE           = 0x3FFF4193U;
enum VI_ATTR_RECV_TCPIP_ADDR               = 0xBFFF4198U;
enum VI_ATTR_USB_RECV_INTR_SIZE            = 0x3FFF41B0U;
enum VI_ATTR_USB_RECV_INTR_DATA            = 0xBFFF41B1U;
enum VI_ATTR_PXI_RECV_INTR_SEQ             = 0x3FFF4240U;
enum VI_ATTR_PXI_RECV_INTR_DATA            = 0x3FFF4241U;

/*- Attributes (platform dependent size) ------------------------------------*/

version(D_LP64){
    enum VI_ATTR_USER_DATA_64                  = 0x3FFF000AU;
    enum VI_ATTR_RET_COUNT_64                  = 0x3FFF4028U;
    enum VI_ATTR_USER_DATA                     = VI_ATTR_USER_DATA_64;
    enum VI_ATTR_RET_COUNT                     = VI_ATTR_RET_COUNT_64;
}else{
    enum VI_ATTR_USER_DATA                     = VI_ATTR_USER_DATA_32;
    enum VI_ATTR_RET_COUNT                     = VI_ATTR_RET_COUNT_32;
}

enum VI_ATTR_WIN_BASE_ADDR_64              = 0x3FFF009BU;
enum VI_ATTR_WIN_SIZE_64                   = 0x3FFF009CU;
enum VI_ATTR_MEM_BASE_64                   = 0x3FFF00D0U;
enum VI_ATTR_MEM_SIZE_64                   = 0x3FFF00D1U;

version(D_LP64){
    enum VI_ATTR_WIN_BASE_ADDR              = VI_ATTR_WIN_BASE_ADDR_64;
    enum VI_ATTR_WIN_SIZE                      = VI_ATTR_WIN_SIZE_64;
    enum VI_ATTR_MEM_BASE                      = VI_ATTR_MEM_BASE_64;
    enum VI_ATTR_MEM_SIZE                      = VI_ATTR_MEM_SIZE_64;
    enum VI_ATTR_PXI_MEM_BASE_BAR0             = VI_ATTR_PXI_MEM_BASE_BAR0_64;
    enum VI_ATTR_PXI_MEM_BASE_BAR1             = VI_ATTR_PXI_MEM_BASE_BAR1_64;
    enum VI_ATTR_PXI_MEM_BASE_BAR2             = VI_ATTR_PXI_MEM_BASE_BAR2_64;
    enum VI_ATTR_PXI_MEM_BASE_BAR3             = VI_ATTR_PXI_MEM_BASE_BAR3_64;
    enum VI_ATTR_PXI_MEM_BASE_BAR4             = VI_ATTR_PXI_MEM_BASE_BAR4_64;
    enum VI_ATTR_PXI_MEM_BASE_BAR5             = VI_ATTR_PXI_MEM_BASE_BAR5_64;
    enum VI_ATTR_PXI_MEM_SIZE_BAR0             = VI_ATTR_PXI_MEM_SIZE_BAR0_64;
    enum VI_ATTR_PXI_MEM_SIZE_BAR1             = VI_ATTR_PXI_MEM_SIZE_BAR1_64;
    enum VI_ATTR_PXI_MEM_SIZE_BAR2             = VI_ATTR_PXI_MEM_SIZE_BAR2_64;
    enum VI_ATTR_PXI_MEM_SIZE_BAR3             = VI_ATTR_PXI_MEM_SIZE_BAR3_64;
    enum VI_ATTR_PXI_MEM_SIZE_BAR4             = VI_ATTR_PXI_MEM_SIZE_BAR4_64;
    enum VI_ATTR_PXI_MEM_SIZE_BAR5             = VI_ATTR_PXI_MEM_SIZE_BAR5_64;
}else{
    enum VI_ATTR_WIN_BASE_ADDR                 = VI_ATTR_WIN_BASE_ADDR_32;
    enum VI_ATTR_WIN_SIZE                      = VI_ATTR_WIN_SIZE_32;
    enum VI_ATTR_MEM_BASE                      = VI_ATTR_MEM_BASE_32;
    enum VI_ATTR_MEM_SIZE                      = VI_ATTR_MEM_SIZE_32;
    enum VI_ATTR_PXI_MEM_BASE_BAR0             = VI_ATTR_PXI_MEM_BASE_BAR0_32;
    enum VI_ATTR_PXI_MEM_BASE_BAR1             = VI_ATTR_PXI_MEM_BASE_BAR1_32;
    enum VI_ATTR_PXI_MEM_BASE_BAR2             = VI_ATTR_PXI_MEM_BASE_BAR2_32;
    enum VI_ATTR_PXI_MEM_BASE_BAR3             = VI_ATTR_PXI_MEM_BASE_BAR3_32;
    enum VI_ATTR_PXI_MEM_BASE_BAR4             = VI_ATTR_PXI_MEM_BASE_BAR4_32;
    enum VI_ATTR_PXI_MEM_BASE_BAR5             = VI_ATTR_PXI_MEM_BASE_BAR5_32;
    enum VI_ATTR_PXI_MEM_SIZE_BAR0             = VI_ATTR_PXI_MEM_SIZE_BAR0_32;
    enum VI_ATTR_PXI_MEM_SIZE_BAR1             = VI_ATTR_PXI_MEM_SIZE_BAR1_32;
    enum VI_ATTR_PXI_MEM_SIZE_BAR2             = VI_ATTR_PXI_MEM_SIZE_BAR2_32;
    enum VI_ATTR_PXI_MEM_SIZE_BAR3             = VI_ATTR_PXI_MEM_SIZE_BAR3_32;
    enum VI_ATTR_PXI_MEM_SIZE_BAR4             = VI_ATTR_PXI_MEM_SIZE_BAR4_32;
    enum VI_ATTR_PXI_MEM_SIZE_BAR5             = VI_ATTR_PXI_MEM_SIZE_BAR5_32;
}

/*- Event Types -------------------------------------------------------------*/

enum VI_EVENT_IO_COMPLETION                = 0x3FFF2009U;
enum VI_EVENT_TRIG                         = 0xBFFF200AU;
enum VI_EVENT_SERVICE_REQ                  = 0x3FFF200BU;
enum VI_EVENT_CLEAR                        = 0x3FFF200DU;
enum VI_EVENT_EXCEPTION                    = 0xBFFF200EU;
enum VI_EVENT_GPIB_CIC                     = 0x3FFF2012U;
enum VI_EVENT_GPIB_TALK                    = 0x3FFF2013U;
enum VI_EVENT_GPIB_LISTEN                  = 0x3FFF2014U;
enum VI_EVENT_VXI_VME_SYSFAIL              = 0x3FFF201DU;
enum VI_EVENT_VXI_VME_SYSRESET             = 0x3FFF201EU;
enum VI_EVENT_VXI_SIGP                     = 0x3FFF2020U;
enum VI_EVENT_VXI_VME_INTR                 = 0xBFFF2021U;
enum VI_EVENT_PXI_INTR                     = 0x3FFF2022U;
enum VI_EVENT_TCPIP_CONNECT                = 0x3FFF2036U;
enum VI_EVENT_USB_INTR                     = 0x3FFF2037U;

enum VI_ALL_ENABLED_EVENTS                 = 0x3FFF7FFFU;

/*- Completion and Error Codes ----------------------------------------------*/

enum VI_SUCCESS_EVENT_EN                   = 0x3FFF0002L; /* 3FFF0002,  1073676290 */
enum VI_SUCCESS_EVENT_DIS                  = 0x3FFF0003L; /* 3FFF0003,  1073676291 */
enum VI_SUCCESS_QUEUE_EMPTY                = 0x3FFF0004L; /* 3FFF0004,  1073676292 */
enum VI_SUCCESS_TERM_CHAR                  = 0x3FFF0005L; /* 3FFF0005,  1073676293 */
enum VI_SUCCESS_MAX_CNT                    = 0x3FFF0006L; /* 3FFF0006,  1073676294 */
enum VI_SUCCESS_DEV_NPRESENT               = 0x3FFF007DL; /* 3FFF007D,  1073676413 */
enum VI_SUCCESS_TRIG_MAPPED                = 0x3FFF007EL; /* 3FFF007E,  1073676414 */
enum VI_SUCCESS_QUEUE_NEMPTY               = 0x3FFF0080L; /* 3FFF0080,  1073676416 */
enum VI_SUCCESS_NCHAIN                     = 0x3FFF0098L; /* 3FFF0098,  1073676440 */
enum VI_SUCCESS_NESTED_SHARED              = 0x3FFF0099L; /* 3FFF0099,  1073676441 */
enum VI_SUCCESS_NESTED_EXCLUSIVE           = 0x3FFF009AL; /* 3FFF009A,  1073676442 */
enum VI_SUCCESS_SYNC                       = 0x3FFF009BL; /* 3FFF009B,  1073676443 */

enum VI_WARN_QUEUE_OVERFLOW                = 0x3FFF000CL; /* 3FFF000C,  1073676300 */
enum VI_WARN_CONFIG_NLOADED                = 0x3FFF0077L; /* 3FFF0077,  1073676407 */
enum VI_WARN_NULL_OBJECT                   = 0x3FFF0082L; /* 3FFF0082,  1073676418 */
enum VI_WARN_NSUP_ATTR_STATE               = 0x3FFF0084L; /* 3FFF0084,  1073676420 */
enum VI_WARN_UNKNOWN_STATUS                = 0x3FFF0085L; /* 3FFF0085,  1073676421 */
enum VI_WARN_NSUP_BUF                      = 0x3FFF0088L; /* 3FFF0088,  1073676424 */
enum VI_WARN_EXT_FUNC_NIMPL                = 0x3FFF00A9L; /* 3FFF00A9,  1073676457 */

enum VI_ERROR_SYSTEM_ERROR       = _VI_ERROR+0x3FFF0000L; /* BFFF0000, -1073807360 */
enum VI_ERROR_INV_OBJECT         = _VI_ERROR+0x3FFF000EL; /* BFFF000E, -1073807346 */
enum VI_ERROR_RSRC_LOCKED        = _VI_ERROR+0x3FFF000FL; /* BFFF000F, -1073807345 */
enum VI_ERROR_INV_EXPR           = _VI_ERROR+0x3FFF0010L; /* BFFF0010, -1073807344 */
enum VI_ERROR_RSRC_NFOUND        = _VI_ERROR+0x3FFF0011L; /* BFFF0011, -1073807343 */
enum VI_ERROR_INV_RSRC_NAME      = _VI_ERROR+0x3FFF0012L; /* BFFF0012, -1073807342 */
enum VI_ERROR_INV_ACC_MODE       = _VI_ERROR+0x3FFF0013L; /* BFFF0013, -1073807341 */
enum VI_ERROR_TMO                = _VI_ERROR+0x3FFF0015L; /* BFFF0015, -1073807339 */
enum VI_ERROR_CLOSING_FAILED     = _VI_ERROR+0x3FFF0016L; /* BFFF0016, -1073807338 */
enum VI_ERROR_INV_DEGREE         = _VI_ERROR+0x3FFF001BL; /* BFFF001B, -1073807333 */
enum VI_ERROR_INV_JOB_ID         = _VI_ERROR+0x3FFF001CL; /* BFFF001C, -1073807332 */
enum VI_ERROR_NSUP_ATTR          = _VI_ERROR+0x3FFF001DL; /* BFFF001D, -1073807331 */
enum VI_ERROR_NSUP_ATTR_STATE    = _VI_ERROR+0x3FFF001EL; /* BFFF001E, -1073807330 */
enum VI_ERROR_ATTR_READONLY      = _VI_ERROR+0x3FFF001FL; /* BFFF001F, -1073807329 */
enum VI_ERROR_INV_LOCK_TYPE      = _VI_ERROR+0x3FFF0020L; /* BFFF0020, -1073807328 */
enum VI_ERROR_INV_ACCESS_KEY     = _VI_ERROR+0x3FFF0021L; /* BFFF0021, -1073807327 */
enum VI_ERROR_INV_EVENT          = _VI_ERROR+0x3FFF0026L; /* BFFF0026, -1073807322 */
enum VI_ERROR_INV_MECH           = _VI_ERROR+0x3FFF0027L; /* BFFF0027, -1073807321 */
enum VI_ERROR_HNDLR_NINSTALLED   = _VI_ERROR+0x3FFF0028L; /* BFFF0028, -1073807320 */
enum VI_ERROR_INV_HNDLR_REF      = _VI_ERROR+0x3FFF0029L; /* BFFF0029, -1073807319 */
enum VI_ERROR_INV_CONTEXT        = _VI_ERROR+0x3FFF002AL; /* BFFF002A, -1073807318 */
enum VI_ERROR_QUEUE_OVERFLOW     = _VI_ERROR+0x3FFF002DL; /* BFFF002D, -1073807315 */
enum VI_ERROR_NENABLED           = _VI_ERROR+0x3FFF002FL; /* BFFF002F, -1073807313 */
enum VI_ERROR_ABORT              = _VI_ERROR+0x3FFF0030L; /* BFFF0030, -1073807312 */
enum VI_ERROR_RAW_WR_PROT_VIOL   = _VI_ERROR+0x3FFF0034L; /* BFFF0034, -1073807308 */
enum VI_ERROR_RAW_RD_PROT_VIOL   = _VI_ERROR+0x3FFF0035L; /* BFFF0035, -1073807307 */
enum VI_ERROR_OUTP_PROT_VIOL     = _VI_ERROR+0x3FFF0036L; /* BFFF0036, -1073807306 */
enum VI_ERROR_INP_PROT_VIOL      = _VI_ERROR+0x3FFF0037L; /* BFFF0037, -1073807305 */
enum VI_ERROR_BERR               = _VI_ERROR+0x3FFF0038L; /* BFFF0038, -1073807304 */
enum VI_ERROR_IN_PROGRESS        = _VI_ERROR+0x3FFF0039L; /* BFFF0039, -1073807303 */
enum VI_ERROR_INV_SETUP          = _VI_ERROR+0x3FFF003AL; /* BFFF003A, -1073807302 */
enum VI_ERROR_QUEUE_ERROR        = _VI_ERROR+0x3FFF003BL; /* BFFF003B, -1073807301 */
enum VI_ERROR_ALLOC              = _VI_ERROR+0x3FFF003CL; /* BFFF003C, -1073807300 */
enum VI_ERROR_INV_MASK           = _VI_ERROR+0x3FFF003DL; /* BFFF003D, -1073807299 */
enum VI_ERROR_IO                 = _VI_ERROR+0x3FFF003EL; /* BFFF003E, -1073807298 */
enum VI_ERROR_INV_FMT            = _VI_ERROR+0x3FFF003FL; /* BFFF003F, -1073807297 */
enum VI_ERROR_NSUP_FMT           = _VI_ERROR+0x3FFF0041L; /* BFFF0041, -1073807295 */
enum VI_ERROR_LINE_IN_USE        = _VI_ERROR+0x3FFF0042L; /* BFFF0042, -1073807294 */
enum VI_ERROR_NSUP_MODE          = _VI_ERROR+0x3FFF0046L; /* BFFF0046, -1073807290 */
enum VI_ERROR_SRQ_NOCCURRED      = _VI_ERROR+0x3FFF004AL; /* BFFF004A, -1073807286 */
enum VI_ERROR_INV_SPACE          = _VI_ERROR+0x3FFF004EL; /* BFFF004E, -1073807282 */
enum VI_ERROR_INV_OFFSET         = _VI_ERROR+0x3FFF0051L; /* BFFF0051, -1073807279 */
enum VI_ERROR_INV_WIDTH          = _VI_ERROR+0x3FFF0052L; /* BFFF0052, -1073807278 */
enum VI_ERROR_NSUP_OFFSET        = _VI_ERROR+0x3FFF0054L; /* BFFF0054, -1073807276 */
enum VI_ERROR_NSUP_VAR_WIDTH     = _VI_ERROR+0x3FFF0055L; /* BFFF0055, -1073807275 */
enum VI_ERROR_WINDOW_NMAPPED     = _VI_ERROR+0x3FFF0057L; /* BFFF0057, -1073807273 */
enum VI_ERROR_RESP_PENDING       = _VI_ERROR+0x3FFF0059L; /* BFFF0059, -1073807271 */
enum VI_ERROR_NLISTENERS         = _VI_ERROR+0x3FFF005FL; /* BFFF005F, -1073807265 */
enum VI_ERROR_NCIC               = _VI_ERROR+0x3FFF0060L; /* BFFF0060, -1073807264 */
enum VI_ERROR_NSYS_CNTLR         = _VI_ERROR+0x3FFF0061L; /* BFFF0061, -1073807263 */
enum VI_ERROR_NSUP_OPER          = _VI_ERROR+0x3FFF0067L; /* BFFF0067, -1073807257 */
enum VI_ERROR_INTR_PENDING       = _VI_ERROR+0x3FFF0068L; /* BFFF0068, -1073807256 */
enum VI_ERROR_ASRL_PARITY        = _VI_ERROR+0x3FFF006AL; /* BFFF006A, -1073807254 */
enum VI_ERROR_ASRL_FRAMING       = _VI_ERROR+0x3FFF006BL; /* BFFF006B, -1073807253 */
enum VI_ERROR_ASRL_OVERRUN       = _VI_ERROR+0x3FFF006CL; /* BFFF006C, -1073807252 */
enum VI_ERROR_TRIG_NMAPPED       = _VI_ERROR+0x3FFF006EL; /* BFFF006E, -1073807250 */
enum VI_ERROR_NSUP_ALIGN_OFFSET  = _VI_ERROR+0x3FFF0070L; /* BFFF0070, -1073807248 */
enum VI_ERROR_USER_BUF           = _VI_ERROR+0x3FFF0071L; /* BFFF0071, -1073807247 */
enum VI_ERROR_RSRC_BUSY          = _VI_ERROR+0x3FFF0072L; /* BFFF0072, -1073807246 */
enum VI_ERROR_NSUP_WIDTH         = _VI_ERROR+0x3FFF0076L; /* BFFF0076, -1073807242 */
enum VI_ERROR_INV_PARAMETER      = _VI_ERROR+0x3FFF0078L; /* BFFF0078, -1073807240 */
enum VI_ERROR_INV_PROT           = _VI_ERROR+0x3FFF0079L; /* BFFF0079, -1073807239 */
enum VI_ERROR_INV_SIZE           = _VI_ERROR+0x3FFF007BL; /* BFFF007B, -1073807237 */
enum VI_ERROR_WINDOW_MAPPED      = _VI_ERROR+0x3FFF0080L; /* BFFF0080, -1073807232 */
enum VI_ERROR_NIMPL_OPER         = _VI_ERROR+0x3FFF0081L; /* BFFF0081, -1073807231 */
enum VI_ERROR_INV_LENGTH         = _VI_ERROR+0x3FFF0083L; /* BFFF0083, -1073807229 */
enum VI_ERROR_INV_MODE           = _VI_ERROR+0x3FFF0091L; /* BFFF0091, -1073807215 */
enum VI_ERROR_SESN_NLOCKED       = _VI_ERROR+0x3FFF009CL; /* BFFF009C, -1073807204 */
enum VI_ERROR_MEM_NSHARED        = _VI_ERROR+0x3FFF009DL; /* BFFF009D, -1073807203 */
enum VI_ERROR_LIBRARY_NFOUND     = _VI_ERROR+0x3FFF009EL; /* BFFF009E, -1073807202 */
enum VI_ERROR_NSUP_INTR          = _VI_ERROR+0x3FFF009FL; /* BFFF009F, -1073807201 */
enum VI_ERROR_INV_LINE           = _VI_ERROR+0x3FFF00A0L; /* BFFF00A0, -1073807200 */
enum VI_ERROR_FILE_ACCESS        = _VI_ERROR+0x3FFF00A1L; /* BFFF00A1, -1073807199 */
enum VI_ERROR_FILE_IO            = _VI_ERROR+0x3FFF00A2L; /* BFFF00A2, -1073807198 */
enum VI_ERROR_NSUP_LINE          = _VI_ERROR+0x3FFF00A3L; /* BFFF00A3, -1073807197 */
enum VI_ERROR_NSUP_MECH          = _VI_ERROR+0x3FFF00A4L; /* BFFF00A4, -1073807196 */
enum VI_ERROR_INTF_NUM_NCONFIG   = _VI_ERROR+0x3FFF00A5L; /* BFFF00A5, -1073807195 */
enum VI_ERROR_CONN_LOST          = _VI_ERROR+0x3FFF00A6L; /* BFFF00A6, -1073807194 */
enum VI_ERROR_MACHINE_NAVAIL     = _VI_ERROR+0x3FFF00A7L; /* BFFF00A7, -1073807193 */
enum VI_ERROR_NPERMISSION        = _VI_ERROR+0x3FFF00A8L; /* BFFF00A8, -1073807192 */

/*- Other VISA Definitions --------------------------------------------------*/
/*
enum VI_VERSION_MAJOR(ver)       ((((ViVersion)ver) & 0xFFF00000U; >> 20)
enum VI_VERSION_MINOR(ver)       ((((ViVersion)ver) & 0x000FFF00U; >>  8)
enum VI_VERSION_SUBMINOR(ver)    ((((ViVersion)ver) & 0x000000FFU;      )*/

enum VI_FIND_BUFLEN              = 256;

enum VI_INTF_GPIB                = 1;
enum VI_INTF_VXI                 = 2;
enum VI_INTF_GPIB_VXI            = 3;
enum VI_INTF_ASRL                = 4;
enum VI_INTF_PXI                 = 5;
enum VI_INTF_TCPIP               = 6;
enum VI_INTF_USB                 = 7;

enum VI_PROT_NORMAL              = 1;
enum VI_PROT_FDC                 = 2;
enum VI_PROT_HS488               = 3;
enum VI_PROT_4882_STRS           = 4;
enum VI_PROT_USBTMC_VENDOR       = 5;

enum VI_FDC_NORMAL               = 1;
enum VI_FDC_STREAM               = 2;

enum VI_LOCAL_SPACE              = 0;
enum VI_A16_SPACE                = 1;
enum VI_A24_SPACE                = 2;
enum VI_A32_SPACE                = 3;
enum VI_A64_SPACE                = 4;
enum VI_PXI_ALLOC_SPACE          = 9;
enum VI_PXI_CFG_SPACE            = 10;
enum VI_PXI_BAR0_SPACE           = 11;
enum VI_PXI_BAR1_SPACE           = 12;
enum VI_PXI_BAR2_SPACE           = 13;
enum VI_PXI_BAR3_SPACE           = 14;
enum VI_PXI_BAR4_SPACE           = 15;
enum VI_PXI_BAR5_SPACE           = 16;
enum VI_OPAQUE_SPACE             = 0xFFFF;

enum VI_UNKNOWN_LA               = -1;
enum VI_UNKNOWN_SLOT             = -1;
enum VI_UNKNOWN_LEVEL            = -1;
enum VI_UNKNOWN_CHASSIS          = -1;

enum VI_QUEUE                    = 1;
enum VI_HNDLR                    = 2;
enum VI_SUSPEND_HNDLR            = 4;
enum VI_ALL_MECH                 = 0xFFFF;

enum VI_ANY_HNDLR                = 0;

enum VI_TRIG_ALL                 = -2;
enum VI_TRIG_SW                  = -1;
enum VI_TRIG_TTL0                = 0;
enum VI_TRIG_TTL1                = 1;
enum VI_TRIG_TTL2                = 2;
enum VI_TRIG_TTL3                = 3;
enum VI_TRIG_TTL4                = 4;
enum VI_TRIG_TTL5                = 5;
enum VI_TRIG_TTL6                = 6;
enum VI_TRIG_TTL7                = 7;
enum VI_TRIG_ECL0                = 8;
enum VI_TRIG_ECL1                = 9;
enum VI_TRIG_ECL2                = 10;
enum VI_TRIG_ECL3                = 11;
enum VI_TRIG_ECL4                = 12;
enum VI_TRIG_ECL5                = 13;
enum VI_TRIG_STAR_SLOT1          = 14;
enum VI_TRIG_STAR_SLOT2          = 15;
enum VI_TRIG_STAR_SLOT3          = 16;
enum VI_TRIG_STAR_SLOT4          = 17;
enum VI_TRIG_STAR_SLOT5          = 18;
enum VI_TRIG_STAR_SLOT6          = 19;
enum VI_TRIG_STAR_SLOT7          = 20;
enum VI_TRIG_STAR_SLOT8          = 21;
enum VI_TRIG_STAR_SLOT9          = 22;
enum VI_TRIG_STAR_SLOT10         = 23;
enum VI_TRIG_STAR_SLOT11         = 24;
enum VI_TRIG_STAR_SLOT12         = 25;
enum VI_TRIG_STAR_INSTR          = 26;
enum VI_TRIG_PANEL_IN            = 27;
enum VI_TRIG_PANEL_OUT           = 28;
enum VI_TRIG_STAR_VXI0           = 29;
enum VI_TRIG_STAR_VXI1           = 30;
enum VI_TRIG_STAR_VXI2           = 31;

enum VI_TRIG_PROT_DEFAULT        = 0;
enum VI_TRIG_PROT_ON             = 1;
enum VI_TRIG_PROT_OFF            = 2;
enum VI_TRIG_PROT_SYNC           = 5;
enum VI_TRIG_PROT_RESERVE        = 6;
enum VI_TRIG_PROT_UNRESERVE      = 7;

enum VI_READ_BUF                 = 1;
enum VI_WRITE_BUF                = 2;
enum VI_READ_BUF_DISCARD         = 4;
enum VI_WRITE_BUF_DISCARD        = 8;
enum VI_IO_IN_BUF                = 16;
enum VI_IO_OUT_BUF               = 32;
enum VI_IO_IN_BUF_DISCARD        = 64;
enum VI_IO_OUT_BUF_DISCARD       = 128;

enum VI_FLUSH_ON_ACCESS          = 1;
enum VI_FLUSH_WHEN_FULL          = 2;
enum VI_FLUSH_DISABLE            = 3;

enum VI_NMAPPED                  = 1;
enum VI_USE_OPERS                = 2;
enum VI_DEREF_ADDR               = 3;
enum VI_DEREF_ADDR_BYTE_SWAP     = 4;

enum VI_TMO_IMMEDIATE            = 0L;
enum VI_TMO_INFINITE             = 0xFFFFFFFFU;

enum VI_NO_LOCK                  = 0;
enum VI_EXCLUSIVE_LOCK           = 1;
enum VI_SHARED_LOCK              = 2;
enum VI_LOAD_CONFIG              = 4;

enum VI_NO_SEC_ADDR              = 0xFFFF;

enum VI_ASRL_PAR_NONE            = 0;
enum VI_ASRL_PAR_ODD             = 1;
enum VI_ASRL_PAR_EVEN            = 2;
enum VI_ASRL_PAR_MARK            = 3;
enum VI_ASRL_PAR_SPACE           = 4;

enum VI_ASRL_STOP_ONE            = 10;
enum VI_ASRL_STOP_ONE5           = 15;
enum VI_ASRL_STOP_TWO            = 20;

enum VI_ASRL_FLOW_NONE           = 0;
enum VI_ASRL_FLOW_XON_XOFF       = 1;
enum VI_ASRL_FLOW_RTS_CTS        = 2;
enum VI_ASRL_FLOW_DTR_DSR        = 4;

enum VI_ASRL_END_NONE            = 0;
enum VI_ASRL_END_LAST_BIT        = 1;
enum VI_ASRL_END_TERMCHAR        = 2;
enum VI_ASRL_END_BREAK           = 3;

enum VI_STATE_ASSERTED           = 1;
enum VI_STATE_UNASSERTED         = 0;
enum VI_STATE_UNKNOWN            = -1;

enum VI_BIG_ENDIAN               = 0;
enum VI_LITTLE_ENDIAN            = 1;

enum VI_DATA_PRIV                = 0;
enum VI_DATA_NPRIV               = 1;
enum VI_PROG_PRIV                = 2;
enum VI_PROG_NPRIV               = 3;
enum VI_BLCK_PRIV                = 4;
enum VI_BLCK_NPRIV               = 5;
enum VI_D64_PRIV                 = 6;
enum VI_D64_NPRIV                = 7;
enum VI_D64_2EVME                = 8;
enum VI_D64_SST160               = 9;
enum VI_D64_SST267               = 10;
enum VI_D64_SST320               = 11;

enum VI_WIDTH_8                  = 1;
enum VI_WIDTH_16                 = 2;
enum VI_WIDTH_32                 = 4;
enum VI_WIDTH_64                 = 8;

enum VI_GPIB_REN_DEASSERT        = 0;
enum VI_GPIB_REN_ASSERT          = 1;
enum VI_GPIB_REN_DEASSERT_GTL    = 2;
enum VI_GPIB_REN_ASSERT_ADDRESS  = 3;
enum VI_GPIB_REN_ASSERT_LLO      = 4;
enum VI_GPIB_REN_ASSERT_ADDRESS_LLO = 5;
enum VI_GPIB_REN_ADDRESS_GTL     = 6;

enum VI_GPIB_ATN_DEASSERT        = 0;
enum VI_GPIB_ATN_ASSERT          = 1;
enum VI_GPIB_ATN_DEASSERT_HANDSHAKE = 2;
enum VI_GPIB_ATN_ASSERT_IMMEDIATE = 3;

enum VI_GPIB_HS488_DISABLED      = 0;
enum VI_GPIB_HS488_NIMPL         = -1;

enum VI_GPIB_UNADDRESSED         = 0;
enum VI_GPIB_TALKER              = 1;
enum VI_GPIB_LISTENER            = 2;

enum VI_VXI_CMD16                = 0x0200;
enum VI_VXI_CMD16_RESP16         = 0x0202;
enum VI_VXI_RESP16               = 0x0002;
enum VI_VXI_CMD32                = 0x0400;
enum VI_VXI_CMD32_RESP16         = 0x0402;
enum VI_VXI_CMD32_RESP32         = 0x0404;
enum VI_VXI_RESP32               = 0x0004;

enum VI_ASSERT_SIGNAL            = -1;
enum VI_ASSERT_USE_ASSIGNED      = 0;
enum VI_ASSERT_IRQ1              = 1;
enum VI_ASSERT_IRQ2              = 2;
enum VI_ASSERT_IRQ3              = 3;
enum VI_ASSERT_IRQ4              = 4;
enum VI_ASSERT_IRQ5              = 5;
enum VI_ASSERT_IRQ6              = 6;
enum VI_ASSERT_IRQ7              = 7;

enum VI_UTIL_ASSERT_SYSRESET     = 1;
enum VI_UTIL_ASSERT_SYSFAIL      = 2;
enum VI_UTIL_DEASSERT_SYSFAIL    = 3;

enum VI_VXI_CLASS_MEMORY         = 0;
enum VI_VXI_CLASS_EXTENDED       = 1;
enum VI_VXI_CLASS_MESSAGE        = 2;
enum VI_VXI_CLASS_REGISTER       = 3;
enum VI_VXI_CLASS_OTHER          = 4;

enum VI_PXI_ADDR_NONE            = 0;
enum VI_PXI_ADDR_MEM             = 1;
enum VI_PXI_ADDR_IO              = 2;
enum VI_PXI_ADDR_CFG             = 3;

enum VI_TRIG_UNKNOWN             = -1;

enum VI_PXI_LBUS_UNKNOWN         = -1;
enum VI_PXI_LBUS_NONE            = 0;
enum VI_PXI_LBUS_STAR_TRIG_BUS_0 = 1000;
enum VI_PXI_LBUS_STAR_TRIG_BUS_1 = 1001;
enum VI_PXI_LBUS_STAR_TRIG_BUS_2 = 1002;
enum VI_PXI_LBUS_STAR_TRIG_BUS_3 = 1003;
enum VI_PXI_LBUS_STAR_TRIG_BUS_4 = 1004;
enum VI_PXI_LBUS_STAR_TRIG_BUS_5 = 1005;
enum VI_PXI_LBUS_STAR_TRIG_BUS_6 = 1006;
enum VI_PXI_LBUS_STAR_TRIG_BUS_7 = 1007;
enum VI_PXI_LBUS_STAR_TRIG_BUS_8 = 1008;
enum VI_PXI_LBUS_STAR_TRIG_BUS_9 = 1009;
enum VI_PXI_STAR_TRIG_CONTROLLER = 1413;

/*- Backward Compatibility Macros -------------------------------------------*/
/*
enum viGetDefaultRM(vi)          viOpenDefaultRM(vi)*/
alias viOpenDefaultRM viGetDefaultRM;

enum VI_ERROR_INV_SESSION        = VI_ERROR_INV_OBJECT;
enum VI_INFINITE                 = VI_TMO_INFINITE;
enum VI_NORMAL                   = VI_PROT_NORMAL;
enum VI_FDC                      = VI_PROT_FDC;
enum VI_HS488                    = VI_PROT_HS488;
enum VI_ASRL488                  = VI_PROT_4882_STRS;
enum VI_ASRL_IN_BUF              = VI_IO_IN_BUF;
enum VI_ASRL_OUT_BUF             = VI_IO_OUT_BUF;
enum VI_ASRL_IN_BUF_DISCARD      = VI_IO_IN_BUF_DISCARD;
enum VI_ASRL_OUT_BUF_DISCARD     = VI_IO_OUT_BUF_DISCARD;

/*- National Instruments ----------------------------------------------------*/

enum VI_INTF_RIO                 = 8;
enum VI_INTF_FIREWIRE            = 9; 

enum VI_ATTR_SYNC_MXI_ALLOW_EN   = 0x3FFF0161U; /* ViBoolean, read/write */

/* This is for VXI SERVANT resources */

enum VI_EVENT_VXI_DEV_CMD        = 0xBFFF200FU;
enum VI_ATTR_VXI_DEV_CMD_TYPE    = 0x3FFF4037U; /* ViInt16, read-only */
enum VI_ATTR_VXI_DEV_CMD_VALUE   = 0x3FFF4038U; /* ViUInt32, read-only */

enum VI_VXI_DEV_CMD_TYPE_16      = 16;
enum VI_VXI_DEV_CMD_TYPE_32      = 32;

extern(Windows) ViStatus viVxiServantResponse(ViSession vi, ViInt16 mode, ViUInt32 resp);
/* mode values include VI_VXI_RESP16, VI_VXI_RESP32, and the next 2 values */
enum VI_VXI_RESP_NONE            = 0;
enum VI_VXI_RESP_PROT_ERROR      = -1;

/* This is for VXI TTL Trigger routing */

enum VI_ATTR_VXI_TRIG_LINES_EN   = 0x3FFF4043U;
enum VI_ATTR_VXI_TRIG_DIR        = 0x3FFF4044U;

/* This allows extended Serial support on Win32 and on NI ENET Serial products */

enum VI_ATTR_ASRL_DISCARD_NULL   = 0x3FFF00B0U;
enum VI_ATTR_ASRL_CONNECTED      = 0x3FFF01BBU;
enum VI_ATTR_ASRL_BREAK_STATE    = 0x3FFF01BCU;
enum VI_ATTR_ASRL_BREAK_LEN      = 0x3FFF01BDU;
enum VI_ATTR_ASRL_ALLOW_TRANSMIT = 0x3FFF01BEU;
enum VI_ATTR_ASRL_WIRE_MODE      = 0x3FFF01BFU;

enum VI_ASRL_WIRE_485_4          = 0;
enum VI_ASRL_WIRE_485_2_DTR_ECHO = 1;
enum VI_ASRL_WIRE_485_2_DTR_CTRL = 2;
enum VI_ASRL_WIRE_485_2_AUTO     = 3;
enum VI_ASRL_WIRE_232_DTE        = 128;
enum VI_ASRL_WIRE_232_DCE        = 129;
enum VI_ASRL_WIRE_232_AUTO       = 130;

enum VI_EVENT_ASRL_BREAK         = 0x3FFF2023U;
enum VI_EVENT_ASRL_CTS           = 0x3FFF2029U;
enum VI_EVENT_ASRL_DSR           = 0x3FFF202AU;
enum VI_EVENT_ASRL_DCD           = 0x3FFF202CU;
enum VI_EVENT_ASRL_RI            = 0x3FFF202EU;
enum VI_EVENT_ASRL_CHAR          = 0x3FFF2035U;
enum VI_EVENT_ASRL_TERMCHAR      = 0x3FFF2024U;

enum VI_ATTR_FIREWIRE_DEST_UPPER_OFFSET = 0x3FFF01F0U;
enum VI_ATTR_FIREWIRE_SRC_UPPER_OFFSET  = 0x3FFF01F1U;
enum VI_ATTR_FIREWIRE_WIN_UPPER_OFFSET  = 0x3FFF01F2U;
enum VI_ATTR_FIREWIRE_VENDOR_ID         = 0x3FFF01F3U;
enum VI_ATTR_FIREWIRE_LOWER_CHIP_ID     = 0x3FFF01F4U;
enum VI_ATTR_FIREWIRE_UPPER_CHIP_ID     = 0x3FFF01F5U;

enum VI_FIREWIRE_DFLT_SPACE           = 5;