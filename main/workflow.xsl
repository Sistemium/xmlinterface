<?xml version="1.0" ?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns="http://unact.net/xml/xi" xmlns:xi="http://unact.net/xml/xi"
 xmlns:php="http://php.net/xsl" exclude-result-prefixes="php"
 >
 
    <!--
        В ходе обработки требуется:
        Определить необходимость произвести переход
        Проверить имеющиеся данные и если все ок, то:
        Произвести переход:
            Запомнить новое положение
            Отобразить поля ввода и статику
     -->

    <xsl:template match="xi:menu[not(*)]"/>
    
    <xsl:template match="xi:datum[@editable='file']/text()|xi:datum[@editable='file']/@modified"/>
    <xsl:template match="xi:datum[@editable='file-name']/@modified"/>
    <xsl:template match="xi:data[xi:datum[@editable='file']]/@persist-this"/>

    <xsl:template match="xi:view[xi:dialogue/xi:events[xi:close and not(xi:save and ancestor::xi:view/xi:view-data//xi:exception)]]"/>
    <xsl:template match="xi:view/xi:exception|xi:view[xi:dialogue[xi:events/xi:backward]]/xi:view-data//xi:response[xi:exception]" />
    
    <!--xsl:template match="xi:dialogue" mode="extend-replace">
        <xsl:apply-templates select="." mode="build-dialogue"/>
    </xsl:template-->

    <xsl:template match="xi:view[xi:workflow]/xi:menu[preceding-sibling::xi:view-data]"/>
 
    <xsl:template match="xi:view[xi:workflow]/xi:dialogue[@current-step]">
        <xsl:apply-templates select="key('id',@current-step)" mode="build-dialogue"/>
    </xsl:template>

    <xsl:template match="xi:view[xi:workflow]/xi:dialogue[not(@current-step)]">
        <xsl:apply-templates select="../xi:workflow/xi:step[1]" mode="build-dialogue"/>
    </xsl:template>

    <xsl:template match="xi:dialogue[xi:events[xi:backward or xi:event[@name='backward']]]">
        <xsl:apply-templates select="(../xi:workflow/xi:step[1]|key('id',@current-step)/preceding-sibling::xi:step)[last()]" mode="build-dialogue"/>
    </xsl:template>
    
    <xsl:template match="xi:view[xi:workflow]/xi:dialogue
                        [xi:events[xi:refresh or *[@name='refresh']] and not(../xi:view-data//xi:exception)]" >
        <xsl:variable name="cs" select="key('id',@current-step)"/>
        <xsl:for-each select="$cs|key('id',@current-step)/preceding-sibling::xi:step[xi:validate or $cs/@hidden]">
            <xsl:if test="position() = 1">
                <xsl:apply-templates select="." mode="build-dialogue"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="xi:dialogue[xi:events/xi:jump/@to=key('id',@current-step)/preceding-sibling::xi:step/@name]" priority="100">
        <xsl:apply-templates select="ancestor::xi:view/xi:workflow/xi:step[@name=current()/xi:events/xi:jump/@to]" mode="build-dialogue"/>
    </xsl:template>
    
    <xsl:template match="xi:dialogue[xi:events[xi:forward or xi:jump]]">
        <xsl:variable name="step" select="key('id',@current-step)"/>
        <xsl:variable name="validated">
            <xsl:apply-templates select="$step" mode="validate"/>
        </xsl:variable>
        <!--xsl:comment><xsl:copy-of select="$validated"/></xsl:comment-->
        <xsl:choose>
            <xsl:when test="xi:events/xi:forward and (../xi:view-data//xi:exception[not(xi:not-found)] or contains($validated,'invalid'))">
                <xsl:copy-of select="$validated"/> 
                <xsl:apply-templates select="../xi:view-data//xi:exception"/>
                <xsl:apply-templates select="$step" mode="build-dialogue"/>
            </xsl:when>
            <xsl:when test="xi:events/xi:jump">
                <xsl:apply-templates select="ancestor::xi:view/xi:workflow/xi:step[@name=current()/xi:events/xi:jump/@to]" mode="build-dialogue"/>                
            </xsl:when>
            <!--xsl:when test="$step/xi:validate/@success-option">
                
            </xsl:when-->
            <xsl:otherwise>
                <xsl:variable name="next" select="($step/following-sibling::xi:step[not(@hidden)])[1]"/>
                <xsl:apply-templates select="(key('id',@current-step)|$next)[last()]" mode="build-dialogue"/>                
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <xsl:template match="xi:step | xi:dialogue" mode="build-dialogue">
    
        <xsl:apply-templates select="." mode="build-menu"/>
    
        <dialogue>
            <xsl:attribute name="current-step"><xsl:value-of select="@id"/></xsl:attribute>
            
            <xsl:attribute name="action">
                <xsl:if test="xi:validate and not(descendant::*[@noforward])">
                    <xsl:text>forward</xsl:text>
                </xsl:if>
            </xsl:attribute>
        
            <xsl:apply-templates select="*" mode="build-dialogue"/>
            <xsl:apply-templates select="*" mode="build-choise"/>
        </dialogue>
        
    </xsl:template>

    <xsl:template match="xi:step[xi:validate or preceding-sibling::*[1][xi:validate]]" mode="build-menu">
        <menu>
            <xsl:for-each select="preceding-sibling::xi:step[1]" mode="build-option">
                <option name="backward" label="Вернуться"/>
            </xsl:for-each>
            <xsl:for-each select="following-sibling::xi:step[1][not(hidden)]" mode="build-option">
                <option name="forward" label="Продолжить"/>
            </xsl:for-each>
        </menu>
    </xsl:template>

    <xsl:template match="xi:step" mode="build-menu">
        <menu>
            <xsl:apply-templates
                select="(preceding-sibling::xi:step|following-sibling::xi:step)
                        [not(xi:validate or preceding-sibling::xi:step/@hidden)]"
                mode="build-option"
            />
        </menu>
    </xsl:template>

    <xsl:template match="xi:step[@hidden]" mode="build-menu" priority="1000"/>
    <xsl:template match="xi:step[@hidden]" mode="build-option" />

    <xsl:template match="xi:step" mode="build-option">
        <xsl:param name="label" select="@label"/>
        <option name="{@name}" label="{$label}"/>
    </xsl:template>

    <xsl:template match="*" mode="build-choise">
        <xsl:apply-templates select="*" mode="build-choise"/>
    </xsl:template>

    <xsl:template match="*" mode="build-dialogue">
        <xsl:apply-templates select="*" mode="build-dialogue"/>
    </xsl:template>

    <xsl:template match="@*" mode="build-dialogue">
        <xsl:copy-of select="."/>
    </xsl:template>
    
    <xsl:template match="@form" mode="build-dialogue">
        <xsl:attribute name="ref">
            <xsl:value-of select="ancestor::xi:view/xi:view-schema//xi:form[@name=current()]/@id"/>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="xi:display//xi:export" mode="build-dialogue">
        <xsl:if test="ancestor::xi:view/xi:view-data//*[@ref=current()/@ref][not(@is-new)]">
            <xsl:copy>
                <xsl:apply-templates select="@*" mode="build-dialogue"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>

    <xsl:template match="xi:for-each/@ref" mode="build-dialogue">
        <xsl:param name="top" select="."/>
        <xsl:attribute name="ref">
            <xsl:value-of select="$top"/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="xi:for-each/@id" mode="build-dialogue">
        <xsl:param name="top" select="."/>
        <xsl:attribute name="id">
            <xsl:value-of select="concat( ., '-', $top )"/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="xi:display//xi:for-each" mode="build-dialogue">
        
        <xsl:variable name="this" select="."/>
        
        <xsl:for-each select="ancestor::xi:view/xi:view-data//*[@ref=current()/@ref][not(ancestor::xi:set-of[@is-choise])]">
            <xsl:choose>
                <xsl:when test="self::xi:data[not(@delete-this)]">
                    <region>
                        <xsl:apply-templates select="$this/@*|$this/*" mode="build-dialogue">
                            <xsl:with-param name="top" select="@id"/>
                        </xsl:apply-templates>
                        <xsl:if test="@deletable and $this[not(@no-deletes)]/xi:input">
                            <option label="{concat('Удалить [',key ('id',@ref)/@label,']')}" ref="{@id}" name="delete"/>
                        </xsl:if>
                    </region>
                </xsl:when>
                <xsl:when test="self::xi:extender and $this[not(@no-deletes)]/xi:input">
                    <option label="{concat('Добавить [',key ('id',@ref)/@label,']')}" ref="{@id}"/>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each>
        
    </xsl:template>

    <xsl:template match="@label-field" mode="build-dialogue">
        <xsl:param name="top" select="."/>
        <xsl:attribute name="label">
            <xsl:value-of select="(key('id',$top)//xi:datum[@name=current()])[1]"/>
        </xsl:attribute>
    </xsl:template>


    <xsl:template match="xi:display//xi:grid" mode="build-dialogue">
        
        <xsl:param name="top" select="ancestor::xi:view/xi:view-data/xi:data/@id"/>
        <xsl:param name="grid" select="."/>
        <xsl:param name="form" select="key('id',@ref)"/>
        
        <xsl:variable name="rows"
                      select="key('id',$top)//xi:data
                             [not(ancestor::xi:set-of[@is-choise])][@name=current()/@form]
                             [descendant::xi:datum[@type='field']]
                             "
        />
        
        <xsl:choose>
            
            <xsl:when test="$rows or $form[@extendable or @pipeline='clientData']">
                <xsl:copy>
                    
                    <xsl:copy-of select="@*"/>
                    <xsl:attribute name="top"><xsl:value-of select="$top"/></xsl:attribute>
                    
                    <xsl:for-each select="$form">
                        
                        <xsl:copy-of select="@deletable"/>
                        <xsl:attribute name="ref"><xsl:value-of select="@id"/></xsl:attribute>
                        
                        <columns>
                            
                            <xsl:for-each select="$grid/xi:columns/*">
                                <xsl:apply-templates select="key('id',@ref) | self::*[not(@ref)]" mode="build-column">
                                    <xsl:with-param name="grid" select="$grid"/>
                                </xsl:apply-templates>
                            </xsl:for-each>
                            
                        </columns>
                        
                    </xsl:for-each>
                    
                    <rows ref="{ancestor::xi:view/xi:view-schema//xi:form[@name=current()/@form]/@id}">
                        <xsl:for-each select="key('id',$top)//xi:preload[@ref=current()/@ref][@pipeline and not(ancestor::xi:set-of[@is-choise])]">
                            <xsl:attribute name="{@pipeline}">
                                <xsl:value-of select="@id"/>
                            </xsl:attribute>
                        </xsl:for-each>
                        <xsl:apply-templates select="xi:group|xi:class"/>
                        <xsl:for-each select="xi:option">
                           <option label="{@label}" ref="{@id}"/>
                        </xsl:for-each>
                    </rows>
                    
                    <xsl:for-each select="key('id',$top)//xi:extender[@ref=current()/@ref][not(ancestor::xi:set-of[@is-choise])]">
                        <option label="+" ref="{@id}"/>
                    </xsl:for-each>
                    
                    <xsl:apply-templates
                        select="key('id',$top)//xi:set-of[@ref=current()/@ref]"
                        mode="build-dialogue"
                    />
                    
                </xsl:copy>
            </xsl:when>
            
            <xsl:when test="key('id',@ref)/@label">
                <text>
                   <xsl:apply-templates select="key('id',@ref)" mode="label"/>
                   <xsl:text> отcутствуют</xsl:text>
                </text>
            </xsl:when>
            
        </xsl:choose>
    </xsl:template>

    <xsl:template match="xi:set-of[@page-size]" mode="build-dialogue">
        
        <page-control ref="{@id}">
            <xsl:copy-of select="@page-start"/>
            <xsl:if test="xi:data">
                <xsl:attribute name="visible">true</xsl:attribute>
            </xsl:if>
            <xsl:copy-of select="*[not(self::xi:data)]"/>
        </page-control>
        
    </xsl:template>


<?BEGIN mode="build-column" ?>
    
    
    <xsl:template match="*[@hidden]" mode="build-column"/>    

    <xsl:template match="*" mode="build-column">
        
        <xsl:param name="grid" select="."/>
        
        <xsl:if test="not(@id=$grid/xi:group/xi:by/@ref)
                      and (not($grid/@hide-empty) or self::xi:form/@choise or ancestor::xi:view[1]/xi:view-data//*[@ref=current()/@id][text()|*])">
            <column ref="{@id}">
                <xsl:copy-of select="@extra-style | $grid/xi:column[@ref=current()/@id]/@*"/>
                <xsl:apply-templates select="*" mode="build-dialogue"/>
            </column>
        </xsl:if>
        
    </xsl:template>

    
    <xsl:template match="xi:column[not(@ref)]" mode="build-column">
        
        <xsl:param name="grid" select="."/>
        
        <column ref="{@id}">
            <xsl:copy-of select="@*[not(local-name()='id')]"/>
            <xsl:apply-templates select="*" mode="build-dialogue">
                <xsl:with-param name="top" select="@id"/>
            </xsl:apply-templates>
        </column>
        
    </xsl:template>


<?END mode="build-column" ?>
    

    <xsl:template match="xi:display//xi:region | xi:display//xi:tabs | xi:display//xi:text" mode="build-dialogue">
        
        <xsl:param name="top" select="ancestor::xi:view/xi:view-data/xi:data/@id"/>
        <xsl:variable name="this" select="."/>
        
        <xsl:copy>
            <xsl:apply-templates select="@*|$this/node()" mode="build-dialogue">
                <xsl:with-param name="top" select="$top"/>
            </xsl:apply-templates>
        </xsl:copy>
        
    </xsl:template>

    <xsl:template match="xi:when[@ref]" mode="validate">
        <xsl:if test="ancestor::xi:view/xi:view-data//xi:datum[@ref=current()/@ref]/text()">
            <xsl:apply-templates select="*" mode="validate"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="xi:display//xi:when[@ref]" mode="build-dialogue">
        <xsl:if test="ancestor::xi:view/xi:view-data//xi:datum[@ref=current()/@ref]/text()">
            <xsl:apply-templates select="*" mode="build-dialogue"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="xi:display//* | xi:navigate" mode="build-dialogue">
        
        <xsl:param name="top" select="ancestor::xi:view/xi:view-data/xi:data/@id"/>
        <xsl:param name="ref" select="key('id',$top)/descendant-or-self::*[not(ancestor::xi:set-of[@is-choise])][@ref=current()/@ref]/@id"/>
        
        <xsl:variable name="form-not-a-choise" select="$ref/parent::xi:data[not(@choise)]/xi:datum[@name='name']"/>
        
        <xsl:variable name="should-show" select="(string-length($ref)!=0 or key('id',@ref)/@type='xml')
                                and (not(self::xi:input) or key('id',$ref)[@choise or self::xi:datum]) 
                                and ((not(self::xi:print) and $ref/parent::*[@editable or @choise])
                                  or (key('id',$ref)/text() and key('id',$ref)/text()!='')
                                  or (key('id',@ref)/@type='xml' and key('id',$ref)/*)
                                )"/>
        
        <xsl:variable name="elem">
            <xsl:choose>
                <xsl:when test="self::xi:input[$form-not-a-choise]">
                    <xsl:text>print</xsl:text>
                </xsl:when>
                <xsl:when test="$should-show or key('id',$ref)/ancestor::xi:workflow or self::xi:navigate">
                    <xsl:value-of select="local-name()"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:if test="string-length($elem)>0"> <xsl:element name="{$elem}">
            
            <xsl:copy-of select="@*"/>
            
            <xsl:attribute name="ref">
                <xsl:value-of select="$ref | self::xi:navigate/@id"/>
            </xsl:attribute>
            
            <xsl:if test="key('id',$ref)/ancestor::xi:workflow">
                <xsl:attribute name="ref">
                    <xsl:value-of select="@ref"/>
                </xsl:attribute>
            </xsl:if>
            
            <xsl:attribute name="id">
                <xsl:value-of select="concat('show-',@id)"/>
            </xsl:attribute>
            
            <xsl:if test="self::xi:input[$form-not-a-choise]">
                <xsl:attribute name="ref">
                    <xsl:value-of select="$form-not-a-choise/@id"/>
                </xsl:attribute>
                <xsl:attribute name="field">name</xsl:attribute>
            </xsl:if>
            
            <xsl:attribute name="top">
                <xsl:value-of select="$top"/>
            </xsl:attribute>
            
            <xsl:apply-templates select="self::xi:exists/@child"/>
            
            <xsl:apply-templates  select="*" mode="build-dialogue"/>
            
        </xsl:element> </xsl:if>
        
    </xsl:template>


    <xsl:template match="xi:display//xi:iframe | xi:display//xi:link" mode="build-dialogue">
        <xsl:copy-of select="."/>
    </xsl:template>
    

    <xsl:template match="*[@label|@what-label]" mode="label">
        <xsl:apply-templates select="@what-label | @label[not(../@what-label)]" mode="quoted"/>
        <xsl:if test="xi:parameter">
            <xsl:for-each select="xi:parameter[@editable]">
                <xsl:if test="position()=1">
                    <xsl:text>, заполнив </xsl:text>
                </xsl:if>
                <xsl:apply-templates select="." mode="label"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*" mode="label">
        <xsl:apply-templates select="@name" mode="doublequoted"/>
    </xsl:template>

    <xsl:template match="*" mode="value">
        <xsl:value-of select="."/>
    </xsl:template>

    <xsl:template match="*[@type='boolean' or key('id',@ref)/@type='boolean']" mode="value">
        <xsl:if test=". = 1">'Да'</xsl:if>
        <xsl:if test=". = 0">'Нет'</xsl:if>
    </xsl:template>

    <xsl:template match="xi:step" mode="validate">
        <xsl:apply-templates select="xi:validate/*" mode="validate"/>
    </xsl:template>

    <xsl:template match="xi:step/xi:validate//xi:nonempty" mode="validate">
        <xsl:variable name="ref"
            select="key('id',self::*[not(@field)]/@ref)/xi:field[@key][1]/@id|self::*[@field]/@ref"
        />
        <xsl:variable name="checkdatum"
            select="ancestor::xi:view/xi:view-data/descendant::*[@ref=$ref][not(ancestor::xi:set-of[@is-choise])]"
        />
        <xsl:variable name="not-found"
            select="ancestor::xi:view/xi:view-data/descendant::*[@ref=current()/@ref]
                    [not(ancestor::xi:set-of[@is-choise])]/xi:response/xi:exception/xi:not-found"
        />
        <xsl:if test="$not-found or not(count($checkdatum)=count(ancestor::xi:view/xi:view-data/descendant::*[@ref=current()/@ref][not(ancestor::xi:set-of[@is-choise])])) or $checkdatum[not(text() and string-length(normalize-space(text())) &gt; 0)]">
            <exception>
                <message>
                    <result>invalid</result>
                    <for-human>
                        <xsl:text>Необходимо указать </xsl:text>
                        <xsl:apply-templates mode="label" select="
                            ancestor::xi:view/xi:view-schema/descendant::xi:form
                                [@name=current()/@form or not(current()/@form)]
                                /descendant-or-self::*
                                [(not(self::xi:form) and @id=current()/@ref) or (not(current()/@field) and self::xi:form and @name=current()/@form)]
                        "/>
                    </for-human>
                </message>
            </exception>
        </xsl:if>
    </xsl:template>

    <xsl:template match="xi:step/xi:validate//xi:empty" mode="validate">
        <xsl:if test="ancestor::xi:view/xi:view-data/descendant::xi:data[not(ancestor::xi:set-of[@is-choise])][(@name=current()/@form or not(current()/@form))][descendant::xi:datum[not(ancestor::xi:set-of[@is-choise])][@ref=current()/@ref or (not(current()/@field) and key('id',@ref)/@key)][text() and string-length(normalize-space(text())) &gt; 0]]">
            <exception>
                <message>
                    <result>invalid</result>
                    <for-human>
                        <xsl:text>Продолжить нельзя, пока есть </xsl:text>
                        <xsl:apply-templates select="ancestor::xi:view/xi:view-schema/descendant::xi:form[@name=current()/@form or not(current()/@form)]/descendant-or-self::*[(not(self::xi:form) and @name=current()/@field) or (not(current()/@field) and self::xi:form and @name=current()/@form)]" mode="label"/>
                        <xsl:if test="@field and @form">
                            <xsl:text> в </xsl:text>
                            <xsl:apply-templates select="ancestor::xi:view/xi:view-schema/descendant::xi:form[@name=current()/@form]" mode="label"/>
                        </xsl:if>
                    </for-human>
                </message>
            </exception>
        </xsl:if>
    </xsl:template>

    <xsl:template match="xi:step/xi:validate//xi:equals" mode="validate">
        <xsl:variable name="data-object"
                  select="ancestor::xi:view/xi:view-data/descendant::xi:data[not(ancestor::xi:set-of[@is-choise])][(@name=current()/@form or not(current()/@form))]/descendant::xi:datum[not(ancestor::xi:set-of[@is-choise])][@name=current()/@field or (not(current()/@field) and key('id',@ref)/@key)]"/>
        
        <xsl:if test="not(ancestor::xi:view/xi:view-data/descendant::xi:data[not(ancestor::xi:set-of[@is-choise])][(@name=current()/@form or not(current()/@form))][descendant::xi:datum[not(ancestor::xi:set-of[@is-choise])][@name=current()/@field or (not(current()/@field) and key('id',@ref)/@key)][text()=current()/text()]])">
            <exception>
                <message>
                    <result>invalid</result>
                    <xsl:if test="$data-object">
                        <for-human>
                            <xsl:apply-templates select="key('id',$data-object/@ref)" mode="label"/>
                            <xsl:if test="@field and @form">
                                <xsl:text> в </xsl:text>
                                <xsl:apply-templates select="ancestor::xi:view/xi:view-schema/descendant::xi:form[@name=current()/@form]" mode="label"/>
                            </xsl:if>
                            <xsl:text> должно быть равно </xsl:text>
                            <xsl:apply-templates select="." mode="value"/>
                        </for-human>
                    </xsl:if>
                </message>
            </exception>
        </xsl:if>
    </xsl:template>

    <xsl:template match="xi:step/xi:display" mode="build-choise">
        <xsl:for-each select="ancestor::xi:view/xi:view-data/descendant::xi:data
                             [(@ref|descendant::*/@ref)=current()//*/@ref]
                             [not(@chosen) and not(ancestor::xi:set-of[@is-choise])]/xi:set-of[@is-choise]
                             ">
            <choose>
                <xsl:apply-templates select="key('id',parent::xi:data/@ref)/@*[not(local-name()='id')]"/>
                <xsl:attribute name="ref"><xsl:value-of select="../@id"/></xsl:attribute>
                <xsl:if test="not(key('id',../@ref)/xi:field[@name='name'])">
                    <xsl:attribute name="choise-style">table</xsl:attribute>
                </xsl:if>
            </choose>
        </xsl:for-each>
    </xsl:template>

</xsl:transform>