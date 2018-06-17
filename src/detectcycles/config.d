module detectcycles.config;

import std.json : JSONValue, parseJSON;
import std.range : ElementEncodingType, isInfinite, isInputRange;
import std.traits : isSomeChar;

/**
 * Configurations determining how files for a given programming language will be scanned to
 * determine their module name and module dependencies.
 */
class Config {
  string language;
  string fileGlob;
  string fileModuleRegex;
  string sourceModuleRegex;
  string moduleName;
  string usesRegex;
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
    config.usesRegex = val["usesRegex"].str;
    config.statementDelimitorRegex = val["statementDelimitorRegex"].str;
    configs ~= config;
  }
  return configs;
}

string defaultConfig = import("config.json");

Config[] loadConfigsFromDefault() {
  return loadConfigsFromJson(defaultConfig);
}

