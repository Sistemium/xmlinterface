<?xml version="1.0" ?>

<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://unact.net/xml/xi"
    xmlns:xi="http://unact.net/xml/xi">
  
    <!--
    
    Все это можно перенести в описание стейджа
    (хотя бы с комментариями
    
    на клиента аяксом нужно слать изменения к контексту
     
    -->
  
    <!--xsl:template match="xi:view[xi:dialogue/xi:events[xi:close and not(xi:save and ancestor::xi:view/xi:view-data//xi:exception)]]"/>
    <xsl:template match="xi:view/xi:exception|xi:view[xi:dialogue[xi:events/xi:backward]]/xi:view-data//xi:response[xi:exception]" /-->
  
    <!--xsl:import href="stage-last-import.xsl"/-->
    
    <xsl:template match="comment()"/>
    
    <xsl:output method="xml" indent="no" encoding="utf-8"/> 
    <xsl:template match="xi:views[not(xi:menu|xi:view)] | xi:menu[not(xi:option)]"/>
    <xsl:template match="xi:view/@justopen"/>
    <xsl:template match="xi:view[@justopen][not(xi:view-schema[descendant::xi:field[@editable or @name='xid'] or descendant::xi:form[@choise or @deletable or @extendable]])]/xi:menu/xi:option[@name='save']"/>
    
    <xsl:template match="xi:dialogue[xi:choose]/*[not(self::xi:choose or self::xi:input[key('id',@ref)/@type='parameter'])]"/>
    <xsl:template match="xi:dialogue/xi:grid/xi:columns/xi:column[@ref=../../xi:rows/xi:group/xi:by/@ref]"/>

    <xsl:template match="xi:dialogue[xi:choose and key('id',@current-step)//xi:input[not(@ref=key('id',ancestor::xi:view/xi:dialogue/xi:input/@ref)/@ref)]]/@action"/>
    
    <xsl:template match="xi:dialogue//xi:region[not(descendant::* [not(self::xi:region)] )]"/>
    
    <xsl:template match="xi:view[not(preceding-sibling::xi:view)]/@hidden"/>
    <xsl:template match="xi:view[@hidden][count(descendant::xi:datum[@editable])&gt;60 or count(descendant::xi:data) &gt; 150]"/>

    <xsl:template match="xi:session/xi:group"/>

    <xsl:template match="xi:view[xi:menu/xi:option[@chosen][@name='close'] and not(xi:view-data/xi:data//xi:exception)]"/>

    <xsl:template match="xi:option/@chosen | xi:events | xi:dummy | xi:data/@delete-null"/>
    <xsl:template match="xi:session/xi:data/xi:datum/@modified | xi:datum[@type='parameter']/@modified-"/>
    <xsl:template match="xi:userinput-debug/*"/>
    <xsl:template match="xi:data[descendant::xi:datum[@modified]]/xi:response[not(@ts)]"/>
    <xsl:template match="xi:response[not(@ts) and not(xi:sql)]"/>
    <xsl:template match="@unchoose-this"/>

    <xsl:template match="xi:datum[key('id',@ref)/@local-data]/@modified"/>
    
    <xsl:template match="xi:view-data//*[@toggle-edit-on]/xi:datum/@editable-off">
      <xsl:attribute name="editable">on</xsl:attribute>
    </xsl:template>

    <xsl:template match="xi:view-data//*[@toggle-edit-off]/xi:datum/@editable">
      <xsl:attribute name="editable-off">true</xsl:attribute>
    </xsl:template>

    <!--xsl:template match="xi:datum[not(.=@original-value)]/@original-value">
      <xsl:attribute name="modified">modified</xsl:attribute>
    </xsl:template-->

    <xsl:template match="/*[xi:userinput/*[@name='livechat' and text()='off']]/xi:session[@authenticated]/@livechat"/>

    <xsl:template match="xi:data[@choise]/@ts">
        <xsl:copy/>
        <xsl:attribute name="modified">chosen</xsl:attribute>
    </xsl:template>

    <xsl:template match="xi:menu[not(@name)]" mode="extend">
        <xsl:attribute name="name">
            <xsl:value-of select="local-name(..)"/>
        </xsl:attribute>
        <xsl:copy-of select="../@name"/>
    </xsl:template>

    <!--xsl:template match="xi:view-data" mode="extend">
        <xsl:for-each select="xi:data//xi:datum[@editable and not (text())]">
           <xsl:if test="position()=1">
              <xsl:attribute name="focus"><xsl:value-of select="@id"/></xsl:attribute>
           </xsl:if>
        </xsl:for-each>
    </xsl:template-->

    <xsl:template match="xi:region[not(ancestor-or-self::*/@class)]" mode="extend">
        <xsl:attribute name="class">default</xsl:attribute>
    </xsl:template>
    
    <xsl:template match="/*/@pipeline">
        <xsl:attribute name="pipeline">
            <xsl:value-of select="/*/xi:userinput/xi:command[@name='stage-last']"/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="xi:view/xi:menu/xi:option" mode="extend">
        <xsl:variable name="value"><xsl:apply-templates select="." mode="advisor"/></xsl:variable>
        <xsl:if test="string-length($value) &gt; 0">
            <xsl:attribute name="advisor"><xsl:value-of select="normalize-space($value)"/></xsl:attribute>
        </xsl:if>
    </xsl:template>

    <xsl:template match=
        "xi:view
        [xi:view-data//xi:datum[@type='field' and not (ancestor::xi:set-of[@is-choise])][@modified] 
        or xi:view-data//xi:data[@delete-this or ((@modified or @ts) and @role)
        ]
        ]/xi:menu/xi:option[@name='save']
        " mode="advisor">
        recommended
    </xsl:template>
    
    <xsl:template match="xi:view/xi:menu/xi:option[@name='save']" mode="advisor" priority="-1000">
        avoid
    </xsl:template>

    <xsl:template match="xi:view/xi:menu/xi:option[@name='save']/@disabled"/>

    <xsl:template match="xi:view/xi:menu/xi:option[@name='save']" mode="extend">
        <xsl:for-each select="ancestor::xi:view">
            <xsl:if test="
                xi:workflow [descendant::xi:command[@name='save']]
                | xi:workflow [descendant::xi:command[text()='save']]
                    [key('id',current()/xi:dialogue/@current-step)/xi:validate]
                | key('id',xi:dialogue/@current-step) [descendant::xi:command[text()='save']]
            ">
                <xsl:attribute name="disabled">true</xsl:attribute>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
</xsl:transform>
