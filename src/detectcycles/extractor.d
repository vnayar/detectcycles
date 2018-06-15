module detectcycles.extractor;

import detectcycles.config;

import std.path : globMatch;

/**
 * Extracts dependency information from a given file using provided configurations.
 */
class Extractor {
private:
  Config[] _configs;

public:
  this(Config[] configs) {
    _configs = configs;
  }


  /**
   * Given a file name, determine what language configuration is appropriate for it.
   * If there are no matches, return null.
   */
  Config findConfigForFileName(string fileName) {
    foreach (c; _configs) {
      if (globMatch(fileName, c.fileGlob)) {
        return c;
      }
    }
    return null;
  }
}
