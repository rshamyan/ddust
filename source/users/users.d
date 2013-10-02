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
			
			auto res = coll.findOne(Bson(["login":Bson(login)]));
			
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
			
			Bson res = coll.findOne(Bson(["login":Bson(login)]));
			
			const Json json = res.toJson();
	
			bool ret = checkPassword(password, 
				json.passhash.to!string, json.salt.to!string);		
				
			logInfo("[Users]Authorization result for %s is %s", login, ret);
			
			return ret;
		}
		catch (Exception ex)
		{
			onError(ex);
		}
		
		return false;
	}
	
	Json queryUserInfo(alias onError = defaultErrorProcessor)(string login)
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
			
			Bson res = coll.findOne(Bson(["login":Bson(login)]));
			
			return res.toJson();
		}
		catch (Exception ex)
		{
			onError(ex);
		}
		
		return Json(null);
		
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
			
			Bson res = coll.findOne(["login": login]);
			
			return res["_id"].get!BsonObjectID;
		}
		catch (Exception ex)
		{
			onError(ex);
		}
		
		return BsonObjectID.fromString("000000000000000000000000");
	}
}
