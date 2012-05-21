<?xml version="1.0" ?>
<xsl:transform version="1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns="http://unact.net/xml/xi"
   xmlns:xi="http://unact.net/xml/xi"
>

    <xsl:param name="model" select="document('domain.xml')/xi:domain"/>

    <xsl:include href="id.xsl"/>

    <xsl:template match="comment()|processing-instruction()"/>

    <xsl:template match="xi:context">
        <recognition>
            <xsl:apply-templates select="xi:userinput"/>
        </recognition>
    </xsl:template>

    <xsl:template match="xi:recognition">
        <extending>
            <xsl:apply-templates />
        </extending>
    </xsl:template>

    <xsl:template match="xi:extending">
        <extended>
            <xsl:copy-of select="xi:extention/@*"/>
            <xsl:apply-templates />
        </extended>
    </xsl:template>

    <xsl:template match="xi:extended">
        <processed>
            <xsl:copy-of select="@id"/>
            <xsl:apply-templates />
        </processed>
    </xsl:template>


    <xsl:template match="xi:userinput">
            <xsl:for-each select="key('id',xi:command[@name='preload'])">
                <xsl:copy-of select="ancestor::xi:view/xi:view-schema
                                    |ancestor::xi:view/xi:dialogue//*[*[@clientData=current()/@id]]
                                    "/>
                <extention>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates select="." mode="build-request">
                         <xsl:with-param name="head">true</xsl:with-param>
                    </xsl:apply-templates>
                </extention>
            </xsl:for-each>
    </xsl:template>

    <xsl:template match="xi:processed/xi:view-schema
                        |xi:processed/xi:data
                        |xi:sql
                        "/>

    
    <xsl:template match="xi:extention[xi:response/xi:result-set]">
        <xsl:apply-templates select="key('id',@ref)" mode="build-data">
            <xsl:with-param name="data" select="xi:response/xi:result-set/*"/>
        </xsl:apply-templates>
    </xsl:template>
    


</xsl:transform>