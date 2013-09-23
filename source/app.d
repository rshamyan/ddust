import vibe.d;

void main(string[] args)
{
	std.stdio.writeln("Init server");
	init();
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