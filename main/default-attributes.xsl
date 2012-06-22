<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns="http://unact.net/xml/xi"
>   
    
    <xsl:template match="xi:workflow//*[not(@id)] | xi:field[not(@id)]" mode="extend">
        <xsl:call-template name="build-id"/>
    </xsl:template>

    <xsl:template match="*[@id][not(@ref)][@form and not(@field)]" mode="extend">
        <xsl:attribute name="ref">
            <xsl:value-of select="ancestor::xi:view/xi:view-schema//xi:form[@name=current()/@form]/@id"/>
        </xsl:attribute>
    </xsl:template>


    <xsl:template match="*[@id][not(@ref)][not(@form) and @field]" mode="extend">
        <xsl:attribute name="ref">
            <xsl:value-of select="
                ancestor::xi:view/xi:view-schema//xi:form/*
                    [self::xi:field or self::xi:parameter][@name=current()/@field]
                /@id
            "/>
        </xsl:attribute>
    </xsl:template>


    <xsl:template match="*[@id][not(@ref)][@form and @field]" mode="extend">
        <xsl:attribute name="ref">
            <xsl:value-of select="
                ancestor::xi:view/xi:view-schema//xi:form[@name=current()/@form]/*
                    [self::xi:field or self::xi:parameter]
                    [@name=current()/@field]
                    [not( current()/self::xi:input or current()/self::xi:print)
                        or (current()/self::xi:input and @editable)
                        or (current()/self::xi:print and last()
                    )]
                /@id"
            />
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="xi:grid[xi:columns]/xi:column"/>

    <xsl:template match="xi:grid[@ref][not(xi:columns)]" mode="extend">
        
        <xsl:param name="overrides" select="xi:column"/>
        
        <xsl:element name="columns">
            
            <xsl:for-each select="key('id',@ref)//*[not (@hidden or @new-only or ancestor::xi:form[@choise])]">
                <xsl:variable name="override" select="$overrides[@ref=current()/@id]"/>                
                <xsl:if test="(self::xi:field|self::xi:parameter|self::xi:form[@choise]|$override)[@label]">
                    <column ref="{@id}" label="{@label}">
                        <xsl:copy-of select="$override/@label|@format"/>
                        <xsl:copy-of select="$override/@format"/>
                    </column>
                </xsl:if>
            </xsl:for-each>
            
        </xsl:element>
        
    </xsl:template>

</xsl:stylesheet>
