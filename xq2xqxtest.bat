@echo off

set CLASSPATH=";saxon8.jar;xquery.jar"

java   net.sf.saxon.Transform XQTSCatalog.xml xq2xqxtest.xsl  test="yes"

