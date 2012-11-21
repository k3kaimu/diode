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
        timeout = 10;   //10ms
        dataBits = 8;
        baudRate = 9600;
        stopBits = Stop.one;
        parity = Parity.none;
    }
    
    auto devRng = dev.buffered().ranged();
    auto devPort = dev.buffered().textPort();
    Thread.sleep(dur!"msecs"(100));
    foreach(d; devRng)
        writeln(d);
}