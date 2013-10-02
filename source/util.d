module util;

import vibe.d;

alias void function (Exception) Processor;

void defaultErrorProcessor(Exception ex)
{
	logError("[Error]%s\n%s", ex.msg, ex.info);
}