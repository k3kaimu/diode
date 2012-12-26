import core.thread : Thread, dur;

import std.algorithm    : startsWith, map;
import std.exception    : enforce;
import std.range        : put, popFrontN, isInputRange;

import dio.core;
import dio.port;

import diode.core;
import diode.visa;

import dranges.range;

pragma(lib, "dio");
pragma(lib, "diode");
pragma(lib, "visa32");
pragma(lib, "dranges");


template Codec_(){
    import std.ascii, std.json;

    size_t start(ref inout(ubyte)[] input){
        foreach(i; 0 .. input.length){
            if(input[i] == 0x02 && i != (input.length - 1)){
                input = input[i+1 .. $];
                return i+1;
            }
        }

        size_t ret = input.length;
        input = input[$ .. $];
        return ret;
    }


    void end(ref inout(ubyte)[] input){
        foreach(i; 0 .. input.length){
            if(input[i] == 0x03){
                if(i == 0){
                    input = input[$ .. $];
                    return;
                }

                input = input[0 .. i-1];
                return;
            }
        }

        input = input[$ .. $];
    }


    alias sliceWithStartEnd!(start, end) slice;

    JSONValue decode(inout(ubyte)[] input){
        return parseJSON(cast(inout(char)[])input);
    }

    ubyte[] encode(JSONValue json){
        return cast(ubyte[])toJSON(&json);
    }
}


alias Codec_!() Codec;


void main(){
    auto port = Serial("COM6");
    
    with(port) {
        timeout = dur!"msecs"(10);  //10ms
        dataBits = 8;               //8bit
        baudRate = 9600;            //9600
        stopBits = Stop.one;        //ストップビット1
        parity = Parity.none;       //パリティーなし
    }

    auto writer = port.sinked.buffered.coded!Codec;
    auto source = port.sourced.buffered.coded!Codec.toForwardRange;

    //この後にJSONValueを使ってやりとりする。
}