<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:dict="dict"
    xmlns:xi="http://unact.net/xml/xi"
    exclude-result-prefixes="dict"
>

    <xsl:output method="text" encoding="utf-8"/>
    
    <xsl:include href="../functions.xsl"/>
    
    
    <xsl:template match="/xi:DDL">
        <xsl:apply-templates mode="sql-ddl" select="*"/>
    </xsl:template>
    
    
    <xsl:template match="*" mode="sql-ddl">
        <xsl:apply-templates mode="sql-ddl" select="*"/>
    </xsl:template>
    
    
    <xsl:template match="xi:table" mode="sql-ddl">
        <xsl:text>create table </xsl:text>
        <xsl:value-of select="concat( ../@name, '.', @name, ' (', xi:crlf() )"/>
        <xsl:for-each select="*">
            <xsl:value-of select="xi:padtab()"/>
            <xsl:if test="position() &gt; 1"><xsl:text>, </xsl:text></xsl:if>
            <xsl:apply-templates mode="sql-ddl" select="."/>
            <xsl:value-of select="xi:crlf()"/>
        </xsl:for-each>
        <xsl:text>);</xsl:text>
        <xsl:value-of select="xi:crlf()"/>
        <xsl:value-of select="xi:crlf()"/>
    </xsl:template>
    
    
    <xsl:template match="xi:primary-key" mode="sql-ddl">
        <xsl:text>primary key ( </xsl:text>
        <xsl:value-of select="xi:list(xi:part/@name)"/>
        <xsl:text> )</xsl:text>
    </xsl:template>
    
    
    <xsl:template match="xi:foreign-key" mode="sql-ddl">
        <xsl:text>foreign key ( </xsl:text>
        <xsl:value-of select="@name"/>
        <xsl:text> )</xsl:text>
        <xsl:text> references </xsl:text>
        <xsl:value-of select="concat(parent::xi:table/parent::*/@name, '.', @parent)"/>
    </xsl:template>
    
    
    <xsl:template match="xi:column" mode="sql-ddl">
        <xsl:value-of select="concat(@name, ' ', @datatype)"/>
    </xsl:template>
    
    
</xsl:stylesheet>