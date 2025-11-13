package formats;

import sys.io.File;

class HXML extends FileParser 
{
    override function parse(path:String) 
    {   
        var file = File.getContent(path);

        var hArgs = file.split("\n");

        
        for (arg in hArgs) 
        {
            if (StringTools.trim(arg).length == 0)
                continue;


            var commands = arg.split(" ");
            commands[1] = StringTools.replace(commands[1], ".", ",");

            if (StringTools.trim(commands[0]) != "-lib" && StringTools.trim(commands[0]) != "--library")
                continue;
            var name = commands[1].split(":");
            libs.push(StringTools.trim(name[0]));

            if (name.length > 1)
            {
                libsVersion.push(StringTools.trim(name[1]));
            }           
        }    
    }
}