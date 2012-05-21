<?xml version="1.0" ?>
<xsl:transform version="1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns="http://unact.net/xml/xi"
   xmlns:xi="http://unact.net/xml/xi"
   xmlns:php="http://php.net/xsl"
   xmlns:str="http://exslt.org/strings"
   exclude-result-prefixes="php mda str"
   extension-element-prefixes="str"
   xmlns:mda="urn:schemas-microsoft-com:xml-analysis:mddataset"
>

    <xsl:template match="xi:data-request" mode="mdx-select">
        <xsl:variable name="descriptor" select="$model/xi:concept[@name=current()/@name]/xi:select"/>
        <xsl:variable name="mdx">
            <xsl:apply-templates select="$descriptor/../*[@mdx-compute]" mode="mdx-with"/>
            <xsl:text> select </xsl:text>
            <xsl:apply-templates select="." mode="mdx-select-list"/>
            <xsl:text> from </xsl:text>
            <xsl:apply-templates select="$descriptor/@cube" mode="doublequoted"/>
            <xsl:apply-templates select="." mode="mdx-where"/>
            <xsl:text> cell properties [Value]</xsl:text>
        </xsl:variable>
        <xsl:variable name="server">
            <xsl:value-of select="@server"/>
        </xsl:variable>
        <xsl:variable name="db">
            <xsl:value-of select="@db"/>
        </xsl:variable>
        <response>
            <xsl:variable name="result" select="php:function('mdxRequest',$mdx,$server,$db)"/>
            <xsl:variable name="measures" select="$result/*/mda:Axes/mda:Axis[1]/mda:Tuples/mda:Tuple"/>
            <xsl:variable name="cells" select="$result/*/mda:CellData/mda:Cell"/>
            
            <xsl:variable name="schema" select="../xi:form"/>
            <xsl:variable name="fieldcnt" select="count($schema/xi:field)"/>

            <xsl:attribute name="ts"><xsl:value-of select="$result/@ts"/></xsl:attribute>
            <xsl:choose>
                <xsl:when test="$measures">
                    <result-set>
                        <xsl:for-each select="$result/*/mda:Axes/mda:Axis[2]/mda:Tuples/mda:Tuple">
                            <xsl:variable name="tuple" select="."/>
                            <xsl:variable name="tuplepos" select="position() - 1"/>
                            <data name="{$schema/@name}">
                                <xsl:for-each select="$schema/xi:field">
                                    <xsl:variable name="fieldpos" select="position() - 1"/>
                                    <xsl:apply-templates select="$cells[@CellOrdinal=($tuplepos*$fieldcnt+$fieldpos)]" mode="mdx-datum">
                                        <xsl:with-param name="name" select="@name"/>
                                        <xsl:with-param name="ordparams" select="concat($tuplepos,',',$fieldpos)"/>
                                    </xsl:apply-templates>
                                </xsl:for-each>
                                <xsl:for-each select="$schema/xi:form">
                                    <data name="{@name}">
                                        <xsl:for-each select="xi:field">
                                            <xsl:apply-templates select="$tuple/mda:Member/*[local-name()=current()/@mdx-name]" mode="mdx-datum">
                                                <xsl:with-param name="name" select="@name"/>
                                            </xsl:apply-templates>
                                        </xsl:for-each>
                                    </data>
                                </xsl:for-each>
                            </data>
                        </xsl:for-each>
                        <xsl:if test="$thisdoc/*[@debug]">
                            <xsl:document href="data/requests/{@id}.mdx">
                               <xsl:copy-of select="$mdx"/>
                            </xsl:document>
                            <xsl:document href="data/requests/{@id}.mda.xml">
                               <xsl:copy-of select="$result"/>
                            </xsl:document>
                        </xsl:if>
                    </result-set>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$result"/>
                </xsl:otherwise>
            </xsl:choose>
            <sql><xsl:value-of select="$mdx"/></sql>
        </response>
    </xsl:template>


    <xsl:template match="mda:Cell" mode="mdx-datum">
        <xsl:param name="name"/>
        <xsl:param name="ordparams"/>
        <datum name="{$name}" ordparams="{$ordparams}">
            <xsl:value-of select="format-number(mda:Value,'0.00')"/>
        </datum>
    </xsl:template>

    <xsl:template match="*" mode="mdx-datum">
        <xsl:param name="name"/>
        <datum name="{$name}">
            <xsl:value-of select="."/>
        </datum>
    </xsl:template>

    <xsl:template match="*" mode="mdx-with">
        <xsl:choose>
            <xsl:when test="position()=1">
                <xsl:text>with </xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>,</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text> member </xsl:text>
        <xsl:value-of select="@mdx-name"/>
        <xsl:text> as </xsl:text>
        <xsl:value-of select="@mdx-compute"/>
    </xsl:template>
    
    <xsl:template match="xi:data-request" mode="mdx-select-list">
        <xsl:text> {</xsl:text>
        <xsl:for-each select="xi:column">
            <xsl:value-of select="@mdx-name"/>
            <xsl:if test="not(position()=last())">
                <xsl:text>, </xsl:text>
            </xsl:if>            
        </xsl:for-each>
        <xsl:text>} on 0 </xsl:text>
        <xsl:for-each select="xi:data-request">
            <xsl:text>, non empty {</xsl:text>
                <xsl:value-of select="@mdx-name"/>
            <xsl:text>} on </xsl:text>
            <xsl:value-of select="position()"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="xi:data-request" mode="mdx-where">
        <xsl:variable name="concept" select="$model/xi:concept[@name=current()/@name]"/>
        <xsl:variable name="params" select="xi:etc/xi:data/xi:parameter[@name='id']|xi:parameter"/>
        <xsl:if test="$params">
            <xsl:text> where ( </xsl:text>
            <xsl:for-each select="$params">
                <xsl:choose>
                    <xsl:when test="../parent::xi:etc">
                        <xsl:value-of select="$concept/*[@name=current()/parent::xi:data/@name]/@mdx-name"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$concept/*[@name=current()/@name]/@mdx-name"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="text()">
                  <xsl:text>.&amp;[</xsl:text>
                  <xsl:value-of select="."/>
                  <xsl:text>]</xsl:text>
                </xsl:if>
                <xsl:if test="not(position()=last())">
                    <xsl:text>, </xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:text> ) </xsl:text>
        </xsl:if>
    </xsl:template>


</xsl:transform>