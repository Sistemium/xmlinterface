<?xml version="1.0" ?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns="http://www.w3.org/1999/xhtml"
>

    <xsl:template match="xi:menu">
        <div>
            <xsl:attribute name="class">
                <xsl:value-of select="local-name()"/>
                <xsl:choose>
                    <xsl:when test="xi:option[@chosen] or following-sibling::xi:view">
                        <xsl:text> chosen</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text> not-chosen</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="not(xi:option)">
                    <xsl:text> empty</xsl:text>
                </xsl:if>
            </xsl:attribute>
            <!--xsl:apply-templates select="@name"/-->
            <xsl:if test="@label">
                <div class="title"><span><xsl:value-of select="@label"/></span></div>
            </xsl:if>
            <xsl:apply-templates />
        </div>
    </xsl:template>
    
    <xsl:template match="
        
        xi:views[xi:view]/xi:menu
        
        | xi:option[@disabled]
        | xi:choise/xi:option
            [xi:command [text()='next' or text()='unchoose']
                [not( @name =
                    ancestor::xi:view//xi:data
                        [@chosen][xi:set-of[@is-choise][count(*) > 1]]
                    /@name
                )]
            ]
        | xi:choise/xi:option
            [xi:command [
                    ancestor::xi:view/xi:view-schema//*/@name=@name
                    or ancestor::xi:view/xi:view-schema//*/@id=@ref
                ][not(
                    ancestor::xi:view/xi:view-data//*/@name=@name
                    or ancestor::xi:view/xi:view-data//*/@ref=@ref
                )]
            ]
        
    "/>

    
    <xsl:template match="xi:option | xi:data/@deletable | xi:data/@removable">
        <xsl:param name="option-value" select="@name"/>
        <div>
            <xsl:apply-templates select="@name|@chosen" />
            <xsl:attribute name="class">
                <xsl:value-of select="normalize-space(concat('option ',@advisor))"/>
                <xsl:for-each select="xi:command[@field]">
                   <xsl:if test="ancestor::xi:view/xi:view-data//*[not(ancestor::xi:set-of[@is-choise])]/xi:datum[@ref=current()/@ref and text()=current()/text()]">
                      <xsl:text> avoid</xsl:text>
                   </xsl:if>
                </xsl:for-each>
                <xsl:if test="descendant::xi:menu">
                    <xsl:text> submenu</xsl:text>
                </xsl:if>
                <xsl:if test="@chosen">
                    <xsl:text> chosen</xsl:text>
                </xsl:if>
                <xsl:if test="position()=1">
                    <xsl:text> first</xsl:text>
                </xsl:if>
            </xsl:attribute>
            <xsl:variable name="element">
                <xsl:choose>
                    <xsl:when test="/*/xi:userinput[@spb-agent or @ipad-agent]">input</xsl:when>
                    <xsl:otherwise>a</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:element name="{$element}">
                <xsl:apply-templates select="@id" />
                <xsl:attribute name="class">button</xsl:attribute>
                <xsl:attribute name="type">button</xsl:attribute>
                <!--xsl:attribute name="accesskey"><xsl:value-of select="count(preceding-sibling::xi:option)+1"/></xsl:attribute-->
                
                <xsl:if test="not(@iframe)">
                    <xsl:attribute name="href">
                        <xsl:text>?</xsl:text>
                        <xsl:apply-templates select="$userinput" mode="links"/>
                        <xsl:for-each select="ancestor-or-self::xi:option">
                            <xsl:value-of select="concat(parent::xi:menu/@name,@id[not(parent::xi:option[parent::xi:menu])]|@ref,'=',$option-value)"/>
                            <xsl:if test="@pipeline">
                                <xsl:value-of select="concat('&amp;pipeline=',@pipeline)"/>
                            </xsl:if>
                            <xsl:if test="position()!=last()">&amp;</xsl:if>
                            <xsl:if test="parent::xi:menu and position()=last() and position()=2" xi:attention="lazha">
                                <xsl:value-of select="concat('#the-',@name)"/>
                            </xsl:if>
                        </xsl:for-each>
                        <xsl:for-each select="parent::xi:data/@deletable">
                            <xsl:value-of select="concat(parent::xi:data/@id,'=delete')"/>
                        </xsl:for-each>
                        <xsl:for-each select="parent::xi:data/@removable">
                            <xsl:value-of select="concat(parent::xi:data/@id,'=remove')"/>
                        </xsl:for-each>
                    </xsl:attribute>
                </xsl:if>
                
                <xsl:if test="/*/xi:userinput/@spb-agent">
                    <xsl:attribute name="onfocus">return onFocus(this)</xsl:attribute>
                </xsl:if>
                
                <xsl:if test="$element='input'">
                    <xsl:attribute name="value">
                        <xsl:value-of select="@label"/>
                        <xsl:if test="parent::xi:data[@deletable or @removable]">x</xsl:if>
                    </xsl:attribute>
                </xsl:if>
                
                <xsl:attribute name="onclick">
                    <xsl:choose>
                        <xsl:when test="@iframe">
                            <xsl:text>location.replace(&apos;</xsl:text>
                            <xsl:value-of select="@iframe"/>
                            <xsl:text>&apos;)</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>return menupad(this</xsl:text>
                            <xsl:if test="ancestor::xi:view/@name">
                                <xsl:text>,&apos;</xsl:text>
                                <xsl:value-of select="concat(ancestor::xi:view/@name,'-form')"/>
                                <xsl:text>&apos;</xsl:text>
                            </xsl:if>
                            <xsl:text>)</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                
                <xsl:if test="$element='a'">
                    <xsl:attribute name="title">
                        <xsl:value-of select="@label"/>
                        <xsl:if test="parent::xi:data[@deletable or @removable]">x</xsl:if>
                    </xsl:attribute>
                    <span>
                        <xsl:value-of select="@label"/>
                        <xsl:if test="parent::xi:data[@deletable or @removable]">x</xsl:if>
                    </span>
                </xsl:if>
                
            </xsl:element>
            <xsl:apply-templates select="xi:menu|*/xi:menu" />
        </div>
    </xsl:template>
 
</xsl:transform>
