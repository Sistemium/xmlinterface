<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:dict="dict"
    exclude-result-prefixes="dict"
>

    <xsl:output method="text" encoding="utf-8"/>  

    <xsl:template match="*">
        <xsl:apply-templates/>
    </xsl:template>
    
    
    <xsl:template match="table">
        
        <xsl:text>create or replace view </xsl:text> <xsl:value-of select="@name"/>
        
        <xsl:text>&#xD;&#xA;</xsl:text>
        
        <xsl:text>as select&#xD;&#xA;</xsl:text>
        
        <xsl:for-each select="columns/column">
            
            <xsl:text>    </xsl:text>
            <xsl:if test="position() &gt; 1">
                <xsl:text>, </xsl:text>
            </xsl:if>
            
            <xsl:value-of select="@name"/>
            <xsl:text>&#xD;&#xA;</xsl:text>
            
        </xsl:for-each>
        
        <xsl:text>from </xsl:text>
        <xsl:value-of select="@fullname"/>
        <xsl:text>&#xD;&#xA;</xsl:text>
        
    </xsl:template>
    
    
</xsl:stylesheet>