<?xml version="1.0" ?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns="http://unact.net/xml/xi" xmlns:xi="http://unact.net/xml/xi"
 xmlns:php="http://php.net/xsl" exclude-result-prefixes="php"
 >
    
    <xsl:include href="dialogue.xsl"/>
    <xsl:include href="validate.xsl"/>
 
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
                <xsl:comment>p1</xsl:comment>
                <xsl:apply-templates select="." mode="build-dialogue"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="xi:dialogue[xi:events[not(xi:event[@name='save']|xi:save)]/xi:jump/@to=key('id',@current-step)/preceding-sibling::xi:step/@name]" priority="100">
        <xsl:comment>p100</xsl:comment>
        <xsl:apply-templates select="ancestor::xi:view/xi:workflow/xi:step[@name=current()/xi:events/xi:jump/@to]" mode="build-dialogue"/>
    </xsl:template>
    
    <xsl:template match="xi:dialogue[xi:events[xi:forward or xi:jump]]">
        <xsl:variable name="step" select="key('id',@current-step)"/>
        <xsl:variable name="validated">
            <xsl:apply-templates select="$step" mode="validate"/>
        </xsl:variable>
        <!--xsl:comment><xsl:copy-of select="$validated"/></xsl:comment-->
        <xsl:comment>p0</xsl:comment>
        <xsl:choose>
            <xsl:when test="xi:events[xi:forward|xi:jump[parent::*[xi:event[@name='save']|xi:save]]] and (../xi:view-data//xi:exception[not(xi:not-found)])">
                <xsl:apply-templates select="$step" mode="build-dialogue"/>
            </xsl:when>
            <xsl:when test="xi:events[xi:forward] and (../xi:view-data//xi:exception[not(xi:not-found)] or contains($validated,'invalid'))">
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
                <xsl:variable name="next" select="
                    ($step [not(xi:validate/@for)]
                        /following-sibling::xi:step[not(@hidden)]
                    ) [1]
                    | $step/../xi:step[@name=$step/xi:validate/@for]
                "/>
                <xsl:apply-templates select="(key('id',@current-step)|$next)[last()]" mode="build-dialogue"/>                
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <xsl:template match="xi:step[xi:validate or (not(@hidden) and preceding-sibling::*[1][xi:validate])]" mode="build-menu">
        <menu>
            <xsl:for-each select="preceding-sibling::xi:step[1][xi:validate]">
                <option name="backward" label="Вернуться"/>
            </xsl:for-each>
            <xsl:for-each select="following-sibling::xi:step[1][not(hidden)]">
                <option name="forward" label="Продолжить"/>
            </xsl:for-each>
        </menu>
    </xsl:template>


    <xsl:template match="xi:step[@hidden and not(xi:validate)]" mode="build-menu" priority="1000"/>
    

    <xsl:template match="xi:step" mode="build-menu">
        <menu>
            <xsl:apply-templates
                select="(preceding-sibling::xi:step|following-sibling::xi:step)
                        [not(xi:validate or preceding-sibling::xi:step/@hidden)]"
                mode="build-option"
            />
        </menu>
    </xsl:template>


    <xsl:template mode="build-option" match="
        xi:step[
            @hidden
            | xi:when [not( ancestor::xi:view[1]/xi:view-data//xi:datum/@ref = @ref)]
        ]
    "/>
    
    <xsl:template match="xi:step[@hidden][xi:validate]" mode="build-option">
        <xsl:for-each select="../xi:step[@name=current()/xi:validate/@for]" mode="build-option">
            <option name="forward" label="Продолжить"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="xi:step" mode="build-option">
        <xsl:param name="label" select="@label[not(../@to-label)]|@to-label"/>
        <option name="{@name}" label="{$label}"/>
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


    <xsl:template match="*" mode="build-choise">
        <xsl:apply-templates select="*" mode="build-choise"/>
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