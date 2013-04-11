<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:dict="dict"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="dict"
>

    <xsl:output method="xml" indent="yes" encoding="utf-8"/>  

    <xsl:key name="id" match="*" use="@id"/>
    
    <xsl:template match="/xi:metadata">
        <html
            tables-count="{count(xi:tables/xi:table)}"
        >
            <body>
                <xsl:apply-templates mode="view-metadata" select="xi:tables"/>
            </body>
        </html>
    </xsl:template>
    
    <xsl:template match="xi:table" mode="view-metadata">
        <xsl:apply-templates mode="view-metadata" select="*"/>
    </xsl:template>
    
    
    <xsl:template match="xi:table" mode="view-metadata">
        <a id="{@id}"/>
        <li class="table">
            <h3>
                <xsl:choose>
                    <xsl:when test="@nameSet">
                        <xsl:value-of select="@nameSet"/>
                    </xsl:when>
                    <xsl:when test="@name">
                        <xsl:value-of select="@name"/>
                    </xsl:when>
                    <xsl:when test="@id">
                        <xsl:value-of select="@id"/>
                    </xsl:when>
                </xsl:choose>
            </h3>
            <xsl:apply-templates mode="view-metadata" select="*"/>
        </li>
    </xsl:template>
    
    <xsl:template match="xi:columns[xi:column[@label]]" mode="view-metadata">
        <ul class="{local-name()}">
            <xsl:apply-templates mode="view-metadata" select="*"/>
        </ul>
    </xsl:template>
    
    <xsl:template match="xi:tables" mode="view-metadata">
        <ol class="{local-name()}">
            <xsl:apply-templates mode="view-metadata" select="*"/>
        </ol>
    </xsl:template>
    
    <xsl:template match="xi:column[@label]" mode="view-metadata">
        <li class="column">
            <xsl:choose>
                <xsl:when test="@parent">
                    <a href="#{@parent}">
                        <xsl:value-of select="@label"/>
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <span>
                        <xsl:value-of select="@label"/>
                    </span>
                    <span class="datatype">
                        <xsl:value-of select="concat('(',@type,')')"/>
                    </span>
                </xsl:otherwise>
            </xsl:choose>
        </li>
    </xsl:template>
    
    <xsl:template match="xi:deps" mode="view-metadata">
        <h4 class="{local-name()}">
            <span class="label">Связи:</span>
            <xsl:apply-templates mode="view-metadata" select="*"/>
        </h4>
    </xsl:template>
    
    <xsl:template match="xi:dep" mode="view-metadata">
        <a href="#{@table_id}">
            <span class="dep">
                <xsl:for-each select="key('id',@table_id)">
                    <xsl:choose>
                        <xsl:when test="@nameSet">
                            <xsl:value-of select="@nameSet"/>
                        </xsl:when>
                        <xsl:when test="@name">
                            <xsl:value-of select="@name"/>
                        </xsl:when>
                        <xsl:when test="@id">
                            <xsl:value-of select="@id"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
            </span>
        </a>
        <xsl:if test="position() &lt; last()">
            <span>, </span>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>
