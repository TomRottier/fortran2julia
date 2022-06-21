# fortran2julia

Requires dotnet runtime to be installed. Parses to JSON by https://github.com/robinrottier/fortran-parser, parse.jl converts to JSON to Julia.

## Usage
- edit parse.bat file and add locations of dotnet executable (if not on path), fortran-parser.dll, and julia executeable (if not on path).
- run parse.bat passing name of fortran file to be parsed - produces intermediate JSON file and eom.jl, parameters.jl, and functions.jl

## configuration
Edit eom_str.jl, parameters_str.jl, and functions_str.jl to customise output. Copy files to working directory and pass _absolute_ path to directory as second argument to parse.bat
