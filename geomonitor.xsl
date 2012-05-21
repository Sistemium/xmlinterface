<?xml version="1.0" ?>
<xsl:transform version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns="http://unact.net/xml/xi"
 xmlns:xi="http://unact.net/xml/xi">
  
  
    <xsl:output method="xml" indent="no" encoding="utf-8"/>  

    <xsl:template match="*">
        <xsl:apply-templates select="*"/>
    </xsl:template>


    <xsl:template match="/*/xi:userinput">
        <xsl:variable name="entity" select="concat(../xi:session/@username,'@',@host)"/>
        <xsl:variable name="long" select="xi:command[@name='long']"/>
        <xsl:variable name="lat" select="xi:command[@name='lat']"/>
        <response>
            <xsl:value-of select="document(concat('https://asa0.unact.ru/geomonitor?entity=',$entity,'&amp;long=',$long,'&amp;lat=',$lat))"/>
        </response>
    </xsl:template>
 


</xsl:transform>
