# MultiPlatformFormatLib

Multi-Platform Format Libaray as a static library.
The ultimate aim is to use this library in a larger project
  and we do not want to deal with the complication of using fmt there.
The thinking is to compile fmt as a full static library
  so that only a hpp and lib files are needed in the downstream project.

The accomplish this, we need to control the exact compiler version and options.
Those settings are selected based on what the downstream project is using.

If you would like to use this library in your project,
  you can adjust the compiler version and options to fit your own.

