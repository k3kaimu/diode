module diode.core;

import dio.core;


/**
Tmpがエンコーダかどうか調べます。
エンコーダとは以下のコードのコンパイルが通るものです。
---
alias Tmp.encode encode;
---
*/
template isEncoder(alias Tmp){
    enum isEncoder = is(typeof({
            alias Tmp.encode encode;
        }));
}
unittest{
    struct LnReverse{
        static char[] encode(inout(char)[] input){return input.dup.reverse;}
    }

    static assert(isEncoder!(LnReverse));
}


/**
Tmpがデコーダかどうか調べます
デコーダは以下のコンパイルが通ります
---
T input;
size_t unusedSize = Tmp.slice(input);

if(input.length)
    auto decoded = Tmp.decode(input);
---
*/
template isDecoder(alias Tmp, T){
    enum isDecoder = is(typeof({
            T input;
            size_t unusedSize = Tmp.slice(input);
            auto decoded =  Tmp.decode(input);
        }));
}
unittest{
    struct LnReverse{
        static size_t slice(ref inout(char)[] input){
            size_t idx;
            foreach(i, e; input)
                if(e == '\n'){
                    idx = i;
                    break;
                }

            input = input[0 .. idx];
            return 0;
        }

        static inout(char)[] decode(inout(char)[] input){return cast(typeof(return))input.dup.reverse;}
    }


    static assert(isDecoder!(LnReverse, char[]));
}


/**
単純なBase64のエンコーダとデコーダです。CRLF又はLFのみを区切りだと判断します。
*/
template Base64CoderImpl(char Map62th,char Map63th,char Padding = '=')
{
    import std.base64;
    alias Base64Impl!(Map62th, Map63th, Padding).encode encode;
    alias Base64Impl!(Map62th, Map63th, Padding).decode decode;

    size_t slice(ref inout(ubyte)[] input){
        size_t n;
        foreach(i, e; input){
            if(!isBase64Char(cast(char)e))
                ++n;
        }

        size_t idx;
        foreach(i, e; input[n .. $])
            if(e == '\n'){
                idx = i;
                break;
            }

        if(idx == 0)
            input = input[n .. n];
        else
            input = input[n .. n + idx - 1];
        return n;
    }

    bool isBase64Char(char c){
        if(('0' <= c && c <= '9')
        || ('a' <= c && c <= 'z')
        || ('A' <= c && c <= 'Z')
        || (c == Map62th) || (c == Map63th) || (c == Padding))
            return true;
        else
            return false;
    }
}

///ditto
alias Base64CoderImpl!('+', '/') Base64Coder;


/**
Buffered-Sourceからデコードしたものを一つ返します
*/
auto decodeOnce(alias Decoder, Src)(Src srcbuf)
if(isBufferedSource!Src && isDecoder!(Decoder, DeviceElementType!Src[]))
{
    typeof(srcbuf.available) input;
    size_t n;
    bool b;
    
    while(srcbuf.fetch()){
        input = srcbuf.available;
        n = Decoder.slice(input);

        if(input.length != 0)
            goto NEXTSTAGE;
    }
    
    import std.exception;
    enforce(b);

NEXTSTAGE:
    srcbuf.consume(n);
    auto decoded = Decoder.decode(input);
    srcbuf.consume(input.length);

    return decoded;
}


/**
bufferedなものを符号化、復号化します。
また、range化してしまいます。
*/
template Coded(alias Coder, Dev)
{
    alias typeof((Dev* d = null){ return (*d).coded!Coder; }()) Coded;
}


///ditto
@property
auto coded(alias Coder, Dev)(Dev d)
if((isBufferedSource!Dev && isDecoder!(Coder, DeviceElementType!Dev[]))
|| (isSink!Dev && isEncoder!(Coder)) )
{
    struct Coded{
    private:
        Dev dev;

      static if(isBufferedSource!Dev){
        alias DeviceElementType!Dev E;
        alias typeof(Coder.decode((E[]).init)) FrontType;
        FrontType _front;
        bool _empty;
      }


    public:
        this(Dev d)
        {
            dev = d;

            static if(isBufferedSource!Dev)
                popFront();
        }


      static if(isBufferedSource!Dev)
      {
        @property FrontType front(){
            return _front;
        }


        @property bool empty() const {
            return _empty;
        }


        void popFront(){
            typeof(dev.available) input;
            size_t n;
            bool b;
            
            while(dev.fetch()){
                input = dev.available;
                n = Coder.slice(input);

                if(input.length != 0)
                    goto NEXTSTAGE;
            }
            
            _empty = true;
            return;

        NEXTSTAGE:
            dev.consume(n);
            _front = Coder.decode(input);
            dev.consume(input.length);
        }
      }

      static if(isSink!Dev)
      {
        void put(U)(const(U)[] input){
            import std.range;
            alias ElementType!(typeof(Coder.encode(input))) EE;
            const(EE)[] encoded = Coder.encode(input);

            while(dev.push(encoded) && encoded.length){}
            if(encoded.length)
                throw new Exception("");
        }
      }
    }

    return Coded(d);
}

unittest{
    import dio.file;
    import dio.core;
    import std.algorithm : equal;

    struct LnReverseDecoder{
        static size_t slice(ref inout(ubyte)[] input){
            size_t idx;
            foreach(i, e; input)
                if(e == '\n'){
                    idx = i;
                    break;
                }

            import std.string;
            input = cast(inout(ubyte)[])chomp(cast(char[])input[0 .. idx+1]);
            return 0;
        }

        static auto decode(inout(ubyte)[] input){return input.dup.reverse;}
    }

    auto file = buffered(File(__FILE__));
    auto cd = file.coded!LnReverseDecoder;

    assert(equal(cast(char[])cd.front, "module diode.encode;".dup.reverse));
}

unittest{
    import std.algorithm;
    import std.range;
    import dio.core;

    struct ArraySink{
        ubyte[] array;

        bool push(ref const(ubyte)[] buf){array ~= buf; buf = buf[$ .. $]; return true;}

        @property auto handle(){return array;}
    }

    static assert(isSink!ArraySink);

    struct LnReverse{
        static ubyte[] encode(U:ubyte)(inout(U)[] input){return input.dup.reverse;}
        static ubyte[] encode(U)(inout(U)[] input){return encode(cast(inout(ubyte[]))input);}
    }

    auto cd = ArraySink.init.coded!LnReverse;

    cd.put(cast(ubyte[])[0x1, 0x2, 0x3]);
    assert(equal(cd.dev.array, cast(ubyte[])[0x3, 0x2, 0x1]));

    cd.put([0x1]);
    assert(equal(cd.dev.array, cast(ubyte[])[0x3, 0x2, 0x1, 0x0, 0x0, 0x0, 0x1]));
}

unittest{
    import dio.file;
    import dio.core;
    import std.algorithm;
    import std.stdio:writeln;

    struct LnReverseDecoder{
        static size_t slice(ref inout(ubyte)[] input){
            size_t idx;
            foreach(i, e; input)
                if(e == '\n'){
                    idx = i;
                    break;
                }

            import std.string;
            input = cast(inout(ubyte)[])chomp(cast(char[])input[0 .. idx+1]);
            return 0;
        }

        static auto decode(inout(ubyte)[] input){return cast(string)input;}
    }

    auto file = buffered(File(__FILE__));
    auto cd = file.coded!LnReverseDecoder;
    assert(equal(cd.front, "module diode.encode;"));
}