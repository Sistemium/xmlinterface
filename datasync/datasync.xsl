<?xml version="1.0" ?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://unact.net/xml/xi"
    xmlns:xi="http://unact.net/xml/xi"
    exclude-result-prefixes="xi">

    <xsl:key name="id" match="*" use="@id"/>
    
    <xsl:template match="node()|@id"/>

    <xsl:template match="*">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="/*">
        <!--xsl:processing-instruction name="xml-stylesheet">
            <xsl:text>type="text/xsl" href="sencha.i.xsl"</xsl:text>
        </xsl:processing-instruction-->
        <datasync>
            <xsl:apply-templates/>
        </datasync>
    </xsl:template>
    
    <xsl:template match="/*[not(@pipeline-name='main')]//xi:view-schema"/>

    <xsl:template match="/*[not(@pipeline-name='download')]//xi:view-data">
        <xsl:apply-templates select="descendant::xi:exception"/>
    </xsl:template>

    <xsl:template match="xi:exception">
        <xsl:copy-of select="."/>
    </xsl:template>

    <xsl:template match="xi:menu[not(*) or /*/xi:userinput/xi:command[@name='filter']]"/>

    <xsl:template match="xi:view-data">
        <data>
            <xsl:copy-of select="../@*"/>
            <xsl:apply-templates/>
        </data>
    </xsl:template>

    <xsl:template match="xi:view-schema"/>

    <xsl:template match="xi:view-schema//*|xi:view-schema//*/@* | xi:menu | xi:option |  @*">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="xi:view-schema//*/@id | xi:view-schema//*/@ref"/>

    <xsl:template match="
        xi:userinput/*
        [@name='filter'][not(@synthetic)]
        [not( /*/xi:views/xi:view[not(@hidden)]/xi:view-data//*[self::xi:data|self::xi:preload]/@name= . )]
    ">
        <no-data name="{.}">
            <xsl:for-each select="/*/xi:views/xi:view[not(@hidden)]/xi:view-schema//xi:form[@name=current()/text()]/ancestor::xi:form[not(@is-set)]">
                <xsl:for-each select="ancestor::xi:view/xi:view-data//*[self::xi:data|self::xi:preload][@ref=current()/@id][@choise and not(@chosen)]">
                    <choose name="{@name}" ref="{@choise}"/>
                </xsl:for-each>
            </xsl:for-each>
        </no-data>
    </xsl:template>

    <xsl:template match="xi:views[xi:view]/xi:menu"/>

    <xsl:template match="xi:session">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:for-each select="xi:exception">
                <xsl:attribute name="exception"><xsl:value-of select="."/></xsl:attribute>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>

    <xsl:template priority="1000" match="
        xi:set-of[@is-choise]
            [parent::xi:data[not(xi:datum[@type='field']) and @name = /*/xi:userinput/*[text()='next']/@name]]
    "/>

    <xsl:template match="xi:set-of[@is-choise]">
        
        <choise>
            
            <xsl:copy-of select="@id"/>
            <xsl:attribute name="options-count">
                <xsl:value-of select="count(xi:data)"/>
            </xsl:attribute>
            <xsl:attribute name="next">
                <xsl:value-of select="xi:data[1]/@id"/>
            </xsl:attribute>
            <xsl:if test="../@chosen">
                <xsl:attribute name="next">
                    <xsl:value-of select="xi:data[@id=current()/../@chosen]/following-sibling::xi:data[1]/@id"/>
                </xsl:attribute>
                <xsl:attribute name="current-position">
                    <xsl:value-of select="count(xi:data[@id=current()/../@chosen]/preceding-sibling::xi:data)+1"/>
                </xsl:attribute>
            </xsl:if>
            
        </choise>
        
    </xsl:template>

    <xsl:template match="xi:data|xi:set-of">
        <xsl:apply-templates select="xi:data|xi:preload[xi:response]|xi:set-of[not(@is-choise)]"/>
    </xsl:template>

    <xsl:template match="xi:set-of[@page-size]">
        <paged>
            <xsl:copy-of select="@page-size|@page-start"/>
            <xsl:apply-templates select="xi:data|xi:set-of"/>
        </paged>
    </xsl:template>

    <xsl:template match="xi:data[@remove-this|@is-new]" priority="1000"/>
    
    <xsl:template match="*[self::xi:data][
        not(/*/xi:userinput/*[@name='filter'])
         or /*/xi:userinput/*[@name='filter']=(
            @name
            | self::*[not(/*/xi:userinput/*[@name='filter-strict'])]/ancestor::xi:data/@name
            | descendant::xi:data[not(@is-new)]/@name
        )]"
    >
        <xsl:element name="{@name}">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="xi:preload[xi:response]">
        <xsl:element name="{@name}">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="xi:response">
        <not-found ts="{@ts}"/>
    </xsl:template>

    <xsl:template match="xi:datum[text()]">
        <xsl:attribute name="{@name}">
            <xsl:value-of select="text()"/>
        </xsl:attribute>
    </xsl:template>

</xsl:transform>