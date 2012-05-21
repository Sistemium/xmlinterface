<?xml version="1.0" ?>

<xsl:transform version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:xi="http://unact.net/xml/xi"
 xmlns:rule="http://unact.net/rules"
 xmlns="http://www.w3.org/1999/xhtml"
 >
    
    <xsl:template match="xi:processed">
        <div>
            <xsl:apply-templates />
        </div>
    </xsl:template>

    <xsl:template match="xi:datum[@editable]" mode="render">
        <xsl:attribute name="xi:key"><xsl:value-of select="@id"/></xsl:attribute>
    </xsl:template>

    <xsl:template match="xi:processed/xi:grid">
        <xsl:apply-templates select="../xi:data[@ref=current()/@ref]" mode="gridrow">
            <xsl:with-param name="columns" select="xi:columns"/>
            <xsl:with-param name="groups" select="xi:rows/xi:group"/>
        </xsl:apply-templates>
    </xsl:template>


    <xsl:template match="xi:column" mode="grid-totals">
         <xsl:if test="key('id',@ref)/@totals='sum'">
            <xsl:variable name="values" select="key('id',parent::*/parent::xi:grid/@top)//xi:datum[@ref=current()/@ref][text()!='']"/>
            <xsl:if test="$values">
               <xsl:value-of select="format-number(sum($values),'#,##0.00')"/>
            </xsl:if>
         </xsl:if>
    </xsl:template>

    <xsl:template match="xi:datum" mode="grid-group">
        <xsl:param name="colspan"/>
        <xsl:param name="cnt"/>
        <xsl:param name="cnt-show"/>
        <tr class="group" name="{@name}">
            <xsl:if test="../@removable">
                <td class="options">
                    <xsl:apply-templates select="../@removable"/>
                </td>
            </xsl:if>
            <td colspan="{$colspan}">
                <span><xsl:value-of select="."/></span>
                <xsl:if test="$cnt-show">
                    <span>(<xsl:value-of select="$cnt"/> шт.)</span>
                </xsl:if>
            </td>
        </tr>
    </xsl:template>

    <xsl:template match="xi:data" mode="gridrow">
        <xsl:param name="columns"/>
        <xsl:param name="groups"/>
        <xsl:variable name="data" select="."/>
        <xsl:variable name="datas-prev" select="preceding-sibling::xi:data[@ref=current()/@ref]"/>
        <xsl:variable name="data-prev" select="$datas-prev[last()]"/>

        <xsl:for-each select="$groups">
            <xsl:for-each select="xi:by">
                <xsl:variable name="current-value"
                              select="$data//xi:datum[@ref=current()/@ref]|$data/ancestor::xi:data/xi:datum[@ref=current()/@ref]"/>
                <xsl:variable name="prev-value"
                              select="$data-prev//xi:datum[@ref=current()/@ref]|$data-prev/ancestor::xi:data/xi:datum[@ref=current()/@ref]"/>
                
                <xsl:if test="not($current-value = $prev-value)">
                    <xsl:apply-templates select="$current-value" mode="grid-group">
                        <xsl:with-param name="colspan" select="count($columns/xi:column|$columns/parent::xi:grid[@deletable])"/>
                        <!--xsl:with-param name="cnt" select="count($data/following::xi:data[@ref=$data/@ref and (descendant::xi:datum|ancestor::xi:data/xi:datum)[@ref=current()/@ref][text()=($data//xi:datum|$data/ancestor::xi:data/xi:datum)[@ref=current()/@ref]]])+1"/>
                        <xsl:with-param name="cnt-show" select="$columns/../@accordeon"/-->
                    </xsl:apply-templates>
                </xsl:if>
            </xsl:for-each>
        </xsl:for-each>
        
        <tr>
            <xsl:attribute name="class">
                <xsl:value-of select="concat('data ',local-name(xi:exception),' ',local-name(@is-new), ' ', local-name(@delete-this))"/>
                <xsl:for-each select="$groups/../xi:class[$data//xi:datum[text()]/@ref=@ref or $data/ancestor::xi:data/xi:datum[text()]/@ref=@ref]">
                    <xsl:value-of select="concat(' ',@name)"/>
                </xsl:for-each>
            </xsl:attribute>
            <xsl:if test="$columns/parent::*[xi:option or xi:rows[xi:option]] or $columns/../@deletable">
                <td class="options">
                    <xsl:apply-templates select="@deletable|$columns/../xi:rows/xi:option">
                        <xsl:with-param name="option-value" select="$data/@id"/>
                    </xsl:apply-templates>
                </td>
            </xsl:if>
            <xsl:for-each select="$columns/xi:column">
                <xsl:variable name="datum" select="$data//*[@ref=current()/@ref]|$data/ancestor::xi:data/xi:datum[@ref=current()/@ref]"/>
                <td>
                    <xsl:for-each select="@extra-style">
                        <xsl:attribute name="style">
                            <xsl:value-of select="."/>
                        </xsl:attribute>
                    </xsl:for-each>
                    <xsl:attribute name="class">
                        <xsl:value-of select="normalize-space(concat(local-name(@modified),' ',key('id',@ref)/@type,' ',local-name($datum/@editable)))"/>
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
                        <xsl:otherwise>
                            <xsl:apply-templates select="$datum" mode="render"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:for-each select="key('id',$datum/@ref)/xi:spin">
                        <xsl:attribute name="xi:spin">
                            <xsl:value-of select="$datum/ancestor::xi:data/xi:datum[@ref=current()/@ref]"/>
                        </xsl:attribute>
                    </xsl:for-each>
                </td>
            </xsl:for-each>
        </tr>
    </xsl:template>

    <xsl:template match="xi:spin" mode="render">
    <xsl:param name="datum"/>
        <xsl:for-each select="*">
            <td class="spin">
            <a class="button {local-name()}" href="?{@id}={$datum/@id}">
                <xsl:attribute name="onclick">
                    <xsl:text>return menupad(this</xsl:text>
                    <xsl:if test="ancestor::xi:view/@name">
                        <xsl:text>,&apos;</xsl:text>
                        <xsl:value-of select="concat(ancestor::xi:view/@name,'-form')"/>
                        <xsl:text>&apos;</xsl:text>
                    </xsl:if>
                    <xsl:text>, true)</xsl:text>
                </xsl:attribute>
                <xsl:apply-templates select="." mode="label"/>
            </a>
            </td>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="xi:spin/xi:more" mode="label">+</xsl:template>
    <xsl:template match="xi:spin/xi:less" mode="label">-</xsl:template>


</xsl:transform>