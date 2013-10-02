module users.users;

import vibe.d;

import users.iusers;

import util;

class MongoUsersProvider : UsersProvider, IUsers
{
	/// default users collection
	private enum USERS_COLLECTION = "ddust.users";
	
	private MongoClient db;
	
	private this() //block default constructor
	{
		
	}
	
	this(string dbAddress)
	{
		db = connectMongoDB(dbAddress);
	}
	
	this(string dbAdrress, ushort port)
	{
		db = connectMongoDB(dbAdrress, port);
	}
	
	private static const char[] checker = 
		"static if ((!is(typeof(onError) : Processor))&&(!is(typeof(&onError): Processor)))
		{
			pragma(msg ,\"[Users]Typeof onError must be \", Processor,\" not \", typeof(onError));
			static assert(false);
		}";
			
	bool isLoginRegistered(alias onError = defaultErrorProcessor)(string login) @property
	{
		mixin(checker);
		try
		{
			MongoCollection coll = db.getCollection(USERS_COLLECTION);
			
			auto res = coll.findOne(Bson(["login":Bson(login)]),
				Bson(["_id":Bson(1)]));
			
			return !res.isNull;
		}
		catch (Exception ex)
		{
			onError(ex);
		}
		
		return true;
	
	}
	
	bool registerUser(alias onError = defaultErrorProcessor)(string login, string password)
	{	
		mixin(checker);
		try
		{
			if(isLoginRegistered(login))
			{
				throw new UserAlreadyRegistered(login);
			}
			
			MongoCollection coll = db.getCollection(USERS_COLLECTION);
			
			auto gened = genPasshash2Store(password);
			
			coll.insert(Bson([
					"login":Bson(login), 
					"passhash": Bson(gened.hash), 
					"salt": Bson(gened.salt), 
					"regdate": Bson(BsonDate(Clock.currTime()))
					]));
			
			return true;
			
		}
		catch (Exception ex)
		{
			onError(ex);
		}
		
		return false;
		
	}
	
	bool queryAuthorization(alias onError = defaultErrorProcessor)(string login, string password)
	{	
		mixin(checker);		
		try
		{
			if (!isValidPassword(password))
			{
				throw new UsersInvalidData("password", "");
			}
			
			if (!isValidLogin(login))
			{
				throw new UsersInvalidData("login", login);
			}
			
			if (!isLoginRegistered(login))
			{
				throw new UserAlreadyRegistered(login);
			}
			
			MongoCollection coll = db.getCollection(USERS_COLLECTION);
			
			Bson res = coll.findOne(Bson(["login":Bson(login)]), 
				Bson(["_id":Bson(1), "passhash":Bson(1), "salt":Bson(1)]));
	
			bool ret = checkPassword(password, 
				res["passhash"].get!string, res["salt"].get!string);		
				
			logInfo("[Users]Authorization result for %s is %s", login, ret);
			
			return ret;
		}
		catch (Exception ex)
		{
			onError(ex);
		}
		
		return false;
	}
	
	Bson queryUserInfo(alias onError = defaultErrorProcessor)(string login)
	{
		mixin(checker);
		try
		{
			if (!isValidLogin(login))
			{
				throw new UsersInvalidData("login", login);
			}
			
			if (!isLoginRegistered(login))
			{
				throw new UserNotFound(login);
			}
			
			MongoCollection coll = db.getCollection(USERS_COLLECTION);
			
			Bson res = coll.findOne(Bson(["login":Bson(login)]),
				Bson(["passhash":Bson(0), "salt":Bson(0)]));
			
			return res;
		}
		catch (Exception ex)
		{
			onError(ex);
		}
		
		return Bson.emptyObject;
		
	}
	
	bool updateProfile(alias onError = defaultErrorProcessor)(string login, in Bson userInfo)
	{
		mixin(checker);
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
			
			if (!isLoginRegistered(login))
			{
				throw new UserNotFound(login);
			}
			
			MongoCollection coll = db.getCollection(USERS_COLLECTION);
			
			Bson res = coll.findOne(["login": login]);
			
			foreach(string k,v; userInfo)
			{
				res[k]=v;
			}
			
			coll.update(Bson(["login":Bson(login)]), res);
			
			logInfo("[Users]Modyfied %s's profile:%s", login, userInfo.toJson);
			
			return true;
		}
		catch (Exception ex)
		{
			onError(ex);
		}
		
		return false;
	}
	
	BsonObjectID queryID(alias onError = defaultErrorProcessor)(string login)
	{
		mixin(checker);
		try
		{
			if (!isValidLogin(login))
			{
				throw new UsersInvalidData("login", login);
			}
			
			if (!isLoginRegistered(login))
			{
				throw new UserNotFound(login);
			}
			
			MongoCollection coll = db.getCollection(USERS_COLLECTION);
			
			Bson res = coll.findOne(["login": login], Bson(["_id":Bson(1)]));
			
			return res["_id"].get!BsonObjectID;
		}
		catch (Exception ex)
		{
			onError(ex);
		}
		
		return BsonObjectID.fromString("000000000000000000000000");
	}
	
	Bson[] queryUsers(alias onError = defaultErrorProcessor)(int count = 0)
	{
		mixin(checker);
		try
		{
			if (count < 0) 
			{
				throw new UsersInvalidQueryCount(count);
			}
			
			MongoCollection coll = db.getCollection(USERS_COLLECTION);
			
			auto res = coll.find(
				Bson(["$query": Bson.emptyObject, 
					"$orderby":Bson(["login" : Bson(1)]) ]),
				["_id":1, "login":1],
				QueryFlags.None, 0, count);
			
			auto ret = new Bson[0];
			
			foreach(doc; res)
			{
				ret ~= doc;
			}
			
			return ret;
		}
		catch(Exception ex)
		{
			onError(ex);
		}
		
		return null;
	}
}
