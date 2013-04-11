<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xi="http://unact.net/xml/xi"
>

    <xsl:template match="xi:after|xi:before|xi:insert|xi:update|xi:delete" mode="sql-trigger-name">
        <xsl:value-of select="xi:upper(substring(local-name(),1,1))"/>
        <xsl:apply-templates mode="sql-trigger-name" select="*"/>
    </xsl:template>
    
    <xsl:template match="node()" mode="sql-name"/>
    <xsl:template match="node()" mode="sql-trigger-name"/>
    <xsl:template match="*" mode="sql-trigger-action"/>
    
    <xsl:template match="xi:after|xi:before|xi:insert|xi:update|xi:delete" mode="sql-trigger-action">
        
        <xsl:if test="(parent::xi:before or parent::xi:after)">
            <xsl:if test="preceding-sibling::*">
                <xsl:text>,</xsl:text>
            </xsl:if>
            <xsl:text> </xsl:text>
        </xsl:if>
        
        <xsl:value-of select="local-name()"/>
        <xsl:apply-templates mode="sql-trigger-action" select="*"/>
        
    </xsl:template>
    
    <xsl:template match="xi:trigger" mode="sql-name">
        <xsl:text>t</xsl:text>
        <xsl:apply-templates mode="sql-trigger-name" select="*"/>
        <xsl:text>_</xsl:text>
        <xsl:value-of select="../@name"/>
    </xsl:template>
    
    
    <xsl:template match="*" mode="sql-ddl-triggers">
        <xsl:apply-templates select="*" mode="sql-ddl-triggers"/>
    </xsl:template>
    
    
    <xsl:template match="xi:trigger" mode="sql-ddl-triggers">
        
        <xsl:text>create or replace trigger </xsl:text>
        <xsl:apply-templates select="." mode="sql-name"/>
        
        <xsl:value-of select="xi:crlf()"/>
        <xsl:value-of select="xi:padtab()"/>
        
        <xsl:apply-templates select="*" mode="sql-trigger-action"/>
        <xsl:text> on </xsl:text>
        <xsl:value-of select="concat(parent::xi:table/parent::*/@name, '.', parent::xi:table/@name)"/>
        
        <xsl:value-of select="xi:crlf()"/>
        <xsl:value-of select="xi:padtab()"/>
        
        <xsl:text>referencing new as inserted old as deleted</xsl:text>
        
        <xsl:value-of select="xi:crlf()"/>
        <xsl:value-of select="xi:padtab()"/>
        
        <xsl:text>for each row</xsl:text>
        
        <xsl:value-of select="xi:crlf()"/>
        
        <xsl:text>begin</xsl:text>
        <xsl:value-of select="xi:crlf()"/>
        <xsl:apply-templates select="*" mode="sql-ddl-triggers"/>
        <xsl:value-of select="xi:crlf()"/>
        <xsl:text>end;</xsl:text>
        
        <xsl:value-of select="xi:crlf(2)"/>
        
    </xsl:template>
    

    <xsl:template match="text()" mode="sql-ddl-triggers"/>
    
    
    <xsl:template match="xi:sql" mode="sql-ddl-triggers">
        <xsl:param name="cnt" select="count(ancestor-or-self::xi:sql)"/>
        <xsl:value-of select="xi:crlf(1)"/>
        <xsl:value-of select="xi:padtab($cnt)"/>
        <xsl:apply-templates select="node()" mode="sql-ddl-triggers"/>
        <xsl:value-of select="xi:crlf(1)"/>
    </xsl:template>
    
    
    <xsl:template match="xi:sql/text()" mode="sql-ddl-triggers">
        
        <xsl:if test="preceding-sibling::xi:sql">
            <xsl:value-of select="xi:crlf(1)"/>
        </xsl:if>
        
        <xsl:variable name="cnt" select="count(preceding-sibling::xi:sql/ancestor::xi:sql)"/>        
        <xsl:value-of select="xi:padtab($cnt)"/>
        <xsl:value-of select="normalize-space(.)"/>
        
        <xsl:if test="following-sibling::xi:sql">
            <xsl:value-of select="xi:crlf(1)"/>
        </xsl:if>
        
    </xsl:template>
    
    
</xsl:stylesheet>