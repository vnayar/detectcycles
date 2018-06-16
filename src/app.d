import detectcycles.config;
import detectcycles.extractor;
import detectcycles.dependency_matrix;

import std.file : readText, dirEntries, SpanMode;
import std.getopt : getopt, GetoptResult, defaultGetoptPrinter;
import std.path : expandTilde;
import std.stdio : writeln;
import std.algorithm : find, map;
import std.range : takeOne;


void main(string[] args)
{
  string language;
  bool showLanguages;
  string configFile;

  GetoptResult getOptResult = getopt(
      args,
      "config|c", "Specify a custom language-support configuration file to use.", &configFile,
      "language|l", "Limit scanning to only a specific language.", &language,
      "showLanguages|s", "Show the supported languages.", &showLanguages);

  if (getOptResult.helpWanted) {
    defaultGetoptPrinter(
        "detectcycles: The source code dependency cycle detector.", getOptResult.options);
    return;
  }

  // Load our language parsing configurations.
  Config[] configs;
  if (configFile) {
    configFile = expandTilde(configFile);
    configs = loadConfigsFromJson(readText(configFile));
  } else {
    configs = loadConfigsFromDefault();
  }

  // If desired, show the supported languages.
  if (showLanguages) {
    writeln("Supported Languages");
    writeln("===================");
    foreach (config; configs) {
      writeln(config.language);
    }
    return;
  }

  // Limit searches to only the given language.
  if (language !is null) {
    configs = find!((config, val)  => config.language == val)(configs, language).takeOne();
  }

  if (configs.length == 0) {
    writeln("No configuration found for language: ", language);
    return;
  }

  // Iterate over all D source files in current directory and all its
  // subdirectories
  string[] rootDirs = args.length > 1 ? args[1..$] : [""];
  auto extractor = new Extractor();
  auto dependencyMatrix = new DependencyMatrix();
  foreach (rootDir; rootDirs) {
    foreach (config; configs) {
      auto dFiles = dirEntries(rootDir, config.fileGlob, SpanMode.depth);
      foreach (dirEntry; dFiles) {
        if (!dirEntry.isFile()) {
          continue;
        }
        writeln(dirEntry.name);
        string sourceText = readText(dirEntry.name);
        string moduleName =
            extractor.extractModuleName(config, dirEntry.name, sourceText);
        writeln("  module: '", moduleName, "'");
        string[] usedModules = extractor.extractUsedModuleNames(config, sourceText);
        writeln("  uses  : ", usedModules);
        if (moduleName is null || moduleName.length == 0) {
          writeln("  -- Skipping module with no name.");
          continue;
        }
        dependencyMatrix.addDependencies(moduleName, usedModules);
      }
    }
  }
}
