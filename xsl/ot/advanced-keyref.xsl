<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema"
	xmlns:jt 	= "http://saxon.sf.net/java-type"
	xmlns:ds	= "http://www.dita-semia.org"
	xmlns:ikd	= "http://www.dita-semia.org/implicit-keydef"
	xmlns:akr	= "http://www.dita-semia.org/advanced-keyref"
	exclude-result-prefixes		= "#all">
	
	<xsl:variable name="OUTPUTCLASS_KEY"				as="xs:string"	select="'key'"/>
	<xsl:variable name="OUTPUTCLASS_KEY_NAME_BRACED"	as="xs:string"	select="'key-name-braced'"/>
	<xsl:variable name="OUTPUTCLASS_KEY_NAME_DASHED"	as="xs:string"	select="'key-name-dashed'"/>
	<xsl:variable name="OUTPUTCLASS_NAME"				as="xs:string"	select="'name'"/>
	
	
	<!-- do NOT match the element itself or whitespace text to avoid conflicts with conbat-templates -->
	<xsl:template match="*[@akr:ref][count(node()) = 1]/text()[not(matches(., '^\s+$'))]">
		<xsl:call-template name="CreateKeyRefContent">
			<xsl:with-param name="keyRef"	select="parent::*"/>
			<xsl:with-param name="content"	select="."/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template name="CreateKeyRefContent">
		<xsl:param name="keyRef"	as="element()"/>
		<xsl:param name="content"	as="node()*"/>

		<xsl:choose>
			<xsl:when test="$keyRef/@akr:ref">
				<xsl:variable name="outputclass"	as="xs:string?"										select="replace($keyRef/@outputclass, '!$', '')"/>
				<xsl:variable name="jKeyDef"		as="jt:org.DitaSemia.Base.AdvancedKeyref.KeyDef?" 	select="akr:getReferencedKeyDef($keyRef)"/>
				<xsl:variable name="href"			as="xs:string?" 									select="if (exists($jKeyDef)) then akr:getKeyDefLocation($jKeyDef) else ()"/>
				
				<xsl:variable name="displaySuffix" 	as="xs:string*" select="akr:getKeyRefDisplaySuffix($keyRef, $jKeyDef)"/>
				<xsl:variable name="isKeyFiltered" 	as="xs:boolean" select="ikd:getIsFilteredKey($jKeyDef)"/>
				<xsl:variable name="isKeyHidden" 	as="xs:boolean" select="ikd:getIsKeyHidden($jKeyDef)"/>
				
				<!--<xsl:message>ref: <xsl:value-of select="@akr:ref"/>, isKeyFiltered: <xsl:value-of select="$isKeyFiltered"/><!-\-, isKeyHidden: <xsl:value-of select="$isKeyHidden"/>-\-></xsl:message>-->

				<xsl:variable name="refContent" as="node()*">
					<xsl:choose>
						<xsl:when test="($outputclass = $OUTPUTCLASS_NAME) or ($isKeyHidden)">
							<!-- no key to be displayed -->
						</xsl:when>
						<xsl:otherwise>
							<xsl:variable name="keyContent" as="node()*">
								<xsl:call-template name="KeyFormatting">
									<xsl:with-param name="keyNode" select="$keyRef"/>
									<xsl:with-param name="content" select="$content"/>
								</xsl:call-template>
								<xsl:value-of select="$displaySuffix[1]"/>
							</xsl:variable>
							<xsl:choose>
								<xsl:when test="$isKeyFiltered">
									<ph class="{$CP_PH}">
										<xsl:variable name="attrContainer" as="element()?" select="ikd:getKeyFilterAttr($jKeyDef)"/>
										<xsl:message>attrContainer: <xsl:copy-of select="$attrContainer"/></xsl:message>
										<xsl:copy-of select="$attrContainer/attribute()"/>
										<xsl:sequence select="$keyContent"/>
									</ph>
								</xsl:when>
								<xsl:otherwise>
									<xsl:sequence select="$keyContent"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:if test="$outputclass != $OUTPUTCLASS_KEY">
						<xsl:value-of select="$displaySuffix[2]"/>
						<xsl:if test="empty($displaySuffix) and ($outputclass = $OUTPUTCLASS_NAME)">
							<xsl:text>&#xA0;</xsl:text>	<!-- insert some text to avoid generated content from link target -->
						</xsl:if>
					</xsl:if>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="exists($href)">
						<xref class="{$CP_XREF}" format="dita" outputclass="advanced-keyref" href="{$href}">
							<xsl:sequence select="$refContent"/>
						</xref>
					</xsl:when>
					<xsl:otherwise>
						<xsl:sequence select="$refContent"/>
						<xsl:if test="empty($jKeyDef)">
							<xsl:variable name="file"	as="xs:string?" select="$keyRef/@xtrf"/>
							<xsl:variable name="pos"	as="xs:string?" select="substring-after($keyRef/@xtrc, ';')"/>
							<xsl:message><xsl:value-of select="concat($file, ':', $pos)"/>: [DOTX][WARN]: Failed to resolve advanced-keyref to xref (<xsl:value-of select="$keyRef/@akr:ref"/>).</xsl:message>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="$content"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- do NOT match the element itself or whitespace text to avoid conflicts with conbat-templates -->
	<xsl:template match="*[@ikd:key-type][count(node()) = 1]/text()[not(matches(., '^\s+$'))]">
		<xsl:call-template name="KeyFormatting">
			<xsl:with-param name="keyNode" select="parent::*"/>
			<xsl:with-param name="content" select="."/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="@akr:* | @ikd:*">
		<!-- remove these attributes -->
	</xsl:template>
	
	
	<xsl:template name="KeyFormatting">
		<xsl:param name="keyNode" as="element()"/>
		<xsl:param name="content" as="node()?"/>
		
		<xsl:choose>
			<xsl:when test="$keyNode/(@ikd:key-type | @akr:ref)">
				<xsl:variable name="keyTypeDef"		as="element()" select="akr:getKeyTypeDef($keyNode)"/>
				<xsl:variable name="keyContent" as="node()*">
					<xsl:value-of select="$keyTypeDef/@prefix"/>
					<xsl:copy-of select="$content"/>
					<xsl:value-of select="$keyTypeDef/@suffix"/>
				</xsl:variable>
				<xsl:variable name="italicWrapper" as="node()*">
					<xsl:choose>
						<xsl:when test="xs:boolean($keyTypeDef/@isItalicFont)">
							<i class="{$CP_I}">
								<xsl:sequence select="$keyContent"/>
							</i>
						</xsl:when>
						<xsl:otherwise>
							<xsl:sequence select="$keyContent"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="xs:boolean($keyTypeDef/@isCodeFont)">
						<codeph class="{$CP_CODEPH}">
							<xsl:sequence select="$italicWrapper"/>
						</codeph>
					</xsl:when>
					<xsl:otherwise>
						<xsl:sequence select="$italicWrapper"/>
					</xsl:otherwise>
				</xsl:choose>	
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="$content"/>
			</xsl:otherwise>
		</xsl:choose>	
	</xsl:template>
	
</xsl:stylesheet>
