<!--
    fullaxis.xsl
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
<xsl:import href="xq2xq.xsl"/>


<xsl:template match="Prolog">
  <xsl:apply-imports/>

declare function local:xq-ancestor($x as node()) as node()* {
 ($x,if ($x/..) then local:xq-ancestor($x/..) else ())
};

</xsl:template>

<xsl:template match="StepExpr[ReverseAxis/data='ancestor']">
local:xq-ancestor(..)[self::<xsl:apply-templates select="NodeTest"/>]
<xsl:apply-templates select="* except (ReverseAxis|NodeTest)"/>
</xsl:template>

<xsl:template match="StepExpr[ReverseAxis/data='ancestor-or-self']">
local:xq-ancestor(.)[self::<xsl:apply-templates select="NodeTest"/>]
<xsl:apply-templates select="* except (ReverseAxis|NodeTest)"/>
</xsl:template>


<xsl:template match="StepExpr[ReverseAxis/data='preceding']">
(let $here := . return
   reverse(root()/descendant::<xsl:apply-templates select="NodeTest"/>[. &lt;&lt; $here][not(descendant::node()[. is $here])]))
<xsl:apply-templates select="* except (ReverseAxis|NodeTest)"/>
</xsl:template>

<xsl:template match="StepExpr[ReverseAxis/data='preceding-sibling']">
(let $here := . return
   reverse(../<xsl:apply-templates select="NodeTest"/>[. &lt;&lt; $here]))
<xsl:apply-templates select="* except (ReverseAxis|NodeTest)"/>
</xsl:template>


<xsl:template match="StepExpr[ReverseAxis/data!='parent'][count(../*)=1]" priority="2">
  <xsl:next-match/><xsl:text>/.</xsl:text>
</xsl:template>

<xsl:template match="StepExpr[ForwardAxis/data='following']">
(let $here := . return
   root()/descendant::<xsl:apply-templates select="NodeTest"/>[. &gt;&gt; $here] except descendant::<xsl:apply-templates select="NodeTest"/>)
<xsl:apply-templates select="* except (ForwardAxis|NodeTest)"/>
</xsl:template>

<xsl:template match="StepExpr[ForwardAxis/data='following-sibling']">
(let $here := . return
   ../<xsl:apply-templates select="NodeTest"/>[. &gt;&gt; $here])
<xsl:apply-templates select="* except (ForwardAxis|NodeTest)"/>
</xsl:template>

</xsl:stylesheet>