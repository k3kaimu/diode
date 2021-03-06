﻿/**
VISAのライブラリ。
VISAライブラリなので計測器などとの通信前提。
ただしSerial(COMPortとか)は、手持ちのマイコンでも動作確認済み。
 */
module diode.visa;

import diode.c.visa.visatype;
import diode.c.visa.visa;

import std.format   : format;
import std.string   : toStringz;
import std.variant  : Variant;
import std.array    : strip, split;
import std.conv     : to;
import std.algorithm: swap;
import std.typecons : Tuple, RefCounted;
import std.typetuple: staticMap, TypeTuple, NoDuplicates;

public import core.time;

import dio.core;

version(unittest){
    void main(){}
    pragma(lib, "dio");
    pragma(lib, "diode");
    pragma(lib, "visa32");
}


private{
    template isEnum(T) {
        static if(is(typeof({enum e = __traits(getMember, T, __traits(allMembers, T)[0]);})))
            enum isEnum = NoDuplicates!(staticMap!(getTypeUserTypeMember!T, __traits(allMembers, T))).length == 1
                        && is(NoDuplicates!(staticMap!(getTypeUserTypeMember!T, __traits(allMembers, T)))[0] == T);
        else
            enum isEnum = false;
    }
    unittest {
        enum A
        {
            a,
        }
        static assert(isEnum!A);
        
        enum B
        {
            a, b, c,
        }
        
        static assert(isEnum!B);
        
        struct S
        {
            int a;
        }
        static assert(!isEnum!S);
    }

    
    string genAttrReadOnly(T)(string name, string val, string unitTest = ""){
        return 
        `
        @property ` ~ T.stringof ~ ` ` ~ name ~ `()
        in{}
        out(value)
        {
        ` ~ unitTest ~ (isEnum!T ? q{assert(value.to!string[0..5] != "cast("[0..5]);} : "") ~ `
        }
        body
        {
            ` ~ T.stringof ~ ` attr = void;
            auto stat = viGetAttribute(_session.handle, ` ~ val ~ `, cast(void*)(&attr));
            assert(stat >= VI_SUCCESS);
            return attr;
        }
        
        unittest
        {
            static assert(is(typeof({
                Serial dev;
                ` ~ T.stringof ~ ` val = dev.` ~ name ~ `;
            })));
        }
        `;
    }
    
    
    string genAttrWriteOnly(T)(string name, string val, string unitTest = ""){
        return 
        `
        @property void ` ~ name ~ `(` ~ T.stringof ~ ` value)
        in{
        ` ~ unitTest ~ `
        }
        body{
            auto stat = viSetAttribute(_session.handle, ` ~ val ~ `, value);
            assert(stat >= VI_SUCCESS, "Error : couldn't set` ~ name ~` to " ~ to!string(value));
        }
        
        unittest
        {
            static assert(is(typeof({
                Serial dev;
                ` ~ T.stringof ~ ` val;
                dev.` ~ name ~ ` = val;
            })));
        }
        `;
    }
    
    
    string genAttr(T)(string name, string val, string unitTestRead = "", string unitTestWrite = ""){
        if(unitTestWrite == "")
            unitTestWrite = unitTestRead;
        return genAttrReadOnly!T(name, val, unitTestRead)
                ~ genAttrWriteOnly!T(name, val, unitTestWrite);
    }
    
    
    string genAttrTFReadOnly(string name, string val){
        return 
        `
        @property bool ` ~ name ~ `()
        {
            ViBoolean attr = void;
            auto stat = viGetAttribute(_session.handle, ` ~ val ~ `, cast(void*)(&attr));
            assert(stat >= VI_SUCCESS);
            return attr.flag;
        }
        
        unittest
        {
            static assert(is(typeof({
                Serial dev;
                bool b = dev.` ~ name ~ `;
            })));
        }
        `;
    }
    
    
    string genAttrTFWriteOnly(string name, string val){
        return 
        `
        @property void ` ~ name ~ `(bool value){
            ViBoolean vb;
            vb.flag = value;
            auto stat = viSetAttribute(_session.handle, ` ~ val ~ `, vb);
            assert(stat >= VI_SUCCESS, "Error : couldn't set` ~ name ~` to " ~ to!string(value));
        }
        
        unittest
        {
            static assert(is(typeof({
                Serial dev;
                dev.` ~ name ~ ` = true;
            })));
        }
        `;
    }
    
    
    string genAttrTF(string name, string val){
        return genAttrTFReadOnly(name, val) 
                ~ genAttrTFWriteOnly(name, val);
    }
    
    
    template getTypeUserTypeMember(T)
    {
        template getTypeUserTypeMember(string name)
        {
            alias typeof(__traits(getMember, T, name)) getTypeUserTypeMember;
        }
    }
}

///デフォルトのリソースマネージャです。実行時に最初に初期化されます。
ViSession defaultRM;

static this(){
    auto stat = viOpenDefaultRM(&defaultRM);
    assert(stat >= VI_SUCCESS, "couldn't open the VISA default resource manager");
}
static ~this(){
    viClose(defaultRM);
}

enum State : short
{
    asserted    = VI_STATE_ASSERTED,
    unasserted  = VI_STATE_UNASSERTED,
    unknown = VI_STATE_UNKNOWN,
}


enum Flush : ushort
{
    onAccess = VI_FLUSH_ON_ACCESS,
    disable = VI_FLUSH_DISABLE,
}


enum Lock : ViAccessMode
{
    noLock  = VI_NO_LOCK,
    exclusiveLock = VI_EXCLUSIVE_LOCK,
    sharedLock = VI_SHARED_LOCK,
}


enum RsrcClass
{
    SerialInstr,
    GpibInstr,
}


///ViSessionを管理する構造体です。各デバイスはこのSessionを内部に持つことになります。参照カウンタ方式により管理しています。
RefCounted!Session openSession(string address)
{
    return RefCounted!Session(address);
}

///ditto
struct Session{
private:
    ViSession _instr;

public:
    ///addressを指定してデバイスを開きます
    this(string address)
    {
        auto stat = viOpen(defaultRM, cast(char*)(address.toStringz), VI_NULL, VI_NULL, &_instr);
        assert(stat >= VI_SUCCESS, "couldn't open " ~ address);
    }
    
    
    ~this()
    {
        viClose(_instr);
    }
    
    
    ///デバイスのINSTRを返します
    @property ViSession handle()
    {
        return _instr;
    }
}


///デバイスを操作するための構造体を定義する際に便利なテンプレートです
mixin template DeviceCommon(RsrcClass rsrcClass){
private:
    RefCounted!Session _session;
    
public:
    ///コンストラクタ
    this(string address){
        _session = openSession(address);
    }
    
    
    ///instrを返す
    @property ViSession handle(){
        return _session.handle;
    }
    
    
    ///Sourceのpullの実装
    bool pull(ref ubyte[] buf){
        ViUInt32 cnt = void;
        
        auto stat = viRead(_session.handle, cast(ubyte*)(buf.ptr), buf.length, &cnt);
        assert(stat >= VI_SUCCESS);
        
        buf = buf[cnt .. $];
        return (cnt > 0);
    }
    
    
    ///Sinkのpushの実装
    bool push(ref const(ubyte)[] buf){
        uint cnt = void;
        
        auto stat = viWrite(_session.handle, cast(ubyte*)(buf.ptr), buf.length, &cnt);
        
        buf = buf[cnt .. $];
        assert(stat >= VI_SUCCESS);
        return cnt > 0;
    }
}


/**
VISAライブラリのSerial INSTRを使ってシリアルポートを制御します。
*/
//["Serial", "COM"] //UDA
struct Serial
{
    mixin DeviceCommon!(RsrcClass.SerialInstr);
    
    mixin(genAttrTF("allowTransmit", "VI_ATTR_ASRL_ALLOW_TRANSMIT"));
    mixin(genAttrReadOnly!uint("availNum", "VI_ATTR_ASRL_AVAIL_NUM"));
    mixin(genAttr!uint("baudRate", "VI_ATTR_ASRL_BAUD"));
    mixin(genAttr!short("breakLen", "VI_ATTR_ASRL_BREAK_LEN", q{assert(1 <= value && value <= 500);}));
    mixin(genAttr!State("breakState", "VI_ATTR_ASRL_BREAK_STATE"));
    mixin(genAttrReadOnly!State("ctsState", "VI_ATTR_ASRL_CTS_STATE"));
    mixin(genAttr!ushort("dataBits", "VI_ATTR_ASRL_DATA_BITS", q{assert(5 <= value && value <= 8);}));
    mixin(genAttrReadOnly!State("dcdState", "VI_ATTR_ASRL_DCD_STATE"));
    mixin(genAttrTF("discardNull", "VI_ATTR_ASRL_DISCARD_NULL"));
    mixin(genAttrReadOnly!State("dsrState", "VI_ATTR_ASRL_DSR_STATE"));
    mixin(genAttrReadOnly!State("dtrState", "VI_ATTR_ASRL_DTR_STATE"));
    
    enum End : ushort
    {
        none        = VI_ASRL_END_NONE,
        lastBit     = VI_ASRL_END_LAST_BIT,
        termChar    = VI_ASRL_END_TERMCHAR,
        break_      = VI_ASRL_END_BREAK,
    }
    
    mixin(genAttr!(Serial.End)("endIn", "VI_ATTR_ASRL_END_IN"));
    mixin(genAttr!(Serial.End)("endOut", "VI_ATTR_ASRL_END_OUT"));
    
    enum Flow : ushort
    {
        none    = VI_ASRL_FLOW_NONE,
        xOnXOff = VI_ASRL_FLOW_XON_XOFF,
        rtsCts  = VI_ASRL_FLOW_RTS_CTS,
        dtrDsr  = VI_ASRL_FLOW_DTR_DSR,
    }
    
    mixin(genAttr!(Serial.Flow)("flowCntrl", "VI_ATTR_ASRL_FLOW_CNTRL"));
    
    enum Parity : ushort
    {
        none    = VI_ASRL_PAR_NONE,
        odd     = VI_ASRL_PAR_ODD,
        even    = VI_ASRL_PAR_EVEN,
        mark    = VI_ASRL_PAR_MARK,
        space   = VI_ASRL_PAR_SPACE,
    }
    
    mixin(genAttr!(Serial.Parity)("parity", "VI_ATTR_ASRL_PARITY"));
    mixin(genAttr!char("replaceChar", "VI_ATTR_ASRL_REPLACE_CHAR"));
    mixin(genAttrReadOnly!State("riState", "VI_ATTR_ASRL_RI_STATE"));
    mixin(genAttr!State("rtsState", "VI_ATTR_ASRL_RTS_STATE"));
    
    enum Stop : ushort
    {
        one     = VI_ASRL_STOP_ONE,
        one5    = VI_ASRL_STOP_ONE5,
        two     = VI_ASRL_STOP_TWO,
    }
    
    mixin(genAttr!(Serial.Stop)("stopBits", "VI_ATTR_ASRL_STOP_BITS"));
    
    enum Wire : short
    {
        _485_4          = VI_ASRL_WIRE_485_4,
        _485_2_DtrEcho  = VI_ASRL_WIRE_485_2_DTR_ECHO,
        _485_2_DtrCtrl  = VI_ASRL_WIRE_485_2_DTR_CTRL,
        _485_2_Auto     = VI_ASRL_WIRE_485_2_AUTO,
        _232_Dte        = VI_ASRL_WIRE_232_DTE,
        _232_Dce        = VI_ASRL_WIRE_232_DCE,
        _232_Auto       = VI_ASRL_WIRE_232_AUTO,
        unknown         = VI_STATE_UNKNOWN,
    }
    
    mixin(genAttr!(Serial.Wire)("wireMode", "VI_ATTR_ASRL_WIRE_MODE"));
    mixin(genAttr!char("xoffChar", "VI_ATTR_ASRL_XOFF_CHAR"));
    mixin(genAttr!char("xonChar", "VI_ATTR_ASRL_XON_CHAR"));
    
    mixin(genAttrTF("dmaAllowEn", "VI_ATTR_DMA_ALLOW_EN"));
    mixin(genAttrReadOnly!ViEventType("eventType", "VI_ATTR_EVENT_TYPE"));
    mixin(genAttrTF("fileAppendEn", "VI_ATTR_FILE_APPEND_EN"));
    mixin(genAttrReadOnly!ViString("intfName", "VI_ATTR_INTF_INST_NAME"));
    mixin(genAttrReadOnly!ushort("intfNum", "VI_ATTR_INTF_NUM"));
    mixin(genAttrReadOnly!ushort("intfType", "VI_ATTR_DMA_ALLOW_EN"));
    
    enum Protocol : ushort
    {
        normal = VI_PROT_NORMAL,
        usbTmcVendor = VI_PROT_USBTMC_VENDOR,
    }
    
    mixin(genAttr!Protocol("protocol", "VI_ATTR_IO_PROT"));
    mixin(genAttr!uint("maxQueueLength", "VI_ATTR_MAX_QUEUE_LENGTH", q{assert(value > 0);}));
    mixin(genAttr!Flush("rdBufOpMode", "VI_ATTR_RD_BUF_OPER_MODE"));
    mixin(genAttrReadOnly!uint("rdBufSize", "VI_ATTR_RD_BUF_SIZE"));
    mixin(genAttrReadOnly!ViSession("rmSession", "VI_ATTR_RM_SESSION"));
    mixin(genAttrReadOnly!ViString("rClass", "VI_ATTR_RSRC_CLASS"));
    mixin(genAttrReadOnly!ViVersion("rVersion", "VI_ATTR_RSRC_IMPL_VERSION"));
    mixin(genAttrReadOnly!Lock("rLockState", "VI_ATTR_RSRC_LOCK_STATE"));
    mixin(genAttrReadOnly!ushort("rManufacturerID", "VI_ATTR_RSRC_MANF_ID", q{assert(value <= 0x3FFF);}));
    mixin(genAttrReadOnly!ViString("rManufacturerName", "VI_ATTR_RSRC_MANF_NAME"));
    mixin(genAttrReadOnly!ViString("rName", "VI_ATTR_RSRC_NAME"));
    mixin(genAttrReadOnly!ViVersion("rSpecVersion", "VI_ATTR_RSRC_SPEC_VERSION"));
    mixin(genAttrTF("sendEndEn", "VI_ATTR_SEND_END_EN"));
    mixin(genAttrTF("suppressEndEn", "VI_ATTR_SUPPRESS_END_EN"));
    mixin(genAttr!char("termChar", "VI_ATTR_TERMCHAR"));
    mixin(genAttrTF("termCharEn", "VI_ATTR_TERMCHAR_EN"));
    mixin("private " ~ genAttr!uint("_timeout", "VI_ATTR_TMO_VALUE"));    //0xFFFFFFFFでinfinite

    @property
    void timeout(Duration time)
    {
        _timeout = cast(uint)time.total!"msecs"();
    }


    @property
    Duration timeout()
    {
        return dur!"msecs"(_timeout);
    }
    
    //mixin(genAttr!ViAddr("userData", "VI_ATTR_USER_DATA"));
    mixin(genAttr!ushort("wrBufOpMode", "VI_ATTR_WR_BUF_OPER_MODE"));
    mixin(genAttrReadOnly!uint("wrBufSize", "VI_ATTR_WR_BUF_SIZE"));
}
unittest
{
    static assert(isDevice!Serial);
}


/**
VISAライブラリのGPIB INSTRを使ってシリアルポートを制御します。
*/
struct Gpib
{
    mixin DeviceCommon!(RsrcClass.GpibInstr);
}