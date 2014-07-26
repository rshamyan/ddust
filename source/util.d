module util;

import vibe.d;
import std.digest.md;
import std.traits;

alias void function (Exception) Processor;

alias void delegate (Exception) Proc;

void defaultErrorProcessor(Exception ex)
{
	logError("[Error]%s\n%s", ex.msg, ex.info);
}

Proc defaultErrorProc;
static this()
{
	defaultErrorProc = delegate (Exception ex)
	{ 
		logError("[Error]%s\n%s", ex.msg, ex.info);
	};
}

mixin template dateconv()
{
	static if (is(typeof(date): SysTime))
	{
		string datestr(string format) @property
		{
			return date.toSimpleString();
		}
		
		string datestr() @property
		{
			return date.toSimpleString();
		}
	}
}

struct MSG
{
	bool error;
	
	string reason;
}

interface Immortal
{
	final protected static const char[] procCheck = 
		"static if ((!is(typeof(onError) : Processor))&&(!is(typeof(&onError): Processor)))
		{
			pragma(msg ,\"[Docs]Typeof onError must be \", Processor,\" not \", typeof(onError));
			static assert(false);
		}";
}

alias BsonObjectID BID;


string md5str(string str)
{
	ubyte[16] hash = md5Of(str);
	
	return toHexString(hash).idup;
}


