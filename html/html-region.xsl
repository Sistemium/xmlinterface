<?xml version="1.0" ?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns="http://www.w3.org/1999/xhtml"
>

    <xsl:template match="xi:dialogue//xi:region">
        
        <xsl:param name="data" select="xi:null"/>
        
        <div>
            
            <xsl:attribute name="class">
                <xsl:text>region </xsl:text>
                <xsl:value-of select="concat(' ',@name, ' ',local-name(@collapsable), ' ', @class)"/>
                <xsl:if test="descendant::*[@clientData]">
                    <xsl:text> ajaxloading</xsl:text>
                </xsl:if>
            </xsl:attribute>
            
            <xsl:copy-of select="@id"/>
            
            <xsl:choose>
                <xsl:when test="@collapsable">
                    <div class="label">
                        <xsl:apply-templates select="@label" mode="build-text">
                            <xsl:with-param name="class">collapsed-label</xsl:with-param>
                        </xsl:apply-templates>
                        <xsl:apply-templates select="@expanded-label|@label[not(../@expanded-label)]" mode="build-text">
                            <xsl:with-param name="class">expanded-label</xsl:with-param>
                        </xsl:apply-templates>
                    </div>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="@label" mode="build-text"/>
                </xsl:otherwise>
            </xsl:choose>
            
            <xsl:if test="self::*[@class='tabs']">
                <xsl:call-template name="build-tabs"/>
            </xsl:if>
            
            <xsl:apply-templates>
                <xsl:with-param name="data" select="$data"/>
            </xsl:apply-templates>
            
        </div>
        
    </xsl:template>


    <xsl:template name="build-tabs">
        <ul>
            <xsl:for-each select="*[@id]">
                <li>
                    <a href="#{@id}">
                        <xsl:choose>
                            <xsl:when test="@label">
                                <xsl:value-of select="@label"/>
                            </xsl:when>
                            <xsl:when test="key('id',@ref)/@label">
                                <xsl:value-of select="key('id',@ref)/@label"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="position()"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </a>
                    <xsl:if test="self::xi:grid/@refreshable">
                        <a type="button"
                           href="?set-of-{@form}=refresh&amp;command=cleanUrl"
                           class="button ui-icon ui-icon-refresh"
                           onclick="return menupad(this,false,false);"
                        />
                    </xsl:if>
                </li>
            </xsl:for-each>
        </ul>
    </xsl:template>
    
    
    <xsl:template match="xi:dialogue//xi:tabs">
        <xsl:param name="data" select="xi:null"/>
        <div class="tabs">
            <xsl:call-template name="build-tabs"/>
            <xsl:apply-templates>
                <xsl:with-param name="data" select="$data"/>
            </xsl:apply-templates>
        </div>
    </xsl:template>
    
    <xsl:template match="xi:region[@class='tabs']/xi:region/@label" mode="build-text" />

</xsl:transform>
