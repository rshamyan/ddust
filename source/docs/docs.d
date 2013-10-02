module docs.docs;

import vibe.d;

import docs.idocs;

import util;

class MongoDocsProvider : DocsProvider, IDocs
{
	private MongoClient db;
	
	private enum DOCS_COLLECTION = "ddust.docs";
	
	private this(){};
	
	this (string dbAddress)
	{
		db = connectMongoDB(dbAddress);
	}
	
	this (string dbAddress, ushort port)
	{
		db = connectMongoDB(dbAddress, port);
	}
	
	private BsonObjectID toID(T)(T id)
	{
		static if (is(T : ubyte[12]))
		{
			return BsonObjectID(id);
		}
		else static if(is(T : string))
		{
			return BsonObjectID.fromString(id);
		}
		else static if (is(T: BsonObjectID))
		{
			return id;
		}
		
		//throw new InvalidID(id);
		
		//return BsonObjectID.fromString("000000000000000000000000");
	}
	
	private bool exists(T)(T id)
	{
		try
		{
			MongoCollection coll = db.getCollection(DOCS_COLLECTION);
			
			Bson res = coll.findOne(Bson(["_id":Bson(toID(id))]));
			
			return !res.isNull;
		}
		catch(Exception ex)
		{
			defaultErrorProcessor(ex);
		}
		
		return false;
	}
	
	private static const char[] checker = 
		"static if ((!is(typeof(onError) : Processor))&&(!is(typeof(&onError): Processor)))
		{
			pragma(msg ,\"[Docs]Typeof onError must be \", Processor,\" not \", typeof(onError));
			static assert(false);
		}";
	
	bool addDocument(alias onError = defaultErrorProcessor)(in Bson doc)
	{
		mixin(checker);
		try
		{
			if (!isValidDocType(doc, DocType.Document))
			{
				return false;
			}
			
			MongoCollection coll = db.getCollection(DOCS_COLLECTION);
			
			coll.insert(doc);
			
			logInfo("[Docs]Added document with title = %s", doc["title"].get!string);
			
			return true;
		}
		catch(Exception ex)
		{
			onError(ex);
		}
		
		return false;
	}
	
	bool removeDocument(T, alias onError = defaultErrorProcessor)(T id)
	{
		mixin(checker);
		try
		{
			if (!exists(id))
			{
				throw new DocDoesntExist(id);
			}
			
			MongoCollection coll = db.getCollection(DOCS_COLLECTION);
			
			coll.remove(Bson(["_id": Bson(toID(id))]));
			
			logInfo("[Docs]Removed document with id = %s", id);
			
			return true;
		}
		catch(Exception ex)
		{
			onError(ex);
		}
		
		return false;
	}
	
	bool addComment(T, alias onError = defaultErrorProcessor)(T docId, in Bson comment)
	{
		mixin(checker);
		try
		{
			if (!exists(docId))
			{
				throw new DocDoesntExist(docId);
			}
			
			if (!isValidComment(comment))
			{
				return false;
			}
			
			MongoCollection coll = db.getCollection(DOCS_COLLECTION);
			
			Bson req = Bson.emptyObject;
			
			foreach(string k,v; comment) 
			{
				req[k] = v;
			}
			
			req["_ref"] = Bson(toID(docId));			
			
			coll.insert(req);
			
			logInfo("[Docs]Added comment to id = %s", docId);
			
			return true;
		}
		catch(Exception ex)
		{
			onError(ex);
		}
		
		return false;
	}
	
	bool removeComment(T, alias onError = defaultErrorProcessor)(T id)
	{
		mixin(checker);
		try
		{
			if (!exists(id))
			{
				throw new DocDoesntExist(id);
			}
			
			MongoCollection coll = db.getCollection(DOCS_COLLECTION);
			
			coll.remove(Bson(["_id":Bson(toID(id))]));
			
			logInfo("[Docs]Removed comment with id = %s", id);
			
			return true;
		}
		catch (Exception ex)
		{
			onError(ex);
		}
		
		return false;
	}
	
	Bson queryDoc(T, alias onError = defaultErrorProcessor)(T id)
	{
		mixin(checker);
		try
		{
			if (!exists(id))
			{
				throw new DocDoesntExist(id);
			}
			
			MongoCollection coll = db.getCollection(DOCS_COLLECTION);
			
			Bson res = coll.findOne(Bson(["_id":Bson(toID(id))]));
			
			return res;
		}
		catch (Exception ex)
		{
			onError(ex);
		}
		
		return Bson(null);
	}
	
	Bson[] queryDocs(alias onError = defaultErrorProcessor)(DocType type, int count = 0)
	{
		mixin(checker);
		try
		{
			if (count < 0) 
			{
				throw new DocsInvalidQueryCount(count);
			}
			
			MongoCollection coll = db.getCollection(DOCS_COLLECTION);
			
			auto res = coll.find(
				Bson(["$query": Bson(["_type":Bson(cast(int)type)]), 
					"$orderby":Bson(["date" : Bson(-1)]) ]),
				Bson.emptyObject,
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
	
	Bson[] queryDocuments(alias onError = defaultErrorProcessor)(int count = 0)
	{
		mixin(checker);
		
		return queryDocs!onError(DocType.Document, count);
	}
	
	Bson queryDocument(T, alias onError)(T id)
	{
		mixin(checker);
		return queryDoc!(T, onError)(id);
	}
	
	Bson queryComment(T, alias onError = defaultErrorProcessor)(T id)
	{
		mixin(checker);
		return queryDoc!(T, onError)(id);
	}
	
	Bson[] queryComments(T, alias onError = defaultErrorProcessor)(T id, int count = 0)
	{
		mixin(checker);
		try
		{
			if (count < 0) 
			{
				throw new DocsInvalidQueryCount(count);
			}
			
			if (!exists(id))
			{
				throw new DocDoesntExist(id);
			}
			
			MongoCollection coll = db.getCollection(DOCS_COLLECTION);
			
			auto res = coll.find(
				Bson(["$query": Bson(["_type":Bson(cast(int)DocType.Comment), "_ref": Bson(toID(id))]), 
					"$orderby":Bson(["date" : Bson(1)]) ]),
				Bson.emptyObject,
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