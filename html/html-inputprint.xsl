<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns="http://www.w3.org/1999/xhtml"
>

    <xsl:template match="xi:input|xi:print">
        
        <xsl:param name="data" select="xi:null"/>
        
        <xsl:variable name="datum"
            select="key( 'id', self::*[not($data)]/@ref
                    |$data/descendant::*[@ref=current()/@ref]/@id
                    |$data/ancestor::*/xi:datum[@ref=current()/@ref]/@id
            )"
        />
        
        <xsl:apply-templates select="self::xi:input | self::xi:print[$datum/node()]" mode="render">
            <xsl:with-param name="datum" select="$datum"/>
            <xsl:with-param name="elem">
                <xsl:choose>
                    <xsl:when test="parent::xi:by">span</xsl:when>
                    <xsl:otherwise>div</xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:apply-templates>
        
    </xsl:template>
    
    
    <xsl:template match="xi:input|xi:print" mode="render">
        
        <xsl:param name="datum" select="xi:null"/>
        <xsl:param name="elem">div</xsl:param>
        
        <xsl:element name="{$elem}">
            <xsl:attribute name="class">
                <xsl:text>datum </xsl:text>
                <xsl:value-of select="normalize-space(concat(
                    local-name(.),' ',
                    @name,' ',
                    local-name($datum/@modified),' ',
                    @class
                ))"/>
            </xsl:attribute>
            
            <xsl:for-each select="@extra-style">
                <xsl:attribute name="style">
                    <xsl:value-of select="."/>
                </xsl:attribute>
            </xsl:for-each>
            
            <xsl:if test="ancestor::xi:region | ancestor::xi:tabs">
                <xsl:attribute name="id">
                    <xsl:value-of select="@id"/>
                </xsl:attribute>
            </xsl:if>
            
            <xsl:choose> <!-- build label -->
                
                <xsl:when test="parent::xi:tabs|self::xi:print[key('id',@ref)/@format='true-only' and not($datum/text())]"/>
                
                <xsl:when test="/*/xi:userinput/@spb-agent and $datum/self::xi:data[@choise and not(@chosen)]">
                    <div>
                        <span><xsl:apply-templates select="$datum[1]" mode="label"/></span>
                        <span class="colon"><xsl:text>:</xsl:text></span>               
                    </div>
                </xsl:when>
                
                <xsl:otherwise>
                    <label for="{@ref}">
                        <span><xsl:apply-templates select="self::*[@label] | $datum[not(current()/@label)][1]" mode="label"/></span>
                        <span class="colon">
                            <xsl:text>:</xsl:text>
                            <xsl:if test="ancestor-or-self::*[@colon-space]">
                                <xsl:text> </xsl:text>
                            </xsl:if>
                        </span>               
                    </label>
                </xsl:otherwise>
                
            </xsl:choose>
            
            <xsl:if test="self::xi:exists">
                <span>
                    <xsl:choose>
                        <xsl:when test="$datum/*[@name=current()/@child]">
                            <xsl:text>Есть </xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="class">exception</xsl:attribute>
                            <xsl:text>Нет </xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:apply-templates select="key('id',$datum/@ref)/*[@name=current()/@child]" mode="label"/>
                </span>
            </xsl:if>
            
            <xsl:choose>
                
                <xsl:when test="self::xi:input[xi:by]">
                    <xsl:variable name="by" select="xi:by"/>
                    
                    <xsl:for-each select="ancestor::xi:view[1] / xi:view-data//xi:set-of
                        [@ref = key('id',$by/@ref)/parent::*/@id ]
                    ">
                        <xsl:call-template name="input">
                            <xsl:with-param name="id" select="$datum/@id"/>
                            <xsl:with-param name="element">select</xsl:with-param>
                            <xsl:with-param name="by" select="$by"/>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:when>
                
                <xsl:when test="
                    self::xi:input [not(@noforward)
                        and not(following-sibling::xi:input
                            or following-sibling::xi:region/xi:input
                            or parent::xi:region/following-sibling::xi:region/xi:input
                            or ($datum[not(@type='parameter')] and following-sibling::xi:grid)
                        )
                    ]
                ">
                    <xsl:apply-templates select="$datum" mode="render">
                        <xsl:with-param name="command">forward</xsl:with-param>
                    </xsl:apply-templates>
                </xsl:when>
                
                <xsl:otherwise>
                    <xsl:apply-templates select="key('id',self::xi:input/@ref)" mode="render"/>
                </xsl:otherwise>
                
            </xsl:choose>
            
            <xsl:for-each select="key('id',self::xi:input/@ref)[@type='parameter'][text()][not(@modified)]">
                <a type="button"
                   class="button"
                   href="?{parent::xi:data/@id}=refresh&amp;command=cleanUrl"
                   onclick="return menupad(this,false,false);"
                > <span class="ui-icon ui-icon-refresh"/>
                </a>

            </xsl:for-each>
            
            <xsl:for-each select="$datum[current()/self::xi:print/@ref]">
                <xsl:call-template name="print"/>
            </xsl:for-each>
            
        </xsl:element>
        
    </xsl:template>

    <xsl:template match="xi:datum | xi:data[@delete-this or @toggle-edit-off]/xi:data[@choise]" mode="render" name="print">
        
        <xsl:param name="element">
            <xsl:choose>
                <xsl:when test="self::xi:datum[key('id',@ref)/@type='xml']">
                    <xsl:text>div</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>span</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:param>
        
        <xsl:param name="value">
            <xsl:apply-templates select="key('id',@ref)" mode="render-value">
                <xsl:with-param name="value"
                                select="self::xi:datum
                                       |self::xi:data/xi:datum[@name='name']"/>
            </xsl:apply-templates>
        </xsl:param>
        
        <xsl:if test="not(key('id',@ref)/@format='true-only' and string-length(normalize-space($value))=0)">
            <xsl:element name="{$element}">
                
                <xsl:if test="@xpath-compute">
                   <xsl:attribute name="id">
                      <xsl:value-of select="@id"/>
                   </xsl:attribute>
                </xsl:if>
                
                <xsl:apply-templates select="." mode="class"/>
                
                <xsl:copy-of select="$value"/>
                
            </xsl:element>
        </xsl:if>
        
    </xsl:template>


    <xsl:template mode="render" name="input" match="
        xi:data [not(@delete-this)]
            /xi:datum [@editable]
        |
        xi:data [not(@delete-this or @toggle-edit-off)]
            /xi:data [@choise]
        |
        xi:view-data/xi:data
            [@choise]
    ">
        
        <xsl:param name="id" select="@id"/>
        <xsl:param name="command" />
        <xsl:param name="element">
            <xsl:choose>
                <xsl:when test="/*/xi:userinput/@spb-agent and self::xi:data[@choise and not(@chosen)]">option</xsl:when>
                <xsl:when test="self::xi:data">select</xsl:when>
                <xsl:when test="self::xi:datum[key('id',@ref)/@type='text']">textarea</xsl:when>
                <xsl:otherwise>input</xsl:otherwise>
            </xsl:choose>
        </xsl:param>
        <xsl:param name="by" select="xi:by"/>
        
        <xsl:variable name="this" select="."/>
        <xsl:variable name="file-name" select="self::xi:datum[@editable='file']/../xi:datum[@editable='file-name']/@id"/>
        <xsl:variable name="def" select="key('id',@ref)"/>
        
        <span>
            <xsl:apply-templates select="self::*[not($by)]" mode="class"/>
            <xsl:choose>
                <xsl:when test="$def/@type='boolean'">
                    <span class="bool">
                        <input type="radio" name="{$id}" id="{concat($id,'-1')}" value="1" onclick="this.form.submit()" >
                            <xsl:if test="text()='1'">
                                <xsl:attribute name="checked">checked</xsl:attribute>
                            </xsl:if>
                        </input>
                        <label for="{concat($id,'-1')}">
                            <xsl:choose>
                                <xsl:when test="$def[@true-only and @true-only-label] and not(text()='1')">
                                    <xsl:value-of select="$def/@true-only-label"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>Да</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </label>
                    </span>
                    <xsl:if test="not($def/@true-only and text()='1')">
                        <span class="bool">
                            <input type="radio" name="{$id}" id="{concat($id,'-0')}" value="0" onclick="this.form.submit()">
                                <xsl:if test="text()!='1'">
                                    <xsl:attribute name="checked">checked</xsl:attribute>
                                </xsl:if>
                            </input>
                            <label for="{concat($id,'-0')}">Нет</label>
                        </span>
                    </xsl:if>
                    <xsl:if test="$def/self::xi:parameter[@optional]">
                        <span class="bool">
                            <input type="radio" name="{$id}" id="{concat($id,'-c')}" value="" onclick="this.form.submit()">
                                <xsl:if test="not(text())">
                                    <xsl:attribute name="checked">checked</xsl:attribute>
                                </xsl:if>
                            </input>
                            <label for="{concat($id,'-c')}">Не  важно</label>
                        </span>
                    </xsl:if>
                </xsl:when>
        
                <xsl:when test="$element='option'">
                    <xsl:for-each select="
                        self::* [@choise] [not(xi:set-of[@is-choise])]
                            /ancestor::xi:view-data
                            //xi:data [@name=current()/@choise]
                        |xi:set-of [@is-choise] [@id=current()/@choise]
                            /*
                    ">
                        <div class="option">
                            <label for="{@id}">
                                <xsl:value-of select="@label|self::*[not(@label)]/xi:datum[@name='name']"/>
                                <xsl:text>:</xsl:text>
                            </label>
                            <input class="focusable" type="radio" name="{$id}" id="{@id}" onclick="this.form.submit()">
                                <xsl:if test="$this/@chosen=@id">
                                    <xsl:attribute name="checked">checked</xsl:attribute>
                                </xsl:if>
                                <xsl:attribute name="onfocus">return onFocus(this)</xsl:attribute>
                                <xsl:attribute name="value">
                                    <xsl:value-of select="@id"/>
                                </xsl:attribute>
                           </input>
                        </div>
                    </xsl:for-each>
                </xsl:when>
    
                <xsl:otherwise>
                    <xsl:element name="{$element}">
                        <xsl:if test="/*/xi:userinput/@spb-agent or not (self::xi:datum[@type='field']) or self::xi:data[xi:set-of[@is-choise]]">
                            <xsl:attribute name="name"><xsl:value-of select="$id"/></xsl:attribute>
                        </xsl:if>
                        <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
                        
                        <xsl:if test="parent::xi:data/@delete-this">
                            <xsl:attribute name="disabled">disabled</xsl:attribute>
                        </xsl:if>
                        
                        <xsl:choose>
                            
                            <xsl:when test="self::xi:data | self::xi:set-of">
                                
                                <xsl:attribute name="onchange">
                                    <xsl:choose>
                                        <xsl:when test="/*/xi:userinput/@spb-agent or xi:set-of[@is-choise]">this.form.submit()</xsl:when>
                                        <xsl:otherwise>
                                            <xsl:text>return selectChanged(this)</xsl:text>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>
                                
                                <xsl:attribute name="onfocus">return onFocus(this)</xsl:attribute>
                                
                                <xsl:if test="self::xi:data[not(@chosen)] or key('id',@ref)/@unchoosable">
                                    <option value="unchoose">(Значение не указано)</option>
                                </xsl:if>
                                
                                <xsl:if test="key('id',@ref)/@expect-choise='optional'">
                                    <option value="ignore">(Все доступные)</option>
                                </xsl:if>
                                
                                <xsl:for-each select="
                                    self::node()
                                        [@choise] [not(xi:set-of[@is-choise])]
                                    /ancestor::xi:view-data
                                    //xi:data
                                        [@name=current()/@choise]
                                        [not(ancestor::xi:set-of[@is-choise])]
                                    |
                                    xi:set-of
                                        [@is-choise] [@id=current()/@choise]
                                    /xi:data
                                    |
                                    self::xi:set-of [$by] /xi:data
                                ">
                                    <option value="{@id[not($by)] | xi:datum[@ref=$by/@ref]}">
                                        
                                        <xsl:if test="$this/@chosen=@id or ($by and xi:datum[@ref=$by/@ref] = $id/parent::*)">
                                            <xsl:attribute name="selected">selected</xsl:attribute>
                                        </xsl:if>
                                        
                                        <xsl:value-of select="@label|self::*[not(@label)]/xi:datum[@name='name']"/>
                                        
                                   </option>
                                </xsl:for-each>
                                
                            </xsl:when>
                            
                            <xsl:otherwise>
                                
                                <xsl:attribute name="type">
                                    <xsl:choose>
                                        <xsl:when test="key('id',@ref)/@type='file'">file</xsl:when>
                                        <xsl:when test="/*/xi:userinput/@ipad-agent and key('id',@ref)[@type='int' or @type='decimal']">number</xsl:when>
                                        <xsl:otherwise>text</xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>
                                
                                <xsl:attribute name="class">
                                    <xsl:value-of select="normalize-space(concat(local-name(@modified),' ',key('id',@ref)/@type))"/>
                                    <xsl:if test="not(key('id',@ref)/@type='file')">
                                        <xsl:text> text</xsl:text>
                                    </xsl:if>
                                    <xsl:if test="$command">
                                        <xsl:text> option-forward</xsl:text>
                                    </xsl:if>
                                </xsl:attribute>
                                
                                <xsl:if test="$id=''">
                                    <xsl:attribute name="name">
                                        <xsl:value-of select="local-name()" />
                                    </xsl:attribute>
                                </xsl:if>
                                
                                <xsl:if test="$id='password' or @editable='password'">
                                    <xsl:attribute name="type">password</xsl:attribute>
                                </xsl:if>
                                
                                <xsl:if test="$id='username'">
                                    <xsl:attribute name="autocapitalize">off</xsl:attribute>
                                    <xsl:attribute name="autocorrect">off</xsl:attribute>
                                </xsl:if>
                                
                                <xsl:if test="not(/*/xi:userinput/@spb-agent)">
                                    <xsl:for-each select="($this/descendant::xi:data|$this/ancestor-or-self::xi:data)[@name=key('id',current()/@ref)/@autofill-form]/xi:datum[@name=key('id',current()/@ref)/@autofill]">
                                        <xsl:attribute name="xi:autofill">
                                            <xsl:value-of select="."/>
                                        </xsl:attribute>
                                    </xsl:for-each>
                                </xsl:if>
                                
                                <xsl:choose>
                                    <xsl:when test="not(/*/xi:userinput/@spb-agent)">
                                        <xsl:if test="$id='password' or @type='parameter'">
                                            <xsl:attribute name="xi:option">
                                                <xsl:text> </xsl:text>
                                            </xsl:attribute>
                                        </xsl:if>
                                        <xsl:if test="$command">
                                            <xsl:attribute name="xi:option">
                                                <xsl:text>forward</xsl:text>
                                            </xsl:attribute>
                                        </xsl:if>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:attribute name="onfocus">return onFocus(this)</xsl:attribute>
                                    </xsl:otherwise>
                                </xsl:choose>
                                
                                <xsl:if test="$file-name">
                                    <xsl:attribute name="xi:file-name">
                                        <xsl:value-of select="$file-name"/>
                                    </xsl:attribute>
                                </xsl:if>
                                
                                <xsl:if test="not($element='textarea')">
                                    <xsl:if test="text()">
                                        <xsl:attribute name="value"><xsl:value-of select="."/></xsl:attribute>
                                    </xsl:if>
                                    <xsl:attribute name="size">
                                        <xsl:variable name="size-default">
                                            <xsl:apply-templates select="key('id',@ref)" mode="input-size"/>
                                        </xsl:variable>
                                        <xsl:choose>
                                            <xsl:when test="key('id',@ref)/@autofill">
                                                <xsl:value-of select="string-length(ancestor::xi:data/xi:datum[key('id',@ref)/@autofill-for=current()/@ref])+1"/>
                                            </xsl:when>
                                            <xsl:when test="string-length(.) = 0">
                                                <xsl:value-of select="$size-default"/>
                                            </xsl:when>
                                            <xsl:when test="string-length(.) &lt; 12">
                                                <xsl:value-of select="12"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="string-length(.)+2"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:attribute>
                                </xsl:if>
                                
                                <xsl:if test="$element='textarea'">
                                    <xsl:attribute name="cols">30</xsl:attribute>
                                    <xsl:attribute name="rows">3</xsl:attribute>
                                    <xsl:value-of select="text()"/>
                                </xsl:if>
                                
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:element>
                </xsl:otherwise>
                
            </xsl:choose>
        </span>

        <xsl:if test="$file-name">
            <input type="hidden" id="{$file-name}" />
        </xsl:if>

        <!--xsl:apply-templates select="key('id',self::xi:datum/@ref)/*" mode="render">
            <xsl:with-param name="datum" select="."/>
        </xsl:apply-templates-->
    </xsl:template>

    <xsl:template match="*" mode="input-size">12</xsl:template>

    <xsl:template match="*[@type='string' or not(@type)]" mode="input-size">18</xsl:template>
    <xsl:template match="*[@type='number' or @type='decimal']" mode="input-size">12</xsl:template>
    <xsl:template match="*[@type='int']" mode="input-size">6</xsl:template>

    <xsl:template match="xi:field[@autofill-for]" mode="render-value">
        <xsl:param name="value"/>
        
        <xsl:if test="string-length($value) &gt; 0">
            
            <xsl:variable name="obj"
                          select="$value/parent::xi:data/following-sibling::xi:data/descendant::xi:datum[@ref=current()/@autofill-for]
                                 |$value/parent::xi:data/descendant::xi:datum[@ref=current()/@autofill-for]
                                 |$value/ancestor::xi:data/xi:datum[@ref=current()/@autofill-for]
                                 "/>
            
            <input type="button" class="button" id="{@id}"
                   onclick="autofill('{$obj/@id}','{$value}')">
                <xsl:attribute name="class">
                    <xsl:text>button</xsl:text>
                    <xsl:if test="/*/xi:userinput/@spb-agent">
                        <xsl:text> focusable</xsl:text>
                    </xsl:if>
                </xsl:attribute>
                <xsl:if test="/*/xi:userinput/@spb-agent">
                    <xsl:attribute name="onfocus">return onFocus(this)</xsl:attribute>
                </xsl:if>
                <xsl:attribute name="value">
                    <xsl:call-template name="render-simple-text">
                        <xsl:with-param name="value" select="$value"/>
                    </xsl:call-template>
                </xsl:attribute>
            </input>
        </xsl:if>
    </xsl:template>
    

    <xsl:template match="*" mode="render-value" name="render-simple-text">
        <xsl:param name="value" select="self::xi:datum/text()"/>
        <xsl:choose>
            <xsl:when test="@pipeline">
                <a href="?pipeline={@pipeline}&amp;datum={$value/@id}&amp;file-name={$value/../xi:datum[@name='name']}">Скачать файл</a>
            </xsl:when>
            <xsl:when test="@type='int' and not(@editable) and string-length($value)>0">
                <xsl:if test="not($value='0')">
                    <xsl:value-of select="format-number($value,'#')"/>
                </xsl:if>
            </xsl:when>
            <xsl:when test="@type='decimal' and not(@editable) and string-length($value)>0">
                <xsl:value-of select="format-number($value,'#,##0.00')"/>
            </xsl:when>
            <xsl:when test="@format='smalltime' and not(@aggregate)">
                <xsl:value-of select="concat(substring($value,1,6),substring($value,9,8))"/>
            </xsl:when>
            <xsl:when test="@format='hh:mm:ss'">
                <xsl:value-of select="substring($value,12,8)"/>
            </xsl:when>
            <xsl:when test="@format='hh:mm'">
                <xsl:value-of select="substring($value,12,5)"/>
            </xsl:when>
            <xsl:when test="@type='boolean' and $value='1'">
                <xsl:text>Да</xsl:text>
            </xsl:when>
            <xsl:when test="@type='xml'">
                <xsl:apply-templates select="$value" mode="xml-print"/>
            </xsl:when>
            <xsl:when test="@type='boolean' and @format='true-only'"/>
            <xsl:when test="@type='boolean' and not (@format='true-only')">
                <xsl:text>Нет</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$value"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <xsl:template match="*[(@name and text()) or text() or not(@*)]" mode="xml-print">
        <div>
            <xsl:if test="@name">
                <span class="xmlname">
                    <xsl:value-of select="concat(@name,':')"/>
                </span>
            </xsl:if>
            <span>
                <xsl:value-of select="text()"/>
            </span>
            <xsl:apply-templates select="*" mode="xml-print"/>
        </div>
    </xsl:template>
    
    <xsl:template match="xi:datum" mode="xml-print" priority="1000">
        <xsl:apply-templates select="*" mode="xml-print"/>
    </xsl:template>


    <xsl:template match="xi:datum[*[count(@*) &gt; 1]]" mode="xml-print" priority="1000">
        <xsl:param name="this" select="."/>
        <div class="tabs">
            <ul>
                <xsl:for-each select="*">
                    <li>
                        <a href="#{$this/@id}-{local-name()}-{count(preceding-sibling::*)}">
                            <xsl:value-of select="local-name()"/>
                        </a>
                    </li>
                </xsl:for-each>
            </ul>
            <xsl:apply-templates select="*" mode="xml-print"/>
        </div>
    </xsl:template>
    
    
    <xsl:template match="*[not(@name) or count(@*) &gt; 1]" mode="xml-print">
        <div id="{ancestor::xi:datum[1]/@id}-{local-name()}-{count(preceding-sibling::*)}">
            <!--h4><xsl:value-of select="concat(local-name(),':')"/></h4-->
            <xsl:for-each select="@*">
                <div>
                    <span class="xmlname">
                        <xsl:value-of select="concat(local-name(),':')"/>
                    </span>
                    <span>
                        <xsl:value-of select="."/>
                    </span>
                </div>
            </xsl:for-each>
            <xsl:apply-templates select="*" mode="xml-print"/>
        </div>
    </xsl:template>


</xsl:stylesheet>
