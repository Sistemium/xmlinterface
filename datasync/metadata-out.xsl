<?xml version="1.0" ?>

<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://unact.net/xml/xi"
    xmlns:xi="http://unact.net/xml/xi"
    exclude-result-prefixes="xi">


    <xsl:include href="../id.xsl"/>
    
    <xsl:template match="/">
        
        <xsl:for-each select="*/@style">
            <xsl:processing-instruction name="xml-stylesheet">
                <xsl:text>type="text/xsl" href="xsl/</xsl:text>
                <xsl:value-of select="."/>
                <xsl:text>-metadata.xsl"</xsl:text>
            </xsl:processing-instruction>
        </xsl:for-each>
        
        <!--xsl:processing-instruction name="xml-stylesheet-">
            <xsl:text>type="text/xsl" href="html-xsl.xsl"</xsl:text>
        </xsl:processing-instruction-->
        
        <xsl:apply-templates select="*"/>
        
    </xsl:template>

    <xsl:template match="xi:table[@extendable]/xi:columns/xi:column[@name='id']/@type" >
        <xsl:attribute name="type">string</xsl:attribute>
    </xsl:template>

    <xsl:template match="comment()"/>
    
    <xsl:template match="/*/@stage"/>
    
    <xsl:template match="@*[normalize-space() = '']"/>
    
    <xsl:template match="*[not(*|@*|text())]"/>

    <xsl:template match="*[@set-of][not(*[local-name()=../@set-of])]"/>
    
    <xsl:template match="xi:column/xi:predicate"/>
    
    <xsl:template match="xi:column/xi:predicate[1]">
        <predicates set-of="predicate">
            <xsl:copy-of select=".|following-sibling::xi:predicate"/>
        </predicates>
    </xsl:template>

</xsl:transform>