module frontend.docs;

import vibe.d;

import backend.iusers;
import frontend.users;

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
		static if (is(typeof(ret.date):SysTime))
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
	void fillAuthorInfo(IUsersProvider usersProvider)
	{
		author = User.fromID(this.author.id, usersProvider);
	}
	
	mixin util.dateconv;
}

package struct Document
{
	string title;
	
	string id;
	
	string bodystr;
	
	User author;
	
	SysTime date;

	mixin doc!Document;

}

package struct Comment
{	
	string id;
	
	string ref_id;
	
	string bodystr;
	
	User author;
	
	SysTime date;

	mixin doc!Comment;
}

package struct BlogDocument
{	
	string id;
	
	string bodystr;
	
	string shortstr;
	
	string title;
	
	User author;
	
	SysTime date;

	mixin doc!BlogDocument;
}