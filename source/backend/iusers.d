module backend.iusers;

import std.typecons;
import std.digest.md;
import std.ascii;
import std.array;
import std.random;
import std.regex;

import vibe.d;

import util;

/**
* Interface for module users
*
* Dependecies
* 	vibe.d
*/
interface IUsersProvider: Immortal
{
	mixin usersValidator;
	
	static protected enum HASH_POWER = 1042; // don't touch!
	
	static protected enum SALT_LENGTH_MIN = 10;
	static protected enum SALT_LENGTH_MAX = 20;
	
	static assert(SALT_LENGTH_MIN < SALT_LENGTH_MAX);
	
	static protected alias Tuple!(string, "hash", string, "salt") GeneratedPassHash;
	
	static protected GeneratedPassHash genPasshash2Store(string passhash)
	out(result)
	{
		assert(checkPassword(passhash, result.hash, result.salt));
	}
	body
	{
		GeneratedPassHash res;
	
		string salt = generateSalt();
		ubyte[16] result = md5Of(salt ~ passhash ~ salt);
	
		foreach(i; 0..HASH_POWER-1)
		{
			MD5 md;
			md.start();
			md.put(cast(ubyte[])salt[]);
			md.put(result[]);
			md.put(cast(ubyte[])salt[]);
			result = md.finish();
		}
	
		res.hash = toHexString(result).idup;
		res.salt = salt;
		return res;
	}
	
	static protected string generateSalt()
	out(value)
	{
		assert(value.length < SALT_LENGTH_MAX);
		assert(value.length >= SALT_LENGTH_MIN);
	}
	body
	{
		static string alph = letters ~ digits;
		auto saltBuilder = appender!string();
		Mt19937 gen;
		gen.seed(unpredictableSeed);
	
		foreach(i; SALT_LENGTH_MIN .. SALT_LENGTH_MAX)
		{
			saltBuilder.put(alph[uniform(0, alph.length, gen)]);
		}
		return saltBuilder.data;
	}
	
	static final protected bool checkPassword(string hash2Check, string storedHash, string salt)
	in
	{
		assert(salt.length < SALT_LENGTH_MAX);
		assert(salt.length >= SALT_LENGTH_MIN);
	}
	body
	{
		ubyte[16] result = md5Of(salt ~ hash2Check ~ salt);
	
		foreach(i; 0..HASH_POWER-1)
		{
			MD5 md;
			md.start();
			md.put(cast(ubyte[])salt[]);
			md.put(result[]);
			md.put(cast(ubyte[])salt[]);
			result = md.finish();
		}
	
		return toHexString(result) == storedHash; 
	}
	
	/// check, is login registered
	final bool isLoginRegistered(alias onError = defaultErrorProcessor)(string login)
	{
		mixin(procCheck);
		try
		{
			return isLoginRegisteredImpl(login);
		}
		catch(Exception ex)
		{
			onError(ex);
		}
		
		return false;
	}
	
	protected bool isLoginRegisteredImpl(string login);
	
	/// register user
	final bool registerUser(string login, string password, Proc onError = defaultErrorProc)
	{
		try
		{
			if (!isValidPassword(password))
			{
				throw new UsersInvalidData("password", "******");
			}
			
			if (!isValidLogin(login))
			{
				throw new UsersInvalidData("login", login);
			}
			
			return registerUserImpl(login, password);
		}
		catch(Exception ex)
		{
			onError(ex);
		}
		
		return false;
	}
	
	protected bool registerUserImpl(string login,string password);
	
	/**
	* Returns:
	*	true if login and password are contained in db
	*/
	final bool queryAuthorization(string login, string password, Proc onError = defaultErrorProc)
	{
		try
		{
			if (!isValidPassword(password))
			{
				throw new UsersInvalidData("password", "******");
			}
			
			if (!isValidLogin(login))
			{
				throw new UsersInvalidData("login", login);
			}
			
			return queryAuthorizationImpl(login, password);
		}
		catch(Exception ex)
		{
			onError(ex);
		}
		
		return false;
	}
	
	protected bool queryAuthorizationImpl(string login, string password);
	
	/**
	* Returns:
	* 	Type which represent all information about login
	*	or null on exception
	*/
	final Bson queryUserInfo(string login, Proc onError = defaultErrorProc)
	{
		try
		{
			if (!isValidLogin(login))
			{
				throw new UsersInvalidData("login", login);
			}
			
			return queryUserInfoImpl(login);
		}
		catch(Exception ex)
		{
			onError(ex);
		}
		
		return Bson.emptyObject;
	}
	
	protected Bson queryUserInfoImpl(string login);
	
	/**
	* query userinfo from id
	*/
	final Bson queryUserInfoFromID(BID id, Proc onError = defaultErrorProc)
	{
		try
		{
			return queryUserInfoFromIDImpl(id);
		}
		catch(Exception ex)
		{
			onError(ex);
		}
		
		return Bson.emptyObject;
	}
	
	protected Bson queryUserInfoFromIDImpl(BID id);
	
	/**
	* Params:
	* 	userInfo = Type (Bson) which contains fields to be replaced or added
	*/
	final bool updateProfile(string login, in Bson userInfo, Proc onError = defaultErrorProc)
	{
		try
		{
			if (!isValidLogin(login))
			{
				throw new UsersInvalidData("login", login);
			}
			
			if (!isValidUserInfo(userInfo))
			{
				throw new UsersInvalidData("userInfo", userInfo.toJson());
			}
			
			return updateProfileImpl(login, userInfo);
		}
		catch(Exception ex)
		{
			onError(ex);
		}
		
		return false;
	}
	
	protected bool updateProfileImpl(string login, in Bson userInfo);
	
	/**
	* Returns:
	* 	id which represent user in database
	*
	*/
	final BID queryID(string login, Proc onError = defaultErrorProc)
	{
		try
		{
			if (!isValidLogin(login))
			{
				throw new UsersInvalidData("login", login);
			}
			
			return queryIDImpl(login);
		}
		catch(Exception ex)
		{
			onError(ex);
		}
		
		return BsonObjectID.fromString("0000000000000000000000");
	}
	
	protected BID queryIDImpl(string login);
	
	/**
	* Params:
	* 	count = number, that represent max query size. If count = 0, then will queried all users
	*			If count < 0 returns users form Z..A
	* Returns:
	* 	array of users(id, login) in alphabetic order	
	*/
	final Bson[] queryUsers(int count = 0, Proc onError = defaultErrorProc)
	{
		try
		{
			return queryUsersImpl(count);
		}
		catch(Exception ex)
		{
			onError(ex);
		}
		
		return new Bson[0];
	} 
	
	protected Bson[] queryUsersImpl(int count = 0);
}

mixin template usersValidator()
{
	static bool isValidLogin(in string login)
	{
		return to!bool(match(login, r"^[a-zA-Z][a-zA-Z0-9.\\-_]{2,20}"));
	}
		
	static bool isValidPassword(in string password)
	{
		return to!bool(match(password, r"[a-zA-Z0-9.\\-_]{3,20}"));
	}
	
	static bool isValidEmail(in string email)
	{
		return to!bool(match(email, r"[a-z0-9.\\-_]{3,100}@[a-z0-9.\\-_]{3,100}\.[a-z]{2,4}"));
	}
	
	static bool isValidFirstname(in string firstname)
	{
		return to!bool(match(firstname, r"[a-zA-Z][a-zA-Z0-9.\\-_]{3,20}"));
	}
	
	static bool isValidLastname(in string lastname)
	{
		return to!bool(match(lastname, r"[a-zA-Z][a-zA-Z0-9.\\-_]{3,20}"));
	}
	
	static bool isValidUsername(in string username)
	{
		return to!bool(match(username, r"[a-zA-Z][a-zA-Z0-9.\\-_]{3,20}"));
	}
	
	static bool isValidUserInfo(in Bson userInfo)
	{
		Json json = userInfo.toJson();
		
		foreach(string k,v; json)
		{
			if ((k == "login")&&(!isValidLogin(v.to!string)))
			{
				throw new UsersInvalidData(k, v.to!string);
			}
			
			else if((k == "email")&&(!isValidEmail(v.to!string)))
			{
				throw new UsersInvalidData(k, v.to!string);
			}
			
			else if ((k == "firstname")&&(!isValidFirstname(v.to!string)))
			{
				throw new UsersInvalidData(k, v.to!string);
			}
			
			else if((k == "lastname")&&(!isValidLastname(v.to!string)))
			{
				throw new UsersInvalidData(k, v.to!string);
			}
			
			else if ((k == "username")&&(!isValidUsername(v.to!string)))
			{
				throw new UsersInvalidData(k, v.to!string);
			}
		}
		
		return true;
	}
}


class UsersException: Exception
{
	this(T...)(string fmt, auto ref T args)
	{
		super(format(fmt, args));
	}
}

class UserNotFound: UsersException
{
	this(string login)
	{
		super("[Users]Login %s not found", login);
	}
}

class UsersInvalidData: UsersException
{
	this(T)(string field, T value)
	{
		super("[Users]Invalid %s = %s", field, value);
	}
}

class UserAlreadyRegistered: UsersException
{
	this(string login)
	{
		super("[Users]Login %s already registered", login);
	}
}

class UsersInvalidQueryCount: UsersException
{
	this(int i)
	{
		super("[Users]Invalid query count %d", i);
	}
}