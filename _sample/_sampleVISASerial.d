/**
 * diodeはdioをベースとしたライブラリです
 */

import diode.visa;
import dio.core;
import dio.port;

pragma(lib, "diode");
pragma(lib, "dio");
pragma(lib, "visa32");

void main(){
    Serial dev = Serial("ASRL5::INSTR");    //COM5
    
    with(dev)
    {
        breakLen = 50;  //50ms
        dataBits = 8;
        baud = 9600;
        stopBits = Stop.one;
        parity = Parity.none;
    }
    
    auto devRng = dev.buffered().ranged();
    auto devPort = dev.buffered().textPort();
    
    //これでSerial Portの設定は終わり。ここからプログラムを書いていく。
}