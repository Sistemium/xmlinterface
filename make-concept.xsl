<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:dict="dict"
    exclude-result-prefixes="dict"
>

    <xsl:output method="xml" indent="yes" encoding="utf-8"/>  

    <xsl:template match="text()">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>
    
    <dict:term name="datatype" to="type">
        <dict:key name="numeric">decimal</dict:key>
        <dict:key name="number">decimal</dict:key>
        <dict:key name="decimal">decimal</dict:key>
        <dict:key name="varchar">string</dict:key>
        <dict:key name="char">string</dict:key>
        <dict:key name="smalldatetime">datetime</dict:key>
        <dict:key name="timestamp">datetime</dict:key>
        <dict:key name="date">date</dict:key>
        <dict:key name="integer">int</dict:key>
    </dict:term>
    
    <xsl:template match="/metadata/*">
        <concept>
            
            <xsl:copy-of select="@name"/>
            
            <select>
                
                <xsl:copy-of select="@owner"/>
                
                <xsl:attribute name="sql-name">
                    <xsl:value-of select="@name"/>
                </xsl:attribute>
                
                <xsl:if test="self::procedure">
                    <xsl:attribute name="type">procedure</xsl:attribute>
                </xsl:if>
                
                <xsl:apply-templates mode="parameter" select="columns/parameter"/>
                
            </select>
            
            <xsl:apply-templates mode="property" select="columns/result|columns/column"/>
            
        </concept>
    </xsl:template>
    
    <xsl:template mode="translate" match="@*">
        <xsl:for-each select="document('')/*/dict:term[@name=local-name(current())]/*[starts-with(current(),@name)]">
            <xsl:attribute name="{../@to}">
                <xsl:value-of select="."/>
            </xsl:attribute>
        </xsl:for-each>
    </xsl:template>
    
    
    <xsl:template mode="parameter" match="*">
        <xsl:element name="parameter">
            <xsl:attribute name="name">
                <xsl:value-of select="@name"/>
            </xsl:attribute>
            <xsl:apply-templates select="@datatype" mode="translate"/>
            <xsl:attribute name="sql-name">
                <xsl:value-of select="@name"/>
            </xsl:attribute>
        </xsl:element>
    </xsl:template>
    
    
    <xsl:template mode="property" match="*">
        
        <xsl:element name="property">
            
            <xsl:attribute name="name">
                <xsl:value-of select="@name"/>
            </xsl:attribute>
            
            <xsl:apply-templates select="@datatype" mode="translate"/>
            
            <xsl:attribute name="sql-name">
                <xsl:value-of select="@name"/>
            </xsl:attribute>
            
            <xsl:if test="@pkey">
                <xsl:attribute name="key">true</xsl:attribute>
            </xsl:if>
            
        </xsl:element>
        
    </xsl:template>
    
    
</xsl:stylesheet>