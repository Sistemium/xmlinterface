<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns:e="http://exslt.org/common"
    xmlns:php="http://php.net/xsl"
    xmlns:func="http://exslt.org/functions"
    xmlns:dyn="http://exslt.org/dynamic"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="func e dyn str"
    exclude-result-prefixes="php func e dyn str"
>
    
    <xsl:variable name="lcletters">abcdefghijklmnopqrstuvwxyz</xsl:variable>
    <xsl:variable name="ucletters">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
    
    <xsl:template name="as-attribute" mode="as-attribute" match="*">
        <xsl:param name="node" select="."/>
        <xsl:attribute name="{local-name($node)}">
            <xsl:value-of select="$node"/>
        </xsl:attribute>
    </xsl:template>


    <func:function name="xi:upper" >
        <xsl:param name="string" select="."/>
        <func:result select="translate($string,$lcletters,$ucletters)"/>
    </func:function>
    
    
    <func:function name="xi:padtab" >
        <xsl:param name="count" select="1"/>
        <xsl:param name="symbol" select="'&#x20;'"/>
        
        <func:result select="str:padding($count*4,$symbol)"/>
    </func:function>

    <func:function name="xi:crlf" >
        <xsl:param name="count" select="1"/>
        <xsl:param name="symbol" select="'&#xD;'"/>
        <func:result select="str:padding($count, $symbol)"/>
    </func:function>

    
    <func:function name="xi:directoryList">
        <xsl:param name="path" select="xi:null"/>
        <func:result select="php:function('directoryList',string($path))"/>
    </func:function>

    <func:function name="xi:regexp">
        <xsl:param name="pattern" select="xi:null"/>
        <xsl:param name="string" select="xi:null"/>
        <func:result select="php:function('preg_match', string($pattern), string($string))"/>
    </func:function>

    <func:function name="xi:list">
        <xsl:param name="tokens" select="xi:null"/>
        <xsl:variable name="result">
            <xsl:for-each select="$tokens">
                <xsl:value-of select="."/>
                <xsl:if test="last()>position()">
                    <xsl:text>, </xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <func:result select="$result"/>
    </func:function>
    
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
    
    <func:function name="xi:map">
        <xsl:param name="point" />
        <xsl:param name="xpath" />
        <func:result select="dyn:map($point, $xpath)"/>
    </func:function>
    
</xsl:transform>