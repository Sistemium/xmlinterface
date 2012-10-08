<?xml version="1.0" ?>
<?xml-stylesheet type="text/xsl" href="html-xsl.xsl"?>

<xsl:transform version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns="http://unact.net/xml/xi"
 xmlns:xi="http://unact.net/xml/xi"
 xmlns:php="http://php.net/xsl"
 exclude-result-prefixes="php"
 >

    <xsl:include href="default-attributes.xsl"/>
    
    <!--  Вообще нет данных в представлении (конструктор окна)   -->
    <xsl:template match="xi:view-data[not(xi:data)]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="../xi:view-schema/xi:form" mode="build-data"/>
        </xsl:copy>
    </xsl:template>
    
    
    <xsl:template match="*[@synthesize-attributes]/@*[.='' or . ='false'][local-name()=../xi:synthesize/@attribute]"/>
    
    <xsl:template match="xi:data
                        [key('id',@ref)/@autosave and (xi:datum[@type='field'][@modified] or xi:data[((@modified or @ts) and @role)])]
                        "
                  mode="extend"
    >
        <xsl:attribute name="persist-this">true</xsl:attribute>
    </xsl:template>

    <!--    Добавление строк     -->
    <xsl:template match="xi:extender
                        [not(ancestor::xi:data[1][xi:set-of[@is-choise] and not(@chosen)])]
                        [xi:command
                            or not(preceding-sibling::xi:data[not(xi:response[@ts][not(xi:result-set)
                                    and xi:rows-affected] and @delete-this)]/@ref=@ref)
                        ]"
    >
        
        <xsl:if test="not(following-sibling::xi:response/xi:result-set//*[@name=current()/@name])">
            <xsl:apply-templates select="key('id',@ref)" mode="build-data">
                <xsl:with-param name="set-thrshld">1</xsl:with-param>
            </xsl:apply-templates>
        </xsl:if>
        
    </xsl:template>
    
    <!-- Удаление, восстановление строки -->
    <xsl:template match="xi:data[@undelete-this]/@delete-this
                        |xi:data[@delete-this]/@undelete-this
                        |xi:data[@delete-this]/@deletable
                        "
    />
    
    <xsl:template match="
        xi:data[@remove-this]
    "/>

    <xsl:template match="xi:data[@delete-this]/@undelete-this">
        <xsl:attribute name="deletable">true</xsl:attribute>
    </xsl:template>


    <xsl:template match="xi:data[@unchoose-this and not(*/@modified)]/@unchoose-this">
        <xsl:apply-templates select="../@role" mode="unchoose"/>
    </xsl:template>
    
    <xsl:template match="@*" mode="unchoose">
        <xsl:attribute name="modified">unchosen</xsl:attribute>
    </xsl:template>
    
    
    <xsl:template match="xi:data[@unchoose-this and not(*/@modified)]/@chosen"/>

    <xsl:template match="xi:data[@unchoose-this and not(*/@modified)]/*[not(self::xi:set-of[@is-choise][*])]"/>

  
    <!--         Выбор          -->
    
    <xsl:template match="xi:data/@ignore-this">
        <xsl:attribute name="just-ignored">true</xsl:attribute>
    </xsl:template>
    
    <xsl:template match="xi:data[@ignore-this]">
        
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            
            <xsl:attribute name="chosen">ignore</xsl:attribute>
            
            <xsl:apply-templates select="key('id',@ref)/xi:form" mode="build-data"/>
            <xsl:copy-of select="xi:set-of[@is-choise]"/>
            
            <!--xsl:comment>choosing for=<xsl:value-of select="@id"/></xsl:comment-->
        </xsl:copy>
        
    </xsl:template>
    
    <xsl:template match="xi:data
                        [xi:chosen[not(@ref=../@chosen)]]
                        [descendant::xi:response/xi:rows-affected
                         or not(ancestor::xi:view/xi:menu/xi:option[@name='save' and @chosen])
                        ]"
    >
        
        <xsl:apply-templates select="key('id',@ref)" mode="build-data">
            <xsl:with-param name="data" select="key('id',xi:chosen/@ref)"/>
            <xsl:with-param name="choose-for" select="@id"/>
        </xsl:apply-templates>
        
        <!--xsl:comment>choosing for=<xsl:value-of select="@id"/></xsl:comment-->
        
    </xsl:template>

    <!--    Построение веток data/datum
                mode build-data        -->

    <xsl:template name="build-set-of">
        
        <xsl:param name="data" select="xi:null"/>
        <xsl:param name="metadata" select="."/>
        
        <xsl:variable name="sort-form" select="$metadata/xi:sort/@form"/>
        <xsl:variable name="sort-field" select="$metadata/xi:sort/@field"/>        
        <xsl:variable name="sort-order">
            <xsl:value-of select="$metadata/xi:sort/@dir"/>
            <xsl:if test="not($metadata/xi:sort/@dir)">
                <xsl:text>asc</xsl:text>
            </xsl:if>
            <xsl:text>ending</xsl:text>
        </xsl:variable>
        
        <xsl:variable name="sort-data-type">text</xsl:variable>
        
        <xsl:variable name="current-set" select="
            $data/ancestor::*[
                self::xi:preload [@page-start]
                | self::xi:set-of
            ] [@ref=$metadata/@id]
        "/>
        
        <xsl:variable name="current-page">
            
            <xsl:if test="not($current-set)"><xsl:text>0</xsl:text></xsl:if>
            
            <xsl:for-each select="$current-set">
                <xsl:choose>
                    <xsl:when test="@refresh-this='next'">
                        <xsl:value-of select="@page-start + 1"/>
                    </xsl:when>
                    <xsl:when test="@refresh-this='prev'">
                        <xsl:value-of select="@page-start - 1"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@page-start"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
            
        </xsl:variable>
        
        <xsl:for-each select="$current-set[not(@page-start=$current-page)]">
            <xsl:copy>
                <xsl:copy-of select="@*[not(local-name()='refresh-this')]"/>
            </xsl:copy>
        </xsl:for-each>
        
        <set-of ref="{$metadata/@id}" name="set-of-{$metadata/@name}" page-start="{$current-page}" close-siblings="true">
            
            <xsl:copy-of select="$metadata/@page-size"/>
            
            <xsl:if test="not(@is-set)">
                <xsl:attribute name="is-choise">true</xsl:attribute>
            </xsl:if>
            
            <xsl:variable name="data-set" select="$data[@name=$metadata/@name]"/>
            
            <xsl:if test="count($data-set) &lt; @page-size">
                <final-page/>
            </xsl:if>
            
            <xsl:for-each select="$data-set">
                
                <xsl:sort data-type="{$sort-data-type}" order="{$sort-order}" select="
                    descendant-or-self::xi:data [@name=$sort-form]
                    /xi:datum [@name=$sort-field]
                "/>
                
                <xsl:apply-templates select="$metadata" mode="build-data">
                    <xsl:with-param name="data" select="."/>
                    <xsl:with-param name="set-thrshld" select="1"/>
                </xsl:apply-templates>
                
            </xsl:for-each>
            
            <xsl:if test="not($data-set) and $metadata/@extendable">
                <xsl:apply-templates select="$metadata" mode="build-data">
                    <xsl:with-param name="set-thrshld" select="1"/>
                </xsl:apply-templates>
            </xsl:if>
            
        </set-of>
        
    </xsl:template>
    
    <!-- основной темплейт -->

    <xsl:template match="xi:form" mode="build-data">
        
        <xsl:param name="data" select="xi:null" />
        <xsl:param name="type" />
        <xsl:param name="choose-for" />
        <xsl:param name="set-thrshld" select="1 - count(@is-set)"/>
        <!-- не доделано @expect-choise[.='forced']) -->
        
        <xsl:variable name="metadata" select="."/>
        
        <xsl:variable name="data-set" select="$data[@name=$metadata/@name or $choose-for][self::xi:data]"/>
        
        <xsl:variable name="choosing"
                select="$data-set and (
                            ($metadata/@choise and $metadata/@id!=$data-set/@ref)
                            or $data-set/parent::xi:set-of[@is-choise][not($type)]
                        )"
        />
        
        <xsl:variable name="inside-of-chosen"
                select="self::*[not(@new-only)]/parent::*[@choise] and not($data-set)"
        />
        
        <xsl:choose>
            
            <xsl:when test="$data[$metadata/@name=@name or @name=concat('set-of-',$metadata/@name)]/ self::xi:preload ">
                <xsl:apply-templates select="$data[$metadata/@name=@name or @name=concat('set-of-',$metadata/@name)]" mode="build-data"/>
            </xsl:when>
            
            <xsl:when test="
                    (count($data-set) > $set-thrshld and $metadata[@is-set])
                    or $metadata[@is-set and @extendable and $set-thrshld=0]
            ">
                <xsl:call-template name="build-set-of">
                    <xsl:with-param name="data" select="$data-set"/>
                </xsl:call-template>                
            </xsl:when>
            
            <xsl:when test="$data-set or $metadata
            
                [@choise or @extendable or @new-only
                    or @build-blank or $inside-of-chosen
                    or xi:parameter
                    or descendant::xi:form
                        [xi:parameter[not(@optional)]]
                ]
                
            ">
                
                <data>
                    
                    <xsl:apply-templates select="$data/xi:response/@ts" />
                    
                    <xsl:if test="$choosing">
                        
                        <xsl:attribute name="chosen">
                            <xsl:value-of select="$data/@id"/>
                        </xsl:attribute>
                        
                        <xsl:attribute name="choise">
                            <xsl:value-of select="$data/parent::xi:set-of/@id"/>
                        </xsl:attribute>
                        
                        <xsl:if test="$metadata/@choise">
                            <xsl:if test="$choose-for">
                                <xsl:attribute name="id"><xsl:value-of select="$choose-for"/></xsl:attribute>
                            </xsl:if>
                            <xsl:attribute name="modified">chosen</xsl:attribute>
                        </xsl:if>
                        
                    </xsl:if>
                    
                    <xsl:if test="$inside-of-chosen">
                        <xsl:attribute name="refresh-this">after-choosing</xsl:attribute>
                    </xsl:if>
                    
                    <xsl:if test="(@new-only or not($data) or $data/@is-new or (xi:field[@name='xid'] and not($data/*[@name='xid']))) and not(@choise)">
                        <xsl:attribute name="is-new">true</xsl:attribute>
                    </xsl:if>
                    
                    <xsl:for-each select="$metadata/xi:reduce[$data and not(@join)]">
                        <xsl:if test="not($data/descendant-or-self::xi:data[@name=current()/@form]/xi:datum[@name=current()/@field])">
                            <xsl:attribute name="remove-this">true</xsl:attribute>
                        </xsl:if>
                    </xsl:for-each>
                            
                    <xsl:for-each select="$metadata/xi:reduce[@join and $data]">
                        <xsl:if test="not( key('id',concat(current()/@form,'-',$data/*[@name=current()/@join])) )">
                            <xsl:attribute name="remove-this">true</xsl:attribute>
                        </xsl:if>
                    </xsl:for-each>
                    
                    <xsl:apply-templates select="$metadata/@*" mode="build-data" />
                    
                    <!--xsl:apply-templates select="$data[1]/parent::xi:result-set/../../xi:datum[@type='parameter']" /-->
                    
                    <xsl:choose>
                        
                        <xsl:when test="count($data-set) > $set-thrshld">
                            
                            <xsl:call-template name="build-set-of">
                                <xsl:with-param name="data" select="$data-set"/>
                                <xsl:with-param name="type" select="not(@is-set)"/>
                            </xsl:call-template>
                            
                        </xsl:when>
                        
                        <xsl:when test="$data-set and (count($data/*)!=0 or not($metadata/xi:field))">
                            
                            <xsl:apply-templates select="$data/parent::xi:result-set[not($type)]" mode="build-data"/>
                            <xsl:apply-templates select="
                                    $data/parent::set-of[not($type)]/../xi:datum
                                    [@type='parameter']
                                    [not(key('id',@ref)/xi:init[@with='userinput'])]
                                "
                            />
                            
                            <xsl:for-each select="*
                                [not(self::xi:copy) and
                                 not(self::xi:parameter
                                     and ($type
                                         or $data/parent::xi:result-set
                                         or $data/parent::xi:set-of[@is-choise]
                                    )
                                )]"
                            >
                                <xsl:apply-templates select="." mode="build-data">
                                    <xsl:with-param name="data"
                                                    select="
                                                        $data/*[not(self::xi:set-of)]
                                                            [@ref=current()/@id or (not(@ref=current()/@id) and @name=current()/@name)]
                                                            [not(@type='parameter' or xi:set-of[@is-choise])]
                                                        |
                                                        $data/xi:set-of/*
                                                            [@ref=current()/@id or (not(@ref=current()/@id) and @name=current()/@name)]
                                                            [not(@type='parameter' or xi:set-of[@is-choise])]
                                                        |
                                                        $data/*[@name=current()/@name]/xi:set-of[@is-choise]/*
                                                            [@name=current()/@name]
                                                    "
                                    />
                                </xsl:apply-templates>
                                
                            </xsl:for-each>
                            
                            <xsl:apply-templates select="$data/parent::xi:set-of[$choosing and not($metadata/@choise)]"/>
                            
                        </xsl:when>
                        
                        <xsl:otherwise>
                            <xsl:apply-templates mode="build-data" select="
                                self::* [not($type or @choise)] [@build-blank or @new-only or @extendable] /*
                                |xi:parameter
                                |self::* [not(@choise)] /xi:form [xi:parameter or @new-only]
                            "/>
                            <!--xsl:comment>data-build-otherwise:<xsl:copy-of select="count($data)"/></xsl:comment-->
                        </xsl:otherwise>
                        
                    </xsl:choose>
                    
                </data>
                
                <xsl:if test="@extendable and (not($data) or ($data and not($data/following-sibling::*/@name=@name)))">
                    <extender>
                        <xsl:apply-templates select="@id|@name" mode="build-data"/>
                    </extender>
                </xsl:if>
                
            </xsl:when>
            
        </xsl:choose>
        
        <!--xsl:for-each select="xi:field/@totals">
            <computed>
                <xsl:copy-of select="@name|."/>
                <xsl:apply-templates select="@id" mode="build-data"/>
            </computed>
        </xsl:for-each-->
        
    </xsl:template>


    <xsl:template match="*/xi:response/xi:result-set" mode="build-data">
        
        <xsl:apply-templates select="parent::xi:response/@ts"/>
        
        <xsl:apply-templates select="
        
            parent::xi:response/parent::*/*
            
            [self::xi:datum[@type='parameter'] or self::xi:set-of[@is-choise]]
            [not(key('id',@ref)/xi:init[@with='userinput'])]
        "/>
        
    </xsl:template>


    <xsl:template match="xi:preload[key('id',@ref)[not(xi:parameter) or xi:parameter[xi:init or @optional]]]" mode="build-data">
        
        <xsl:param name="data" select="."/>
        
        <xsl:copy>
            
            <xsl:copy-of select=" @* | key('id',@ref)/@preload "/>
            
            <xsl:for-each select="key('id',@ref)[@is-set]">
                <xsl:attribute name="name">
                    <xsl:value-of select="concat('set-of-',@name)"/>
                </xsl:attribute>
            </xsl:for-each>
            
            <xsl:apply-templates select="key('id',@ref)/xi:natural-key" mode="build-data">
                <xsl:with-param name="data" select="$data"/>
            </xsl:apply-templates>
            
            <xsl:apply-templates select="key('id',@ref)/xi:parameter" mode="build-data"/>
            
        </xsl:copy>
        
    </xsl:template>


    <xsl:template match="xi:natural-key" mode="build-data">
        <xsl:param name="data"/>
        <xsl:if test="$data">
            <xsl:attribute name="id">
                <xsl:for-each select="xi:part">
                    <xsl:if test="not(position()=1)">
                        <xsl:text>-</xsl:text>
                    </xsl:if>
                    <xsl:value-of select="translate(
                                         /*[current()/@root]/@id
                                         |$data/ancestor-or-self::*[@name=current()/@form]/*[@name=current()/@field]
                                         |$data/ancestor-or-self::*[@name=current()/@form][not(current()/@field)]/@name
                                         ,'.','-')
                                         "/>

                </xsl:for-each>
            </xsl:attribute>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*" mode="build-data"/>

    <xsl:template match="xi:xor" mode="build-data">
        <xsl:param name="data"/>
        <xsl:apply-templates select="*" mode="build-data">
            <xsl:with-param name="data" select="$data"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="xi:datum" mode="build-data">
        <xsl:copy-of select="node()"/>
    </xsl:template>

    <xsl:template match="xi:init" mode="build-data">
        <xsl:if test="parent::*[self::xi:parameter or @editable]">
            <xsl:attribute name="modified">xi:init</xsl:attribute>
        </xsl:if>
        <xsl:apply-templates select="." mode="build-data-init"/>
    </xsl:template>

    <xsl:template match="xi:init" mode="build-data-init"/>

    <xsl:template match="xi:init[@with='today']" mode="build-data-init">
        <xsl:value-of select="php:function('initToday')"/>
    </xsl:template>

    <xsl:template match="xi:init[@with='constant' or @with='const']" mode="build-data-init">
        <xsl:value-of select="."/>
    </xsl:template>

    <xsl:template match="xi:init[@with='device-name']" mode="build-data-init">
        <xsl:choose>
            <xsl:when test="/*/xi:userinput/@ipad-agent">ipad</xsl:when>
            <xsl:when test="/*/xi:userinput/@safari-agent">safari</xsl:when>
            <xsl:when test="/*/xi:userinput/@spb-agent">tsd</xsl:when>
            <xsl:when test="/*/xi:userinput/@firefox-agent">firefox</xsl:when>
            <xsl:otherwise>browser</xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="xi:init[@with='uuid']" mode="build-data-init">
        <xsl:value-of select="php:function('uuidSecure','')"/>
    </xsl:template>
 
    <xsl:template match="xi:init[@with='userinput']" mode="build-data-init">
        <xsl:value-of select="/*/xi:userinput/xi:command[@name=current()/parent::*/@name]"/>
    </xsl:template>
    
    <xsl:template match="xi:init[@with='username']" mode="build-data-init">
        <xsl:value-of select="/*/xi:session/@username"/>
    </xsl:template>

    <!--xsl:template match="xi:init[@with='field']" mode="build-data-init">
        <xsl:apply-templates select="." mode="init-with-field"/>
    </xsl:template>
    
    <xsl:template match="*[@ref]" mode="init-with-field">
        <xsl:value-of select="
            ancestor::xi:view/xi:view-data//xi:datum[@ref=current()/@ref]
        "/>
    </xsl:template>
    
    <xsl:template match="*" mode="init-with-field">
        <xsl:value-of select="
            ancestor::* [@name=current()/@form]
                /* [@name=current()/@field]
        "/>
    </xsl:template-->

    <xsl:template match="xi:init[@with='view-schema-version']" mode="build-data-init">
        <xsl:value-of select="concat(ancestor::xi:view/@name, '_', ancestor::xi:view-schema/@version)"/>
    </xsl:template>

    <xsl:template match="xi:view-schema//*/@id" mode="build-data">
        <xsl:apply-templates select=".." mode="build-ref"/>
    </xsl:template>

    <xsl:template match="@id|@name|@editable|@deletable|@choise|@role
                        |xi:field/@modified|@removable|@modifiable
                        |@toggle-edit-off|@xpath-compute"
                  mode="build-data">
        <xsl:copy/>
    </xsl:template>

    <xsl:template match="*[@alias]/@name" mode="build-data"/>

    <xsl:template match="@alias" mode="build-data">
        <xsl:attribute name="name">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>
  
    <xsl:template match="@*" mode="build-data"/>

    <xsl:template match="xi:parameter[@editable='new-only']" mode="build-data">
        <xsl:param name="data"/>
        <xsl:if test="not($data)">
            <xsl:call-template name="datum-build"/>                
        </xsl:if>
    </xsl:template>

    <xsl:template match="xi:field|xi:parameter|xi:copy" mode="build-data" name="datum-build">
        <xsl:param name="data" select="*"/>
        
        <xsl:variable name="data2" select="$data|xi:init[not ($data) or count($data)=0]"/>
        
        <datum type="{local-name()}">
        
            <xsl:apply-templates select="@*" mode="build-data"/>
            
            <xsl:if test="@modifiable and not(@editable) and $data2">
               <xsl:attribute name="original-value">
                  <xsl:apply-templates select="$data2" mode="build-data"/>
               </xsl:attribute>
            </xsl:if>
            
            <xsl:apply-templates select="$data2" mode="build-data"/>
            
        </datum>
    </xsl:template>
 

</xsl:transform>