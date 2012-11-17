/**
 * diodeはdioをベースとしたライブラリです
 */

import diode.windows;
import dio.core;
import dio.port;
import core.thread : Thread, dur;

pragma(lib, "diode");
pragma(lib, "dio");
pragma(lib, "win32");

void main(){
    auto dev = comPortOpen("COM6");
    
    auto devRng = dev.buffered().ranged();
    auto devPort = dev.buffered().textPort();
    
    foreach(d; devRng)
        writeln(d);
}