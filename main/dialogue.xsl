<?xml version="1.0" ?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns="http://unact.net/xml/xi"
>

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

    <xsl:template match="xi:step//xi:options" mode="build-dialogue">
        <xsl:copy>
            <xsl:apply-templates mode="build-dialogue" select="@*|*"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="xi:options//xi:option" mode="build-dialogue">
        <xsl:copy-of select="."/>
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
                    <region class="for-each">
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
        
        <xsl:variable name="rows" select="
            key('id',$top)//xi:data
            [not(ancestor::xi:set-of[@is-choise])][@name=current()/@form]
            [descendant::xi:datum[@type='field']]
        "/>
        
        <xsl:choose>
            
            <xsl:when test="
                $rows
                or $form[@extendable or @pipeline='clientData']
                or $top[../self::xi:column]
            ">
                <xsl:copy>
                    
                    <xsl:copy-of select="@*"/>
                    <xsl:attribute name="top"><xsl:value-of select="$top"/></xsl:attribute>
                    
                    <xsl:for-each select="$form">
                        
                        <xsl:copy-of select="@deletable"/>
                        <xsl:copy-of select="$grid/@deletable"/>
                        <xsl:attribute name="ref"><xsl:value-of select="@id"/></xsl:attribute>
                        
                        <columns>
                            
                            <xsl:for-each select="$grid/xi:columns/*">
                                <xsl:apply-templates select="key('id',@ref) | self::*[not(@ref)]" mode="build-column">
                                    <xsl:with-param name="grid" select="$grid"/>
                                    <xsl:with-param name="column" select="current()"/>
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
            
            <xsl:when test="@label | key('id',@ref)/@label">
                <region id="{@id}" class="empty">
                    <xsl:attribute name="label">
                        <xsl:value-of select="@label | key('id',self::*[not(@label)]/@ref)/@label" />
                    </xsl:attribute>
                    <text>
                        <xsl:value-of select="@label | key('id',self::*[not(@label)]/@ref)/@label" />
                        <xsl:text> отcутствуют</xsl:text>
                    </text>
                </region>
            </xsl:when>
            
            <xsl:otherwise>
                <xsl:comment>
                    no data top = <xsl:value-of select="$top"/>
                </xsl:comment>
            </xsl:otherwise>
            
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
        <xsl:param name="column" select="."/>
        
        <xsl:if test="
            not(@id=$grid/xi:group/xi:by/@ref)
            and (not($grid/@hide-empty)
                    or key('id',@ref)/@editable
                    or self::xi:form/@choise
                    or ancestor::xi:view[1]/xi:view-data//*
                        [@ref=current()/@id] [text()|*]
                )
        ">
            <column ref="{@id}">
                <xsl:copy-of select="@extra-style | $grid/xi:columns/xi:column[@ref=current()/@id]/@*"/>
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

    <xsl:template match="xi:step//xi:when[@ref][not(@not-equals)]" mode="build-dialogue">
        <xsl:apply-templates mode="display-when" select="
            ancestor::xi:view/xi:view-data//xi:datum
               [@ref=current()/@ref]
               [not(current()/@equals) or . = current()/@equals]
               [not(current()/@not-modified and @modified)]
        ">
            <xsl:with-param name="context" select="."/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="xi:step//xi:when[@ref][@not-equals]" mode="build-dialogue">
        <xsl:if test="not(
            ancestor::xi:view/xi:view-data//xi:datum
               [@ref=current()/@ref]
               [. = current()/@not-equals]
        )">
            <xsl:apply-templates select="*" mode="build-dialogue"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template mode="display-when" match="*">
        <xsl:comment>display-when: no match</xsl:comment>
    </xsl:template>
    
    <xsl:template mode="display-when" match="*[text()]">
        <xsl:param name="context" />
        <xsl:apply-templates select="$context/*" mode="build-dialogue"/>
    </xsl:template>

    <xsl:template mode="display-when" match="*[key('id',@ref)/@type='boolean'][text()='0']">
        <xsl:param name="context" />
        <xsl:choose>
            <xsl:when test="$context/@equals='0'">
                <xsl:apply-templates select="$context/*" mode="build-dialogue"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:comment>display-when: matches 0 bool</xsl:comment>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="xi:display//xi:not-when[@ref]" mode="build-dialogue">
        <xsl:if test="not(
            ancestor::xi:view/xi:view-data
            //xi:datum [@ref=current()/@ref]
            [text() [key('id',../@ref)/@type='boolean' and . = '1'] or (not(text()) and key('id',@ref)/@type='boolean')]
        )">
            <xsl:apply-templates select="*" mode="build-dialogue"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="xi:display//* | xi:navigate" mode="build-dialogue">
        
        <xsl:param name="top" select="ancestor::xi:view/xi:view-data/xi:data/@id"/>
        <xsl:param name="ref" select="
            key('id',$top)
                /descendant-or-self::* [
                    not(ancestor::xi:set-of[@is-choise])
                ] [@ref=current()/@ref]
                /@id
            | key('id',$top)
                /ancestor::xi:data
                    [not(ancestor::xi:set-of[@is-choise])]
                /* [@ref=current()/@ref]
                /@id
        "/>
        
        <xsl:variable name="form-not-a-choise" select="
            $ref/parent::xi:data [not(@choise)]
            /xi:datum [@name='name']
        "/>
        
        <xsl:variable name="should-show" select="
            ( string-length($ref)!=0
                or key('id',@ref)/@type='xml'
            ) and ( not( self::xi:input )
                or key('id',$ref)[@choise or self::xi:datum]
            ) and (( not(self::xi:print)
                    and ( $ref/parent::*[@editable or @choise]
                        or ($ref/parent::*/@modifiable and self::xi:input[xi:by/@ref])
                    )
                )
                or (key('id',$ref)/text() and key('id',$ref)/text()!='')
                or (key('id',@ref)/@type='xml' and key('id',$ref)/*)
            )
        "/>
        
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


    <xsl:template mode="build-dialogue" match="
        xi:display//xi:iframe
        | xi:display//xi:link
        | xi:display//xi:by
    ">
        <xsl:copy-of select="."/>
    </xsl:template>

</xsl:transform>