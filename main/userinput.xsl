<?xml version="1.0" ?>
<xsl:transform version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns="http://unact.net/xml/xi"
 xmlns:xi="http://unact.net/xml/xi">
  
    <xsl:import href="stage-1-import.xsl"/>

    <xsl:key name="name" match="xi:data|xi:form|xi:datum|xi:field|xi:parameter" use="@name"/>
    
    <xsl:template match="xi:message"/>
    <xsl:template match="xi:option/@chosen|xi:events"/>
    
    <xsl:template match="xi:session [xi:role[@name='admin'] and /*/xi:userinput/xi:command[@name='--set-username']]/@username">
        <xsl:attribute name="username">
            <xsl:value-of select="../../xi:userinput/xi:command[@name='--set-username']"/>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="xi:userinput/xi:command[key('id',@name)/self::xi:navigate]">
        
        <xsl:param name="datum" select="key('id',text())"/>
        
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:for-each select="key('id',@name)/self::xi:navigate/xi:pull">
                <xsl:copy>
                    <xsl:copy-of select="@name"/>
                    <xsl:apply-templates select="$datum/ancestor::*/xi:datum[@ref=current()/@ref]" mode="pull-value">
                        <xsl:with-param name="xpath" select="@xpath"/>
                    </xsl:apply-templates>
                </xsl:copy>
            </xsl:for-each>
        </xsl:copy>
        
    </xsl:template>
    
    <xsl:template mode="pull-value" match="*">
        <xsl:param name="xpath" />
        <xsl:if test="$xpath">
            <xsl:value-of select="xi:xpath($xpath)"/>
        </xsl:if>
        <xsl:apply-templates select="self::*[not($xpath)]/node()" mode="pull-value"/>
    </xsl:template>
    
    <!-- недоделка: предусмотреть отправку сообщений в активное вью -->
    
    <xsl:template match="xi:view[not(@hidden)]//*[@editable or (@modifiable and not(@xpath-compute))]/text()"/>
    
    <xsl:template match="xi:view[not(@hidden)][/*/xi:userinput/xi:command[@name='views']] | xi:view[@hidden]">
        <xsl:copy-of select="."/>
    </xsl:template>
    

</xsl:transform>
