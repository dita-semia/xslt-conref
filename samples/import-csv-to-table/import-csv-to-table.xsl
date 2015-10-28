<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema"
	xmlns:ds	= "http://www.dita-semia.org"
    exclude-result-prefixes	= "#all"
	expand-text				= "yes">
	
	<xsl:include href="../../xsl/csv-to-xml.xsl"/>
	<xsl:include href="../../xsl/class.xsl"/>
	
	<xsl:output method="xml" indent="yes"/>
	
    <xsl:template match="/">
    	
    	<xsl:variable name="csvCode" 	as="xs:string" 	select="unparsed-text(resolve-uri('Data.csv'))"/>
    	<xsl:variable name="rowList" 	as="element()+" select="ds:csvToXml($csvCode)"/>
    	<xsl:variable name="colCount" 	as="xs:integer" select="max(for $i in $rowList return count($i/*))"/>
    	
    	
    	<xsl:processing-instruction name="xml-model">href="urn:dita-ng:dita:rng:topic.rng" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:processing-instruction>

        <simpletable relcolwidth="{for $i in 1 to $colCount return '1.0*'}">
        	<xsl:for-each select="$rowList">
        		<xsl:variable name="colList" as="element()*" select="*"/>
        		<xsl:element name="{if (position() = 1) then 'sthead' else 'strow'}">
        			<xsl:for-each select="1 to $colCount">
        				<xsl:variable name="colIndex" as="xs:integer" select="."/>
        				<stentry>
        					<xsl:value-of select="$colList[$colIndex]"/>
        				</stentry>
        			</xsl:for-each>
        		</xsl:element>
        	</xsl:for-each>
        </simpletable>
    </xsl:template>
	
	
</xsl:stylesheet>