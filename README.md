# Detect Cycles: A source-code dependency cycle checker.

## Summary

This program dives through your source code in order to determine what modules exist
and what the dependencies are between them. If dependency cycles are found, they are
printed to the output.

Programming language support is configurable using basic data in a JSON configuration file.

By default, the following languages are supported:  C++, D, Java

## Installation

A [D Programming Language](https://dlang.org/download.html) compiler is needed to build the
project. Once that is installed, and the source code can be downloaded and built.

First download the source.

```shell
$ git clone https://github.com/vnayar/detectcycles.git
$ cd detectcycles
```

Run the tests.
```shell
$ dub test
```

Build the program.
```shell
$ dub --build=release
```

That's it, your shiny new program will be there as "detectcycles", which you can copy into
`/usr/local/bin` or any other desired location.

## Usage

With no arguments, `detectcycles` will crawl through the current directory and find all
source code of supported types.

```shell
$ detectcycles
The following cycles were detected:
Cycle #0
s2.s2region => s2.s2cell => s2.s2cap => s2.s2latlng_rect
```

Other usage options can be viewed with the `--help` command line option:

```shell
$ detectcycles -h

detectcycles: The source code dependency cycle detector.
Usage: detectcycles [options] [srcDir1] [srcDir2] ...
-c        --config Specify a custom language-support configuration file to use.
-d         --debug Enable debug logging.
-g      --generate Generates default configurations to modify and use with -c.
-l      --language Limit scanning to only a specific language.
-s --showLanguages Show the supported languages.
-h          --help This help information.
```

## Language Support

By default, `detectcycles` will use it's built-in language support configuration, which has
basic suport for C++, D, and Java. C++ is a bit tricky due to the existance of forward
declarations and dependencies being introduced without clear declaration.

A configuration file may be provided to `detectcycles` in order to add rules for determining
the module name from a source file and its file name, and for reading uses/depends relations
from the source.

The default configuration may be produced as a starting point with the command:
```shell
$ detectcycles --generate
```

If your save your configuration file in "detectcycles.json", you can use it with the program
like so:
```shell
$ detectcycles --config detectcycles.json
```

The format of the config file is as follows:
```
[
  {
    # The name of the language when chosen with the "--language" option.
    "language": "Java",

    # The filter used to detect files for this language.
    # For format, see: https://dlang.org/phobos/std_path.html#globMatch
    "fileGlob": "*.java",

    # A regular expression to capture the part of the file name used to build the module name.
    # The last matching group '()' will be saved as $fileModule.
    "fileModuleRegex": "(.+[/\\\\])?([^/\\\\]+).java",

    # A regular expression matching statements of source code used to build a module name.
    # The last matching group '()' will be saved as $sourceModule.
    "sourceModuleRegex": "^package (.+);",

    # A string name of the module.
    # The variables $sourceModule and $fileModule will be substituted.
    "moduleName": "$sourceModule.$fileModule",

    # A regular expression to detect a 'uses' or 'depends' relationship.
    # THe last matching group '()' will be the name of module that is used.
    "usesRegex": "^import ([^;]+);",

    # A delimitor for a uses statement in the language being used.
    # Note: In C++, '#include' statements are used for dependencies, so '\n' is the delimitor.
    "statementDelimitorRegex": "[;]"
  },
  {
    "language": "D",
    "fileGlob": "*.{d,di}",
    "fileModuleRegex": "",
    "sourceModuleRegex": "module (.+);",
    "moduleName": "$sourceModule",
    "usesRegex": "import ([.a-zA-Z0-9_]+).*;",
    "statementDelimitorRegex": "[;]"
  },
  ...
]
```
