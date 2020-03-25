<!--
    xq2xsl.xsl
    Copyright David Carlisle 2005.

Use and distribution of this code are permitted under the terms of the
W3C Software Notice and License.
http://www.w3.org/Consortium/Legal/2002/copyright-software-20021231
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		version="2.0"
		xmlns:axsl="http://www.w3.org/1999/XSL/TransformA"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		xmlns:saxon="http://saxon.sf.net/"
		xmlns:xq="java:Xq2xml"
		exclude-result-prefixes="#all">
  <xsl:param name="xq" select="'&lt;error/&gt;'"/>
  <xsl:param name="dump" select="'no'"/>
  
  <xsl:namespace-alias stylesheet-prefix="axsl" result-prefix="xsl"/>
  
  <xsl:output method="xml"  omit-xml-declaration="yes" encoding="US-ASCII" indent="yes"/>
  
  <!--
      Initial template, processes the query in the document specified in the global xq
      parameter. Dumps the intermediate xml if the dump parameter is set.
  -->
  
  <xsl:key name="vref" match="PathExpr/VarName|StepExpr/VarName" use="QName/data"/>
  
  
  <!-- orderBy59 -->
  <xsl:template name="main">
    <xsl:variable name="xqtext" select="replace(unparsed-text($xq,'utf-8'),'&#13;&#10;','&#10;')"/>
    <xsl:variable name="xqxml1" select="xq:convert($xqtext)"/>
    <!--
	parser sometimes has problems with comments, so if an error is reported, zap
	(3 levels of) comments and try again.
    -->
    <xsl:variable name="xqxml" select="saxon:parse(
				       if (starts-with($xqxml1,'&lt;error')) then 
				       xq:convert(replace(replace(replace($xqtext,'\(:[^:]*([^\(]:[^\)][^:]*)*:\)',''),'\(:[^:]*([^\(]:[^\)][^:]*)*:\)',''),'\(:[^:]*([^\(]:[^\)][^:]*)*:\)','')) else
				       $xqxml1)"/>
    <xsl:if test="$dump!='no'">
      <xsl:result-document href="temp.xml" indent="no">
	<xsl:copy-of select="$xqxml"/>
      </xsl:result-document>
    </xsl:if>
    <xsl:result-document href="{replace($xq,'\.[a-z]*$','')}.xsl">
      <xsl:apply-templates select="$xqxml"/>
    </xsl:result-document>
  </xsl:template>
  
  
  <!--===================-->
  
  <!--
      The XQuery EBNF.
      The first two productions are not offical but are eported by the XQuery Parser QueryList is
      translated to the nonstandard xqx:queryList if it contains more than one module, this allows
      multiple queries in the same xqx document.
  -->
  
  
  <!-- [-1] XPath2 ::=
       QueryList
  -->
  
  <xsl:template match="XPath2">
    <xsl:apply-templates select="*" mode="xslt"/>
  </xsl:template>
  
  <xsl:template match="XPath2" mode="xslt">
    <xsl:apply-templates select="*" mode="xslt"/>
  </xsl:template>
  
  
  <!-- [0] QueryList ::=
       Module+
  -->
  
  
  <xsl:template match="QueryList"  mode="xslt">
    <xsl:apply-templates select="*" mode="xslt"/>
  </xsl:template>
  
  <!-- [1] Module ::=
       VersionDecl? (MainModule | LibraryModule)
  -->
  
  <xsl:template match="Module" mode="xslt">
    <xsl:variable name="prolog" select="*/Prolog"/>
    <axsl:stylesheet version="2.0"
		     extension-element-prefixes="xq"
		     exclude-result-prefixes="{('xq','xs','xsi','xdt','local','fn')
  [not(.=$prolog/NamespaceDecl[string-length(URILiteral/StringLiteral/data)=2]/NCName/data)]}">

      <xsl:namespace name="xq" select="'java:Xq2xml'"/>

      <xsl:apply-templates select="LibraryModule/ModuleDecl|*/Prolog" mode="ns"/>
      <xsl:apply-templates select="*/Prolog/Import/ModuleImport" mode="xslt"/>


      <xsl:variable name="query">
	<xsl:apply-templates select="*" mode="xslt">
	  <xsl:with-param name="functionns"
			  select="*/Prolog/DefaultNamespaceDecl[data='function']/URILiteral/StringLiteral/substring(data,2,string-length(data)-2)" tunnel="yes"/>
	  <xsl:with-param name="emptygreatest"
			  select="*/Prolog/Setter/EmptyOrderDecl/Greatest" tunnel="yes"/>
	  <xsl:with-param name="noinherit" as="attribute()?" tunnel="yes">
	    <xsl:if test="*/Prolog/Setter/CopyNamespacesDecl/InheritMode/data='no-inherit'">
	      <xsl:attribute name="inherit-namespaces" select="'no'"/>
	    </xsl:if>
	  </xsl:with-param>
	  <xsl:with-param name="nopreserve" as="xs:boolean" tunnel="yes" select=
			  "exists(*/Prolog/Setter/CopyNamespacesDecl/PreserveMode[data='no-preserve'])"/>
	  <xsl:with-param name="preservespace" as="xs:boolean" tunnel="yes" select=
			  "exists(*/Prolog/Setter/BoundarySpaceDecl[data='preserve'])"/>
	</xsl:apply-templates>
      </xsl:variable>
<!--
      <xsl:result-document href="p2.xml">
	<xsl:copy-of select="$query"/>
      </xsl:result-document>
-->
      <xsl:apply-templates mode="p2" select="$query"/>
      <xsl:text>&#10;&#10;</xsl:text>
      <xsl:apply-templates select="$query//xsl:select/xsl:function" mode="p3"/>

    </axsl:stylesheet>
    <xsl:text>&#10;</xsl:text>

  </xsl:template>


  <!-- [2] VersionDecl ::=
       <"xquery" "version"> StringLiteral ("encoding" StringLiteral)? Separator
  -->

  <xsl:template match="VersionDecl" mode="xslt"/>


  <!-- [3] MainModule ::=
       Prolog QueryBody
  -->

  <xsl:template match="MainModule" mode="xslt">
    <axsl:output indent="yes"/>
    <axsl:param name="input" as="item()" select="1"/>
    <axsl:param name="xq:empty"  select="()"/>
    <xsl:apply-templates select="*" mode="xslt"/>
    <xsl:if test=".//FunctionCall[$basic='yes'][FunctionQName/data][key('builtintypes',FunctionQName/data, $primtypes)/parent::xs:integer]">
      <axsl:function name="xq:integer">
	<xsl:namespace name="xs" select="'http://www.w3.org/2001/XMLSchema'"/>
	<axsl:param name="x"/>
	<axsl:param name="min" as="xs:integer"/>
	<axsl:param name="max" as="xs:integer"/>
	<axsl:variable name="v" select="xs:integer($x)"/>
	<axsl:sequence select="if (
			       (if ($min!=9) then ($min&lt;=$v) else true())
			       and
			       (if ($max!=9) then ($max&gt;=$v) else true()))
			       then $v
			       else error(QName('http://www.w3.org/2005/xqt-errors','FORG0001'),'built in type range')"/>
      </axsl:function>
    </xsl:if>
    
  </xsl:template>


  <!-- [4] LibraryModule ::=
       ModuleDecl Prolog
  -->

  <xsl:template match="LibraryModule" mode="xslt">
    <xsl:apply-templates select="*" mode="xslt"/>
  </xsl:template>


  <!-- [5] ModuleDecl ::=
       <"module" "namespace"> NCName "=" URILiteral Separator
  -->

  <xsl:template match="ModuleDecl" mode="xslt"/>


  <!-- [6] Prolog ::=
       ((Setter | Import | NamespaceDecl | DefaultNamespaceDecl) Separator)* 
       ((VarDecl | FunctionDecl | OptionDecl) Separator)*
  -->

  <xsl:template match="Prolog" mode="ns">
    <xsl:apply-templates select="*|Setter/*|Import/*" mode="ns"/>
    <xsl:if test="not(NamespaceDecl/NCName[.='xs'])">
      <xsl:namespace name="xs" select="'http://www.w3.org/2001/XMLSchema'"/>
    </xsl:if>
    <xsl:if test="not(NamespaceDecl/NCName[.='local'])">
      <xsl:namespace name="local" select="'http://www.w3.org/2005/xquery-local-functions'"/>
    </xsl:if>
    <xsl:if test="not(NamespaceDecl/NCName[.='fn'])">
      <xsl:namespace name="fn" select="'http://www.w3.org/2005/xpath-functions'"/>
    </xsl:if>
    <xsl:if test="not(NamespaceDecl/NCName[.='xdt'])">
      <xsl:namespace name="xdt" select="'http://www.w3.org/2005/xpath-datatypes'"/>
    </xsl:if>
    <xsl:if test="not(NamespaceDecl/NCName[.='xsi'])">
      <xsl:namespace name="xsi" select="'http://www.w3.org/2001/XMLSchema-instance'"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="Prolog" mode="xslt">
    <xsl:apply-templates select="*" mode="xslt"/>
  </xsl:template>


  <!-- [7] Setter ::=
       BoundarySpaceDecl | DefaultCollationDecl | BaseURIDecl | ConstructionDecl |
       OrderingModeDecl | EmptyOrderDecl | CopyNamespacesDecl
  -->

   <xsl:template match="Setter" mode="xslt">
    <xsl:apply-templates select="*" mode="xslt"/>
  </xsl:template>

  <!-- [8] Import ::=
       SchemaImport | ModuleImport
  -->

  <!-- module import handled earlier (xsl:import has to come first) -->
  <xsl:template match="Import" mode="xslt">
    <xsl:apply-templates select="SchemaImport" mode="xslt"/>
  </xsl:template>


  <!-- [9] Separator ::=
       ";"
  -->

  <xsl:template match="Separator" mode="xslt"/>

  <!-- [10] NamespaceDecl ::=
       <"declare" "namespace"> NCName "=" URILiteral
  -->
  <xsl:template match="*" mode="ns"/>


  <xsl:template match="NamespaceDecl" mode="xslt"/>

  <xsl:template match="NamespaceDecl" mode="ns">
    <xsl:variable name="ns" select="xq:chars(substring(URILiteral/StringLiteral/data,2,string-length(URILiteral/StringLiteral/data)-2))"/>
    <xsl:if test="not($ns=('','http://www.w3.org/XML/1998/namespace')) and not(NCName/data=('xml','xmlns'))">
      <xsl:namespace name="{NCName/data}" select="$ns"/>
    </xsl:if>
  </xsl:template>

  <!-- [11] BoundarySpaceDecl ::=
       <"declare" "boundary-space"> ("preserve" | "strip")
  -->

  <xsl:template match="BoundarySpaceDecl" mode="xslt"/>


  <!-- [12] DefaultNamespaceDecl ::=
       (<"declare" "default" "element"> | <"declare" "default" "function">)
       "namespace" URILiteral
  -->

  <xsl:template match="DefaultNamespaceDecl" mode="xslt"/>

  <xsl:template match="DefaultNamespaceDecl[data='element']" mode="ns">
    <xsl:namespace name="" select="substring(URILiteral/StringLiteral/data,2,string-length(URILiteral/StringLiteral/data)-2)"/>
    <xsl:attribute name="xpath-default-namespace"
		   select="substring(URILiteral/StringLiteral/data,2,string-length(URILiteral/StringLiteral/data)-2)"/>
  </xsl:template>

  <xsl:template match="DefaultNamespaceDecl[data='function']" mode="ns">
    <xsl:variable name="functionns" select="substring(URILiteral/StringLiteral/data,2,string-length(URILiteral/StringLiteral/data)-2)"/>
    <xsl:if test="not(URILiteral/StringLiteral/data=$functionns)">
      <xsl:namespace name="default-function-namespace" select="if ($functionns) then $functionns else 'java:Xq2xml'"/>
      <xsl:attribute name="exclude-result-prefixes" select="'default-function-namespace xq xs xdt local'"/>
    </xsl:if>
  </xsl:template>


  <!-- [13] OptionDecl ::=
       <"declare" "option"> QName StringLiteral
  -->

  <xsl:template match="OptionDecl" mode="xslt">
    <xq:option name="{QName/data}">
      <xsl:value-of select="substring(StringLiteral/data,2,string-length(StringLiteral/data)-2)"/>
    </xq:option>
  </xsl:template>

  <!-- [14] OrderingModeDecl ::=
       <"declare" "ordering"> ("ordered" | "unordered")
  -->

  <xsl:template match="OrderingModeDecl"  mode="xslt"/>


  <!-- [15] EmptyOrderDecl ::=
       <"declare" "default" "order"> (<"empty" "greatest"> | <"empty" "least">)
  -->

  <xsl:template match="EmptyOrderDecl" mode="xslt"/>



  <!-- [16] CopyNamespacesDecl ::=
       <"declare" "copy-namespaces"> PreserveMode "," InheritMode
  -->

  <xsl:template match="CopyNamespacesDecl" mode="xslt"/>



  <!-- [17] PreserveMode ::=
       "preserve" | "no-preserve"
  -->

  <xsl:template match="PreserveMode" mode="xslt"/>

  <!-- [18] InheritMode ::=
       "inherit" | "no-inherit"
  -->

  <xsl:template match="InheritMode" mode="xslt"/>

  <!-- [19] DefaultCollationDecl ::=
       <"declare" "default" "collation"> URILiteral
  -->

  <xsl:template match="DefaultCollationDecl" mode="xslt"/>
  <xsl:template match="DefaultCollationDecl" mode="ns">
    <xsl:attribute name="default-collation"
		   select="substring(URILiteral/StringLiteral/data,2,string-length(URILiteral/StringLiteral/data)-2)"/>
  </xsl:template>


  <!-- [20] BaseURIDecl ::=
       <"declare" "base-uri"> URILiteral
  -->

  <xsl:template match="BaseURIDecl" mode="xslt"/>
  <xsl:template match="BaseURIDecl" mode="ns">
    <xsl:variable name="q" select="substring(URILiteral/StringLiteral/data,1,1)"/>
    <xsl:attribute name="xml:base"
		   select="replace(substring(URILiteral/StringLiteral/data,2,string-length(URILiteral/StringLiteral/data)-2)
                   ,concat($q,$q),$q)"/>
  </xsl:template>

  <!-- [21] SchemaImport ::=
       <"import" "schema"> SchemaPrefix? URILiteral
       (<"at" URILiteral> ("," URILiteral)*)?
  -->

  <xsl:template match="SchemaImport" mode="xslt">
    <xsl:variable name="ns" select="substring(URILiteral[1]/StringLiteral/data,2,string-length(URILiteral[1]/StringLiteral/data)-2)"/>
    <xsl:variable name="at" select="substring(URILiteral[2]/StringLiteral/data,2,string-length(URILiteral[2]/StringLiteral/data)-2)"/>
    <!--
	<xsl:namespace name="yyy" select="'xxx'"/>
    -->
    <xsl:choose>
      <xsl:when test="URILiteral[2]">
	<xsl:for-each select="URILiteral[position()!=1]/StringLiteral/data">
	  <axsl:import-schema namespace="{$ns}" schema-location="{substring(.,2,string-length(.)-2)}"/>
	</xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
	<axsl:import-schema namespace="{$ns}"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="SchemaImport" mode="ns">
    <xsl:namespace name="{SchemaPrefix/NCName/data}" select="substring(URILiteral[1]/StringLiteral/data,2,string-length(URILiteral[1]/StringLiteral/data)-2)"/>
    <xsl:if test="not(SchemaPrefix/NCName)">
      <xsl:attribute name="xpath-default-namespace" select="substring(URILiteral[1]/StringLiteral/data,2,string-length(URILiteral[1]/StringLiteral/data)-2)"/>
    </xsl:if>
  </xsl:template>

  <!-- [22] SchemaPrefix ::=
       ("namespace" NCName "=") | (<"default" "element"> "namespace")
  -->


  <!-- [23] ModuleImport ::=
       <"import" "module"> ("namespace" NCName "=")? URILiteral
       (<"at" URILiteral> ("," URILiteral)*)?
  -->


  <xsl:template match="ModuleImport" mode="xslt">
    <xsl:variable name="ns" select="substring(URILiteral[1]/StringLiteral/data,2,string-length(URILiteral[1]/StringLiteral/data)-2)"/>
    <!--
	<xsl:namespace name="yyy" select="'xxx'"/>
    -->
    <xsl:choose>
      <xsl:when test="URILiteral[2]">
	<xsl:for-each select="URILiteral[position()!=1]/StringLiteral/data">
	  <axsl:include href="{concat(replace(substring(.,2,string-length(.)-2),'\.xq',''),'.xsl')}"/>
	</xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
	<axsl:include href="{$ns}"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="ModuleImport|ModuleDecl" mode="ns">
    <xsl:variable name="u" select="substring(URILiteral[1]/StringLiteral/data,2,string-length(URILiteral[1]/StringLiteral/data)-2)"/>
<xsl:if test="not(NCName/data='xml') and $u">
    <xsl:namespace name="{NCName/data}" select="$u"/>
</xsl:if>
</xsl:template>

  <!-- [24] VarDecl ::=
       <"declare" "variable" "$"> VarName TypeDeclaration?
       ((":=" ExprSingle) | "external")
  -->


  <xsl:template match="VarDecl[External]" mode="xslt">
    <axsl:param name="{QName/data}" as="item()*">
      <xsl:apply-templates select="TypeDeclaration/SequenceType" mode="xslt"/>
    </axsl:param>
  </xsl:template>

  <xsl:template match="VarDecl" mode="xslt">
    <axsl:variable name="{QName/data}" as="item()*">
      <xsl:apply-templates select="TypeDeclaration/SequenceType" mode="xslt"/>
      <axsl:for-each select="$input">
	<xsl:apply-templates select="*[last()]" mode="xslt"/>
      </axsl:for-each>
    </axsl:variable>
  </xsl:template>




  <!-- [25] ConstructionDecl ::=
       <"declare" "construction"> ("preserve" | "strip")
  -->

  <xsl:template match="ConstructionDecl" mode="xslt"/>


  <!-- [26] FunctionDecl ::=
       <"declare" "function"> <QName "("> ParamList? 
       (")" |   (<")" "as"> SequenceType))
       (EnclosedExpr | "external")
  -->


  <xsl:template match="FunctionDecl" mode="xslt">
    <xsl:param name="functionns" tunnel="yes"/>
    <axsl:function name="{if($functionns and not(contains(QName,':'))) then 'default-function-namespace:' else ''}{QName}" as="item()*">
      <xsl:apply-templates select="SequenceType" mode="xslt"/>
      <xsl:apply-templates select="ParamList/Param" mode="xslt"/>
      <!-- not really right: current item should be undefined
	   but that would mean tracking context for use of xq:here eleewhere
	   this should be OK except in error cases
	   Just do this if there is a FLWOR in the function body
      -->
      <xsl:choose>
	<xsl:when test="EnclosedExpr//FLWORExpr">
	  <axsl:for-each select="$input">
	    <xsl:apply-templates select="EnclosedExpr" mode="xslt"/>
	  </axsl:for-each>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:apply-templates select="EnclosedExpr" mode="xslt"/>	  
	</xsl:otherwise>
      </xsl:choose>
    </axsl:function>
  </xsl:template>

  <xsl:template match="FunctionDecl[External]" mode="xslt"/>

  <!-- [27] ParamList ::=
       Param ("," Param)*
  -->

  <xsl:template match="ParamList" mode="xslt"/>

  <!-- [28] Param ::=
       "$" VarName TypeDeclaration?
  -->


  <xsl:template match="Param" mode="xslt">
    <axsl:param name="{QName/data}" as="item()*">
      <xsl:apply-templates select="TypeDeclaration/SequenceType" mode="xslt"/>
    </axsl:param>
  </xsl:template>


  <!-- [29] EnclosedExpr ::=
       "{" Expr "}"
  -->

  <xsl:template match="EnclosedExpr" mode="xslt">
    <xsl:apply-templates select="Expr" mode="xslt"/>
  </xsl:template>

  <!-- not sure this can happen 
       <xsl:template match="DirElemConstructor/EnclosedExpr[following-sibling::*]" mode="xslt">
       <xsl:apply-templates select="Expr" mode="xslt"/>
       <axsl:text/>
       </xsl:template>
  -->
  <xsl:template match="DirElemContent/CommonContent/EnclosedExpr" mode="xslt">
    <xsl:param name="nopreserve" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="$nopreserve">
	<axsl:variable name="content" as="item()*">
	  <xsl:apply-templates select="Expr" mode="xslt"/>
	</axsl:variable>
	<axsl:copy-of select="$content" copy-namespaces="no" />
      </xsl:when>
      <xsl:otherwise>
	<xsl:apply-templates select="Expr" mode="xslt"/>
      </xsl:otherwise>
    </xsl:choose>
    <axsl:text/>
  </xsl:template>

  <xsl:template match="DirAttributeValue/*/*/EnclosedExpr" mode="xslt">
    <axsl:value-of separator=" "><xsl:apply-templates select="Expr" mode="xslt"/></axsl:value-of>
  </xsl:template>


  <!-- [30] QueryBody ::=
       Expr
  -->

  <xsl:template match="QueryBody" mode="xslt">
    <axsl:template name="main">
      <axsl:for-each select="$input">
	<xsl:apply-templates select="*" mode="xslt"/>
      </axsl:for-each>
    </axsl:template>
  </xsl:template>

  <xsl:template match="node()" mode="p2 p3">
<!--
<xsl:message>
===  <xsl:copy-of select=".."/>===
</xsl:message>
-->
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="p2"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="/xsl:function[.//xsl:function]" mode="p2">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="p2" select="xsl:param"/>
      <axsl:for-each select="$input">
	<xsl:apply-templates mode="p2" select="* except xsl:param"/>
      </axsl:for-each>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="xsl:select" mode="p2 p3">
    <xsl:attribute name="select">
      <xsl:apply-templates mode="p2"/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="xsl:if/xsl:select" mode="p2 p3">
    <xsl:attribute name="test">
      <xsl:apply-templates mode="p2"/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="xsl:select/xsl:function" mode="p2">
    <xsl:value-of select="@name"/>
    <xsl:text>(.</xsl:text>
    <xsl:for-each select="xsl:param[position()!=1]">
      <xsl:text>,$</xsl:text>
      <xsl:value-of select="@name"/>
    </xsl:for-each>
    <xsl:text>)</xsl:text>
  </xsl:template>







  <xsl:template match="*" mode="xslt">
    <xsl:text>&#10;</xsl:text><xsl:comment><xsl:value-of select="name()"/></xsl:comment>
    <xsl:message terminate="yes"> unexpected element in xslt: <xsl:copy-of select="."/> </xsl:message>
  </xsl:template>



  <!-- [31] Expr ::=
       ExprSingle ("," ExprSingle)*
  -->

  <xsl:template match="Expr" mode="xpath">
    <xsl:for-each select="*">
      <xsl:apply-templates select="." mode="xpath"/>
      <xsl:if test="position()!=last()">,</xsl:if>
    </xsl:for-each>
  </xsl:template>


  <xsl:template match="Expr" mode="xslt">
    <xsl:apply-templates select="*" mode="xslt"/>
  </xsl:template>


  <!-- [32] ExprSingle ::=
       FLWORExpr | QuantifiedExpr | TypeswitchExpr | IfExpr | OrExpr
  -->

  <!-- Not reported by the parser. -->

  <!-- [33] FLWORExpr ::=
       (ForClause | LetClause)+ WhereClause? OrderByClause? "return" ExprSingle
  -->

  <xsl:template match="FLWORExpr[not(ForClause/PositionalVar|TypeDeclaration|LetClause|WhereClause|OrderByClause)]" mode="xpath">
    <xsl:text> for </xsl:text>
    <xsl:for-each select="ForClause/VarName">
      <xsl:if test="position()!=1">, </xsl:if>
      <xsl:text>$</xsl:text>
      <xsl:value-of select="QName/data"/>
      <xsl:text> in </xsl:text>
      <xsl:apply-templates select="following-sibling::*[not(self::TypeDeclaration)][1]" mode="xpath"/>
    </xsl:for-each>
    <xsl:text> return </xsl:text>
    <xsl:apply-templates select="*[last()]" mode="xpath"/>
  </xsl:template>


  <xsl:template match="FLWORExpr" mode="xslt">
    <xsl:param name="here" select="true()"/>
    <xsl:if test="$here">
      <axsl:variable name="xq:here" select="{if (parent::VarDecl) then '$input' else '.'}"/>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="*[1][self::LetClause]">
	<axsl:if test="true()">
	  <xsl:apply-templates select="(ForClause|LetClause)[1]" mode="xslt"/>
	</axsl:if>
      </xsl:when>
      <xsl:otherwise>
	<xsl:apply-templates select="(ForClause|LetClause)[1]" mode="xslt"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="FLWORExpr[OrderByClause][(ForClause/VarName)[2]|LetClause]" mode="xslt" priority="2">
    <xsl:param name="emptygreatest" tunnel="yes"/>
    <axsl:variable name="xq:here" select="{if (parent::VarDecl) then '$input' else '.'}"/>
    <xsl:variable name="for1">
      <axsl:variable name="xq:forc" as="xs:string*">
	<xsl:apply-templates select="(ForClause|LetClause)[1]" mode="xsltc"/>
      </axsl:variable>
    </xsl:variable>
    <xsl:sequence select="$for1/*"/>
    <xsl:variable name="vars">
      <xsl:apply-templates select="$for1/*/*" mode="xsltc2"/>
    </xsl:variable>
    <axsl:for-each select="$xq:forc">
      <xsl:for-each select="OrderByClause/OrderSpecList/OrderSpec">
	<xsl:variable name="sorttemp">
	  <axsl:sort collation="http://www.w3.org/2005/xpath-functions/collation/codepoint">
	    <xsl:if test="OrderModifier/Descending">
	      <xsl:attribute name="order">descending</xsl:attribute>
	    </xsl:if>
	    <xsl:apply-templates select="OrderModifier/URILiteral" mode="xslt"/>
	    <axsl:select>
	      <axsl:function name="xq:orderby_{generate-id()}" as="item()*">
		<axsl:param name="xq:here"/>
		<xsl:for-each select="distinct-values(
    ( ../../ancestor::*[parent::FLWORExpr or parent::ForClause or parent::LetClause or parent::QuantifiedExpr]
   /(preceding-sibling::VarName|preceding-sibling::ForClause/(VarName|PositionalVar/VarName)|preceding-sibling::LetClause/VarName),
  ancestor::FunctionDecl/ParamList/Param)
  /QName/data[key('vref','u',current()/../../..)]
)">
		  <axsl:param name="{.}"/>
		</xsl:for-each>
		<axsl:for-each select="$xq:here">
		  <axsl:variable name="xq:index" select="for $i in string-to-codepoints(.) return($i - 32)"/>
		  <xsl:copy-of select="$vars"/>
		  <xsl:apply-templates select="*[1]" mode="xslt"/>
		</axsl:for-each>
	      </axsl:function>
	    </axsl:select>
	  </axsl:sort>
	</xsl:variable>
	<xsl:if test="OrderModifier/Greatest or ($emptygreatest and not(OrderModifier/Least))">
	  <axsl:sort collation="http://www.w3.org/2005/xpath-functions/collation/codepoint">
	    <xsl:copy-of select="@*"/>
	    <xsl:if test="OrderModifier/Descending">
	      <xsl:attribute name="order">descending</xsl:attribute>
	    </xsl:if>
	    <xsl:apply-templates select="OrderModifier/URILiteral" mode="xslt"/>
	    <xsl:attribute name="select">
	      <xsl:text>empty(</xsl:text>
	      <xsl:apply-templates mode="p2" select="$sorttemp/xsl:sort/xsl:select/node()"/>
	      <xsl:text>)</xsl:text>
	    </xsl:attribute>
	  </axsl:sort>
	  <axsl:sort collation="http://www.w3.org/2005/xpath-functions/collation/codepoint">
	    <xsl:copy-of select="@*"/>
	    <xsl:if test="OrderModifier/Descending">
	      <xsl:attribute name="order">descending</xsl:attribute>
	    </xsl:if>
	    <xsl:apply-templates select="OrderModifier/URILiteral" mode="xslt"/>
	    <xsl:attribute name="select">
	      <xsl:text>for $xq:j in(</xsl:text>
	      <xsl:apply-templates mode="p2" select="$sorttemp/xsl:sort/xsl:select/node()"/>
	      <xsl:text>) return (($xq:j instance of xs:double and not($xq:j = $xq:j)))</xsl:text>
	    </xsl:attribute>
	  </axsl:sort>
	</xsl:if>
	<xsl:copy-of select="$sorttemp"/>
      </xsl:for-each>
      <axsl:variable name="xq:index" select="for $i in string-to-codepoints(.) return($i - 32)"/>
      <axsl:for-each select="$xq:here">
	<xsl:copy-of select="$vars"/>
	<xsl:apply-templates select="*[last()]" mode="xslt"/>
      </axsl:for-each>
    </axsl:for-each>
  </xsl:template>


  <xsl:template match="*" mode="xsltc2">
    <xsl:message terminate="yes"> unexpected element in xsltc2: </xsl:message>
  </xsl:template>

  <xsl:template match="xsl:for-each" mode="xsltc2">
    <xsl:apply-templates select="*" mode="xsltc2"/>
  </xsl:template>
  <xsl:template match="xsl:select" mode="xsltc2"/>

  <xsl:template match="xsl:variable[@select='.']" mode="xsltc2">
    <axsl:variable name="xq:p{count(ancestor::xsl:for-each)}" select="$xq:index[{count(ancestor::xsl:for-each)}]"/>
    <axsl:variable name="{@name}">
      <xsl:attribute name="select">
	<xsl:text>(</xsl:text>
	<xsl:apply-templates mode="p2" select="preceding-sibling::xsl:select[1]/node()"/>
	<xsl:text>)[$xq:p</xsl:text>
	<xsl:value-of select="count(ancestor::xsl:for-each)"/>
	<xsl:text>]</xsl:text>
      </xsl:attribute>
    </axsl:variable>
  </xsl:template>

  <xsl:template match="xsl:variable[@select='position()']" mode="xsltc2"/>

  <xsl:template match="xsl:variable" mode="xsltc2">
    <xsl:copy-of select="."/>
  </xsl:template>

  <xsl:template match="xsl:sequence" mode="xsltc2"/>
  <xsl:template match="xsl:if" mode="xsltc2"/>


  <!-- [34] ForClause ::=
       <"for" "$"> VarName TypeDeclaration? PositionalVar? "in"
       ExprSingle ("," "$" VarName TypeDeclaration? PositionalVar? "in"
       ExprSingle)*
  -->

  <xsl:template match="ForClause" mode="xslt">
    <xsl:apply-templates select="VarName[1]" mode="xslt"/>
  </xsl:template>

  <xsl:template match="ForClause/VarName" mode="xslt">
    <axsl:for-each>
      <axsl:select>
	<xsl:apply-templates select="following-sibling::*[not(self::PositionalVar or self::TypeDeclaration)][1]" mode="xpath"/>
      </axsl:select>
      <xsl:apply-templates select="../following-sibling::OrderByClause/OrderSpecList/OrderSpec" mode="xslt">
	<xsl:with-param name="var" select="QName/data"/>
      </xsl:apply-templates>
      <axsl:variable name="{QName/data}" select=".">
	<xsl:for-each select="following-sibling::*[1][self::TypeDeclaration]">
	  <xsl:attribute name="select">
	    <xsl:text>. treat as </xsl:text>
	    <xsl:apply-templates select="SequenceType" mode="xpath"/>
	  </xsl:attribute>
	  <xsl:apply-templates select="SequenceType" mode="xslt"/>
	</xsl:for-each>
      </axsl:variable>
      <xsl:apply-templates select="following-sibling::*[position()&lt;3][self::PositionalVar]" mode="xslt"/>
      <xsl:apply-templates select="(following-sibling::VarName|../following-sibling::*[self::ForClause|self::LetClause|self::WhereClause])[1]" mode="xslt"/>
      <xsl:if test="not(following-sibling::VarName|../following-sibling::*[(self::ForClause|self::LetClause|self::WhereClause)])">
	<axsl:for-each select="$xq:here">
	  <xsl:apply-templates select="../following-sibling::*[last()]" mode="xslt"/>
	</axsl:for-each>
      </xsl:if>
    </axsl:for-each>
  </xsl:template>


  <xsl:template match="ForClause" mode="xsltc">
    <xsl:apply-templates select="VarName[1]" mode="xsltc"/>
  </xsl:template>

  <xsl:template match="ForClause/VarName" mode="xsltc">
    <axsl:for-each>
      <axsl:select>
	<xsl:apply-templates select="following-sibling::*[not(self::PositionalVar or self::TypeDeclaration)][1]" mode="xpath"/>
      </axsl:select>
      <axsl:variable name="{QName/data}" select="."/>
      <xsl:variable name="varn" select="count(preceding-sibling::VarName)+ count(../preceding-sibling::ForClause/VarName) + 1"/>
      <axsl:variable name="xq:p{$varn}" select="position()"/>
      <xsl:for-each select="following-sibling::*[position()&lt;2][self::PositionalVar]">
	<axsl:variable name="{VarName/QName/data}" select="$xq:p{$varn}"/>
      </xsl:for-each>
      <xsl:apply-templates select="(following-sibling::VarName|../following-sibling::*[self::ForClause|self::LetClause|self::WhereClause])[1]" mode="xsltc"/>
      <xsl:if test="not(following-sibling::VarName|../following-sibling::*[(self::ForClause|self::LetClause|self::WhereClause)])">
	<axsl:sequence select="codepoints-to-string(({string-join(
			       for $v in (1 to $varn) return concat('$xq:p',$v,'+32'),',')}))"/>
      </xsl:if>
    </axsl:for-each>
  </xsl:template>

  <!-- [35] PositionalVar ::=
       "at" "$" VarName
  -->

  <xsl:template match="PositionalVar" mode="xslt">
    <axsl:variable name="{VarName/QName/data}" select="position()"/>
  </xsl:template>


  <!-- [36] LetClause ::=
       <"let" "$"> VarName TypeDeclaration? ":=" ExprSingle 
       ("," "$" VarName TypeDeclaration? ":=" ExprSingle)*
  -->

  <xsl:template match="LetClause" mode="xslt">
    <xsl:for-each select="VarName">
      <axsl:variable as="item()*" name="{QName/data}">
	<xsl:apply-templates select="following-sibling::*[1][self::TypeDeclaration]/SequenceType" mode="xslt"/>
	<xsl:variable name="content" as="item()*">
	  <xsl:apply-templates select="following-sibling::*[not(self::TypeDeclaration)][1]" mode="xslt"/>
	</xsl:variable>
<!--
<xsl:message>
[[[

<xsl:copy-of select="following-sibling::*[not(self::TypeDeclaration)][1]/name()" />

]]]
</xsl:message>
-->
<!--
<xsl:message>
<x>  <xsl:copy-of select="$content"/> </x>
</xsl:message>
-->
<xsl:choose>
	  <xsl:when test="$content[not(self::xsl:sequence)]">
	    <xsl:sequence select="$content"/>
</xsl:when>
	  <xsl:otherwise>
	    <axsl:select>
	      <xsl:sequence select="('(',$content[1]/xsl:select/node(),for $e in $content[position()!=1] return (',',$e/xsl:select/node()),')')"/>
</axsl:select>
	  </xsl:otherwise>
	</xsl:choose>
</axsl:variable>
    </xsl:for-each>
    <xsl:apply-templates select="following-sibling::*[(self::ForClause|self::LetClause|self::WhereClause)][1]" mode="xslt"/>
    <xsl:if test="not(following-sibling::*[(self::ForClause|self::LetClause|self::WhereClause)])">
      <axsl:for-each select="$xq:here">
	<xsl:apply-templates select="following-sibling::*[last()]" mode="xslt"/>
      </axsl:for-each>
    </xsl:if>
  </xsl:template>

  <xsl:template match="LetClause" mode="xsltc">
    <xsl:for-each select="VarName">
      <axsl:variable as="item()*" name="{QName/data}">
	<xsl:variable name="content" as="item()*">
	  <xsl:apply-templates select="following-sibling::*[not(self::TypeDeclaration)][1]" mode="xslt"/>
	</xsl:variable>
	<xsl:choose>
	  <xsl:when test="$content[not(self::xsl:sequence)]">
	    <xsl:sequence select="$content"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <axsl:select>
	      <xsl:sequence select="('(',$content[1]/xsl:select/node(),for $e in $content[position()!=1] return (',',$e/xsl:select/node()),')')"/>
	    </axsl:select>
	  </xsl:otherwise>
	</xsl:choose>
      </axsl:variable>
    </xsl:for-each>
    <xsl:apply-templates select="following-sibling::*[(self::ForClause|self::LetClause|self::WhereClause)][1]" mode="xsltc"/>
    <xsl:if test="not(following-sibling::*[(self::ForClause|self::LetClause|self::WhereClause)])">
      <xsl:variable name="varn" select="count(preceding-sibling::ForClause/VarName)"/>
      <axsl:sequence select="codepoints-to-string(({string-join(
			     for $v in (1 to $varn) return concat('$xq:p',$v,'+32'),',')}))"/>
    </xsl:if>
  </xsl:template>

  <!-- [37] WhereClause ::=
       "where" ExprSingle
  -->

  <xsl:template match="WhereClause" mode="xslt">
    <axsl:if>
      <axsl:select>
	<xsl:apply-templates select="*" mode="xpath"/>
      </axsl:select>
      <axsl:for-each select="$xq:here">
	<xsl:apply-templates select="following-sibling::*[last()]" mode="xslt"/>
      </axsl:for-each>
    </axsl:if>
  </xsl:template>

  <xsl:template match="WhereClause" mode="xsltc">
    <axsl:if>
      <xsl:attribute name="test">
	<xsl:apply-templates select="*" mode="xpath"/>
      </xsl:attribute>
      <xsl:variable name="varn" select="count(preceding-sibling::ForClause/VarName)"/>
      <axsl:sequence select="codepoints-to-string(({string-join(
			     for $v in (1 to $varn) return concat('$xq:p',$v,'+32'),',')}))"/>
    </axsl:if>
  </xsl:template>

  <!-- [38] OrderByClause ::=
       (<"order" "by"> | <"stable" "order" "by">) OrderSpecList
  -->


  <!-- [39] OrderSpecList ::=
       OrderSpec ("," OrderSpec)*
  -->

  <!-- [40] OrderSpec ::=
       ExprSingle OrderModifier
  -->

  <xsl:template match="OrderSpec" mode="xslt">
    <xsl:param name="emptygreatest" tunnel="yes"/>
    <xsl:param name="var"/>
    <xsl:variable name="sorttemp">
      <axsl:sort collation="http://www.w3.org/2005/xpath-functions/collation/codepoint">
	<xsl:if test="OrderModifier/Descending">
	  <xsl:attribute name="order">descending</xsl:attribute>
	</xsl:if>
	<xsl:apply-templates select="OrderModifier/URILiteral" mode="xslt"/>
	<axsl:select>
	  <xsl:text>for $</xsl:text>
	  <xsl:value-of select="$var"/>
	  <xsl:text> in . return (</xsl:text>
	  <xsl:apply-templates select="*[1]" mode="xpath"/>
	  <xsl:text>)</xsl:text>
	</axsl:select>
      </axsl:sort>
    </xsl:variable>
    <xsl:if test="OrderModifier/Greatest or ($emptygreatest and not(OrderModifier/Least))">
      <axsl:sort collation="http://www.w3.org/2005/xpath-functions/collation/codepoint">
	<xsl:if test="OrderModifier/Descending">
	  <xsl:attribute name="order">descending</xsl:attribute>
	</xsl:if>
	<xsl:apply-templates select="OrderModifier/URILiteral" mode="xslt"/>
	<xsl:copy-of select="@*"/>
	<xsl:attribute name="select">
	  <xsl:text>empty(</xsl:text>
	  <xsl:apply-templates mode="p2" select="$sorttemp/xsl:sort/xsl:select/node()"/>
	  <xsl:text>)</xsl:text>
	</xsl:attribute>
      </axsl:sort>
      <axsl:sort collation="http://www.w3.org/2005/xpath-functions/collation/codepoint">
	<xsl:if test="OrderModifier/Descending">
	  <xsl:attribute name="order">descending</xsl:attribute>
	</xsl:if>
	<xsl:apply-templates select="OrderModifier/URILiteral" mode="xslt"/>
	<xsl:copy-of select="@*"/>
	<xsl:attribute name="select">
	  <xsl:text>for $xq:j in(</xsl:text>
	  <xsl:apply-templates mode="p2" select="$sorttemp/xsl:sort/xsl:select/node()"/>
	  <xsl:text>) return (($xq:j instance of xs:double and not($xq:j = $xq:j)))</xsl:text>
	</xsl:attribute>
      </axsl:sort>
    </xsl:if>
    <xsl:copy-of select="$sorttemp"/>
  </xsl:template>


  <!-- [41] OrderModifier ::=
       ("ascending" | "descending")? (<"empty" "greatest"> | <"empty" "least">)?
       ("collation" URILiteral)?
  -->

  <xsl:template match="OrderModifier/URILiteral" mode="xslt">
    <xsl:attribute name="collation"
		   select="substring(StringLiteral/data,2,string-length(StringLiteral/data)-2)"/>
  </xsl:template>

  <!-- [42] QuantifiedExpr ::=
       (<"some" "$"> | <"every" "$">) VarName TypeDeclaration? "in" 
       ExprSingle ("," "$" VarName TypeDeclaration? "in" ExprSingle)*
       "satisfies" ExprSingle
  -->

  <xsl:template match="QuantifiedExpr" mode="xpath">
    <xsl:apply-templates select="data|VarName" mode="xpath"/>
    <xsl:text> satisfies </xsl:text>
    <xsl:apply-templates select="*[position()=last()]" mode="xpath"/>
  </xsl:template>



  <xsl:template match="QuantifiedExpr/VarName" mode="xpath">
    <xsl:if test="preceding-sibling::VarName">, </xsl:if>
    <xsl:text>$</xsl:text>
    <xsl:value-of select="QName/data"/>
    <xsl:text> in </xsl:text>
    <xsl:if test="following-sibling::*[1][self::TypeDeclaration]">
      <xsl:text>(for $i in </xsl:text>
    </xsl:if>
    <xsl:apply-templates select="following-sibling::*[not(self::TypeDeclaration)][1]" mode="xpath"/>
    <xsl:if test="following-sibling::*[1][self::TypeDeclaration]">
      <xsl:text> return $i treat as </xsl:text>
      <xsl:apply-templates select="following-sibling::*[1][self::TypeDeclaration]"  mode="xpath"/>
      <xsl:text>)</xsl:text>
    </xsl:if>
  </xsl:template>


  <xsl:template match="Every" mode="xpath">
    <xsl:text> every </xsl:text>
  </xsl:template>

  <xsl:template match="Some" mode="xpath">
    <xsl:text> some </xsl:text>
  </xsl:template>


  <!-- [43] TypeswitchExpr ::=
       <"typeswitch" "("> Expr ")" CaseClause+ "default" ("$" VarName)?
       "return" ExprSingle
  -->

  <xsl:template match="TypeswitchExpr" mode="xslt">
    <axsl:variable as="item()*" name="xq:ts">
      <xsl:variable name="content" as="item()*">
	<xsl:apply-templates select="Expr" mode="xslt"/>
      </xsl:variable>
      <xsl:choose>
	<xsl:when test="$content[not(self::xsl:sequence)]">
	  <xsl:sequence select="$content"/>
	</xsl:when>
	<xsl:otherwise>
	  <axsl:select>
	    <!-- spurious ,() at end to stop xslt compiler spotting literals and so generating type errors on unexecuted branches
  saxon 8.6.1 got smarter and optimised () away, now use $input[0], now use $xq:empty
            -->
	    <xsl:sequence select="('((',$content[1]/xsl:select/node(),for $e in $content[position()!=1] return (',',$e/xsl:select/node()),'),$xq:empty)')"/>
	  </axsl:select>
	</xsl:otherwise>
      </xsl:choose>
    </axsl:variable>
    <axsl:choose>
      <xsl:apply-templates select="CaseClause|(VarName|PathExpr)[1]" mode="xslt"/>
    </axsl:choose>
  </xsl:template>

  <xsl:template match="TypeswitchExpr/VarName" mode="xslt" priority="2">
    <axsl:otherwise>
      <xsl:if test="following-sibling::*[1]">
	<axsl:variable as="item()*" name="{QName/data}" select="$xq:ts"/>
      </xsl:if>
      <xsl:apply-templates select="following-sibling::*[last()]" mode="xslt"/>
    </axsl:otherwise>
  </xsl:template>

 <xsl:template match="TypeswitchExpr/PathExpr" mode="xslt" priority="2">
    <axsl:otherwise>
      <xsl:next-match/>
    </axsl:otherwise>
  </xsl:template>


  <!-- [44] CaseClause ::=
       "case" ("$" VarName "as")? SequenceType "return" ExprSingle
  -->

  <xsl:template match="CaseClause" mode="xslt">
    <xsl:variable name="t">
      <xsl:apply-templates select="SequenceType" mode="xpath"/>
    </xsl:variable>
    <axsl:when test="$xq:ts instance of {$t}">
      <xsl:if test="VarName">
	<axsl:variable as="{$t}" name="{VarName/QName/data}" select="$xq:ts"/>
      </xsl:if>
      <xsl:apply-templates select="*[last()]" mode="xslt"/>
    </axsl:when>
  </xsl:template>

  <!-- [45] IfExpr ::=
       <"if" "("> Expr ")" "then" ExprSingle "else" ExprSingle
  -->

  <xsl:template match="IfExpr" mode="xpath">
    <xsl:text> if (</xsl:text>
    <xsl:apply-templates select="*[1]" mode="xpath"/>
    <xsl:text>) then </xsl:text>
    <xsl:apply-templates select="*[2]" mode="xpath"/>
    <xsl:text> else </xsl:text>
    <xsl:apply-templates select="*[3]" mode="xpath"/>
  </xsl:template>

  <!-- [46] OrExpr ::=
       AndExpr ( "or" AndExpr )*
  -->

  <xsl:template match="OrExpr">
  </xsl:template>

  <!-- [47] AndExpr ::=
       ComparisonExpr ( "and" ComparisonExpr )*
  -->


  <!-- [48] ComparisonExpr ::=
       RangeExpr ( (ValueComp
       | GeneralComp
       | NodeComp) RangeExpr )?
  -->



  <xsl:template match="AndExpr|ComparisonExpr|AdditiveExpr|MultiplicativeExpr|IntersectExceptExpr|UnionExpr|RangeExpr|IntersectExceptExpr|ComparisonExpr|AndExpr|OrExpr" mode="xpath">
    <xsl:text>(</xsl:text>
    <xsl:apply-templates select="*[2]" mode="xpath"/>
    <xsl:value-of select="concat(' ',data,' ')"/>
    <xsl:apply-templates select="*[3]" mode="xpath"/>
    <xsl:text>)</xsl:text>
  </xsl:template>

  <!-- [49] RangeExpr ::=
       AdditiveExpr ( "to" AdditiveExpr )?
  -->


  <!-- [50] AdditiveExpr ::=
       MultiplicativeExpr ( ("+" | "-") MultiplicativeExpr )*
  -->

  <!-- Shares code with ComparisonExpr template -->

  <!-- [51] MultiplicativeExpr ::=
       UnionExpr ( ("*" | "div" | "idiv" | "mod") UnionExpr )*
  -->

  <!-- Shares code with ComparisonExpr template -->

  <!-- [52] UnionExpr ::=
       IntersectExceptExpr ( ("union" | "|") IntersectExceptExpr )*
  -->



  <!-- [53] IntersectExceptExpr ::=
       InstanceofExpr ( ("intersect" | "except") InstanceofExpr )*
  -->

  <!-- Shares code with ComparisonExpr template -->

  <!-- [54] InstanceofExpr ::=
       TreatExpr ( <"instance" "of"> SequenceType )?
  -->
  <xsl:template match="InstanceofExpr" mode="xpath">
    <xsl:text>((</xsl:text>
    <xsl:apply-templates select="*[1]" mode="xpath"/>
    <xsl:text>) instance of </xsl:text>
    <xsl:apply-templates select="*[2]" mode="xpath"/>
    <xsl:text>)</xsl:text>
  </xsl:template>


<!--
have to get false for 3 instance of xs:byte and true for xs:byte(3) instance of xs:byte
I don't think this is possible using a basic xslt back end.
  <xsl:template match="InstanceofExpr[$basic='yes']" mode="xpath">
    <xsl:variable name="prim" select="key('builtintypes',*[2]//data,$primtypes)"/>
    <xsl:choose>
      <xsl:when test="exists($prim)">
        <xsl:text>(((</xsl:text>
        <xsl:apply-templates select="*[1]" mode="xpath"/>     
        <xsl:text>)castable as </xsl:text> 
        <xsl:value-of select="*[2]//data"/>     
        <xsl:text>) and (</xsl:text>
	<xsl:next-match/>
        <xsl:text>))</xsl:text>
      </xsl:when>
       <xsl:otherwise>
	<xsl:next-match/>
       </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
-->

  <!-- [55] TreatExpr ::=
       CastableExpr ( <"treat" "as"> SequenceType )?
  -->

  <xsl:template match="TreatExpr" mode="xpath">
    <xsl:text>((</xsl:text>
    <xsl:apply-templates select="*[1]" mode="xpath"/>
    <xsl:text>) treat as </xsl:text>
    <xsl:apply-templates select="*[2]" mode="xpath"/>
    <xsl:text>)</xsl:text>
  </xsl:template>

  <!-- [56] CastableExpr ::=
       CastExpr ( <"castable" "as"> SingleType )?
  -->

  <xsl:template match="CastableExpr" mode="xpath">
    <xsl:text>((</xsl:text>
    <xsl:apply-templates select="*[1]" mode="xpath"/>
    <xsl:text>) castable as </xsl:text>
    <xsl:apply-templates select="*[2]" mode="xpath"/>
    <xsl:text>)</xsl:text>
  </xsl:template>

  <!-- [57] CastExpr ::=
       UnaryExpr ( <"cast" "as"> SingleType )?
  -->

  <xsl:template match="CastExpr" mode="xpath">
    <xsl:text>((</xsl:text>
    <xsl:apply-templates select="*[1]" mode="xpath"/>
    <xsl:text>) cast as </xsl:text>
    <xsl:apply-templates select="*[2]" mode="xpath"/> 
    <xsl:text>)</xsl:text>
  </xsl:template>

  <!-- [58] UnaryExpr ::=
       ("-" | "+")* ValueExpr
  -->


  <!-- [59] ValueExpr ::=
       ValidateExpr | PathExpr | ExtensionExpr
  -->


  <!-- [60] GeneralComp ::=
       "=" | "!=" | "<" | "<=" | ">" | ">="
  -->



  <!-- [61] ValueComp ::=
       "eq" | "ne" | "lt" | "le" | "gt" | "ge"
  -->



  <!-- [62] NodeComp ::=
       "is" | "<<" | ">>"
  -->



  <!-- [63] ValidateExpr ::=
       (<"validate" "{"> | (<"validate" ValidationMode> "{")) Expr "}"
  -->

  <xsl:template match="ValidateExpr" mode="xslt">
    <axsl:variable name="xq:temp" as="item()">
      <xsl:apply-templates select="Expr" mode="xslt"/>
    </axsl:variable>
<!--
    <axsl:copy-of use-when="system-property('xsl:is-schema-aware')='no'"
		  select="$xq:temp"/>
    <axsl:copy-of use-when="system-property('xsl:is-schema-aware')='yes'"
		  validation="{ValidationMode/data}"
		  select="$xq:temp"/>
-->
    <axsl:copy-of 
		  validation="{(ValidationMode/data,'strict')}"
		  select="$xq:temp"/>
  </xsl:template>


  <!-- [64] ExtensionExpr ::=
       Pragma+ "{" Expr? "}"
  -->

  <xsl:template match="ExtensionExpr" mode="xslt">
    <xsl:for-each select="Pragma/QNameForPragma/data">
      <axsl:if test="xs:QName('{.}')=xs:QName('{.}')"/>
    </xsl:for-each>
    <xq:extension>
      <xsl:apply-templates select="Pragma" mode="xslt"/>
      <xsl:if test="Expr">
	<axsl:fallback>
	  <xsl:apply-templates select="Expr" mode="xslt"/>
	</axsl:fallback>
      </xsl:if>
    </xq:extension>
  </xsl:template>


  <!-- [65] Pragma ::=
       "(#" S? QName PragmaContents "#)"
  -->

  <xsl:template match="Pragma" mode="xslt">
    <xq:pragma name="{QNameForPragma/data}">
      <xsl:value-of select="PragmaContents/ExtensionContentChar/data" separator=""/>
    </xq:pragma>
  </xsl:template>

  <!-- [66] PragmaContents ::=
       (Char* - (Char* '#)' Char*))
  -->


  <!-- [67] PathExpr ::=
       ("/" RelativePathExpr?)
       | ("//" RelativePathExpr)
       | RelativePathExpr
  -->


  <xsl:template match="PathExpr" mode="xpath">
    <xsl:if test="*[1][self::Slash]">/</xsl:if>
    <xsl:for-each select="*">
      <xsl:apply-templates select="." mode="xpath"/>
      <xsl:if test="not(
		    (position()=last()) or
		    self::Slash or self::SlashSlash
		    )">
	<xsl:text>/</xsl:text>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="Slash" mode="xpath"></xsl:template>

  <xsl:template match="SlashSlash" mode="xpath">/</xsl:template>
  <xsl:template match="SlashSlash[not(preceding-sibling::*)]" mode="xpath">//</xsl:template>

  <xsl:template match="PathExpr|IfExpr|IntegerLiteral|StringLiteral|DoubleLiteral|DecimalLiteral|AdditiveExpr|MultiplicativeExpr|UnionExpr|QuantifiedExpr|FunctionCall|VarName|IntersectExceptExpr|ComparisonExpr|UnaryExpr|Root|AndExpr|OrExpr|StepExpr|CastExpr|CastableExpr|InstanceofExpr|TreatExpr|RangeExpr" mode="xslt">
    <axsl:sequence>
      <axsl:select>
	<xsl:apply-templates select="." mode="xpath"/>
      </axsl:select>
    </axsl:sequence>
  </xsl:template>

  <xsl:template match="PathExpr[not(*[2]) and not(Slash)]" mode="xslt">
    <xsl:apply-templates select="*" mode="xslt"/>
  </xsl:template>


  <!-- [68] RelativePathExpr ::=
       StepExpr (("/" | "//") StepExpr)*
  -->


  <!-- [69] StepExpr ::=
       AxisStep | FilterExpr
  -->

  <xsl:template match="StepExpr" mode="xpath">
    <xsl:apply-templates select="*" mode="xpath"/>
  </xsl:template>

  <!-- [70] AxisStep ::=
       (ForwardStep | ReverseStep) PredicateList
  -->


  <!-- [71] ForwardStep ::=
       (ForwardAxis NodeTest) | AbbrevForwardStep
  -->


  <!-- [72] ForwardAxis ::=
       <"child" "::">
       | <"descendant" "::">
       | <"attribute" "::">
       | <"self" "::">
       | <"descendant-or-self" "::">
       | <"following-sibling" "::">
       | <"following" "::">
  -->

  <xsl:template match="ForwardAxis" mode="xpath">
    <xsl:value-of select="data"/>
    <xsl:text>::</xsl:text>
  </xsl:template>

  <!-- [73] AbbrevForwardStep ::=
       "@"? NodeTest
  -->


  <!-- [74] ReverseStep ::=
       (ReverseAxis NodeTest) | AbbrevReverseStep
  -->


  <!-- [75] ReverseAxis ::=
       <"parent" "::">
       | <"ancestor" "::">
       | <"preceding-sibling" "::">
       | <"preceding" "::">
       | <"ancestor-or-self" "::">
  -->

  <xsl:template match="ReverseAxis" mode="xpath">
    <xsl:value-of select="data"/>
    <xsl:text>::</xsl:text>
  </xsl:template>

  <!-- [76] AbbrevReverseStep ::=
       ".."
  -->

 <xsl:template match="AbbrevReverseStep" mode="xpath">
    <xsl:text>..</xsl:text>
  </xsl:template>


  <!-- [77] NodeTest ::=
       KindTest | NameTest
  -->

  <xsl:template match="NodeTest" mode="xpath">
    <xsl:apply-templates select="*" mode="xpath"/>
  </xsl:template>


  <!-- [78] NameTest ::=
       QName | Wildcard
  -->

  <xsl:template match="NameTest" mode="xpath">
    <xsl:apply-templates select="*" mode="xpath"/>
  </xsl:template>


  <!-- [79] Wildcard ::=
       "*"
       | <NCName ":" "*">
       | <"*" ":" NCName>
  -->


  <!-- [80] FilterExpr ::=
       PrimaryExpr PredicateList
  -->


  <!-- [81] PredicateList ::=
       Predicate*
  -->


  <!-- [82] Predicate ::=
       "[" Expr "]"
  -->

  <xsl:template match="Predicate" mode="xpath">
    <xsl:text>[</xsl:text>
    <xsl:apply-templates select="*" mode="xpath"/>
    <xsl:text>]</xsl:text>
  </xsl:template>

  <!-- [83] PrimaryExpr ::=
       Literal | VarRef | ParenthesizedExpr | ContextItemExpr | FunctionCall |
       Constructor | OrderedExpr | UnorderedExpr
  -->


  <!-- [84] Literal ::=
       NumericLiteral | StringLiteral
  -->


  <!-- [85] NumericLiteral ::=
       IntegerLiteral | DecimalLiteral | DoubleLiteral
  -->


  <!-- [86] VarRef ::=
       "$" VarName
  -->

<!--?? Varname/data=/ test04-->

  <xsl:template match="PathExpr/VarName" mode="xpath">
    <xsl:text>$</xsl:text>
    <xsl:value-of select="QName/data"/>
  </xsl:template>
  <xsl:template match="StepExpr/VarName" mode="xpath">
    <xsl:text>$</xsl:text>
    <xsl:value-of select="QName/data"/>
  </xsl:template>
  <xsl:template match="FLWORExpr/VarName" mode="xpath">
    <xsl:text>$</xsl:text>
    <xsl:value-of select="QName/data"/>
  </xsl:template>



  <!-- [87] ParenthesizedExpr ::=
       "(" Expr? ")"
  -->

  <xsl:template match="ParenthesizedExpr/data" mode="xpath"/><!--??-->

  <xsl:template match="ParenthesizedExpr" mode="xslt">
    <xsl:apply-templates select="*" mode="xslt"/>
  </xsl:template>

  <xsl:template match="ParenthesizedExpr" mode="xpath">
    <xsl:text>(</xsl:text>
    <xsl:apply-templates select="*" mode="xpath"/>
    <xsl:text>)</xsl:text>
  </xsl:template>

  <!-- [88] ContextItemExpr ::=
       "."
  -->


  <!-- [89] OrderedExpr ::=
       <"ordered" "{"> Expr "}"
  -->

  <xsl:template match="OrderedExpr" mode="xpath">
    <xsl:apply-templates select="Expr" mode="xpath"/>
  </xsl:template>

  <xsl:template match="OrderedExpr" mode="xslt">
    <xsl:apply-templates select="Expr" mode="xslt"/>
  </xsl:template>

  <!-- [90] UnorderedExpr ::=
       <"unordered" "{"> Expr "}"
  -->


  <xsl:template match="UnorderedExpr" mode="xpath">
    <xsl:apply-templates select="Expr" mode="xpath"/>
  </xsl:template>

  <xsl:template match="UnorderedExpr" mode="xslt">
    <xsl:apply-templates select="Expr" mode="xslt"/>
  </xsl:template>

  <!-- [91] FunctionCall ::=
       <QName "("> (ExprSingle ("," ExprSingle)*)? ")"

  -->

  <xsl:template match="FunctionCall" mode="xpath">
    <xsl:param name="functionns" tunnel="yes"/>
    <xsl:if test="$functionns and not(contains(FunctionQName/data,':'))">
      <xsl:text>default-function-namespace:</xsl:text>
    </xsl:if>
    <xsl:if test="not($functionns) and FunctionQName/data=('document','current','key','format-date','format-time','format-dateTime','format-number','unparsed-text','unparsed-text-available','unparsed-entity-uri','unparsed-entity-public-id','generate-id','system-property','element-available')">
      <xsl:text>xsl-</xsl:text>
    </xsl:if>
      <xsl:apply-templates select="FunctionQName" mode="xpath"/>
    <xsl:text>(</xsl:text>
    <xsl:choose>
      <xsl:when test="not(*[2]) and FunctionQName[(data='collection' and not($functionns))
                           or (data='fn:collection')]">
      <xsl:text>$xq:dc</xsl:text>
      </xsl:when>
      <xsl:otherwise>
	<xsl:for-each select="*[position()!=1]">
    <xsl:if test="not($functionns) and ../FunctionQName/data=('max','min') and position()=1">($xq:empty,</xsl:if>
	  <xsl:apply-templates select="." mode="xpath"/>
    <xsl:if test="not($functionns) and ../FunctionQName/data=('max','min') and position()=1">)</xsl:if>
	  <xsl:if test="not(position()=last())">,</xsl:if>
	</xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>)</xsl:text>
  </xsl:template>

  <xsl:param name="basic" select="if(system-property('xsl:is-schema-aware')) then 'yes' else 'no'"/>

<!-- doesn't work in 8.7.1
  <xsl:template match="FunctionCall[$basic='yes']" mode="xpath">
    <xsl:variable name="prim" select="key('builtintypes',FunctionQName/data,$primtypes)"/>
    <xsl:choose>
      <xsl:when test="exists($prim)">
        <xsl:text>(if ((</xsl:text>
        <xsl:apply-templates select="*[2]" mode="xpath"/>     
        <xsl:text>)castable as </xsl:text> 
        <xsl:value-of select="FunctionQName/data"/>
        <xsl:text>) then (</xsl:text>
	<xsl:next-match/>
        <xsl:text>) else error())</xsl:text>
      </xsl:when>
       <xsl:otherwise>
	<xsl:next-match/>
       </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
-->


  <xsl:template match="FunctionCall[$basic='yes'][FunctionQName/data]" mode="xpath" priority="2">
    <xsl:variable name="b" select="key('builtintypes',FunctionQName/data, $primtypes)"/>
    <xsl:choose>
      <xsl:when test="$b/parent::xs:integer">
	<xsl:text>xq:integer(</xsl:text>
	<xsl:apply-templates select="*[2]"  mode="xpath"/>
	<xsl:text>,</xsl:text>
	<xsl:value-of select="$b/@min"/>
	<xsl:text>,</xsl:text>
	<xsl:value-of select="$b/@max"/>
	<xsl:text>)</xsl:text>
      </xsl:when>
      <xsl:otherwise>
	<xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="FunctionCall/FunctionQName[$basic='yes']" mode="xpath">
    <xsl:variable name="prim" select="key('builtintypes',data,$primtypes)/.."/>
    <xsl:value-of select="if (exists($prim)) then (name($prim)) else ."/>
  </xsl:template>

  <xsl:template match="AtomicType/QName[$basic='yes'][not(.='xs:!NOTATION')]" mode="xpath">
    <xsl:variable name="prim" select="key('builtintypes',data,$primtypes)/.."/>
    <xsl:value-of select="if (exists($prim)) then name($prim) else ."/>
  </xsl:template>

  <xsl:template match="SingleType/QName[$basic='yes'][not(.='xs:!NOTATION')]" mode="xpath">
    <xsl:variable name="prim" select="key('builtintypes',data,$primtypes)/.."/>
    <xsl:value-of select="if (exists($prim)) then name($prim) else ."/>
  </xsl:template>

<!--
 <xsl:template match="InstanceofExpr/SequenceType/AtomicType/QName" priority="2" mode="xpath">
    <xsl:value-of select="."/>
  </xsl:template>
-->

<xsl:template match="CastableExpr/SingleType/AtomicType/QName" priority="2" mode="xpath">
  <xsl:value-of select="."/>
</xsl:template>


  <xsl:key name="builtintypes" match="t" use="@name"/>
  <xsl:variable name="primtypes">
    <xs:integer>

      <t name="xs:nonPositiveInteger" min="9" max="0"/>
      <t name="xs:negativeInteger" min="9" max="-1"/>
      <t name="xs:long" min="-9223372036854775808" max="9223372036854775807"/>
      <t name="xs:int" min="-2147483648" max="2147483647"/>
      <t name="xs:short" min="-32768" max="32767"/>
      <t name="xs:byte" min="-128" max="127"/>
      <t name="xs:nonNegativeInteger" min="0" max="9"/>
      <t name="xs:unsignedLong" min="0" max="18446744073709551615"/>
      <t name="xs:unsignedInt" min="0" max="4294967295"/>
      <t name="xs:unsignedShort" min="0" max="65535"/>
      <t name="xs:unsignedByte" min="0" max="255"/>
      <t name="xs:positiveInteger" min="1" max="9"/>

    </xs:integer>
    <xs:string>
      <t name="xs:normalizedString" pattern="[^&#9;&#10;&#13;]*"/>
      <t name="xs:token" pattern="[^&#9;&#10;&#13;]*"/><!-- not quite right -->
      <t name="xs:language" pattern="[a-zA-Z]{1,8}(-[a-zA-Z0-9]{1,8})*"/>
      <t name="xs:NMTOKEN" pattern="\c+"/>
      <t name="xs:Name" pattern="\i\c*"/>
      <t name="xs:NCName" pattern="\i\c*"/><!-- minus : -->
      <t name="xs:ID" pattern="\i\c*"/><!-- minus : -->
      <t name="xs:IDREF" pattern="\i\c*"/><!-- minus : -->
      <t name="xs:IDREFS" pattern="((\i\c*) *)*"/>
      <t name="xs:ENTITY" pattern="\i\c*"/><!-- minus : -->
    </xs:string>
    <xs:anyAtomicType>
      <t name="xs:NOTATION" pattern="\i\c+"/>      
    </xs:anyAtomicType>
  </xsl:variable>

  <!-- [92] Constructor ::=
       DirectConstructor
       | ComputedConstructor
  -->

  <xsl:template match="Constructor" mode="xslt">
    <xsl:apply-templates select="*" mode="xslt"/>
  </xsl:template>

  <xsl:template match="Constructor/data" mode="xslt"/><!--??-->

  <xsl:template match="FLWORExpr|ExtensionExpr|TypeswitchExpr|Expr[PathExpr/Constructor]|Constructor" mode="xpath">
    <axsl:function name="xq:xpath_{generate-id()}" as="item()*">
      <axsl:param name="xq:here"/>
      <xsl:for-each select="distinct-values(
			    (ancestor::*[parent::FLWORExpr or parent::ForClause or parent::LetClause or parent::QuantifiedExpr]/
			    preceding-sibling::*[self::VarName|self::ForClause|self::LetClause]/
			    (self::VarName|VarName|PositionalVar/VarName)
                           ,
                          ancestor::FunctionDecl/ParamList/Param)
                            /QName/data
			    [key('vref',.,current())])">
	<axsl:param name="{.}"/>
      </xsl:for-each>
      <axsl:for-each select="$xq:here">
	<xsl:apply-templates select="." mode="xslt">
	  <xsl:with-param name="here" select="false()"/>
	</xsl:apply-templates>
      </axsl:for-each>
    </axsl:function>
  </xsl:template>

  <!-- [93] DirectConstructor ::=
       DirElemConstructor
       | DirCommentConstructor
       | DirPIConstructor
  -->

  <xsl:template match="DirectConstructor" mode="xslt">
    <xsl:apply-templates select="*" mode="xslt"/>
  </xsl:template>


  <!-- [94] DirElemConstructor ::=
       "<" QName DirAttributeList ("/>" | (">" DirElemContent* "</" QName S? ">"))
  -->

  <xsl:template match="DirElemConstructor" mode="xslt">
    <xsl:param name="noinherit" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="exists($noinherit)">
	<axsl:element name="{TagQName[1]/data}">
	    <xsl:attribute name="inherit-namespaces" select="'no'"/>
	  <xsl:call-template name="direlemcontent"/>
	</axsl:element>
      </xsl:when>
      <xsl:when test="DirAttributeList/TagQName[data='xmlns'][following-sibling::DirAttributeValue[1][not(*[3])]]">
	<xsl:element name="{TagQName[1]/data}" xmlns="">
	  <xsl:call-template name="direlemcontent"/>
	</xsl:element>
      </xsl:when>
      <xsl:otherwise>
	<axsl:element name="{TagQName[1]/data}">
	  <xsl:call-template name="direlemcontent"/>
	</axsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>



  <xsl:template name="direlemcontent">
    <xsl:param name="preservespace" tunnel="yes"/>
<!--
<xsl:message>
dec: [[<xsl:copy-of select="DirAttributeList"/>]]
</xsl:message>
-->
    <xsl:apply-templates select="DirAttributeList/TagQName" mode="ns"/>
<!-- saxon 8.7 ns pull mode bug -->
<!--      <xsl:apply-templates select="DirAttributeList/TagQName" mode="xslt"/>-->
    <axsl:variable name="content" as="item()*">
      <xsl:apply-templates select="DirAttributeList/TagQName" mode="xslt"/>
      <!--?? data-->
      <xsl:for-each-group select="DirElemContent/*[not(self::data)]" group-adjacent="exists(self::ElementContentChar|self::CommonContent[CharRef|PredefinedEntityRef|LCurlyBraceEscape|RCurlyBraceEscape])">
	<xsl:choose>
	  <xsl:when test="not($preservespace) and current-grouping-key() and not(normalize-space(string-join(current-group()//data,'')))
		    and not(current-group()[1]/../preceding-sibling::*[1]/CDataSection)
		    and not(current-group()[last()]/../following-sibling::*[1]/CDataSection)">
	  </xsl:when>
	  <xsl:when test="current-grouping-key()">
	    <axsl:text>
	      <xsl:apply-templates select="current-group()" mode="xslt"/>
	    </axsl:text>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:apply-templates select="current-group()" mode="xslt"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:for-each-group>
    </axsl:variable>
    <axsl:variable name="att" select="$content[. instance of attribute()]/node-name(.)"/>
    <axsl:if test="count($att)!=count(distinct-values($att))">
      <axsl:sequence select="error(QName('http://www.w3.org/2005/xqt-errors','XQDY0025'),'duplicated attribute')"/>
    </axsl:if>
    <axsl:sequence select="$content"/>
  </xsl:template>
  

  <!-- [95] DirAttributeList ::=
       (S (QName S? "=" S? DirAttributeValue)?)*
  -->

  <!-- use axsl:attribute rather than xsl:attribute, as for element constructors -->
  <xsl:template match="DirAttributeList/TagQName" mode="xslt">
    <xsl:param name="noinherit" tunnel="yes"/>
    <xsl:variable name="nstmp">
      <xsl:apply-templates select="following-sibling::DirAttributeValue[1]/(QuotAttrValueContent|AposAttrValueContent|EscapeQuot|EscapeApos)/*" mode="xslt"/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="string($nstmp) and data='xmlns'">
	  <axsl:namespace name="" select="'{$nstmp}'"/>
      </xsl:when>
      <xsl:when test="string($nstmp)and starts-with(data,'xmlns:')">
	  <axsl:namespace name="{substring-after(data,':')}" select="'{$nstmp}'"/>
      </xsl:when>
      <xsl:when test="data='xmlns' or starts-with(data,'xmlns:')">
      </xsl:when>
      <xsl:otherwise>
	<!-- use content here rather than select attribute as "" and ' have been unescaped -->
	<axsl:attribute name="{data}">
	  <xsl:for-each select="$nstmp/node()">
	    <xsl:choose>
	      <xsl:when test="self::text()">
		<axsl:text><xsl:value-of select="."/></axsl:text>
	      </xsl:when>
	      <xsl:otherwise>
		<xsl:sequence select="."/>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:for-each>
	</axsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="DirAttributeList/TagQName" mode="ns">
    <xsl:variable name="nstmp">
      <xsl:apply-templates select="following-sibling::DirAttributeValue[1]/(QuotAttrValueContent|AposAttrValueContent|EscapeQuot|EscapeApos)/*" mode="xslt"/>
    </xsl:variable>
<xsl:choose>
      <xsl:when test="not(string($nstmp))"/>
      <xsl:when test="data='xmlns'">
	<xsl:namespace name="" select="$nstmp"/>
      </xsl:when>
      <xsl:when test="data='xmlns:xml'"/>
      <xsl:when test="data='xmlns:xmlns'"/>
      <xsl:when test="starts-with(data,'xmlns:')">
	<xsl:namespace name="{substring-after(data,':')}" select="$nstmp"/>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:template>



  <!-- [96] DirAttributeValue ::=
       ('"' (EscapeQuot | QuotAttrValueContent)* '"')
       | ("'" (EscapeApos | AposAttrValueContent)* "'")
  -->


  <!-- [97] QuotAttrValueContent ::=
       QuotAttrContentChar
       | CommonContent
  -->


  <!-- [98] AposAttrValueContent ::=
       AposAttrContentChar
       | CommonContent
  -->

  <!-- [99] DirElemContent ::=
       DirectConstructor
       | ElementContentChar
       | CDataSection
       | CommonContent
  -->

  <xsl:template match="DirElemContent" mode="xslt">
    <xsl:apply-templates select="*" mode="xslt"/>
  </xsl:template>

  <!-- [100] CommonContent ::=
       PredefinedEntityRef | CharRef | "{{" | "}}" | EnclosedExpr
  -->

  <xsl:template match="CommonContent" mode="xslt">
    <xsl:apply-templates select="*" mode="xslt"/>
  </xsl:template>

  <xsl:template match="LCurlyBraceEscape" mode="xslt">
    <xsl:text>{</xsl:text>
  </xsl:template>

  <xsl:template match="RCurlyBraceEscape" mode="xslt">
    <xsl:text>}</xsl:text>
  </xsl:template>


  <!-- [101] DirCommentConstructor ::=
       "<!-/-" DirCommentContents "-/->"
  -->

  <xsl:template match="DirCommentConstructor" mode="xslt">
    <axsl:comment>
      <xsl:value-of select="DirCommentContents/(CommentContentChar|CommentContentCharDash)/data" separator=""/>
    </axsl:comment>
  </xsl:template>

  <!-- [102] DirCommentContents ::=
       ((Char - '-') | <'-' (Char - '-')>)*
  -->

  <!-- handled in [101] -->

  <!-- [103] DirPIConstructor ::=
       "<?" PITarget (S DirPIContents)? "?>"
  -->

  <xsl:template match="DirPIConstructor" mode="xslt">
    <axsl:processing-instruction name="{PITarget/data}">
      <xsl:value-of select="DirPIContents/PIContentChar/data" separator=""/>
    </axsl:processing-instruction>
  </xsl:template>

  <!-- [104] DirPIContents ::=
       (Char* - (Char* '?>' Char*))
  -->


  <!-- [105] CDataSection ::=
       "<![CDATA[" CDataSectionContents "]]>"
  -->

  <xsl:template match="CDataSection" mode="xslt">
    <axsl:text>
      <xsl:value-of select="CDataSectionContents/CDataSectionChar/data" separator=""/>
    </axsl:text>
  </xsl:template>

  <!-- [106] CDataSectionContents ::=
       (Char* - (Char* ']]>' Char*))
  -->

  <!-- handled in [105] -->

  <!-- [107] ComputedConstructor ::=
       CompDocConstructor
       | CompElemConstructor
       | CompAttrConstructor
       | CompTextConstructor
       | CompCommentConstructor
       | CompPIConstructor
  -->

  <xsl:template match="ComputedConstructor" mode="xslt">
    <xsl:apply-templates select="*" mode="xslt"/>
  </xsl:template>

  <!-- [108] CompDocConstructor ::=
       <"document" "{"> Expr "}"
  -->

  <xsl:template match="CompDocConstructor" mode="xslt">
    <axsl:document>
      <xsl:apply-templates select="Expr" mode="xslt"/>
    </axsl:document>
  </xsl:template>

  <!-- [109] CompElemConstructor ::=
       (<"element" QName "{"> | (<"element" "{"> Expr "}" "{")) ContentExpr? "}"
  -->

  <xsl:template match="CompElemConstructor[not(QName)]" mode="xslt">
    <axsl:variable name="xq:name" as="item()*">
      <axsl:select>
	<xsl:apply-templates select="Expr[1]" mode="xpath"/>
	<xsl:text>,$xq:empty</xsl:text>
      </axsl:select>
    </axsl:variable>
    <axsl:variable name="content" as="item()*">
      <xsl:apply-templates select="ContentExpr/*" mode="xslt"/>
    </axsl:variable>
    <axsl:variable name="att" select="$content[. instance of attribute()]/node-name(.)"/>
    <axsl:choose>
      <axsl:when test="count($att)!=count(distinct-values($att))">
	<axsl:sequence select="error(QName('http://www.w3.org/2005/xqt-errors','XQDY0025'),'duplicated attribute')"/>
      </axsl:when>
      <axsl:when test="$xq:name instance of xs:QName">
	<axsl:element name="{{string($xq:name)}}" namespace="{{namespace-uri-from-QName($xq:name)}}">
	  <axsl:sequence select="$content"/>
	</axsl:element>
      </axsl:when>
      <axsl:otherwise>
	<axsl:element name="{{$xq:name}}">
	  <axsl:sequence select="$content"/>
	</axsl:element>
      </axsl:otherwise>
    </axsl:choose>
  </xsl:template>

  <xsl:template match="CompElemConstructor[QName]" mode="xslt">
    <axsl:element name="{QName/data}">
      <axsl:variable name="content" as="item()*">
	<xsl:apply-templates select="ContentExpr/*" mode="xslt"/>
      </axsl:variable>
      <axsl:variable name="att" select="$content[. instance of attribute()]/node-name(.)"/>
      <axsl:if test="count($att)!=count(distinct-values($att))">
	<axsl:sequence select="error(QName('http://www.w3.org/2005/xqt-errors','XQDY0025'),'duplicated attribute')"/>
      </axsl:if>
      <axsl:sequence select="$content"/>
    </axsl:element>
  </xsl:template>
  

  <!-- [110] ContentExpr ::=
       Expr
  -->

  <!-- [111] CompAttrConstructor ::=
       (<"attribute" QName "{"> | (<"attribute" "{"> Expr "}" "{")) Expr? "}"
  -->

  <xsl:template match="CompAttrConstructor" mode="xslt">
    <axsl:variable name="xq:name" as="item()*">
      <axsl:select>
	<xsl:apply-templates select="Expr[1]" mode="xpath"/>
	<xsl:text>,$xq:empty</xsl:text>
      </axsl:select>
    </axsl:variable>
    <axsl:variable name="content" as="item()*">
      <xsl:apply-templates select="Expr[2]" mode="xslt"/>
    </axsl:variable>
    <axsl:choose>
      <axsl:when test="$xq:name instance of xs:QName">
	<axsl:attribute name="{{string($xq:name)}}" namespace="{{namespace-uri-from-QName($xq:name)}}">
	  <axsl:sequence select="$content"/>
	</axsl:attribute>
      </axsl:when>
      <axsl:otherwise>
	<axsl:attribute name="{{$xq:name}}">
	  <axsl:sequence select="$content"/>
	</axsl:attribute>
      </axsl:otherwise>
    </axsl:choose>
  </xsl:template>

  <xsl:template match="CompAttrConstructor[QName]" mode="xslt">
    <axsl:attribute separator=" " name="{QName/data}" >
      <xsl:apply-templates select="Expr" mode="xslt"/>
    </axsl:attribute>
  </xsl:template>

  <!-- [112] CompTextConstructor ::=
       <"text" "{"> Expr "}"
  -->

  <xsl:template match="CompTextConstructor" mode="xslt">
    <axsl:variable name="content" as="item()*">
            <xsl:apply-templates select="Expr" mode="xslt"/>
    </axsl:variable>
    <axsl:if test="exists($content)">
      <axsl:value-of separator=" " select="for $i in $content return string($i)"/>
    </axsl:if>
  </xsl:template>

  <!-- [113] CompCommentConstructor ::=
       <"comment" "{"> Expr "}"
  -->

  <xsl:template match="CompCommentConstructor" mode="xslt">
    <axsl:variable name="content" as="xs:string">
      <axsl:value-of separator=" ">
	<xsl:apply-templates select="Expr" mode="xslt"/>
      </axsl:value-of>
    </axsl:variable>
    <axsl:choose>
      <axsl:when test="matches(concat($content,'-'),'--')">
	<axsl:sequence select="error(QName('http://www.w3.org/2005/xqt-errors','XQDY0072'),'-- in Comment')"/> 
      </axsl:when>
      <axsl:otherwise>
	<axsl:comment>
	  <axsl:value-of select="$content"/>
	</axsl:comment>
      </axsl:otherwise>
    </axsl:choose>
</xsl:template>

  <!-- [114] CompPIConstructor ::=
       (<"processing-instruction" NCName "{"> | 
       (<"processing-instruction" "{"> Expr "}" "{")) Expr? "}"
  -->

  <xsl:template match="CompPIConstructor[NCName]" mode="xslt">
    <axsl:variable name="content" as="xs:string">
      <axsl:value-of separator=" ">
	<xsl:apply-templates select="Expr" mode="xslt"/>
      </axsl:value-of>
    </axsl:variable>
    <axsl:choose>
      <axsl:when test="contains($content,'?&gt;')">
	<axsl:sequence select="error(QName('http://www.w3.org/2005/xqt-errors','XQDY0026'),'?&gt; in PI Content')"/>
      </axsl:when>
      <axsl:otherwise>
	<axsl:processing-instruction name="{NCName/data}">
	  <axsl:value-of select="$content"/>
	</axsl:processing-instruction>
      </axsl:otherwise>
    </axsl:choose>
  </xsl:template>

  <xsl:template match="CompPIConstructor" mode="xslt">
    <axsl:variable name="content" as="xs:string">
      <xsl:apply-templates select="Expr[2]" mode="xslt"/>
    </axsl:variable>
    <axsl:choose>
      <axsl:when test="contains($content,'?&gt;')">
	<axsl:sequence select="error(QName('http://www.w3.org/2005/xqt-errors','XQDY0026'),'?&gt; in PI Content')"/>
      </axsl:when>
      <axsl:otherwise>
	<axsl:processing-instruction>
	  <xsl:attribute name="name">
	    <xsl:text>{</xsl:text>
	    <xsl:apply-templates select="Expr[1]" mode="xpath"/>
	    <xsl:text>}</xsl:text>
	  </xsl:attribute>
	  <axsl:value-of select="$content"/>
	</axsl:processing-instruction>
      </axsl:otherwise>
    </axsl:choose>
  </xsl:template>

  <!-- [115] SingleType ::=
       AtomicType "?"?
  -->
  <xsl:template match="SingleType" mode="xpath">
    <xsl:apply-templates select="AtomicType,data" mode="xpath"/>
  </xsl:template>

  <!-- [116] TypeDeclaration ::=
       "as" SequenceType
  -->

  <!-- [117] SequenceType ::=
       (ItemType OccurrenceIndicator?)
       | <"void" "(" ")">
  -->

  <xsl:template match="SequenceType" mode="xslt">
    <xsl:attribute name="as">
      <xsl:apply-templates select="." mode="xpath"/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="SequenceType" mode="xpath">
    <xsl:apply-templates select="*" mode="xpath"/>
  </xsl:template>

  <xsl:template match="SequenceType[data='empty-sequence']" mode="xpath">
    <xsl:text> empty-sequence()</xsl:text>
  </xsl:template>



  <!-- [118] OccurrenceIndicator ::=
       "?" | "*" | "+"
  -->


  <!-- [119] ItemType ::=
       AtomicType | KindTest | <"item" "(" ")">
  -->
  
  <xsl:template match="ItemType[data='item']" mode="xpath">
    <xsl:text> item()</xsl:text>
  </xsl:template>
  

  <!-- [120] AtomicType ::=
       QName
  -->

  <xsl:template match="AtomicType" mode="xpath">
    <xsl:apply-templates select="*" mode="xpath"/>
  </xsl:template>


  <!-- [121] KindTest ::=
       DocumentTest
       | ElementTest
       | AttributeTest
       | SchemaElementTest
       | SchemaAttributeTest
       | PITest
       | CommentTest
       | TextTest
       | AnyKindTest
  -->
  <!-- [122] AnyKindTest ::=
       <"node" "("> ")"
  -->

  <xsl:template match="AnyKindTest" mode="xpath">
    <xsl:text>node()</xsl:text>
  </xsl:template>

  <!-- [123] DocumentTest ::=
       <"document-node" "("> (ElementTest | SchemaElementTest)? ")"
  -->

  <xsl:template match="DocumentTest" mode="xpath">
    <xsl:text> document-node(</xsl:text>
    <xsl:apply-templates select="*" mode="xpath"/>
    <xsl:text>)</xsl:text>
  </xsl:template>


  <!-- [124] TextTest ::=
       <"text" "("> ")"
  -->

  <xsl:template match="TextTest" mode="xpath">
    <xsl:text>text()</xsl:text>
  </xsl:template>

  <!-- [125] CommentTest ::=
       <"comment" "("> ")"
  -->

  <xsl:template match="CommentTest" mode="xpath">
    <xsl:text>comment()</xsl:text>
  </xsl:template>

  <!-- [126] PITest ::=
       <"processing-instruction" "("> (NCName | StringLiteral)? ")"
  -->

  <xsl:template match="PITest" mode="xpath">
    <xsl:text>processing-instruction(</xsl:text>
    <xsl:value-of select="(StringLiteral|NCName)/data"/>
    <xsl:text>)</xsl:text>
  </xsl:template>

  <!-- [127] AttributeTest ::=
       <"attribute" "("> (AttribNameOrWildcard ("," TypeName)?)? ")"
  -->

  <xsl:template match="AttributeTest" mode="xpath">
    <xsl:text>attribute(</xsl:text>
    <xsl:apply-templates select="*[1]" mode="xpath"/>
    <xsl:if test="*[2]">
       <xsl:text>,</xsl:text>
       <xsl:apply-templates select="*[2]" mode="xpath"/>
    </xsl:if>
    <xsl:text>)</xsl:text>
  </xsl:template>

  <!-- [128] AttribNameOrWildcard ::=
       AttributeName | "*"
  -->


  <!-- [129] SchemaAttributeTest ::=
       <"schema-attribute" "("> AttributeDeclaration ")"
  -->

  <xsl:template match="SchemaAttributeTest" mode="xpath">
    <xsl:text>schema-attribute(</xsl:text>
    <xsl:apply-templates select="*" mode="xpath"/>
    <xsl:text>)</xsl:text>
  </xsl:template>


  <!-- [130] AttributeDeclaration ::=
       AttributeName
  -->



  <!-- [131] ElementTest ::=
       <"element" "("> (ElementNameOrWildcard ("," TypeName "?"?)?)? ")"
  -->

  <xsl:template match="ElementTest" mode="xpath">
    <xsl:text>element(</xsl:text>
    <xsl:apply-templates select="*[1]" mode="xpath"/>
    <xsl:if test="*[2]">
      <xsl:text>,</xsl:text>
      <xsl:apply-templates select="*[2]" mode="xpath"/>
    </xsl:if>
    <xsl:text>)</xsl:text>
  </xsl:template>

  <!-- [133] SchemaElementTest ::=
       <"schema-element" "("> ElementDeclaration ")"
  -->

  <xsl:template match="SchemaElementTest" mode="xpath">
    <xsl:text>schema-element(</xsl:text>
    <xsl:apply-templates select="*" mode="xpath"/>
    <xsl:text>)</xsl:text>
  </xsl:template>


  <!-- [134] ElementDeclaration ::=
       ElementName
  -->


  <!-- [135] AttributeName ::=
       QName
  -->


  <!-- [136] ElementName ::=
       QName
  -->


  <!-- [137] TypeName ::=
       QName
  -->


  <!-- [138] IntegerLiteral ::=
       Digits
  -->


  <!-- [139] DecimalLiteral ::=
       ("." Digits) | (Digits "." [0-9]*)
  -->


  <!-- [140] DoubleLiteral ::=
       (("." Digits) | (Digits ("." [0-9]*)?)) [eE] [+-]? Digits
  -->

  <!-- [141] URILiteral ::=
       StringLiteral
  -->

  <!-- [142] StringLiteral ::=
       ('"' (PredefinedEntityRef | CharRef | ('"' '"') | [^"&])* '"') | 
       ("'" (PredefinedEntityRef | CharRef | ("'" "'") | [^'&])* "'")
  -->

  <xsl:template match="StringLiteral" mode="xpath">
    <xsl:value-of select="if (starts-with(data,'&quot;')) then xq:chars(replace(data,'&amp;quot;','&quot;&quot;'))
			  else if (starts-with(data,'''')) then xq:chars(replace(data,'&amp;apos;',''''''))
			  else
			  xq:chars(data)"/>
  </xsl:template>

  <!-- [143] PITarget ::=
       [http://www.w3.org/TR/REC-xml#NT-PITarget]XML
  -->


  <!-- [144] VarName ::=
       QName
  -->



  <!-- [145] ValidationMode ::=
       "lax" | "strict"
  -->


  <!-- [146] Digits ::=
       [0-9]+
  -->



  <!-- [147] PredefinedEntityRef ::=
       "&" ("lt" | "gt" | "amp" | "quot" | "apos") ";"
  -->

  <xsl:template match="PredefinedEntityRef|CharRef" mode="xslt">
    <xsl:value-of select="xq:chars(data)"/>
  </xsl:template>

  <!-- [148] CharRef ::=
       [http://www.w3.org/TR/REC-xml#NT-CharRef]XML
  -->

  <!-- Shares code with PredefinedEntityRef template -->

  <!-- [149] EscapeQuot ::=
       '""'
  -->

  <xsl:template match="EscapeQuot/data" mode="xslt">"</xsl:template>

  <!-- [150] EscapeApos ::=
       "''"
  -->

  <xsl:template match="EscapeApos/data" mode="xslt">'</xsl:template>

  <!-- [151] ElementContentChar ::=
       Char - [{}<&]
  -->

  <xsl:template match="ElementContentChar" mode="xslt" priority="222">
    <xsl:value-of select="data"/>
  </xsl:template>


  <!-- [152] QuotAttrContentChar ::=
       Char - ["{}<&]
  -->


  <xsl:template match="QuotAttrContentChar" mode="xslt">
    <xsl:value-of select="translate(data,'&#9;&#10;', '  ')"/>
  </xsl:template>


  <!-- [153] AposAttrContentChar ::=
       Char - ['{}<&]
  -->

  <xsl:template match="AposAttrContentChar" mode="xslt">
    <xsl:value-of select="translate(data,'&#9;&#10;', ' ')"/>
  </xsl:template>

  <xsl:template match="AposAttrContentChar" mode="value">
  </xsl:template>

  <!-- [154] Comment ::=
       "(:" (CommentContents | Comment)* ":)"

  -->

  <!-- comments are dropped in translation (not reported by the xquery parser)-->

  <!-- [155] CommentContents ::=
       (Char+ - (Char* ':)' Char*))
  -->

  <!-- comments are dropped in translation (not reported by the xquery parser)-->

  <!-- [156] QName ::=
       [http://www.w3.org/TR/REC-xml-names/#NT-QName]Names
  -->


  <!-- [157] NCName ::=
       [http://www.w3.org/TR/REC-xml-names/#NT-NCName]Names
  -->
  <!-- [158] S ::=
       [http://www.w3.org/TR/REC-xml#NT-S]XML
  -->


  <!-- [159] Char ::=
       [http://www.w3.org/TR/REC-xml#NT-Char]XML
  -->

  <!--===================-->


  <xsl:template match="*">
    <xsl:message terminate="yes">Unsupported element: <xsl:value-of select="name()"/></xsl:message>
  </xsl:template>

  <xsl:template match="*" mode="xpath">
    <xsl:apply-templates select="*" mode="xpath"/>
  </xsl:template>

  <xsl:template match="data" mode="xpath">
    <xsl:text> </xsl:text>
    <xsl:value-of select="."/>
    <xsl:text> </xsl:text>
  </xsl:template>
  <!--===================-->

  <!--
      A top level error element indicates a syntax error was reported by the parser.
      Some syntax errors (mostly relating to bad character references) get past the
      parser and are detected here .

Currently generate error() Perhaps could try hrder to generate a more appropriate error
code in each case.
  -->



  <!--===================-->

  <!-- generates mismatched quotes on error: a bit cheap but I don't want to generate errors during conversion 
       (I think) and can't call error() in the middle of a string in the generated code.
  -->
  <xsl:function name="xq:chars">
    <xsl:param name="s"/>
    <xsl:value-of>
      <xsl:analyze-string select="$s" regex="&amp;(#?)(x?)([0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);">
	<xsl:matching-substring>
	  <xsl:choose>
	    <xsl:when test="regex-group(2)='x'">
	      <xsl:variable name="cp" select="xq:hex(
					      for $i in string-to-codepoints(upper-case(regex-group(3)))
					      return if ($i &gt; 64) then $i - 55 else $i - 48)"/>
	      <xsl:value-of select="if ($cp=(9,10,13) or ($cp &gt; 31)) then codepoints-to-string($cp) else 'ERROR&quot;'''"/>
	    </xsl:when>
	    <xsl:when test="regex-group(1)='#'">
	      <xsl:variable name="cp" select="xs:integer(regex-group(3))"/>
	      <xsl:value-of select="if ($cp=(9,10,13) or ($cp &gt; 31)) then codepoints-to-string($cp) else 'ERROR&quot;'''"/>
	    </xsl:when>
	    <xsl:when test="$xq:ents/key('xq:ents',regex-group(3))">
	      <xsl:value-of select="$xq:ents/key('xq:ents',regex-group(3))"/>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:message>xq2xqx: Unknown entity: <xsl:value-of select="regex-group(3)"/></xsl:message>
	      <xsl:text>ERROR'"</xsl:text>
	      <xsl:value-of select="regex-group(3)"/>
	      <xsl:text>;</xsl:text>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:matching-substring>
	<xsl:non-matching-substring>
	  <xsl:value-of select="."/>
	</xsl:non-matching-substring>
      </xsl:analyze-string>
    </xsl:value-of>
  </xsl:function>


  <xsl:function name="xq:hex">
    <xsl:param name="x"/>
    <xsl:value-of
	select="if (empty($x)) then 0 else ($x[last()] + 16* xq:hex($x[position()!=last()]))"/>
  </xsl:function>

  <xsl:variable name="xq:ents">
    <entity name="amp">&amp;</entity>
    <entity name="quot">&quot;</entity>
    <entity name="apos">&apos;</entity>
    <entity name="lt">&lt;</entity>
    <entity name="gt">&gt;</entity>
  </xsl:variable>

  <xsl:key name="xq:ents" match="entity" use="@name"/>

  <xsl:function name="xq:staticerror">
    <xsl:param name="code" as="xs:string"/>
    <xsl:param name="message" as="xs:string"/>
    <axsl:stylesheet version="2.0">
      <axsl:param name="input"/>
      <axsl:template name="main">
	<axsl:sequence select="error(QName('http://www.w3.org/2005/xqt-errors','{$code}'),'{$message}')"/>
      </axsl:template>
    </axsl:stylesheet>
  </xsl:function>
  
  <xsl:template match="error" >
    <axsl:stylesheet version="2.0">
      <axsl:param name="input"/>
      <axsl:template name="main">
	<axsl:sequence select="error()"/>
	<!--<xsl:message><xsl:value-of select="data"/></xsl:message>-->
      </axsl:template>
    </axsl:stylesheet>
  </xsl:template>


  <xsl:template match="Module[.//ForClause[VarName/QName=PositionalVar/VarName/QName]]" mode="xslt">
    <xsl:sequence select="xq:staticerror('XQST0089','repeated variable in for clause')"/>
  </xsl:template>

  <xsl:template match="Module[*/Prolog/NamespaceDecl[
  (not(NCName/data='xml') and 
     URILiteral/substring(StringLiteral/data,2,string-length(StringLiteral/data)-2)='http://www.w3.org/XML/1998/namespace')
  or
  (NCName/data=('xml','xmlns'))]]" mode="xslt">
    <xsl:sequence select="xq:staticerror('XQST0070','Rebinding XML Namespace')"/>
  </xsl:template>


  <xsl:template match="Module[*/Prolog/NamespaceDecl[
		       NCName=following-sibling::NamespaceDecl/NCName
		       ]]" mode="xslt">
    <xsl:sequence select="xq:staticerror('XQST0033','duplicated namespace prefix')"/>
  </xsl:template>


  <xsl:template match="Module[*/Prolog/OptionDecl[
		       not(substring-before(QName/data,':')=('local','fn','xs',../NamespaceDecl/NCName/string()))
		       ]]" mode="xslt">
    <xsl:sequence select="xq:staticerror('XQST0081','Undeclared option namespace')"/>
  </xsl:template>
  
  <xsl:template match="Module[VersionDecl/StringLiteral[1][not(data=('''1.0''','&quot;1.0&quot;'))]]" mode="xslt">
    <xsl:sequence select="xq:staticerror('XQST0031','version != 1.0')"/>
  </xsl:template>
  
  <xsl:template match="Module[VersionDecl/StringLiteral[2][not(matches(data,'^.[a-zA-Z0-9\-]+.$'))]]" mode="xslt">
    <xsl:sequence select="xq:staticerror('XQST0087','bad encoding')"/>
  </xsl:template>
  
  <xsl:template match="Module[*/Prolog/(Setter/BoundarySpaceDecl)[2]]" mode="xslt">
    <xsl:sequence select="xq:staticerror('XQST0068','2 boundary space decln')"/>
  </xsl:template>

  <xsl:template match="Module[*/Prolog/(Setter/ConstructionDecl)[2]]" mode="xslt">
    <xsl:sequence select="xq:staticerror('XQST0067','2 construction mode decln')"/>
  </xsl:template>
  
  <xsl:template match="Module[*/Prolog/(Setter/BaseURIDecl)[2]]" mode="xslt">
    <xsl:sequence select="xq:staticerror('XQST0032','2 base URI decln')"/>
  </xsl:template>

  <xsl:template match="Module[*/Prolog/(Setter/DefaultCollationDecl)[2]]" mode="xslt">
    <xsl:sequence select="xq:staticerror('XQST0038','2 default collation decln')"/>
  </xsl:template>

  <xsl:template match="Module[*/Prolog/(Setter/CopyNamespacesDecl)[2]]" mode="xslt">
    <xsl:sequence select="xq:staticerror('XQST0055','2 copy ns decln')"/>
  </xsl:template>

  <xsl:template match="Module[*/Prolog/(Setter/OrderingModeDecl)[2]]" mode="xslt">
    <xsl:sequence select="xq:staticerror('XQST0065','2 ordering mode decln')"/>
  </xsl:template>
  
  
  <xsl:template match="Module[.//DirAttributeList/TagQName[.=following-sibling::TagQName]]" mode="xslt">
    <xsl:choose>
      <xsl:when test=".//DirAttributeList/TagQName[.=following-sibling::TagQName][starts-with(data,'xmlns')]">
	<xsl:sequence select="xq:staticerror('XQST0071','Duplicate namespace declaration')"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:sequence select="xq:staticerror('XQST0040','Duplicate attribute')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="Module[*/Prolog/(Setter/EmptyOrderDecl)[2]]" mode="xslt">
    <xsl:sequence select="xq:staticerror('XQST0069','2 empty order decln')"/>
  </xsl:template>



<!-- disable 1.1 support for now -->
  <xsl:template match="Module[.//DirAttributeList/TagQName[starts-with(.,'xmlns:')][not(following-sibling::DirAttributeValue[1]/*[3])]]" mode="xslt">
    <xsl:sequence select="xq:staticerror('XQST0085','undeclare prefix')"/>
  </xsl:template>


  <xsl:template match="Module[MainModule/Prolog/DefaultNamespaceDecl[data='element'][2]]" mode="xslt">
    <xsl:sequence select="xq:staticerror('XQST0066','2 default element namespace declarations')"/>
  </xsl:template>

  <xsl:template match="Module[MainModule/Prolog/DefaultNamespaceDecl[data='function'][2]]" mode="xslt">
    <xsl:sequence select="xq:staticerror('XQST0066','2 default function namespace declarations')"/>
  </xsl:template>


  <xsl:template match="Module[string-length(MainModule/Prolog/Import/ModuleImport/URILiteral[1]/StringLiteral/data)=2]" mode="xslt">
    <xsl:sequence select="xq:staticerror('XQST0088','empty target namespace in module import')"/>
  </xsl:template>

</xsl:stylesheet>



