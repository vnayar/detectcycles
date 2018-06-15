module detectcycles.config_test;

import unit_threaded;

import detectcycles.config;

Config[] initTestLanguageConfigs() {
  Config[] configs = loadConfigsFromJson(q"EOS
[
  {
    "language": "Java",
    "fileGlob": "*.java",
    "fileModuleRegex": ".*\\([^/\\\\]\\).java",
    "sourceModuleRegex": "package \\(.*\\);",
    "moduleName": "$sourceModule.$fileModule"
  },
  {
    "language": "D",
    "fileGlob": "*.{d,di}",
    "fileModuleRegex": "",
    "sourceModuleRegex": "module \\(.*\\);",
    "moduleName": "$sourceModule"
  }
]
EOS");
  return configs;
}

@("loadFromJson")
unittest {
  auto configs = initTestLanguageConfigs();

  (configs.length).shouldEqual(2);
  Config javaConfig = configs[0];
  (javaConfig.language).shouldEqual("Java");
  (javaConfig.fileGlob).shouldEqual("*.java");
  (javaConfig.fileModuleRegex).shouldEqual(".*\\([^/\\\\]\\).java");
  (javaConfig.sourceModuleRegex).shouldEqual("package \\(.*\\);");
  (javaConfig.moduleName).shouldEqual("$sourceModule.$fileModule");
}
