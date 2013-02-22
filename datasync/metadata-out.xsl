<?xml version="1.0" ?>

<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://unact.net/xml/xi"
    xmlns:xi="http://unact.net/xml/xi"
    exclude-result-prefixes="xi">


    <xsl:include href="../id.xsl"/>
    
    <xsl:template match="/">
        
        <xsl:processing-instruction name="xml-stylesheet">
            <xsl:text>type="text/xsl" href="xsl/html-metadata.xsl"</xsl:text>
        </xsl:processing-instruction>
        
        <!--xsl:processing-instruction name="xml-stylesheet-">
            <xsl:text>type="text/xsl" href="html-xsl.xsl"</xsl:text>
        </xsl:processing-instruction-->
        
        <xsl:apply-templates select="*"/>
        
    </xsl:template>

    <xsl:template match="xi:table[@extendable]/xi:columns/xi:column[@name='id']/@type" >
        <xsl:attribute name="type">string</xsl:attribute>
    </xsl:template>

    <xsl:template match="/*/@stage"/>
    
    <xsl:template match="@*[normalize-space() = '']"/>
    
    <xsl:template match="*[not(*|@*|text())]"/>

    <xsl:template match="*[@set-of][not(*[local-name()=../@set-of])]"/>

</xsl:transform>