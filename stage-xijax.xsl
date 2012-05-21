<?xml version="1.0" ?>

<xsl:transform version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns="http://unact.net/xml/xi"
 xmlns:xi="http://unact.net/xml/xi"
 xmlns:php="http://php.net/xsl"
 >
  
    <xsl:output method="xml" indent="no" encoding="utf-8"/> 
    <xsl:param name="context-old" select="php:function('getContext','context')"/>
    <xsl:param name="context-new" select="/"/>
  
    <xsl:key name="id" match="*" use="@id"/>

    <xsl:template match="/">
        <context-changes>
            <xsl:apply-templates select="$context-old/*">
                <xsl:with-param name="new" select="*"/>
            </xsl:apply-templates>
        </context-changes>
    </xsl:template>

    <xsl:template match="*" name="standart">
        <xsl:param name="new"/>
        <!--xsl:comment>
            <xsl:value-of select="concat(local-name(),':',@id,':',@name)"/>
        </xsl:comment-->
        <xsl:choose>
            <xsl:when test="self::xi:data[@choise][@chosen!=$new/@chosen or (not(@chosen) and $new/@chosen)]">
                <xsl:copy-of select="$new"/>
            </xsl:when>
            <xsl:when test="self::xi:data[not($new)]">
                <deleted>
                    <xsl:copy-of select="@*"/>
                </deleted>
            </xsl:when>
            <xsl:when test="self::xi:data[not(xi:response[xi:exception])][$new/xi:response[xi:exception]]">
                <inserted>
                    <xsl:copy-of select="@*|$new/xi:response"/>
                </inserted>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="*">
                    <xsl:choose>
                        <xsl:when test="@id">
                            <xsl:apply-templates select=".">
                                <xsl:with-param name="new" select="$new/*[@id=current()/@id]"/>
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:when test="@name">
                            <xsl:apply-templates select=".">
                                <xsl:with-param name="new" select="$new/*[@name=current()/@name]"/>
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:when test="parent::xi:view|self::xi:exception|self::xi:response">
                            <xsl:apply-templates select=".">
                                <xsl:with-param name="new" select="$new/*[local-name()=local-name(current())]"/>
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:variable name="position" select="position()"/>
                            <xsl:apply-templates select=".">
                                <xsl:with-param name="new" select="$new/*[position()=$position]"/>
                            </xsl:apply-templates>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="xi:option">
        <xsl:param name="new"/>
        <xsl:if test="@advisor!=$new/@advisor or (not(@advisor) and $new/@advisor)">
            <xsl:copy-of select="$new"/>
        </xsl:if>        
    </xsl:template>

    <xsl:template match="xi:exception|xi:response-">
        <xsl:param name="new"/>
        <xsl:if test="not($new)">
            <deleted>
                <xsl:copy-of select="."/>
            </deleted>
        </xsl:if>        
    </xsl:template>

    <xsl:template match="xi:datum[@id]">
        <xsl:param name="new"/>
        <xsl:if test="text()!=$new/text() or (not(text()) and $new/text()) or (text() and not($new/text())) or $context-new/*/xi:userinput/xi:command/@name=@id">
            <xsl:copy-of select="$new"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*" mode="text-change">
        <xsl:copy-of select="."/>
    </xsl:template>

</xsl:transform>
