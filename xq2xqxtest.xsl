<!--
    xqtest.xsl
    Copyright David Carlisle 2005.

    Use and distribution of this code are permitted under the terms of the
    W3C Software Notice and License.
    http://www.w3.org/Consortium/Legal/2002/copyright-software-20021231
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="2.0"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:saxon="http://saxon.sf.net/"
xmlns:xq="java:Xq2xml"
xmlns:xqx="http://www.w3.org/2005/XQueryX"
xmlns:qt="http://www.w3.org/2005/02/query-test-XQTSCatalog"
exclude-result-prefixes="saxon xs  xq qt">
<xsl:import href="xq2xqx.xsl"/>
<xsl:import href="xqueryx.xsl"/>
<xsl:preserve-space elements="data"/>
<xsl:param name="test" select="'no'"/>

<xsl:variable name="qthome" select="/qt:test-suite/@XQueryQueryOffsetPath"/>
<!--
<xsl:variable name="qtxhome" select="/qt:test-suite/@XQueryXQueryOffsetPath"/>
-->
<xsl:variable name="qtxhome" select="'Queries/XQueryX-dpc/'"/>
<xsl:variable name="qtext" select="/qt:test-suite/@XQueryFileExtension"/>
<xsl:variable name="qtxext" select="/qt:test-suite/@XQueryXFileExtension"/>

<xsl:output encoding="utf-8"/>

<xsl:template match="xqx:operand|xqx:firstOperand|xqx:secondOperand|xqx:startExpr|xqx:endExpr|xqx:orderByExpr|xqx:contentExpr|xqx:valueExpr">
<xsl:apply-templates/>
</xsl:template>
<xsl:template match="xqx:varValue|xqx:sourceExpr|xqx:predicateExpr|xqx:module|xqx:argExpr|xqx:parenthesizedExpr|xqx:ifClause|xqx:thenClause|xqx:elseClause|xqx:forExpr|xqx:letExpr|xqx:resultExpr">
<xsl:apply-templates/>
</xsl:template>

<xsl:template match="/">
<xsl:for-each select="descendant::qt:test-case
(:[@name=('K-ErrorFunc-7','K-XQueryComment-19')]:)
(:[@name='Constr-ws-tag-6']:)
[not(qt:query/@name=preceding-sibling::*[1]/qt:query/@name)]/(qt:query|qt:input-query)
">


<xsl:variable name="xq" select="concat($qthome,../@FilePath,@name,$qtext)"/>
<xsl:variable name="xqxf" select="concat($qtxhome,../@FilePath,@name,'.xqx')"/>
<xsl:variable name="xq1" select="if (@name=(
'K-CopyNamespacesProlog-4',
'K-CopyNamespacesProlog-5',
'K-ConstructionProlog-2',
'K-InternalVariablesWith-17',
'K-InternalVariablesWith-19',
'K-InternalVariablesWith-20',
'K-InternalVariablesWith-23',
'K-XQueryComment-14',
'K-XQueryComment-15',
'K2-DirectConElemAttr-7',
'prolog-version-2'
)) then '+' else unparsed-text($xq,'utf-8')"/>
<xsl:variable name="xqxml" select="saxon:discard-document(saxon:parse(xq:convert($xq1)))"/>


<!--
<xsl:message>:<xsl:value-of select="$xq"/></xsl:message>
-->

<xsl:variable name="xqx">
<xsl:choose>
<!-- parser had problems with comments, so if it failed to parse, try zapping comments then try again.
Only do this if failed when failure unexpected as it isn't really safe, eg "comments" inside strings
or attributes will be corrupted 
-->
<xsl:when test="false() and $xqxml/error and not(../@scenario='parse-error')">
<xsl:apply-templates select="saxon:discard-document(saxon:parse(xq:convert(
replace(replace(replace($xq1,'\(:[^:]*([^\(]:[^\)][^:]*)*:\)',''),'\(:[^:]*([^\(]:[^\)][^:]*)*:\)',''),'\(:[^:]*([^\(]:[^\)][^:]*)*:\)','')
)))/*"/>
</xsl:when>
<xsl:when test="../qt:expected-error">
<xsl:apply-templates select="$xqxml/*">
  <xsl:with-param name="error" select="../qt:expected-error[1]" tunnel="yes"/>
</xsl:apply-templates>
</xsl:when>
<xsl:otherwise>
<xsl:apply-templates select="$xqxml/*"/>
</xsl:otherwise>
</xsl:choose>
</xsl:variable>



<xsl:result-document href="{$xqxf}" method="xml" indent="yes">
<xsl:comment>
<xsl:text>
    Automatically converted by xq2xqx.xsl
</xsl:text>
<xsl:variable name="c" select="xq:comment(tokenize($xq1,' *&#13;?&#10; *'))"/>
<xsl:if test="$c">
  <xsl:text>    Original Comments:&#10;</xsl:text>
  <xsl:value-of select="$c"/>
</xsl:if>
</xsl:comment>
<xsl:text>&#10;</xsl:text>
<xsl:apply-templates mode="x2" select="saxon:discard-document($xqx)"/>
</xsl:result-document>

<xsl:if test="$test='yes'">

<xsl:variable name="xq2">
 <xsl:apply-templates select="$xqx/*"/>
</xsl:variable>

<xsl:result-document href="{$xq}2" method="text">
 <xsl:copy-of select="($xq2)"/>
</xsl:result-document>



<xsl:choose>
<xsl:when test="$xqx//xqx:functionName='error'">
<xsl:if test="not(../@scenario='parse-error' or ../@scenario='runtime-error' or $xqxml//FunctionCall/FunctionQName[data='error'])">
<xsl:message terminate="no">
==== unexpected error
<xsl:value-of select="position()"/>:
<xsl:value-of select="$xq"/>
<xsl:copy-of select="$xqxml"/>
=================
</xsl:message>
</xsl:if>
</xsl:when>
<xsl:when test="../@scenario='parse-error'">
<xsl:message terminate="no">
==== no error reported <xsl:value-of select="position()"/>:
<xsl:value-of select="$xq"/><xsl:text>&#10;</xsl:text>
<xsl:copy-of select="$xqxml"/>
=================
</xsl:message>
</xsl:when>
<xsl:otherwise>

<xsl:variable name="xq1a">
<xsl:analyze-string select="
 replace(
 replace($xq1,
      'encoding +[''&quot;].*?[''&quot;]',''),
     '\(:[^:]*:\)','')" 
    regex="(&lt;\?(.*?)\?>)|(&lt;!--(.*?)-->)|(&lt;!\[CDATA\[(.*?)\]\]&gt;)" flags="s">
<xsl:matching-substring>
<xsl:choose>
<xsl:when test="starts-with(.,'&lt;?')">
<xsl:text>processing-instruction</xsl:text>
<xsl:value-of select="replace(regex-group(2),'&amp;','&amp;amp;')"/>
</xsl:when>
<xsl:when test="starts-with(.,'&lt;!--')">
<xsl:text>comment</xsl:text>
<xsl:value-of select="replace(regex-group(4),'&amp;','&amp;amp;')"/>
</xsl:when>
<xsl:otherwise>
<xsl:value-of select="replace(regex-group(6),'&amp;','&amp;amp;')"/>
</xsl:otherwise>
</xsl:choose>
</xsl:matching-substring>
<xsl:non-matching-substring>
<xsl:value-of select="replace(xq:chars(.),'&amp;','&amp;amp;')"/>
</xsl:non-matching-substring>
</xsl:analyze-string>
</xsl:variable>



<xsl:variable name="nxq1" select="xq:n($xq1a)"/>
<xsl:variable name="nxq2" select="xq:n($xq2)"/>

<xsl:if test="$nxq1!=$nxq2">
<xsl:message terminate="no">
:<xsl:value-of select="$xq"/>
<!--
====
<xsl:value-of select="position()"/>:
<xsl:value-of select="$xq"/>
====xq1:
<xsl:value-of select="$xq1"/>
====xq2:
<xsl:value-of select="$xq2"/>
====xq1a:
<xsl:value-of select="$xq1a"/>
-->
====nxq1:
<xsl:value-of select="$nxq1"/>
====nxq2:
<xsl:value-of select="$nxq2"/>
====
</xsl:message>
</xsl:if>
</xsl:otherwise>
</xsl:choose>
</xsl:if>

</xsl:for-each>

<xsl:if test="$test='yes'">
<xsl:for-each select="descendant::qt:test-group[qt:test-case]">
<xsl:result-document method="text" href="xq2xqxtest-{@name}.xml">
&lt;!DOCTYPE xqx:queryList [
<xsl:for-each select="qt:test-case[not(qt:query/@name=preceding-sibling::*[1]/qt:query/@name)]/(qt:query|qt:input-query)">
&lt;!ENTITY <xsl:value-of select="concat(@name,' SYSTEM &quot;',$qtxhome,../@FilePath,@name,'.xqx&quot;>')"/>
</xsl:for-each>
]>
&lt;xqx:queryList xmlns:xqx="http://www.w3.org/2005/XQueryX">
<xsl:for-each select="qt:test-case[not(qt:query/@name=preceding-sibling::*[1]/qt:query/@name)]/(qt:query|qt:input-query)">
&amp;<xsl:value-of select="@name"/><xsl:text>;</xsl:text>
</xsl:for-each>
&lt;/xqx:queryList>
</xsl:result-document>
</xsl:for-each>
</xsl:if>

</xsl:template>

<xsl:function name="xq:n">
 <xsl:param name="s"/>
<xsl:sequence select="replace(
 replace(
 replace(
 replace(
 replace(
 replace(
 replace(
replace(
xq:rem-comment($s),
'&amp;lt;','&lt;'),
'\|','union'),
'(\(:.*?:\)|[ \t\r\n(){},''&quot;/@]|&lt;/\i\c*\s*&gt;|descendant-or-self::node|attribute::|parent::node|\.\.|child::|for|declare\s*boundary-space\s*(preserve|strip)\s*;)','',
's'),
'\++','+'),
'\++-\+*','-'),
'\--','+'),
'\++','+'),
'\+*-\+*','-')
"/>
</xsl:function>


<xsl:function name="xq:comment" as="xs:string">
  <xsl:param name="x"/>
  <xsl:sequence select="if (matches($x[1],'^ *\(:.*:\) *$'))
			then concat($x[1],'&#10;',xq:comment($x[position()&gt;1]))
			else ''"/>
</xsl:function>

<xsl:function name="xq:rem-comment" as="xs:string">
  <xsl:param name="x"/>
  <xsl:variable name="x2" select="replace($x,'\(:([^:]|[^\(]:[^\)])*:\)',' ')"/>
  <xsl:sequence select="if($x=$x2) then $x else xq:rem-comment($x2)"/>
</xsl:function>

</xsl:stylesheet>



