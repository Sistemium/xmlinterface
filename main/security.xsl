<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
    xmlns="http://unact.net/xml/xi"
    xmlns:xi="http://unact.net/xml/xi"
>

    <xsl:param name="session" />
    

    <xsl:template match="*[xi:access[not(@authorised)]]">
        <xsl:if test="not(xi:access[not($session/xi:role/@name = @role)])">
            <xsl:apply-templates select="." mode="build-secure"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="xi:secure[@role]">
        <xsl:if test="$session/xi:role/@name = @role">
            <xsl:apply-templates select="*" mode="build-secure"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="xi:secure[@not-role]">
        <xsl:if test="not($session/xi:role/@name = @not-role)">
            <xsl:apply-templates select="*" mode="build-secure"/>
        </xsl:if>
    </xsl:template>


    <xsl:template match="*" name="build-secure" mode="build-secure">
        <xsl:call-template name="id"/>
    </xsl:template>
    
    <xsl:template match="xi:access" mode="build-option">
        <xsl:call-template name="id"/>
    </xsl:template>
    
    <xsl:template match="xi:access[not(@authorised or @authorise)]" mode="extend">
        <xsl:attribute name="authorise">check</xsl:attribute>
    </xsl:template>
    
    <xsl:template match="xi:access/@authorise" >
        <xsl:attribute name="authorised">true</xsl:attribute>
    </xsl:template>
    
    <xsl:template match="xi:secure/@role" />

    <xsl:template match="*[xi:secure[@role]]" mode="extend" name="build-role-attrs">
        <xsl:for-each select="xi:secure[@role=$session/xi:role/@name]">
            <xsl:apply-templates select="@*"/>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>