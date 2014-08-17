module frontend.docs;

import vibe.d;

import backend.iusers;
import frontend.users;
import backend.idocs:DocType;

import util;

package enum DOC_DATA_STATUS:string
{
	NO_TITLE="Title is empty",
	
	NO_BODY = "Body is empty",
	
	NO_SHORT = "Short body is empty",
	
	BAD_DATE = "Date is bad",
	
	NO_REFERENCE = "Reference is empty",
	
	OK = "OK"
}

package mixin template docValidator(T)
{
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
}

package mixin template doc(T)
{	
	import util;
	
	ignore
	
	BID _id;
	
	BID author_id;
	
	@ignore()
	User author;
	
	BsonDate _date;
	
	string id() @property
	{
		return _id.toString();
	}
	
	void id(string str) @property
	{
		_id = BID.fromString(str);
	}
	
	SysTime date() @property
	{
		return _date.toSysTime;
	}
	
	void date(long time) @property
	{
		_date = BsonDate.fromStdTime(time);
	}

	
	void fillAuthorInfo(string id, IUsersProvider usersProvider)
	{
		author = author.fromID(id, usersProvider);
		author_id = author._id;
	}

	void fillAuthorInfo(BID id, IUsersProvider usersProvider)
	{
		author = author.fromID(id, usersProvider);
		author_id = author._id;
	}
	

	void fillAuthorInfoFromLogin(string login,IUsersProvider usersProvider)
	{
		author = author.fromLogin(login, usersProvider);
		author_id = author._id;
	}
	
	
	mixin util.dateconv;
}

package struct Document
{	

	static immutable DocType _type = DocType.Document;
	
	string title;
	
	string bodystr;

	mixin doc!Document;
	
	mixin docValidator!Document;

}

package struct Comment
{	

	static immutable DocType _type = DocType.Comment;
	
	BID _ref;
		
	string ref_id() @property
	{
		return _ref.toString();
	}
	
	void ref_id(string str) @property
	{
		_ref = BID.fromString(str);
	}
	
	string bodystr;

	mixin doc!Comment;

	mixin docValidator!Comment;
}

package struct BlogDocument
{	
	static DocType _type = DocType.BlogDocument;
	
	string bodystr;
	
	string shortstr;
	
	string title;

	mixin doc!BlogDocument;
	
	mixin docValidator!BlogDocument;
}