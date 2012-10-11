<?xml version="1.0" ?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns:php="http://php.net/xsl"
    xmlns:func="http://exslt.org/functions"
    extension-element-prefixes="func"
    exclude-result-prefixes="php func"
>
    <xsl:output method="xml" indent="no" encoding="utf-8"/>  
    
    <xsl:param name="counter">1</xsl:param>
    
    <xsl:param name="userinput" select="/*/xi:userinput/xi:command"/>
    <xsl:param name="model" select="
        document(/*/xi:session/xi:domains/xi:domain/@href)/xi:domain
    "/>
    <xsl:param name="thisdoc" select="/"/>
    <xsl:param name="session" select="/*/xi:session"/>

    <xsl:key name="id" match="*" use="@id"/>

    <xsl:include href="functions.xsl"/>
    
    <xsl:template match="*" name="id">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="." mode="extend"/>
            <xsl:apply-imports/>
            <xsl:variable name="replace"><xsl:apply-templates select="." mode="extend-replace"/></xsl:variable>
            <xsl:if test="string-length($replace)!=0">
                <xsl:apply-templates select="." mode="extend-replace"/>
            </xsl:if>
            <xsl:if test="string-length($replace)=0 ">
                <xsl:apply-templates select="node()"/>
            </xsl:if>
            <!--xsl:apply-templates select="node()"/-->
        </xsl:copy>
    </xsl:template>

    <xsl:template match="@*|processing-instruction()|comment()">
        <xsl:copy/>
    </xsl:template>

    <xsl:template match="node()" mode="extend-replace"/>
    
    <xsl:template match="node()|@*" mode="extend"/>

    <xsl:template match="@*|node()" mode="quoted">
        <xsl:param name="value" select="."/>
        <xsl:text>'</xsl:text>
        <xsl:value-of select="$value"/>
        <xsl:text>'</xsl:text>
    </xsl:template>

    <xsl:template match="@*|node()" mode="doublequoted">
        <xsl:param name="value" select="."/>
        <xsl:text>[</xsl:text>
        <xsl:value-of select="$value"/>
        <xsl:text>]</xsl:text>
    </xsl:template>

    <xsl:template match="*" mode="build-ref"/>
    
    <xsl:template match="*[@id]" mode="build-ref">
        <xsl:attribute name="ref">
            <xsl:value-of select="@id"/>
        </xsl:attribute>
    </xsl:template>
 
    <!--xsl:template match="*[@id]" mode="generate-id" >
        <xsl:value-of select="@id"/>
    </xsl:template-->
    
    <xsl:template match="@*|node()" mode="generate-id" >
        <xsl:value-of select="concat('i',translate(generate-id(),'id',''),'c',$counter)"/>
    </xsl:template>
    
    <xsl:template match="@*|node()" mode="build-id" name="build-id">
        
        <xsl:param name="name">id</xsl:param>
        <xsl:param name="id-value">
            <xsl:apply-templates mode="generate-id" select="."/>
        </xsl:param>
        
        <xsl:attribute name="{$name}">
            <xsl:value-of select="$id-value"/>
        </xsl:attribute>
        
    </xsl:template>

</xsl:transform>
