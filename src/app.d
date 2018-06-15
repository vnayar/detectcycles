import std.stdio;
import std.file;

void main(string[] args)
{

  // Iterate over all D source files in current directory and all its
  // subdirectories
  string baseDir = args.length > 1 ? args[1] : "";
  auto dFiles = dirEntries(baseDir, SpanMode.depth);
  foreach (d; dFiles)
    writeln(d.name);
}
