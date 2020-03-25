@echo off


set CLASSPATH=";saxon8.jar;xquery.jar;xq2xml.jar"
echo  %1


java   net.sf.saxon.Transform -o xq2xqx.log  -it main xq2xqx.xsl xq=%1 dump="no$2"


java net.sf.saxon.Transform  -novw -o %12 %1x  xqueryx.xsl


echo ===
type %1

echo "==="
type %12