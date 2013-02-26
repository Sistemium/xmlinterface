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
        <xsl:text>revoke connect from </xsl:text>
        <xsl:value-of select="concat(@name,';',xi:crlf())"/>
        <xsl:text>grant connect to </xsl:text>
        <xsl:value-of select="concat(@name,';',xi:crlf(2))"/>
        <xsl:apply-templates mode="sql-ddl" select="*"/>
    </xsl:template>
    
    
    <xsl:template match="*" mode="sql-ddl">
        <xsl:apply-templates mode="sql-ddl" select="*"/>
    </xsl:template>
    
    
    <xsl:template match="xi:table" mode="sql-ddl">
        
        <xsl:text>create table </xsl:text>
        <xsl:value-of select="concat( ../@name, '.', @name, ' (', xi:crlf() )"/>
        
        <xsl:for-each select="*">
            <xsl:if test="not(preceding-sibling::*[1][name()=name(current())])">
                <xsl:value-of select="xi:crlf()"/>
            </xsl:if>
            <xsl:value-of select="xi:padtab()"/>
            <xsl:if test="position() &gt; 1"><xsl:text>, </xsl:text></xsl:if>
            <xsl:apply-templates mode="sql-ddl" select="."/>
            <xsl:value-of select="xi:crlf()"/>
        </xsl:for-each>
        
        <xsl:text>);</xsl:text>
        <xsl:value-of select="xi:crlf(2)"/>
        
    </xsl:template>
    
    
    <xsl:template match="xi:primary-key|xi:unique" mode="sql-ddl">
        
        <xsl:variable name="extra" select="../xi:foreign-key[@name=current()/xi:part/@name]"/>
        
        <xsl:for-each select="$extra">
            <xsl:if test="position() &gt; 1">
                <xsl:text>, </xsl:text>
            </xsl:if>
            <xsl:value-of select="concat( @name, ' IDREF' )"/>
        </xsl:for-each>
        
        <xsl:if test="$extra">
            <xsl:value-of select="concat( xi:crlf(), xi:padtab(), ', ' )"/>
        </xsl:if>
        
        <xsl:value-of select="translate(local-name(),'-',' ')"/>
        <xsl:text> ( </xsl:text>
        <xsl:value-of select="xi:list(xi:part/@name)"/>
        <xsl:if test="not(xi:part)">
            <xsl:text>xid</xsl:text>
        </xsl:if>
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
        <xsl:value-of select="concat( '[',@name,']', '  ', @datatype)"/>
    </xsl:template>
    
    
</xsl:stylesheet>