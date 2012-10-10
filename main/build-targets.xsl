<?xml version="1.0" ?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns="http://unact.net/xml/xi"
    
    xi:usage="import"
    
>

    <xsl:template match="xi:userinput">
        
        <targets>
            <xsl:apply-templates select="*" mode="build-target"/>
        </targets>
        
    </xsl:template>


    <xsl:template mode="build-target" match="xi:userinput/xi:command">
        
        <xsl:apply-templates mode="build-target" select="
            key('id',current()/@name)
        ">
            <xsl:with-param name="command" select="."/>
        </xsl:apply-templates>
        
    </xsl:template>


    <xsl:template mode="build-target" match="*">
        <xsl:param name="command" select="xi:null"/>
        <xsl:apply-templates select="*" mode="build-target">
            <xsl:with-param name="command" select="$command"/>
        </xsl:apply-templates>
    </xsl:template>
    
    
    <xsl:template name="build-target">
        <xsl:param name="target-id"/>
        <xsl:param name="payload"/>
        <target ref="{$target-id}">
            <xsl:value-of select="$payload"/>
        </target>
    </xsl:template>
    
    
    <xsl:template mode="build-target" match="xi:command [not(@name)] [@xpath-compute]">
        
        <xsl:param name="command"/>
        <xsl:param name="this" select="."/>
        
        <xsl:for-each select="xi:map(key('id', $command), @xpath-compute)">
            <xsl:call-template name="build-target">
                <xsl:with-param name="target-id" select="current()"/>
                <xsl:with-param name="payload" select="$this"/>
            </xsl:call-template>
        </xsl:for-each>
        
    </xsl:template>
    

</xsl:transform>
