<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
    xmlns="http://unact.net/xml/xi"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns:e="http://exslt.org/common"
    exclude-result-prefixes="e"
    extension-element-prefixes="e"
>
    
    <xsl:output method="xml" indent="no" encoding="utf-8"/>
    
    
    <xsl:param name="model"/>
    <xsl:param name="export-server"/>
    
    <xsl:template match="/">
        <xsl:apply-templates select="$model"/>
    </xsl:template>
    
    <xsl:template match="*" mode="export">
        
        <xsl:text>
</xsl:text>
        
        <xsl:for-each select="ancestor::*">
            <xsl:value-of select="'    '"/>
        </xsl:for-each>
        
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="*" mode="export"/>
        </xsl:copy>
        
        <xsl:text>
</xsl:text>
        
        <xsl:for-each select="ancestor::*">
            <xsl:text>    </xsl:text>
        </xsl:for-each>
        
    </xsl:template>
    
    <xsl:template match="xi:domain">
        
        <xsl:variable name="export" select="xi:concept[@server='op.unact.ru']"/>
        
        <xsl:document href="data/op.unact.ru.domain.xml"
                      encoding="utf-8" method="xml" indent="no">
            <xsl:copy>
                <xsl:apply-templates select="$export" mode="export"/>
            </xsl:copy>
        </xsl:document>
        
        <xsl:copy>
            <domain>
                <xsl:apply-templates select="*[not(@name=$export/@name)]"/>
            </domain>
        </xsl:copy>
        
    </xsl:template>
    
    
    <!--xsl:template match="*[@export-this]">
        <e:document href="{@export-this}.xml">
            <xsl:copy-of select="."/>
        </e:document>
    </xsl:template-->
    
    
    <xsl:template match="xi:views//xi:menu">
        <xsl:copy>
            <xsl:copy-of select="ancestor::xi:views[1]/@name|@*"/>
            <xsl:copy-of select="ancestor::xi:views/xi:access"/>
            <xsl:copy-of select="*"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="xi:secure">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>
