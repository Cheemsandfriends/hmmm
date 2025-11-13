package formats;

import sys.io.File;

class LimeParser extends FileParser 
{
    override function parse(path:String) // TODO: parse Project.xml files that require other Project.xml files.
    {
        var file = File.getContent(path);


        var xml = Xml.parse(file);
        var haxelibs = xml.firstElement().elementsNamed("haxelib");

        for (lib in haxelibs)
        {
            if (lib.exists("name"))
            {
                libs.push(lib.get("name"));
            }
            if (lib.exists("version"))
            {
                libsVersion.push(lib.get("version"));
            }
        }
    }
}