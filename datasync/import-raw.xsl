<?xml version="1.0" ?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns="http://unact.net/xml/xi"
>

    
    <xsl:key name="name" match="xi:field|xi:form" use="@name"/>
    
    <xsl:template match="xi:preload/@refresh-this | xi:preload/@page-start"/>

    <xsl:template match="xi:userinput/xi:command[@name='filter' and key('name',text())/@is-set]">
        <xsl:call-template name="id" />
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="synthetic">true</xsl:attribute>
            <xsl:text>set-of-</xsl:text>
            <xsl:copy-of select="text()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="xi:userinput/xi:command[key('name',@name)/self::xi:form[@is-set]]/@name">
        <xsl:attribute name="name">
            <xsl:text>set-of-</xsl:text>
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>
    
    
    <xsl:template match="xi:userinput/xi:rawxml">
        <xsl:apply-templates select="*" mode="build-import"/>
    </xsl:template>
    
    <xsl:template match="xi:userinput/xi:import//*[@ref][not(@name)]" mode="extend">
        <xsl:copy-of select="key('id',@ref)/@name"/>
    </xsl:template>
    
    <xsl:template match="node()|@*" mode="build-import"/>
    
    
    <xsl:template match="xi:upload" mode="build-import">
        <import>
            
            <xsl:copy-of select="@*" />
            
            <xsl:apply-templates select="*" mode="build-import"/>
            
        </import>
    </xsl:template>

    
    <xsl:template match="node()|@*" mode="build-import"/>
    
    
    <xsl:template match="xi:datum/node()" mode="build-import">
        <xsl:copy-of select="."/>
    </xsl:template>
    
    <xsl:template match="xi:datum[@parent and text()='null']/text()" mode="build-import" priority="1000"/>    
    
    <xsl:template match="xi:data|xi:datum" mode="build-import">
        <xsl:copy>
            
            <xsl:apply-templates select="@*" mode="build-import"/>
            
            <xsl:apply-templates select="node()" mode="build-import"/>
            
        </xsl:copy>
    </xsl:template>

    <xsl:template match="xi:delete" mode="build-import">
        <data delete-this="true">
            <xsl:apply-templates mode="build-ref" select="
                key('name',@name)/self::xi:form
            "/>
            <datum name="xid">
                <xsl:apply-templates mode="build-ref" select="
                    key('name','xid')/self::xi:field
                        [parent::xi:form/@name=current()/@name]
                "/>
                <xsl:value-of select="@xid"/>
            </datum>
        </data>
    </xsl:template>
    
    <xsl:template match="xi:data/@name" mode="build-import">
        <xsl:apply-templates mode="build-ref" select="
            key('name',.)/self::xi:form
        "/>
    </xsl:template>
    

    <xsl:template match="xi:datum/@name" mode="build-import">
        <xsl:apply-templates mode="build-ref" select="
            key('name',.)/self::xi:field
                [parent::xi:form/@name=current()/parent::*/parent::xi:data[1]/@name]
        "/>
    </xsl:template>
    
    
    <xsl:template match="xi:datum/@alias" mode="build-import">
        <xsl:param name="form" select="key('name',parent::*/parent::xi:data[1]/@name)"/>
        <xsl:apply-templates mode="build-ref" select="
            $form/xi:field[@alias=current() or self::*[not(@alias)]/@name=current()]
        "/>
    </xsl:template>
    
    <xsl:template match="xi:datum/@parent" mode="build-import">
        <xsl:param name="form" select="key('name',parent::*/parent::xi:data[1]/@name)"/>
        <xsl:apply-templates mode="build-ref" select="
            $form/parent::xi:form[@name=current()]
        "/>
        <xsl:apply-templates mode="build-ref" select="
            $form/xi:parent-join[@name=current()][@role=current()/../@alias]
        "/>
    </xsl:template>
    
</xsl:transform>
