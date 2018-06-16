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
    usesRegex = "import ([^;]+);";
    statementDelimitorRegex = "[;]";
  }

  Config dConfig = new Config();
  with (dConfig) {
    language = "D";
    fileGlob = "*.{d,di}";
    fileModuleRegex = "";
    sourceModuleRegex = "module (.+);";
    moduleName = "$sourceModule";
    usesRegex = "import ([^;]+);";
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
  static void main() {
    System.out.println("hello world");
  }
}
EOS";
}

@("extractModuleName")
unittest {
  auto extractor = new Extractor(initConfigs());

  string fileSource = getFileSource();

  (extractor.extractModuleName(extractor.configs[0], "/a/b/c/Ham.java", fileSource))
      .shouldEqual("cat.dog.fish.Ham");
  (extractor.extractModuleName(extractor.configs[0], "../a/b/c/Ham.java", fileSource))
      .shouldEqual("cat.dog.fish.Ham");
  (extractor.extractModuleName(extractor.configs[0], "a/b/c/Ham.java", fileSource))
      .shouldEqual("cat.dog.fish.Ham");
}

@("extractUsedModuleNames")
unittest {
  auto extractor = new Extractor(initConfigs());
  string fileSource = getFileSource();
  string[] usedModules = extractor.extractUsedModuleNames(extractor.configs[0], fileSource);
  (usedModules.length).shouldEqual(2);

  (usedModules[0]).shouldEqual("a.b.c");
  (usedModules[1]).shouldEqual("d.e.f");
}
