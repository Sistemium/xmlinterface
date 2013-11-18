<?xml version="1.0" ?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns="http://unact.net/xml/xi"
    
    xi:usage="import"
    
>

    <xsl:key match="xi:datum" name="ref" use="@ref"/>

    <xsl:template match="xi:userinput">
        
        <targets>
            <xsl:apply-templates select="*" mode="build-target"/>
        </targets>
        
    </xsl:template>


    <!-- build-target -->
    
    
    <xsl:template mode="build-target" match="*">
        
        <xsl:param name="command" select="/.."/>
        
        <xsl:apply-templates select="*" mode="build-target">
            <xsl:with-param name="command" select="$command"/>
        </xsl:apply-templates>
        
    </xsl:template>
    
    
    <xsl:template mode="build-target" match="xi:userinput/xi:command">
        
        <xsl:apply-templates mode="build-target" select="
            key('id',current()/@name)
        ">
            <xsl:with-param name="command" select="."/>
        </xsl:apply-templates>
        
    </xsl:template>


    <xsl:template mode="build-target" match="xi:field[@autofill-for]">
        
        <xsl:param name="command" select="/.."/>
        
        <xsl:if test="$command='mass-autofill'">
            <xsl:for-each select="key('ref',current()/@autofill-for)">
                <xsl:call-template name="build-target">
                    <xsl:with-param name="target-id" select="@id"/>
                    <xsl:with-param name="payload" select="
                        (descendant::xi:data|ancestor-or-self::xi:data)
                        [@name=key('id',current()/@ref)/@autofill-form]
                        /xi:datum[@name=key('id',current()/@ref)/@autofill]
                    "/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:if>
        
    </xsl:template>


    <xsl:template mode="build-target" match="xi:field">
        
        <xsl:param name="command" select="/.."/>
        
        <xsl:for-each select="key('ref',@id)/self::xi:datum">
            <xsl:call-template name="build-target">
                <xsl:with-param name="target-id" select="@id"/>
                <xsl:with-param name="payload" select="$command"/>
            </xsl:call-template>
        </xsl:for-each>
        
    </xsl:template>


    <xsl:template mode="build-target" match="xi:command [key('id',@ref)/self::xi:field] [@xpath-compute or text()='mass-autofill']">
        
        <xsl:param name="command"/>
        <xsl:param name="this" select="."/>
        
        <xsl:apply-templates mode="build-target" select="key('id',@ref)">
            <xsl:with-param name="command" select="."/>
        </xsl:apply-templates>
        
    </xsl:template>
    
    <xsl:template mode="build-target" match="xi:step//xi:options//xi:command" priority="1000"/>
    
    <xsl:template mode="build-target" match="xi:command [not(@name|@ref)] [@xpath-compute|xi:xpath-compute]">
        
        <xsl:param name="command"/>
        <xsl:param name="this" select="."/>
        
        <xsl:for-each select="xi:map(
            (key('id', $command) | $this)[1]
            , self::*[not(xi:xpath-compute)]/@xpath-compute
            | xi:xpath-compute
        )">
            <xsl:call-template name="build-target">
                <xsl:with-param name="target-id" select="current()/@id|current()[not(@id)]"/>
                <xsl:with-param name="payload" select="$this"/>
            </xsl:call-template>
        </xsl:for-each>
        
    </xsl:template>
    
    <xsl:template mode="build-target" match="
        xi:when [not(
            ancestor::xi:view/xi:view-data
            //xi:datum [@ref=current()/@ref]
            /text() [not(.='0' and key('id',../@ref)/@type='boolean')]
        )]
    ">
        <xsl:comment>xi:when removed</xsl:comment>
    </xsl:template>
    

    <xsl:template mode="build-target" match="xi:command [@ref = ancestor::xi:view/xi:view-data//xi:data[@choise]/@ref]">
        
        <xsl:param name="command"/>
        <xsl:param name="this" select="."/>
        
        <xsl:variable name="payload" select="xi:map(
                key('id', $command)
                , self::*[not(xi:xpath-compute)]/@xpath-compute
                | xi:xpath-compute
            ) | self::*[not(xi:xpath-compute|@xpath-compute)]
        "/>
        
        <xsl:call-template name="build-target">
                <xsl:with-param name="target-id" select="ancestor::xi:view/xi:view-data//xi:data[@choise][@ref=current()/@ref]/@id"/>
                <xsl:with-param name="payload" select="$payload"/>
        </xsl:call-template>
        
    </xsl:template>
    
    
    <xsl:template mode="build-target" match="
        xi:on/*/xi:command
            [ @name = ancestor::xi:view/xi:view-data//xi:set-of/@name ]
    ">
        
        <xsl:call-template name="build-target">
                <xsl:with-param name="target-id" select="ancestor::xi:view/xi:view-data//xi:set-of [@name=current()/@name]/@id"/>
                <xsl:with-param name="payload" select="current()"/>
        </xsl:call-template>
        
    </xsl:template>
    
    
    <xsl:template mode="build-target" match="
        xi:on/*/xi:command
            [ @name = ancestor::xi:view/xi:view-data
                //* [self::xi:preload|self::xi:data] /@name
            ]
    ">
        
        <xsl:call-template name="build-target">
            <xsl:with-param name="target-id" select="
                ancestor::xi:view/xi:view-data
                    //* [self::xi:preload|self::xi:data]
                        [@name=current()/@name]/@id
            "/>
            <xsl:with-param name="payload" select="current()"/>
        </xsl:call-template>
        
    </xsl:template>
    
    
    <xsl:template mode="build-target" match="
        xi:command [@name = ancestor::xi:workflow/@name or @name = ancestor::xi:view/@name]
            [text()= ancestor::xi:view/xi:step/@name]
    ">
        
        <xsl:param name="command"/>
        
        <xsl:apply-templates mode="build-target" select="
            ancestor::xi:workflow
            /xi:step [@name=current()/text()]
            /xi:on/xi:activation/*
        ">
            <xsl:with-param name="command" select="$command"/>
        </xsl:apply-templates>
        
    </xsl:template>


    <xsl:template mode="build-target" match="
        xi:command [@name = /*/xi:views/xi:view[1]/@name]
    ">
        
        <xsl:param name="command"/>
        <xsl:variable name="target" select="/*/xi:views/xi:view[1]/xi:workflow/xi:step[@name=current()/text()]"/>
        
        <xsl:apply-templates mode="build-target" select="$target/xi:on/xi:activation/*">
            <xsl:with-param name="command" select="$command"/>
        </xsl:apply-templates>
        
    </xsl:template>


    <!-- build-target helper -->
    
    
    <xsl:template name="build-target">
        
        <xsl:param name="target-id"/>
        <xsl:param name="payload"/>
        
        <target ref="{$target-id}">
            <xsl:apply-templates mode="build-target-value" select="$payload">
                <xsl:with-param name="target" select="current()"/>
            </xsl:apply-templates>
        </target>
        
    </xsl:template>
    
    
    <!-- build-target-value -->
    
    
    <xsl:template mode="build-target-value" match="*[*]">
        <xsl:param name="target" select="xi:null"/>
        <!--xsl:comment>
            <xsl:value-of select="local-name()"/>
        </xsl:comment-->
        <xsl:apply-templates mode="build-target-value" select="*">
            <xsl:with-param name="target" select="$target"/>
        </xsl:apply-templates>
    </xsl:template>
    
    
    <xsl:template mode="build-target-value" match="xi:xpath-compute[text()]">
        <xsl:param name="target" select="."/>
        <!--xsl:comment>1</xsl:comment-->
        <xsl:value-of select="xi:map($target, text())"/>
    </xsl:template>
    
    <xsl:template mode="build-target-value" match="*[text()][not(*)]">
        <!--xsl:comment>text of <xsl:value-of select="local-name()"/></xsl:comment-->
        <xsl:copy-of select="text()"/>
    </xsl:template>
    
    
    <xsl:template mode="build-target-value" match="*[not(*|text()|@xpath-compute)]">
        <!--xsl:comment>*</xsl:comment-->
        <xsl:copy-of select="."/>
    </xsl:template>
    
    <xsl:template mode="build-target-value" match="*[@name|@ref][@xpath-compute]">
        <xsl:param name="target" select="."/>
        <!--xsl:comment>1</xsl:comment-->
        <xsl:value-of select="xi:map($target, @xpath-compute)"/>
    </xsl:template>
    
    
</xsl:transform>
