module detectcycles.dependency_matrix_test;

import unit_threaded;
import detectcycles.dependency_matrix;

@("addSymbol")
unittest {
  auto dMatrix = new DependencyMatrix();
  dMatrix.addSymbol("ham");
  dMatrix.addSymbol("crab.claw");
  dMatrix.addSymbol("ham");

  (dMatrix.numSymbols()).shouldEqual(2);

  (dMatrix.getModuleId("ham")).shouldEqual(0);
  (dMatrix.getModuleId("crab.claw")).shouldEqual(1);

  (dMatrix.getModuleName(0)).shouldEqual("ham");
  (dMatrix.getModuleName(1)).shouldEqual("crab.claw");

  (dMatrix.getDependencies(0).empty()).shouldBeTrue();
  (dMatrix.getDependencies(1).empty()).shouldBeTrue();
}

@("addDependencies")
unittest {
  auto dMatrix = new DependencyMatrix();
  dMatrix.addDependencies("sandwich", ["bread", "cheese", "meat", "tomato"]);
  dMatrix.addDependencies("spagetti", ["noodles", "tomato", "basil"]);
  dMatrix.addDependencies("recursiveSandwich", ["recursiveSandwich", "bread", "cheese"]);

  (dMatrix.numSymbols()).shouldEqual(9);
  (dMatrix.getDependencies(dMatrix.getModuleId("sandwich")).length()).shouldEqual(4);
  (dMatrix.getDependencies(dMatrix.getModuleId("recursiveSandwich")).length()).shouldEqual(3);

  dMatrix.getModuleId("meat").shouldBeIn(dMatrix.getDependencies(dMatrix.getModuleId("sandwich")));
  dMatrix.getModuleId("basil")
      .shouldNotBeIn(dMatrix.getDependencies(dMatrix.getModuleId("sandwich")));
}
