module users.iusers;

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
interface IUsers
{
	/// check, is login registered
	bool isLoginRegistered(alias onError)(string login);
	
	/// register user
	bool registerUser(alias onError)(string login, string password);
	
	/**
	* Returns:
	*	true if login and password are contained in db
	*/
	bool queryAuthorization(alias onError)(string login, string password);
	
	/**
	* Returns:
	* 	Type which repsesent all information about login
	*	or Json(null)
	*/
	auto queryUserInfo(alias onError)(string login);
	
	/**
	* Params:
	* 	userInfo = Type (see implementation) which contains fields to be replaced or added
	*/
	bool updateProfile(alias onError)(string login, in auto userInfo);
	
	/**
	* Returns:
	* 	id which represent user in database
	*
	*/
	auto queryID(alias onError)(string login);
	
}

mixin template usersValidator()
{
	bool isValidLogin(in string login)
	{
		return to!bool(match(login, r"^[a-zA-Z][a-zA-Z0-9.\\-_]{2,20}"));
	}
		
	bool isValidPassword(in string password)
	{
		return to!bool(match(password, r"[a-zA-Z0-9.\\-_]{3,20}"));
	}
	
	bool isValidEmail(in string email)
	{
		return to!bool(match(email, r"[a-z0-9.\\-_]{3,100}@[a-z0-9.\\-_]{3,100}\.[a-z]{2,4}"));
	}
	
	bool isValidFirstname(in string firstname)
	{
		return to!bool(match(firstname, r"[a-zA-Z][a-zA-Z0-9.\\-_]{3,20}"));
	}
	
	bool isValidLastname(in string lastname)
	{
		return to!bool(match(lastname, r"[a-zA-Z][a-zA-Z0-9.\\-_]{3,20}"));
	}
	
	bool isValidUsername(in string username)
	{
		return to!bool(match(username, r"[a-zA-Z][a-zA-Z0-9.\\-_]{3,20}"));
	}
	
	bool isValidUserInfo(in Bson userInfo)
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

abstract class UsersProvider
{
	protected enum HASH_POWER = 1042; // don't touch!
	
	protected enum SALT_LENGTH_MIN = 10;
	protected enum SALT_LENGTH_MAX = 20;
	
	static assert(SALT_LENGTH_MIN < SALT_LENGTH_MAX);
	
	protected alias Tuple!(string, "hash", string, "salt") GeneratedPassHash;
	
	protected GeneratedPassHash genPasshash2Store(string passhash)
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
	
	protected string generateSalt()
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
	
	protected bool checkPassword(string hash2Check, string storedHash, string salt)
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
	
	mixin usersValidator;
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