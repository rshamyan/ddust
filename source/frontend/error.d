module frontend.error;

mixin template errorPage()
{
	import vibe.d;
	
	void error(HTTPServerRequest req, HTTPServerResponse res, HTTPServerErrorInfo error)
	{
		res.renderCompat!("ddust.error.dt", HTTPServerRequest, "req", HTTPServerErrorInfo,"error")(req, error);
	}
	
	void setupErrorPage()
	{
		settings.errorPageHandler = toDelegate(&error);
	}
}