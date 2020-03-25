<!--
    xq2xsltest.xsl
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
		xmlns="http://www.w3.org/2005/02/query-test-XQTSResult"
		xmlns:xq="java:Xq2xml"
		xmlns:trans2="java:trans2"
		xmlns:xqx="http://www.w3.org/2005/XQueryX"
		xmlns:qt="http://www.w3.org/2005/02/query-test-XQTSCatalog"
		exclude-result-prefixes="saxon xs  xq qt trans2 xsl axsl xqx">
  <xsl:import href="xq2xsl.xsl"/>
  <xsl:namespace-alias stylesheet-prefix="axsl" result-prefix="xsl"/>

  <xsl:param name="test" select="'no'"/>

  <xsl:variable name="qthome" select="/qt:test-suite/@XQueryQueryOffsetPath"/>
  <xsl:variable name="qtxhome" select="/qt:test-suite/@XQueryXQueryOffsetPath"/>
  <xsl:variable name="qtxslhome" select="replace($qtxhome,'XQueryX','XQueryXXSLT')"/>

  <xsl:variable name="xqueryx" select="trans2:compile-stylesheet(doc('xqueryx.xsl'))"/>

  <xsl:output encoding="utf-8"/>

  <xsl:key name="s" match="qt:sources/qt:source" use="@ID"/>
  <xsl:key name="m" match="qt:sources/qt:module" use="@ID"/>
  <xsl:template match="/">
    <xsl:result-document href="xqx2xslresults.xml">
      <test-suite-result>

	<xsl:copy-of select="$top-matter"/>


	<xsl:for-each select="
descendant::qt:test-case
(:[@name='fn-string-length-18']:)
(:[@name='externalcontextitem-22']:)
(:[matches(@name,'^fn-collection-')]:)
(:[matches(@name,'^K2?-Int')]:)
(:descendant::qt:test-group[@name='Modules']//qt:test-case:)
(: [@name='copynamespace-1.xq']/following::qt:test-case :)
(: [@name='K2-InternalVariablesWithout-1']/following::qt:test-case :)
(: [@name='Constr-cont-uripres-1']:)
(: [@name='modules-1']/(.,following-sibling::qt:test-case):)
(:   [@name='Constr-cont-uripres-1']:)
(:[doc('xr-88.xml')//*:test-case[@name=current()/@name]/@result='fail']:)
(:[position() &gt;4948]:)
">
	  <test-case name="{@name}">


		<xsl:message>
!!<xsl:value-of select="position()"/>: <xsl:value-of select="@name"/>
		</xsl:message>
		
		<xsl:variable name="xqx" select="concat($qtxhome,@FilePath,qt:query/@name,'.xqx')"/>

	    <xsl:choose>
	      <xsl:when test="@scenario='parse-error'">
		<xsl:attribute name="result" select="'not tested'"/>
		<xsl:attribute name="comment" select="'(parse-error scenario)'"/>
	      </xsl:when>
	      <xsl:when test="not(doc-available($xqx))">
		<xsl:attribute name="result" select="'not tested'"/>
		<xsl:attribute name="comment" select="'(missing xqx file)'"/>
	      </xsl:when>
	      <xsl:when test="../@name=('Surrogates')">
		<xsl:attribute name="result" select="'fail'"/>
		<xsl:attribute name="comment" select="'(processing failed)'"/>
	      </xsl:when>
	      <xsl:when test="@name=('prolog-version-2')">
		<xsl:attribute name="result" select="'fail'"/>
		<xsl:attribute name="comment" select="'(utf16)'"/>
	      </xsl:when>
	      <xsl:when test="@name=('Constr-namespace-24')">
		<xsl:attribute name="result" select="'fail'"/>
		<xsl:attribute name="comment" select="'(incorretc ns syntax)'"/>
	      </xsl:when>
	      <xsl:when test="@name=('K-CopyNamespacesProlog-4','K-CopyNamespacesProlog-5','K-ConstructionProlog-2')">
		<xsl:attribute name="result" select="'fail'"/>
		<xsl:attribute name="comment" select="'(parser exception)'"/>
	      </xsl:when>
	      <xsl:when test="matches(@name,'^K2-InternalVariablesWithout-[1-6]$|^K-InternalVariablesWith-(16|18|20)$')">
		<xsl:attribute name="result" select="'fail'"/>
		<xsl:attribute name="comment" select="'(XSLT stack overflow)'"/>
	      </xsl:when>
	      <xsl:when test="matches(@name,'^K2-InternalVariablesWithout-[9]$')">
		<xsl:attribute name="result" select="'fail'"/>
		<xsl:attribute name="comment" select="'(XSLT loops)'"/>
	      </xsl:when>
	      <xsl:when test="ancestor::qt:test-group/@name='StaticTyping'">
		<xsl:attribute name="result" select="'not tested'"/>
		<xsl:attribute name="comment" select="'(Static Typing)'"/>
	      </xsl:when>
	      <xsl:when test="ancestor::qt:test-group/@name='SchemaImport'">
		<xsl:attribute name="result" select="'not tested'"/>
		<xsl:attribute name="comment" select="'(Schema Import)'"/>
	      </xsl:when>
	      <xsl:when test="ancestor::qt:test-group/@name='SchemaValidation'">
		<xsl:attribute name="result" select="'not tested'"/>
		<xsl:attribute name="comment" select="'(Schema Validation)'"/>
	      </xsl:when>
	      <xsl:when test="ancestor::qt:test-group/@name='TrivialEmbedding'">
		<xsl:attribute name="result" select="'not tested'"/>
		<xsl:attribute name="comment" select="'(Trivial)'"/>
	      </xsl:when>
	      <xsl:otherwise>

		<xsl:variable name="xq" select="concat($qthome,@FilePath,qt:query/@name,'.xq')"/>
		<xsl:variable name="xqxslf" select="concat($qtxslhome,@FilePath,qt:query/@name,'.xsl')"/>


<!--
		<xsl:variable name="xq1" select="replace(unparsed-text($xq,'utf-8'),'&#13;&#10;','&#10;')"/>
-->

		<xsl:variable name="xq1" select="string(trans2:transform($xqueryx,doc($xqx)))"/>

<!--
<xsl:message>
===========
<xsl:copy-of select="$xq1"/>
===============
</xsl:message>
-->

		<xsl:variable name="xqxml" select="saxon:discard-document(saxon:parse(xq:convert($xq1)))"/>



		<xsl:variable name="xqx">
		  <xsl:choose>
		    <!-- parser has problems with comments, so if it failed to parse, try zapping comments then try again.
			 Only do this if failed when failure unexpected as it isn't really safe, eg "comments" inside strings
			 or attributes will be corrupted 
		    -->
		    <xsl:when test="false() and $xqxml/error and not(@scenario='parse-error')">
		      <xsl:apply-templates select="saxon:discard-document(saxon:parse(xq:convert(
						   replace(replace(replace($xq1,'\(:[^:]*([^\(]:[^\)][^:]*)*:\)',''),'\(:[^:]*([^\(]:[^\)][^:]*)*:\)',''),'\(:[^:]*([^\(]:[^\)][^:]*)*:\)','')
						   )))/*"/>
		    </xsl:when>
		    <xsl:otherwise>
		      <xsl:apply-templates select="$xqxml/*"/>
		    </xsl:otherwise>
		  </xsl:choose>
		</xsl:variable>


		<xsl:if test="false() and not(preceding-sibling::*[1]/qt:query/@name=qt:query/@name)">
		  <xsl:result-document href="{$xqxslf}" method="xml" indent="yes">
		    <xsl:comment>
		      <xsl:text>
			Automatically converted by xq2xsl.xsl
		      </xsl:text>
		      <xsl:variable name="c" select="xq:comment(tokenize($xq1,' *&#13;?&#10; *'))"/>
		      <xsl:if test="$c">
			<xsl:text>    Original Comments:&#10;</xsl:text>
			<xsl:value-of select="$c"/>
		      </xsl:if>
		    </xsl:comment>
		    <xsl:text>&#10;</xsl:text>
		    <xsl:copy-of select="saxon:discard-document($xqx)"/>
		  </xsl:result-document>
		</xsl:if>


		<xsl:variable name="in" select="qt:input-file[@variable]"/>
		<xsl:variable name="dc" select="qt:defaultCollection"/>
		<xsl:variable name="ic" select="qt:contextItem"/>
		<xsl:variable name="inuri" select="qt:input-URI[@variable]"/>
		<xsl:variable name="mod" select="qt:module"/>
		<xsl:variable name="extvar" select="qt:input-query"/>

<!-- make xsl version -->
		      <xsl:for-each select="$extvar">
<!--
<xsl:message>
extvar  <xsl:value-of select="@variable"/>
</xsl:message>
-->
		<xsl:variable name="evxq" select="concat($qthome,../@FilePath,@name,'.xq')"/>
<!--
<xsl:message>
extvar  <xsl:copy-of select="$evxq"/>
</xsl:message>
-->
		<xsl:variable name="evxqxslf" select="concat($qtxslhome,../@FilePath,@name,'.xsl')"/>

		<xsl:variable name="evxq1" select="replace(unparsed-text($evxq,'utf-8'),'&#13;&#10;','&#10;')"/>
		<xsl:variable name="evxqxml" select="saxon:discard-document(saxon:parse(xq:convert($evxq1)))"/>
		<xsl:variable name="evxqx">
		      <xsl:apply-templates select="$evxqxml/*"/>
		</xsl:variable>

		<xsl:if test="false() and not(../preceding-sibling::*[1]/qt:input-query/@name=@name)">
		  <xsl:result-document href="{$evxqxslf}" method="xml" indent="yes">
		    <xsl:comment>
		      <xsl:text>
			Automatically converted by xq2xsl.xsl
		      </xsl:text>
		      <xsl:variable name="c" select="xq:comment(tokenize($evxq1,' *&#13;?&#10; *'))"/>
		      <xsl:if test="$c">
			<xsl:text>    Original Comments:&#10;</xsl:text>
			<xsl:value-of select="$c"/>
		      </xsl:if>
		    </xsl:comment>
		    <xsl:text>&#10;</xsl:text>
		    <xsl:copy-of select="saxon:discard-document($evxqx)"/>
      </xsl:result-document>
		</xsl:if>

		      </xsl:for-each>
<!-- end of xsl output  -->

		<xsl:variable name="xqtest">
		  <xsl:for-each select="$xqx/*">
		    <xsl:copy>
		      <xsl:copy-of select="@*"/>
                      <xsl:for-each select="xsl:include[@href=$mod/@namespace]">
                       <xsl:for-each select="$mod[@namespace=current()/@href]">
			 <axsl:include href="dpc-{key('m',string(.))/@FileName}.xsl"/>
		       </xsl:for-each>
		      </xsl:for-each>
		      <xsl:copy-of select="*[not(self::xsl:param[@name=($in,$inuri,$extvar)/@variable])]
                                            [not(self::xsl:include[@href=$mod/@namespace])]
					    [not(self::xsl:param[@name='input'] and $ic)]"/>


		      <xsl:for-each select="$ic">
			<axsl:param name="input" select="doc('{key('s',.)/@FileName}')"/>
		      </xsl:for-each>

		      <xsl:for-each select="$in">
			<axsl:param name="{@variable}" select="doc('{key('s',.)/@FileName}')"/>
		      </xsl:for-each>

		      <xsl:for-each select="$dc">
			<axsl:param name="xq:dc" select="'{(key('s',.)[self::qt:source]/@FileName,concat('collections/',.,'/collection.xml'))[1]}'"/>
		      </xsl:for-each>

		      <xsl:for-each select="$inuri">
			<axsl:param name="{@variable}" select="'{(key('s',.)[self::qt:source]/@FileName,concat('collections/',.,'/collection.xml'))[1]}'"/>
		      </xsl:for-each>


		      <xsl:for-each select="$extvar">

		<xsl:variable name="evxq" select="concat($qthome,../@FilePath,@name,'.xq')"/>

		<xsl:variable name="evxqxslf" select="concat($qtxslhome,../@FilePath,@name,'.xsl')"/>
		<xsl:variable name="evxq1" select="replace(unparsed-text($evxq,'utf-8'),'&#13;&#10;','&#10;')"/>
		<xsl:variable name="evxqxml" select="saxon:discard-document(saxon:parse(xq:convert($evxq1)))"/>

		<xsl:variable name="evxqx">
		      <xsl:apply-templates select="$evxqxml/*"/>
		</xsl:variable>



<!--
<xsl:message>
evxqx <xsl:copy-of select="$evxqx"/>
</xsl:message>
-->

			<axsl:param name="{@variable}" as="item()*">
<xsl:copy-of select="$xqx/*/xsl:param[@name=current()/@name]/@as"/>
<xsl:copy-of select="$evxqx/*/xsl:template/xsl:for-each/node()"/>
			</axsl:param>
		      </xsl:for-each>



		      <axsl:template match="/">
			<axsl:call-template name="main"/>
		      </axsl:template>
		    </xsl:copy>

		  </xsl:for-each>

		</xsl:variable>




<!--
<xsl:message>
[[[[
  <xsl:copy-of select="$xqtest"/>
]]]]
</xsl:message>
-->

		<xsl:variable name="comp" select="trans2:compile-stylesheet($xqtest)"/>
		<xsl:variable name="comp-err" select="$comp instance of xs:string"/>
		<xsl:choose>
		  <xsl:when test="$comp-err and (@scenario='parse-error' or qt:expected-error)">
<!--
		    <xsl:message>
		      <xsl:value-of select="@name"/>
		    </xsl:message>
-->
		    <xsl:attribute name="result" select="'pass'"/>
		    <xsl:attribute name="comment" select="string-join(('compile time error',$comp,':',qt:expected-error),' ')"/>
		  </xsl:when>
		  <xsl:when test="$comp-err and $xqtest/xsl:stylesheet/xsl:import-schema">
<!--
		    <xsl:message>
		      <xsl:value-of select="@name"/>
		    </xsl:message>
-->
		    <xsl:attribute name="result" select="'not applicable'"/>
		    <xsl:attribute name="comment" select="'schema import feature'"/>
		  </xsl:when>
		  <xsl:when test="$comp-err and not(@scenario='parse-error' or qt:expected-error)">
<!--
		    <xsl:message>
		      <xsl:value-of select="@name"/>
		    </xsl:message>
-->
		    <xsl:attribute name="result" select="'fail'"/>
		    <xsl:attribute name="comment" select="'unexpected compile time error'"/>
		  </xsl:when>
		  <xsl:otherwise>
		    <xsl:variable name="r" select="trans2:transform($comp,$xqtest)"/>
		    <xsl:variable name="run-err" select="$r instance of xs:string"/>
		    <xsl:choose>
		      <xsl:when test="$run-err and (@scenario='runtime-error' or qt:expected-error)">
<!--
			<xsl:message>
			  <xsl:value-of select="@name"/>
			</xsl:message>
-->
			<xsl:attribute name="result" select="'pass'"/>
<xsl:if test="not(qt:expected-error and (some $e in qt:expected-error satisfies contains(string($r),$e)))">
			<xsl:attribute name="comment" select="string-join(('run time error',$r,':',qt:expected-error[1]),' ')"/>
</xsl:if>
</xsl:when>

		      <xsl:when test="$run-err and not(@scenario='runtime-error'  or qt:expected-error) and $xqtest/xsl:stylesheet/xsl:import-schema">
<!--
			<xsl:message>
			  <xsl:value-of select="@name"/>
			</xsl:message>
-->
			<xsl:attribute name="result" select="'not applicable'"/>
			<xsl:attribute name="comment" select="'schema import feature'"/>
		      </xsl:when>

		      <xsl:when test="$run-err and not(@scenario='runtime-error' or qt:expected-error)"> 
<!--
			<xsl:message>
			  <xsl:value-of select="@name"/>
			</xsl:message>
-->
			<xsl:attribute name="result" select="'fail'"/>
			<xsl:attribute name="comment" select="string-join(('unexpected run time error',$r,':',qt:expected-error),' ')"/>
		      </xsl:when>

		      <xsl:when test="$run-err"> 
<!--
			<xsl:message>
			  <xsl:value-of select="@name"/>
			</xsl:message>
-->
			<xsl:attribute name="result" select="'fail'"/>
			<xsl:attribute name="comment" select="string-join(('very unexpected run time error',$r,':',qt:expected-error),' ')"/>
		      </xsl:when>

		      <xsl:when test="@scenario=('parse-error','runtime-error') and not(qt:expected-error)">
			<xsl:attribute name="result" select="'not tested'"/>
			<xsl:attribute name="comment" select="'catalog inconsistent'"/>
		      </xsl:when>

		      <xsl:when test="(@scenario=('parse-error','runtime-error') or qt:expected-error) and not(qt:output-file)">

			<xsl:attribute name="result" select="'fail'"/>
			<xsl:attribute name="comment" select="'no error reported'"/>

			<xsl:message>fail
<!--
			comp-err:<xsl:value-of select="$comp-err"/>
			run-err:<xsl:value-of select="$run-err"/>
			comp:<xsl:value-of select="$comp"/>
			r:<xsl:value-of select="$r"/>
-->
			</xsl:message>

		      </xsl:when>


		      <xsl:when test="qt:output-file">
			<xsl:apply-templates select="qt:output-file[1]">
			  <xsl:with-param name="r" select="$r"/>
			  <xsl:with-param name="xqtest" select="$xqtest"/>
			</xsl:apply-templates>
		      </xsl:when>


		      <xsl:otherwise>
			<xsl:attribute name="comment" select="'not tested (no expected result)'"/>
		      </xsl:otherwise>
		    </xsl:choose>

		  </xsl:otherwise>
		</xsl:choose>

	      </xsl:otherwise>
	    </xsl:choose>

	  </test-case>
	</xsl:for-each>
      </test-suite-result>
    </xsl:result-document>
    <xsl:message>Done!</xsl:message>
  </xsl:template>

  <xsl:function name="xq:comment" as="xs:string">
    <xsl:param name="x"/>
    <xsl:sequence select="if (matches($x[1],'^ *\(:.*:\) *$'))
			  then concat($x[1],'&#10;',xq:comment($x[position()&gt;1]))
			  else ''"/>
  </xsl:function>

  <xsl:template match="*" mode="nspace">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="nspace"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="text()" mode="nspace" priority="2">
    <xsl:text></xsl:text><xsl:value-of select="normalize-space(.)"/>
  </xsl:template>


  <xsl:template match="qt:output-file[@compare=('Fragment','Text')]">
    <xsl:param name="r"/>
    <xsl:param name="xqtest"/>
    <xsl:variable name="er" select="saxon:discard-document(saxon:parse(concat('&lt;x>',
				    replace(unparsed-text(concat(/qt:test-suite/@ResultOffsetPath,../@FilePath,.)),'&lt;\?xml.*?\?&gt;',''),
				    '&lt;/x>')))/x/node()"/>
    <xsl:choose>
      <xsl:when test="deep-equal($r/node(),$er)">
	<xsl:attribute name="result" select="'pass'"/>
<!--	<xsl:attribute name="comment" select="'Fragment ='"/> -->
      </xsl:when>
      <xsl:otherwise>
	<xsl:variable name="rn">
	  <xsl:apply-templates select="$r" mode="nspace"/>
	</xsl:variable>
	<xsl:variable name="ern">
	  <xsl:apply-templates select="$er" mode="nspace"/>
	</xsl:variable>
	<xsl:choose>
	  <xsl:when test="deep-equal(saxon:discard-document($rn),saxon:discard-document($ern))">
	    <xsl:attribute name="result" select="'pass'"/>
	    <xsl:attribute name="comment" select="'Fragment normalize-space ='"/>
<!--
		<xsl:message>fail
1: <xsl:value-of select="deep-equal($r,$r)"/>
2: <xsl:value-of select="deep-equal($r,$er)"/>
5: <xsl:value-of select="count($r),count($er)"/>
2a: <xsl:value-of select="deep-equal($r/node(),$er)"/>
5a: <xsl:value-of select="count($r/node()),count($er)"/>
8: <xsl:value-of select="$r/node()/saxon:type-annotation(.),'|',$er/saxon:type-annotation(.)"/>
4 <xsl:value-of select="'t',$r instance of text(),$er instance of text()"/>
4 <xsl:value-of select="'d',$r instance of document-node(),$er instance of document-node()"/>
3: <xsl:value-of select="$r=$er"/>
</xsl:message>
		<xsl:result-document href="r.xml" indent="no">
		<xsl:copy-of select="$r"/>
		</xsl:result-document>
		<xsl:result-document href="er.xml" indent="no">
		<xsl:copy-of select="$er"/>
		</xsl:result-document>
-->
	  </xsl:when>
	  <xsl:when test="following-sibling::qt:output-file">
	    <xsl:apply-templates select="following-sibling::qt:output-file[1]">
	      <xsl:with-param name="r" select="$r"/>
	      <xsl:with-param name="xqtest" select="$xqtest"/>
	    </xsl:apply-templates>
	  </xsl:when>
	  <xsl:when test="$xqtest/xsl:stylesheet/xsl:import-schema">
	    <xsl:attribute name="result" select="'not applicable'"/>
	    <xsl:attribute name="comment" select="'schema import feature'"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:attribute name="result" select="'fail'"/>
	    <xsl:attribute name="comment" select="'Fragment !='"/>

		<xsl:message>fail</xsl:message>
<!--
		<xsl:result-document href="r.xml" indent="no">
		<xsl:copy-of select="$r"/>
		</xsl:result-document>
		<xsl:result-document href="er.xml" indent="no">
		<xsl:copy-of select="$er"/>
		</xsl:result-document>
		<xsl:result-document href="xqt.xml" indent="no">
		<xsl:copy-of select="$xqtest"/>
		</xsl:result-document>
-->
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="qt:output-file[@compare='!!Text']">
    <xsl:param name="r"/>
    <xsl:param name="xqtest"/>
    <xsl:variable name="er" select="unparsed-text(concat(/qt:test-suite/@ResultOffsetPath,../@FilePath,.))"/>
    <xsl:choose>
      <xsl:when test="$r=$er">
	<xsl:attribute name="result" select="'pass'"/>
	<xsl:attribute name="comment" select="'text ='"/>
      </xsl:when>
      <xsl:when test="normalize-space($r)=normalize-space($er)">
	<xsl:attribute name="result" select="'pass'"/>
	<xsl:attribute name="comment" select="'text normalize-space ='"/>
      </xsl:when>
      <xsl:when test="following-sibling::qt:output-file">
	<xsl:apply-templates select="following-sibling::qt:output-file[1]">
	  <xsl:with-param name="r" select="$r"/>
	  <xsl:with-param name="xqtest" select="$xqtest"/>
	</xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$xqtest/xsl:stylesheet/xsl:import-schema">
	<xsl:attribute name="result" select="'not applicable'"/>
	<xsl:attribute name="comment" select="'schema import feature'"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:attribute name="result" select="'fail'"/>
	<xsl:attribute name="comment" select="'text !='"/>
	<!--
	    <xsl:message>fail</xsl:message>
	    <xsl:result-document href="r.xml" indent="no">
	    <xsl:value-of select="normalize-space($r)"/>
	    </xsl:result-document>
	    <xsl:result-document href="er.xml" indent="no">
	    <xsl:value-of select="normalize-space($er)"/>
	    </xsl:result-document>
	-->
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="qt:output-file[@compare='XML']">
    <xsl:param name="r"/>
    <xsl:param name="xqtest"/>
    <xsl:variable name="er" select="saxon:discard-document(doc(concat(/qt:test-suite/@ResultOffsetPath,../@FilePath,.)))"/>
    <xsl:choose>
      <xsl:when test="deep-equal($r,$er)">
	<xsl:attribute name="result" select="'pass'"/>
<!--	<xsl:attribute name="comment" select="'XML ='"/> -->
      </xsl:when>
      <xsl:otherwise>
	<xsl:variable name="rn">
	  <xsl:apply-templates select="$r" mode="nspace"/>
	</xsl:variable>
	<xsl:variable name="ern">
	  <xsl:apply-templates select="$er" mode="nspace"/>
	</xsl:variable>
	<xsl:choose>
	  <xsl:when test="deep-equal(saxon:discard-document($rn),saxon:discard-document($ern))">
	    <xsl:attribute name="result" select="'pass'"/>
	    <xsl:attribute name="comment" select="'XML normalize-space ='"/>
	  </xsl:when>
	  <xsl:when test="following-sibling::qt:output-file">
	    <xsl:apply-templates select="following-sibling::qt:output-file[1]">
	      <xsl:with-param name="r" select="$r"/>
	      <xsl:with-param name="xqtest" select="$xqtest"/>
	    </xsl:apply-templates>
	  </xsl:when>
	  <xsl:when test="$xqtest/xsl:stylesheet/xsl:import-schema">
	    <xsl:attribute name="result" select="'not applicable'"/>
	    <xsl:attribute name="comment" select="'schema import feature'"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:attribute name="result" select="'fail'"/>
	    <xsl:attribute name="comment" select="'XML !='"/>
	    <!--
		<xsl:message>fail</xsl:message>
		<xsl:result-document href="r.xml" indent="no">
		<xsl:copy-of select="$rn"/>
		</xsl:result-document>
		<xsl:result-document href="er.xml" indent="no">
		<xsl:copy-of select="$ern"/>
		</xsl:result-document>
	    -->
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>



  <xsl:template match="qt:output-file[@compare='Ignore']"/>

  <xsl:template match="qt:output-file[@compare='Inspect']">
	<xsl:attribute name="result" select="'not tested'"/>
	<xsl:attribute name="comment" select="'Inspect'"/>
  </xsl:template>

  <xsl:template match="qt:output-file[@compare='Inspect'][.=('Constr-inscope-1.xml','Constr-inscope-2.xml','Constr-inscope-3.xml','Constr-inscope-4.xml')or starts-with(.,'fn-trace-')or starts-with(.,'fn-current-date') or starts-with(.,'fn-current-time-') or starts-with(.,'fn-implicit-time')]" priority="3">
	<xsl:attribute name="result" select="'pass'"/>
	<xsl:attribute name="comment" select="'Inspect'"/>
  </xsl:template>

  <xsl:variable name="top-matter">
    <implementation name="xq2xsl" version="{format-date(current-date(), '[Y0001][M01][D01]')}" anonymous-result-column="false">
      <organization name="David Carlisle" website="http://monet.nag.co.uk/xq2xml" anonymous="false" />

      <submittor name="David Carlisle" email="davidc@nag.co.uk"/>

      <description>
	<p>xq2xsl Is a convertor from XQuery 1.0 to XSLT 2.0  implemented
        in XSLT 2.0. The xq2xsl conversion, followed by execution of the resulting XSLT stylesheet may be considered as an implementation of Xquery.
For this test XSLT engine used both to execute the conversion and execute the resulting stylesheet was: <xsl:value-of select="$xslt"/>.</p>
      </description>

      <implementation-defined-items>
	<implementation-defined-item name="expressionUnicode" value="As used by Test Applet"/>
	<implementation-defined-item name="collations" value="{$xslt}"/>
	<implementation-defined-item name="implicitTimezone" value="{$xslt}"/>
	<implementation-defined-item name="warningsMethod" value="{$xslt}"/>
	<implementation-defined-item name="errorsMethod" value="{$xslt}"/>
	<implementation-defined-item name="XMLVersion" value="{$xslt}"/>
	<implementation-defined-item name="overwrittenContextComponents" value="{$xslt}"/>
	<implementation-defined-item name="axes" value="all"/>
	<implementation-defined-item name="defaultOrderEmpty" value="empty first"/>
	<implementation-defined-item name="pragmas" value="{$xslt}"/>
	<implementation-defined-item name="optionDeclarations" value="{$xslt}"/>
	<implementation-defined-item name="externalFunctionProtocols" value="{$xslt}"/>
	<implementation-defined-item name="moduleLocationHints" value="{$xslt}"/>
	<implementation-defined-item name="staticTypingExtensions" value="none"/>
	<implementation-defined-item name="serializationInvocation" value="{$xslt}"/>
	<implementation-defined-item name="serializationDefaults" value="{$xslt}"/>
	<implementation-defined-item name="traceDestination" value="{$xslt}"/>
	<implementation-defined-item name="numericOverflow" value="{$xslt}"/>
	<implementation-defined-item name="decimalDigits" value="{$xslt}"/>
	<implementation-defined-item name="roundOrTruncate" value="{$xslt}"/>
	<implementation-defined-item name="Unicode" value="{$xslt}"/>
	<implementation-defined-item name="whitespaceXMLVersion" value="{$xslt}"/>
	<implementation-defined-item name="normalizationForms" value="{$xslt}"/>
	<implementation-defined-item name="collationUnits" value="{$xslt}"/>
	<implementation-defined-item name="secondsDigits" value="{$xslt}"/>
	<implementation-defined-item name="URISchemes" value="{$xslt}"/>
	<implementation-defined-item name="nonXMLMediaTypes" value="{$xslt}"/>
	<implementation-defined-item name="DTDValidation" value="{$xslt}"/>
	<implementation-defined-item name="numericLimits" value="{$xslt}"/>
	<implementation-defined-item name="integerLimits" value="{$xslt}"/>
	<implementation-defined-item name="additionalTypes" value="{$xslt}"/>
	<implementation-defined-item name="leapSecondsPreservation" value="{$xslt}"/>
	<implementation-defined-item name="undefinedProperties" value="{$xslt}"/>
	<implementation-defined-item name="sequenceNormalization" value="{$xslt}"/>
	<implementation-defined-item name="outputMethods" value="{$xslt}"/>
	<implementation-defined-item name="normalizationForms" value="{$xslt}"/>
	<implementation-defined-item name="encodingPhase" value="{$xslt}"/>
	<implementation-defined-item name="CDATASerialization" value="{$xslt}"/>
	
      </implementation-defined-items>
      <features>
	<feature name="Minimum Conformance" supported="true"/>
	<feature name="Schema Import" supported="{'yes'=system-property('xsl:is-schema-aware')}" comment="{$xslt}"/>
	<feature name="Schema Validation" supported="{'yes'=system-property('xsl:is-schema-aware')}" comment="{$xslt}"/>
	<feature name="Static Typing" supported="no"/>
	<feature name="Static Typing Extensions" supported="false"/>
	<feature name="Full Axis" supported="true"/>
	<feature name="Module" supported="true" comment="partial (mapped to xsl:import)"/>
	<feature name="Serialization" supported="true"/>
      </features>
      <context-properties>
	<context-property value="predefined XQuery ones plus 'xsl' bound to the xslt namespace." name="Statically known namespaces" context-type="static"/>
	<context-property name="Default element/type namespace" value="null" context-type="static"/>
	<context-property name="Default function namespace" value="" context-type="static"/>
	<context-property name="In-scope schema types" value="none" context-type="static"/>
	<context-property name="In-scope element declarations" value="none" context-type="static"/>
	<context-property name="In-scope attribute declarations" value="none" context-type="static"/>
	<context-property name="In-scope variables" value="none" context-type="static"/>
	<context-property name="Context item static type" value="xs:integer" context-type="static"/>
	<context-property name="Function signatures" value="XSLT" context-type="static"/>
	<context-property name="Statically known collations" value="{$xslt}" context-type="static"/>
	<context-property name="Default collation" value="Unicode codepoint" context-type="static"/>
	<context-property name="Construction mode" value="" context-type="static"/>
	<context-property name="Ordering mode" value="ordered" context-type="static"/>
	<context-property name="Default order for empty sequences" value="empty first" context-type="static"/>
	<context-property name="Boundary-space policy" value="strip" context-type="static"/>
	<context-property name="Copy-namespaces mode" value="{$xslt}" context-type="static"/>
	<context-property name="Base URI" value="" context-type="static"/>
	<context-property name="Statically known documents" value="{$xslt}" context-type="static"/>
	<context-property name="Statically known collections" value="{$xslt}" context-type="static"/>
	<context-property name="Statically known default collection type" value="{$xslt}" context-type="static"/>
	<context-property name="Context item" value="1" context-type="dynamic"/>
	<context-property name="Context position" value="1" context-type="dynamic"/>
	<context-property name="Context size" value="1" context-type="dynamic"/>
	<context-property name="Variable values" value="" context-type="dynamic"/>
	<context-property name="Function implementations" value="{$xslt}" context-type="dynamic"/>
	<context-property name="Current dateTime" value="{$xslt}" context-type="dynamic"/>
	<context-property name="Implicit timezone" value="{$xslt}" context-type="dynamic"/>
	<context-property name="Available documents" value="{$xslt}" context-type="dynamic"/>
	<context-property name="Available collections" value="{$xslt}" context-type="dynamic"/>
	<context-property name="Default collection" value="{$xslt}" context-type="dynamic"/>
      </context-properties>

    </implementation>
    <syntax>XQueryX</syntax>
    <test-run dateRun="{format-date(current-date(), '[Y0001]-[M01]-[D01]')}">
      <test-suite version="{/*/@version}" />
      <transformation>
	<p>This is a trivial xqueryx implementation, simply prepending a call to the normative xqueryx stylesheet
          onto the test harness used by the xq2xsl XQuery implementation.</p>
      </transformation>
      <comparison>
	<p>XML: The result is not serialised. The expected result is parsed using doc() and compared using deep-equal(), if this fails, text nodes are normalized with normalize-space(), then deep-equal() is retried (Use of normalize-space is noted in the comment field in this case).</p>
	<p>Fragment: The result is not serialised. The expected result is wrapped in an element node so it can be parsed by am XML parser, the child nodes of this element are then compared using deep-equal (and optionaly normalize-space, as for the XML comparision).</p>
        <p>Text: is treated as a synonym for the Fragment comparison</p>
        <p>Inspect: If these have been looked at, they are declared pass, otherwise declared not tested.</p>
         <p>Errors are currently NOT compared. If (any) error is expected, (any) error raised is considered to be a test pass. (Due to limitations of the test harness: This should be fixed in time for a future version of the test suite.)</p>
      </comparison>
      <otherComments>
	<p>The xq2xsl transformation process is designed to only require a basic XSLT2 engine however the generated XSLT code may require a schema-aware XSLT engine to process some constructs. This test uses the same XSLT engine to transform the Query to XSLT and to execute the generated XSLT. The system used was <xsl:value-of select="system-property('xsl:vendor')"/>, for which the value of xsl:is-schema-aware is <xsl:value-of select="system-property('xsl:is-schema-aware')"/>.</p>
      </otherComments>
    </test-run>
  </xsl:variable>

<xsl:variable name="xslt" select="concat('Depends on underlying XSLT engine, in this case: ',system-property('xsl:vendor'))"/>
</xsl:stylesheet>



