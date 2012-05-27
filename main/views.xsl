<?xml version="1.0" ?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://unact.net/xml/xi"
    xmlns:xi="http://unact.net/xml/xi"
 >

    <xsl:include href="security.xsl"/>
    <xsl:include href="view-definition.xsl"/>
    <xsl:include href="context-extension.xsl"/>
 
    <xsl:template match="xi:context[xi:session[@authenticated] and not(xi:views)]">
        <xsl:param name="pipeline" select="/*/@pipeline-name"/>
        <xsl:copy>
            <xsl:copy-of select="@*|*"/>
            <xsl:apply-templates select="document(/*/@init-file)/*/xi:context-extension/xi:views"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="xi:views/xi:view[@name=../xi:menu/xi:option[@chosen]/@name]/@hidden"/>
    
    <xsl:template match="xi:views[xi:menu/xi:option[@chosen]]/xi:view[not(@name=../xi:menu/xi:option[@chosen]/@name)]" mode="extend">
        <xsl:attribute name="hidden">true</xsl:attribute>
    </xsl:template>

    <!--xsl:template match="xi:context-extension/xi:views[count(xi:menu/xi:option)=1]/xi:menu">
        <xsl:apply-templates select="document(xi:option/@href)"/>
    </xsl:template-->
  
    <xsl:template match="xi:views[xi:menu/xi:option[@chosen]]">
        <xsl:copy>
            <xsl:apply-templates select="@*|*[not(self::xi:view)]"/>
            <xsl:for-each select="xi:menu/xi:option[@chosen]">
                <xsl:variable name="alreadyOpen" select="../../xi:view[@name=current()/@name]"/>
                <xsl:apply-templates select="document(@href[not($alreadyOpen)])|$alreadyOpen" mode="build-secure"/>
            </xsl:for-each>
            <xsl:apply-templates select="xi:view[not(@name=../xi:menu/xi:option[@chosen]/@name)]"/>
        </xsl:copy>
    </xsl:template>


</xsl:transform>
