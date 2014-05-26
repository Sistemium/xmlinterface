<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://unact.net/xml/xi"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns:php="http://php.net/xsl"
    xmlns:str="http://exslt.org/strings"
    xmlns:e="http://exslt.org/common"
    exclude-result-prefixes="php str e"
    extension-element-prefixes="str e"
>

    <xsl:param name="model" />
    
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
        
        <xsl:variable name="no-xmlagg-style"
            select="self::xi:data-request[@name- or @storage='mssql' or @page-size-]"
        />
        
        <xsl:variable name="select" select="
            $model/xi:concept [@name=current()/@concept] /xi:select [$select-id=generate-id()]
        "/>
        
        <xsl:variable name="agg-wrapper" select="
            @page-size and 'xmlagg'='xmlagg' and not($select/xi:parameter[xi:top|@top])
        "/>
        
        <xsl:if test="$agg-wrapper">
            
            <xsl:text> ( select xmlagg( </xsl:text>
            <xsl:apply-templates select="@name" mode="doublequoted"/>
            <xsl:text>.[data]) from </xsl:text>
            
        </xsl:if>
        
        <xsl:value-of select="concat('(&#xD;',str:padding(count(ancestor::xi:data-request),'&#x9;'),'')"/>
        
        <xsl:text>SELECT </xsl:text>
        
        <xsl:if test="not($select/xi:parameter[xi:top|@top])">
            
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
        
        <xsl:variable name="dont-xmlagg" select="xi:column[@aggregate] or (@page-size and not($select/xi:parameter[xi:top|@top]))"/>
        
        <xsl:if test="not($no-xmlagg-style)">
            <xsl:if test="not($dont-xmlagg)">
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
            <xsl:if test="not($dont-xmlagg)">
               <xsl:text>&#xD;</xsl:text>
               <xsl:value-of select="str:padding(count(ancestor::xi:data-request)+1,'&#x9;')"/>
               <xsl:text>)</xsl:text>
                <xsl:value-of select="$order-by"/>
            </xsl:if>
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
        
        <xsl:if test="$no-xmlagg-style or $dont-xmlagg">
            <xsl:value-of select="$order-by"/>
            <xsl:if test="$no-xmlagg-style">
                <xsl:text> for xml auto, elements</xsl:text>
            </xsl:if>
        </xsl:if>
        
        <!--xsl:if test="parent::xi:data-request"-->
            <xsl:text>&#xD;</xsl:text>
            <xsl:value-of select="str:padding(count(ancestor::xi:data-request) - 1,'&#x9;')"/>
            <xsl:text>)</xsl:text>
        <!--/xsl:if-->
        
        <xsl:if test="parent::xi:data-request">
            <xsl:value-of select="concat(' as [',@name,'] ([data])')"/>
        </xsl:if>
        
        <xsl:if test="$agg-wrapper">
            <xsl:if test="parent::xi:data-request">
                <xsl:text>)</xsl:text>
            </xsl:if>
            <xsl:text> as </xsl:text>
            <xsl:apply-templates select="@name" mode="doublequoted"/>
            <xsl:text> ([data]) </xsl:text>
            <xsl:if test="not(parent::xi:data-request)">
                <xsl:text>)</xsl:text>
            </xsl:if>
        </xsl:if>
        
    </xsl:template>
    

    <xsl:template match="xi:data/xi:parameter" mode="select-list">
        <xsl:if test="@use-in">
            <xsl:text>'</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="value"/>
        <xsl:if test="@use-in">
            <xsl:text>'</xsl:text>
        </xsl:if>
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

    
</xsl:transform>
