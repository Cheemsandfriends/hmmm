package;

import haxe.PosInfos;
import haxe.Json;
import sys.io.Process;
import sys.io.File;
import sys.FileSystem;
import formats.*;


class Main 
{
    public static function main()
    {
        
        var args = Sys.args();

        if (!FileSystem.exists("./made")) // copied from OG hmm lol
        {
            File.saveContent("./made", "");

            if (Sys.systemName() == "Windows") {
                
                File.saveContent(Sys.getEnv("HAXEPATH") + "/hmmm.cmd", File.getContent("./dump/hmmm.cmd"));
            } else {
                var linkPath = "/usr/local/bin/hmm";
                var realPath = FileSystem.absolutePath("./") + "dump/hmm";
                Sys.command("chmod", ["+x", realPath]);
                Sys.command("sudo", ["rm", linkPath]);
                Sys.command("sudo", ["ln", "-s", realPath, linkPath]);
            }
        }

        var hmm:HMM = {dependencies: []};

        

        var path = args[args.length - 1];

        
        args.pop();

        if (args.length == 0)
        {
            Sys.println("You need to input an hxml or a Lime formatted XML!\n Exiting...\n");
            return;
        }

        var input = "";
        var libPath = "";
        var mod = "";

        var verbose = false;
        
        for (arg in args)
        {
            if (StringTools.startsWith(arg, "-"))
            {
                switch(StringTools.replace(arg, "-", "").toLowerCase())
                {
                    case "global", "g": mod = "--global";
                    case "verbose", "v": verbose = true;
                }
            }
            else 
                input = arg;
        }

        haxe.Log.trace = function (v:Dynamic, ?infos:Null<PosInfos>)
        {
            if (verbose)
            {
                Sys.println( " \x1B[7m \x1B[34m HMMM: \x1B[0m " + v);
            }
        };

        libPath = new Process("haxelib "+ mod +" config").stdout.readLine();

        if (FileSystem.exists(path + input))
        {
            var parser:FileParser = null;
            switch (haxe.io.Path.extension(input))
            {
                case "hxml":
                    parser = new HXML(path + input);
                case "xml":
                    parser = new LimeParser(path + input);
            }

            var libs = parser.libs;

            var list = new Process("haxelib "+ mod +" list").stdout.readAll().toString().split("\n");
            list.pop();

            

            list = list.filter(f -> libs.indexOf(f.split(":")[0]) != -1);

            libs = [];


            for (i in 0...list.length)
            {

                libs.push(list[i].split(":")[0]);
                list[i] = StringTools.trim(list[i].split("[")[1].split("]")[0]);
            }


            for (i in 0...libs.length)
            {
                var lib = libs[i];
                var curLib = (parser.libsVersion[i] == null) ? list[i] : parser.libsVersion[i];
                var file:Dynamic = null;
                var st = libPath + lib + "/" + curLib;

                if (verbose)
                {
                    Sys.print( " \x1B[7m \x1B[34m HMMM: \x1B[0m Configuring " + lib + "...");
                }

                if (FileSystem.exists(st))
                    file = Json.parse(File.getContent(st + "/haxelib.json"));


                if (verbose)
                {
                    
                    Sys.print(" \x1B[4m\x1B[91mVERSION:\x1B[0m " + curLib);

                }
                
                switch (curLib.split(":")[0])
                {
                    case "git", "hg":
                        var commit = new Process(curLib + ' -C "$st" log -1 --format=%H').stdout.readAll().toString().split("\n")[0];
                        var fetch = "http" + StringTools.trim(new Process(curLib + ' -C "$st" remote -v').stdout.readAll().toString().split("http")[1].split("(")[0]);

                        hmm.dependencies.push({
                            name: lib,
                            type: curLib,
                            ref: commit,
                            url: fetch,
                            dir: (file != null) ? file.classPath : null
                        });
                    case "dev":
                        var result = 2;

                        Sys.print("\n");

                        function check(message:String)
                        {
                            Sys.println(" \x1B[7m \x1B[93m WARN: \x1B[0m " + message);

                        
                            var ch = String.fromCharCode(Sys.getChar(false)).toLowerCase();

                            
                            return switch (ch)
                            {
                                case "y": 1;
                                case "n": 0;
                                case _: 2;
                            }
                        }

                        while (result == 2)
                        {
                            result = check("Warning! "+ lib + " is set as a development branch! do you want to continue or replace it with a publicly available version? [Y/N]");
                        }
                        
                        var __p = curLib.split(":");
                        __p.shift();
                        var path = __p.join(":");
                        
                        if (result == 1)
                        {
                            hmm.dependencies.push({
                                name: lib,
                                type: "dev",
                                path: path,
                            });
                        }
                        else 
                        {

                            var isGit = false;
                            var isHaxeLib = file != null;

                            try {
                                new Process('git -C "$path" status').stderr.readByte();
                                
                            }
                            catch (e)
                            {
                                isGit = true;
                            }


                            isHaxeLib = FileSystem.exists(path + "haxelib.json");


                            if (isGit && isHaxeLib)
                            {
                                result = 2;
    
                                while (result == 2)
                                {
                                    result = check("Warning! the library seems to have both git and haxelib in your library! do you want to add Git to your hmm file? [Y/N]");
                                }

                                if (result == 1)
                                    isHaxeLib = false;
                                else 
                                    isGit = false;
                            }

                            if (isGit)
                            {
                                var commit = new Process('git -C "$path" log -1 --format=%H').stdout.readAll().toString().split("\n")[0];
                                var fetch = "http" + StringTools.trim(new Process('git -C "$path" remote -v').stdout.readAll().toString().split("http")[1].split("(")[0]);

                                trace(fetch);
                                hmm.dependencies.push({
                                    name: lib,
                                    type: "git",
                                    ref: commit,
                                    url: fetch,
                                    dir: (file != null) ? file.classPath : null
                                });
                            }
                            
                            if (isHaxeLib)
                            {
                                var file = Json.parse(File.getContent(path + "haxelib.json"));
                                hmm.dependencies.push({
                                    name: lib,
                                    type: "haxelib",
                                    version: file.version,
                                    dir: (file != null) ? file.classPath : null
                                });
                            }
                        }

                    case _: 
                        hmm.dependencies.push({
                            name: lib,
                            type: "haxelib",
                            version: curLib,
                            dir: (file != null) ? file.classPath : null
                        });
                }


                if (verbose)
                {
                    
                    Sys.print("\n");

                }
            }

            File.saveContent(path + "hmm.json", Json.stringify(hmm, "\t"));
        }
    }
}

typedef HMM = {
    var dependencies:Array<HMMDependency>;
} 

typedef HMMDependency = {
    var name:String;
    var type:String;
    var ?dir:String;
    var ?ref:String;
    var ?version:String;
    var ?path:String;
    var ?url:String;
} 