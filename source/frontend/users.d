module frontend.users;

import vibe.d;
import backend.iusers;
import std.conv;
import util;

package struct User
{			
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

package mixin template usersPages()
{
	import util;
	import backend.iusers;
	
	enum LOGIN_STATUS:string
	{
		OK = "Authorization was successful",
		INVALID = "Login or password has incorrect format"
	}
	
	struct LoginData
	{
		string login;
		
		string password;
		
		mixin usersValidator;
		
		LOGIN_STATUS status() @property
		{
			if ((!isValidLogin(login))||(!isValidPassword(login))) return LOGIN_STATUS.INVALID;
			return LOGIN_STATUS.OK;
		}
	}
	
	void login(HTTPServerRequest req, HTTPServerResponse res)
	{
		res.renderCompat!("ddust.login.dt", HTTPServerRequest,"req", MSG, "message")(req, MSG(false,""));
	}
	
	void postLogin(HTTPServerRequest req, HTTPServerResponse res)
	{
		LoginData loginData;
		
		loadFormData(req, loginData, "auth");
		
		if (loginData.status == LOGIN_STATUS.OK)
		{
			auto msg = usersProvider.queryAuthorization(loginData.login, loginData.password);			
			
			if (msg)
			{
				if (req.session !is null)
				{
					res.terminateSession();
				}
				auto session = res.startSession();
				session["login"] = loginData.login;
				session["logon_time"] = Clock.currTime().toISOExtString();
				session["ip"]= req.host();
				res.redirect("/");

			} 
			else
			{
				res.renderCompat!("ddust.login.dt", HTTPServerRequest, "req", MSG, "message")(req,
					MSG(true,"Authorization failed"));
			}
		}
		else 
		{
			res.renderCompat!("ddust.login.dt", HTTPServerRequest, "req", MSG, "message")(req, 
				MSG(true, loginData.status));
		}
	}
	
	void setupUsersPages()
	{
		router.get("/login", &login);
		router.post("/login", &postLogin);
	}
}