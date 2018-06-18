import detectcycles.config;
import detectcycles.extractor;
import detectcycles.dependency_matrix;

import std.algorithm : find, map;
import std.file : readText, dirEntries, SpanMode;
import std.getopt : getopt, GetoptResult, defaultGetoptPrinter;
import std.path : expandTilde;
import std.range : empty, takeOne;
import std.stdio : write, writeln;

enum LogLevel { OFF, DEBUG }
class Logger {
  LogLevel _logLevel;
  this(LogLevel logLevel) {
    _logLevel = logLevel;
  }
  void logDebug(T...)(lazy T args) {
    if (_logLevel == LogLevel.DEBUG) {
      writeln(args);
    }
  }
}

void main(string[] args)
{
  string configFile;
  bool debugLog;
  bool generate;
  string language;
  bool plantUml;
  bool showLanguages;

  GetoptResult getOptResult = getopt(
      args,
      "config|c", "Specify a custom language-support configuration file to use.", &configFile,
      "debug|d", "Enable debug logging.", &debugLog,
      "generate|g", "Generates default configurations to modify and use with -c.", &generate,
      "language|l", "Limit scanning to only a specific language.", &language,
      "plantUml|p", "Prints the cyclical components in PlantUml syntax.", &plantUml,
      "showLanguages|s", "Show the supported languages.", &showLanguages);

  auto logger = new Logger( debugLog ? LogLevel.DEBUG : LogLevel.OFF);

  if (getOptResult.helpWanted) {
    defaultGetoptPrinter(
        "detectcycles: The source code dependency cycle detector.\n"
            ~ "Usage: detectcycles [options] [srcDir1] [srcDir2] ...",
        getOptResult.options);
    return;
  }

  if (generate) {
    writeln("Save the following to a file");
    writeln("============================");
    writeln(detectcycles.config.defaultConfig);
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
    rootDir = expandTilde(rootDir);
    foreach (config; configs) {
      auto dFiles = dirEntries(rootDir, config.fileGlob, SpanMode.depth);
      foreach (dirEntry; dFiles) {
        if (!dirEntry.isFile()) {
          continue;
        }
        logger.logDebug(dirEntry.name);
        string sourceText = readText(dirEntry.name);
        string moduleName =
            extractor.extractModuleName(config, dirEntry.name, sourceText);
        logger.logDebug("  module: \"", moduleName, "\"");
        string[] usedModules = extractor.extractUsedModuleNames(config, sourceText);
        logger.logDebug("  uses  : ", usedModules);
        if (moduleName is null || moduleName.length == 0) {
          logger.logDebug("  -- Skipping module with no name.");
          continue;
        }
        dependencyMatrix.addDependencies(moduleName, usedModules);
      }
    }
  }

  // Finally detect the cycles and print them out.
  IdSet[] stronglyConnectedComponents = dependencyMatrix.detectStronglyConnectedComponents();

  if (stronglyConnectedComponents.length == 0) {
    writeln("No cycles detected.");
  } else {
    writeln("The following blocks of cyclical components were detected:");
    foreach (i, scc; stronglyConnectedComponents) {
      writeln("Cycle #", i, " (", scc.length, " components)");
      if (plantUml) {
        printSccPlantUml(dependencyMatrix, scc);
      } else {
        printSccBasic(dependencyMatrix, scc);
      }
      writeln("");
    }
  }
}

void printSccBasic(DependencyMatrix m, IdSet scc) {
  size_t i = 0;
  foreach (moduleId; scc) {
    if (i++ != 0) {
      write(" => ");
    }
    write(m.getModuleName(moduleId));
  }
  writeln("\n");
}

void printSccPlantUml(DependencyMatrix m, IdSet scc) {
  foreach (componentId; scc) {
    foreach (dependencyId; m.getDependencies(componentId)) {
      if (dependencyId in scc) {
        writeln(m.getModuleName(componentId), " ..> ", m.getModuleName(dependencyId));
      }
    }
  }
}
