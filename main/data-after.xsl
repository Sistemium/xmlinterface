<?xml version="1.0" ?>
<xsl:transform version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns="http://unact.net/xml/xi"
 xmlns:xi="http://unact.net/xml/xi"
 >

   <xsl:template match="
        xi:set-of[@choise]//xi:datum/@xpath-compute
        |
        xi:set-of[@choise]//xi:datum/@modifiable
        |
        @close-siblings   
   "/>
   
    <xsl:template match="*[xi:set-of/@close-siblings]/xi:set-of[not(@close-siblings) and @name=../*[@close-siblings]/@name]/*" priority="1001">
        <xsl:comment>removed by close-siblings</xsl:comment>
    </xsl:template>
   
   
    <xsl:template match="xi:view//*[not(@ref)][@form and @field]" mode="extend">
        <xsl:apply-templates mode="build-ref" select="
            ancestor::xi:view/xi:view-schema//xi:form[@name=current()/@form]/*
                [self::xi:field or self::xi:parameter][@name=current()/@field]
                [not(current()/self::xi:input or current()/self::xi:print)
                    or (current()/self::xi:input and @editable)
                    or (current()/self::xi:print and last())
                ]
        "/>
    </xsl:template>

    <!--xsl:template match="xi:view[xi:menu/xi:option/@chosen]//xi:data/xi:response"/-->

    <xsl:template match="xi:display//*[@form and @field='*']">
        <xsl:variable name="this" select="."/>
        <xsl:for-each select="
            ancestor::xi:view/xi:view-schema//xi:form[@name=current()/@form]/*
                [self::xi:field or self::xi:parameter][@label][not(@id=current()/../*/@ref)]
                [not(current()/self::xi:input or current()/self::xi:print)
                 or (current()/self::xi:input and @editable) or (current()/self::xi:print and last())
                ]
        ">
            <xsl:element name="{local-name($this)}">
                <xsl:copy-of select="$this/@*"/>
                <xsl:attribute name="ref"><xsl:value-of select="@id"/></xsl:attribute>
                <xsl:attribute name="field"><xsl:value-of select="@name"/></xsl:attribute>
                <xsl:apply-templates />
            </xsl:element>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="xi:data/*[key('id',@ref)/xi:natural-key]" mode="build-id">
        <xsl:apply-templates select="key('id',@ref)/xi:natural-key" mode="build-data">
            <xsl:with-param name="data" select="."/>
        </xsl:apply-templates>
    </xsl:template>


    <xsl:template mode="extend" match="
        xi:extender[not(@id)]
        |
        xi:datum[not(@id) and not(ancestor::xi:set-of[@is-choise])]
        |
        xi:data[not(@id)]
    ">
      
        <xsl:apply-templates select="." mode="build-id"/>
        
        <xsl:if test="self::xi:data[xi:set-of[@is-choise][not(@id)]]">
            <xsl:call-template name="build-choise-ref"/>
        </xsl:if>
        
        <xsl:variable name="chosen" select="        
            self::xi:data[@choise and not (@chosen)]/ancestor::xi:view-data//xi:data
                [@name=current()/@choise][xi:datum[@name='id']=current()/xi:datum[@name='id']]
        "/>
        
        <xsl:for-each select="$chosen">
           
            <xsl:attribute name="chosen"><xsl:value-of select="@id"/></xsl:attribute>
           
            <xsl:if test="not(@id)">
                <xsl:apply-templates select="$chosen" mode="build-id">
                    <xsl:with-param name="name">chosen</xsl:with-param>
                </xsl:apply-templates>
            </xsl:if>
            
        </xsl:for-each>
        
    </xsl:template>

    <xsl:template match="
        xi:exception[not(text()) and not(*)]
        |
        xi:extender[ancestor::xi:set-of[@is-choise]]
        |
        xi:data[not(@is-new)]/xi:datum[key('id',@ref)/@editable='new-only']/@editable
   "/>

    <xsl:template
        match="xi:option[not(@id)] | xi:choise[not(@id)] | xi:set-of[not(@id)]"
        mode="extend"
    >
        <xsl:apply-templates select="." mode="build-id"/>
    </xsl:template>

    <xsl:template match="xi:data[@id][xi:set-of[@is-choise] and not(@choise)]" mode="extend" name="build-choise-ref">
       <xsl:apply-templates select="xi:set-of[@is-choise]" mode="build-id">
           <xsl:with-param name="name">choise</xsl:with-param>
       </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="xi:view-data//*[@toggle-edit|@is-new]/@toggle-edit-off">
        <xsl:attribute name="toggle-edit-on">true</xsl:attribute>
    </xsl:template>
   
    <xsl:template match="xi:view-data//*[@toggle-edit and not(@is-new)]/@toggle-edit-on">
        <xsl:attribute name="toggle-edit-off">true</xsl:attribute>
    </xsl:template>

   <xsl:template match="xi:view-data//*/@toggle-edit"/>

   <!--xsl:template match="xi:choise/xi:data[not(@label)]" mode="extend">
        <xsl:attribute name="label">
            <xsl:variable name="selfdatum" select="xi:datum[@name='name']"/>
            <xsl:for-each select="$selfdatum|self::*[not($selfdatum)]/xi:data/xi:datum[@name='name']">
                <xsl:value-of select="."/>
                <xsl:if test="position()!=last()"><xsl:text>, </xsl:text></xsl:if>
            </xsl:for-each>
        </xsl:attribute>
        <xsl:if test="not(@id)">
            <xsl:apply-templates select="." mode="build-id"/>
        </xsl:if>
   </xsl:template-->
   

</xsl:transform>