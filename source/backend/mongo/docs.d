module backend.mongo.docs;

import vibe.d;

import backend.idocs;

import util;

public class MongoDocsProvider : IDocsProvider
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
	
	private bool exists(BID id)
	{
		try
		{
			MongoCollection coll = db.getCollection(DOCS_COLLECTION);
			
			Bson res = coll.findOne(Bson(["_id":Bson(id)]));
			
			return !res.isNull;
		}
		catch(Exception ex)
		{
			defaultErrorProcessor(ex);
		}
		
		return false;
	}
	
	protected bool addDocumentImpl(in Bson doc)
	{		
		MongoCollection coll = db.getCollection(DOCS_COLLECTION);
		
		coll.insert(doc);
		
		logInfo("[Docs]Added document with title = %s", doc["title"].get!string);
		
		return true;
	}
	
	protected bool removeDocumentImpl(BID id)
	{
		if (!exists(id))
		{
			throw new DocDoesntExist(id);
		}
		
		MongoCollection coll = db.getCollection(DOCS_COLLECTION);
		
		coll.remove(Bson(["_id": Bson(id)]));
		
		logInfo("[Docs]Removed document with id = %s", id);
		
		return true;
	}
	
	protected bool addCommentImpl(BID docId, in Bson comment)
	{
		if (!exists(docId))
		{
			throw new DocDoesntExist(docId);
		}
		
		MongoCollection coll = db.getCollection(DOCS_COLLECTION);
		
		Bson req = Bson.emptyObject;
		
		foreach(string k,v; comment) 
		{
			req[k] = v;
		}
		
		req["_ref"] = Bson(docId);			
		
		coll.insert(req);
		
		logInfo("[Docs]Added comment to id = %s", docId);
		
		return true;
	}
	
	protected bool removeCommentImpl(BID id)
	{
		if (!exists(id))
		{
			throw new DocDoesntExist(id);
		}
		
		MongoCollection coll = db.getCollection(DOCS_COLLECTION);
		
		coll.remove(Bson(["_id":Bson(id)]));
		
		logInfo("[Docs]Removed comment with id = %s", id);
		
		return true;
	}
	
	protected Bson queryDoc(BID id)
	{
		if (!exists(id))
		{
			throw new DocDoesntExist(id);
		}
		
		MongoCollection coll = db.getCollection(DOCS_COLLECTION);
		
		Bson res = coll.findOne(Bson(["_id":Bson(id)]));
		
		return res;
	}
	
	protected Bson[] queryDocs(DocType type, int count = 0)
	{
		byte order = 1;
		if (count < 0) 
		{
			order = -1;
		}
		
		MongoCollection coll = db.getCollection(DOCS_COLLECTION);
		
		auto res = coll.find(
			Bson(["$query": Bson(["_type":Bson(cast(int)type)]), 
				"$orderby":Bson(["date" : Bson(order)]) ]),
			Bson.emptyObject,
			QueryFlags.None, 0, count);
		
		auto ret = new Bson[0];
		
		foreach(doc; res)
		{
			ret ~= doc;
		}
		
		return ret;
	}
	
	protected Bson[] queryDocumentsImpl(int count = 0)
	{		
		return queryDocs(DocType.Document, count);
	}
	
	protected Bson queryDocumentImpl(BID id)
	{
		return queryDoc(id);
	}
	
	protected Bson queryBlogDocumentImpl(BID id)
	{
		
		return queryDoc(id);
	}
	
	protected Bson queryCommentImpl(BID id)
	{
		return queryDoc(id);
	}
	
	protected Bson[] queryCommentsImpl(BID id, int count = 0)
	{
		byte order = 1;
		
		if (count < 0) 
		{
			order = -1;
		}
		
		if (!exists(id))
		{
			throw new DocDoesntExist(id);
		}
		
		MongoCollection coll = db.getCollection(DOCS_COLLECTION);
		
		auto res = coll.find(
			Bson(["$query": Bson(["_type":Bson(cast(int)DocType.Comment), "_ref": Bson(id)]), 
				"$orderby":Bson(["date" : Bson(order)]) ]),
			Bson.emptyObject,
			QueryFlags.None, 0, count);
		
		auto ret = new Bson[0];
		
		foreach(doc; res)
		{
			ret ~= doc;
		}
		
		return ret;
	}
	
	protected bool addBlogCategoryImpl(in Bson cat)
	{	
		MongoCollection coll = db.getCollection(DOCS_COLLECTION);
		
		coll.insert(cat);
		
		logInfo("[Docs]Added blogCategory %s", cat["name"].get!string);
		
		return true;
	}
	
	protected bool addBlogDocumentImpl(in Bson doc)
	{
		MongoCollection coll = db.getCollection(DOCS_COLLECTION);
		
		coll.insert(doc);
		
		logInfo("[Docs]Added blogDocument %s", doc["title"].get!string);
		
		return true;
	}
	
	protected bool removeBlogCategoryImpl(BID id)
	{
		if(!exists(id))
		{
			throw new DocDoesntExist(id);
		}
		
		MongoCollection coll = db.getCollection(DOCS_COLLECTION);
		
		coll.remove(Bson(["_id": Bson(id)]));
		
		logInfo("[Docs]Deleted blogCategory with id = %s", id);
		
		return true;
	}
	
	protected bool removeBlogDocumentImpl(BID id)
	{
		if(!exists(id))
		{
			throw new DocDoesntExist(id);
		}
		
		MongoCollection coll = db.getCollection(DOCS_COLLECTION);
		
		coll.remove(Bson(["_id": Bson(id)]));
		
		logInfo("[Docs]Deleted blogDocument with id = %s", id);
		
		return true;
	}
	
	protected Bson[] queryBlogDocumentsImpl(int count = 0)
	{
		return queryDocs(DocType.BlogDocument, count);
	}
	
	protected Bson[] queryBlogDocumentsImpl(int count, BID catId)
	{
		byte order = 1;
		if (count < 0) 
		{
			order = -1;
		}
		
		if (!exists(catId))
		{
			throw new DocDoesntExist(catId);
		}
		
		MongoCollection coll = db.getCollection(DOCS_COLLECTION);
		
		auto res = coll.find(
			Bson(["$query": Bson(["_type":Bson(cast(int)DocType.BlogDocument), "_ref":Bson(catId)]), 
				"$orderby":Bson(["date" : Bson(order)]) ]),
			Bson.emptyObject,
			QueryFlags.None, 0, count);
		
		auto ret = new Bson[0];
		
		foreach(doc; res)
		{
			ret ~= doc;
		}
		
		return ret;
	}
}