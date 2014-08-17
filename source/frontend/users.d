module frontend.users;

import vibe.d;
import backend.iusers;
import std.conv;
import util;

package struct User
{				
	string login;
	
	BID _id;
	
	USER_ROLE role;
	
	@optional()
	string username;
	
	@optional()
	string email;
	
	@optional()
	string firstname;
	
	@optional()
	string lastname;
	
	@optional()
	BsonDate regdate;
	
	@ignore()
	string id() @property
	{
		return _id.toString();
	}
	
	@ignore()
	void id(string str) @property
	{
		_id = BID.fromString(str);
	}
	
	static User fromID(string id, IUsersProvider usersProvider)
	{
		Bson res = usersProvider.queryUserInfoFromID(BsonObjectID.fromString(id));

		return fromBson!User(res);
	}

	static User fromID(BID id, IUsersProvider usersProvider)
	{
		Bson res = usersProvider.queryUserInfoFromID(id);

		return fromBson!User(res);
	}
	
	static User fromLogin(string login, IUsersProvider usersProvider)
	{
		Bson res = usersProvider.queryUserInfo(login);
		
		return fromBson!User(res);
	}
	
	@ignore()
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

package enum t_session = "
	
	import core.time:dur;
	
	enum TIMEOUT = 5;//mins

	void setRedirect(string addr)
	{
		auto redirect = new Cookie(); 
		redirect.value = addr;
		redirect.maxAge = 10;
		res.cookies[\"redirect\"] = redirect;
	}
	
	bool isOnline(out string login)
	{

		if (req.session.id !is null)
		{
			auto logon_time = SysTime.fromISOExtString(req.session[\"logon_time\"]);
			if ((Clock.currTime() - logon_time) > dur!\"minutes\"(TIMEOUT))
			{
				return false;
			}
			else
			{
				login = req.session[\"login\"];
				return true;
			}
		}
		
		return false;
	}

	bool hasRedirect(out string addr)
	{
		try
		{
			addr = req.cookies.get(\"redirect\");
			res.setCookie(\"redirect\", null); //TODO: Why no effect?
			if (addr is null) return false;
            return true;
        }
        catch(Exception ex)
        {
        
        }
        return false;
    }   
	
	void activate(string login)
	{

		if (req.session.id !is null)
		{
			res.terminateSession();
		}
		
		auto session = res.startSession();
		session[\"login\"] = login;
		session[\"logon_time\"] = Clock.currTime().toISOExtString();
		session[\"ip\"]= req.host();
	}
	
";

package mixin template t_login()
{
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
	
	@GA(USER_ROLE.init, "/login")
	void login(HTTPServerRequest req, HTTPServerResponse res)
	{
		res.renderCompat!("ddust.login.dt", HTTPServerRequest,"req", MSG, "message")(req, MSG());
	}
	
	@GA(USER_ROLE.init, "/login")
	void postLogin(HTTPServerRequest req, HTTPServerResponse res)
	{
		mixin(t_session);
		
		LoginData loginData;		
		
		loadFormData(req, loginData, "auth");
		
		if (loginData.status == LOGIN_STATUS.OK)
		{
			auto msg = usersProvider.queryAuthorization(loginData.login, loginData.password);			
			
			if (msg)
			{
				string addr;
				activate(loginData.login);
				if (hasRedirect(addr))
				{
					res.redirect(addr);
				}
				else
				{
					res.redirect("/");
				}
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
}


package mixin template t_register()
{
	enum REG_DATA_STATUS:string
	{
		OK = "Login and Password is OK",
		
		INVALID_PASSWORD = "Password is invalid",
		
		INVALID_LOGIN = "Login is invalid",
		
		DONOT_MATCH_PASSWORDS = "Passwords don't match",
		
		USER_ALREADY_REGISTERED = "Login already registered"
	}
		
	struct RegisterData
	{
		mixin usersValidator;
		
		string login;
		
		string password;
		
		string repassword;
		
		USER_ROLE role;
		
		REG_DATA_STATUS status() @property
		{
			if (!isValidLogin(login)) return REG_DATA_STATUS.INVALID_LOGIN;
			
			if (password != repassword) return REG_DATA_STATUS.DONOT_MATCH_PASSWORDS;
			
			if (!isValidPassword(password)) return REG_DATA_STATUS.INVALID_PASSWORD;
			
			return REG_DATA_STATUS.OK;
		}
				
	}
	
	@GA(USER_ROLE.init, "/register")
	void register(HTTPServerRequest req, HTTPServerResponse res)
	{
		res.renderCompat!("ddust.register.dt", HTTPServerRequest, "req", MSG, "message")(req, MSG(false, ""));
	}
	
	@GA(USER_ROLE.init, "/register")
	void postRegister(HTTPServerRequest req, HTTPServerResponse res)
	{
		RegisterData regData;
		
		loadFormData(req, regData, "reg");
		
		string reason;
		void onError(Exception ex)
		{
			if (cast(UserAlreadyRegistered) ex)
			{
				reason = REG_DATA_STATUS.USER_ALREADY_REGISTERED;
			}
			else
			{
				reason = ex.msg;
			}
		}
		
		if (regData.status == REG_DATA_STATUS.OK)
		{
			auto msg = usersProvider.registerUser(regData.login, regData.password, &onError);
			
			if(msg)
			{
				res.renderCompat!("ddust.register.dt", HTTPServerRequest, "req", MSG, "message")(req, 
					MSG(false,""));
			}
			else
			{
				res.renderCompat!("ddust.register.dt", HTTPServerRequest, "req", MSG, "message")(req, 
					MSG(true, reason));
			} 
		}
		else 
		{
			res.renderCompat!("ddust.register.dt", HTTPServerRequest, "req", MSG, "message")(req, 
				MSG(true, regData.status));
		}
	}
}

package mixin template t_profile()
{
	enum PROFILE_DATA_STATUS:string
	{
		OK = "OK",
		INVALID_LOGIN = "Login is incorrect",
		INVALID_FIRSTNAME = "Firstname is incorrect",
		INVALID_LASTNAME = "Lastname is incorrect",
		INVALID_EMAIL = "Email is incorrect",
		INVALID_USERNAME = "Username is incorrect"
	}

	struct ProfileData
	{
		mixin usersValidator;
		
		string login;
		
		@optional()
		string username;
		
		@optional()
		string firstname;
		
		@optional()
		string lastname;
		
		@optional()
		string email;
		
		@ignore()
		string gravatarUrl() @property
		{
			return format("%s%s?s=200&d=identicon","http://www.gravatar.com/avatar/",toLower(md5str(email)));
		}

		
		PROFILE_DATA_STATUS status()
		{	
			if (!isValidLogin(login))
			{
				return PROFILE_DATA_STATUS.INVALID_LOGIN;
			}
			else if (!isValidFirstname(firstname))
			{
				return PROFILE_DATA_STATUS.INVALID_FIRSTNAME;
			}
			else if (!isValidLastname(lastname))
			{
				return PROFILE_DATA_STATUS.INVALID_LASTNAME;
			}
			else if (!isValidUsername(username))
			{
				return PROFILE_DATA_STATUS.INVALID_USERNAME;
			}
			else if (!isValidEmail(email))
			{
				return PROFILE_DATA_STATUS.INVALID_EMAIL;
			}
			
			return PROFILE_DATA_STATUS.OK;
		}
		
		
	}
	
	@GA(USER_ROLE.init, "/profile")
	void profile(HTTPServerRequest req, HTTPServerResponse res)
	{
		mixin(t_session);
		
		string login;
		
		if (isOnline(login))
		{
			auto userInfo = usersProvider.queryUserInfo(login);
			
			ProfileData data = fromBson!ProfileData(userInfo);
			
			res.renderCompat!("ddust.profile.dt", HTTPServerRequest, "req", ProfileData, 
				"profile_data", MSG, "message")(req, data, MSG());
		}
		else
		{
			setRedirect(req.fullURL.localURI);
			res.redirect("/login");
		}
		
	}
	
	@GA(USER_ROLE.init, "/profile")
	void postProfile(HTTPServerRequest req, HTTPServerResponse res)
	{
		mixin(t_session);
		
		ProfileData  profileData;
		
		loadFormData(req, profileData, "profile");
		
		string login;
		if (!isOnline(profileData.login))
		{
			return;
		}
		
		if (profileData.status != PROFILE_DATA_STATUS.OK)
		{
			res.renderCompat!("ddust.profile.dt", HTTPServerRequest, "req", ProfileData, 
				"profile_data", MSG, "message")(req, profileData, MSG(true, profileData.status));
		}
		else
		{
			
			string reason;
			void onError(Exception ex)
			{
				reason = ex.msg;
			}
			
			auto msg = usersProvider.updateProfile(profileData.login, profileData.toBson, &onError);
			
			if (msg)
			{
				res.renderCompat!("ddust.profile.dt", HTTPServerRequest, "req", ProfileData, 
					"profile_data", MSG, "message")(req, profileData, MSG(false, "Updated"));
			}
			else
			{
				res.renderCompat!("ddust.profile.dt", HTTPServerRequest, "req", ProfileData, 
					"profile_data", MSG, "message")(req, profileData, MSG(true, reason));
			}
		}
		
	}
} 

package mixin template usersPages()
{
	import util;
	import backend.iusers;
	
	mixin t_login;
	mixin t_profile;
	mixin t_register;
}