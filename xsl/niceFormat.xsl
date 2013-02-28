<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xi="http://unact.net/xml/xi"
>

    <xsl:output method="xml" indent="no" encoding="utf-8"/>  
    <xsl:include href="../functions.xsl"/>
    
    
    <xsl:template match="text()">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>

    <xsl:template match="xi:sql/text()">
        <xsl:copy/>
    </xsl:template>
    
    <xsl:template match="node()">
        
        <xsl:variable name="cnt" select="count(ancestor::*)"/>
        
        <xsl:if test="self::*">
            <xsl:if test="not(preceding-sibling::*[1][name()=name(current())]) or *"><xsl:text>
</xsl:text>
                <xsl:value-of select="xi:padtab($cnt)"/>
            </xsl:if>
            <xsl:if test="not(*) and preceding-sibling::*[1][name()=name(current())]">
                <xsl:value-of select="xi:padtab()"/>
            </xsl:if>
        </xsl:if>
        
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
        
        <xsl:if test="self::*">
            <xsl:text>
</xsl:text>
            <xsl:value-of select="xi:padtab($cnt - 1)"/>
            <xsl:if test="following-sibling::*[1][not(name()=name(current()))]">
                <xsl:value-of select="xi:padtab()"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
    
</xsl:stylesheet>
