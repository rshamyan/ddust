module frontend.blog;


mixin template blog()
{	
	import std.regex;
	import std.functional;
	import vibe.d;
	import frontend.docs;
	import frontend.users;
	import backend.idocs;
	
	
	void setupBlog()
	{
		router.get("/blog", &blog);
		router.get("/blog/entry/*", &blogSingle);
		router.get("/blog/add/entry", &addBlogEntry);
		router.post("/blog/add/entry", &postAddBlogEntry);
	}
	
	void blog(HTTPServerRequest req, HTTPServerResponse res)
	{
		
		BlogDocument[] docs = new BlogDocument[0];
		
		foreach(each; docsProvider.queryBlogDocuments(-10))
		{
			BlogDocument doc = BlogDocument.fromBson(each);
			doc.fillAuthorInfo(doc.author.id, usersProvider);
			
			docs ~= doc;
		}
		
		res.renderCompat!("ddust.blog.dt", HTTPServerRequest, "req", BlogDocument[], "docs")(req, docs);
	}
	
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
		
		BlogDocument doc = BlogDocument.fromBson(bdoc);
		
		doc.fillAuthorInfo(doc.author.id, usersProvider);
		
		Comment[] coms = new Comment[0];
		
		foreach(each; docsProvider.queryComments(BsonObjectID.fromString(m[1]), 10))
		{
			Comment com = Comment.fromBson(each);
			com.fillAuthorInfo(com.author.id, usersProvider);
			
			coms ~= com;
		}
		
		res.renderCompat!("ddust.blog.single.dt", HTTPServerRequest, "req", BlogDocument, "doc", Comment[],"coms")
			(req, doc, coms);
				
	}
	
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
			
			doc.date = Clock.currTime();
			
			return doc;
		}
		
		mixin doc!BlogEntry;
	}
	
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
			
			if(docsProvider.addBlogDocument(doc.toBson(doc), &onError))
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