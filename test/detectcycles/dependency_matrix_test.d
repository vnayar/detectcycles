module detectcycles.dependency_matrix_test;

import unit_threaded;
import detectcycles.dependency_matrix;

@("addModule")
unittest {
  import std.range;
  auto dMatrix = new DependencyMatrix();
  dMatrix.addModule("ham");
  dMatrix.addModule("crab.claw");
  dMatrix.addModule("ham");

  (dMatrix.numModules()).shouldEqual(2);

  (dMatrix.getModuleId("ham")).shouldEqual(0);
  (dMatrix.getModuleId("crab.claw")).shouldEqual(1);

  (dMatrix.getModuleName(0)).shouldEqual("ham");
  (dMatrix.getModuleName(1)).shouldEqual("crab.claw");

  (dMatrix.getDependencies(0).empty).shouldBeTrue();
  (dMatrix.getDependencies(1).empty).shouldBeTrue();
}

@("addDependencies")
unittest {
  import std.algorithm : find;
  import std.range;

  auto dMatrix = new DependencyMatrix();
  dMatrix.addDependencies("sandwich", ["bread", "cheese", "meat", "tomato"]);
  dMatrix.addDependencies("spagetti", ["noodles", "tomato", "basil"]);
  dMatrix.addDependencies("recursiveSandwich", ["recursiveSandwich", "bread", "cheese"]);

  (dMatrix.numModules()).shouldEqual(9);
  (dMatrix.getDependencies(dMatrix.getModuleId("sandwich")).length).shouldEqual(4);
  (dMatrix.getDependencies(dMatrix.getModuleId("recursiveSandwich")).length).shouldEqual(3);

  (dMatrix.getModuleId("meat") in dMatrix.getDependencies(dMatrix.getModuleId("sandwich")))
      .shouldBeTrue;
  (dMatrix.getModuleId("basil") in dMatrix.getDependencies(dMatrix.getModuleId("sandwich")))
      .shouldBeFalse;
}

@("detectStronglyConnectedComponentsByModuleId")
unittest {
  auto dMatrix = new DependencyMatrix();

  dMatrix.addDependencies("building", ["business"]);
  dMatrix.addDependencies("business", ["time", "money", "ideas"]);
  dMatrix.addDependencies("ideas", ["talent", "time"]);
  dMatrix.addDependencies("time", ["money"]);
  dMatrix.addDependencies("money", ["business"]);

  dMatrix.addDependencies("city", ["people", "infrastructure"]);
  dMatrix.addDependencies("infrastructure", ["workers", "resources"]);
  dMatrix.addDependencies("workers", ["city"]);

  IdSet[] sccs = dMatrix.detectStronglyConnectedComponents();

  (sccs.length).shouldEqual(2);

  (sccs[0].length).shouldEqual(4);
  (dMatrix.getModuleId("business")).shouldBeIn(sccs[0]);
  (dMatrix.getModuleId("ideas")).shouldBeIn(sccs[0]);
  (dMatrix.getModuleId("time")).shouldBeIn(sccs[0]);
  (dMatrix.getModuleId("money")).shouldBeIn(sccs[0]);

  (sccs[1].length).shouldEqual(3);
}
