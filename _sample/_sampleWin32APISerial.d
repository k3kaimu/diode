/**
 * diodeはdioをベースとしたライブラリです
 */

import diode.windows;
import dio.core;
import dio.port;
import core.thread : Thread, dur;

pragma(lib, "diode");
pragma(lib, "dio");

import std.algorithm;

void main()
{
    auto dev = SerialPort("COM6");
    
    with(dev){
        dev.baudRate = 9600;
        dev.timeout = dur!"msecs"(10);
    }
    
    auto devBuffered = dev.buffered();
    
    auto devRngUbyte = devBuffered.ranged();
    {
        while(!devRngUbyte.startsWith([0xFF, 0xFF]))
            devRngUbyte.popFront();
    }
    
    uint i;
    foreach(d; devRngUbyte){
        writeln(i%10, " : ", d);
        ++i;
    }
}