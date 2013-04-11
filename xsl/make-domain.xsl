<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:dict="dict"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns="http://unact.net/xml/xi"
    exclude-result-prefixes="dict"
>

    <xsl:output method="xml" indent="no" encoding="utf-8"/>
    
    <xsl:template match="/xi:metadata">
        <domain server="demo">
            <xsl:apply-templates mode="domain-metadata" select="xi:tables"/>
        </domain>
    </xsl:template>
    
    
    <dict:term name="type" to="type">
        <dict:key name="float">decimal</dict:key>
        <dict:key name="boolean">boolean</dict:key>
        <dict:key name="string">string</dict:key>
        <dict:key name="date">date</dict:key>
        <dict:key name="datetime">datetime</dict:key>
        <dict:key name="int">int</dict:key>
    </dict:term>
    
    
    <xsl:template mode="sql-translate" match="@*">
        <xsl:for-each select="document('')/*/dict:term[@name=local-name(current())]/*[starts-with(current(),@name)]">
            <xsl:attribute name="{../@to}">
                <xsl:value-of select="."/>
            </xsl:attribute>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="*" mode="domain-metadata">
        <xsl:apply-templates mode="domain-metadata" select="*"/>
    </xsl:template>
    
    
    <xsl:template match="xi:table" mode="domain-metadata">
        <concept name="{@id}" server="demo">
            <select owner="iorders" sql-name="{@id}"/> 
            <save owner="iorders" sql-name="{@id}"/> 
            <xsl:apply-templates mode="domain-metadata" select="xi:columns"/>
        </concept>
    </xsl:template>
    
    
    <xsl:template match="xi:columns" mode="domain-metadata">
        
        <xsl:apply-templates mode="domain-metadata" select="xi:column[@name='id']"/>
        
        <property name="xid"/>
        
        <xsl:apply-templates mode="domain-metadata" select="xi:column[not(@parent or @name='id' or @name='xid')]"/>
        <xsl:apply-templates mode="domain-metadata" select="xi:column[@parent]"/>
        
    </xsl:template>
    
    
    <xsl:template match="xi:column[@parent]" mode="domain-metadata">
        <role name="{@name}" actor="{@parent}">
            <xsl:if test="ancestor::xi:table[1]/@belongs = @parent">
                <xsl:attribute name="type">belongs</xsl:attribute>
            </xsl:if>
        </role>
    </xsl:template>
    
    
    <xsl:template match="xi:column[not(@parent)]" mode="domain-metadata">
        
        <property>
            <xsl:copy-of select="@name"/>
            <xsl:apply-templates select="@type" mode="sql-translate"/>
            <xsl:if test="@name='id'">
                <xsl:attribute name="type">int</xsl:attribute>
            </xsl:if>
            <xsl:copy-of select="@key|@label"/>            
        </property>
        
    </xsl:template>
    
    
</xsl:stylesheet>