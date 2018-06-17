module detectcycles.dependency_matrix;

import std.stdio;
import std.container.rbtree;
import std.typecons : Typedef;
import std.algorithm : min;
import std.range;

//alias IdSet = RedBlackTree!size_t;

class DependencyMatrix {
private:
  size_t[string] _moduleIdByName;
  string[] _moduleNameById;
  size_t[][] _dependencies;

  invariant {
    size_t length = _moduleIdByName.length;
    assert(_moduleNameById.length == length);
    assert(_dependencies.length == length);
  }

public:

  size_t numModules() {
    return _moduleNameById.length;
  }

  size_t getModuleId(string moduleName) {
    return _moduleIdByName[moduleName];
  }

  string getModuleName(size_t moduleId) {
    return _moduleNameById[moduleId];
  }

  size_t[] getDependencies(size_t moduleId) {
    return _dependencies[moduleId];
  }

  /// Idempotently add a new module to the module table.
  void addModule(string moduleName) {
    if (moduleName !in _moduleIdByName) {
      auto id = _dependencies.length;
      _dependencies.length++;
      _dependencies[id] = [];
      _moduleNameById.length++;
      _moduleNameById[id] = moduleName;
      _moduleIdByName[moduleName] = id;
    }
  }

  /// Store the dependencies for the given module by name for later analysis.
  void addDependencies(string moduleName, string[] dependencyNames) {
    addModule(moduleName);
    foreach (dependency; dependencyNames) {
      addModule(dependency);
      _dependencies[getModuleId(moduleName)] ~= getModuleId(dependency);
    }
  }

  string[][] detectStronglyConnectedComponents() {
    size_t[][] sccs = detectStronglyConnectedComponentsByModuleId();
    string[][] sccsByName = [];
    foreach (scc; sccs) {
      string[] sccByName = [];
      foreach (id; scc) {
        sccByName ~= getModuleName(id);
      }
      sccsByName ~= sccByName;
    }
    return sccsByName;
  }

  /**
   * Based upon Tarjan's strongly connected components algorithm.
   * $(LINK https://en.wikipedia.org/wiki/Tarjan%E2%80%99s_strongly_connected_components_algorithm)
   */
  size_t[][] detectStronglyConnectedComponentsByModuleId() {
    size_t order = 1;
    size_t[] stack;
    size_t[] onStack = new size_t[numModules()];
    size_t[] discoverOrder = new size_t[numModules()];
    size_t[] lowestReachableOrder = new size_t[numModules()];

    size_t[] strongConnect(size_t v) {
      // Initialize the state of the vertex as it is discovered in the depth-first search.
      discoverOrder[v] = order;
      lowestReachableOrder[v] = order;
      order++;
      stack ~= v;
      onStack[v] = true;

      // Consider successors.
      foreach(w; _dependencies[v]) {
        if (discoverOrder[w] == 0) {
          // If w has not yet been visited, recurse depth-first.
          strongConnect(w);
          lowestReachableOrder[v] = min(lowestReachableOrder[v], lowestReachableOrder[w]);
        } else if (onStack[w]) {
          // The successor is on the stack, and in the current strongly connected component.
          lowestReachableOrder[v] = min(lowestReachableOrder[v], discoverOrder[w]);
        }
      }

      // If v is a root of a depth-first tree, pop the stack and make the
      // strongly-connected component.
      if (lowestReachableOrder[v] == discoverOrder[v]) {
        // Strongly Connected Component
        size_t[] scc = [];
        size_t w;
        do {
          w = stack.back();
          stack.popBack();
          onStack[w] = false;
          scc ~= w;
        } while (w != v);
        if (scc.length > 1) {
          return scc;
        }
      }
      return null;
    }

    size_t[][] stronglyConnectedComponents = [];
    foreach (moduleId; 0 .. numModules()) {
      if (discoverOrder[moduleId] == 0) {
        size_t[] scc = strongConnect(moduleId);
        if (scc != null) {
          stronglyConnectedComponents ~= scc;
        }
      }
    }

    return stronglyConnectedComponents;
  }
}
