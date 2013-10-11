module frontend.blog;


mixin template blog()
{	
	import std.regex;
	import vibe.d;
	import docs.idocs;
	import docs.docs;
	import frontend.docs;
	
	void setupBlog()
	{
		router.get("/blog", &blog);
		router.get("/blog/*", &blogSingle);
	}
	
	void blog(HTTPServerRequest req, HTTPServerResponse res)
	{
		
		BlogDocument[] docs = new BlogDocument[0];
		
		foreach(each; docsProvider.queryBlogDocuments(10))
		{
			BlogDocument doc = BlogDocument.fromBson(each);
			doc.fillAuthorInfo(usersProvider);
			
			docs ~= doc;
		}
		
		res.renderCompat!("ddust.blog.dt", HTTPServerRequest, "req", BlogDocument[], "docs")(req, docs);
	}
	
	void blogSingle(HTTPServerRequest req, HTTPServerResponse res)
	{		
		string path = req.fullURL().toString();
		
		auto m = split(path, r"/blog/");
		
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
		Bson bdoc = docsProvider.queryBlogDocument(id);
		BlogDocument doc = BlogDocument.fromBson(bdoc);
		doc.fillAuthorInfo(usersProvider);
		
		Comment[] coms = new Comment[0];
		
		foreach(each; docsProvider.queryComments(BsonObjectID.fromString(m[1]), 10))
		{
			logInfo("2");
			Comment com = Comment.fromBson(each);
			com.fillAuthorInfo(usersProvider);
			
			coms ~= com;
		}
		
		res.renderCompat!("ddust.blog.single.dt", HTTPServerRequest, "req", BlogDocument, "doc", Comment[],"coms")
			(req, doc, coms);
		
		
	}
}