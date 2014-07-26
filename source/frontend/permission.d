module frontend.permission;

import backend.iusers;

mixin template t_permission(Frontend)
{
	import std.traits;
	import std.string;
	import std.stdio;
	import std.functional;
	import std.regex;
	
	import vibe.d;
	
	import backend.iusers;
	import backend.idocs;

	import frontend.users;	
	
	private void setupModulesWithAccess()
	{
		foreach(mem; __traits(derivedMembers, Frontend))
		{
			static if (isSomeFunction!(__traits(getMember,Frontend,mem)) &&
				is(ParameterTypeTuple!(__traits(getMember,Frontend,mem)) == ParameterTypeTuple!HTTPServerRequestDelegate))
			{
				auto ga = getGA!(__traits(getMember,Frontend,mem));
				
				auto role = ga.role;
				
				alias curry!(requestHandler!(__traits(getMember,Frontend,mem)), role) curryDel;
				
				if (mem.indexOf("post") == 0 )
				{
					router.post(ga.resource, &curryDel);
				}
				else if (mem.indexOf("any") == 0 )
				{
					router.any(ga.resource, &curryDel);
				}
				else
				{
					router.get(ga.resource, &curryDel);
				}
			}
		}
	}
	
	void requestHandler(alias del)(USER_ROLE role, HTTPServerRequest req, HTTPServerResponse res)
	{
		mixin(t_session);
		
		string login;
		
		if (isOnline(login))
		{
			auto user = User.fromLogin(login,usersProvider);
			
			if (user.role >= role)
			{
				del(req,res);
				return;
			}
		}
		else if (role == USER_ROLE.GUEST)
		{
			del(req,res);
			return;
		}
		
		throw new AccessDenied("Access denied");
	}
		
}

class AccessDenied:Exception
{
	@safe pure nothrow this(string msg = "", string file = __FILE__, size_t line = __LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
}

struct GA 
{
	USER_ROLE role;
	
	string resource;

}

package GA getGA(alias func)()
{
	GA ret;
	
	foreach(attr; __traits(getAttributes, func))
	{
		if( is(typeof(attr) == GA))
		{
			ret = attr;
		}
	}
	
	return ret;
}


