<?xml version="1.0" ?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns="http://unact.net/xml/xi"
>

    
    <xsl:key name="name" match="xi:field|xi:form" use="@name"/>

    
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
    
    
    <xsl:template match="xi:data|xi:datum" mode="build-import">
        <xsl:copy>
            
            <xsl:apply-templates select="@*" mode="build-import"/>
            
            <xsl:apply-templates select="node()" mode="build-import"/>
            
        </xsl:copy>
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
    </xsl:template>
    
</xsl:transform>
