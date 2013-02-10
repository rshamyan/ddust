module ddust.main;

import vibe.vibe;

int main()
{
	auto f = openFile("test.html", FileMode.CreateTrunc);
	f.write(download("http://google.com/"));
	return 0;
}