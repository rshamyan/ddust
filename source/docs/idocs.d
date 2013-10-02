module docs.idocs;

import std.conv;
import std.string;

import vibe.d;

enum DocType: int
{
	Undefined = 0x00,
	
	Document = 0x01,
	
	News = 0x02,
	
	Comment = 0x03,
	
	BlogDocument = 0x04,
	
	BlogComment = 0x05,
	
	ForumDocument = 0x06,
	
	ForumComment = 0x07
}

interface IDocs
{
	/**
	* add Document
	*/
	bool addDocument(alias onError)(in auto doc);
	
	/**
	* remove Document
	*/
	bool removeDocument(T, alias onError)(T id);
	
	/**
	* add Comment to id
	*/
	bool addComment(T, alias onError)(T docId, in auto comment);
	
	/**
	* remove Comment
	*/
	bool removeComment(T, alias onError)(T id);
	
	/**
	* query document with id
	* Params:
	*	id = document id
	*/
	auto queryDocument(alias onError)(T id);
	
	/**
	* query Comment with id
	* Params:
	*	id = comment id
	*/
	auto queryComment(alias onError)(T id);
	
	/**
	* query documents
	* Params:
	* 	count = max size of array. if count = 0 then will queried all Documents
	* Returns:
	* 	array of documents from newest to oldest
	*/
	auto queryDocuments(alias onError)(int count);
	
	/**
	* query comments to id
	* Params:
	* 	id = comments $(D _ref) id
	* 	count = max size of array. if count = 0 then will queried all Comments referencing to id
	* Returns:
	* 	array of comments from oldest to newest
	*/
	auto queryComments(T, alias onError)(T id, int count);
}

mixin template docsValidator()
{	
	
	DocType getType(T)(in T doc)
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
	
	bool isValidDocument(T)(in T doc)
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
	
	bool isValidComment(T)(in T doc)
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
	
	bool isValidDocType(T)(in T doc, DocType type)
	{
		switch(type)
		{
			case DocType.Document:
				return isValidDocument(doc);
				
			case DocType.Comment:
				return isValidComment(doc);
				
			default:
				throw new InvalidDocType(type);
		}
			
	}
}

abstract class DocsProvider
{
	
	mixin docsValidator;
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