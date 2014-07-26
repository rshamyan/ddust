module frontend.frontend;

import vibe.d;

import backend.idocs;
import backend.iusers;
import backend.mongo.docs;
import backend.mongo.users;

import frontend.blog;
import frontend.error;
import frontend.users;
import frontend.permission;


class FrontEnd
{	
	private IDocsProvider docsProvider;

	private IUsersProvider usersProvider;
	
	private URLRouter router;
	
	private HTTPServerSettings settings;
	
	private void setupRouter()
	{
		router = new URLRouter;
		
		router.get("*", serveStaticFiles("./public/"));
	}
	
	private void setupSettings()
	{
		settings = new HTTPServerSettings;
		settings.sessionStore = new MemorySessionStore;
		settings.bindAddresses = ["127.0.0.1","192.168.1.100"];
		settings.port = 80;
	}
	
	private void init()
	{
		setupRouter();
		
		setupSettings();
		
		setupModules();
		
		listenHTTP(settings, router);
	}
	
	mixin t_permission!FrontEnd;
	mixin blog;
	mixin errorPage;
	mixin usersPages;
	private void setupModules()
	{
		setupErrorPage();
		setupModulesWithAccess();
	}
	
	this()
	{
		docsProvider = new MongoDocsProvider("127.0.0.1");
		usersProvider = new MongoUsersProvider("127.0.0.1");
		
		init();
	}

}

