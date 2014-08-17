module frontend.blog;


mixin template blog()
{	
	import std.regex;
	import std.functional;
	import vibe.d;
	import frontend.permission;
	import frontend.docs;
	import frontend.users;
	import backend.idocs;
	import backend.iusers;
	
	@GA(USER_ROLE.init, "/blog")
	void blog(HTTPServerRequest req, HTTPServerResponse res)
	{
		
		BlogDocument[] docs = new BlogDocument[0];
		
		foreach(each; docsProvider.queryBlogDocuments(-10))
		{
			BlogDocument doc = fromBson!BlogDocument(each);
			std.stdio.writeln(each);
			std.stdio.writeln(doc);
			doc.fillAuthorInfo(doc.author_id, usersProvider);
			
			docs ~= doc;
		}
		
		res.renderCompat!("ddust.blog.dt", HTTPServerRequest, "req", BlogDocument[], "docs")(req, docs);
	}
	
	@GA(USER_ROLE.init, "/blog/entry/*")
	void blogSingle(HTTPServerRequest req, HTTPServerResponse res)
	{		
		string path = req.fullURL().toString();
		
		auto m = split(path, r"/blog/entry/");
		
		if (m.length < 2)
		{
			res.redirect("/blog", HTTPStatus.Forbidden);
			return;
		}
		
		if (m[1].length == 0)
		{
			return res.redirect("/blog");
		}
		else if (m[1].length != 24)
		{
			res.statusCode = HTTPStatus.NotFound;
			
			return;
		}
		
		
		auto id = BsonObjectID.fromString(m[1]);
		
		bool error = false;
		void onError(Exception ex)
		{
			if (cast(DocDoesntExist) ex)
			{
				res.statusCode = HTTPStatus.NotFound;
			}
			else throw ex;
			error = true;
		}
		
		Bson bdoc = docsProvider.queryBlogDocument(id, &onError);
		
		if (error) return;
		
		BlogDocument doc = fromBson!BlogDocument(bdoc);
		
		doc.fillAuthorInfo(doc.author.id, usersProvider);
		
		Comment[] coms = new Comment[0];
		
		foreach(each; docsProvider.queryComments(BsonObjectID.fromString(m[1]), 10))
		{
			Comment com = fromBson!Comment(each);
			com.fillAuthorInfo(com.author.id, usersProvider);
			
			coms ~= com;
		}
		
		res.renderCompat!("ddust.blog.single.dt", HTTPServerRequest, "req", BlogDocument, "doc", Comment[],"coms")
			(req, doc, coms);
				
	}
	
	@GA(USER_ROLE.USER, "/blog/add/entry")
	void addBlogEntry(HTTPServerRequest req, HTTPServerResponse res)
	{
		mixin(t_session);
		
		string login;
		if (isOnline(login))
		{ 
			res.renderCompat!("ddust.blog.add.dt", HTTPServerRequest, "req", BlogEntry, "entry", MSG, "message")(
				req, BlogEntry(), MSG());
		}
	}
	
	struct BlogEntry
	{
		string title;
		string bodystr;
		string shortstr;
		
		BlogDocument toBlogDocument()
		{
			BlogDocument doc;
			
			doc.title = title;
			
			doc.bodystr = bodystr;
			
			doc.shortstr = shortstr;
			
			doc.date = Clock.currStdTime;
			
			return doc;
		}
		
		mixin docValidator!BlogEntry;
	}
	
	@GA(USER_ROLE.USER, "/blog/add/entry")
	void postAddBlogEntry(HTTPServerRequest req, HTTPServerResponse res)
	{
		mixin(t_session);
		
		string login;
		if (!isOnline(login))
		{ 
			return;
		}
		
		BlogEntry entry;
		
		loadFormData(req, entry, "entry");
		
		string reason;
		
		void onError(Exception ex)
		{
			reason = ex.msg;
		}
		
		if (!entry.isValid(reason))
		{
			res.renderCompat!("ddust.blog.add.dt", HTTPServerRequest, "req", BlogEntry, "entry", MSG, "message")(
				req, entry, MSG(true,reason));
		}
		else 
		{
			BlogDocument doc = entry.toBlogDocument();
		
			doc.fillAuthorInfoFromLogin(login, usersProvider);
			
			if(docsProvider.addBlogDocument(toBson(doc), &onError))
			{
				res.redirect("/blog");
			}
			else
			{
				res.renderCompat!("ddust.blog.add.dt", HTTPServerRequest, "req", BlogEntry, "entry", MSG, "message")(
					req, entry, MSG(true, reason));
			
			}
		}
	}
}