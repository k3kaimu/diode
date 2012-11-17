/**
 * Windows APIを使ってIOを叩く。
 */
module diode.windows;

import std.conv                 : to;
import std.c.windows.windows;
import std.string               : toStringz;
//import std.c.windows.windows;
import win32.all : DCB, CreateFile, GetCommState, CBR_9600, NOPARITY, ONESTOPBIT;

@property serialPortOpen(string name){
    static struct SerialPort
    {
    private:
        HANDLE  _handle;
        DCB*     _dcb;
    
    public:
        this(string name)
        {
            _dcb = new DCB;
            _handle = CreateFile(   name.toStringz(),
                                    GENERIC_READ | GENERIC_WRITE,
                                    0,
                                    null,
                                    OPEN_EXISTING,
                                    FILE_FLAG_OVERLAPPED,
                                    null);
            assert(_handle != INVALID_HANDLE_VALUE, name ~ ", could not open.");
            
            GetCommState(_handle, _dcb);
            
            with(*_dcb){
                DCBlength = typeof(*_dcb).sizeof;
                BaudRate = CBR_9600;
                fBinary = true;
                fParity = false;
                ByteSize = 8;
                Parity = NOPARITY;
                StopBits = ONESTOPBIT;
            }
        }
        
        
        ~this()
        {
            CloseHandle(_handle);
        }
        
        
        
    }
    
    import std.typecons;
    return RefCounted!SerialPort(name);
}