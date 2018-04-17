<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema"
	xmlns:ds	= "http://www.dita-semia.org"
	xmlns:cba	= "http://www.dita-semia.org/conbat"
	exclude-result-prefixes		= "#all">
	
	
	<xsl:variable name="NEWLINE" as="xs:string" select="'&#x0A;'"/>
	
	<xsl:function name="ds:extractText" as="xs:string?">
		<xsl:param name="node" as="node()?"/>
		
		<xsl:variable name="text" as="xs:string*">
			<xsl:apply-templates select="$node" mode="ExtractText"/>
		</xsl:variable>
		<xsl:sequence select="string-join($text, '')"/>
	</xsl:function>


	<!-- @cba:hide-empty -->
	<xsl:template match="*[xs:boolean(@cba:hide-empty)][empty(node())]" priority="9" mode="ExtractText">
		<!-- remove -->
	</xsl:template>

	<!-- paragraph-prefix -->
	<xsl:template match="*[@cba:prefix][contains(@class, $C_UL) or contains(@class, $C_OL) or contains(@class, $C_SL) or contains(@class, $C_CODEBLOCK)]" priority="8" mode="ExtractText">
		<xsl:sequence select="ds:resolveEmbeddedXPath(@cba:prefix, .)"/>
		<xsl:sequence select="$NEWLINE"/>
		<xsl:next-match/>
	</xsl:template>
	
	<!-- paragraph-suffix -->
	<xsl:template match="*[@cba:suffix][contains(@class, $C_UL) or contains(@class, $C_OL) or contains(@class, $C_SL)]" priority="7" mode="ExtractText">
		<xsl:next-match/>
		<xsl:sequence select="$NEWLINE"/>
		<xsl:sequence select="ds:resolveEmbeddedXPath(@cba:suffix, .)"/>
	</xsl:template>
	
	
	<!-- title -->
	<xsl:template match="*[@cba:title]" priority="6" mode="ExtractText">
		<xsl:sequence select="ds:resolveEmbeddedXPath(@cba:title, .)"/>
		<xsl:sequence select="$NEWLINE"/>
		<xsl:next-match/>
	</xsl:template>

	<!-- dd-term -->
	<xsl:template match="*[@cba:dt][contains(@class, $C_DD)]" priority="6" mode="ExtractText">
		<xsl:sequence select="ds:resolveEmbeddedXPath(@cba:dt, .)"/>
		<xsl:sequence select="$NEWLINE"/>
		<xsl:next-match/>
	</xsl:template>
	
	
	<!-- inline-content -->
	<xsl:template match="*[contains(@class, $C_P) or 
							contains(@class, $C_PH) or 
							contains(@class, $C_SLI) or 
							contains(@class, $C_STENTRY) or 
							contains(@class, $C_TITLE) or
							contains(@class, $C_CODEPH) or
							contains(@class, $C_DD)]" priority="5" mode="ExtractText">
		<xsl:call-template name="insert-csli-prefix"/>
		<xsl:sequence select="ds:getCbaText(@cba:prefix)"/>
		<xsl:sequence select="ds:getCbaText(@cba:content)"/>
		<xsl:choose>
			<xsl:when test="empty(node())">
				<xsl:sequence select="ds:getCbaText(@cba:default-content)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="node()" mode="#current"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:sequence select="ds:getCbaText(@cba:suffix)"/>
	</xsl:template>
	

	<!-- table-header -->
	<xsl:template match="*[@cba:header][contains(@class, $C_TGROUP)]" priority="5" mode="ExtractText">
		<!-- not handled yet -->
	</xsl:template>
	
	
	<!-- simpletable-header -->
	<xsl:template match="*[@cba:header][contains(@class, $C_SIMPLETABLE)]" priority="5" mode="ExtractText">
		<!-- not handled yet -->
	</xsl:template>


	<!-- remove whitespaces next to content generated by attributes -->
	<xsl:template match="text()[matches(., '^\s+$')]" mode="ExtractText">
		<xsl:choose>
			<xsl:when test="empty(preceding-sibling::node()) and exists(parent::*/@cba:prefix)">
				<!-- first node within an element with a prefix -->
			</xsl:when>
			<xsl:when test="exists(preceding-sibling::node()[1]/@cba:suffix)">
				<!-- following node of an element with a suffix --> 
			</xsl:when>
			<xsl:when test="(tokenize(preceding-sibling::node()[1]/@cba:flags, '\s+') = $CBA_FLAG_CSLI) and
				(tokenize(following-sibling::node()[1]/@cba:flags, '\s+') = $CBA_FLAG_CSLI)">
				<!-- node between two csli elements --> 
			</xsl:when>
			<xsl:when test="exists(following-sibling::node()[1]/@cba:prefix)">
				<!-- preceding node of an element with a prefix -->
			</xsl:when>
			<xsl:when test="empty(following-sibling::node()) and exists(parent::*/@cba:suffix)">
				<!-- last node within an element with a suffix -->
			</xsl:when>
			<xsl:otherwise>
				<xsl:next-match/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<!-- @cba:o-class = "csli" (comma seperated list item) -->
	<xsl:template name="insert-csli-prefix">
		<xsl:variable name="pre" as="node()?" select="preceding-sibling::node()[not(self::text()[matches(., '^\s+$')])][1]"/>
		<xsl:if test="(tokenize(@cba:o-class, '\s+') = $CBA_FLAG_CSLI) and (tokenize($pre/@cba:flags, '\s+') = $CBA_FLAG_CSLI)">
			<xsl:text>, </xsl:text>
		</xsl:if>
	</xsl:template>
	

	<xsl:function name="ds:getCbaText">
		<xsl:param name="attribute" as="attribute()?"/>
		
		<xsl:if test="exists($attribute)">
			<xsl:sequence select="ds:resolveEmbeddedXPath($attribute, $attribute/parent::*)"/>
		</xsl:if>
	</xsl:function>

</xsl:stylesheet>
