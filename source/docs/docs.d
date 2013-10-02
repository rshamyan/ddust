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
		
		throw new InvalidID(id);
		
		return null;
	}
	
	private bool exists(T)(T id)
	{
		try
		{
			MongoCollection coll = db.getCollection(DOCS_COLLECTION);
			
			Bson res = coll.findOne(Bson(["_id":toID(id)]));
			
			return !res.isNull;
		}
		catch(Execption ex)
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
			if (!exists(id))
			{
				throw new DocDoesntExist(id);
			}
			
			if (!isValidDocumentType(comment, DocType.Comment))
			{
				return false;
			}
			
			MongoCollection coll = db.getCollection(DOCS_COLLECTION);
			
			comment._ref = Bson(toID(docId));
			
			coll.insert(comment);
			
			logInfo("[Docs]Added comment to id = %s", docID);
			
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
	
	auto queryDoc(T, alias onError)(T id)
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
	
	auto queryDocument(T, alias onError)(T id)
	{
		mixin(checker);
		return queryDoc!(T, onError)(id);
	}
	
	auto queryComment(T, alias onError)(T id)
	{
		mixin(checker);
		return queryDoc!(T, onError)(id);
	}
}