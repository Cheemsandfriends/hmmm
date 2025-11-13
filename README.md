# HMMM (HMM Maker)

HMMM is a automated `hmm.json` file generator, based completely on your haxelib libraries and your build sheet

## Usage

should be as simple as running the program! The first time you will have to run the following command
```
haxelib run hmmm
```

After this, you can just type `hmmm` and it works!

Warning! every argument should go *before* the file. Right now there are two possible arguments:

* --v or --verbose: traces the stuff
* --g or --global: explicitly fetches from your global haxelib libraries list

![image](./dump/image.png)