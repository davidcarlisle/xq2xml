<!--
    xq2xqx.xsl
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
		exclude-result-prefixes="xs saxon xq">
  <xsl:param name="xq" select="'&lt;error/&gt;'"/>
  <xsl:param name="dump" select="'no'"/>
  <xsl:param name="error" select="'FOER0000'"/>

  <xsl:output method="xml"  omit-xml-declaration="yes" encoding="US-ASCII" indent="yes"/>

  <!--
      Initial template, processes the query in the document specified in the global xq
      parameter. Dumps the intermediate xml if the dump parameter is set.
  -->

  <!-- orderBy59 -->
  <xsl:template name="main">

    <xsl:variable name="xqtext" select="unparsed-text($xq,'utf-8')"/>
    <xsl:variable name="xqxml1" select="xq:convert(unparsed-text($xq,'utf-8'))"/>
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
    <xsl:result-document href="{$xq}x">
      <xsl:variable name="x">
	<xsl:apply-templates select="$xqxml"/>
      </xsl:variable>
<!--
<xsl:message>
[[[
<xsl:copy-of select="$x"/>
]]]
</xsl:message>
-->
	<xsl:apply-templates mode="x2" select="$x"/>
    </xsl:result-document>
  </xsl:template>


  <xsl:template match="*" mode="x2">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="x2"/>
    </xsl:copy>
  </xsl:template>

 <xsl:template match="xqx:sequenceExpr[xqx:sequenceExpr and not(*[2])]" mode="x2">
   <xsl:apply-templates mode="x2" select="*"/>
 </xsl:template>

 <xsl:template match="xqx:elementContent" mode="x2">
   <xqx:elementContent>
     <xsl:for-each-group select="*" group-adjacent="exists(self::xqx:stringConstantExpr)">
       <xsl:choose>
	 <xsl:when test="current-grouping-key()">
	   <xqx:stringConstantExpr>
	     <xqx:value>
	       <xsl:value-of select="current-group()/xqx:value" separator=""/>
	     </xqx:value>
	   </xqx:stringConstantExpr>
	 </xsl:when>
	 <xsl:otherwise>
	   <xsl:copy-of select="current-group()"/>
	 </xsl:otherwise>
       </xsl:choose>
     </xsl:for-each-group>
   </xqx:elementContent>
 </xsl:template>

  <!--===================-->

  <!--
      The XQuery EBNF.
      The first two productions are not offical but are reported by the XQuery Parser QueryList is
      translated to the nonstandard xqx:queryList if it contains more than one module, this allows
      multiple queries in the same xqx document.
  -->


  <!-- [-1] XPath2 ::=
       QueryList
  -->

  <xsl:template match="XPath2">
    <xsl:apply-templates select="*"/>
  </xsl:template>


  <!-- [0] QueryList ::=
       Module+
  -->

  <xsl:template match="QueryList">
    <xsl:apply-templates select="*"/>
  </xsl:template>


  <xsl:template match="QueryList[Module[2]]">
    <xqx:queryList><xsl:apply-templates select="*"/></xqx:queryList>
  </xsl:template>


<!-- [1] Module ::=
  VersionDecl? (LibraryModule | MainModule)
-->

  <xsl:template match="Module">
    <xqx:module>
      <xsl:apply-templates select="*">
	  <xsl:with-param name="preservespace" as="xs:boolean" tunnel="yes" select=
			  "exists(*/Prolog/Setter/BoundarySpaceDecl[data='preserve'])"/>
      </xsl:apply-templates>
    </xqx:module>
  </xsl:template>


<!-- [2] VersionDecl ::=
  "xquery" "version" StringLiteral ("encoding" StringLiteral)? Separator
-->

  <xsl:template match="VersionDecl">
    <xqx:versionDecl>
      <xqx:version>
	<xsl:value-of select="substring(StringLiteral[1]/data,2,string-length(StringLiteral[1]/data)-2)"/>
      </xqx:version>
    </xqx:versionDecl>
  </xsl:template>

<!-- [3] MainModule ::=
  Prolog QueryBody
-->

  <xsl:template match="MainModule">
    <xqx:mainModule>
      <xsl:apply-templates select="*"/>
    </xqx:mainModule>
  </xsl:template>

<!-- [4] LibraryModule ::=
  ModuleDecl Prolog
-->

  <xsl:template match="LibraryModule">
    <xqx:libraryModule>
      <xsl:apply-templates select="*"/>
    </xqx:libraryModule>
  </xsl:template>


<!-- [5] ModuleDecl ::=
  "module" "namespace" NCName "=" URILiteral Separator
-->

  <xsl:template match="ModuleDecl">
    <xqx:moduleDecl>
      <xsl:apply-templates select="*"/>
    </xqx:moduleDecl>
  </xsl:template>

  <xsl:template match="ModuleDecl/NCName">
    <xqx:prefix><xsl:value-of select="data"/></xqx:prefix>
  </xsl:template>

<!-- [6] Prolog ::=
  ((DefaultNamespaceDecl | Setter | NamespaceDecl | Import) Separator)*
  ((VarDecl | FunctionDecl | OptionDecl) Separator)*
-->

  <xsl:template match="Prolog[not(*)]"/>

  <xsl:template match="Prolog">
    <xqx:prolog>
      <xsl:apply-templates select="*"/>
    </xqx:prolog>
  </xsl:template>

<!-- [7] Setter ::=
  BoundarySpaceDecl | DefaultCollationDecl | BaseURIDecl | ConstructionDecl
  | OrderingModeDecl | EmptyOrderDecl | CopyNamespacesDecl
-->

  <xsl:template match="Setter">
    <xsl:apply-templates select="*"/>
  </xsl:template>

<!-- [8] Import ::=
  SchemaImport | ModuleImport
-->

  <xsl:template match="Import">
    <xsl:apply-templates select="*"/>
  </xsl:template>


<!-- [9] Separator ::=
  ";"
-->

  <xsl:template match="Separator"/>

 <!-- [10] NamespaceDecl ::=
  "declare" "namespace" NCName "=" URILiteral
-->


  <xsl:template match="NamespaceDecl">
    <xqx:namespaceDecl>
      <xsl:apply-templates select="*"/>
    </xqx:namespaceDecl>
  </xsl:template>

  <xsl:template match="NamespaceDecl/NCName">
    <xqx:prefix><xsl:value-of select="data"/></xqx:prefix>
  </xsl:template>


<!-- [11] BoundarySpaceDecl ::=
  "declare" "boundary-space" ("preserve" | "strip")
-->


  <xsl:template match="BoundarySpaceDecl">
<!--
    <xqx:boundarySpaceDecl>
      <xsl:value-of select="(XMLSpaceStrip|XMLSpacePreserve|Strip|Preserve)"/>
    </xqx:boundarySpaceDecl>
-->
  </xsl:template>

<!-- [12] DefaultNamespaceDecl ::=
  "declare" "default" ("element" | "function") "namespace" URILiteral
-->

  <xsl:template match="DefaultNamespaceDecl">
    <xqx:defaultNamespaceDecl>
      <xqx:defaultNamespaceCategory>
	<xsl:value-of select="data"/>
      </xqx:defaultNamespaceCategory>
      <xsl:apply-templates select="*"/>
    </xqx:defaultNamespaceDecl>
  </xsl:template>


<!-- [13] OptionDecl ::=
  "declare" "option" QName StringLiteral
-->

  <xsl:template match="OptionDecl">
    <xqx:optionDecl>
      <xqx:optionName>
	<xsl:apply-templates select="QName" mode="qname"/>
      </xqx:optionName>
      <xqx:optionContents>
	<xsl:value-of select="substring(StringLiteral/data,2,string-length(StringLiteral/data)-2)"/>
      </xqx:optionContents>
    </xqx:optionDecl>
  </xsl:template>

<!-- [14] OrderingModeDecl ::=
  "declare" "ordering" ("ordered" | "unordered")
-->

  <xsl:template match="OrderingModeDecl">
    <xqx:orderingModeDecl>
      <xsl:value-of select="data"/>
    </xqx:orderingModeDecl>
  </xsl:template>

<!-- [15] EmptyOrderDecl ::=
  "declare" "default" "order" "empty" ("greatest" | "least")
-->

  <xsl:template match="EmptyOrderDecl">
    <xqx:emptyOrderingDecl>
      <xsl:value-of select="'empty',*/data"/>
    </xqx:emptyOrderingDecl>
  </xsl:template>


<!-- [16] CopyNamespacesDecl ::=
  "declare" "copy-namespaces" PreserveMode "," InheritMode
-->

  <xsl:template match="CopyNamespacesDecl">
    <xqx:copyNamespacesDecl>
      <xsl:apply-templates select="(PreserveMode|InheritMode)"/>
    </xqx:copyNamespacesDecl>
  </xsl:template>


<!-- [17] PreserveMode ::=
  "preserve" | "no-preserve"
-->

  <xsl:template match="PreserveMode">
    <xqx:preserveMode><xsl:value-of select="data"/></xqx:preserveMode>
  </xsl:template>

  <!-- [18] InheritMode ::=
       "inherit" | "no-inherit"
  -->

  <xsl:template match="InheritMode">
    <xqx:inheritMode><xsl:value-of select="data"/></xqx:inheritMode>
  </xsl:template>

<!-- [19] DefaultCollationDecl ::=
  "declare" "default" "collation" URILiteral
-->

  <xsl:template match="DefaultCollationDecl">
    <xqx:defaultCollationDecl>
      <xsl:value-of select="substring(URILiteral/StringLiteral/data,2,string-length(URILiteral/StringLiteral/data)-2)"/>
    </xqx:defaultCollationDecl>
  </xsl:template>

<!-- [20] BaseURIDecl ::=
  "declare" "base-uri" URILiteral
-->

  <xsl:template match="BaseURIDecl">
    <xqx:baseUriDecl>
      <xsl:variable name="q" select="substring(URILiteral/StringLiteral/data,1,1)"/>
	<xsl:value-of select="xq:chars(replace(substring(URILiteral/StringLiteral/data,2,string-length(URILiteral/StringLiteral/data)-2),concat($q,$q),$q))"/>
    </xqx:baseUriDecl>
  </xsl:template>

<!-- [21] SchemaImport ::=
  "import" "schema" SchemaPrefix? URILiteral ("at" URILiteral ("," URILiteral)*)?
-->

  <xsl:template match="SchemaImport">
    <xqx:schemaImport>
      <xsl:apply-templates select="*"/>
    </xqx:schemaImport>
  </xsl:template>

<!-- [22] SchemaPrefix ::=
  ("namespace" NCName "=") | ("default" "element" "namespace")
-->

  <xsl:template match="SchemaPrefix">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="SchemaPrefix[not(*)]">
    <xqx:defaultElementNamespace/>
  </xsl:template>

<!--??
  <xsl:template match="SchemaPrefix/NCName" priority="2">
    <xqx:prefix><xsl:value-of select="data"/></xqx:prefix>
  </xsl:template>
-->

  <xsl:template match="Import//NCName">
    <xqx:namespacePrefix><xsl:value-of select="data"/></xqx:namespacePrefix>
  </xsl:template>

<!--
  <xsl:template match="DefaultElement">
    <xqx:defaultElementNamespace/>
  </xsl:template>
-->

<!-- [23] ModuleImport ::=
  "import" "module" ("namespace" NCName "=")? URILiteral ("at" URILiteral ("," URILiteral)*)?
-->

  <xsl:template match="ModuleImport">
    <xqx:moduleImport>
      <xsl:apply-templates select="*"/>
    </xqx:moduleImport>
  </xsl:template>

  <xsl:template match="Import/*/URILiteral[1]">
    <xqx:targetNamespace><xsl:value-of select="substring(StringLiteral/data,2,string-length(StringLiteral/data)-2)"/></xqx:targetNamespace>
  </xsl:template>

  <xsl:template match="Import/*/URILiteral[position()&gt;1]">
    <xqx:targetLocation><xsl:value-of select="substring(StringLiteral/data,2,string-length(StringLiteral/data)-2)"/></xqx:targetLocation>
  </xsl:template>

<!-- [24] VarDecl ::=
  "declare" "variable" "$" QName TypeDeclaration? ((":=" ExprSingle) | "external")
-->

  <xsl:template match="DefineVariable" priority="10"/>

  <xsl:template match="VarDecl">
    <xqx:varDecl>
      <xsl:apply-templates select="*"/>
      </xqx:varDecl>
  </xsl:template>
  
  <xsl:template match="External" priority="10">
    <xqx:external/>	 
  </xsl:template>


  <xsl:template match="VarDecl/*[not(self::Separator|self::TypeDeclaration|self::VarName|self::QName)]" priority="9">
    <xqx:varValue>
      <xsl:next-match/>
    </xqx:varValue>
  </xsl:template>


<!-- [25] ConstructionDecl ::=
  "declare" "construction" ("strip" | "preserve")
-->

  <xsl:template match="ConstructionDecl">
    <xqx:constructionDecl>
      <xsl:value-of  select="data"/>
    </xqx:constructionDecl>
  </xsl:template>

<!-- [26] FunctionDecl ::=
  "declare" "function" QName "(" ParamList? ")" ("as" SequenceType)? (EnclosedExpr | "external")
-->

  <xsl:template match="FunctionDecl">
    <xqx:functionDecl>
      <xqx:functionName>
	<xsl:apply-templates select="QName" mode="qname"/>
      </xqx:functionName>
      <xqx:paramList>
	<xsl:apply-templates select="ParamList/*"/>
      </xqx:paramList>
      <xsl:apply-templates select="*"/>
    </xqx:functionDecl>
  </xsl:template>

  <xsl:template match="FunctionDecl/QName" priority="11"/>

  <xsl:template match="FunctionDecl/External" priority="11">
    <xqx:externalDefinition/>
  </xsl:template>

  <xsl:template match="FunctionDecl/EnclosedExpr">
    <xqx:functionBody>
      <xsl:apply-templates select="*"/>
    </xqx:functionBody>
  </xsl:template>

  <xsl:template match="RparAs">
    <xsl:apply-templates select="*"/>
  </xsl:template>

<!-- [27] ParamList ::=
  Param ("," Param)*
-->

  <xsl:template match="ParamList"/>

<!-- [28] Param ::=
  "$" QName TypeDeclaration?
-->

  <xsl:template match="Param">
    <xqx:param>
      <xsl:apply-templates select="*"/>
    </xqx:param>
  </xsl:template>


  <!-- [29] EnclosedExpr ::=
       "{" Expr "}"
  -->

  <xsl:template match="EnclosedExpr">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="DirElemContent/CommonContent/EnclosedExpr">
    <xqx:sequenceExpr>
    <xsl:apply-templates select="*"/>
    </xqx:sequenceExpr>
  </xsl:template>


  <!-- [30] QueryBody ::=
       Expr
  -->

  <xsl:template match="QueryBody">
    <xqx:queryBody>
      <xsl:apply-templates select="*"/>
    </xqx:queryBody>
  </xsl:template>


  <!-- [31] Expr ::=
       ExprSingle ("," ExprSingle)*
  -->

  <xsl:template match="Expr">
    <xsl:apply-templates select="*"/>
  </xsl:template>


  <xsl:template match="Expr[*[2]]" priority="2">
    <xqx:sequenceExpr>
      <xsl:apply-templates select="*"/>
    </xqx:sequenceExpr>
  </xsl:template>

  <!-- [32] ExprSingle ::=
       FLWORExpr | QuantifiedExpr | TypeswitchExpr | IfExpr | OrExpr
  -->

  <!-- Not reported by the parser. -->

  <!-- [33] FLWORExpr ::=
       (ForClause | LetClause)+ WhereClause? OrderByClause? "return" ExprSingle
  -->

  <xsl:template match="FLWORExpr">
    <xqx:flworExpr>
      <xsl:apply-templates select="ForClause|LetClause|WhereClause|OrderByClause"/>
      <xqx:returnClause>
	<xsl:apply-templates select="*[last()]"/>
      </xqx:returnClause>
    </xqx:flworExpr>
  </xsl:template>

<!-- [34] ForClause ::=
  "for" "$" VarName TypeDeclaration? PositionalVar? "in" ExprSingle
  ("," "$" VarName TypeDeclaration? PositionalVar? "in" ExprSingle)*
-->

  <xsl:template match="ForClause">
    <xqx:forClause>
       <xsl:apply-templates select="VarName"/>
    </xqx:forClause>
  </xsl:template>

  <xsl:template match="ForClause/VarName">
      <xqx:forClauseItem>
	<xqx:typedVariableBinding>
	  <xqx:varName><xsl:apply-templates select="QName" mode="qname"/></xqx:varName>
	  <xsl:apply-templates select="following-sibling::*[1][self::TypeDeclaration]"/>
	</xqx:typedVariableBinding>
	<xsl:apply-templates select="following-sibling::*[position()&lt;3][self::PositionalVar]"/>
	<xqx:forExpr>
	  <xsl:apply-templates select="following-sibling::*[not(self::TypeDeclaration|self::PositionalVar)][1]"/>
	</xqx:forExpr>
      </xqx:forClauseItem>
  </xsl:template>

  <!-- [35] PositionalVar ::=
       "at" "$" VarName
  -->

  <xsl:template match="PositionalVar">
    <xqx:positionalVariableBinding>
      <xsl:apply-templates select="VarName/QName" mode="qname"/>
    </xqx:positionalVariableBinding>
  </xsl:template>


<!-- [36] LetClause ::=
  "let" "$" VarName TypeDeclaration? ":=" ExprSingle
  ("," "$" VarName TypeDeclaration? ":=" ExprSingle)*
-->

  <xsl:template match="LetClause">
    <xqx:letClause>
      <xsl:for-each select="VarName">
	<xqx:letClauseItem>
	  <xqx:typedVariableBinding>
	    <xqx:varName><xsl:apply-templates select="QName" mode="qname"/></xqx:varName>
	    <xsl:apply-templates select="following-sibling::*[1][self::TypeDeclaration]"/>
	  </xqx:typedVariableBinding>
	  <xqx:letExpr>
	    <xsl:apply-templates select="following-sibling::*[not(self::TypeDeclaration|self::PositionalVar)][1]"/>
	  </xqx:letExpr>
	</xqx:letClauseItem>
      </xsl:for-each>
    </xqx:letClause>
  </xsl:template>

  <!-- [37] WhereClause ::=
       "where" ExprSingle
  -->

  <xsl:template match="WhereClause">
    <xqx:whereClause>
      <xsl:apply-templates select="*"/>
    </xqx:whereClause>
  </xsl:template>

<!-- [38] OrderByClause ::=
  (("order" "by") | ("stable" "order" "by")) OrderSpecList
-->

  <xsl:template match="OrderByClause">
    <xqx:orderByClause>
      <xsl:apply-templates select="*"/>
    </xqx:orderByClause>
  </xsl:template>

  <xsl:template match="OrderByClause/data[.='stable']" priority="2">
    <xqx:stable/>
  </xsl:template>

  <!-- [39] OrderSpecList ::=
       OrderSpec ("," OrderSpec)*
  -->

  <xsl:template match="OrderSpecList">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <!-- [40] OrderSpec ::=
       ExprSingle OrderModifier
  -->

  <xsl:template match="OrderSpec">
    <xqx:orderBySpec>
      <xqx:orderByExpr>
	<xsl:apply-templates select="*[not(self::OrderModifier)]"/>
      </xqx:orderByExpr>
      <xsl:apply-templates select="OrderModifier"/>
    </xqx:orderBySpec>
  </xsl:template>

<!-- [41] OrderModifier ::=
  ("ascending" | "descending")? ("empty" ("greatest" | "least"))? ("collation" URILiteral)?
-->

  <xsl:template match="OrderModifier[not(*)]"/>

  <xsl:template match="OrderModifier">
    <xqx:orderModifier>
      <xsl:apply-templates select="*"/>
    </xqx:orderModifier>
  </xsl:template>

  <xsl:template match="Descending">
    <xqx:orderingKind>descending</xqx:orderingKind>
  </xsl:template>

  <xsl:template match="Ascending">
    <xqx:orderingKind>ascending</xqx:orderingKind>
  </xsl:template>


  <xsl:template match="Greatest">
    <xqx:emptyOrderingMode>empty greatest</xqx:emptyOrderingMode>
  </xsl:template>

  <xsl:template match="Least">
    <xqx:emptyOrderingMode>empty least</xqx:emptyOrderingMode>
  </xsl:template>

  <xsl:template match="Collation"/>

  <xsl:template match="OrderModifier/URILiteral">
    <xqx:collation>
      <xsl:value-of select="substring(StringLiteral/data,2,string-length(StringLiteral/data)-2)"/>
    </xqx:collation>
  </xsl:template>


<!-- [42] QuantifiedExpr ::=
  ("some" | "every") "$" VarName TypeDeclaration? "in" ExprSingle
  ("," "$" VarName TypeDeclaration? "in" ExprSingle)* "satisfies" ExprSingle
-->
  
  <xsl:template match="QuantifiedExpr">
    <xqx:quantifiedExpr>
    <xqx:quantifier>
    <xsl:value-of select="data"/>
    </xqx:quantifier>
    <xsl:apply-templates select="VarName"/>
    <xqx:predicateExpr>
      <xsl:apply-templates select="*[last()]"/>
    </xqx:predicateExpr>
    </xqx:quantifiedExpr>
  </xsl:template>
  
  
  <xsl:template match="QuantifiedExpr/VarName">
    <xqx:quantifiedExprInClause>
      <xqx:typedVariableBinding>
	<xqx:varName><xsl:apply-templates select="QName" mode="qname"/></xqx:varName>
	<xsl:apply-templates select="following-sibling::*[1][self::TypeDeclaration]"/>
      </xqx:typedVariableBinding>
      <xqx:sourceExpr>
	<xsl:apply-templates select="following-sibling::*[not(self::TypeDeclaration)][1]"/>
      </xqx:sourceExpr>
    </xqx:quantifiedExprInClause>
  </xsl:template>
  
<!-- [43] TypeswitchExpr ::=
  "typeswitch" "(" Expr ")" CaseClause+ "default" ("$" VarName)? "return" ExprSingle
-->

  <xsl:template match="TypeswitchExpr">
    <xqx:typeswitchExpr>
      <xqx:argExpr>
	<xsl:apply-templates select="*[1]"/>
      </xqx:argExpr>
      <xsl:apply-templates select="CaseClause|*[not(self::CaseClause)][last()]"/>
    </xqx:typeswitchExpr>
  </xsl:template>

  <xsl:template match="TypeswitchExpr/VarName" priority="4">
    <xqx:variableBinding>
      <xsl:apply-templates select="QName" mode="qname"/>
    </xqx:variableBinding>
  </xsl:template>


  <xsl:template match="TypeswitchExpr/*[last()]" priority="4">
    <xqx:typeswitchExprDefaultClause>
      <xsl:apply-templates select="preceding-sibling::VarName[1]"/>
      <xqx:resultExpr>
	<xsl:next-match/>
      </xqx:resultExpr>
    </xqx:typeswitchExprDefaultClause>
  </xsl:template>


<!-- [44] CaseClause ::=
  "case" ("$" VarName "as")? SequenceType "return" ExprSingle
-->

  <xsl:template match="CaseClause" priority="2">
    <xqx:typeswitchExprCaseClause>
      <xsl:apply-templates select="*"/>
    </xqx:typeswitchExprCaseClause>
  </xsl:template>

  <xsl:template match="Case"/>

  <xsl:template match="CaseClause/VarName">
    <xqx:variableBinding>
      <xsl:apply-templates select="QName" mode="qname"/>
    </xqx:variableBinding>
  </xsl:template>

  <xsl:template match="CaseClause/SequenceType">
    <xqx:sequenceType>
      <xsl:apply-templates select="*"/>
    </xqx:sequenceType>
  </xsl:template>

  <xsl:template match="CaseClause/*[last()]" priority="10">
    <xqx:resultExpr>
      <xsl:next-match/>
    </xqx:resultExpr>
  </xsl:template>

<!-- [45] IfExpr ::=
  "if" "(" Expr ")" "then" ExprSingle "else" ExprSingle
-->

  <xsl:template match="IfExpr">
    <xqx:ifThenElseExpr>
      <xqx:ifClause>
	<xsl:apply-templates select="*[1]"/>
      </xqx:ifClause>
      <xqx:thenClause>
	<xsl:apply-templates select="*[2]"/>
      </xqx:thenClause>
      <xqx:elseClause>
	<xsl:apply-templates select="*[3]"/>
      </xqx:elseClause>
    </xqx:ifThenElseExpr>
  </xsl:template>

  <!-- [46] OrExpr ::=
       AndExpr ( "or" AndExpr )*
  -->

  <xsl:template match="OrExpr">
    <xqx:orOp>
      <xqx:firstOperand>
	<xsl:apply-templates select="*[2]"/>
      </xqx:firstOperand>
      <xqx:secondOperand>
	<xsl:apply-templates select="*[3]"/>
      </xqx:secondOperand>
    </xqx:orOp>
  </xsl:template>

  <!-- [47] AndExpr ::=
       ComparisonExpr ( "and" ComparisonExpr )*
  -->

  <xsl:template match="AndExpr">
    <xqx:andOp>
      <xqx:firstOperand>
	<xsl:apply-templates select="*[2]"/>
      </xqx:firstOperand>
      <xqx:secondOperand>
	<xsl:apply-templates select="*[3]"/>
      </xqx:secondOperand>
    </xqx:andOp>
  </xsl:template>

  <!-- [48] ComparisonExpr ::=
       RangeExpr ( (ValueComp
       | GeneralComp
       | NodeComp) RangeExpr )?
  -->


  <xsl:variable name="ComparisonExpr">
    <c op="=">xqx:equalOp</c>
    <c op="!=">xqx:notEqualOp</c>
    <c op="&lt;">xqx:lessThanOp</c>
    <c op="&gt;">xqx:greaterThanOp</c>
    <c op="&lt;=">xqx:lessThanOrEqualOp</c>
    <c op="&gt;=">xqx:greaterThanOrEqualOp</c>
    <c op="is">xqx:isOp</c>
    <c op="&lt;&lt;">xqx:nodeBeforeOp</c>
    <c op="&gt;&gt;">xqx:nodeAfterOp</c>
    <c op="eq">xqx:eqOp</c>
    <c op="ne">xqx:neOp</c>
    <c op="lt">xqx:ltOp</c>
    <c op="gt">xqx:gtOp</c>
    <c op="le">xqx:leOp</c>
    <c op="ge">xqx:geOp</c>
    <c op="+">xqx:addOp</c>
    <c op="-">xqx:subtractOp</c>
    <c op="*">xqx:multiplyOp</c>
    <c op="div">xqx:divOp</c>
    <c op="idiv">xqx:idivOp</c>
    <c op="mod">xqx:modOp</c>
    <c op="intersect">xqx:intersectOp</c>
    <c op="except">xqx:exceptOp</c>
  </xsl:variable>

  <xsl:key name="ComparisonExpr" match="c" use="@op"/>

  <xsl:template match="ComparisonExpr|AdditiveExpr|MultiplicativeExpr|IntersectExceptExpr">
    <xsl:element name="{key('ComparisonExpr',data,$ComparisonExpr)}">
      <xqx:firstOperand>
	<xsl:apply-templates select="*[2]"/>
      </xqx:firstOperand>
      <xqx:secondOperand>
	<xsl:apply-templates select="*[3]"/>
      </xqx:secondOperand>
    </xsl:element>
  </xsl:template>

  <!-- [49] RangeExpr ::=
       AdditiveExpr ( "to" AdditiveExpr )?
  -->

  <xsl:template match="RangeExpr">
    <xqx:rangeSequenceExpr>
      <xqx:startExpr>
	<xsl:apply-templates select="*[2]"/>
      </xqx:startExpr>
      <xqx:endExpr>
	<xsl:apply-templates select="*[3]"/>
      </xqx:endExpr>
    </xqx:rangeSequenceExpr>
  </xsl:template>

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

  <xsl:template match="UnionExpr">
    <xqx:unionOp>
      <xqx:firstOperand>
	<xsl:apply-templates select="*[2]"/>
      </xqx:firstOperand>
      <xqx:secondOperand>
	<xsl:apply-templates select="*[3]"/>
      </xqx:secondOperand>
    </xqx:unionOp>
  </xsl:template>


  <!-- [53] IntersectExceptExpr ::=
       InstanceofExpr ( ("intersect" | "except") InstanceofExpr )*
  -->

  <!-- Shares code with ComparisonExpr template -->

<!-- [54] InstanceofExpr ::=
  TreatExpr ( "instance" "of" SequenceType )?
-->

  <xsl:template match="InstanceofExpr">
    <xqx:instanceOfExpr>
      <xqx:argExpr>
	<xsl:apply-templates select="*[1]"/>
      </xqx:argExpr>
      <xsl:apply-templates select="*[2]"/>
    </xqx:instanceOfExpr>
  </xsl:template>

<!-- [55] TreatExpr ::=
  CastableExpr ( "treat" "as" SequenceType )?
-->

  <xsl:template match="TreatExpr">
    <xqx:treatExpr>
      <xqx:argExpr>
	<xsl:apply-templates select="*[1]"/>
      </xqx:argExpr>
      <xsl:apply-templates select="SequenceType"/>
    </xqx:treatExpr>
  </xsl:template>

<!-- [56] CastableExpr ::=
  CastExpr ( "castable" "as" SingleType )?
-->

  <xsl:template match="CastableExpr">
    <xqx:castableExpr>
      <xqx:argExpr>
	<xsl:apply-templates select="*[1]"/>
      </xqx:argExpr>
      <xsl:apply-templates select="*[2]"/>
    </xqx:castableExpr>
  </xsl:template>

<!-- [57] CastExpr ::=
  UnaryExpr ( "cast" "as" SingleType )?
-->

  <xsl:template match="CastExpr">
    <xqx:castExpr>
      <xqx:argExpr>
	<xsl:apply-templates select="*[1]"/>
      </xqx:argExpr>
      <xsl:apply-templates select="SingleType"/>
    </xqx:castExpr>
  </xsl:template>

  <!-- [58] UnaryExpr ::=
       ("-" | "+")* ValueExpr
  -->

  <xsl:template match="UnaryExpr">
    <xsl:choose>
      <xsl:when test="count(Minus) mod 2 = 1">
	<xqx:unaryMinusOp>
	  <xqx:operand>
	    <xsl:apply-templates select="*[not(self::Plus|self::Minus)][1]"/>
	  </xqx:operand>
	</xqx:unaryMinusOp>
      </xsl:when>
      <xsl:when test="Plus|Minus">
	<xqx:unaryPlusOp>
	  <xqx:operand>
	    <xsl:apply-templates select="*[not(self::Plus|self::Minus)][1]"/>
	  </xqx:operand>
	</xqx:unaryPlusOp>
      </xsl:when>
      <xsl:otherwise>
	<xsl:apply-templates select="*[1]"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- [59] ValueExpr ::=
       ValidateExpr | PathExpr | ExtensionExpr
  -->

  <!-- Not reported by the parser -->

  <!-- [60] GeneralComp ::=
       "=" | "!=" | "<" | "<=" | ">" | ">="
  -->

  <!-- Shares code with ComparisonExpr template -->

  <!-- [61] ValueComp ::=
       "eq" | "ne" | "lt" | "le" | "gt" | "ge"
  -->

  <!-- Shares code with ComparisonExpr template -->

  <!-- [62] NodeComp ::=
       "is" | "<<" | ">>"
  -->

  <!-- Shares code with ComparisonExpr template -->

<!-- [63] ValidateExpr ::=
  "validate" ValidationMode? "{" Expr "}"
-->

  <xsl:template match="ValidateExpr">
    <xqx:validateExpr>
      <xsl:apply-templates select="ValidationMode"/>
      <xqx:argExpr>
	<xsl:apply-templates select="LbraceExprEnclosure/following-sibling::*"/>
      </xqx:argExpr>
    </xqx:validateExpr>
  </xsl:template>

  <!-- [64] ValidationMode ::=
       "lax" | "strict"
  -->

  <xsl:template match="ValidationMode">
    <xqx:validationMode>
      <xsl:value-of select="data"/>
    </xqx:validationMode>
  </xsl:template>

  <!-- [65] ExtensionExpr ::=
       Pragma+ "{" Expr? "}"
  -->

  <xsl:template match="ExtensionExpr">
    <xqx:extensionExpr>
      <xsl:apply-templates select="Pragma"/>
      <xsl:if test="Expr">
	<xqx:argExpr>
	  <xsl:apply-templates select="Expr"/>
	</xqx:argExpr>
      </xsl:if>
    </xqx:extensionExpr>
  </xsl:template>

  <!-- [66] Pragma ::=
       "(#" S? QName PragmaContents "#)"
  -->

  <xsl:template match="Pragma">
    <xqx:pragma>
      <xqx:pragmaName>
	<xsl:apply-templates select="QNameForPragma" mode="qname"/>
      </xqx:pragmaName>
      <xqx:pragmaContents>
	<xsl:apply-templates select="PragmaContents"/>
      </xqx:pragmaContents>
    </xqx:pragma>
  </xsl:template>

  <!-- [67] PragmaContents ::=
       (Char* - (Char* '#)' Char*))
  -->

  <xsl:template match="PragmaContents">
    <xsl:value-of select="string-join(ExtensionContentChar/data,'')"/>
  </xsl:template>

  <!-- [68] PathExpr ::=
       ("/" RelativePathExpr?)
       | ("//" RelativePathExpr)
       | RelativePathExpr
  -->

  <xsl:template match="Slash">
    <xqx:rootExpr/>
  </xsl:template>

  <xsl:template match="PathExpr">
    <xqx:pathExpr>
      <xsl:apply-templates select="*"/>
    </xqx:pathExpr>
  </xsl:template>

  <xsl:template match="PathExpr[count(*)=1 and (Constructor|IntegerLiteral | DecimalLiteral | DoubleLiteral|StringLiteral|FunctionCall|Constructor|OrderedExpr|UnorderedExpr)]" priority="2">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="StepExpr[ (Constructor|IntegerLiteral | DecimalLiteral | DoubleLiteral|StringLiteral|FunctionCall|Constructor|OrderedExpr|UnorderedExpr) and PredicateList]" priority="2.5">
    <xqx:stepExpr>
      <xqx:filterExpr>
	<xsl:apply-templates select="*[1]"/>
      </xqx:filterExpr>
      <xsl:apply-templates select="*[position()!=1]"/>
    </xqx:stepExpr>
  </xsl:template>
  
  <xsl:template match="PathExpr[count(*)=1 and (ParenthesizedExpr)]" priority="3">
    <xqx:sequenceExpr>
      <xsl:apply-templates select="ParenthesizedExpr/*"/>
    </xqx:sequenceExpr>
  </xsl:template>

<!--
  <xsl:template match="lPathExpr[*[2]]/Slash" priority="2">
      <xsl:next-match/>
  </xsl:template>
-->

  <xsl:template match="PathExpr[*[2]]/SlashSlash[not(preceding-sibling::*)]" priority="2">
      <xqx:rootExpr/>
    <xsl:next-match/>
  </xsl:template>

  <xsl:template match="PathExpr[*[2]]/varName" priority="2">
    <xqx:stepExpr>
      <xsl:next-match/>
    </xqx:stepExpr>
  </xsl:template>

  <xsl:template match="PathExpr[*[2]]/FunctionCall" priority="2">
    <xqx:stepExpr>
      <xqx:filterExpr>
	<xsl:next-match/>
      </xqx:filterExpr>
    </xqx:stepExpr>
  </xsl:template>

  <xsl:template match="PathExpr[*[2]]/Constructor" priority="2">
    <xqx:stepExpr>
      <xqx:filterExpr>
	<xsl:next-match/>
      </xqx:filterExpr>
    </xqx:stepExpr>
  </xsl:template>

  <xsl:template match="PathExpr[*[2]]/ParenthesizedExpr" priority="2">
    <xqx:stepExpr>
      <xqx:filterExpr>
	<xsl:next-match/>
      </xqx:filterExpr>
    </xqx:stepExpr>
  </xsl:template>

  <xsl:template match="SlashSlash">
    <xqx:stepExpr>
      <xqx:xpathAxis>descendant-or-self</xqx:xpathAxis>
      <xqx:anyKindTest/>
    </xqx:stepExpr>
  </xsl:template>


<!-- [69] RelativePathExpr ::=
  StepExpr (("/" | "//") StepExpr)*
-->

  <!-- Not reported by the parser -->

<!-- [70] StepExpr ::=
  FilterExpr | AxisStep
-->

  <xsl:template match="StepExpr">
    <xqx:stepExpr>
      <xsl:apply-templates select="*"/>
    </xqx:stepExpr>
  </xsl:template>

  <!-- [71] AxisStep ::=
       (ForwardStep | ReverseStep) PredicateList
  -->

  <!-- Not reported by the parser -->

  <!-- [72] ForwardStep ::=
       (ForwardAxis NodeTest) | AbbrevForwardStep
  -->

  <!-- Not reported by the parser -->

 <!-- [73] ForwardAxis ::=
  ("child" "::") | ("descendant" "::") | ("attribute" "::") | ("self" "::")
  | ("descendant-or-self" "::") | ("following-sibling" "::") | ("following" "::")
-->

  <xsl:template match="ForwardAxis">
    <xqx:xpathAxis><xsl:value-of select="data"/></xqx:xpathAxis>
  </xsl:template>

  <!-- [74] AbbrevForwardStep ::=
       "@"? NodeTest
  -->


  <xsl:template match="AbbrevForwardStep">
    <xqx:xpathAxis>
      <xsl:value-of select="if(data='@' or NodeTest/(AttributeTest|SchemaAttributeTest)) then 'attribute' else 'child'"/>
    </xqx:xpathAxis>
    <xsl:apply-templates select="*"/>
  </xsl:template>



  <!-- [75] ReverseStep ::=
       (ReverseAxis NodeTest) | AbbrevReverseStep
  -->

  <!-- Not reported by the parser -->

<!-- [76] ReverseAxis ::=
  ("parent" "::") | ("ancestor" "::") | ("preceding-sibling" "::")
  | ("preceding" "::") | ("ancestor-or-self" "::")
-->

  <xsl:template match="ReverseAxis">
    <xqx:xpathAxis><xsl:value-of select="data"/></xqx:xpathAxis>
  </xsl:template>

  <!-- [77] AbbrevReverseStep ::=
       ".."
  -->

  <xsl:template match="AbbrevReverseStep">
    <xqx:stepExpr>
      <xqx:xpathAxis>parent</xqx:xpathAxis>
      <xqx:anyKindTest/>
    </xqx:stepExpr>
  </xsl:template>

  <xsl:template match="StepExpr/AbbrevReverseStep">
    <xqx:xpathAxis>parent</xqx:xpathAxis>
    <xqx:anyKindTest/>
  </xsl:template>


  <!-- [78] NodeTest ::=
       KindTest | NameTest
  -->

  <xsl:template match="NodeTest">
    <xsl:apply-templates select="*"/>
  </xsl:template>


  <!-- [79] NameTest ::=
       QName | Wildcard
  -->

  <xsl:template match="NameTest">
    <xqx:nameTest>
      <xsl:apply-templates select="*" mode="qname"/>
    </xqx:nameTest>
  </xsl:template>

 
 <xsl:template match="NameTest[Wildcard]">
      <xsl:apply-templates select="Wildcard"/>
  </xsl:template>


<!-- [80] Wildcard ::=
  "*" | (NCName ":" "*") | ("*" ":" NCName)
-->

  <xsl:template match="Wildcard[data='*']">
    <xqx:Wildcard>
      <xqx:star/>
    </xqx:Wildcard>
</xsl:template>

  <xsl:template match="Wildcard[NCNameColonStar]">
    <xqx:Wildcard>
      <xqx:NCName><xsl:value-of select="substring-before(NCNameColonStar/data,':')"/></xqx:NCName>
      <xqx:star/>
    </xqx:Wildcard>
  </xsl:template>

  <xsl:template match="Wildcard[StarColonNCName]">
    <xqx:Wildcard>
      <xqx:star/>
      <xqx:NCName><xsl:value-of select="substring-after(StarColonNCName/data,':')"/></xqx:NCName>
    </xqx:Wildcard>
  </xsl:template>

  <!-- [81] FilterExpr ::=
       PrimaryExpr PredicateList
  -->

  <!-- Not reported by the parser -->

  <!-- [82] PredicateList ::=
       Predicate*
  -->

  <xsl:template match="PredicateList">
    <xqx:predicates>
      <xsl:apply-templates select="*"/>
    </xqx:predicates>
  </xsl:template>

  <!-- [83] Predicate ::=
       "[" Expr "]"
  -->

  <xsl:template match="Predicate">
    <xsl:apply-templates select="*"/>
  </xsl:template>

<!-- [84] PrimaryExpr ::=
  Literal | VarRef | ParenthesizedExpr | ContextItemExpr | FunctionCall
  | OrderedExpr | UnorderedExpr | Constructor
-->

  <!-- Not reported by the parser -->

  <!-- [85] Literal ::=
       NumericLiteral | StringLiteral
  -->

  <!-- Not reported by the parser -->


  <!-- [86] NumericLiteral ::=
       IntegerLiteral | DecimalLiteral | DoubleLiteral
  -->

  <!-- Not reported by the parser -->

  <!-- [87] VarRef ::=
       "$" VarName
  -->



  <xsl:template match="PathExpr/VarName">
    <xqx:stepExpr>
      <xqx:filterExpr>
	<xqx:varRef><xqx:name><xsl:apply-templates select="QName" mode="qname"/></xqx:name></xqx:varRef>
      </xqx:filterExpr>
    </xqx:stepExpr>
  </xsl:template>

  <xsl:template match="StepExpr/VarName">
    <xqx:filterExpr>
      <xqx:varRef><xqx:name><xsl:apply-templates select="QName" mode="qname"/></xqx:name></xqx:varRef>
    </xqx:filterExpr>
  </xsl:template>


  <!-- [88] VarName ::=
       QName
  -->

  <xsl:template match="VarName">
    <xqx:varName><xsl:apply-templates select="." mode="qname"/></xqx:varName>
  </xsl:template>

  <xsl:template match="Param/QName">
    <xqx:varName><xsl:apply-templates select="." mode="qname"/></xqx:varName>
  </xsl:template>

  <xsl:template match="VarDecl/QName">
    <xqx:varName><xsl:apply-templates select="." mode="qname"/></xqx:varName>
  </xsl:template>


  <!-- [89] ParenthesizedExpr ::=
       "(" Expr? ")"
  -->

  <xsl:template match="ParenthesizedExpr">
    <xqx:sequenceExpr>
      <xsl:apply-templates select="*"/>
    </xqx:sequenceExpr>
  </xsl:template>

  <xsl:template match="StepExpr[*[2]]/ParenthesizedExpr" priority="2">
    <xqx:filterExpr>
      <xsl:next-match/>
    </xqx:filterExpr>
  </xsl:template>

  <!-- [90] ContextItemExpr ::=
       "."
  -->

  <xsl:template match="ContextItemExpr">
    <xqx:filterExpr>
      <xqx:contextItemExpr/>
    </xqx:filterExpr>
  </xsl:template>


<!-- [91] OrderedExpr ::=
  "ordered" "{" Expr "}"
-->

  <xsl:template match="OrderedExpr">
    <xqx:orderedExpr>
      <xqx:argExpr>
	<xsl:apply-templates select="Expr"/>
      </xqx:argExpr>
    </xqx:orderedExpr>
  </xsl:template>

  <xsl:template match="StepExpr/OrderedExpr" priority="2">
    <xqx:filterExpr>
      <xqx:orderedExpr>
	<xqx:argExpr>
	  <xsl:apply-templates select="Expr/*"/>
	</xqx:argExpr>
      </xqx:orderedExpr>
    </xqx:filterExpr>
  </xsl:template>

<!-- [92] UnorderedExpr ::=
  "unordered" "{" Expr "}"
-->
 
  <xsl:template match="UnorderedExpr">
    <xqx:unorderedExpr>
      <xqx:argExpr>
	<xsl:apply-templates select="Expr"/>
      </xqx:argExpr>
    </xqx:unorderedExpr>
  </xsl:template>

  <xsl:template match="StepExpr/UnorderedExpr" priority="2">
    <xqx:filterExpr>
      <xqx:unorderedExpr>
	<xqx:argExpr>
	  <xsl:apply-templates select="Expr/*"/>
	</xqx:argExpr>
      </xqx:unorderedExpr>
    </xqx:filterExpr>
  </xsl:template>

<!-- [93] FunctionCall ::=
  QName "(" (ExprSingle ("," ExprSingle)*)? ")"
-->

  <xsl:template match="FunctionCall">
    <xqx:functionCallExpr>
      <xqx:functionName>
	<xsl:apply-templates select="FunctionQName" mode="qname"/>
      </xqx:functionName>
      <xqx:arguments>
	<xsl:apply-templates select="*[position()&gt;1]"/>
      </xqx:arguments>
    </xqx:functionCallExpr>
  </xsl:template>

<!-- [94] Constructor ::=
  DirectConstructor | ComputedConstructor
-->

  <xsl:template match="Constructor">
    <xsl:apply-templates select="*"/>
  </xsl:template>

<!-- [95] DirectConstructor ::=
  DirElemConstructor | DirCommentConstructor | DirPIConstructor
-->

  <xsl:template match="DirectConstructor">
    <xsl:apply-templates select="*"/>
  </xsl:template>

<!-- [96] DirElemConstructor ::=
  "<" QName DirAttributeList ("/>" | (">" DirElemContent* "</" QName S? ">"))
-->

  <xsl:template match="DirElemConstructor">
    <xsl:param name="preservespace" tunnel="yes"/>
    <xqx:elementConstructor>
      <xsl:apply-templates select="TagQName|DirAttributeList"/>
      <xsl:if test="DirElemContent">
	<xqx:elementContent>
	  <xsl:for-each-group  select="DirElemContent/*[not(self::data)]" group-adjacent="exists(self::ElementContentChar|self::CommonContent[CharRef|PredefinedEntityRef|LCurlyBraceEscape|RCurlyBraceEscape])">
	    <xsl:choose>
	      <xsl:when test="not(current-group()[last()]/../following-sibling::DirElemContent[1]/CDataSection) and 
                              not(current-group()[1]/../preceding-sibling::DirElemContent[1]/CDataSection) and 
                              not($preservespace) and current-grouping-key() and not(normalize-space(string-join(current-group()//data,'')))"/>
	      <xsl:when test="current-grouping-key()">
		<xqx:stringConstantExpr>
		  <xqx:value>
		    <xsl:apply-templates select="current-group()"/>
		  </xqx:value>
		</xqx:stringConstantExpr>    
	      </xsl:when>
	      <xsl:otherwise>
		<xsl:apply-templates select="current-group()"/>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:for-each-group>
	</xqx:elementContent>
      </xsl:if>
    </xqx:elementConstructor>
  </xsl:template>

  <xsl:template match="TagQName">
    <xqx:tagName><xsl:apply-templates select="." mode="qname"/></xqx:tagName>
  </xsl:template>


  <xsl:template match="TagQName[preceding-sibling::*[1][self::EndTagOpen]]"/>


<!-- [97] DirAttributeList ::=
  (S (QName S? "=" S? DirAttributeValue)?)*
-->

  <xsl:template match="DirAttributeList[not(*[not(self::S)])]"/>

  <xsl:template match="DirAttributeList">
    <xqx:attributeList>
      <xsl:apply-templates select="TagQName"/>
    </xqx:attributeList>
  </xsl:template>

  <xsl:template match="AttributeConstructor">
    <xqx:attributeConstructor>
      <xsl:apply-templates select="*"/>
    </xqx:attributeConstructor>
  </xsl:template>

  <xsl:template match="DirAttributeList/TagQName">
    <xqx:attributeConstructor>
      <xqx:attributeName>
	<xsl:apply-templates select="." mode="qname"/>
      </xqx:attributeName>
      <xsl:apply-templates select="following-sibling::DirAttributeValue[1]"/>
    </xqx:attributeConstructor>
  </xsl:template>

  <xsl:template match="DirAttributeList/TagQName[.='xmlns']" priority="2">
    <xqx:namespaceDeclaration>
      <xqx:uri>
	<xsl:value-of select="following-sibling::DirAttributeValue[1]/*/(QuotAttrContentChar|AposAttrContentChar)/data" separator=""/>
      </xqx:uri>
    </xqx:namespaceDeclaration>
  </xsl:template>

  <xsl:template match="DirAttributeList/TagQName[starts-with(data,'xmlns:')]" priority="3">
    <xqx:namespaceDeclaration>
      <xqx:prefix>
	<xsl:value-of select="substring-after(data,':')"/>
      </xqx:prefix>
      <xqx:uri>
	<xsl:value-of select="following-sibling::DirAttributeValue[1]/*/(QuotAttrContentChar|AposAttrContentChar)/data" separator=""/>
      </xqx:uri>
    </xqx:namespaceDeclaration>
  </xsl:template>

<!-- [98] DirAttributeValue ::=
  ('"' (EscapeQuot | QuotAttrValueContent)* '"')
  | ("'" (EscapeApos | AposAttrValueContent)* "'")
-->

  <xsl:template match="DirAttributeValue[count(*)=2+count(*/(QuotAttrContentChar|AposAttrContentChar))]">
    <xqx:attributeValue>
      <xsl:value-of select="*/(QuotAttrContentChar|AposAttrContentChar)/data" separator=""/>
    </xqx:attributeValue>
  </xsl:template>

  <xsl:template match="DirAttributeValue">
    <xqx:attributeValueExpr>
      <xsl:for-each-group  select="(QuotAttrValueContent|AposAttrValueContent)/*" group-adjacent="empty(self::QuotAttrContentChar|self::AposAttrContentChar)">
	<xsl:choose>
	  <xsl:when test="current-grouping-key()">
	    <xsl:apply-templates select="current-group()"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xqx:stringConstantExpr>
	      <xqx:value>
		<xsl:value-of select="current-group()/data" separator=""/>
	      </xqx:value>
	    </xqx:stringConstantExpr>    
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:for-each-group>
    </xqx:attributeValueExpr>
  </xsl:template>

  <!-- [99] QuotAttrValueContent ::=
       QuotAttrContentChar | CommonContent
  -->

  <xsl:template match="QuotAttrValueContent">
    <xsl:apply-templates select="*"/>
  </xsl:template>


  <!-- [100] AposAttrValueContent ::=
       AposAttrContentChar | CommonContent
  -->

  <xsl:template match="AposAttrValueContent">
    <xsl:apply-templates select="*"/>
  </xsl:template>


<!-- [101] DirElemContent ::=
  DirectConstructor | CDataSection | CommonContent | ElementContentChar
-->

<!-- [102] CommonContent ::=
  PredefinedEntityRef | CharRef | "{{" | "}}" | EnclosedExpr
-->

  <xsl:template match="CommonContent">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="LCurlyBraceEscape">
    <xqx:stringConstantExpr>
      <xqx:value>{</xqx:value>
    </xqx:stringConstantExpr>
  </xsl:template>

  <xsl:template match="RCurlyBraceEscape">
    <xqx:stringConstantExpr>
      <xqx:value>}</xqx:value>
    </xqx:stringConstantExpr>
  </xsl:template>

  <!-- [103] DirCommentConstructor ::=
       "<!-/-" DirCommentContents "-/->"
  -->

  <xsl:template match="DirCommentConstructor">
    <xqx:computedCommentConstructor>
      <xqx:argExpr>
	<xqx:stringConstantExpr>
	  <xqx:value>
	    <xsl:value-of select="string-join(DirCommentContents/*/data,'')"/>
	  </xqx:value>
	</xqx:stringConstantExpr>
      </xqx:argExpr>
    </xqx:computedCommentConstructor>
  </xsl:template>

<!-- [104] DirCommentContents ::=
  ((Char - '-') | ('-' (Char - '-')))*
-->

  <!-- handled in [101] -->

  <!-- [105] DirPIConstructor ::=
       "<?" PITarget (S DirPIContents)? "?>"
  -->

  <xsl:template match="DirPIConstructor">
    <xqx:computedPIConstructor>
      <xsl:apply-templates select="*"/>
    </xqx:computedPIConstructor>
  </xsl:template>

  <!-- [106] DirPIContents ::=
       (Char* - (Char* '?>' Char*))
  -->

  <xsl:template match="DirPIContents">
    <xqx:piValueExpr>
      <xqx:stringConstantExpr>
	<xqx:value>
	  <xsl:value-of select="string-join(PIContentChar/data,'')"/>
	</xqx:value>
      </xqx:stringConstantExpr>
    </xqx:piValueExpr>
  </xsl:template>

  <!-- [107] CDataSection ::=
       "<![CDATA[" CDataSectionContents "]]>"
  -->

  <xsl:template match="CDataSection">
    <xqx:stringConstantExpr>
      <xqx:value>
	<xsl:value-of select="string-join(CDataSectionContents/CDataSectionChar/data,'')"/>
      </xqx:value>
    </xqx:stringConstantExpr>
  </xsl:template>

  <!-- [108] CDataSectionContents ::=
       (Char* - (Char* ']]>' Char*))
  -->

  <!-- handled in [105] -->

<!-- [109] ComputedConstructor ::=
  CompDocConstructor | CompElemConstructor | CompAttrConstructor
  | CompTextConstructor | CompCommentConstructor | CompPIConstructor
-->

  <xsl:template match="ComputedConstructor">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <!-- [110] CompDocConstructor ::=
       "document" "{" Expr "}"
  -->

  <xsl:template match="CompDocConstructor">
    <xqx:computedDocumentConstructor>
      <xqx:argExpr>
	<xsl:apply-templates select="Expr"/>
      </xqx:argExpr>
    </xqx:computedDocumentConstructor>
  </xsl:template>

<!-- [111] CompElemConstructor ::=
  "element" (QName | ("{" Expr "}")) "{" ContentExpr? "}"
-->

  <xsl:template match="CompElemConstructor">
    <xqx:computedElementConstructor>
      <xqx:tagNameExpr>
	<xsl:apply-templates select="Expr[1]"/>
      </xqx:tagNameExpr>
      <xsl:apply-templates select="ContentExpr"/>
    </xqx:computedElementConstructor>
  </xsl:template>

  <xsl:template match="CompElemConstructor[QName]">
    <xqx:computedElementConstructor>
      <xqx:tagName><xsl:apply-templates select="QName" mode="qname"/></xqx:tagName>
      <xsl:apply-templates select="ContentExpr"/>
    </xqx:computedElementConstructor>
  </xsl:template>


  <!-- [112] ContentExpr ::=
       Expr
  -->

  <xsl:template match="ContentExpr">
    <xqx:contentExpr>
      <xsl:apply-templates select="*"/>
    </xqx:contentExpr>
  </xsl:template>

<!-- [113] CompAttrConstructor ::=
  "attribute" (QName | ("{" Expr "}")) "{" Expr? "}"
-->

  <xsl:template match="CompAttrConstructor[QName]">
    <xqx:computedAttributeConstructor>
    <xqx:tagName><xsl:apply-templates select="QName" mode="qname"/></xqx:tagName>
    <xsl:if test="Expr">
      <xqx:valueExpr>
	<xsl:apply-templates select="Expr"/>
      </xqx:valueExpr>
    </xsl:if>
    </xqx:computedAttributeConstructor>
  </xsl:template>

  <xsl:template match="CompAttrConstructor[not(QName)]">
    <xqx:computedAttributeConstructor>
      <xqx:tagNameExpr>
	<xsl:apply-templates select="LbraceExprEnclosure[1]/following-sibling::*[1]"/>
      </xqx:tagNameExpr>
      <xsl:if test="LbraceExprEnclosure[2]/following-sibling::Expr">
	<xqx:valueExpr>
	  <xsl:apply-templates select="LbraceExprEnclosure[2]/following-sibling::Expr[1]"/>
	</xqx:valueExpr>
      </xsl:if>
    </xqx:computedAttributeConstructor>
  </xsl:template>

<!-- [114] CompTextConstructor ::=
  "text" "{" Expr "}"
-->

  <xsl:template match="CompTextConstructor">
    <xqx:computedTextConstructor>
      <xqx:argExpr>
	<xsl:apply-templates select="*"/>
      </xqx:argExpr>
    </xqx:computedTextConstructor>
  </xsl:template>

<!-- [115] CompCommentConstructor ::=
  "comment" "{" Expr "}"
-->

  <xsl:template match="CompCommentConstructor">
    <xqx:computedCommentConstructor>
      <xqx:argExpr>
	<xsl:apply-templates select="*"/>
      </xqx:argExpr>
    </xqx:computedCommentConstructor>
  </xsl:template>

<!-- [116] CompPIConstructor ::=
  "processing-instruction" (NCName | ("{" Expr "}")) "{" Expr? "}"
-->

  <xsl:template match="CompPIConstructor[NCName]">
    <xqx:computedPIConstructor>
    <xqx:piTarget><xsl:value-of select="NCName/data"/></xqx:piTarget>
      <xqx:piValueExpr>
	<xsl:apply-templates select="Expr"/>
      </xqx:piValueExpr>
    </xqx:computedPIConstructor>
  </xsl:template>



  <xsl:template match="CompPIConstructor">
    <xqx:computedPIConstructor>
      <xqx:piTargetExpr>
	<xsl:apply-templates select="Expr[1]"/>
      </xqx:piTargetExpr>
      <xsl:if test="Expr[2]">
	<xqx:piValueExpr>
	  <xsl:apply-templates select="Expr[2]"/>
	</xqx:piValueExpr>
      </xsl:if>
    </xqx:computedPIConstructor>
  </xsl:template>

  <!-- [117] SingleType ::=
       AtomicType "?"?
  -->
  <xsl:template match="SingleType">
    <xqx:singleType>
      <xsl:apply-templates select="*"/>
      <xsl:if test="data='?'">
	<xqx:optional/>
      </xsl:if>
    </xqx:singleType>
  </xsl:template>

  <!-- [118] TypeDeclaration ::=
       "as" SequenceType
  -->

  <xsl:template match="TypeDeclaration">
    <xqx:typeDeclaration>
      <xsl:apply-templates select="SequenceType/*"/>
    </xqx:typeDeclaration>
  </xsl:template>

<!-- [119] SequenceType ::=
  ("empty-sequence" "(" ")") | (ItemType OccurrenceIndicator?)
-->

  <xsl:template match="SequenceType">
    <xqx:sequenceType>
      <xsl:apply-templates select="*"/>
    </xqx:sequenceType>
  </xsl:template>

  <xsl:template match="FunctionDecl/SequenceType">
    <xqx:typeDeclaration>
      <xsl:apply-templates select="*"/>
    </xqx:typeDeclaration>
  </xsl:template>

  <xsl:template match="SequenceType/data[.='empty-sequence']" priority="2">
      <xqx:voidSequenceType/>
  </xsl:template>

  <!-- [120] OccurrenceIndicator ::=
       "?" | "*" | "+"
  -->

  <xsl:template match="OccurrenceIndicator">
    <xqx:occurrenceIndicator><xsl:value-of select="data"/></xqx:occurrenceIndicator>
  </xsl:template>

<!-- [121] ItemType ::=
  KindTest | ("item" "(" ")") | AtomicType
-->

  <xsl:template match="ItemType">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="ItemType/data[.='item']">
    <xqx:anyItemType/>
  </xsl:template>

  <!-- [122] AtomicType ::=
       QName
  -->

  <xsl:template match="AtomicType">
    <xqx:atomicType>
      <xsl:apply-templates select="*" mode="qname"/>
    </xqx:atomicType>
  </xsl:template>

<!-- [123] KindTest ::=
  DocumentTest | ElementTest | AttributeTest | SchemaElementTest
  | SchemaAttributeTest | PITest | CommentTest | TextTest | AnyKindTest
-->

<!-- [124] AnyKindTest ::=
  "node" "(" ")"
-->

  <xsl:template match="AnyKindTest">
    <xqx:anyKindTest/>
  </xsl:template>

<!-- [125] DocumentTest ::=
  "document-node" "(" (ElementTest | SchemaElementTest)? ")"
-->

  <xsl:template match="DocumentTest">
    <xqx:documentTest>
      <xsl:apply-templates select="*"/>
    </xqx:documentTest>
  </xsl:template>

<!-- [126] TextTest ::=
  "text" "(" ")"
-->

  <xsl:template match="TextTest">
    <xqx:textTest/>
  </xsl:template>

<!-- [127] CommentTest ::=
  "comment" "(" ")"
-->

  <xsl:template match="CommentTest">
    <xqx:commentTest/>
  </xsl:template>

<!-- [128] PITest ::=
  "processing-instruction" "(" (NCName | StringLiteral)? ")"
-->

  <xsl:template match="PITest">
    <xqx:piTest/>
  </xsl:template>

  <xsl:template match="PITest[StringLiteral]">
    <xqx:piTest>
      <xqx:piTarget>
	<xsl:value-of select="substring(StringLiteral/data,2,string-length(StringLiteral/data)-2)"/>
      </xqx:piTarget>
    </xqx:piTest>
  </xsl:template>

  <xsl:template match="PITest[NCName]">
    <xqx:piTest>
      <xqx:piTarget>
	<xsl:value-of select="NCName/data"/>
      </xqx:piTarget>
    </xqx:piTest>
  </xsl:template>

<!-- [129] AttributeTest ::=
  "attribute" "(" (AttribNameOrWildcard ("," TypeName)?)? ")"
-->

  <xsl:template match="AttributeTest">
    <xqx:attributeTest>
      <xsl:apply-templates select="*"/>
    </xqx:attributeTest>
  </xsl:template>

<!-- [130] AttribNameOrWildcard ::=
  AttributeName | "*"
-->

  <xsl:template match="AttribNameOrWildcard">
    <xqx:attributeName>
      <xsl:apply-templates select="*"/>
    </xqx:attributeName>
  </xsl:template>

  <xsl:template match="AttributeTest/AttribNameOrWildcard[not(AttributeName)]">
    <xqx:attributeName>
      <xsl:apply-templates select="*"/>
    </xqx:attributeName>
  </xsl:template>

  <xsl:template match="AttributeTest/AttribNameOrWildcard[data='*' and not(*[2])]" priority="2">
    <xqx:attributeName>
      <xqx:star/>
    </xqx:attributeName>
  </xsl:template>

<!-- [131] SchemaAttributeTest ::=
  "schema-attribute" "(" AttributeDeclaration ")"
-->

  <xsl:template match="SchemaAttributeTest">
    <xqx:schemaAttributeTest>
      <xsl:apply-templates select="AttributeDeclaration/AttributeName/QName" mode="qname"/>
    </xqx:schemaAttributeTest>
  </xsl:template>


  <!-- [132] AttributeDeclaration ::=
       AttributeName
  -->

  <!-- Handled by SchemaAttributeTest -->


<!-- [133] ElementTest ::=
  "element" "(" (ElementNameOrWildcard ("," TypeName "?"?)?)? ")"
-->

  <xsl:template match="ElementTest">
    <xqx:elementTest>
      <xsl:apply-templates select="*"/>
    </xqx:elementTest>
  </xsl:template>

  <xsl:template match="Nillable">
    <xqx:nillable/>
  </xsl:template>

  <!-- [134] ElementNameOrWildcard ::=
       ElementName | "*"
  -->

  <xsl:template match="ElementNameOrWildcard[not(ElementName)]">
    <xqx:simpleWildcard>
      <xqx:star/>
    </xqx:simpleWildcard>
  </xsl:template>

  <xsl:template match="ElementNameOrWildcard[ElementName]">
    <xqx:simpleWildcard>
      <xsl:apply-templates select="ElementName"/>
    </xqx:simpleWildcard>
  </xsl:template>

  <xsl:template match="ElementTest/ElementNameOrWildcard[not(ElementName)]" priority="2">
    <xqx:elementName>
      <xqx:star/>
    </xqx:elementName>
  </xsl:template>

  <xsl:template match="ElementTest/ElementNameOrWildcard[ElementName]" priority="2">
    <xsl:apply-templates select="ElementName"/>
  </xsl:template>

<!-- [135] SchemaElementTest ::=
  "schema-element" "(" ElementDeclaration ")"
-->

  <xsl:template match="SchemaElementTest">
    <xqx:schemaElementTest>
      <xsl:apply-templates select="ElementDeclaration/ElementName/QName" mode="qname"/>
    </xqx:schemaElementTest>
  </xsl:template>

  <!-- [136] ElementDeclaration ::=
       ElementName
  -->


  <!-- [137] AttributeName ::=
       QName
  -->

  <xsl:template match="AttributeName">
    <xqx:QName>
      <xsl:apply-templates select="QName" mode="qname"/>
    </xqx:QName>
  </xsl:template>

  <!-- [138] ElementName ::=
       QName
  -->

  <xsl:template match="ElementName">
    <xqx:elementName>
      <xqx:QName>
	<xsl:apply-templates select="*" mode="qname"/>
      </xqx:QName>
    </xqx:elementName>
  </xsl:template>

  <!-- [139] TypeName ::=
       QName
  -->

  <xsl:template match="TypeName">
    <xqx:typeName>
      <xsl:apply-templates select="QName" mode="qname"/>
    </xqx:typeName>
  </xsl:template>

  <!-- [140] URILiteral ::=
       StringLiteral
  -->

  <xsl:template match="URILiteral">
    <xqx:uri>
      <xsl:variable name="q" select="substring(StringLiteral/data,1,1)"/>
	<xsl:value-of select="xq:chars(replace(substring(StringLiteral/data,2,string-length(StringLiteral/data)-2),concat($q,$q),$q))"/>
    </xqx:uri>
  </xsl:template>

  <!-- [141] IntegerLiteral ::=
       Digits
  -->

  <xsl:template match="IntegerLiteral">
    <xqx:integerConstantExpr>
      <xqx:value><xsl:value-of select="data"/></xqx:value>
    </xqx:integerConstantExpr>
  </xsl:template>

  <!-- [142] DecimalLiteral ::=
       ("." Digits) | (Digits "." [0-9]*)
  -->

  <xsl:template match="DecimalLiteral">
    <xqx:decimalConstantExpr>
      <xqx:value><xsl:value-of select="data"/></xqx:value>
    </xqx:decimalConstantExpr>
  </xsl:template>

  <!-- [143] DoubleLiteral ::=
       (("." Digits) | (Digits ("." [0-9]*)?)) [eE] [+-]? Digits
  -->

  <xsl:template match="DoubleLiteral">
    <xqx:doubleConstantExpr>
      <xqx:value><xsl:value-of select="data"/></xqx:value>
    </xqx:doubleConstantExpr>
  </xsl:template>

<!-- [144] StringLiteral ::=
  ('"' (PredefinedEntityRef | CharRef | EscapeQuot | [^"&])* '"')
  | ("'" (PredefinedEntityRef | CharRef | EscapeApos | [^'&])* "'")
-->

  <xsl:template match="StringLiteral">
    <xqx:stringConstantExpr>
      <xsl:variable name="q" select="substring(data,1,1)"/>
      <xqx:value>
	<xsl:value-of select="xq:chars(replace(substring(data,2,string-length(data)-2),concat($q,$q),$q))"/>
      </xqx:value>
    </xqx:stringConstantExpr>
  </xsl:template>

  <!-- [145] PredefinedEntityRef ::=
       "&" ("lt" | "gt" | "amp" | "quot" | "apos") ";"
  -->

  <xsl:template match="PredefinedEntityRef|CharRef">
    <xqx:stringConstantExpr>
      <xqx:value>
	<xsl:value-of select="xq:chars(data)"/>
      </xqx:value>
    </xqx:stringConstantExpr>
  </xsl:template>

  <xsl:template match="DirElemContent/CommonContent/PredefinedEntityRef|DirElemContent/CommonContent/CharRef">
    <xsl:value-of select="xq:chars(data)"/>
  </xsl:template>

 <!-- [146] EscapeQuot ::=
       '""'
  -->

  <xsl:template match="EscapeQuot" mode="value">"</xsl:template>

  <!-- [147] EscapeApos ::=
       "''"
  -->

  <xsl:template match="EscapeApos" mode="value">'</xsl:template>

<!-- [148] ElementContentChar ::=
  Char - [{}<&]
-->

  <xsl:template match="ElementContentChar">
    <xsl:value-of select="data"/>
  </xsl:template>


  <!-- [149] QuotAttrContentChar ::=
       Char - ["{}<&]
  -->

  <xsl:template match="QuotAttrValueContent[following-sibling::*[1]/QuotAttrContentChar and preceding-sibling::*[1]/QuotAttrContentChar]" priority="2"/>

  <xsl:template match="QuotAttrContentChar">
    <xqx:stringConstantExpr>
      <xqx:value>
	<xsl:apply-templates select="." mode="value"/>
      </xqx:value>
    </xqx:stringConstantExpr>
  </xsl:template>

  <xsl:template match="QuotAttrContentChar" mode="value">
    <xsl:value-of select="data"/>
    <xsl:apply-templates select="../following-sibling::*[1]/(self::EscapeApos|./AposAttrContentChar)" mode="value"/>
  </xsl:template>

  <!-- [150] AposAttrContentChar ::=
       Char - ['{}<&]
  -->

  <xsl:template match="AposAttrValueContent[following-sibling::*[1]/AposAttrContentChar and preceding-sibling::*[1]/AposAttrContentChar]" priority="2"/>

  <xsl:template match="AposAttrContentChar|EscapeApos">
    <xqx:stringConstantExpr>
      <xqx:value>
	<xsl:apply-templates select="." mode="value"/>
      </xqx:value>
    </xqx:stringConstantExpr>
  </xsl:template>

  <xsl:template match="AposAttrContentChar" mode="value">
    <xsl:value-of select="data"/>
    <xsl:apply-templates select="../following-sibling::*[1]/(self::EscapeApos|./AposAttrContentChar)" mode="value"/>
  </xsl:template>

<!-- [151] Comment ::=
  "(:" (CommentContents | Comment)* ":)"
-->

  <!-- comments are dropped in translation (not reported by the xquery parser)-->

  <!-- [152] PITarget ::=
       [http://www.w3.org/TR/REC-xml#NT-PITarget]XML
  -->

  <xsl:template match="PITarget">
    <xqx:piTarget><xsl:value-of select="data"/></xqx:piTarget>
  </xsl:template>

  <!-- [153] CharRef ::=
       [http://www.w3.org/TR/REC-xml#NT-CharRef]XML
  -->

  <!-- Shares code with PredefinedEntityRef template -->


  <!-- [154] QName ::=
       [http://www.w3.org/TR/REC-xml-names/#NT-QName]Names
  -->

  <xsl:template match="*" mode="qname">
    <xsl:value-of select="data"/>
  </xsl:template>

  <xsl:template match="*[contains(data,':')]" mode="qname">
    <xsl:attribute name="xqx:prefix" select="substring-before(data,':')"/>
    <xsl:value-of select="substring-after(data,':')"/>
  </xsl:template>


  <!-- [155] NCName ::=
       [http://www.w3.org/TR/REC-xml-names/#NT-NCName]Names
  -->
  <!-- [156] S ::=
       [http://www.w3.org/TR/REC-xml#NT-S]XML
  -->

  <xsl:template match="S"/>


  <!-- [157] Char ::=
       [http://www.w3.org/TR/REC-xml#NT-Char]XML
  -->

  <!-- [158] Digits ::=
       [0-9]+
  -->

  <!-- Not Reported by the parser -->

<!-- [159] CommentContents ::=
  (Char+ - (Char* ('(:' | ':)') Char*))
-->

  <!--===================-->

  <!-- assorted terminals that need to be discarded in translation -->

  <xsl:template match="DeclareNamespace|ModuleNamespace"/>
  <xsl:template match="AssignEquals"/>
  <xsl:template match="OpenQuot|OpenApos|CloseApos|CloseQuot"/>
  <xsl:template match="SForPI|ProcessingInstructionStart|ProcessingInstructionEnd"/>
  <xsl:template match="LbraceExprEnclosure|ElementTypeForKindTest|ElementTypeForDocumentTest|As|StartTagOpenRoot|EmptyTagClose|StartTagClose|EndTagOpen|EndTagClose|Lbrace|Rbrace|CommaForKindTest|DocumentLpar|DocumentLparForKindTest|DefineFunction|CommentLbrace|PILbrace|TextLbrace|ElementLbrace|ValueIndicator|ProcessingInstructionStartForElementContent"/>
  <xsl:template match="In|Where|OrderBy"/>
  <xsl:template match="LetVariable|ColonEquals" priority="10"/>
  <xsl:template match="QNameLpar"/>
  <xsl:template match="Namespace"/>
  <xsl:template match="ImportSchemaToken"/>
  <xsl:template match="ImportModuleToken"/>
  <xsl:template match="ElementType|AttributeType|AttributeTypeForKindTest"/>


  <!-- new names in september 05 -->
  <xsl:template match="VariableIndicatorForProlog|CommaForProlog|LparForProlog|AsForProlog|LbraceExprEnclosureForProlog|VariableIndicatorForCase|ColonEqualsForProlog" priority="10"/>

  <xsl:template match="data"/>


  <xsl:template match="*">
    <xsl:message terminate="yes">
Unsupported element: <xsl:value-of select="name(..)"/>/<xsl:value-of select="name()"/>
===
<xsl:copy-of select="/"/>
</xsl:message>
  </xsl:template>

  <!--===================-->

  <!--
      A top level error element indicates a syntax error was reported by the parser.
      Some syntax errors (mostly relating to bad character references) get past the
      parser and are detected here .

Currently generate error() Perhaps could try hrder to generate a more appropriate error
code in each case.
  -->

  <xsl:template match="/error" name="error">
    <xsl:param name="error" select="$error" tunnel="yes"/>
    <xqx:module>
      <xqx:mainModule>
	<xqx:queryBody>
	  <xqx:functionCallExpr>
	    <xqx:functionName>error</xqx:functionName>
	    <xqx:arguments>
	      <xqx:functionCallExpr>
		<xqx:functionName>QName</xqx:functionName>
		<xqx:arguments>
		  <xqx:stringConstantExpr>
		    <xqx:value>http://www.w3.org/2005/xqt-errors</xqx:value>
		  </xqx:stringConstantExpr>
		  <xqx:stringConstantExpr>
		    <xqx:value><xsl:value-of select="$error"/></xqx:value>
		  </xqx:stringConstantExpr>
		</xqx:arguments>
	      </xqx:functionCallExpr>
	    </xqx:arguments>
	  </xqx:functionCallExpr>
	</xqx:queryBody>
      </xqx:mainModule>
    </xqx:module>
  </xsl:template>

  <xsl:template match="Module[.//StringLiteral/data[matches(.,'&amp;#0*(([1-8]|1[124-9]|2[0-9]|30|31)|x[1-8bBcCe-fE-F]);')]]" priority="11">
    <xsl:call-template name="error"/>
  </xsl:template>

  <xsl:template match="Module[.//(QuotAttrContentChar|AposAttrContentChar|ElementContentChar)/data='&amp;']" priority="10">
    <xsl:call-template name="error"/>
  </xsl:template>


  <xsl:template match="Module[.//DirAttributeList[TagQName[starts-with(data,'xmlns:') or data='xmlns'][following-sibling::DirAttributeValue[1]/*/CommonContent]]]" priority="10">
    <xsl:call-template name="error"/>
  </xsl:template>


  <!--===================-->

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
	      <xsl:value-of select="if ($cp=(9,10,13) or ($cp &gt; 31)) then codepoints-to-string($cp) else 'ERROR'"/>
	    </xsl:when>
	    <xsl:when test="regex-group(1)='#'">
	      <xsl:variable name="cp" select="xs:integer(regex-group(3))"/>
	      <xsl:value-of select="if ($cp=(9,10,13) or ($cp &gt; 31)) then codepoints-to-string($cp) else 'ERROR'"/>
	    </xsl:when>
	    <xsl:when test="$xq:ents/key('xq:ents',regex-group(3))">
	      <xsl:value-of select="$xq:ents/key('xq:ents',regex-group(3))"/>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:message>xq2xqx: Unknown entity: <xsl:value-of select="regex-group(3)"/></xsl:message>
	      <xsl:text>&amp;</xsl:text>
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

</xsl:stylesheet>



