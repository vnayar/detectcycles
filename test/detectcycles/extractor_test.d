module detectcycles.extractor_test;

import unit_threaded;
import detectcycles.extractor;
import detectcycles.config;

Config[] initConfigs() {
  Config javaConfig = new Config();
  with (javaConfig) {
    language = "Java";
    fileGlob = "*.java";
    fileModuleRegex = ".*\\([^/\\\\]\\).java";
    sourceModuleRegex = "package \\(.*\\);";
    moduleName = "$sourceModule.$fileModule";
  }

  Config dConfig = new Config();
  with (dConfig) {
    language = "D";
    fileGlob = "*.{d,di}";
    fileModuleRegex = "";
    sourceModuleRegex = "module \\(.*\\);";
    moduleName = "$sourceModule";
  }

  return [javaConfig, dConfig];
}


@("findConfigForFileName")
unittest {
  auto extractor = new Extractor(initConfigs());
  (extractor.findConfigForFileName("ham.d").language).shouldEqual("D");
  (extractor.findConfigForFileName("bird/fish/cat/ham.d").language).shouldEqual("D");
  (extractor.findConfigForFileName("/fence/dog.di").language).shouldEqual("D");
  (extractor.findConfigForFileName("../ham.d").language).shouldEqual("D");
  (extractor.findConfigForFileName("~/rum/bacon.d").language).shouldEqual("D");

  (extractor.findConfigForFileName("~/rum/bacon.d.java").language).shouldEqual("Java");

  (extractor.findConfigForFileName("digdog/benno.dig")).shouldBeNull;
  (extractor.findConfigForFileName("digdog/benno.dog")).shouldBeNull;
}
