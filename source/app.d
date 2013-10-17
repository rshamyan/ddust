import std.stdio;

import vibe.d;

import backend.mongo.docs;
import backend.mongo.users;
import backend.idocs;
import backend.iusers;
import frontend.frontend;

import std.stdio;

void main(string[] args)
{
	new FrontEnd();
	
	runEventLoop();
	
	lowerPrivileges();
}