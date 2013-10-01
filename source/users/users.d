module users.users;

import vibe.d;

import users.iusers;

class MongoUsersProvider : UsersProvider, IUsers
{
	/// default users collection
	private enum USERS_COLLECTION = "ddust.users";
	
	private MongoClient db;
	
	private this()
	{
		
	}
	
	this(string dbAddress)
	{
		db = connectMongoDB(dbAddress);
	}
			
	bool isLoginRegistered(string login, Processor onError = &defaultErrorProcessor) @property
	{
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
	
	bool registerUser(string login, string password, Processor onError = &defaultErrorProcessor)
	{	
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
	
	bool queryAuthorization(string login, string password, Processor onError = &defaultErrorProcessor)
	{			
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
	
	Json queryUserInfo(string login, Processor onError = &defaultErrorProcessor)
	{
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
	
	bool updateProfile(string login, Bson userInfo, Processor onError = &defaultErrorProcessor)
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
}
