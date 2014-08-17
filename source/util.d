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
			import std.string;
			return format("%d/%d/%d %d:%d",date.day,date.month,date.year,date.hour,date.minute);
				
		}
	}
}

struct MSG
{
	bool error;
	
	string reason;
}

alias BsonObjectID BID;

alias serializeToBson toBson;

alias deserializeBson fromBson;

string md5str(string str)
{
	ubyte[16] hash = md5Of(str);
	
	return toHexString(hash).idup;
}


