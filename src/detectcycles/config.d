module detectcycles.config;

import std.json : JSONValue, parseJSON;
import std.range : ElementEncodingType, isInfinite, isInputRange;
import std.traits : isSomeChar;

/**
 * Configurations determining how files for a given programming language will be scanned to
 * determine their module name and module dependencies.
 */
class Config {
  /**
   * The name of the language when chosen with the "--language" option.
   */
  string language;

  /**
   * The filter used to detect files for this language.
   * For format, see: https://dlang.org/phobos/std_path.html#globMatch
   */
  string fileGlob;

  /**
   * A regular expression to capture the part of the file name used to build the module name.
   * The last matching group '()' will be saved as $fileModule.
   */
  string fileModuleRegex;

  /**
   * A regular expression matching statements of source code used to build a module name.
   * The last matching group '()' will be saved as $sourceModule.
   */
  string sourceModuleRegex;

  /**
   * A string name of the module.
   * The variables $sourceModule and $fileModule will be substituted.
   */
  string moduleName;

  /**
   * Regular expressions to detect a 'uses' or 'depends' relationship.
   * The last matching group '()' will be the name of module that is used.
   * These regexes are checked in order, only the first match will apply.
   */
  string[] usesRegexes;

  /**
   * A delimitor for a uses statement in the language being used.
   * Note: In C++, '#include' statements are used for dependencies, so '\n' is the delimitor.
   */
  string statementDelimitorRegex;
}

Config[] loadConfigsFromJson(R)(R jsonInput)
if (isInputRange!R && !isInfinite!R && isSomeChar!(ElementEncodingType!R)) {
  Config[] configs;

  JSONValue rootValue = parseJSON(jsonInput);
  foreach (languageValue; rootValue.array) {
    auto val = languageValue.object;
    auto config = new Config();
    config.language = val["language"].str;
    config.fileGlob = val["fileGlob"].str;
    config.fileModuleRegex = val["fileModuleRegex"].str;
    config.sourceModuleRegex = val["sourceModuleRegex"].str;
    config.moduleName = val["moduleName"].str;
    config.usesRegexes = [];
    foreach (usesRegexValue; val["usesRegexes"].array) { 
      config.usesRegexes ~= usesRegexValue.str;
    }
    config.statementDelimitorRegex = val["statementDelimitorRegex"].str;
    configs ~= config;
  }
  return configs;
}

string defaultConfig = import("config.json");

Config[] loadConfigsFromDefault() {
  return loadConfigsFromJson(defaultConfig);
}

