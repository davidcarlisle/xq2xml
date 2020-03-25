@echo off


set CLASSPATH=";saxon8.jar;xquery.jar;xq2xml.jar"

java   net.sf.saxon.Transform -o xq2xqx.log  -it main xq2xsl.xsl xq=%1 dump="yes"


