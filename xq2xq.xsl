<!--
    xq2xq.xsl
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
		exclude-result-prefixes="xs saxon xq">
  <xsl:param name="xq" select="'&lt;error/&gt;'"/>
  <xsl:param name="dump" select="'no'"/>
  <xsl:param name="error" select="'FOER0000'"/>

  <xsl:output method="text" />

  <!--
      Initial template, processes the query in the document specified in the global xq
      parameter. Dumps the intermediate xml if the dump parameter is set.
  -->

  <!-- orderBy59 -->
  <xsl:template name="main">
    <xsl:variable name="xqtext" select="unparsed-text($xq,'utf-8')"/>
    <xsl:variable name="xqxml" select="saxon:parse(xq:convert(replace(unparsed-text($xq,'utf-8'),'&#13;&#10;','&#10;')))"/>

    <xsl:if test="$dump!='no'">
      <xsl:result-document href="temp.xml" method="xml" indent="no">
	<xsl:copy-of select="$xqxml"/>
      </xsl:result-document>
    </xsl:if>
    <xsl:result-document href="{$xq}3">
      <xsl:apply-templates select="$xqxml"/>
    </xsl:result-document>
  </xsl:template>


  <!--===================-->

  <!--
      The XQuery EBNF.
      The first two productions are not offical but are eported by the XQuery Parser .
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
    <xsl:for-each select="Module">
    <xsl:apply-templates select="."/>
    <xsl:if test="position()!=last()">
      
%%%

    </xsl:if>
    </xsl:for-each>
  </xsl:template>



<!-- [1] Module ::=
  VersionDecl? (LibraryModule | MainModule)
-->

  <xsl:template match="Module">
    <xsl:text>&#10;</xsl:text>
    <xsl:apply-templates select="*"/>
  </xsl:template>


<!-- [2] VersionDecl ::=
  "xquery" "version" StringLiteral ("encoding" StringLiteral)? Separator
-->

  <xsl:template match="VersionDecl">
    <xsl:text>xquery version </xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

<!-- [3] MainModule ::=
  Prolog QueryBody
-->

  <xsl:template match="MainModule">
    <xsl:apply-templates select="*"/>
  </xsl:template>

<!-- [4] LibraryModule ::=
  ModuleDecl Prolog
-->

  <xsl:template match="LibraryModule">
    <xsl:apply-templates select="*"/>
  </xsl:template>


<!-- [5] ModuleDecl ::=
  "module" "namespace" NCName "=" URILiteral Separator
-->

  <xsl:template match="ModuleDecl">
    <xsl:text>module namespace </xsl:text>
      <xsl:apply-templates select="*[1]"/>
      <xsl:text> = </xsl:text>
      <xsl:apply-templates select="*[position()!=1]"/>
  </xsl:template>

<!-- [6] Prolog ::=
  ((DefaultNamespaceDecl | Setter | NamespaceDecl | Import) Separator)*
  ((VarDecl | FunctionDecl | OptionDecl) Separator)*
-->


  <xsl:template match="Prolog">
    <xsl:apply-templates select="*"/>
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

  <xsl:template match="Separator">
    <xsl:text>;&#10;</xsl:text>
  </xsl:template>

 <!-- [10] NamespaceDecl ::=
  "declare" "namespace" NCName "=" URILiteral
-->


  <xsl:template match="NamespaceDecl">
    <xsl:text>declare namespace </xsl:text>
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="NamespaceDecl/NCName">
    <xsl:value-of select="data"/>
    <xsl:text> = </xsl:text>
  </xsl:template>


<!-- [11] BoundarySpaceDecl ::=
  "declare" "boundary-space" ("preserve" | "strip")
-->


  <xsl:template match="BoundarySpaceDecl">
    <xsl:text>declare boundary-space </xsl:text>
    <xsl:value-of select="data"/>
  </xsl:template>

<!-- [12] DefaultNamespaceDecl ::=
  "declare" "default" ("element" | "function") "namespace" URILiteral
-->

  <xsl:template match="DefaultNamespaceDecl">
    <xsl:text>declare default </xsl:text>
    <xsl:value-of select="data"/>
    <xsl:text> namespace </xsl:text>
    <xsl:apply-templates select="*"/>
  </xsl:template>


<!-- [13] OptionDecl ::=
  "declare" "option" QName StringLiteral
-->

  <xsl:template match="OptionDecl">
    <xsl:text>declare option </xsl:text>
    <xsl:apply-templates select="*"/>
  </xsl:template>

<!-- [14] OrderingModeDecl ::=
  "declare" "ordering" ("ordered" | "unordered")
-->

  <xsl:template match="OrderingModeDecl">
    <xsl:text>declare ordering </xsl:text>
    <xsl:value-of select="data"/>
  </xsl:template>

<!-- [15] EmptyOrderDecl ::=
  "declare" "default" "order" "empty" ("greatest" | "least")
-->

  <xsl:template match="EmptyOrderDecl">
    <xsl:text>declare default order empty </xsl:text>
    <xsl:value-of select="*/data"/>
  </xsl:template>


<!-- [16] CopyNamespacesDecl ::=
  "declare" "copy-namespaces" PreserveMode "," InheritMode
-->

  <xsl:template match="CopyNamespacesDecl">
    <xsl:text>declare copy-namespaces </xsl:text>
    <xsl:value-of select="(PreserveMode|InheritMode)/data" separator=","/>
  </xsl:template>


<!-- [17] PreserveMode ::=
  "preserve" | "no-preserve"
-->


  <!-- [18] InheritMode ::=
       "inherit" | "no-inherit"
  -->


<!-- [19] DefaultCollationDecl ::=
  "declare" "default" "collation" URILiteral
-->

  <xsl:template match="DefaultCollationDecl">
    <xsl:text>declare default collation </xsl:text>
    <xsl:value-of select="URILiteral/StringLiteral/data"/>
  </xsl:template>

<!-- [20] BaseURIDecl ::=
  "declare" "base-uri" URILiteral
-->

  <xsl:template match="BaseURIDecl">
    <xsl:text>declare base-uri </xsl:text>
    <xsl:value-of select="URILiteral/StringLiteral/data"/>
  </xsl:template>

<!-- [21] SchemaImport ::=
  "import" "schema" SchemaPrefix? URILiteral ("at" URILiteral ("," URILiteral)*)?
-->

  <xsl:template match="SchemaImport">
    <xsl:text>import schema </xsl:text>
    <xsl:apply-templates select="SchemaPrefix"/>
    <xsl:apply-templates select="URILiteral"/>
  </xsl:template>


<!-- [22] SchemaPrefix ::=
  ("namespace" NCName "=") | ("default" "element" "namespace")
-->

  <xsl:template match="SchemaPrefix">
    <xsl:text>namespace </xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text> = </xsl:text>
  </xsl:template>

  <xsl:template match="SchemaPrefix[not(*)]">
    <xsl:text>default element namespace </xsl:text>
  </xsl:template>


<!-- [23] ModuleImport ::=
  "import" "module" ("namespace" NCName "=")? URILiteral ("at" URILiteral ("," URILiteral)*)?
-->

  <xsl:template match="ModuleImport">
    <xsl:text>import module </xsl:text>
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="Import/*/URILiteral[1]">
    <xsl:value-of select="StringLiteral/data"/>
  </xsl:template>

  <xsl:template match="Import/*/URILiteral[2]">
    <xsl:text> at </xsl:text>
    <xsl:value-of select="StringLiteral/data"/>
  </xsl:template>

  <xsl:template match="Import/*/URILiteral[position()&gt;2]">
    <xsl:text>, </xsl:text>
    <xsl:value-of select="StringLiteral/data"/>
  </xsl:template>

<!-- [24] VarDecl ::=
  "declare" "variable" "$" QName TypeDeclaration? ((":=" ExprSingle) | "external")
-->

  <xsl:template match="VarDecl">
    <xsl:text>declare variable $</xsl:text>
    <xsl:apply-templates select="*"/>
  </xsl:template>
  
  <xsl:template match="External">
    <xsl:text> external</xsl:text>
  </xsl:template>


  <xsl:template match="VarDecl[not(External)]/*[not(self::Separator|self::TypeDeclaration|self::QName)]" priority="9">
    <xsl:text> := </xsl:text>
    <xsl:next-match/>
  </xsl:template>


<!-- [25] ConstructionDecl ::=
  "declare" "construction" ("strip" | "preserve")
-->

  <xsl:template match="ConstructionDecl">
    <xsl:text>declare construction </xsl:text>
    <xsl:value-of select="data"/>
    <xsl:apply-templates select="Separator"/>
  </xsl:template>

<!-- [26] FunctionDecl ::=
  "declare" "function" QName "(" ParamList? ")" ("as" SequenceType)? (EnclosedExpr | "external")
-->

  <xsl:template match="FunctionDecl">
    <xsl:text>declare function </xsl:text>
    <xsl:apply-templates select="QName"/>
    <xsl:text>(</xsl:text>
    <xsl:apply-templates select="ParamList"/>
    <xsl:text>)</xsl:text>
    <xsl:apply-templates select="SequenceType|EnclosedExpr|External"/>
  </xsl:template>

  <xsl:template match="FunctionDecl/SequenceType">
    <xsl:text> as </xsl:text>
    <xsl:apply-templates select="*"/>
  </xsl:template>

<!-- [27] ParamList ::=
  Param ("," Param)*
-->

  <xsl:template match="ParamList">
    <xsl:for-each select="Param">
      <xsl:if test="position()!=1">, </xsl:if>
      <xsl:apply-templates select="."/>
    </xsl:for-each>
  </xsl:template>

<!-- [28] Param ::=
  "$" QName TypeDeclaration?
-->

  <xsl:template match="Param">
    <xsl:text>$</xsl:text>
    <xsl:apply-templates select="*"/>
  </xsl:template>


  <!-- [29] EnclosedExpr ::=
       "{" Expr "}"
  -->

  <xsl:template match="EnclosedExpr">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <!-- [30] QueryBody ::=
       Expr
  -->

  <xsl:template match="QueryBody">
    <xsl:apply-templates select="*"/>
  </xsl:template>


  <!-- [31] Expr ::=
       ExprSingle ("," ExprSingle)*
  -->

  <xsl:template match="Expr">
    <xsl:for-each select="*">
      <xsl:apply-templates select="."/>
      <xsl:if test="position()!=last()">, </xsl:if>
    </xsl:for-each>
  </xsl:template>


  <!-- [32] ExprSingle ::=
       FLWORExpr | QuantifiedExpr | TypeswitchExpr | IfExpr | OrExpr
  -->

  <!-- Not reported by the parser. -->

  <!-- [33] FLWORExpr ::=
       (ForClause | LetClause)+ WhereClause? OrderByClause? "return" ExprSingle
  -->

  <xsl:template match="FLWORExpr">
    <xsl:apply-templates select="ForClause|LetClause|WhereClause|OrderByClause"/>
    <xsl:text>&#10;return&#10;</xsl:text>
    <xsl:apply-templates select="*[last()]"/>
  </xsl:template>

<!-- [34] ForClause ::=
  "for" "$" VarName TypeDeclaration? PositionalVar? "in" ExprSingle
  ("," "$" VarName TypeDeclaration? PositionalVar? "in" ExprSingle)*
-->

  <xsl:template match="ForClause">
    <xsl:text>&#10;for </xsl:text>
    <xsl:apply-templates select="VarName"/>
  </xsl:template>

  <xsl:template match="ForClause/VarName">
    <xsl:if test="position()!=1">,&#10;    </xsl:if>
    <xsl:text>$</xsl:text>
    <xsl:value-of select="QName/data"/>
    <xsl:apply-templates select="following-sibling::*[1][self::TypeDeclaration]"/>
    <xsl:apply-templates select="following-sibling::*[position()&lt;3][self::PositionalVar]"/>
    <xsl:text> in </xsl:text>
    <xsl:apply-templates select="following-sibling::*[not(self::TypeDeclaration|self::PositionalVar)][1]"/>
  </xsl:template>

  <!-- [35] PositionalVar ::=
       "at" "$" VarName
  -->

  <xsl:template match="PositionalVar">
    <xsl:text> at $</xsl:text>
    <xsl:value-of select="VarName/QName/data"/>
  </xsl:template>


<!-- [36] LetClause ::=
  "let" "$" VarName TypeDeclaration? ":=" ExprSingle
  ("," "$" VarName TypeDeclaration? ":=" ExprSingle)*
-->

  <xsl:template match="LetClause">
    <xsl:text>&#10;let </xsl:text>
      <xsl:for-each select="VarName">
	<xsl:text>$</xsl:text>
	<xsl:value-of select="QName/data"/>
	<xsl:apply-templates select="following-sibling::*[1][self::TypeDeclaration]"/>
        <xsl:text>:=</xsl:text>
	<xsl:apply-templates select="following-sibling::*[not(self::TypeDeclaration)][1]"/>
	<xsl:if test="position()!=last()">, </xsl:if>
      </xsl:for-each>
  </xsl:template>

  <!-- [37] WhereClause ::=
       "where" ExprSingle
  -->

  <xsl:template match="WhereClause">
    <xsl:text> where </xsl:text>
    <xsl:apply-templates select="*"/>
  </xsl:template>

<!-- [38] OrderByClause ::=
  (("order" "by") | ("stable" "order" "by")) OrderSpecList
-->

  <xsl:template match="OrderByClause">
    <xsl:text> </xsl:text>
    <xsl:value-of select="data"/>
    <xsl:text> order by </xsl:text>
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <!-- [39] OrderSpecList ::=
       OrderSpec ("," OrderSpec)*
  -->

  <xsl:template match="OrderSpecList">
    <xsl:apply-templates select="OrderSpec"/>
  </xsl:template>

  <!-- [40] OrderSpec ::=
       ExprSingle OrderModifier
  -->

  <xsl:template match="OrderSpec">
    <xsl:if test="position()!=1">, </xsl:if>
    <xsl:apply-templates select="*[1]"/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="OrderModifier"/>
  </xsl:template>

<!-- [41] OrderModifier ::=
  ("ascending" | "descending")? ("empty" ("greatest" | "least"))? ("collation" URILiteral)?
-->

  <xsl:template match="OrderModifier">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="Descending">
    <xsl:text> descending</xsl:text>
  </xsl:template>

  <xsl:template match="Ascending">
    <xsl:text> ascending</xsl:text>
  </xsl:template>


  <xsl:template match="Greatest">
    <xsl:text> empty greatest</xsl:text>
  </xsl:template>

  <xsl:template match="Least">
    <xsl:text> empty least</xsl:text>
  </xsl:template>

  <xsl:template match="OrderModifier/URILiteral">
    <xsl:text> collation </xsl:text>
    <xsl:value-of select="StringLiteral/data"/>
  </xsl:template>


<!-- [42] QuantifiedExpr ::=
  ("some" | "every") "$" VarName TypeDeclaration? "in" ExprSingle
  ("," "$" VarName TypeDeclaration? "in" ExprSingle)* "satisfies" ExprSingle
-->
  
  <xsl:template match="QuantifiedExpr">
    <xsl:value-of select="data,''"/>
    <xsl:apply-templates select="VarName"/>
    <xsl:text>&#10;satisfies&#10;</xsl:text>
    <xsl:apply-templates select="*[last()]"/>
  </xsl:template>
  
  
  <xsl:template match="QuantifiedExpr/VarName">
    <xsl:if test="position()!=1">,&#10;     </xsl:if>
    <xsltext>$</xsltext>
    <xsl:value-of select="QName/data"/>
    <xsl:apply-templates select="following-sibling::*[1][self::TypeDeclaration]"/>
    <xsltext> in </xsltext>
    <xsl:apply-templates select="following-sibling::*[not(self::TypeDeclaration)][1]"/>
  </xsl:template>
  
<!-- [43] TypeswitchExpr ::=
  "typeswitch" "(" Expr ")" CaseClause+ "default" ("$" VarName)? "return" ExprSingle
-->

  <xsl:template match="TypeswitchExpr">
    <xsl:text>typeswitch (</xsl:text>
    <xsl:apply-templates select="*[1]"/>
    <xsl:text>)&#10;</xsl:text>
    <xsl:apply-templates select="CaseClause|*[not(self::CaseClause)][last()]"/>
  </xsl:template>

  <xsl:template match="TypeswitchExpr/VarName" priority="3">
    <xsltext> $</xsltext>
    <xsl:value-of select="QName/data"/>
  </xsl:template>


  <xsl:template match="TypeswitchExpr/*[last()]" priority="3">
    <xsltext>&#10;default&#10;</xsltext>
    <xsl:apply-templates select="preceding-sibling::VarName[1]"/>
    <xsltext>&#10;return&#10;</xsltext>
    <xsl:next-match/>
  </xsl:template>
  
  
  <!-- [44] CaseClause ::=
       "case" ("$" VarName "as")? SequenceType "return" ExprSingle
  -->
  
  <xsl:template match="CaseClause" priority="2">
    <xsl:text>&#10;case </xsl:text>
    <xsl:apply-templates select="*"/>
  </xsl:template>
  
    <xsl:template match="CaseClause/VarName">
    <xsl:text>$</xsl:text>
    <xsl:value-of select="QName/data"/>
    <xsl:text> as </xsl:text>
  </xsl:template>

  <xsl:template match="CaseClause/*[last()]" priority="10">
    <xsltext> return </xsltext>
    <xsl:next-match/>
  </xsl:template>
  
  <!-- [45] IfExpr ::=
       "if" "(" Expr ")" "then" ExprSingle "else" ExprSingle
  -->
  
  <xsl:template match="IfExpr">
    <xsl:text> if (</xsl:text>
    <xsl:apply-templates select="*[1]"/>
    <xsl:text>) then </xsl:text>
    <xsl:apply-templates select="*[2]"/>
    <xsl:text> else </xsl:text>
    <xsl:apply-templates select="*[3]"/>
  </xsl:template>
  
  <!-- [46] OrExpr ::=
       AndExpr ( "or" AndExpr )*
  -->
  
  <xsl:template match="OrExpr">
    <xsl:apply-templates select="*[2]"/>
    <xsl:text> or </xsl:text>
    <xsl:apply-templates select="*[3]"/>
  </xsl:template>
  
  <!-- [47] AndExpr ::=
       ComparisonExpr ( "and" ComparisonExpr )*
  -->
  
  <xsl:template match="AndExpr">
    <xsl:apply-templates select="*[2]"/>
    <xsl:text> and </xsl:text>
    <xsl:apply-templates select="*[3]"/>
  </xsl:template>
  
  <!-- [48] ComparisonExpr ::=
       RangeExpr ( (ValueComp
       | GeneralComp
       | NodeComp) RangeExpr )?
  -->
  
  
  <xsl:template match="ComparisonExpr|AdditiveExpr|MultiplicativeExpr|IntersectExceptExpr|UnionExpr|RangeExpr">
      <xsl:apply-templates select="*[2]"/>
      <xsl:value-of select="('',data,'')"/>
      <xsl:apply-templates select="*[3]"/>
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
  TreatExpr ( "instance" "of" SequenceType )?
-->

  <xsl:template match="InstanceofExpr">
    <xsl:apply-templates select="*[1]"/>
    <xsl:text> instance of </xsl:text>
    <xsl:apply-templates select="*[2]"/>
  </xsl:template>

<!-- [55] TreatExpr ::=
  CastableExpr ( "treat" "as" SequenceType )?
-->

  <xsl:template match="TreatExpr">
    <xsl:apply-templates select="*[1]"/>
    <xsl:text> treat as </xsl:text>
    <xsl:apply-templates select="SequenceType"/>
  </xsl:template>

<!-- [56] CastableExpr ::=
  CastExpr ( "castable" "as" SingleType )?
-->

  <xsl:template match="CastableExpr">
    <xsl:apply-templates select="*[1]"/>
    <xsl:text> castable as </xsl:text>
    <xsl:apply-templates select="*[2]"/>
  </xsl:template>

<!-- [57] CastExpr ::=
  UnaryExpr ( "cast" "as" SingleType )?
-->

  <xsl:template match="CastExpr">
    <xsl:apply-templates select="*[1]"/>
    <xsl:text> cast as </xsl:text>
    <xsl:apply-templates select="SingleType"/>
  </xsl:template>

  <!-- [58] UnaryExpr ::=
       ("-" | "+")* ValueExpr
  -->

  <xsl:template match="UnaryExpr">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="Plus">+</xsl:template>

  <xsl:template match="Minus">-</xsl:template>

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
   <xsl:text> validate </xsl:text>
   <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="LbraceExprEnclosure">{</xsl:template>

  <xsl:template match="Rbrace">}</xsl:template>

  <!-- [64] ValidationMode ::=
       "lax" | "strict"
  -->

  <xsl:template match="ValidationMode">
      <xsl:value-of select="data"/>
  </xsl:template>

  <!-- [65] ExtensionExpr ::=
       Pragma+ "{" Expr? "}"
  -->

  <xsl:template match="ExtensionExpr">
    <xsl:apply-templates select="Pragma"/>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="Expr"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <!-- [66] Pragma ::=
       "(#" S? QName PragmaContents "#)"
  -->

  <xsl:template match="Pragma">
    <xsl:text>(#</xsl:text>
    <xsl:value-of select="QNameForPragma/data"/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="PragmaContents"/>
    <xsl:text>#)</xsl:text>
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
    <xsl:text>/</xsl:text>
  </xsl:template>

  <xsl:template match="PathExpr">
    <xsl:for-each select="*">
      <xsl:apply-templates select="."/>
      <xsl:if test="not(self::SlashSlash) and position()!=last()">/</xsl:if>
    </xsl:for-each>
  </xsl:template>


  <xsl:template match="SlashSlash">
    <xsl:text>/</xsl:text>
  </xsl:template>


<!-- [69] RelativePathExpr ::=
  StepExpr (("/" | "//") StepExpr)*
-->

  <!-- Not reported by the parser -->

<!-- [70] StepExpr ::=
  FilterExpr | AxisStep
-->

  <xsl:template match="StepExpr">
    <xsl:apply-templates select="*"/>
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
    <xsl:value-of select="data"/>
    <xsl:text>::</xsl:text>
  </xsl:template>

  <!-- [74] AbbrevForwardStep ::=
       "@"? NodeTest
  -->


  <xsl:template match="AbbrevForwardStep">
    <xsl:value-of select="data"/>
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
    <xsl:value-of select="data"/>
    <xsl:text>::</xsl:text>
  </xsl:template>

  <!-- [77] AbbrevReverseStep ::=
       ".."
  -->

  <xsl:template match="AbbrevReverseStep">
    <xsl:text>..</xsl:text>
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
    <xsl:apply-templates select="*"/>
  </xsl:template>

 

<!-- [80] Wildcard ::=
  "*" | (NCName ":" "*") | ("*" ":" NCName)
-->

  <xsl:template match="Wildcard">
   <xsl:value-of select=".//data"/>
  </xsl:template>

  
  <!-- [81] FilterExpr ::=
       PrimaryExpr PredicateList
  -->

  <!-- Not reported by the parser -->

  <!-- [82] PredicateList ::=
       Predicate*
  -->

  <xsl:template match="PredicateList">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <!-- [83] Predicate ::=
       "[" Expr "]"
  -->

  <xsl:template match="Predicate">
    <xsl:text>[</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>]</xsl:text>
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
    <xsl:text>$</xsl:text>
    <xsl:value-of select="QName/data"/>
  </xsl:template>

  <xsl:template match="StepExpr/VarName">
    <xsl:text>$</xsl:text>
    <xsl:value-of select="QName/data"/>
  </xsl:template>


  <!-- [88] VarName ::=
       QName
  -->

  <xsl:template match="VarName">
    <xsl:value-of select="QName/data"/>
  </xsl:template>


  <!-- [89] ParenthesizedExpr ::=
       "(" Expr? ")"
  -->

  <xsl:template match="ParenthesizedExpr">
    <xsl:text>(</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>)</xsl:text>
  </xsl:template>

  <!-- [90] ContextItemExpr ::=
       "."
  -->

  <xsl:template match="ContextItemExpr">
    <xsl:text>.</xsl:text>
  </xsl:template>


<!-- [91] OrderedExpr ::=
  "ordered" "{" Expr "}"
-->

  <xsl:template match="OrderedExpr">
    <xsl:text> ordered {</xsl:text>
    <xsl:apply-templates select="Expr"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

<!-- [92] UnorderedExpr ::=
  "unordered" "{" Expr "}"
-->
 
  <xsl:template match="UnorderedExpr">
    <xsl:text> unordered {</xsl:text>
    <xsl:apply-templates select="Expr"/>
    <xsl:text>}</xsl:text>
  </xsl:template>


<!-- [93] FunctionCall ::=
  QName "(" (ExprSingle ("," ExprSingle)*)? ")"
-->

  <xsl:template match="FunctionCall">
    <xsl:apply-templates select="FunctionQName"/>
    <xsl:text>(</xsl:text>
     <xsl:for-each select="*[position()&gt;1]">
	<xsl:apply-templates select="."/>
	<xsl:if test="position()!=last()">, </xsl:if>
     </xsl:for-each>
    <xsl:text>)</xsl:text>
  </xsl:template>


  <xsl:template match="FunctionQName">
    <xsl:value-of select="data"/>
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
  <xsl:text>&lt;</xsl:text>
  <xsl:apply-templates select="TagQName|DirAttributeList"/>
  <xsl:choose>
    <xsl:when test="StartTagClose">
      <xsl:text>&gt;</xsl:text>
      <xsl:apply-templates select="DirElemContent"/>
      <xsl:text>&lt;/</xsl:text>
      <xsl:apply-templates select="TagQName"/>
      <xsl:text>&gt;</xsl:text>
    </xsl:when>
    <xsl:otherwise>/&gt;</xsl:otherwise>
  </xsl:choose>
</xsl:template>
  
  <xsl:template match="TagQName">
    <xsl:value-of select="data"/>
  </xsl:template>


  <xsl:template match="TagQName[preceding-sibling::*[1][self::EndTagOpen]]"/>


<!-- [97] DirAttributeList ::=
  (S (QName S? "=" S? DirAttributeValue)?)*
-->

  <xsl:template match="DirAttributeList">
    <xsl:apply-templates select="TagQName"/>
  </xsl:template>

  <xsl:template match="AttributeConstructor">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="DirAttributeList/TagQName">
    <xsl:text> </xsl:text>
    <xsl:value-of select="data"/>
    <xsl:text>=</xsl:text>
    <xsl:apply-templates select="following-sibling::DirAttributeValue[1]"/>
  </xsl:template>


<!-- [98] DirAttributeValue ::=
  ('"' (EscapeQuot | QuotAttrValueContent)* '"')
  | ("'" (EscapeApos | AposAttrValueContent)* "'")
-->

  <xsl:template match="DirAttributeValue">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="OpenQuot|CloseQuot">"</xsl:template>

  <xsl:template match="OpenApos|CloseApos">'</xsl:template>

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

  <xsl:template match="DirElemContent">
    <xsl:apply-templates select="*"/>
  </xsl:template>

<!-- [102] CommonContent ::=
  PredefinedEntityRef | CharRef | "{{" | "}}" | EnclosedExpr
-->

  <xsl:template match="CommonContent">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="LCurlyBraceEscape">
    <xsl:text>{{</xsl:text>
  </xsl:template>

  <xsl:template match="RCurlyBraceEscape">
    <xsl:text>}}</xsl:text>
  </xsl:template>

  <!-- [103] DirCommentConstructor ::=
       "<!-/-" DirCommentContents "-/->"
  -->

  <xsl:template match="DirCommentConstructor">
    <xsl:text>&lt;!--</xsl:text>
    <xsl:value-of select="string-join(DirCommentContents/*/data,'')"/>
    <xsl:text>--&gt;</xsl:text>
  </xsl:template>

<!-- [104] DirCommentContents ::=
  ((Char - '-') | ('-' (Char - '-')))*
-->

  <!-- handled in [101] -->

  <!-- [105] DirPIConstructor ::=
       "<?" PITarget (S DirPIContents)? "?>"
  -->

  <xsl:template match="DirPIConstructor">
    <xsl:text>&lt;?</xsl:text>
    <xsl:value-of select="PITarget/data"/>
    <xsl:apply-templates select="DirPIContents"/>
    <xsl:text>?&gt;</xsl:text>
  </xsl:template>

  <!-- [106] DirPIContents ::=
       (Char* - (Char* '?>' Char*))
  -->

  <xsl:template match="DirPIContents">
    <xsl:text> </xsl:text>
    <xsl:value-of select="string-join(PIContentChar/data,'')"/>
  </xsl:template>

  <!-- [107] CDataSection ::=
       "<![CDATA[" CDataSectionContents "]]>"
  -->

  <xsl:template match="CDataSection">
    <xsl:text>&lt;![CDATA[</xsl:text>
    <xsl:value-of select="string-join(CDataSectionContents/CDataSectionChar/data,'')"/>
    <xsl:text>]]&gt;</xsl:text>
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
    <xsl:text> document {</xsl:text>
    <xsl:apply-templates select="Expr"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

<!-- [111] CompElemConstructor ::=
  "element" (QName | ("{" Expr "}")) "{" ContentExpr? "}"
-->

  <xsl:template match="CompElemConstructor">
    <xsl:text> element </xsl:text>
    <xsl:apply-templates select="*"/>
  </xsl:template>


  <!-- [112] ContentExpr ::=
       Expr
  -->

  <xsl:template match="ContentExpr">
    <xsl:apply-templates select="*"/>
  </xsl:template>

<!-- [113] CompAttrConstructor ::=
  "attribute" (QName | ("{" Expr "}")) "{" Expr? "}"
-->

  <xsl:template match="CompAttrConstructor">
    <xsl:text> attribute </xsl:text>
    <xsl:apply-templates select="*"/>
  </xsl:template>

<!-- [114] CompTextConstructor ::=
  "text" "{" Expr "}"
-->

  <xsl:template match="CompTextConstructor">
    <xsl:text> text</xsl:text>
    <xsl:apply-templates select="*"/>
  </xsl:template>

<!-- [115] CompCommentConstructor ::=
  "comment" "{" Expr "}"
-->

  <xsl:template match="CompCommentConstructor">
    <xsl:text> comment</xsl:text>
    <xsl:apply-templates select="*"/>
  </xsl:template>

<!-- [116] CompPIConstructor ::=
  "processing-instruction" (NCName | ("{" Expr "}")) "{" Expr? "}"
-->

  <xsl:template match="CompPIConstructor">
    <xsl:text> processing-instruction </xsl:text>
    <xsl:apply-templates select="*"/>
  </xsl:template>


  <!-- [117] SingleType ::=
       AtomicType "?"?
  -->
  <xsl:template match="SingleType">
    <xsl:apply-templates select="*"/>
    <xsl:value-of select="data"/>
  </xsl:template>

  <!-- [118] TypeDeclaration ::=
       "as" SequenceType
  -->

  <xsl:template match="TypeDeclaration">
    <xsl:text> as </xsl:text>
    <xsl:apply-templates select="SequenceType/*"/>
  </xsl:template>

<!-- [119] SequenceType ::=
  ("empty-sequence" "(" ")") | (ItemType OccurrenceIndicator?)
-->

  <xsl:template match="SequenceType">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="SequenceType/data[.='empty-sequence']" priority="2">
    <xsl:text> empty-sequence()</xsl:text>
  </xsl:template>

  <!-- [120] OccurrenceIndicator ::=
       "?" | "*" | "+"
  -->

  <xsl:template match="OccurrenceIndicator">
    <xsl:value-of select="data"/>
  </xsl:template>

<!-- [121] ItemType ::=
  KindTest | ("item" "(" ")") | AtomicType
-->

  <xsl:template match="ItemType">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="ItemType/data[.='item']">
    <xsl:text> item()</xsl:text>
  </xsl:template>

  <!-- [122] AtomicType ::=
       QName
  -->

  <xsl:template match="AtomicType">
    <xsl:apply-templates select="*"/>
  </xsl:template>

<!-- [123] KindTest ::=
  DocumentTest | ElementTest | AttributeTest | SchemaElementTest
  | SchemaAttributeTest | PITest | CommentTest | TextTest | AnyKindTest
-->

<!-- [124] AnyKindTest ::=
  "node" "(" ")"
-->

  <xsl:template match="AnyKindTest">
    <xsl:text> node()</xsl:text>
  </xsl:template>

<!-- [125] DocumentTest ::=
  "document-node" "(" (ElementTest | SchemaElementTest)? ")"
-->

  <xsl:template match="DocumentTest">
    <xsl:text> document-node (</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>)</xsl:text>
  </xsl:template>

<!-- [126] TextTest ::=
  "text" "(" ")"
-->

  <xsl:template match="TextTest">
    <xsl:text> text()</xsl:text>
  </xsl:template>

<!-- [127] CommentTest ::=
  "comment" "(" ")"
-->

  <xsl:template match="CommentTest">
    <xsl:text> comment()</xsl:text>
  </xsl:template>

<!-- [128] PITest ::=
  "processing-instruction" "(" (NCName | StringLiteral)? ")"
-->

  <xsl:template match="PITest">
    <xsl:text> processing-instruction(</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>)</xsl:text>
  </xsl:template>

<!-- [129] AttributeTest ::=
  "attribute" "(" (AttribNameOrWildcard ("," TypeName)?)? ")"
-->

  <xsl:template match="AttributeTest">
    <xsl:text> attribute(</xsl:text>
    <xsl:apply-templates select="*[1]"/>
    <xsl:if test="*[2]">
      <xsl:text>,</xsl:text>
      <xsl:apply-templates select="*[2]"/>
    </xsl:if>
    <xsl:text>)</xsl:text>
  </xsl:template>

<!-- [130] AttribNameOrWildcard ::=
  AttributeName | "*"
-->

  <xsl:template match="AttribNameOrWildcard">
    <xsl:apply-templates select="*"/>
  </xsl:template>


  <xsl:template match="AttribNameOrWildcard[data='*' and not(*[2])]" priority="2">
    <xsl:text>*</xsl:text>
  </xsl:template>

<!-- [131] SchemaAttributeTest ::=
  "schema-attribute" "(" AttributeDeclaration ")"
-->

  <xsl:template match="SchemaAttributeTest">
    <xsl:text> schema-attribute(</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>)</xsl:text>
  </xsl:template>


  <!-- [132] AttributeDeclaration ::=
       AttributeName
  -->

  <!-- Handled by SchemaAttributeTest -->


<!-- [133] ElementTest ::=
  "element" "(" (ElementNameOrWildcard ("," TypeName "?"?)?)? ")"
-->

  <xsl:template match="ElementTest">
    <xsl:text> element(</xsl:text>
    <xsl:apply-templates select="*[1]"/>
    <xsl:if test="*[2]">
      <xsl:text>,</xsl:text>
      <xsl:apply-templates select="*[2]"/>
    </xsl:if>
    <xsl:text>)</xsl:text>
  </xsl:template>

  <xsl:template match="Nillable">
    <xsl:text>?</xsl:text>
  </xsl:template>

  <!-- [134] ElementNameOrWildcard ::=
       ElementName | "*"
  -->

  <xsl:template match="ElementNameOrWildcard[not(ElementName)]">
    <xsl:text>*</xsl:text>
  </xsl:template>

  <xsl:template match="ElementNameOrWildcard[ElementName]">
    <xsl:apply-templates select="ElementName"/>
  </xsl:template>

<!-- [135] SchemaElementTest ::=
  "schema-element" "(" ElementDeclaration ")"
-->

  <xsl:template match="SchemaElementTest">
    <xsl:text> schema-element(</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>)</xsl:text>
  </xsl:template>

  <!-- [136] ElementDeclaration ::=
       ElementName
  -->


  <!-- [137] AttributeName ::=
       QName
  -->

  <xsl:template match="AttributeName">
    <xsl:apply-templates select="QName"/>
  </xsl:template>

  <!-- [138] ElementName ::=
       QName
  -->

  <xsl:template match="ElementName">
    <xsl:apply-templates select="QName"/>
  </xsl:template>

  <!-- [139] TypeName ::=
       QName
  -->

  <xsl:template match="TypeName">
    <xsl:apply-templates select="QName"/>
  </xsl:template>

  <!-- [140] URILiteral ::=
       StringLiteral
  -->

  <xsl:template match="URILiteral">
    <xsl:value-of select="StringLiteral/data"/>
  </xsl:template>

  <!-- [141] IntegerLiteral ::=
       Digits
  -->

  <xsl:template match="IntegerLiteral">
    <xsl:value-of select="data"/>
  </xsl:template>

  <!-- [142] DecimalLiteral ::=
       ("." Digits) | (Digits "." [0-9]*)
  -->

  <xsl:template match="DecimalLiteral">
    <xsl:value-of select="data"/>
  </xsl:template>

  <!-- [143] DoubleLiteral ::=
       (("." Digits) | (Digits ("." [0-9]*)?)) [eE] [+-]? Digits
  -->

  <xsl:template match="DoubleLiteral">
    <xsl:value-of select="data"/>
  </xsl:template>

<!-- [144] StringLiteral ::=
  ('"' (PredefinedEntityRef | CharRef | EscapeQuot | [^"&])* '"')
  | ("'" (PredefinedEntityRef | CharRef | EscapeApos | [^'&])* "'")
-->

  <xsl:template match="StringLiteral">
    <xsl:value-of select="data"/>
  </xsl:template>

  <!-- [145] PredefinedEntityRef ::=
       "&" ("lt" | "gt" | "amp" | "quot" | "apos") ";"
  -->

  <xsl:template match="PredefinedEntityRef">
    <xsl:value-of select="data"/>
  </xsl:template>

  <!-- [146] EscapeQuot ::=
       '""'
  -->

  <xsl:template match="EscapeQuot">""</xsl:template>

  <!-- [147] EscapeApos ::=
       "''"
  -->

  <xsl:template match="EscapeApos">''</xsl:template>

<!-- [148] ElementContentChar ::=
  Char - [{}<&]
-->


  <xsl:template match="ElementContentChar">
    <xsl:value-of select="data"/>
  </xsl:template>


  <!-- [149] QuotAttrContentChar ::=
       Char - ["{}<&]
  -->


  <xsl:template match="QuotAttrContentChar">
    <xsl:value-of select="data"/>
  </xsl:template>


  <!-- [150] AposAttrContentChar ::=
       Char - ['{}<&]
  -->

  <xsl:template match="AposAttrContentChar">
    <xsl:value-of select="data"/>
  </xsl:template>

<!-- [151] Comment ::=
  "(:" (CommentContents | Comment)* ":)"
-->

  <!-- comments are dropped in translation (not reported by the xquery parser)-->

  <!-- [152] PITarget ::=
       [http://www.w3.org/TR/REC-xml#NT-PITarget]XML
  -->

  <xsl:template match="PITarget">
    <xsl:value-of select="data"/>
  </xsl:template>

  <!-- [153] CharRef ::=
       [http://www.w3.org/TR/REC-xml#NT-CharRef]XML
  -->

  <xsl:template match="CharRef">
    <xsl:value-of select="data"/>
  </xsl:template>



  <!-- [154] QName ::=
       [http://www.w3.org/TR/REC-xml-names/#NT-QName]Names
  -->

  <xsl:template match="QName">
    <xsl:value-of select="data"/>
  </xsl:template>

  <!-- [155] NCName ::=
       [http://www.w3.org/TR/REC-xml-names/#NT-NCName]Names
  -->

  <xsl:template match="NCName">
    <xsl:value-of select="data"/>
  </xsl:template>

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

  <xsl:template match="data"/>


  <xsl:template match="*">
    <xsl:message terminate="no">
Unsupported element: <xsl:value-of select="name(..)"/>/<xsl:value-of select="name()"/>
<xsl:copy-of select="."/>
===
<!--<xsl:copy-of select="/"/>-->
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
    <xsl:text>error(QName("http://www.w3.org/2005/xqt-errors",</xsl:text>
    <xsl:value-of select="$error"/>
    <xsl:text>))</xsl:text>
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


  <xsl:template match="Lbrace">{</xsl:template>

</xsl:stylesheet>



