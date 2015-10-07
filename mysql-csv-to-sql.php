#!/usr/bin/env php
<?php

if ($argc < 2) {
  $name = basename ($argv[0]);
  fputs (STDERR, "
Syntax:   $name table-name [-d]

Options:  -d    drop existing rows

Ex:       $name table-name < infile.csv > outfile.sql

Description:

Converts a CSV file to SQL INSERT statements.
The first row of the CSV should contain column names.
The generated SQL is output to STDOUT and can be redirected to a file.

");
  exit (1);
}

echo "BEGIN;\n";

$table  = $argv[1];
if ($argc == 3) {
  if ($argv[2] == '-d') echo "DELETE FROM $table;\n";
  else {
    fputs (STDERR, "Invalid option $argv[2]\n");
    exit (1);
  }
}

$fields = substr (fgets (STDIN), 0, -1);

$l = 1;
while ($row = fgetcsv (STDIN)) {
  $line = implode (',', array_map (function ($v) {
    if ($v == 'NULL' || is_numeric ($v))
      return $v;
    return '"' . addslashes (trim ($v)) . '"';
  }, $row));
  echo "INSERT INTO $table ($fields) VALUES ($line);\n";
  fputs (STDERR, "Row $l\n");
  ++$l;
}

echo "COMMIT;\n";
