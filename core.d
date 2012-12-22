module diode.core;

import dio.core;

version(unittest){
    pragma(lib, "dio");
    pragma(lib, "diode");
    void main(){}
}


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
ubyte[]をエンコードしてcharを出力。
*/
template Base64CoderImpl(char Map62th, char Map63th, char Padding = '=')
{
    import std.base64;
    alias Base64Impl!(Map62th, Map63th, Padding).encode encode;
    alias Base64Impl!(Map62th, Map63th, Padding).decode decode;

    size_t slice(ref inout(char)[] input){
        size_t idx;
        size_t ret;

        foreach(i, e; input){
            if(!isBase64Char(e))
                ++ret;
            else
                break;
        }

        foreach(e; input[ret .. $])
            if(isBase64Char(e))
                ++idx;
            else
                break;

        input = input[ret .. idx + ret];
        return ret;
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

unittest{
    static assert(isDecoder!(Base64Coder, char[]));
    static assert(isEncoder!Base64Coder);
}


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
            import std.stdio;
            typeof(dev.available) input;
            size_t n;
            bool b;
            
            do{
                input = dev.available;
                n = Coder.slice(input);
                dev.consume(n);
                
                if(input.length != 0)
                    goto NEXTSTAGE;
            }while(dev.available.length || dev.fetch());

            _empty = true;
            return;

        NEXTSTAGE:
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

      static if(is(typeof({Dev.init.flush();})))
      {
        bool flush(){
            return dev.flush();
        }
      }
    }

    return Coded(d);
}

unittest{
    import dio.file;
    import dio.core;
    import std.algorithm;
    import std.range;
    import std.stdio : writeln;

    struct LnReverser{
        static size_t slice(ref inout(ubyte)[] input){
            size_t idx;
            size_t ret;

            foreach(i, e; input){
                if(e == '\n' || e == '\r')
                    ++ret;
                else
                    break;
            }

            foreach(e; input[ret .. $])
                if(e != '\n' && e != '\r')
                    ++idx;
                else
                    break;

            input = input[ret .. idx + ret];
            return ret;
        }
        unittest{
            ubyte[] a = cast(ubyte[])"\n\r\n\rabcd\n".dup,
                    b = a.dup;
            auto sidx = slice(a);
            assert(sidx == 4);
            assert(a == b[4 .. $-1]);

            a = cast(ubyte[])"\n\n\n\n\n\n".dup,
            sidx = slice(a);
            assert(sidx == 6);
            assert(a == (ubyte[]).init);
        }

        static ubyte[] decode(inout(ubyte)[] input){return input.dup.reverse;}

        static ubyte[] encode(inout(ubyte)[] input){return input.dup.reverse;}
    }


    struct ArrayDeviced{
    private:
        ubyte[]* _src;
        ubyte[]* _sink;

    public:
        this(ubyte[]* src, ubyte[]* sink)
        {
            _src = src;
            _sink = sink;
        }


        bool pull(ref ubyte[] buf){
            size_t len = min(buf.length, (*_src).length);
            buf[0..len][] = (*_src)[0..len][];
            buf = buf[len .. $];
            (*_src) = (*_src)[len .. $];

            return len > 0;
        }

        bool push(ref const(ubyte)[] buf){
            size_t len = buf.length;
            (*_sink) ~= buf;
            buf = buf[0 .. 0];

            return len > 0;
        }

        auto handle(){return _src;}
    }


    {
        auto file = buffered(File(__FILE__));
        auto cd = file.coded!LnReverser;
        assert(equal(cast(char[])cd.front, "module diode.core;".dup.reverse));
    }

    {
        ubyte[] src = cast(ubyte[])"\nabc\ndef\nghi\njkl\nmno\npqr\nstu\n".dup;
        ubyte[] sink = cast(ubyte[])"".dup;

        auto dev = buffered(ArrayDeviced(&src, &sink));

        auto cd = dev.coded!LnReverser;
        auto check = map!"cast(ubyte[])(a.dup.reverse)"(["abc", "def", "ghi", "jkl", "mno", "pqr", "stu"]);
        assert(equal(cd, check));
    }

    {
        ubyte[] sink = cast(ubyte[])"".dup;

        auto dev = buffered(ArrayDeviced(&sink, &sink));

        auto cd = dev.coded!LnReverser;

        put(cd, cast(ubyte[])("abc".dup));
        put(cd, cast(ubyte[])("def".dup));
        put(cd, cast(ubyte[])("ghi".dup));
        cd.flush();

        assert(cast(string)sink == "cbafedihg");
    }

    {
        
    }
}