module detectcycles.extractor;

import detectcycles.config;

import std.format : format;
import std.path : globMatch;
import std.range : ElementEncodingType, isInfinite, isInputRange;
import std.regex : matchFirst;
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

    string moduleFormat = config.moduleName
        .replace("$fileModule", "%1$s")
        .replace("$sourceModule", "%2$s");
    return format(moduleFormat, fileNamePart, sourceNamePart);
  }

  string[] extractUsedModuleNames(R)(Config config, R sourceInput)
  if (isInputRange!R && !isInfinite!R && isSomeChar!(ElementEncodingType!R))
  in {
    assert(config !is null);
  } body {
    string[] used;
    while (!sourceInput.empty > 0) {
      auto captures = matchFirst(sourceInput, config.usesRegex, config.statementDelimitorRegex);
      if (captures.whichPattern == 1 && !captures.empty()) {
        used ~= captures[captures.length - 1];
        sourceInput = captures.post();
      } else if (captures.whichPattern == 2) {
        sourceInput = captures.post();
      } else {
        sourceInput = "";
      }
    }
    return used;
  }

}
