#!/usr/bin/env php
<?php

if ($argc < 2) {
    echo "\nSyntax: import-csv.php table-name

Ex: import-csv table-name < infile.csv > outfile.sql

";
    exit;
}

echo "BEGIN;\n";

$table = $argv[1];
$fields = substr(fgets(STDIN), 0, -1);

$l = 1;
while ($row = fgetcsv(STDIN)) {
    $line = implode(',', array_map(function ($v) {
        if ($v == 'NULL' || is_numeric($v))
            return $v;
        return '"' . addslashes(trim($v)) . '"';
    }, $row));
    echo "INSERT INTO $table ($fields) VALUES ($line);\n";
    fputs(STDERR, "Row $l\n");
    ++$l;
}

echo "COMMIT;\n";
