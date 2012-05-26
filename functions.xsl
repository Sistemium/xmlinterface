<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns:e="http://exslt.org/common"
    xmlns:php="http://php.net/xsl"
    xmlns:func="http://exslt.org/functions"
    extension-element-prefixes="func e"
    exclude-result-prefixes="php func e"
>
    
    <func:function name="xi:isnull">
        <xsl:param name="a" select="xi:null"/>
        <xsl:param name="b" select="xi:null"/>
        <xsl:value-of select="$a"/>
        <xsl:if test="not($a)">
            <xsl:value-of select="$b"/>
        </xsl:if>
    </func:function>
    
</xsl:transform>