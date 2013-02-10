#!/usr/bin/rdmd
/// Скрипт автоматической компиляции проекта под Linux и Windows
/** 
 * Очень важно установить пути к зависимостям (смотри дальше), 
 */
module compile;

import dmake;

import std.stdio;
import std.process;

// Здесь прописать пути к зависимостям
string[string] depends;

// Список либ
string[] deimosLibs;

version(X86)
	enum MODEL = "32";
version(X86_64)
	enum MODEL = "64";
	
static this()
{
	version(Windows)
	{
		depends =
		[
			"Deimos": "../dependencies/deimos/",
		];
		
		deimosLibs =
		[
			"eay",
			"event2",
			"ssl",
		];
	}

}

//======================================================================
//							Основная часть
//======================================================================
int main(string[] args)
{

	addCompTarget("ddust", "../bin", "ddust", BUILD.APP);
	
	setDependPaths(depends);
	
	addLibraryFiles("Deimos", "lib", deimosLibs, ["import"], 
	(string libPath)
	{
		//writeln("Building Derelict3 lib...");
		//system("cd "~libPath~`/build && rdmd build.d`);
	});

	addSource("../src/vibe");
	addSource("../src/ddust");

	addCustomFlags("-D -Dd../docs ../docs/candydoc/candy.ddoc ../docs/candydoc/modules.ddoc -version=CL_VERSION_1_1 wsock32.lib");

	checkProgram("dmd", "Cannot find dmd to compile project! You can get it from http://dlang.org/download.html");
	// Компиляция!
	return proceedCmd(args);
}