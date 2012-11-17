/**
 * Windows APIを使ってIOを叩く。
 */
module diode.windows;

import std.conv                 : to;
import std.c.windows.windows;
import std.string               : toStringz;
import std.exception            : enforce;
//import std.c.windows.windows;
import win32.all : DCB, CreateFile, GetCommState, CBR_9600, NOPARITY, ONESTOPBIT, COMMTIMEOUTS, SetCommState, GetCommTimeouts, SetCommTimeouts;


@property comPortOpen(string name){
    
    static struct SerialPort
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
                DCBlength = typeof(*_dcb).sizeof;
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
                ReadTotalTimeoutMultiplier  = 0;
                ReadTotalTimeoutConstant    = 10;
                WriteTotalTimeoutMultiplier = 0;
                WriteTotalTimeoutConstant   = 0;
            }
            
            SetCommTimeouts(_handle, _cto);
        }
        
        
        ~this()
        {
            CloseHandle(_handle);
        }
        
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
        
        
        ///ボーレート
        @property uint baudRate()
        {
            GetCommState(_handle, _dcb);
            return _dcb.BaudRate;
        }
        
        
        ///ditto
        @property void baudRate(uint rate)
        {
            _dcb.BaudRate = rate;
            enforce(SetCommState(_handle, _dcb));
        }
        
    }
    
    import std.typecons;
    return RefCounted!SerialPort(name);
}