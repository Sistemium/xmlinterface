<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:dict="dict"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns="http://unact.net/xml/xi"
    exclude-result-prefixes="dict"
>

    <xsl:output method="xml" indent="no" encoding="utf-8"/>
    
    <xsl:param name="domain-name">iorders-demo</xsl:param>
    <xsl:param name="domain" select="document('../domain.xml')/*|document(concat('../domain/',$domain-name,'.xml'))/*"/>
    
    <xsl:include href="../id.xsl"/>
    
    <xsl:template match="
        @concept | @sql-compute
        | xi:field [xi:sql-compute] /node()
        | comment()
    "/>
    
    <xsl:template match="xi:form|xi:join">
        <xsl:choose>
            <xsl:when test="not($domain/xi:concept/@name = @name)">
                <xsl:apply-templates select="xi:form"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="id"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="xi:where|xi:order-by">
        <xsl:choose>
            <xsl:when test="not($domain/xi:concept[@name = current()/../@name]/*[@name = current()/@name])">
                <xsl:apply-templates select="xi:form"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="id"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="xi:field/@alias">
        <xsl:attribute name="name">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>
    
</xsl:stylesheet>