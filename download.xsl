<?xml version="1.0" ?>
<xsl:transform version="1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns="http://unact.net/xml/xi"
   xmlns:xi="http://unact.net/xml/xi"
>
    <xsl:key name="id" match="*" use="@id"/>
    
    <xsl:template match="/*/*"/>

    <xsl:template match="/*/xi:userinput">
        <download>
            <xsl:copy-of select="/*/@*"/>
            <xsl:for-each select="xi:command[@name='datum']">
                
                <xsl:variable name="model" select="document('domain.xml')/xi:domain"/>
                <xsl:variable name="datum" select="key('id',text())"/>
                <xsl:variable name="form" select="key('id',$datum/../@ref)"/>
                <xsl:variable name="concept" select="$model/xi:concept[@name=$form/@concept]"/>
                
                <data-request name="{$form/@name}" concept="{$concept/@name}">
                    <xsl:copy-of select="$concept/@*"/>
                    <column name="{$datum/@name}" type="file"/>
                    <parameter name="xid" property="xid"><xsl:value-of select="$datum/../xi:datum[@name='xid']"/></parameter>
                </data-request>
                
            </xsl:for-each>
        </download>
    </xsl:template>

    <xsl:template match="xi:download[*/xi:result-set]">
        <xsl:value-of select="*/xi:result-set"/>
    </xsl:template>
   
</xsl:transform>