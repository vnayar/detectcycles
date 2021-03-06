module detectcycles.extractor_test;

import unit_threaded;
import detectcycles.extractor;
import detectcycles.config;

Config[] initConfigs() {
  Config javaConfig = new Config();
  with (javaConfig) {
    language = "Java";
    fileGlob = "*.java";
    fileModuleRegex = "(.+[/\\\\])?([^/\\\\]+).java";
    sourceModuleRegex = "package (.+);";
    moduleName = "$sourceModule.$fileModule";
    usesRegexes = [
        "import ([^;]+);",
        "@Autowired[ \\t\\n]+(private|public)[ \\t\\n]+([_0-9a-zA-Z]+)"
    ];
    statementDelimitorRegex = "[;]";
  }

  Config dConfig = new Config();
  with (dConfig) {
    language = "D";
    fileGlob = "*.{d,di}";
    fileModuleRegex = "";
    sourceModuleRegex = "module (.+);";
    moduleName = "$sourceModule";
    usesRegexes = ["import ([^;]+);"];
    statementDelimitorRegex = "[;]";
  }

  return [javaConfig, dConfig];
}

string getFileSource() {
  return q"EOS
package cat.dog.fish;

import a.b.c;
import d.e.f;

class Ham {
  @Autowired
  private FishDog fishDog;

  static void main() {
    System.out.println("hello world");
  }
}
EOS";
}

@("extractModuleName")
unittest {
  Config[] configs = initConfigs();
  auto extractor = new Extractor();

  string fileSource = getFileSource();

  (extractor.extractModuleName(configs[0], "/a/b/c/Ham.java", fileSource))
      .shouldEqual("cat.dog.fish.Ham");
  (extractor.extractModuleName(configs[0], "../a/b/c/Ham.java", fileSource))
      .shouldEqual("cat.dog.fish.Ham");
  (extractor.extractModuleName(configs[0], "a/b/c/Ham.java", fileSource))
      .shouldEqual("cat.dog.fish.Ham");
}

@("extractUsedModuleNames")
unittest {
  Config[] configs = initConfigs();
  auto extractor = new Extractor();
  string fileSource = getFileSource();
  string[] usedModules = extractor.extractUsedModuleNames(configs[0], fileSource);
  (usedModules.length).shouldEqual(3);

  (usedModules[0]).shouldEqual("a.b.c");
  (usedModules[1]).shouldEqual("d.e.f");
  (usedModules[2]).shouldEqual("FishDog");
}
