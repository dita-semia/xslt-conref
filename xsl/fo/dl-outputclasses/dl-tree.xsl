<?xml version='1.0' encoding='utf-8'?>
<xsl:stylesheet version="2.0"
	xmlns:xs				= "http://www.w3.org/2001/XMLSchema" 
	xmlns:xsl				= "http://www.w3.org/1999/XSL/Transform" 
	xmlns:fo				= "http://www.w3.org/1999/XSL/Format"
	xmlns:ds				= "http://www.dita-semia.org"
	exclude-result-prefixes	= "#all">
	
	
	<xsl:variable name="DL_OUTPUTCLASS_TREE" 		as="xs:string">tree</xsl:variable>
	<xsl:variable name="DL_OUTPUTCLASS_DT_WIDTH" 	as="xs:string">^dt-([0-9]+)$</xsl:variable>
	
	<xsl:variable name="PAGE_WIDTH" 				as="xs:string">165mm</xsl:variable>
	<xsl:variable name="DEFAULT_TREE_DT_WIDTH" 		as="xs:integer" select="40"/>
	
	
	<xsl:template match="*[contains(@class, ' topic/dl ')][tokenize(@outputclass, '\s+') = $DL_OUTPUTCLASS_TREE]">
		<fo:block xsl:use-attribute-sets="ds:dl-tree">
			
			<xsl:call-template name="commonattributes"/>
			
			<xsl:variable name="dt-width-attr"	as="xs:string?" 	select="tokenize(@outputclass, '\s+')[matches(., $DL_OUTPUTCLASS_DT_WIDTH)]"/>
			<xsl:variable name="dt-width" 		as="xs:integer?"	select="if ($dt-width-attr) then xs:integer(replace($dt-width-attr, $DL_OUTPUTCLASS_DT_WIDTH, '$1')) else $DEFAULT_TREE_DT_WIDTH"/>
			
			<xsl:apply-templates mode="dl-tree">
				<xsl:with-param name="dt-width" select="$dt-width" tunnel="yes"/>
			</xsl:apply-templates>
			
		</fo:block>
	</xsl:template>
	
	
	<xsl:template match="*[contains(@class, ' topic/dlentry ')]" mode="dl-tree">
		<xsl:param name="dt-width" as="xs:integer" tunnel="yes"/>
		
		<xsl:variable name="allEntries"			as="element()*"	select="ancestor::*[contains(@class, ' topic/dl ')]//*[contains(@class, ' topic/dlentry ')]"/>
		<xsl:variable name="countPreEntries"	as="xs:integer"	select="count($allEntries intersect (preceding::* | ancestor::*))"/>
		<xsl:variable name="countPostEntries"	as="xs:integer"	select="count($allEntries intersect (following::*))"/>
		<xsl:variable name="level" 				as="xs:integer" select="count(ancestor::*[contains(@class, ' topic/dlentry ')]) + 1"/>
		
		<!--<xsl:message>Name: '<xsl:value-of select="Name"/>', vor: <xsl:value-of select="$ElementeVor"/>, nach: <xsl:value-of select="$ElementeNach"/></xsl:message>-->
		
		<fo:block xsl:use-attribute-sets="ds:dlentry-tree">
			
			<xsl:copy-of select="@id"/>	<!-- explicitly copy it since for fop it is suppressed of dlentry -->
			
			<xsl:call-template name="commonattributes"/>
			
			<xsl:if test="not(contains(parent::*/@class, ' topic/dl '))">
				<xsl:if test="exists(preceding-sibling::*)">
					<xsl:attribute name="border-top-style" select="'solid'"/>
				</xsl:if>
				<xsl:attribute name="margin-left" 		select="$DL_TREE_INDENT"/>
				<xsl:attribute name="border-left-style" select="'solid'"/>
			</xsl:if>

			<xsl:if test="($DL_TREE_WIDOWS > $countPreEntries)">
				<xsl:attribute name="keep-with-previous.within-column" select="100"/>
			</xsl:if>
			<xsl:if test="($DL_TREE_ORPHANS > $countPostEntries) and ($countPostEntries > 0)">
				<xsl:attribute name="keep-with-next.within-column" select="100"/>
			</xsl:if>
			
			<xsl:choose>
				<xsl:when test="exists(*[contains(@class, ' topic/dd ')]/node())">

					<!-- formatting as table -->
					<fo:table table-layout="fixed" width="100%">
						
						<fo:table-column column-number="1" column-width="({$PAGE_WIDTH} * {$dt-width} div 100) - ({$level} * ({$DL_TREE_INDENT} + {$DL_TREE_BORDER_WIDTH}))"/>
						<fo:table-column column-number="2" column-width="({$PAGE_WIDTH} * (100 - {$dt-width}) div 100)"/>
						
						<fo:table-body>
							<fo:table-row keep-together.within-column	= "100">
								
								<fo:table-cell margin-left = "0" xsl:use-attribute-sets="ds:dl-tree-cell"> 
									<!-- margin-left muss explizit auf 0 gesetzt werden, da es sich anderenfalls aufsummiert -->
									<xsl:apply-templates select="*[contains(@class, ' topic/dt ')]" mode="#current"/>
								</fo:table-cell>
								<fo:table-cell margin-left="0" padding-right="1.5mm" xsl:use-attribute-sets="ds:dl-tree-cell">									
									<!-- margin-left muss explizit auf 0 gesetzt werden, da es sich anderenfalls aufsummiert -->
									<xsl:apply-templates select="*[contains(@class, ' topic/dd ')]" mode="#current"/>
								</fo:table-cell>
							</fo:table-row>
						</fo:table-body>
					</fo:table>
					<xsl:apply-templates select="*[contains(@class, ' topic/dlentry ')]" mode="#current"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="*[contains(@class, ' topic/dt ') or contains(@class, ' topic/dlentry ')]" mode="#current"/>
				</xsl:otherwise>
			</xsl:choose>
			
		</fo:block>
		
	</xsl:template>
	
	
	<xsl:template match="*[contains(@class, ' topic/dt ')]" mode="dl-tree">
		
		<fo:block xsl:use-attribute-sets="ds:dt-tree">
			<xsl:if test="exists(following-sibling::*)">
				<xsl:attribute name="keep-with-next.within-column">100</xsl:attribute>
			</xsl:if>
			
			<xsl:call-template name="commonattributes"/>
			
			<xsl:apply-templates mode="#default"/>
			
		</fo:block>
		
	</xsl:template>
	
	
	<xsl:template match="*[contains(@class, ' topic/dd ')]" mode="dl-tree">
		
		<fo:block xsl:use-attribute-sets="ds:dd-tree">
			
			<xsl:call-template name="commonattributes"/>
			
			<xsl:apply-templates mode="#default"/>
			
		</fo:block>
		
	</xsl:template>

</xsl:stylesheet>
