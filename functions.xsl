<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns:e="http://exslt.org/common"
    xmlns:php="http://php.net/xsl"
    xmlns:func="http://exslt.org/functions"
    xmlns:dyn="http://exslt.org/dynamic"
    extension-element-prefixes="func e dyn"
    exclude-result-prefixes="php func e dyn"
>
    
    <xsl:template name="as-attribute" mode="as-attribute" match="*">
        <xsl:param name="node" select="."/>
        <xsl:attribute name="{local-name($node)}">
            <xsl:value-of select="$node"/>
        </xsl:attribute>
    </xsl:template>

    <func:function name="xi:isnull">
        <xsl:param name="a" select="xi:null"/>
        <xsl:param name="b" select="xi:null"/>
        <xsl:choose>
            <xsl:when test="not($a) or string-length($a)=0">
                <func:result select="$b"/>
            </xsl:when>
            <xsl:otherwise>
                <func:result select="$a"/>
            </xsl:otherwise>
        </xsl:choose>
    </func:function>
    
    <func:function name="xi:string-to-date">
        <xsl:param name="datum" select="."/>
        <xsl:variable name="numbers" select="translate($datum,'./-','')"/>
        <func:result select="concat(substring($numbers,5,4),substring($numbers,3,2),substring($numbers,1,2))"/>
    </func:function>
    
    <func:function name="xi:max">
        <xsl:param name="a"/>
        <xsl:param name="b" select="0"/>
        <xsl:if test="$a > $b">
            <func:result select="$a"/>
        </xsl:if>
        <func:result select="$b"/>
    </func:function>

    <func:function name="xi:xpath">
        <xsl:param name="xpath" />
        <func:result select="dyn:evaluate($xpath)"/>
    </func:function>
    
</xsl:transform>