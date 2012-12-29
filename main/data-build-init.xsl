<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns="http://unact.net/xml/xi"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns:php="http://php.net/xsl"
    exclude-result-prefixes="php"
>
 
    <xsl:template match="xi:init" mode="build-data-init"/>

    <xsl:template match="xi:init[@with='today']" mode="build-data-init">
        <xsl:value-of select="php:function('initToday')"/>
    </xsl:template>

    <xsl:template match="xi:init[@with='constant' or @with='const']" mode="build-data-init">
        <xsl:value-of select="."/>
    </xsl:template>

    <xsl:template match="xi:init[@with='device-name']" mode="build-data-init">
        <xsl:choose>
            <xsl:when test="/*/xi:userinput/@ipad-agent">ipad</xsl:when>
            <xsl:when test="/*/xi:userinput/@safari-agent">safari</xsl:when>
            <xsl:when test="/*/xi:userinput/@spb-agent">tsd</xsl:when>
            <xsl:when test="/*/xi:userinput/@firefox-agent">firefox</xsl:when>
            <xsl:otherwise>browser</xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="xi:init[@with='uuid']" mode="build-data-init">
        <xsl:value-of select="php:function('uuidSecure','')"/>
    </xsl:template>
 
    <xsl:template match="xi:init[@with='userinput']" mode="build-data-init">
        <xsl:value-of select="/*/xi:userinput/xi:command[@name=current()/parent::*/@name]"/>
    </xsl:template>
    
    <xsl:template match="xi:init[@with='username']" mode="build-data-init">
        <xsl:value-of select="/*/xi:session/@username"/>
    </xsl:template>

    <xsl:template match="xi:init[@with='role']" mode="build-data-init">
        <xsl:variable name="role" select="/*/xi:session/xi:role[@name=current()]"/>
        <xsl:value-of select="$role|/*[not($role/text())]/xi:session/@username"/>
    </xsl:template>

    <!--xsl:template match="xi:init[@with='field']" mode="build-data-init">
        <xsl:apply-templates select="." mode="init-with-field"/>
    </xsl:template>
    
    <xsl:template match="*[@ref]" mode="init-with-field">
        <xsl:value-of select="
            ancestor::xi:view/xi:view-data//xi:datum[@ref=current()/@ref]
        "/>
    </xsl:template>
    
    <xsl:template match="*" mode="init-with-field">
        <xsl:value-of select="
            ancestor::* [@name=current()/@form]
                /* [@name=current()/@field]
        "/>
    </xsl:template-->

    <xsl:template match="xi:init[@with='view-schema-version']" mode="build-data-init">
        <xsl:value-of select="concat(ancestor::xi:view/@name, '_', ancestor::xi:view-schema/@version)"/>
    </xsl:template>

</xsl:stylesheet>
