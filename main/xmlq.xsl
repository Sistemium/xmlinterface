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

    
    <xsl:template match="xi:data-update" mode="sql-save">
        
        <xsl:variable name="storage">
            <xsl:value-of select="@storage"/>
        </xsl:variable>
        
        <xsl:variable name="server">
            <xsl:value-of select="@server"/>
        </xsl:variable>
        
        <xsl:variable name="db">
            <xsl:value-of select="@db"/>
        </xsl:variable>
        
        <xsl:variable name="descriptor" select="$model/xi:concept[@name=current()/@name]"/>
        
        <xsl:variable name="sql">
            <xsl:apply-templates select="$model/xi:concept[@name=current()/@name]" mode="save">
                <xsl:with-param name="query" select="."/>
            </xsl:apply-templates>
        </xsl:variable>
        
        <xsl:if test="$thisdoc/*[@debug]">
            <xsl:document href="data/requests/{@id}.sql" method="text">
               <xsl:value-of select="$sql"/>
            </xsl:document>
        </xsl:if>
        
        <xsl:variable name="program">
            <xsl:value-of select="@program"/>
        </xsl:variable>
        
        <xsl:apply-templates select="php:function(
            'sqlRequest', $sql, $storage, $server, $db, $program, 'rowcount'
        )"/>
        
        <!--xsl:if test="$thisdoc/*/xi:userinput[contains(@host,'mac')]">
            <dummy>
                <xsl:copy-of select="$sql"/>
            </dummy>
        </xsl:if-->
        
    </xsl:template>

    <xsl:template match="xi:concept[xi:save[@type='procedure']]" mode="save">
        <xsl:param name="query"/>
        <xsl:param name="concept" select="."/>
        
        <xsl:text>execute </xsl:text>
        <xsl:apply-templates select="xi:save/@owner" mode="prefix"/>
        <xsl:apply-templates select="xi:save" mode="sql-name"/>
        <xsl:text> </xsl:text>
        
        <xsl:for-each select="$query/xi:set | $query/xi:parameter | $query/xi:data">
            <xsl:variable name="parameter" select="$concept/xi:save/xi:parameter[@name=current()/@name]"/>
            <xsl:if test="$parameter">
                <xsl:apply-templates select="$parameter" mode="sql-name"/>
                <xsl:text> = </xsl:text>
                <xsl:apply-templates select="." mode="value"/>
                <xsl:if test="position()!=last()">
                    <xsl:text>, </xsl:text>
                </xsl:if>
            </xsl:if>
        </xsl:for-each>
        
    </xsl:template>

    <xsl:template match="xi:concept" mode="save">
        <xsl:param name="query"/>
        <xsl:choose>
            <xsl:when test="$query[@type='insert']">
                <xsl:text>insert into </xsl:text>
                <xsl:apply-templates select="xi:save/@owner" mode="prefix"/>
                <xsl:apply-templates select="xi:save" mode="sql-name"/>
                <xsl:text> ( </xsl:text>
                <xsl:apply-templates select="$query/xi:set|$query/xi:parameter" mode="select-list"/>
                <xsl:text> ) values ( </xsl:text>
                <xsl:for-each select="$query/xi:set|$query/xi:parameter">
                    <xsl:apply-templates select="." mode="value"/>
                    <xsl:if test="position()!=last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
                <xsl:text> )</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$query/@type"/>
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="xi:save/@owner" mode="prefix"/>
                <xsl:apply-templates select="xi:save" mode="sql-name"/>
                <xsl:if test="$query/@type='update'">
                    <xsl:text> set </xsl:text>
                    <xsl:for-each select="$query/xi:set[current()/*/@name=@name]">
                        <xsl:apply-templates select="." mode="select-list"/>
                        <xsl:text> = </xsl:text>
                        <xsl:apply-templates select="." mode="value"/>
                        <xsl:if test="position()!=last()">
                            <xsl:text>, </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:if>
                <xsl:text> where </xsl:text>
                <xsl:for-each select="$query/xi:parameter | $query/xi:data[@key][not(@name = $query/xi:set/@name)]">
                    <xsl:apply-templates select="." mode="sql-name"/>
                    <xsl:text> = </xsl:text>
                    <xsl:apply-templates select="." mode="value"/>
                    <xsl:if test="position()!=last()">
                        <xsl:text> and </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
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

    <xsl:template match="xi:data-request" mode="select-list">
        
        <!--xsl:variable name="concept" select="$model/xi:concept[@name=current()/@name]"/-->
        
        <xsl:variable name="order-by">
            <xsl:call-template name="build-order-by"/>
        </xsl:variable>
        
        <xsl:variable name="select-id">
            <xsl:call-template name="select-id"/>
        </xsl:variable>
        
        <xsl:if test="parent::xi:data-request">
            <xsl:choose>
                <xsl:when test="@constrain-parent">
                   <xsl:text> cross</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                   <xsl:text> cross</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text> apply </xsl:text>
        </xsl:if>
        
        <xsl:value-of select="concat('(&#xD;',str:padding(count(ancestor::xi:data-request),'&#x9;'),'')"/>
        
        <xsl:text>SELECT </xsl:text>
        
        <xsl:variable name="no-xmlagg-style"
            select="self::xi:data-request[@name- or @storage='mssql' or @page-size-]"
        />
        
        <xsl:variable name="select" select="
            $model/xi:concept [@name=current()/@name] /xi:select [$select-id=generate-id()]
        "/>
        
        <xsl:if test="1=2 and $no-xmlagg-style and $select/xi:parameter[xi:top|@top]">
            <xsl:for-each select="@page-size">
                <xsl:text> TOP </xsl:text>
                <xsl:value-of select="."/>
                <xsl:text> </xsl:text>
            </xsl:for-each>
            
            <xsl:if test="@page-start > 0">
                <xsl:text> START AT </xsl:text>
                <xsl:value-of select="@page-start * @page-size"/>
                <xsl:text> </xsl:text>
            </xsl:if>
        </xsl:if>
        
        <xsl:if test="not($no-xmlagg-style)">
            <xsl:if test="not(xi:column[@aggregate])">
                <xsl:text>xmlagg(</xsl:text>
            </xsl:if>
            <xsl:text>xmlelement(</xsl:text>
            <xsl:apply-templates select="@name" mode="quoted"/>
        </xsl:if>        
        
        <xsl:if test="xi:column[not(@type='file' or @type='xml')]">
            <xsl:if test="not($no-xmlagg-style)">
                <xsl:text>, xmlattributes(</xsl:text>
            </xsl:if>
            
            <xsl:apply-templates select="xi:column[not(@type='file' or @type='xml')]" mode="select-list"/>
            
            <xsl:if test="not($no-xmlagg-style)">
                <xsl:text>)</xsl:text>
            </xsl:if>
        </xsl:if>
        
        <xsl:if test="xi:column[@type='file' or @type='xml']">
           <xsl:text>, </xsl:text>
           <xsl:apply-templates select="xi:column[@type='file' or @type='xml']" mode="select-list"/>
        </xsl:if>
        
        <!--xsl:variable name="have-aggregates" select="xi:column[@aggregate]"/-->
        
        <xsl:for-each select="xi:data-request">
            <xsl:if test="not($no-xmlagg-style) or position() &gt; 1 or parent::xi:data-request/xi:column">
               <xsl:text>, </xsl:text>
            </xsl:if>
            <xsl:if test="$no-xmlagg-style">
               <xsl:if test="not(ancestor-or-self::*[@storage='mssql'])">
                  <xsl:text>xmlelement('aggdata', </xsl:text>
               </xsl:if>
            </xsl:if>
            <xsl:text>cast (</xsl:text>
            <xsl:value-of select="concat('[',@name,'].data')"/>
            <xsl:text> as xml)</xsl:text>
            <xsl:if test="$no-xmlagg-style">
               <xsl:if test="not(ancestor-or-self::*[@storage='mssql'])">
                  <xsl:text>) as "</xsl:text>
                  <xsl:value-of select="@name"/>
                  <xsl:text>"</xsl:text>
               </xsl:if>
            </xsl:if>
        </xsl:for-each>
        
        <xsl:for-each select="xi:preload">
            <xsl:if test="preceding-sibling::xi:column or preceding-sibling::xi:data-request">
                <xsl:text>, </xsl:text>
            </xsl:if>
            <xsl:text>cast((select '</xsl:text>
            <!--xsl:value-of select="@id"/>
            <xsl:text>' as id, '</xsl:text-->
            <xsl:value-of select="@ref"/>
            <xsl:text>' as ref, '</xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text>' as name </xsl:text>
            <xsl:if test="@pipeline">
                <xsl:text>, '</xsl:text>
                <xsl:value-of select="@pipeline"/>
                <xsl:text>' as pipeline </xsl:text>
            </xsl:if>
            <xsl:text> from (select null as c) as [preload] for xml auto) as xml)</xsl:text>
        </xsl:for-each>
        
        <xsl:if test="not($no-xmlagg-style)">
            <xsl:if test="not(xi:column[@aggregate])">
               <xsl:text>&#xD;</xsl:text>
               <xsl:value-of select="str:padding(count(ancestor::xi:data-request)+1,'&#x9;')"/>
               <xsl:text>)</xsl:text>
            </xsl:if>
            <xsl:value-of select="$order-by"/>
            <xsl:text>&#xD;</xsl:text>
            <xsl:value-of select="str:padding(count(ancestor::xi:data-request),'&#x9;')"/>
            <xsl:text>)</xsl:text>
        </xsl:if>
        
        <xsl:text> from </xsl:text>
        
        <xsl:apply-templates select="." mode="from"/>

        <!--xsl:if test="$have-aggregates and xi:data-request">
            <xsl:text>&#xD; group by </xsl:text>
            <xsl:for-each select="xi:data-request">
                <xsl:if test="position() &gt; 1">
                    <xsl:text>, </xsl:text>
                </xsl:if>
                <xsl:value-of select="concat('[',@name,'].data')"/>
            </xsl:for-each>
        </xsl:if-->
        
        <xsl:if test="$no-xmlagg-style">
            <xsl:value-of select="$order-by"/>
            <xsl:text> for xml auto, elements</xsl:text>
        </xsl:if>
        
        <!--xsl:if test="parent::xi:data-request"-->
            <xsl:text>&#xD;</xsl:text>
            <xsl:value-of select="str:padding(count(ancestor::xi:data-request) - 1,'&#x9;')"/>
            <xsl:text>)</xsl:text>
        <!--/xsl:if-->
        
        <xsl:if test="parent::xi:data-request">
            <xsl:value-of select="concat(' as [',@name,'] ([data])')"/>
        </xsl:if>
        
    </xsl:template>
    

    <xsl:template match="xi:data/xi:parameter" mode="select-list">
        <xsl:apply-templates select="." mode="value"/>
        <xsl:text> as </xsl:text>
        <xsl:apply-templates select="." mode="sql-name"/>
        <xsl:if test="position()!=last()">
           <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:template>
    

    <xsl:template match="*" mode="select-list">
        <!--xsl:apply-templates select="../@name" mode="doublequoted"/>
        <xsl:text>.</xsl:text-->
        <xsl:if test="@aggregate">
            <xsl:value-of select="concat(@aggregate,'(')"/>
        </xsl:if>
        
        <xsl:apply-templates select="." mode="sql-name"/>
        
        <xsl:if test="@aggregate">
            <xsl:text>)</xsl:text>
        </xsl:if>
        
        <xsl:if test="ancestor::xi:data-request[1][@page-size-]  or ancestor::xi:data-request[@storage='mssql' or not(current()[@type='file' or @type='xml'])]">
           <xsl:text> as </xsl:text>
           <xsl:apply-templates select="@name" mode="doublequoted"/>
        </xsl:if>
        
        <xsl:if test="position()!=last()">
           <xsl:text>, </xsl:text>
        </xsl:if>
        
    </xsl:template>

    <xsl:template name="select-id">
        
        <xsl:param name="this" select ="."/>
        <xsl:param name="concept" select="$model/xi:concept[@name=$this/@concept]"/>
        
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
        
        <xsl:value-of select="$select-id"/>
        
    </xsl:template>

    <xsl:template match="xi:data-request" mode="from">
        
        <xsl:param name="this" select ="."/>
        <xsl:param name="concept" select="$model/xi:concept[@name=$this/@concept]"/>
        
        <xsl:variable name="parameters"
                      select="xi:parameter
                             |(ancestor::xi:data-request|xi:etc/xi:data)[@name=$this/xi:use/@concept]
                             /xi:parameter[@name=$this/xi:use/@parameter and ../@name=$this/xi:use/@concept]
        "/>
        
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
        
        <xsl:if test="@page-size">
            
            <xsl:text> ( select</xsl:text>
            
            <xsl:if test="not($select/xi:parameter[xi:top|@top])">
                <xsl:for-each select="@page-size">
                    <xsl:text> TOP </xsl:text>
                    <xsl:value-of select="."/>
                    <xsl:text> </xsl:text>
                </xsl:for-each>
                
                <xsl:if test="@page-start > 0">
                    <xsl:text> START AT </xsl:text>
                    <xsl:value-of select="@page-start * @page-size + 1"/>
                    <xsl:text> </xsl:text>
                </xsl:if>
            </xsl:if>
            
            <xsl:text> * from </xsl:text>
            
        </xsl:if>
        
        <xsl:apply-templates select="$concept" mode="from-name">
            <xsl:with-param name="parameters" select="$parameters"/>
            <xsl:with-param name="joins" select="xi:join"/>
            <xsl:with-param name="request" select="."/>
            <xsl:with-param name="select" select="$select"/>
            <xsl:with-param name="parmnams" select="$parmnams"/>
        </xsl:apply-templates>
        
        <xsl:if test="not(@page-size)">
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
                
                <xsl:for-each select="xi:parameter | xi:use">
                    
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
        
        <xsl:if test="@page-size">
            <xsl:call-template name="build-order-by"/>
            <xsl:text>) as </xsl:text>
            <xsl:apply-templates select="@name" mode="doublequoted"/>
            <xsl:apply-templates select="xi:data-request" mode="select-list"/>
        </xsl:if>
        
        <xsl:if test="xi:data-request[@constrain-parent]">
            <xsl:if test="@page-size or normalize-space($where)=''">
                <xsl:text> where </xsl:text>
            </xsl:if>
            
            <xsl:if test="not (@page-size) and normalize-space($where)!=''">
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
                    
                    <xsl:apply-templates select="$request/@name" mode="doublequoted"/>
                    <xsl:text>.</xsl:text>
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
        
        <xsl:param name="parameters" select="self::xi:null"/>
        <xsl:param name="joins" select="self::xi:null"/>
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
                
                <xsl:for-each select="
                    xi:parameter[$this/@storage='mssql'
                        or $parmnams=@name or @sql-name=($parm-for-top/@sql-name|$parm-for-start-at/@sql-name)
                    ]
                ">
                    <xsl:variable name="datum" select="
                        $parmnams [.=current()/@name] /parent::*
                    "/>
                
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
            
            <xsl:text> as </xsl:text>
            <xsl:apply-templates select="$request/@name" mode="doublequoted"/>
            
            <xsl:for-each select="$this[current()[not(@type='procedure')]]/*[@name=$request/xi:order-by[1][@use-sql-index]/@name]/@sql-index">
                <xsl:text>force index(</xsl:text>
                <xsl:value-of select="."/>
                <xsl:text>)</xsl:text>
            </xsl:for-each>
            
        </xsl:for-each>
        
    </xsl:template>



<!--  Templates for building strings of values  -->

    <xsl:template match="*[not(*)][not(text()) or text()='']" mode="value" priority="1000">
        <xsl:text>NULL</xsl:text>
    </xsl:template>
    
    <xsl:template match="*[@type='xml']" mode="value">
        <xsl:text>'</xsl:text>
        <xsl:copy-of select="*"/>
        <xsl:text>'</xsl:text>
    </xsl:template>

    <xsl:template match="*[@type='number' or @type='int' or @type='decimal']" mode="value">
        <xsl:value-of select="."/>
    </xsl:template>
    
    <xsl:template match="*[@type='boolean']" mode="value">
        <xsl:value-of select="."/>
    </xsl:template>

    <xsl:template match="*[xi:less-than]" mode="value" priority="1000">
        <xsl:text>&lt;</xsl:text>
        <xsl:apply-templates select="xi:less-than/text()" mode="value"/>        
    </xsl:template>
        
    <xsl:template match="*[xi:more-than]" mode="value" priority="1000">
        <xsl:text>&gt;</xsl:text>
        <xsl:apply-templates select="xi:more-than/text()" mode="value"/>        
    </xsl:template>
        
    <xsl:template match="xi:use" mode="value" priority="1001">
        <xsl:param name="datum" select="
            (ancestor::xi:data-request|parent::*/xi:etc/xi:data)[@name=current()/@concept]
            /xi:parameter[@name=current()/@parameter]
        "/>
        <xsl:apply-templates select="$datum" mode="value"/>
        <xsl:if test="not($datum/text())">
            <xsl:text>null</xsl:text>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*" mode="value">
        <xsl:apply-templates select="." mode="quoted">
            <xsl:with-param name="value">
                <xsl:apply-templates select="." mode="sqlvalue"/>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="xi:datum" mode="value">
        <xsl:apply-templates select="." mode="quoted">
            <xsl:with-param name="value">
                <xsl:apply-templates select="key('id',@ref)" mode="sqlvalue">
                    <xsl:with-param name="datum" select="."/>
                </xsl:apply-templates>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="*[@type='file']" mode="value">
      <xsl:variable name="path">
         <xsl:value-of select="."/>
      </xsl:variable>
      <xsl:text>base64_decode('</xsl:text>
      <xsl:copy-of select="php:function('getFileContents',$path)"/>
      <xsl:text>')</xsl:text>
    </xsl:template>

    <xsl:template match="xi:data" mode="value">
        <xsl:apply-templates select="*[@key][1]" mode="value"/>
    </xsl:template>

    <xsl:template match="*" mode="sqlvalue">
        <xsl:param name="datum" select="."/>
        <xsl:variable name="q">'</xsl:variable>
        <xsl:value-of select="translate($datum,$q,' ')"/>
    </xsl:template>
    
    <xsl:template match="*[@use-like]" mode="sqlvalue">
        <xsl:param name="datum" select="."/>
        <xsl:value-of select="translate($datum,'*','%')"/>
    </xsl:template>

    <xsl:template match="*[@type='date']" mode="sqlvalue">
        <xsl:param name="datum" select="."/>
        <xsl:variable name="numbers" select="translate($datum,'./-','')"/>
        <xsl:value-of select="concat(substring($numbers,5),substring($numbers,3,2),substring($numbers,1,2))"/>
    </xsl:template>


<!--  Templates for building strings of sql column names  -->

    <xsl:template match="@*" mode="sql-name">
        <xsl:apply-templates select="." mode="doublequoted"/>
    </xsl:template>

    <xsl:template match="*[@sql-compute]" mode="sql-name" name="compute-sql-name">
        <xsl:value-of select="@sql-compute"/>
    </xsl:template>

    <xsl:template match="xi:column[@type='date' and not(@sql-compute)]" mode="sql-name" priority="1000">
        <xsl:text>convert(char(10),</xsl:text>
        <xsl:apply-templates select="../@name" mode="doublequoted"/>
        <xsl:text>.</xsl:text>
        <xsl:apply-templates select="@sql-name|self::*[not(@sql-name)]/@name" mode="doublequoted"/>
        <xsl:text>,104)</xsl:text>
    </xsl:template>

    <xsl:template match="xi:data-request//xi:column[@type='datetime' and not(@sql-compute)]" mode="sql-name" priority="1000">
        <xsl:text>convert(varchar(19),</xsl:text>
        <xsl:apply-templates select="../@name" mode="doublequoted"/>
        <xsl:text>.</xsl:text>
        <xsl:apply-templates select="@sql-name|self::*[not(@sql-name)]/@name" mode="doublequoted"/>
        <xsl:text>,10</xsl:text>
        <xsl:choose>
         <xsl:when test="@aggregate">2</xsl:when>
         <xsl:otherwise>4</xsl:otherwise>
        </xsl:choose>
        <xsl:text>)+' '+convert(varchar(8),</xsl:text>
        <xsl:apply-templates select="../@name" mode="doublequoted"/>
        <xsl:text>.</xsl:text>
        <xsl:apply-templates select="@sql-name|self::*[not(@sql-name)]/@name" mode="doublequoted"/>
        <xsl:text>,8)</xsl:text>
    </xsl:template>

    <xsl:template match="xi:join/xi:on" mode="sql-name">
        <xsl:param name="value"
            select="ancestor::xi:data-request/xi:etc/xi:parameter[@name=current()[@property='id']/@name]
                | ancestor::xi:data-request/xi:etc/xi:data[@name=current()/@name]/xi:set-of-parameters
            "
        />
        <xsl:choose>
            <xsl:when test="$value/self::xi:set-of-parameters">
                <xsl:for-each select="$value/*">
                    <xsl:apply-templates select="." mode="value"/>
                    <xsl:if test="last() > position()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="$value">
                <xsl:apply-templates select="$value" mode="value"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="self::*[@name]/@name|self::*[not(@name)]/@concept" mode="doublequoted"/>
                <xsl:text>.</xsl:text>
                <xsl:variable name="property" select="$model/xi:concept[@name=current()/@concept]/*[@name=current()/@property]"/>
                <xsl:apply-templates select="$property" mode="sql-name"/>
                <xsl:if test="not($property)">
                    <xsl:apply-templates select="@property" mode="sql-name"/>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="xi:column[@type='file']" mode="sql-name">
        <xsl:text>base64_encode(</xsl:text>
        <xsl:apply-templates select="@sql-name|self::*[not(@sql-name)]/@name" mode="doublequoted"/>
        <xsl:text>)</xsl:text>
    </xsl:template>

    <xsl:template match="xi:column[@type='xml']" mode="sql-name">
        <xsl:if test="not(ancestor::xi:data-request[@storage='mssql' or @page-size-])">
            <xsl:text>xmlelement(</xsl:text>
            <xsl:apply-templates select="@name" mode="quoted"/>
            <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:text>xmlelement(</xsl:text>
        <xsl:apply-templates select="@name" mode="quoted"/>
        <xsl:text>, xmlattributes ('xml' as "type"), cast( </xsl:text>
        <xsl:apply-templates select="@sql-name|self::*[not(@sql-name)]/@name" mode="doublequoted"/>
        <xsl:text> as xml))</xsl:text>
        <xsl:if test="not(ancestor::xi:data-request[@storage='mssql' or @page-size-])">
            <xsl:text>)</xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="xi:parameter[@sql-name]" mode="sql-name">
        <xsl:value-of select="@sql-name"/>
    </xsl:template>

    <xsl:template match="*[@sql-name]" mode="sql-name">
        <xsl:if test="self::xi:column">
            <xsl:apply-templates select="../@name" mode="doublequoted"/>
            <xsl:text>.</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="@sql-name" mode="doublequoted"/>
    </xsl:template>

    <xsl:template match="*[@name]" mode="sql-name" priority="-100">
        <xsl:if test="self::xi:column">
            <xsl:apply-templates select="../@name" mode="doublequoted"/>
            <xsl:text>.</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="@name" mode="doublequoted"/>
    </xsl:template>

    <xsl:template match="*[not(@name)]" mode="sql-name" priority="-100">
        <xsl:apply-templates select="../@name" mode="doublequoted"/>
    </xsl:template>
    
    <xsl:template match="@*" mode="prefix">
        <xsl:apply-templates select="." mode="doublequoted"/>
        <xsl:text>.</xsl:text>
    </xsl:template>
 
</xsl:transform>