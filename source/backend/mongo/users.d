module backend.mongo.users;

import vibe.d;

import backend.iusers;
import util;

class MongoUsersProvider : IUsersProvider
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
	
	private bool exists(BID id)
	{
		try
		{
			MongoCollection coll = db.getCollection(USERS_COLLECTION);
			
			Bson res = coll.findOne(Bson(["_id":Bson(id)]));
			
			return !res.isNull;
		}
		catch(Exception ex)
		{
			defaultErrorProcessor(ex);
		}
		
		return false;
	}
			
	protected bool isLoginRegisteredImpl(string login)
	{
		MongoCollection coll = db.getCollection(USERS_COLLECTION);
			
		auto res = coll.findOne(Bson(["login":Bson(login)]),
			Bson(["_id":Bson(1)]));
		
		return !res.isNull;
	
	}
	
	protected bool registerUserImpl(string login, string password)
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
		
		logInfo("[Users]login %s successfully registered", login);
		
		return true;
		
	}
	
	protected bool queryAuthorizationImpl(string login, string password)
	{			
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
	
	protected Bson queryUserInfoImpl(string login)
	{			
		if (!isLoginRegistered(login))
		{
			throw new UserNotFound(login);
		}
		
		MongoCollection coll = db.getCollection(USERS_COLLECTION);
		
		Bson res = coll.findOne(Bson(["login":Bson(login)]),
			Bson(["passhash":Bson(0), "salt":Bson(0)]));
		
		return res;
	}
	
	protected Bson queryUserInfoFromIDImpl(BID id)
	{
		if(!exists(id))
		{
			throw new UsersException("[Users]ID %s doesnt' exists", id);
		}
		
		MongoCollection coll = db.getCollection(USERS_COLLECTION);
		
		Bson res = coll.findOne(Bson(["_id":Bson(id)]),
			Bson(["passhash":Bson(0), "salt":Bson(0)]));
		
		return res;
	}
	
	protected bool updateProfileImpl(string login, in Bson userInfo)
	{			
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
	
	protected BID queryIDImpl(string login)
	{		
		if (!isLoginRegistered(login))
		{
			throw new UserNotFound(login);
		}
		
		MongoCollection coll = db.getCollection(USERS_COLLECTION);
		
		Bson res = coll.findOne(["login": login], Bson(["_id":Bson(1)]));
		
		return res["_id"].get!BsonObjectID;
	}
	
	protected Bson[] queryUsersImpl(int count = 0)
	{
		byte order = 1;
		if (count < 0) order = -1;
		MongoCollection coll = db.getCollection(USERS_COLLECTION);
		
		auto res = coll.find(
			Bson(["$query": Bson.EmptyObject, 
				"$orderby":Bson(["login" : Bson(order)]) ]),
			["_id":1, "login":1],
			QueryFlags.None, 0, count);
		
		auto ret = new Bson[0];
		
		foreach(doc; res)
		{
			ret ~= doc;
		}
		
		return ret;
	}
}
