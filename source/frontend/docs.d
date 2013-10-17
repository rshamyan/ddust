module frontend.docs;

import vibe.d;

import backend.iusers;
import frontend.users;
import backend.idocs:DocType;

package enum DOC_DATA_STATUS:string
{
	NO_TITLE="Title is empty",
	
	NO_BODY = "Body is empty",
	
	NO_SHORT = "Short body is empty",
	
	BAD_DATE = "Date is bad",
	
	NO_REFERENCE = "Reference is empty",
	
	OK = "OK"
}

package mixin template doc(T)
{	
	static T fromBson(in Bson doc)
	{
		T ret;
		
		static if (is(typeof(ret.title):string))
		{
			ret.title = doc["title"].get!string;
		}
		static if (is(typeof(ret.id):string)) 
		{
			BsonObjectID id = doc["_id"].get!BsonObjectID;
			
			ret.id = id.toString();
		}
		static if (is(typeof(ret.author):User))
		{
			BsonObjectID author_id = doc["author_id"].get!BsonObjectID;
			
			ret.author.id = author_id.toString();
		}
		static if (is(typeof(ret.date)))
		{
			BsonDate date = doc["date"].get!BsonDate;
			
			ret.date = date.toSysTime();
		}
		static if (is(typeof(ret.bodystr):string))
		{
			ret.bodystr = doc["body"].get!string;
		}
		static if (is(typeof(ret.shortstr):string))
		{
			ret.shortstr = doc["short"].get!string;
		}
		static if (is(typeof(ret.ref_id):string))
		{
			BsonObjectID ref_id = doc["_ref"].get!BsonObjectID;
			
			ret.ref_id = ref_id.toString();
		}
		
		
		return ret;
	}
	
	static if (is(typeof(author): User))
	void fillAuthorInfo(string id, IUsersProvider usersProvider)
	{
		author = User.fromID(id, usersProvider);
	}
	
	static if (is(typeof(author): User))
	void fillAuthorInfoFromLogin(string login,IUsersProvider usersProvider)
	{
		author = User.fromLogin(login, usersProvider);
	}
	
	Bson toBson(in T doc)
	{
		Bson bson = Bson.EmptyObject;
		static if (is(typeof(doc.title):string))
		{
			bson["title"] = Bson(doc.title);
		}
		static if (is(typeof(doc.author):User))
		{
			bson["author_id"] = Bson(BsonObjectID.fromString(doc.author.id));
		}
		static if (is(typeof(doc.date)))
		{
			bson["date"] = Bson(BsonDate(doc.date));
		}
		static if (is(typeof(doc.bodystr):string))
		{
			bson["body"] = Bson(doc.bodystr);
		}
		static if (is(typeof(doc.shortstr):string))
		{
			bson["short"] = Bson(doc.shortstr);
		}
		static if (is(typeof(doc.ref_id):string))
		{
			bson["_ref"] = Bson(BsonObjectID.fromString(doc.ref_id));
		}
		static if (is(typeof(doc._type):DocType))
		{
			bson["_type"] = Bson(cast(int)doc._type);
		}
		
		return bson;
	}
	
	DOC_DATA_STATUS status() @property
	{
		import std.array;
		static if (is(typeof(doc.title):string))
		{
			if (doc.title.empty)
			{
				return DOC_DATA_STATUS.NO_TITLE;
			}
		}
		static if (is(typeof(doc.date)))
		{
			if (Clock.currTime < doc.date)
			{
				return DOC_DATA_STATUS.BAD_DATE;
			}
		}
		static if (is(typeof(doc.bodystr):string))
		{
			if (doc.bodystr.empty)
			{
				return DOC_DATA_STATUS.NO_BODY;
			}
		}
		static if (is(typeof(doc.shortstr):string))
		{
			if (doc.shortstr.empty)
			{
				return DOC_DATA_STATUS.NO_SHORT;
			}
		}
		static if (is(typeof(doc.ref_id):string))
		{
			if (doc.ref_id.empty)
			{
				return DOC_DATA_STATUS.NO_REFERENCE;
			}
		}
		
		return DOC_DATA_STATUS.OK;
	}
	
	bool isValid(out string reason)
	{
		if (status != DOC_DATA_STATUS.OK)
		{
			reason = status;
			return false;
		}
		
		return true;
	}
	
	
	mixin util.dateconv;
}

package struct Document
{
	string title;
	
	string id;
	
	static final DocType _type = DocType.Document;
	
	string bodystr;
	
	User author;
	
	SysTime date;

	mixin doc!Document;

}

package struct Comment
{	
	string id;
		
	string ref_id;
	
	static final DocType _type = DocType.Comment;
	
	string bodystr;
	
	User author;
	
	SysTime date;

	mixin doc!Comment;
}

package struct BlogDocument
{		
	string id;
	
	static final DocType _type = DocType.BlogDocument;
	
	string bodystr;
	
	string shortstr;
	
	string title;
	
	User author;
	
	SysTime date;

	mixin doc!BlogDocument;
}