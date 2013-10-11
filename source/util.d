module util;

import vibe.d;

alias void function (Exception) Processor;

void defaultErrorProcessor(Exception ex)
{
	logError("[Error]%s\n%s", ex.msg, ex.info);
}


mixin template dateconv()
{
	static if (is(typeof(date): SysTime))
	{
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