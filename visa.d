/**
 * VISAのライブラリ。
 * VISAライブラリなので計測器などとの通信前提。
 * ただしSerial(COMPortとか)は、手持ちのマイコンでも動作確認済み。
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
import std.typecons : Tuple;
import std.typetuple: staticMap, TypeTuple, NoDuplicates;

import dio.core;

version(unittest){
    void main(){}
    pragma(lib, "dio");
    pragma(lib, "diode");
    pragma(lib, "visa32");
}


private{
    private template staticFilter(alias F, T...){
        static if(T.length){
            static if(F!(T[0]))
                alias TypeTuple!(T, staticFilter!(F, T[1..$])) staticFilter;
            else
                alias staticFilter!(F, T[1..$]) staticFilter;
        }else
            alias TypeTuple!() staticFilter;
    }


    private template isStatic(alias v){
        static if(is(typeof({enum value = v;})))
            enum isStatic = true;
        else
            enum isStatic = false;
    }
    unittest{
        struct S{
            enum a = 12;
        }
        
        static assert(staticFilter!(isStatic, staticMap!(getMember!(S), __traits(allMembers, S))).length == 1);
    }
    
    private template eval(alias f){
        alias f eval;
    }
    
    private template getMember(alias v){
        template getMember(string m){
            alias eval!(__traits(getMember, v, m)) getMember;
        }
    }

    
    template isEnum(T)
    {
        static if(is(typeof({enum e = __traits(getMember, T, __traits(allMembers, T)[0]);})))
            enum isEnum = NoDuplicates!(staticMap!(getTypeUserTypeMember!T, __traits(allMembers, T))).length == 1
                        && is(NoDuplicates!(staticMap!(getTypeUserTypeMember!T, __traits(allMembers, T)))[0] == T);
        else
            enum isEnum = false;
    }
    unittest
    {
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
  
    
  version(none){
    E to(E, N)(N value)
    if( isEnum!E && 
        is(typeof(__traits(getMember, E, __traits(allMembers, E)[0])) : N))
    {
        foreach(e;  __traits(allMembers, E))
        {
            if(__traits(getMember, E, e) == value)
                return __traits(getMember, E, e);
        }
        assert(0);
    }
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

///ViSessionを管理する構造体です。各デバイスはこのSessionを内部に持つことになります。参照カウンタ方式により管理しています。
struct Session{
private:
    ViSession _instr;
    size_t* _pRefCountor;

public:
    ///addressを指定してデバイスを開きます
    this(string address)
    {
        auto stat = viOpen(defaultRM, cast(char*)(address.toStringz), VI_NULL, VI_NULL, &_instr);
        assert(stat >= VI_SUCCESS, "couldn't open " ~ address);
        
        _pRefCountor = new size_t;
        *_pRefCountor = 1;
    }
    
    
    this(this)
    {
        ++(*_pRefCountor);
    }
    
    
    ~this()
    {
        if(_pRefCountor)
            if(--(*_pRefCountor) == 0)
                viClose(_instr);
    }
    
    
    void opAssign(typeof(this) rhs)
    {
        swap(this, rhs);
    }
    
    
    ///デバイスのINSTRを返します
    @property ViSession handle()
    {
        return _instr;
    }
}


///GPIBデバイスを操作するための構造体です
mixin template DeviceCommon(){
private:
    Session _session;
    
public:
    ///コンストラクタ
    this(string address){
        _session = Session(address);
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
    
    
    @property
    void attribute(AttrType)(AttrType val){
        auto stat = viSetAttribute(_session.handle,  val[0], val[1]);
        assert(stat >= VI_SUCCESS);
    }
    
    
    @property
    auto attribute(alias f)(){
        static if(is(f == struct)){
            enum v = staticFilter!(isStatic, staticMap!(getMember!(f), __traits(allMembers, f)))[0];
            alias typeof(v[1]) AttributeType;
            AttributeType t;
            auto stat = veGetAttribute(_session.handle, v[0], cast(void*)(&t));
            return t;
        }else{
            alias typeof(ReturnType!(f).init[1]) AttributeType;
            AttributeType t;
            auto stat = viGetAttribute(_session.handle, f(AttributeType.init)[0], cast(void*)(&t));
            assert(stat >= VI_SUCCESS);
            return t;
        }
    }
}


struct GPIBDevice{
    mixin DeviceCommon!();
}


struct Serial
{
    mixin DeviceCommon!();
    
    mixin(genAttrTF("allowTransmit", "VI_ATTR_ASRL_ALLOW_TRANSMIT"));
    mixin(genAttrReadOnly!uint("availNum", "VI_ATTR_ASRL_AVAIL_NUM"));
    mixin(genAttr!uint("baud", "VI_ATTR_ASRL_BAUD"));
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
}
unittest
{
    static assert(isDevice!Serial);
}


unittest{
    static assert(isDevice!GPIBDevice);
}


