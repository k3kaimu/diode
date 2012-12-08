import diode.visa;

import dio.core;
import dio.port;

import core.thread : Thread, dur;

import std.algorithm    : startsWith;
import std.exception    : enforce;

import dranges.all      : interpret, popFrontWhile;

pragma(lib, "diode");
pragma(lib, "dio");
pragma(lib, "visa32");
pragma(lib, "dranges");


align(1): struct Data   //マイコンから受け取るデータ
{
    ulong time;         //マイコンの電源が入ってからの時間[μs]
    ubyte value;        //p22-p29のdigitalReadのデータ。p22がMSBでp29がLSB
}


void main(){
    auto dev = Serial("COM6");
    
    with(dev)
    {
        timeout = dur!"msecs"(10);       //10ms
        dataBits = 8;       //8bit
        baudRate = 9600;    //9600
        stopBits = Stop.one;
        parity = Parity.none;
    }
    
    
    auto devBuffered = dev.buffered();
    auto devRngUbyte = devBuffered.ranged();
    
    with(devRngUbyte){
        put([cast(ubyte)1]);
        flush();
        
        while(!empty)
        {
            devRngUbyte.popFrontWhile!"a != 0xFF"();
            popFront();
            enforce(!empty);
            if(front == 0xFF){
                popFront();
                break;
            }
        }
    }
    
    auto devRng = devRngUbyte.interpret!Data(); //マイコンからの情報をData型に変換
    
    ulong time_0;
    foreach(e; devRng)
    {
        writefln("%s[micro sec] : val = %s", e.time - time_0, e.value); //前回のとの時間差と値
        time_0 = e.time;
    }
}

/+ マイコンボードのコード。マイコンボードはGR-SAKURA, 搭載マイコンはRX63N
/*GR-SAKURA Sketch Template Version: V1.02*/
#include <rxduino.h>
#include <iodefine_gcc63n.h>

#define INTERVAL 512

typedef uint8_t ubyte;
typedef uint16_t ushort;
typedef uint32_t uint;
typedef uint64_t ulong_t;

ulong_t time;
ubyte data[INTERVAL];
ubyte head[2];

const uint IN0 = 22;

void setup()
{
    head[0] = 0xFF;
    head[1] = 0xFF;
    pinMode(PIN_LED0,OUTPUT);
    pinMode(PIN_LED1,OUTPUT);
    pinMode(PIN_LED2,OUTPUT);
    pinMode(PIN_LED3,OUTPUT);
    
    for(int i = 0; i < 8; ++i)
        pinMode(IN0 + i, OUTPUT);
    Serial.begin(9600);
    
    while(1){
        if(Serial.available() > 0){
            Serial.write(head, 2);
            data[0] = Serial.read();
            break;
        }
    }
}

void loop()
{
    if(Serial.available() > 0)
    {
        Serial.write(head, 2);
        data[0] = Serial.read();
    }
    
    time = micros();
    for(int i = 0; i < INTERVAL; ++i)
        for(int j = 0; j < 8; ++j){
            data[i] <<= 1;
            data[i] |= digitalRead(IN0 + j);
        }
    
    Serial.write((ubyte*)&time, 8);
    Serial.write(data, 1);
}
+/