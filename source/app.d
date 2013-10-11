import std.stdio;

import vibe.d;

import backend.mongo.docs;
import backend.mongo.users;
import backend.idocs;
import backend.iusers;
import frontend.frontend;

void main2(string[] args)
{
	std.stdio.writeln("Init server");
	init();
	
	MongoUsersProvider usersProvider = new MongoUsersProvider("127.0.1.1");

	//std.stdio.writeln(usersProvider.queryAuthorization!bar("1redeye","123456"));
	
	Bson bson = Bson([
		"username": Bson("My Name Is Rest"),
		"somedate": Bson(BsonDate(Clock.currTime())) 
		]);
	
	//usersProvider.registerUser!bar("rest", "123456");
	
	//usersProvider.updateProfile!bar("rest", bson);
	
	MongoDocsProvider docProvider = new MongoDocsProvider("127.0.0.1");
	
	Bson doc = Bson([
		"title": Bson("Is universe alive?"),
		"body": Bson("I guess yes!..."),
		"author_id": Bson(usersProvider.queryID("redeye")),
		"date": Bson(BsonDate(Clock.currTime())),
		"_type": Bson(cast(int)DocType.Document)
	]);
	
	auto doc2 = docProvider.queryDocuments()[0]; 
	Bson comment = Bson([
		//"doc_id": Bson(doc2["_id"].get!BsonObjectID),
		"body":Bson("+1 Evidently yes"),
		"author_id": Bson(usersProvider.queryID("asd")),
		"date": Bson(BsonDate(Clock.currTime())),
		"_type":Bson(cast(int) DocType.Comment)		
	]);
	
	docProvider.addComment(doc2["_id"].get!BsonObjectID, comment);
	
	Bson comment2 = Bson([
		//"doc_id": Bson(doc2["_id"].get!BsonObjectID),
		"body":Bson(";)"),
		"author_id": Bson(usersProvider.queryID("redeye")),
		"date": Bson(BsonDate(Clock.currTime())),
		"_type":Bson(cast(int) DocType.Comment)		
	]);
	
	auto doc3 = docProvider.queryComments(doc2["_id"].get!BsonObjectID)[$ - 1];
	
	docProvider.addComment(doc3["_id"].get!BsonObjectID, comment2);
	
	//writeln(usersProvider.queryUserInfo("rest").toJson); 
	
	
	
	//writeln(doc.type);
	
	//writeln(doc["title"].get!string);
	
	//docProvider.addDocument(doc);
	
//	foreach(Bson each; docProvider.queryDocuments()) 
//		writeln(each.toJson);
	
	
	foreach(each; docProvider.queryDocuments)
	{
		writeln(each["title"].get!string);
		foreach(each2; docProvider.queryComments(each["_id"].get!BsonObjectID))
		{
			writeln("\t"~each2["body"].get!string);
			foreach(each3; docProvider.queryComments(each2["_id"].get!BsonObjectID))
			{
				writeln("\t\t"~each3["body"].get!string);
			}
		}
	}
		
	std.stdio.writeln("Finished");
}

void main(string[] args)
{
	new FrontEnd();
	
	runEventLoop();
}

void bar(Exception ex)
{
	writeln(ex.msg);
}

private URLRouter setupRouter()
{
	return new URLRouter;
}

private HTTPServerSettings setupSettings()
{
	auto settings = new HTTPServerSettings;
	settings.sessionStore = new MemorySessionStore;
	settings.bindAddresses = ["127.0.0.1"];
	settings.port = 80;
	return settings;
}

private void init()
{
	listenHTTP(setupSettings(), setupRouter()); 
}