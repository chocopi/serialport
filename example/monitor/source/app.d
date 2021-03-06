import std.stdio;
import std.string;
import std.range;
import core.thread;

import serialport;

int main(string[] args)
{
    string port;
    size_t step = 8;

    void[1024*4] data = void;

    if (args.length < 2)
    {
        stderr.writeln("use: monitor /dev/<PORTNAME>");
        return 1;
    }

    auto msg = "listen " ~ args[1];

    size_t pcount=0;

    void dots(bool reset=false)
    {
        if (reset)
        {
            auto w = " ".repeat(msg.length+pcount+40).join;
            stdout.write("\r", w, "\r");
            stdout.write(msg);
            pcount = 0;
        }
        else
        {
            pcount++;
            stdout.write(".");
        }
        stdout.flush();
    }

    auto com = new SerialPort(args[1], SerialPort.Config(9600));

    stdout.writeln("port config: ", com.config);

    dots(true);
    stdout.flush();

    while (true)
    {
        if (pcount>5) dots(true);
        void[] tmp;
        try tmp = com.read(data, 500.dur!"msecs");
        catch (TimeoutException e)
        {
            dots();
            continue;
        }
        catch (SerialPortException e)
        {
            dots(true); writeln();
            stderr.writeln("error: ", e.msg);
            continue;
        }

        writeln();

        size_t i;
        foreach (c; (cast(ubyte[])tmp).chunks(step))
        {
            auto hex = format("%(0x%02X %)", c);
            auto dec = format("%(% 4d%)", c);
            writefln("%05d..%05d > %s  | %s", i*step, i*step + c.length,
                    hex ~ " ".repeat(max(0,40-hex.length-1)).join, dec);
            i++;
        }
        writefln("receive %d bytes", tmp.length);

        dots(true);
    }
}
