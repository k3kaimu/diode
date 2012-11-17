import diode.visa;
import dio.core;
import dio.port;
import core.thread : Thread, dur;
import std.exception;

pragma(lib, "diode");
pragma(lib, "dio");
pragma(lib, "visa32");

void main(){
    auto dev = Serial("COM6");
    
    with(dev)
    {
        timeOut = 10;   //10ms
        dataBits = 8;
        baud = 9600;
        stopBits = Stop.one;
        parity = Parity.none;
        flowCntrl = Flow.none;
    }
    
    auto devRng = dev.buffered().ranged();
    auto devPort = dev.buffered().textPort();
    
    foreach(d; devRng)
        writeln(d);
}