@echo off

set  CLASSPATH=";trans2.jar;saxon8.jar;xquery.jar"

java   net.sf.saxon.Transform XQTSCatalog.xml xq2xsltest.xsl

cd  ReportingResults
java -jar ../xgrammar/lib/ant.jar

