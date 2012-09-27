<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns="http://www.w3.org/1999/xhtml"
>
 
    <xsl:template match="xi:grid">
        
        <xsl:variable name="this" select="."/>
        <xsl:variable name="colspan"
                      select="count($this/xi:columns/xi:column)+count($this//xi:option)+count($this/@deletable)"
        />
        
        <div id="{@id}">
            
            <xsl:attribute name="class">
                <xsl:text>grid</xsl:text>
                <xsl:if test="@accordeon">
                   <xsl:text> accordeon</xsl:text>
                </xsl:if>
            </xsl:attribute>
            
            <table class="grid">
                <thead>
                    
                    <xsl:apply-templates select="." mode="build-tools">
                        <xsl:with-param name="colspan" select="$colspan"/>
                    </xsl:apply-templates>
                    
                    <xsl:for-each select="@label">
                        <tr class="title">
                           <th colspan="{$colspan}">
                                
                                <a href="?set-of-{key('id',../@ref)/@name}=refresh" onclick="return menupad(this,false,false);">
                                    <xsl:value-of select="."/>
                                </a>
                                
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
                    <xsl:apply-templates select="xi:rows"/>
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
        </div>
    </xsl:template>

    <xsl:template match="*" mode="build-tools">
        <xsl:param name="colspan" />
        <tr class="tools" style="display:none">
            <td>
                <xsl:if test="$colspan">
                    <xsl:attribute name="colspan">
                        <xsl:value-of select="$colspan"/>
                    </xsl:attribute>
                </xsl:if>
                <a href="?pipeline=csv1251&amp;form={@ref}">csv</a>
            </td>
        </tr>
    </xsl:template>                    

    <xsl:template match="xi:column" mode="grid-totals">
         <xsl:if test="key('id',@ref)/@totals='sum'">
            <xsl:variable name="values" select="key('id',parent::*/parent::xi:grid/@top)//xi:datum[@ref=current()/@ref][text()!='']"/>
            <xsl:if test="$values">
               <xsl:value-of select="format-number(sum($values),'#,##0.00')"/>
            </xsl:if>
         </xsl:if>
    </xsl:template>

    <xsl:template match="xi:datum|xi:field" mode="grid-group">
        <xsl:param name="colspan"/>
        <xsl:param name="cnt"/>
        <xsl:param name="cnt-show"/>
        <tr class="group" name="{@name}">
            <xsl:for-each select="parent::xi:data/@removable">
                <td class="options">
                    <xsl:apply-templates select="."/>
                </td>
            </xsl:for-each>
            <td colspan="{$colspan}">
                <span><xsl:value-of select="."/></span>
                <xsl:if test="$cnt-show">
                    <span class="cnt">
                        <xsl:text>(</xsl:text>
                        <xsl:value-of select="$cnt"/>
                        <xsl:text>шт.)</xsl:text>
                    </span>
                </xsl:if>
            </td>
        </tr>
    </xsl:template>

    <xsl:template match="xi:data" mode="gridrow">
        
        <xsl:param name="columns"/>
        <xsl:param name="groups"/>
        
        <xsl:variable name="data" select="."/>
        <xsl:variable name="datas-prev" select="preceding::xi:data[@ref=current()/@ref]"/>
        <xsl:variable name="data-prev" select="$datas-prev[last()]"/>

        <xsl:for-each select="$groups">
            <xsl:for-each select="xi:by">
                <xsl:variable name="current-value" select="$data//xi:datum[@ref=current()/@ref]|$data/ancestor::xi:data/xi:datum[@ref=current()/@ref]"/>
                <xsl:variable name="prev-value" select="$data-prev//xi:datum[@ref=current()/@ref]|$data-prev/ancestor::xi:data/xi:datum[@ref=current()/@ref]"/>
                <xsl:if test="not($current-value = $prev-value)">
                    <xsl:apply-templates select="$current-value|key('id',@ref[not($current-value) and $prev-value])" mode="grid-group">
                        <xsl:with-param name="colspan" select="count($columns/xi:column|$columns/parent::xi:grid[@deletable]|key('id',$columns/parent::xi:grid/@id)[xi:option])"/>
                        <xsl:with-param name="cnt" select="count($data/following::xi:data[@ref=$data/@ref and (descendant::xi:datum|ancestor::xi:data/xi:datum)[@ref=current()/@ref][text()=($data//xi:datum|$data/ancestor::xi:data/xi:datum)[@ref=current()/@ref]]])+1"/>
                        <xsl:with-param name="cnt-show" select="$columns/../@accordeon"/>
                    </xsl:apply-templates>
                </xsl:if>
            </xsl:for-each>
        </xsl:for-each>
        
        <tr xi:id="{@id}">
            
            <xsl:attribute name="class">
                <xsl:value-of select="concat('data ',local-name(xi:exception),' ',local-name(@is-new), ' ', local-name(@delete-this))"/>
                <xsl:for-each select="$groups/../xi:class[$data//xi:datum[text()]/@ref=@ref or $data/ancestor::xi:data/xi:datum[text()]/@ref=@ref]">
                    <xsl:value-of select="concat(' ',@name)"/>
                </xsl:for-each>
            </xsl:attribute>
            
            <xsl:if test="$columns/parent::*[xi:option or xi:rows[xi:option]] or $columns/../@deletable">
                <td class="options">
                    <xsl:apply-templates select="@deletable|$columns/../xi:rows/xi:option">
                        <xsl:with-param name="option-value" select="$data/@id"/>
                    </xsl:apply-templates>
                </td>
            </xsl:if>
            
            <xsl:for-each select="$columns/xi:column">
                
                <xsl:variable name="datum"
                              select="$data//*[@ref=current()/@ref]
                                     |$data/ancestor::xi:data/xi:datum[@ref=current()/@ref]"
                />
                
                <td>
                    
                    <xsl:for-each select="@extra-style">
                        <xsl:attribute name="style">
                            <xsl:value-of select="."/>
                        </xsl:attribute>
                    </xsl:for-each>
                    
                    <xsl:attribute name="class">
                        <xsl:value-of select="normalize-space(concat(local-name(@modified),' text ',key('id',@ref)/@type))"/>
                    </xsl:attribute>
                    
                    <xsl:if test="$datum/@modified">
                        <xsl:attribute name="class">modified</xsl:attribute>
                    </xsl:if>
                    
                    <xsl:choose>
                        
                        <xsl:when test="@display-only and $datum/self::xi:datum">
                            <xsl:for-each select="$datum">
                                <xsl:call-template name="print"/>
                            </xsl:for-each>
                        </xsl:when>
                        
                        <xsl:when test="xi:navigate[$datum]">
                            <a>
                                <xsl:attribute name="href">
                                    <xsl:value-of select="concat('?views=',xi:navigate/@to)"/>
                                    <xsl:value-of select="concat('&amp;',xi:navigate/@ref,'=',$datum/@id)"/>
                                    <xsl:for-each select="key('id',xi:navigate/@ref)/xi:pass">
                                        <xsl:value-of select="concat('&amp;', @name, '=', $datum/ancestor::*/xi:datum[@ref=current()/@ref])"/>
                                    </xsl:for-each>
                                </xsl:attribute>
                                <xsl:for-each select="$datum">
                                    <xsl:call-template name="print"/>
                                </xsl:for-each>
                            </a>
                        </xsl:when>
                        
                        <xsl:otherwise>
                            <xsl:apply-templates select="$datum" mode="render"/>
                        </xsl:otherwise>
                        
                    </xsl:choose>
                    
                    <xsl:apply-templates select="*[not($datum)]">
                        <xsl:with-param name="data" select="$data"/>
                    </xsl:apply-templates>
                    
                </td>
                
                <xsl:for-each select="key('id',$datum/@ref)/xi:spin">
                    
                    <xsl:apply-templates select="." mode="render">
                        <xsl:with-param name="datum" select="$datum"/>
                    </xsl:apply-templates>
                    
                </xsl:for-each>
                
            </xsl:for-each>
            
        </tr>
        
    </xsl:template>

    <xsl:template match="xi:rows[@ref]">
        
        <xsl:for-each select="@clientData">
            <xsl:attribute name="class">clientData empty </xsl:attribute>
            <xsl:attribute name="id"><xsl:value-of select="."/></xsl:attribute>
        </xsl:for-each>
        
        <xsl:apply-templates select="
                    key('id',parent::xi:grid/@top)//xi:data
                    [not(@hidden)]
                    [not(ancestor::xi:set-of[@is-choise])]
                    [@ref=current()/@ref]
                " mode="gridrow"
        >
            
            <xsl:with-param name="columns" select="../xi:columns"/>
            <xsl:with-param name="groups" select="xi:group"/>
            
        </xsl:apply-templates>
        
    </xsl:template>

    <!--xsl:template match="xi:rows/xi:row">
        <xsl:apply-templates select="key('id',@ref)[1]">
            <xsl:with-param name="columns" select="ancestor::xi:grid/xi:columns"/>
        </xsl:apply-templates>
    </xsl:template-->

</xsl:stylesheet>
