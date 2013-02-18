<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
    xmlns="http://unact.net/xml/xi"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns:php="http://php.net/xsl"
>

    <xsl:template match="xi:import[@href]">
        <xsl:apply-templates select="document(@href)"/>
    </xsl:template>
    
    <xsl:template match="xi:context-extension">
        <xsl:apply-templates select="*"/>
    </xsl:template>
    
    <xsl:template match="
        xi:context-extension//text()
        |
        xi:context-extension//comment()"
    />
    
    <xsl:template match="xi:context-extension//*/@directory">
        <xsl:apply-templates select="php:function('directoryList',string(.))" mode="import-directory">
            <xsl:with-param name="this" select=".."/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="xi:context-extension//*/@href">
        <xsl:copy/>
        <xsl:apply-templates select=".." mode="import-file"/>
    </xsl:template>
    
    <xsl:template match="xi:directory" mode="import-directory">
        
        <xsl:param name="this" select="xi:null"/>
        
        <xsl:for-each select="xi:file">
            <xsl:apply-templates select="$this" mode="import-file">
                <xsl:with-param name="href" select="concat($this/@directory,'/',.)"/>
            </xsl:apply-templates>
        </xsl:for-each>
        
    </xsl:template>

    <xsl:template match="*" mode="import-file">
        <xsl:param name="href" select="@href"/>
        <xsl:apply-templates select="document($href)/*"/>
    </xsl:template>
    
    <xsl:template match="xi:option" mode="import-file">
        <xsl:apply-templates select="document(@href)/*" mode="build-option"/>
    </xsl:template>
    
    <xsl:template match="xi:menu" mode="import-file">
        <xsl:param name="href" select="@href"/>
        <option href="{$href}">
            <xsl:apply-templates select="@*|document(concat('../',$href))/*|*" mode="build-option"/>
        </option>
    </xsl:template>
 
    <xsl:template match="node()" mode="build-option"/>
    <xsl:template match="/*" mode="build-option">
        <xsl:apply-templates select="@*|*" mode="build-option"/>
    </xsl:template>
    
    <xsl:template match="@*" mode="build-option">
        <xsl:copy/>
    </xsl:template>
    
    
    <xsl:template match="xi:context-extension[count(xi:views)&gt;1]//xi:views[not(@name)]" mode="extend">
        
        <xsl:attribute name="name">
            
            <xsl:variable name="role-name">
                <xsl:for-each select="(xi:access|xi:secure)[@role]">
                    <xsl:if test="position() >1">-</xsl:if>
                    <xsl:value-of select="@role"/>
                </xsl:for-each>
            </xsl:variable>
            
            <xsl:value-of select="$role-name"/>
            
            <xsl:if test="$role-name=''">
                <xsl:value-of select="concat('views-', count(ancestor::xi:context-extension/preceding-sibling::xi:context-extension[xi:views])+1)"/>
            </xsl:if>
            
        </xsl:attribute>
        
    </xsl:template>
    

</xsl:stylesheet>
