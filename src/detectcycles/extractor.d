module detectcycles.extractor;

import detectcycles.config;

import std.algorithm : map;
import std.path : globMatch;
import std.range : ElementEncodingType, isInfinite, isInputRange;
import std.regex : matchFirst, regex, Regex;
import std.string : replace, empty;
import std.traits : isSomeChar;


/// Extracts dependency information from a given file using provided configurations.
class Extractor {
  string extractModuleName(R)(Config config, string fileName, R sourceInput)
  if (isInputRange!R && !isInfinite!R && isSomeChar!(ElementEncodingType!R))
  in {
    assert(config !is null);
  } body {
    auto captures = matchFirst(fileName, config.fileModuleRegex);
    // If a capture group exists, inside \( and \), use that, otherwise use the whole match.
    string fileNamePart = !captures.empty() ? captures[captures.length - 1] : "";

    captures = matchFirst(sourceInput, config.sourceModuleRegex);
    string sourceNamePart = !captures.empty() ? captures[captures.length - 1] : "";

    string moduleName = config.moduleName
        .replace("$fileModule", fileNamePart)
        .replace("$sourceModule", sourceNamePart);
    return moduleName;
  }

  string[] extractUsedModuleNames(R)(Config config, R sourceInput)
  if (isInputRange!R && !isInfinite!R && isSomeChar!(ElementEncodingType!R))
  in {
    assert(config !is null);
  } body {
    string[] used;
    Regex!char statementDelimitorRegex = regex(".*?" ~ config.statementDelimitorRegex, "s");
    auto usesRegexes = config.usesRegexes
        .map!(usesRegexStr => regex(usesRegexStr, "s"));
    while (!sourceInput.empty) {
      auto statementCaptures = matchFirst(sourceInput, statementDelimitorRegex);
      if (!statementCaptures.empty()) {
        foreach (usesRegex; usesRegexes) {
          auto captures = matchFirst(statementCaptures.hit(), usesRegex);
          if (!captures.empty()) {
            used ~= captures[captures.length - 1];
            break;
          }
        }
        sourceInput = statementCaptures.post();
      } else {
        sourceInput = "";
      }
    }
    return used;
  }

}
