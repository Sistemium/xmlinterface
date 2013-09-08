<?xml version="1.0" encoding="UTF-8"?>

<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://unact.net/xml/xi"
    xmlns:xi="http://unact.net/xml/xi"
>
    
    
    <!--  Templates for building strings of sql column names  -->

    <xsl:template match="@*" mode="sql-name">
        <xsl:apply-templates select="." mode="doublequoted"/>
    </xsl:template>

    <xsl:template match="*[@sql-compute]" mode="sql-name" name="compute-sql-name">
        <xsl:value-of select="@sql-compute"/>
    </xsl:template>

    <xsl:template match="xi:column[@type='date' and not(@sql-compute)]" mode="sql-name" priority="1000">
        <xsl:text>convert(char(10),</xsl:text>
        <xsl:apply-templates select="../@name" mode="doublequoted"/>
        <xsl:text>.</xsl:text>
        <xsl:apply-templates select="@sql-name|self::*[not(@sql-name)]/@name" mode="doublequoted"/>
        <xsl:text>,104)</xsl:text>
    </xsl:template>

    <xsl:template match="xi:data-request//xi:column[@type='datetime' and not(@sql-compute)]" mode="sql-name" priority="1000">
        <xsl:text>convert(varchar(19),</xsl:text>
        <xsl:apply-templates select="../@name" mode="doublequoted"/>
        <xsl:text>.</xsl:text>
        <xsl:apply-templates select="@sql-name|self::*[not(@sql-name)]/@name" mode="doublequoted"/>
        <xsl:text>,10</xsl:text>
        <xsl:choose>
         <xsl:when test="@aggregate">2</xsl:when>
         <xsl:otherwise>4</xsl:otherwise>
        </xsl:choose>
        <xsl:text>)+' '+convert(varchar(8),</xsl:text>
        <xsl:apply-templates select="../@name" mode="doublequoted"/>
        <xsl:text>.</xsl:text>
        <xsl:apply-templates select="@sql-name|self::*[not(@sql-name)]/@name" mode="doublequoted"/>
        <xsl:text>,8)</xsl:text>
    </xsl:template>

    <xsl:template match="xi:join/xi:on" mode="sql-name">
        <xsl:param name="value"
            select="ancestor::xi:data-request/xi:etc/xi:parameter[@name=current()[@property='id']/@name]
                | ancestor::xi:data-request/xi:etc/xi:data[@name=current()/@name]/xi:set-of-parameters
            "
        />
        <xsl:choose>
            <xsl:when test="$value/self::xi:set-of-parameters">
                <xsl:for-each select="$value/*">
                    <xsl:apply-templates select="." mode="value"/>
                    <xsl:if test="last() > position()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="$value">
                <xsl:apply-templates select="$value" mode="value"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="self::*[@name]/@name|self::*[not(@name)]/@concept" mode="doublequoted"/>
                <xsl:text>.</xsl:text>
                <xsl:variable name="property" select="$model/xi:concept[@name=current()/@concept]/*[@name=current()/@property]"/>
                <xsl:apply-templates select="$property" mode="sql-name"/>
                <xsl:if test="not($property)">
                    <xsl:apply-templates select="@property" mode="sql-name"/>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="xi:column[@type='file']" mode="sql-name">
        <xsl:text>base64_encode(</xsl:text>
        <xsl:apply-templates select="@sql-name|self::*[not(@sql-name)]/@name" mode="doublequoted"/>
        <xsl:text>)</xsl:text>
    </xsl:template>

    <xsl:template match="xi:column[@type='xml']" mode="sql-name">
        <xsl:if test="not(ancestor::xi:data-request[@storage='mssql' or @page-size-])">
            <xsl:text>xmlelement(</xsl:text>
            <xsl:apply-templates select="@name" mode="quoted"/>
            <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:text>xmlelement(</xsl:text>
        <xsl:apply-templates select="@name" mode="quoted"/>
        <xsl:text>, xmlattributes ('xml' as "type"), cast( </xsl:text>
        <xsl:apply-templates select="@sql-name|self::*[not(@sql-name)]/@name" mode="doublequoted"/>
        <xsl:text> as xml))</xsl:text>
        <xsl:if test="not(ancestor::xi:data-request[@storage='mssql' or @page-size-])">
            <xsl:text>)</xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="xi:parameter[@sql-name]" mode="sql-name">
        <xsl:value-of select="@sql-name"/>
    </xsl:template>

    <xsl:template match="*[@sql-name]" mode="sql-name">
        <xsl:if test="self::xi:column">
            <xsl:apply-templates select="../@name" mode="doublequoted"/>
            <xsl:text>.</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="@sql-name" mode="doublequoted"/>
    </xsl:template>

    <xsl:template match="*[@name]" mode="sql-name" priority="-100">
        <xsl:if test="self::xi:column">
            <xsl:apply-templates select="../@name" mode="doublequoted"/>
            <xsl:text>.</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="@name" mode="doublequoted"/>
    </xsl:template>

    <xsl:template match="*[not(@name)]" mode="sql-name" priority="-100">
        <xsl:apply-templates select="../@name" mode="doublequoted"/>
    </xsl:template>
    
    <xsl:template match="@*" mode="prefix">
        <xsl:apply-templates select="." mode="doublequoted"/>
        <xsl:text>.</xsl:text>
    </xsl:template>
    
    
    
</xsl:transform>