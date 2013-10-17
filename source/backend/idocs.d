module backend.idocs;

import std.conv;
import std.string;
import std.variant;

import vibe.d;

import util;

enum DocType: int
{
	Undefined = 0x00,
	
	Document = 0x01,
	
	News = 0x02,
	
	Comment = 0x03,
	
	BlogDocument = 0x04,
	
	BlogCategory = 0x05,
	
	ForumThread = 0x06,
	
	ForumTopic = 0x07,
	
	ForumReply = 0x08
}

interface IDocsProvider:Immortal
{
	mixin docsValidator;
	
	/**
	* add Document
	*/
	final bool addDocument(in Bson doc, Proc onError = defaultErrorProc)
	{
		try
		{
			if (!isValidDocType(doc, DocType.Document))
			{
				return false;
			}
			
			return addDocumentImpl(doc);
		}
		catch(Exception ex)
		{
			onError(ex);
		}
		
		return false;
	}
	
	protected bool addDocumentImpl(in Bson doc);
	
	/**
	* remove Document
	*/
	final bool removeDocument(BID id, Proc onError = defaultErrorProc)
	{
		try
		{
			return removeDocumentImpl(id);
		}
		catch(Exception ex)
		{
			onError(ex);
		}
		
		return false;
	}
	
	protected bool removeDocumentImpl(BID id);
	
	/**
	* add Comment to id
	*/
	final bool addComment(BID docId, in Bson comment, Proc onError = defaultErrorProc)
	{
			try
			{
				if (!isValidComment(comment))
				{
					return false;
				}
				
				return addCommentImpl(docId, comment);
			}
			catch(Exception ex)
			{
				onError(ex);
			}
			
			return false;
	}
	
	protected bool addCommentImpl(BID docId, in Bson comment);
	
	/**
	* remove Comment
	*/
	final bool removeComment(BID id, Proc onError = defaultErrorProc)
	{
		try
		{
			return removeCommentImpl(id);
		}
		catch (Exception ex)
		{
			onError(ex);
		}
		
		return false;
	}
	
	protected bool removeCommentImpl(BID id);
	
	/**
	* query document with id
	* Params:
	*	id = document id
	*/
	final Bson queryDocument(BID id, Proc onError = defaultErrorProc)
	{
		try
		{
			return queryDocumentImpl(id);
		}
		catch (Exception ex)
		{
			onError(ex);
		}
		
		return Bson.EmptyObject;
	}
	
	protected Bson queryDocumentImpl(BID id);
	
	/**
	* query Comment with id
	* Params:
	*	id = comment id
	*/
	final Bson queryComment(BID id, Proc onError = defaultErrorProc)
	{
		try
		{
			return queryCommentImpl(id);
		}
		catch (Exception ex)
		{
			onError(ex);
		}
		
		return Bson.EmptyObject;
	}
	
	protected Bson queryCommentImpl(BID id);
	
	/**
	* query documents
	* Params:
	* 	count = quering size. If count = 0 then will queried all documents referencing to id from newest to oldest 
	* Returns:
	* 	If count > 0 then returns documents from newest to oldest. 
	*	If count < 0 then returns documents from oldest to newest
	*/
	final Bson[] queryDocuments(int count = 0, Proc onError = defaultErrorProc)
	{
		try
		{
			return queryDocumentsImpl(count);
		}
		catch(Exception ex)
		{
			onError(ex);
		}
		
		return new Bson[0];
	}
	
	protected Bson[] queryDocumentsImpl(int count = 0);
	
	/**
	* query comments to id
	* Params:
	* 	id = comments id
	* 	count = quyering size. If count = 0 then will queried all comments referencing to id from newest to oldest 
	* Returns:
	* 	If count > 0 then returns comments from newest to oldest. 
	*	If count < 0 then returns comments from oldest to newest
	*/
	final Bson[] queryComments(BID id, int count = 0, Proc onError = defaultErrorProc)
	{
		try
		{
			return queryCommentsImpl(id, count);
		}
		catch(Exception ex)
		{
			onError(ex);
		}
		
		return null;
	}
	
	protected Bson[] queryCommentsImpl(BID id, int count = 0);
	
	/**
	* add blogDocument
	*/
	final bool addBlogDocument(Bson doc, Proc onError = defaultErrorProc)
	{
		try
		{
			if (!isValidBlogDocument(doc))
			{
				return false;
			}
			
			return addBlogDocumentImpl(doc);
			
		}
		catch(Exception ex)
		{
			onError(ex);
		}
		
		return false;
	}
	
	protected bool addBlogDocumentImpl(in Bson doc);
	
	
	/**
	* remove blog document
	*/
	final bool removeBlogDocument(BID id, Proc onError = defaultErrorProc)
	{
		try
		{
			return removeBlogDocumentImpl(id);
		}
		catch(Exception ex)
		{
			onError(ex);
		}
		
		return false;
	}
	
	protected bool removeBlogDocumentImpl(BID id);
	
	/**
	* add blog category
	*/
	final bool addBlogCategory(Bson cat, Proc onError = defaultErrorProc)
	{
		try
		{
			if (!isValidBlogCategory(cat))
			{
				return false;
			}
			
			return addBlogCategoryImpl(cat);
		}
		catch(Exception ex)
		{
			onError(ex);
		}
		
		return false;
	}
	
	protected bool addBlogCategoryImpl(in Bson cat);
	
	/**
	* remove blog category
	*/
	final bool removeBlogCategory(BID catID, Proc onError = defaultErrorProc)
	{
		try
		{
			return removeBlogCategoryImpl(catID);
		}
		catch (Exception ex)
		{
			onError(ex);
		}
		
		return false;
	}
	
	protected bool removeBlogCategoryImpl(BID catID);
	
	/**
	* query last blog documents from all categories
	* Params:
	* 	count = quering size. If count = 0 then will queried all blog documents referencing from newest to oldest 
	* Returns:
	* 	If count > 0 then returns blog documents from newest to oldest. 
	*	If count < 0 then returns blog documents from oldest to newest
	*/	
	final Bson[] queryBlogDocuments(int count = 0, Proc onError = defaultErrorProc)
	{
		try
		{
			return queryBlogDocumentsImpl(count);
		}
		catch (Exception ex)
		{
			onError(ex);
		}
		
		return null;
	}
	
	protected Bson[] queryBlogDocumentsImpl(int count);
	
	/**
	* query blog documents from category
	* Params:
	* 	count = quering size. If count = 0 then will queried all blog documents referencing 
	*			to id from newest to oldest 
	* Returns:
	* 	If count > 0 then returns blog documents from newest to oldest. 
	*	If count < 0 then returns blog documents from oldest to newest
	*/
	final Bson[] queryBlogDocuments(int count, BID catId, Proc onError = defaultErrorProc)
	{
		try
		{
			return queryBlogDocumentsImpl(count, catId);
		}
		catch(Exception ex)
		{
			onError(ex);
		}
		
		return new Bson[0];
	}
	
	protected Bson[] queryBlogDocumentsImpl(int count, BID catID);
	
	/**
	* query blog document form id
	*/
	final Bson queryBlogDocument(BID id, Proc onError = defaultErrorProc)
	{
		try
		{
			return queryBlogDocumentImpl(id);
		}
		catch(Exception ex)
		{
			onError(ex);
		}
		
		return Bson.EmptyObject;
	}
	
	protected Bson queryBlogDocumentImpl(BID id);
	
//	bool addForumThread(alias onError)(auto thread);
//	
//	bool addForumTopic(alias onError)(auto topic);
//	
//	bool addForumReply(alias onError)(auto reply);
//	
//	bool removeForumThread(T, alias onError)(T id);
//	
//	bool removeForumTopic(T, alias onError)(T id);
//	
//	bool removeForumReply(T, alias onError)(T id);
}

mixin template docsValidator()
{	
	static DocType getType(in Bson doc)
	{
		if (doc.isNull)
		{
			throw new NullDoc();
		}

		if (doc["_type"].isNull)
		{
			throw new DocsInvalidData("_types", null);
		}

		try
		{
			return cast(DocType) doc["_type"].get!int;
		}
		catch(Exception ex)
		{
			return DocType.Undefined;
		}
	}

	static bool isValidDocument(in Bson doc)
	{
		if (doc.isNull)
		{
			throw new NullDocument();
		}

		if (doc["_type"].isNull)
		{
			throw new DocsInvalidData("_type", null);
		}
		else if (getType(doc) != DocType.Document)
		{
			throw new InvalidDocType(getType(doc), DocType.Document);
		}

		if (doc["title"].isNull)
		{
			throw new DocsInvalidData("title", null);
		}

		if (doc["body"].isNull)
		{
			throw new DocsInvalidData("body", null);
		}

		if (doc["author_id"].isNull)
		{
			throw new DocsInvalidData("author_id", null);
		}

		if (doc["date"].isNull)
		{
			throw new DocsInvalidData("date", null);
		}

		return true;
	}

	static bool isValidComment(in Bson doc)
	{
		if (doc.isNull)
		{
			throw new NullComment();
		}

		if (doc["_type"].isNull)
		{
			throw new DocsInvalidData("_type", null);
		}
		else if (getType(doc) != DocType.Comment)
		{
			throw new InvalidDocType(getType(doc), DocType.Comment);
		}

		if (doc["body"].isNull)
		{
			throw new DocsInvalidData("body", null);
		}

		if (doc["author_id"].isNull)
		{
			throw new DocsInvalidData("author_id", null);
		}

		if (doc["date"].isNull)
		{
			throw new DocsInvalidData("date", null);
		}

		return true;
	}
	
	static bool isValidBlogCategory(in Bson cat)
	{
		if (cat.isNull)
		{
			throw new NullComment();
		}

		if (cat["_type"].isNull)
		{
			throw new DocsInvalidData("_type", null);
		}
		else if (getType(cat) != DocType.BlogCategory)
		{
			throw new InvalidDocType(getType(cat), DocType.BlogCategory);
		}

		if (cat["name"].isNull)
		{
			throw new DocsInvalidData("name", null);
		}

		return true;
	}
	
	static bool isValidBlogDocument(in Bson doc)
	{
		if (doc.isNull)
		{
			throw new NullDoc();
		}

		if (doc["_type"].isNull)
		{
			throw new DocsInvalidData("_type", null);
		}
		else if (getType(doc) != DocType.BlogDocument)
		{
			throw new InvalidDocType(getType(doc), DocType.BlogDocument);
		}

		if (doc["body"].isNull)
		{
			throw new DocsInvalidData("body", null);
		}

		if (doc["author_id"].isNull)
		{
			throw new DocsInvalidData("author_id", null);
		}

		if (doc["date"].isNull)
		{
			throw new DocsInvalidData("date", null);
		}
		
		if (doc["short"].isNull)
		{
			throw new DocsInvalidData("short", null);
		}

		return true;
	}
	
	
	static bool isValidDocType(in Bson doc, DocType type)
	{
		switch(type)
		{
			case DocType.Document:
				return isValidDocument(doc);
				
			case DocType.Comment:
				return isValidComment(doc);
				
			case DocType.BlogCategory:
				return isValidBlogCategory(doc);
				
			case DocType.BlogDocument:
				return isValidBlogDocument(doc);
				
			default:
				throw new InvalidDocType(type);
		}
			
	}
}


class DocsException: Exception
{
	this(T...)(string fmt, auto ref T args)
	{
		super(format(fmt, args));
	}
}


class InvalidDocType: DocsException
{
	this(DocType type, DocType expected)
	{
		super("[Docs]Expected got type %s, but got type %s", 
			to!string(expected), to!string(type));
	}
	
	this(DocType type)
	{
		super("[Docs]Invalid type %s (not support yet)", to!string(type));
	}
}

class DocDoesntExist: DocsException
{
	this(T)(T id)
	{
		super("[Docs]Document with id %s doesnt exist", id);
	}
}

class InvalidID: DocsException
{
	this(T)(T id)
	{
		super("[Docs]Invalid id %s. Type must be ubyte[12] or string", id);
	}
}

class NullDoc: DocsException
{
	this()
	{
		super("[Docs]Was got null doc");
	}
	
	this(string msg)
	{
		super(msg);
	}
}

class NullComment: NullDoc
{
	this()
	{
		super("[Docs]Was got null comment");
	}
	
}

class NullDocument: NullDoc
{
	this()
	{
		super("[Docs]Was got null document");
	}
}

class DocsInvalidData: DocsException
{
	this(T)(string field, T value)
	{
		super("[Docs]Invalid %s = %s", field, value);
	}
}

class DocsInvalidQueryCount: DocsException
{
	this(int i)
	{
		super("[Docs]Invalid query count %d", i);
	}
}