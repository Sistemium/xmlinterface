<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://unact.net/xml/xi"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns:php="http://php.net/xsl"
    exclude-result-prefixes="php"
>

    <xsl:param name="model" />
    
    
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
    
    
</xsl:transform>
