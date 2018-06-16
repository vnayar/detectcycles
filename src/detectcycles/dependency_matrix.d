module detectcycles.dependency_matrix;

import std.stdio;
import std.container.rbtree;
import std.typecons : Typedef;


alias IdSet = RedBlackTree!size_t;

class DependencyMatrix {
private:
  size_t[string] _moduleIdByName;
  string[] _moduleNameById;
  IdSet[] _dependencies;

  invariant {
    size_t length = _moduleIdByName.length;
    assert(_moduleNameById.length == length);
    assert(_dependencies.length == length);
  }

public:

  size_t numSymbols() {
    return _moduleNameById.length;
  }

  size_t getModuleId(string moduleName) {
    return _moduleIdByName[moduleName];
  }

  string getModuleName(size_t moduleId) {
    return _moduleNameById[moduleId];
  }

  IdSet getDependencies(size_t moduleId) {
    return _dependencies[moduleId];
  }
  
  /// Idempotently add a new module to the module table.
  void addSymbol(string moduleName) {
    if (moduleName !in _moduleIdByName) {
      auto id = _dependencies.length;
      _dependencies.length++;
      _dependencies[id] = new IdSet();
      _moduleNameById.length++;
      _moduleNameById[id] = moduleName;
      _moduleIdByName[moduleName] = id;
    }
  }

  /// Store the dependencies for the given module by name for later analysis.
  void addDependencies(string moduleName, string[] dependencyNames) {
    addSymbol(moduleName);
    foreach (dependency; dependencyNames) {
      addSymbol(dependency);
      _dependencies[getModuleId(moduleName)].insert(getModuleId(dependency));
    }
  }
}
