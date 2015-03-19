<?xml version="1.0" ?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://unact.net/xml/xi"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns:php="http://php.net/xsl"
    xmlns:str="http://exslt.org/strings"
    xmlns:e="http://exslt.org/common"
    exclude-result-prefixes="php mda str e"
    extension-element-prefixes="str e"
    xmlns:mda="urn:schemas-microsoft-com:xml-analysis:mddataset"
>
    <xsl:decimal-format name="mdx" decimal-separator="." grouping-separator="" NaN="" zero-digit="0" />

    <xsl:param name="model" select="document('domain.xml')/xi:domain"/>

    <xsl:include href="xmlq-mdx.xsl"/>
    <xsl:include href="xmlq-value.xsl"/>
    <xsl:include href="xmlq-name.xsl"/>
    <xsl:include href="xmlq-save.xsl"/>
    <xsl:include href="xmlq-select.xsl"/>
   
    <!-- Не хочется процедуры писать
   
       Метаданные или управляющие данные можно возвращать из бд в подчиненных элементах специального неймспейса
   
    -->


    <xsl:template match="xi:data-request|xi:data-update">
        <xsl:if test="$thisdoc/*[@debug]">
            <xsl:document href="data/requests/{@id}.xml">
               <xsl:copy-of select="."/>
            </xsl:document>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="self::xi:data-update">
               <xsl:apply-templates select="." mode="sql-save"/>
            </xsl:when>
            <xsl:when test="@storage='olap'">
               <xsl:apply-templates select="." mode="mdx-select"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                </xsl:copy>
               <xsl:apply-templates select="." mode="sql-select"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <xsl:template match="xi:result-set//*/@* | xi:result-set//*[not(* or parent::xi:result-set)]">
        <datum name="{local-name()}">
            <xsl:value-of select="."/>
        </datum>
    </xsl:template>

    <xsl:template match="xi:result-set//xi:callback">
        <xsl:copy-of select="$thisdoc//*[@id=current()/@id]"/>
    </xsl:template>

    <xsl:template match="xi:result-set//xi:preload">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="id">
                <xsl:value-of select="php:function('uuidSecure','')"/>
            </xsl:attribute>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="xi:result-set//*[@type='xml']" priority="1000">
        <datum name="{local-name()}">
            <xsl:copy-of select="*"/>
        </datum>
    </xsl:template>


    <xsl:template match="*[xi:aggdata][local-name()=local-name(xi:aggdata/*)]
                        |*[local-name()=local-name(*[xi:aggdata])] | xi:aggdata | xi:result-set//*[*[@type='xml']]" priority="1000">
        <xsl:apply-templates select="*"/>
    </xsl:template>

    <xsl:template match="xi:result-set//*[* or @* or parent::xi:result-set]">
        <data name="{local-name()}">
            <xsl:apply-templates select="@*|node()"/>
        </data>
    </xsl:template>

    <xsl:template match="xi:datatable-//*"/>

    <xsl:template match="xi:data-request" mode="sql-select">
        
        <xsl:variable name="sql">
            <xsl:if test="not(@storage = 'mssql')">
                <xsl:text>set @result = </xsl:text>
            </xsl:if>
            <xsl:if test="@storage = 'mssql'">
                <xsl:text>select </xsl:text>
            </xsl:if>
            <xsl:apply-templates select="." mode="select-list"/>
            <xsl:if test="not(@storage = 'mssql')">
                <xsl:text></xsl:text>
            </xsl:if>
        </xsl:variable>
        
        <xsl:variable name="server">
            <xsl:value-of select="@server"/>
            <xsl:if test="not(@server) and @storage = 'mssql'">
                <xsl:text>pps</xsl:text>
            </xsl:if>
        </xsl:variable>
        
        <xsl:variable name="storage">
            <xsl:value-of select="@storage"/>
        </xsl:variable>
        
        <xsl:variable name="db">
            <xsl:value-of select="@db"/>
        </xsl:variable>
        
        <xsl:variable name="program">
            <xsl:value-of select="@program"/>
        </xsl:variable>
        
        <xsl:if test="$thisdoc/*[@debug]">
            <xsl:document href="data/requests/{@id}.sql" method="text">
               <xsl:value-of select="$sql"/>
            </xsl:document>
        </xsl:if>
        
        <xsl:variable name="resp" select="php:function(
            'sqlRequest', $sql, $storage, $server, $db, $program
        )"/>
        
        <xsl:apply-templates select="$resp"/>
        
        <xsl:if test="$thisdoc/*[@debug]">
            <xsl:document href="data/requests/{@id}.rsp.xml">
               <xsl:copy-of select="$resp"/>
            </xsl:document>
        </xsl:if>
        
    </xsl:template>


    <xsl:template name="build-order-by">
        <xsl:if test="xi:order-by">
            <xsl:text> order by </xsl:text>
            <xsl:for-each select="xi:order-by">
                
                <xsl:variable name="sql-compute" select="../xi:column[@name=current()/@name]/@sql-compute"/>
                
                <xsl:if test="not($sql-compute)">
                    <xsl:apply-templates select="../@name" mode="doublequoted"/>
                    <xsl:text>.</xsl:text>
                    <xsl:apply-templates select="../xi:column[@name=current()/@name]/@sql-name
                                                |../xi:column[@name=current()/@name][not(@sql-name)]/@name
                                                " mode="sql-name"/>
                </xsl:if>
                
                <xsl:if test="not(../xi:column[@name=current()/@name])">
                    <xsl:apply-templates select="." mode="sql-name"/>
                </xsl:if>
                
                <xsl:if test="$sql-compute">
                    <xsl:value-of select="$sql-compute"/>
                </xsl:if>
                
                <xsl:text> </xsl:text>
                <xsl:value-of select="@dir"/>
                <xsl:if test="position()!=last()">
                    <xsl:text>, </xsl:text>
                </xsl:if>
                
            </xsl:for-each>
        </xsl:if>
    </xsl:template>


    <xsl:template match="xi:data-request|xi:exists" mode="from">
        
        <xsl:param name="this" select ="."/>
        <xsl:param name="concept" select="$model/xi:concept[@name=$this/@concept]"/>
        
        <xsl:variable name="parameters" select="
            xi:parameter
            |(ancestor::xi:data-request|ancestor-or-self::xi:data-request/xi:etc/xi:data)
                [@name=$this/xi:use/@concept]
                /xi:parameter
                    [@name=$this/xi:use/@parameter and ../@name=$this/xi:use/@concept]
        "/>
        
        <!--xsl:text>/*</xsl:text><xsl:value-of select="$parameters"/><xsl:text>*/</xsl:text-->
        
        <xsl:variable name="parmnams"
                      select="xi:parameter[not(@property)]/@name
                             |(xi:use|xi:parameter)/@property
                             |xi:join/xi:on[@name=$this/@name]/@property
        "/>
        
        <xsl:variable name="select-id">
            <xsl:for-each select="$concept/xi:select[not(xi:parameter[@required][not(@name=$parmnams)])]">
                <xsl:sort data-type="number" order="descending"
                          select="count(xi:parameter[@name=$parmnams])"
                />
                <xsl:if test="position()=1">
                    <xsl:value-of select="generate-id()"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:variable name="select" select="$concept/xi:select[$select-id=generate-id()]"/>
        
        <xsl:for-each select="xi:etc/xi:data[xi:parameter]">
            <xsl:value-of select="str:padding(count(ancestor::xi:data-request),'&#x9;')"/>
            <xsl:text> (select </xsl:text>
            <xsl:apply-templates select="xi:parameter" mode="select-list"/>
            <xsl:text> ) as </xsl:text>
            <xsl:apply-templates select="@name" mode="doublequoted"/>
            <xsl:text>&#xD;</xsl:text>
            <xsl:text> cross apply </xsl:text>
        </xsl:for-each>
        
        <xsl:apply-templates select="$concept" mode="from-name">
            <xsl:with-param name="parameters" select="$parameters"/>
            <xsl:with-param name="joins" select="xi:join"/>
            <xsl:with-param name="request" select="."/>
            <xsl:with-param name="select" select="$select"/>
            <xsl:with-param name="parmnams" select="$parmnams"/>
        </xsl:apply-templates>
        
        <xsl:if test="not(@page-size-)">
            <xsl:apply-templates select="xi:data-request" mode="select-list"/>
        </xsl:if>
        
        <xsl:variable name="join">
            <xsl:for-each select="xi:join">
                <xsl:if test="not($select[@type='procedure']/xi:parameter/@name=xi:on[@concept=$concept/@name]/@property)">
                    <xsl:variable name="set-of-parameters"
                        select="ancestor::xi:data-request/xi:etc/xi:data[@name=current()/xi:on[1]/@name]/xi:set-of-parameters"
                    />
                    <xsl:apply-templates select="xi:on[2]" mode="sql-name"/>
                    <xsl:choose>
                        <xsl:when test="$set-of-parameters">
                            <xsl:text> in ( </xsl:text>
                        </xsl:when>
                        <xsl:when test="xi:less-equal">
                            <xsl:text> &gt;= </xsl:text>
                        </xsl:when>
                        <xsl:when test="xi:more-equal">
                            <xsl:text> &lt;= </xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text> = </xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:apply-templates select="xi:on[1]" mode="sql-name"/>
                    <xsl:if test="$set-of-parameters">
                        <xsl:text> )</xsl:text>
                    </xsl:if>
                    <xsl:text> and </xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        
        <!--xsl:value-of select="concat('pcnt:',count($parameters))"/-->
        
        <xsl:variable name="where">
            
            <xsl:value-of select="substring($join, 1, string-length($join)-4 )"/>
            
            <xsl:variable name="where-for-parms">
                
                <xsl:for-each select="xi:parameter | xi:use | xi:exists">
                    
                    <xsl:variable name="where-part">
                        <xsl:apply-templates select="." mode="build-where">
                            <xsl:with-param name="select" select="$select"/>
                            <xsl:with-param name="request" select="$this"/>
                        </xsl:apply-templates>
                    </xsl:variable>
                    
                    <xsl:if test="normalize-space($where-part)!=''">
                        <xsl:text> and </xsl:text>
                    </xsl:if>
                    
                    <xsl:value-of select="$where-part"/>
                    
                </xsl:for-each>
                
            </xsl:variable>
            
            <xsl:if test="not(normalize-space($where-for-parms)='') and normalize-space($join)=''">
                <xsl:text> 1 = 1 </xsl:text>
            </xsl:if>
            
            <xsl:value-of select="$where-for-parms"/>
            
        </xsl:variable>
        
        <xsl:if test="normalize-space($where)!=''">
            
            <xsl:text>&#xD;</xsl:text>
            <xsl:value-of select="str:padding(count(ancestor::xi:data-request),'&#x9;')"/>
            
            <xsl:text> where </xsl:text>
            <xsl:value-of select="$where"/>
            
        </xsl:if>
        
        <xsl:if test="xi:data-request[@constrain-parent]">
            <xsl:if test="@page-size- or normalize-space($where)=''">
                <xsl:text> where </xsl:text>
            </xsl:if>
            
            <xsl:if test="not (@page-size-) and normalize-space($where)!=''">
                <xsl:text> and </xsl:text>
            </xsl:if>
            
            <xsl:for-each select="xi:data-request[@constrain-parent]">
               <xsl:value-of select="concat('[',@name,'].data is not null')"/>
               <xsl:if test="position() &lt; last()">
                  <xsl:text> and </xsl:text>
               </xsl:if>
            </xsl:for-each>
        </xsl:if>
        
    </xsl:template>
    

    <xsl:template match="xi:exists" mode="build-where">
        
        <xsl:text> exists (select * from </xsl:text>
        <xsl:apply-templates select="." mode="from"/>
        <xsl:text> ) </xsl:text>
        
    </xsl:template>
    
    
    <xsl:template match="*" mode="build-where">
        
        <xsl:param name="request" select="parent::xi:data-request" />        
        <xsl:param name="select" />
        <xsl:param name="use" select="." />
        <xsl:param name="value"
            select="
                $use/self::xi:parameter
                |($request[$use/self::xi:use]/ancestor-or-self::*
                 |$request[$use/self::xi:use]/ancestor-or-self::*/xi:etc/xi:data)
                 [@name=$use/@concept]/xi:parameter[@name=$use/@parameter]
            "
        />
        
        <xsl:if test="not( $select/xi:parameter[@name=$use/@property] )">
            
            <xsl:variable name="property"
                select="$select/parent::xi:concept/*[@name=$use/@property]"
            />
            
            <xsl:if test="$value and ($property)">
                
                <xsl:if test="not($use/xi:between or $property/self::xi:index)">
                    
                    <xsl:if test="$use/parent::xi:use">
                        <xsl:text> or </xsl:text>
                    </xsl:if>
                    
                    <xsl:if test="$use/xi:use">
                        <xsl:text> ( </xsl:text>
                    </xsl:if>
                    
                    <xsl:for-each select="$request/@name">
                        <xsl:apply-templates select="." mode="doublequoted"/>
                        <xsl:text>.</xsl:text>
                    </xsl:for-each>
                    <xsl:apply-templates select="$property" mode="sql-name"/>
                    
                    <xsl:choose>
                        
                        <xsl:when test="$use/xi:not">
                            <xsl:text> &lt;&gt; </xsl:text>
                        </xsl:when>
                        
                        <xsl:when test="$value/@type='boolean' and $property[self::xi:role[not(@false-means-zero)]]">
                            
                            <xsl:choose>
                                <xsl:when test="$value/text()='1'">
                                    <xsl:text>&gt; 0 </xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text> is null </xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                            
                            <xsl:text> and </xsl:text>
                            <xsl:apply-templates select="$value" mode="value"/>
                            <xsl:text>=</xsl:text>
                            
                        </xsl:when>
                        
                        <xsl:when test="$value/@type='boolean' and not($property/@type='boolean')">
                            <xsl:if test="$value/text()='1'">
                                <xsl:text>&gt;</xsl:text>
                            </xsl:if>
                            <xsl:text>=</xsl:text>
                        </xsl:when>
                        
                        <xsl:when test="($use|$value)[@use-like]">
                            <xsl:text> like </xsl:text>
                        </xsl:when>
                        
                        <xsl:when test="($use|$value)[@use-in]">
                            <xsl:text> in </xsl:text>
                        </xsl:when>
                        
                        <xsl:when test="not($use/*) and $value[not(text()) or text()='']">
                            <xsl:text> is </xsl:text>
                        </xsl:when>
                        
                        <xsl:when test="$use/*">
                            <xsl:text> </xsl:text>
                        </xsl:when>
                        
                        <xsl:when test="$value/text()">
                            <xsl:text>=</xsl:text>
                        </xsl:when>
                        
                    </xsl:choose>
                    
                </xsl:if>
                
                <xsl:for-each select="$property/self::xi:index">
                    <xsl:text>contains(</xsl:text>
                    <xsl:value-of select="@sql-name"/>
                    <xsl:text>, </xsl:text>
                </xsl:for-each>
                    
                <xsl:apply-templates select="$value" mode="value"/>
                
                <xsl:for-each select="$property/self::xi:index">
                    <xsl:text>)</xsl:text>
                </xsl:for-each>
                
                <xsl:for-each select="$use/xi:between">
                    <xsl:text> between </xsl:text>
                    <xsl:apply-templates select="xi:start" mode="sql-name"/>
                    <xsl:text> and </xsl:text>
                    <xsl:apply-templates select="xi:end" mode="sql-name"/>
                </xsl:for-each>
                
                <xsl:apply-templates select="$use/xi:use" mode="build-where">
                    <xsl:with-param name="request" select="$request"/>
                    <xsl:with-param name="select" select="$select"/>
                </xsl:apply-templates>
                
                <xsl:if test="$use[not(xi:use) and parent::xi:use]">
                    <xsl:text> ) </xsl:text>
                </xsl:if>
                
            </xsl:if>
            
        </xsl:if>
        
    </xsl:template>
    

    <xsl:template match="xi:concept[not(xi:select)]" mode="join-name">
        <xsl:apply-templates select="@name" mode="doublequoted"/>
    </xsl:template>


    <xsl:template match="xi:concept" mode="from-name">
        
        <xsl:param name="parameters" select="/.."/>
        <xsl:param name="joins" select="/.."/>
        <xsl:param name="request"/>
        <xsl:param name="this" select="."/>
        <xsl:param name="select" select="xi:select[1]"/>
        <xsl:param name="parmnams" select="$parameters/@name|$joins/xi:on[@concept=$this/@name]/@property"/>
        
        <xsl:for-each select="$select">
            <xsl:apply-templates select="../@db" mode="prefix"/>
            <xsl:apply-templates select="@owner" mode="prefix"/>
            <xsl:apply-templates select="." mode="sql-name"/>
            
            <xsl:if test="@type='procedure'">
                <xsl:text>(</xsl:text>
                
                <xsl:variable name="parm-for-top" select="
                    xi:parameter[$request/@page-size and (xi:top or @top)]
                "/>
                <xsl:variable name="parm-for-start-at" select="
                    xi:parameter[$request/@page-size and $parm-for-top and (xi:start-at or @start-at)]
                "/>
                
                <xsl:variable name="select-parameters" select="
                    xi:parameter[$this/@storage='mssql'
                        or $parmnams=@name
                        or @sql-name=($parm-for-top/@sql-name|$parm-for-start-at/@sql-name)
                    ] [not(@required='ignore')]
                "/>
                
                <xsl:for-each select="$select-parameters">
                    <xsl:variable name="datum" select="
                        $parmnams [.=current()/@name] /parent::*
                    "/>
                    
                    <!--xsl:text>/*</xsl:text><xsl:value-of select="local-name($datum)"/><xsl:text>*/</xsl:text-->
                    
                    <xsl:if test="not($this/@storage='mssql')">
                        <xsl:apply-templates select="." mode="sql-name"/>
                        <xsl:text>=</xsl:text>
                    </xsl:if>
                    
                    <xsl:apply-templates select="$datum[self::xi:use or self::xi:parameter]" mode="value"/>
                    
                    <xsl:apply-templates mode="sql-name" select="
                        $joins[xi:on[@concept=$this/@name and @property=current()/@name]]
                        /xi:on[not(@concept=$this/@name) or not(@name=$request/@name)]"
                    />
                    
                    <xsl:choose>
                        <xsl:when test="@sql-name=$parm-for-top/@sql-name">
                            <xsl:value-of select="$request/@page-size"/>
                        </xsl:when>
                        <xsl:when test="@sql-name=$parm-for-start-at/@sql-name">
                            <xsl:value-of select="xi:isnull($request/@page-start,0) * $request/@page-size + 1"/>
                        </xsl:when>
                        <xsl:when test="$this/@storage='mssql' and not($parmnams=@name)">
                            <xsl:text> default</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                    
                    <xsl:if test="position()!=last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                    
                </xsl:for-each>
                
                <xsl:text>)</xsl:text>
            </xsl:if>
            
            <xsl:for-each select="$request/@name">
                <xsl:text> as </xsl:text>
                <xsl:apply-templates select="." mode="doublequoted"/>
            </xsl:for-each>
            
            <xsl:for-each select="$this[current()[not(@type='procedure')]]/*[@name=$request/xi:order-by[1][@use-sql-index]/@name]/@sql-index">
                <xsl:text>force index(</xsl:text>
                <xsl:value-of select="."/>
                <xsl:text>)</xsl:text>
            </xsl:for-each>
            
        </xsl:for-each>
        
    </xsl:template>

 
</xsl:transform>