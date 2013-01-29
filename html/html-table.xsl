<?xml version="1.0" ?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns="http://www.w3.org/1999/xhtml"
>

    <xsl:template name="build-table">
        
        <xsl:param name="data" select="xi:null"/>
        <xsl:param name="top" select="xi:null"/>
        
        <table class="grid">
            
            <xsl:variable name="colspan" select="
                count(xi:columns/xi:column)
                +count(descendant::xi:option)
                +count(@deletable)
            "/>
                
            <thead>
                
                <xsl:apply-templates select="." mode="build-tools">
                    <xsl:with-param name="colspan" select="$colspan"/>
                </xsl:apply-templates>
                
                <xsl:for-each select="@label">
                    <tr class="title">
                       <th colspan="{$colspan}">
                            
                            <span>
                                <xsl:value-of select="."/>
                            </span>
                            
                            <xsl:if test="ancestor::xi:grid[1]/@refreshable">
                                <a type="button"
                                   href="?set-of-{key('id',../@ref)/@name}=refresh&amp;command=cleanUrl"
                                   class="button"
                                   onclick="return menupad(this,false,false);"
                                ><span class="ui-icon ui-icon-refresh"/></a>
                            </xsl:if>
                            
                            <xsl:if test="key('id',../@ref)/@toggle-edit-off">
                                <a type="button" href="?{key('id',../@ref)/@name}=toggle-edit&amp;command=cleanUrl"
                                   class="button ui-icon ui-icon-pencil" onclick="return menupad(this,false,false);"/>
                            </xsl:if>
                       </th>
                    </tr>
                </xsl:for-each>
                <tr class="header">
                    <xsl:if test="descendant::xi:option or @deletable">
                        <th class="options">
                            <xsl:apply-templates select="xi:option"/>
                        </th>
                    </xsl:if>
                    <xsl:for-each select="xi:columns/xi:column">
                        <th>
                            <span><xsl:apply-templates select="." mode="label"/></span>
                        </th>
                    </xsl:for-each>
                </tr>
            </thead>
            
            <tbody>
                <xsl:apply-templates select="xi:rows">
                    <xsl:with-param name="top" select="$top"/>
                </xsl:apply-templates>
            </tbody>
            
            <tfoot>
                <xsl:variable name="totals-footer">
                    <tr class="footer">
                        <xsl:if test="xi:option or @deletable">
                            <th/>
                        </xsl:if>
                        <xsl:for-each select="xi:columns/xi:column">
                            <th>
                                <span>
                                    <xsl:apply-templates select="." mode="class"/>
                                    <xsl:apply-templates select="." mode="grid-totals"/>
                                </span>
                            </th>
                        </xsl:for-each>
                    </tr>
                </xsl:variable>
                
                <xsl:if test="string-length(normalize-space($totals-footer))>0">
                    <xsl:copy-of select="$totals-footer"/>
                </xsl:if>
                
                <xsl:if test="xi:page-control[not(xi:final-page)]">
                    <tr class="page-control">
                        <th colspan="{$colspan}">
                            <xsl:for-each select="xi:page-control">
                                <!--xsl:if test="position()=1">
                                    <span><a class="button" href="?{@ref}=prev&amp;command=cleanUrl">&lt;</a></span>
                                </xsl:if-->
                                <a class="button" href="?{@ref}=refresh&amp;command=cleanUrl">
                                    <xsl:if test="@visible"><span><xsl:text>Страница </xsl:text></span></xsl:if>
                                    <span><xsl:value-of select="@page-start + 1"/></span>
                                </a>
                                <xsl:if test="position()=last() and not(xi:final-page)">
                                    <span><a class="button" href="?{@ref}=next&amp;command=cleanUrl">&gt;</a></span>
                                </xsl:if>
                            </xsl:for-each>
                        </th>
                    </tr>
                </xsl:if>
                
                <xsl:apply-templates select="." mode="build-tools">
                    <xsl:with-param name="colspan" select="$colspan"/>
                </xsl:apply-templates>
                
            </tfoot>
        </table>
    </xsl:template>

</xsl:transform>
