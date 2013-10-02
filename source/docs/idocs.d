module docs.idocs;

import std.conv;
import std.string;

import vibe.d;

enum DocType
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
	bool addDocument(alias onError)(in auto doc);
	
	bool removeDocument(T, alias onError)(T id);
	
	bool addComment(T, alias onError)(T docId, in auto comment);
	
	bool removeComment(T, alias onError)(T id);
	
	auto queryDocument(alias onError)(T id);
	
	auto queryComment(alias onError)(T id);
}

mixin template docsValidator()
{	
	bool isValidDocument(T)(in T doc)
	{
		if (doc.isNull)
		{
			throw new NullDocument();
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
		
		if (doc["doc_id"].isNull)
		{
			throw new DocsInvalidData("doc_id", null);
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
		super("[Docs]Was Got null doc");
	}
}

class NullComment: NullDoc
{
	
}

class NullDocument: NullDoc
{
	
}

class DocsInvalidData: DocsException
{
	this(T)(string field, T value)
	{
		super("[Docs]Invalid %s = %s", field, value);
	}
}