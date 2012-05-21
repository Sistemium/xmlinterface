<?xml version="1.0" ?>
<xsl:transform version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns="http://unact.net/xml/xi"
 xmlns:xi="http://unact.net/xml/xi"
 xmlns:dyn="http://exslt.org/dynamic"
 exclude-result-prefixes="dyn"
 extension-element-prefixes="dyn"
 >


   <xsl:template match="@synthesize-attributes">
      <xsl:for-each select="../xi:synthesize[@attribute]">
         <xsl:variable name="precompute" select="dyn:evaluate(@xpath-precompute)"/>
         <xsl:attribute name="{@attribute}">
            <xsl:value-of select="dyn:evaluate(@xpath-compute)"/>
         </xsl:attribute>
      </xsl:for-each>
      <xsl:copy/>
   </xsl:template>


</xsl:transform>