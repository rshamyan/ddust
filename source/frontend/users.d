module frontend.users;

import vibe.d;

package struct User
{	
	import users.iusers;
	import std.conv;
	import util;
	import vibe.d;
	
	string login;
	
	string username;
	
	string id;
	
	string email;
	
	string firstname;
	
	string lastname;
	
	static User fromID(string id, IUsersProvider usersProvider)
	{
		User ret;
		
		ret.id = id; // DEBUG ME
		
		Bson res = usersProvider.queryUserInfoFromID(BsonObjectID.fromString(id));
		
		foreach(string k, v; res)
		{
			if (k == "login") 
			{
				ret.login = v.get!string;
			}
			else if (k == "username")
			{
				ret.username = v.get!string;
			}
			else if (k == "email")
			{
				ret.username = v.get!string;
			}
			else if (k == "firstname")
			{
				ret.firstname = v.get!string;
			}
			else if (k == "lastname")
			{
				ret.lastname = v.get!string;
			}
		}
		
		return ret;
	}
	
	string name() @property
	{
		if ( username is null)
		{
			return login;
		}
		else
		{
			return username;
		}
	}
}