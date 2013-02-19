<?xml version="1.0" ?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://unact.net/xml/xi"
    xmlns:xi="http://unact.net/xml/xi"
    exclude-result-prefixes="xi">

    <xsl:param name="model" select="document(/*/xi:session/xi:domains/xi:domain/@href)/xi:domain/xi:concept"/>

    <xsl:include href="../id.xsl"/>
    <xsl:variable name="lcletters">abcdefghijklmnopqrstuvwxyz</xsl:variable>
    <xsl:variable name="ucletters">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
    
    <xsl:template match="xi:view-data | xi:display"/>

    <xsl:template match="xi:field[not(@alias)]" mode="extend">
        <xsl:attribute name="alias"><xsl:value-of select="@name"/></xsl:attribute>
    </xsl:template>
    
    <xsl:template match="xi:form[not(@hidden)]/xi:form" mode="extend">
        <xsl:variable name="form" select="."/>
        <xsl:for-each select="$model[@name=current()/@concept]
                             [not(xi:role[@name = current()/xi:field/@name and @actor=current()/parent::xi:form/@concept])]
                             /xi:role[not(@name = current()/xi:field/@name) and @actor=current()/parent::xi:form/@concept]">
            <field name="{@actor}">
                <xsl:attribute name="alias">
                    <xsl:value-of select="translate($form/../@name,$ucletters,$lcletters)"/>
                </xsl:attribute>
                <xsl:apply-templates select="$form/../xi:field[@name='id']/@type"/>
                <xsl:if test="not($form/xi:field[@name='id'])">
                    <xsl:attribute name="key">true</xsl:attribute>
                </xsl:if>
            </field>
        </xsl:for-each>
    </xsl:template>

</xsl:transform>