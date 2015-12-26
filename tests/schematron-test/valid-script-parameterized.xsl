<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
    xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs	= "http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes = "xs" 
    expand-text             = "yes">
    
    
    <xsl:param name="string"    as="xs:string"/>
    <xsl:param name="integer"   as="xs:integer"/>
    
    <xsl:template match="/">
        
        <p class="- topic/p ">String: {$string}, Integer: {$integer}</p>
        
    </xsl:template>
    
</xsl:stylesheet>