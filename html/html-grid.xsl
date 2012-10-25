<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns="http://www.w3.org/1999/xhtml"
>
 
    <xsl:include href="html-table.xsl"/>
    
    <xsl:template match="xi:grid">
        
        <xsl:param name="data" select="xi:null"/>
        <xsl:param name="top" select="@top[not($data)]|$data/@id"/>
        
        <xsl:variable name="this" select="."/>
        
        <div id="{@id}">
            
            <xsl:attribute name="class">
                <xsl:text>grid</xsl:text>
                <xsl:if test="@accordeon">
                   <xsl:text> accordeon</xsl:text>
                </xsl:if>
            </xsl:attribute>
            
            <xsl:choose>
                
                <xsl:when test="not($data) or $data//*[@name=current()/@form][xi:field|xi:data]">
                    <xsl:call-template name="build-table">
                        <xsl:with-param name="data" select="$data"/>
                        <xsl:with-param name="top" select="$top"/>
                    </xsl:call-template>
                </xsl:when>
                
                <xsl:when test="$data/@id or @build-preload">
                    <!--a type="button"
                       href="?{$data//xi:preload[@ref=current()/@ref]/@id}=refresh&amp;command=cleanUrl"
                       class="button ui-icon ui-icon-refresh"
                       onclick="return menupad(this,false,false);"
                    /-->
                </xsl:when>
                
            </xsl:choose>
            
        </div>
        
    </xsl:template>
    

    <xsl:template match="xi:rows[@ref]">
        
        <xsl:param name="top" select="parent::xi:grid/@top"/>
        
        <xsl:for-each select="@clientData">
            <xsl:attribute name="class">clientData empty </xsl:attribute>
            <xsl:attribute name="id"><xsl:value-of select="."/></xsl:attribute>
        </xsl:for-each>
        
        <xsl:apply-templates mode="gridrow" select="
            key('id',$top)//xi:data
                [not(@hidden)]
                [not(ancestor::xi:set-of[@is-choise])]
                [@ref=current()/@ref]
        ">
            
            <xsl:with-param name="columns" select="../xi:columns"/>
            <xsl:with-param name="groups" select="xi:group"/>
            
        </xsl:apply-templates>
        
    </xsl:template>
    

    <!--xsl:template match="xi:rows/xi:row">
        <xsl:apply-templates select="key('id',@ref)[1]">
            <xsl:with-param name="columns" select="ancestor::xi:grid/xi:columns"/>
        </xsl:apply-templates>
    </xsl:template-->
    

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
                
                <span>
                    <xsl:if test="key('id',@ref)/@type='boolean'">
                        <xsl:apply-templates select="." mode="label"/>
                        <xsl:text> - </xsl:text>
                    </xsl:if>
                    <xsl:apply-templates select="key('id',@ref)" mode="render-value">
                        <xsl:with-param name="value" select="."/>
                    </xsl:apply-templates>
                </span>
                
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
                
                <xsl:variable name="current-value" select="
                    $data//xi:datum[@ref=current()/@ref]|$data/ancestor::xi:data/xi:datum[@ref=current()/@ref]
                "/>
                <xsl:variable name="prev-value" select="
                    $data-prev//xi:datum[@ref=current()/@ref]|$data-prev/ancestor::xi:data/xi:datum[@ref=current()/@ref]
                "/>
                
                <xsl:if test="not($current-value = $prev-value)">
                    <xsl:apply-templates mode="grid-group" select="
                        $current-value
                        | key( 'id', @ref [not($current-value) and $prev-value] )
                    ">
                        <xsl:with-param name="colspan" select="
                            count(
                                $columns/xi:column
                                | $columns/parent::xi:grid [@deletable]
                                | key('id',$columns/parent::xi:grid/@id) [xi:option]
                            )
                        "/>
                        <xsl:with-param name="cnt" select="
                            count(
                                $data/following::xi:data
                                    [@ref=$data/@ref
                                        and ( descendant::xi:datum | ancestor::xi:data/xi:datum )
                                            [@ref=current()/@ref]
                                            [text()=($data//xi:datum|$data/ancestor::xi:data/xi:datum) [@ref=current()/@ref] ]
                                    ])+1
                        "/>
                        <xsl:with-param name="cnt-show" select="
                            $columns/../@accordeon
                        "/>
                    </xsl:apply-templates>
                </xsl:if>
                
            </xsl:for-each>
        </xsl:for-each>
        
        <tr xi:id="{@id}">
            
            <xsl:attribute name="class">
                
                <xsl:value-of select="concat('data ',local-name(xi:exception),' ',local-name(@is-new), ' ', local-name(@delete-this))"/>
                
                <xsl:for-each select="$groups/../xi:class">
                    <xsl:variable name="class-datum" select="
                        $data//xi:datum [text()] [@ref=current()/@ref]
                        | $data/ancestor::xi:data/xi:datum[text()][@ref=current()/@ref]
                    "/>
                    <xsl:if test="$class-datum">
                        <xsl:value-of select="concat(' ', @name | $class-datum[not(current()/@name)])"/>
                    </xsl:if>
                </xsl:for-each>
                
            </xsl:attribute>
            
            <xsl:if test="$columns/parent::*[xi:option or xi:rows[xi:option]] or $columns/../@deletable">
                <td class="options">
                    <xsl:apply-templates select="self::*[not(@toggle-edit-off) or @is-new]/@deletable|$columns/../xi:rows/xi:option">
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
    

</xsl:stylesheet>