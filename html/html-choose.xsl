<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns="http://www.w3.org/1999/xhtml"
>
 
    <xsl:template match="xi:dialogue/xi:choose">
        <xsl:variable name="top" select="key('id',key('id',@ref)/@ref)"/>
        <div class="choose">
            <div class="exception">
                <span><xsl:value-of select="concat('Уточните [',@what-label,']')"/></span>
            </div>
            <xsl:if test="$top[@expect-choise='optional']">
                <div class="option ignore">
                    <label for="{@id}-ignore">
                        <xsl:text>Все доступные</xsl:text>
                    </label>
                    <input type="radio" class="radio" id="{@id}-ignore" value="ignore" name="{@ref}">
                        <xsl:attribute name="onclick">
                            <xsl:text>this.form.submit()</xsl:text>
                        </xsl:attribute>
                        <xsl:if test="/*/xi:userinput/@spb-agent">
                            <xsl:attribute name="onfocus">return onFocus(this)</xsl:attribute>
                        </xsl:if>
                    </input>
                </div>
            </xsl:if>
            <xsl:for-each select="key('id',@ref)/xi:set-of/xi:data">
                <div class="option">
                    <label for="{@id}">
                        <xsl:value-of select="xi:datum[@name='name']"/>
                    </label>
                    <input type="radio" class="radio" id="{@id}" value="{@id}" name="{../../@id}">
                        <xsl:attribute name="onclick">
                            <xsl:text>this.form.submit()</xsl:text>
                        </xsl:attribute>
                        <xsl:if test="/*/xi:userinput/@spb-agent">
                            <xsl:attribute name="onfocus">return onFocus(this)</xsl:attribute>
                        </xsl:if>
                    </input>
                </div>
            </xsl:for-each>
        </div>
    </xsl:template>

    <xsl:template match="xi:dialogue/xi:choose[@choise-style='table']" name="table-choise">
        <xsl:variable name="top" select="key('id',key('id',@ref)/@ref)"/>
        <xsl:variable name="column"
                      select="$top/descendant-or-self::xi:form
                                [(@no-preload or @id=$top/@id
                                    ) and not(
                                 ancestor-or-self::xi:form[@is-set][ancestor-or-self::xi:form/@id=$top/@id])]/xi:field
                                 [@label][not(@hidden or @editable or @xpath-compute)]"/>
        <table class="choose">
            <thead>
                <tr class="exception">
                    <th colspan="{count($column)+1}"><xsl:value-of select="concat('Уточните [',@what-label,']')"/></th>
                </tr>
                <tr>
                    <xsl:for-each select="$column">
                        <th><xsl:value-of select="@label"/></th>
                    </xsl:for-each>
                </tr>
            </thead>
            <tbody>
                <xsl:if test="$top[@expect-choise='optional']">
                    <tr class="option ignore">
                        <td colspan="{count($column)}">
                            <xsl:text>Все доступные</xsl:text>
                        </td>
                        <td>
                            <input type="radio" class="radio" id="{@id}-ignore" value="ignore" name="{@ref}">
                                <xsl:attribute name="onclick">
                                    <xsl:text>this.form.submit()</xsl:text>
                                </xsl:attribute>
                                <xsl:if test="/*/xi:userinput/@spb-agent">
                                    <xsl:attribute name="onfocus">return onFocus(this)</xsl:attribute>
                                </xsl:if>
                            </input>
                        </td>
                    </tr>
                </xsl:if>
                <xsl:for-each select="key('id',@ref)/xi:set-of[@is-choise]/xi:data">
                    <xsl:variable name="currentOption" select="."/>
                    <tr class="option">
                        <xsl:for-each select="$column">
                            <td>
                                <xsl:attribute name="class">
                                    <xsl:value-of select="concat('text ',@type)"/>
                                </xsl:attribute>
                                <xsl:for-each select="$currentOption/descendant::xi:datum[@ref=current()/@id]">
                                    <xsl:call-template name="print"/>
                                </xsl:for-each>
                            </td>
                        </xsl:for-each>
                        <td>
                            <input type="radio" class="radio" id="{@id}" value="{@id}" name="{../../@id}">
                                <xsl:attribute name="onclick">
                                    <xsl:text>this.form.submit()</xsl:text>
                                </xsl:attribute>
                                <xsl:if test="/*/xi:userinput/@spb-agent">
                                    <xsl:attribute name="onfocus">return onFocus(this)</xsl:attribute>
                                </xsl:if>
                            </input>
                        </td>
                    </tr>
                </xsl:for-each>
            </tbody>
        </table>
    </xsl:template>

    
</xsl:stylesheet>
