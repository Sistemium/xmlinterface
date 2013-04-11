#!/bin/bash

xsltproc -o ../data/dump/datasync/metadata/sql-ddl.xml ../xsl/sql-metadata.xsl ../data/dump/datasync/metadata/clean.xml 
xsltproc -o /Users/sasha/Desktop/ddl.txt ../xsl/sql-ddl.xsl ../data/dump/datasync/metadata/sql-ddl.xml