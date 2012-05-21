<?xml version="1.0" ?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns="http://unact.net/xml/xi" xmlns:xi="http://unact.net/xml/xi"
 xmlns:php="http://php.net/xsl" exclude-result-prefixes="php"
 >
 
    <xsl:output method="text" encoding="windows-1251"/>  

    <xsl:param name="userinput" select="/*/xi:userinput/xi:command"/>

    <xsl:key name="id" match="*" use="@id"/>

    <xsl:template match="node()|@*">
        <xsl:apply-templates select="*"/>
    </xsl:template>
   
    <xsl:template match="xi:download">
        <xsl:value-of select="*/xi:result-set"/>
    </xsl:template>
   
    <xsl:template match="/">
        <xsl:apply-templates select="$userinput|xi:download"/>
    </xsl:template>
    
    <xsl:template match="xi:userinput/xi:command[@name='form']">
        <xsl:variable name="name" select="key('id',current()/text())/@name"/>
        <xsl:apply-templates select="/*/xi:views/*/xi:view-data//*[@ref=current()/text()]/descendant-or-self::xi:data[@name=$name]"/>
    </xsl:template>
    
    <xsl:template match="xi:data[not(@ref)]">
        <xsl:param name="meta" select="ancestor::xi:view/xi:view-schema//xi:form[@name=current()/@name]"/>
        <xsl:param name="data" select="."/>
        <xsl:for-each select="$meta/xi:field">
            <xsl:apply-templates select=".">
                <xsl:with-param name="datum" select="$data/xi:datum[@name=current()/@name]"/>
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="xi:datum|xi:field">
        <xsl:param name="datum" select="."/>
        <xsl:value-of select="translate($datum,';',',')"/>
        <xsl:apply-templates select="." mode="csv-delimiter"/>
    </xsl:template>

    <xsl:template match="*" mode="csv-delimiter">
        <xsl:text>;</xsl:text>
    </xsl:template>

    <xsl:template match="*[last()]|xi:field[not(following-sibling::xi:field)]" mode="csv-delimiter" >
        <xsl:text>&#13;&#10;</xsl:text>
    </xsl:template>

</xsl:transform>