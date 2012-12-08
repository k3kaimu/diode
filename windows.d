/**
 * Windows APIを使ってIOを叩く。
 */
module diode.windows;

version(Windows)
{

import std.algorithm            : swap;
import std.conv                 : to;
import std.c.windows.windows;
import std.exception            : enforce;
import std.string               : toStringz, toUpperInPlace;
import std.typecons             : RefCounted;

public import core.time;
import std.c.windows.windows;

import dio.core                 : isDevice;
//["Serial", "COM"] //UDA

///ditto
RefCounted!SerialPort serialPortOpen(string name)
{
    return RefCounted!SerialPort(name);
}


///ditto
struct SerialPort
{
private:
    HANDLE  _handle;
    DCB*     _dcb;
    COMMTIMEOUTS* _cto;

public:
    this(string name)
    {
        _dcb = new DCB;
        _handle = CreateFile(   name.toStringz(),
                                GENERIC_READ | GENERIC_WRITE,
                                0,
                                null,
                                OPEN_EXISTING,
                                FILE_ATTRIBUTE_NORMAL,
                                null);
        assert(_handle != INVALID_HANDLE_VALUE, name ~ ", could not open.");
        
        GetCommState(_handle, _dcb);
        
        with(*_dcb){
            BaudRate = 9600;
            fBinary = true;
            fParity = false;
            ByteSize = 8;
            Parity = NOPARITY;
            StopBits = ONESTOPBIT;/*
            dcb.fOutxCtsFlow = 0;
            dcb.fOutxDsrFlow = 0;
            dcb.fDtrControl = DTR_CONTROL_DISABLE;
            */
        }
        
        enforce(SetCommState(_handle, _dcb));
        
        _cto = new COMMTIMEOUTS;
        GetCommTimeouts(_handle, _cto);
        
        with(*_cto)
        {
            ReadIntervalTimeout         = 10;		// タイムアウト：0.01秒	　
            ReadTotalTimeoutMultiplier  = 2;
            ReadTotalTimeoutConstant    = 10;
            WriteTotalTimeoutMultiplier = 2;
            WriteTotalTimeoutConstant   = 10;
        }
        
        SetCommTimeouts(_handle, _cto);
    }
    
    
    ///
    @property
    HANDLE handle()
    {
        return _handle;
    }
        
    ///Sourceのpullの実装
    bool pull(ref ubyte[] buf){
        DWORD cnt = void;
        
        enforce(ReadFile(_handle, cast(ubyte*)(buf.ptr), buf.length, &cnt, null));
        
        buf = buf[cnt .. $];
        return cnt > 0;
    }
    
    
    ///Sinkのpushの実装
    bool push(ref const(ubyte)[] buf){
        DWORD cnt = void;
        
        enforce(WriteFile(_handle, cast(ubyte*)(buf.ptr), buf.length, &cnt, null));
        
        buf = buf[cnt .. $];
        return cnt > 0;
    }
    
    
    ///プロパティ：ボーレート
    @property
    uint baudRate()
    {
        return _dcb.BaudRate;
    }
    
    
    ///ditto
    @property
    void baudRate(uint rate)
    {
        _dcb.BaudRate = rate;
        enforce(SetCommState(_handle, _dcb));
    }
    
    
    ///ビット数の設定
    @property
    void dataBits(size_t value)
    {
        _dcb.ByteSize = cast(ubyte)value;
        enforce(SetCommState(_handle, _dcb));
    }
    
    
    ///ditto
    @property
    ushort dataBits()
    {
        GetCommState(_handle, _dcb);
        return _dcb.ByteSize;
    }
    
    
    ///タイムアウトの設定
    template _Timeout()
    {
        enum Read : ubyte
        {
            interval    = 0x1,
            multiplier  = 0x2,
            constant    = 0x4,
            all         = 0x7,
        }
        
        enum Write : ubyte
        {
            multiplier  = 0x8,
            constant    = 0x10,
            all         = 0x18,
        }
        
        enum ubyte all      = 0x1F;
    }
    
    
    ///ditto
    alias _Timeout!() Timeout;
    
    
    ///プロパティ：タイムアウト
    @property
    void timeout(ubyte spec = Timeout.Read.interval | Timeout.Read.constant | Timeout.Write.constant)
    (Duration value)
    {
        string genCode()
        {
            string dst;
            foreach(e; __traits(allMembers, Timeout.Read))
                if(spec & __traits(getMember, Timeout.Read, e)){
                    if(e == "all")
                        continue;
                    
                    char[] t = e.dup;
                    
                    t[0..1].toUpperInPlace();
                    dst ~= "_cto.Read" ~ ((__traits(getMember, Timeout.Read, e) == Timeout.Read.interval) ? "" : "TotalTimeout") 
                             ~ t.idup 
                             ~ ((__traits(getMember, Timeout.Read, e) == Timeout.Read.interval) ? "Timeout" : "") ~ ` = cast(uint)value.total!"msecs"();
                             `;
                }
            
            foreach(e; __traits(allMembers, Timeout.Write))
                if(spec & __traits(getMember, Timeout.Write, e)){
                    if(e == "all")
                        continue;
               
                    char[] t = e.dup;
                    
                    t[0..1].toUpperInPlace();
                    dst ~= "_cto.WriteTotalTimeout"
                             ~ t.idup 
                             ~ ` = cast(uint)value.total!"msecs"();
                                `;
                }
            
            return dst;
        }
        
        
        GetCommTimeouts(_handle, _cto);
        
        mixin(genCode());
        
        SetCommTimeouts(_handle, _cto);
    }
    
    
    ///ditto
    @property
    Duration timeout(ubyte spec = Timeout.Read.constant)()
    {
        GetCommTimeouts(_handle, _cto);
        
        final switch(spec)
        {
            case Timeout.Read.interval:
                return dur!"msecs"(_cto.ReadIntervalTimeout);
                break;
            
            case Timeout.Read.multiplier:
                return dur!"msecs"(_cto.ReadTotalTimeoutMultiplier);
                break;
            
            case Timeout.Read.constant:
                return dur!"msecs"(_cto.ReadTotalTimeoutConstant);
                break;
            
            case Timeout.Write.multiplier:
                return dur!"msecs"(_cto.WriteTotalTimeoutMultiplier);
                break;
            
            case Timeout.Write.constant:
                return dur!"msecs"(_cto.WriteTotalTimeoutConstant);
                break;
        }
        
        assert(0, "Failed get timeout");
    }
}

unittest{
    static assert(isDevice!SerialPort);
    static assert(isDevice!(typeof(serialPortOpen("COM1"))));
}


private{
    extern(Windows):
    //Win32API
    HANDLE CreateFileA(LPCSTR, DWORD, DWORD, LPSECURITY_ATTRIBUTES, DWORD, DWORD, HANDLE);
    alias CreateFileA CreateFile;
    BOOL GetCommState(HANDLE, LPDCB);
    BOOL SetCommState(HANDLE, LPDCB);
    BOOL GetCommTimeouts(HANDLE, LPCOMMTIMEOUTS);
    BOOL SetCommTimeouts(HANDLE, LPCOMMTIMEOUTS);

    struct DCB {
        DWORD DCBlength = DCB.sizeof;
        DWORD BaudRate;

        import std.bitmanip;

        mixin(bitfields!(
            uint, "fBinary", 1,
            uint, "fParity", 1,
            uint, "fOutxCtsFlow", 1,
            uint, "fOutxDsrFlow", 1,
            uint, "fDtrControl", 2,
            uint, "fDsrSensitivity", 1,
            uint, "fTXContinueOnXoff", 1,
            uint, "fOutX", 1,
            uint, "fInX", 1,
            uint, "fErrorChar", 1,
            uint, "fNull", 1,
            uint, "fRtsControl", 2,
            uint, "fAbortOnError", 1,
            uint, "dDummy2", 17
        ));

        WORD wReserved;
        WORD XonLim;
        WORD XoffLim;
        BYTE ByteSize;
        BYTE Parity;
        BYTE StopBits;
        char XonChar;
        char XoffChar;
        char ErrorChar;
        char EofChar;
        char EvtChar;
        WORD wReserved1;
    }

    alias DCB* LPDCB;

    enum : BYTE {
        NOPARITY = 0,
        ODDPARITY,
        EVENPARITY,
        MARKPARITY,
        SPACEPARITY
    }

    // DCB
    enum : BYTE {
        ONESTOPBIT = 0,
        ONE5STOPBITS,
        TWOSTOPBITS
    }

    struct COMMTIMEOUTS {
        DWORD ReadIntervalTimeout;
        DWORD ReadTotalTimeoutMultiplier;
        DWORD ReadTotalTimeoutConstant;
        DWORD WriteTotalTimeoutMultiplier;
        DWORD WriteTotalTimeoutConstant;
    }

    alias COMMTIMEOUTS* LPCOMMTIMEOUTS;

    struct SECURITY_ATTRIBUTES {
        DWORD  nLength;
        LPVOID lpSecurityDescriptor;
        BOOL   bInheritHandle;
    }

    alias SECURITY_ATTRIBUTES* LPSECURITY_ATTRIBUTES;
}


}