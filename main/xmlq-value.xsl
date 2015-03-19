<?xml version="1.0" encoding="UTF-8"?>

<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://unact.net/xml/xi"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns:php="http://php.net/xsl"
    exclude-result-prefixes="php"
>
    <!--  Templates for building strings of values  -->

    <xsl:template match="*[not(*)][not(text()) or text()='']" mode="value" priority="1000">
        <xsl:text>NULL</xsl:text>
    </xsl:template>
    
    <xsl:template match="*[@type='xml']" mode="value">
        <xsl:text>'</xsl:text>
        <xsl:copy-of select="*"/>
        <xsl:text>'</xsl:text>
    </xsl:template>

    <xsl:template match="*[@use-in]" mode="value" priority="101">
        <xsl:param name="datum" select="."/>
        <xsl:value-of select="concat('(',$datum,')')"/>
    </xsl:template>

    <xsl:template match="*[@type='number' or @type='int' or @type='decimal']" mode="value">
        <xsl:value-of select="."/>
    </xsl:template>
    
    <xsl:template match="*[@type='boolean']" mode="value">
        <xsl:value-of select="."/>
    </xsl:template>

    <xsl:template match="*[xi:less-than]" mode="value" priority="1000">
        <xsl:text>&lt;</xsl:text>
        <xsl:apply-templates select="xi:less-than/text()" mode="value"/>        
    </xsl:template>
        
    <xsl:template match="*[xi:more-than]" mode="value" priority="1000">
        <xsl:text>&gt;</xsl:text>
        <xsl:apply-templates select="xi:more-than/text()" mode="value"/>        
    </xsl:template>
        
    <xsl:template match="xi:use" mode="value" priority="1001">
        <xsl:param name="datum" select="
            (ancestor::xi:data-request|ancestor::*/xi:etc/xi:data)[@name=current()/@concept]
            /xi:parameter[@name=current()/@parameter]
        "/>
        <xsl:apply-templates select="$datum" mode="value"/>
        <xsl:if test="not($datum/text())">
            <xsl:text>null</xsl:text>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*" mode="value">
        <xsl:apply-templates select="." mode="quoted">
            <xsl:with-param name="value">
                <xsl:apply-templates select="." mode="sqlvalue"/>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="xi:datum" mode="value">
        <xsl:apply-templates select="." mode="quoted">
            <xsl:with-param name="value">
                <xsl:apply-templates select="key('id',@ref)" mode="sqlvalue">
                    <xsl:with-param name="datum" select="."/>
                </xsl:apply-templates>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="*[@type='file']" mode="value">
      <xsl:variable name="path">
         <xsl:value-of select="."/>
      </xsl:variable>
      <xsl:text>base64_decode('</xsl:text>
      <xsl:copy-of select="php:function('getFileContents',$path)"/>
      <xsl:text>')</xsl:text>
    </xsl:template>

    <xsl:template match="xi:data" mode="value">
        <xsl:apply-templates select="*[@key][1]" mode="value"/>
    </xsl:template>

    <xsl:template match="*" mode="sqlvalue">
        <xsl:param name="datum" select="."/>
        <xsl:variable name="q">'</xsl:variable>
        <xsl:value-of select="translate($datum,$q,' ')"/>
    </xsl:template>
    
    <xsl:template match="*[@use-like]" mode="sqlvalue">
        <xsl:param name="datum" select="."/>
        <xsl:value-of select="translate($datum,'*','%')"/>
    </xsl:template>

    <xsl:template match="*[@type='date']" mode="sqlvalue">
        <xsl:param name="datum" select="."/>
        <xsl:variable name="numbers" select="translate($datum,'./-','')"/>
        <xsl:value-of select="concat(substring($numbers,5),substring($numbers,3,2),substring($numbers,1,2))"/>
    </xsl:template>
    
    
</xsl:transform>
