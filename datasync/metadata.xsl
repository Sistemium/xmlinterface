<?xml version="1.0" ?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://unact.net/xml/xi"
    xmlns:xi="http://unact.net/xml/xi"
    exclude-result-prefixes="xi">

    <xsl:key name="id" match="*" use="@id"/>
    <xsl:variable name="lcletters">abcdefghijklmnopqrstuvwxyz</xsl:variable>
    <xsl:variable name="ucletters">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>

    <xsl:param name="model" select="document(/*/xi:session/xi:domains/xi:domain/@href)/xi:domain/xi:concept"/>
    
    <xsl:template match="node()"/>

    <xsl:template match="*">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="/">
        <metadata>
            <xsl:variable name="style" select="*/xi:userinput/xi:command[@name='style']"/>
            <xsl:if test="$style">
                <xsl:attribute name="style">
                    <xsl:value-of select="$style"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates/>
        </metadata>
    </xsl:template>

    <xsl:template match="xi:command[@name='metadata']">
        <xsl:apply-templates select="//*[local-name()=current()/text()]" mode="metadata">
            <xsl:with-param name="non-recursive" select="1"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="@id" mode="metadata"/>
    
    <xsl:template match="*|@*" mode="metadata">
        <xsl:param name="non-recursive"/>
        <xsl:copy>
            <xsl:apply-templates select="@*|node()[not($non-recursive) or not(local-name() = local-name(current()))]" mode="metadata"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="xi:view" mode="metadata">
        <xsl:copy-of select="@* | xi:view-schema/@*"/>
        <xsl:apply-templates select="*" mode="metadata"/>
    </xsl:template>

    <xsl:template match="xi:menu|xi:dialogue" mode="metadata"/>

    <xsl:template match="xi:view-schema" mode="metadata">
        <xsl:variable name="forms" select="descendant::xi:form[not(@hidden)]"/> 
        <tables set-of="table"><xsl:for-each select="$forms">
            
            <xsl:variable name="form" select="."/>
            
            <table id="{@name}" name="{@label}" nameSet="{@set-label}" level="{count(ancestor::xi:form[not(@hidden)])}">
                
                <xsl:copy-of select="@extendable | @deletable | */@editable | @mainMenu"/>
                
                <xsl:if test="$model[@name=current()/@concept]/xi:role[@actor=current()/../@concept][@type='belongs']">
                    <xsl:attribute name="belongs">
                        <xsl:value-of select="parent::*/@name"/>
                    </xsl:attribute>
                </xsl:if>
                
                <columns set-of="column"><xsl:for-each select="xi:field">
                    
                    <column id="{../@name}{@alias}" name="{@alias}">
                        
                        <xsl:attribute name="type">
                            <xsl:choose>
                                <xsl:when test="@type='decimal'">float</xsl:when>
                                <xsl:otherwise><xsl:value-of select="@type"/></xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        
                        <xsl:for-each select="$forms[@concept = $model[@name=current()/../@concept]/xi:role[@name=current()/@alias]/@actor]">
                            <xsl:attribute name="parent"><xsl:value-of select="@name"/></xsl:attribute>
                            <xsl:copy-of select="@label"/>
                            <xsl:if test="$form/@extendable">
                                <xsl:attribute name="editable">true</xsl:attribute>
                            </xsl:if>
                        </xsl:for-each>
                        
                        <xsl:copy-of select="@label|@editable|@aggregable|@title|@init|self::*[not(@name='xid')]/@key"/>
                        
                    </column>
                    
                </xsl:for-each></columns>
                
                <deps set-of="dep"><xsl:for-each select="$model/xi:role[@actor=current()/@concept]">
                    <xsl:variable name="role" select="."/>
                    <!--xsl:comment>
                        <xsl:value-of select="concat(local-name(),':',@name,':',@actor,':',../@name)"/>
                    </xsl:comment-->
                    <xsl:for-each select="$forms[@concept=current()/../@name][not(@no-inwards)]/xi:field[@alias=current()/@name][not(@no-inwards)]">
                        <dep table_id="{../@name}" id="{../@name}{@alias}">
                            <xsl:if test="$role/@type='belongs'">
                                <xsl:attribute name="contains">true</xsl:attribute>
                            </xsl:if>
                        </dep>
                    </xsl:for-each>
                </xsl:for-each></deps>
                
            </table>
            
        </xsl:for-each></tables>
        
    </xsl:template>

    <xsl:template match="xi:workflow" mode="metadata">
        <xsl:variable name="steps" select="descendant::xi:step[not(@hidden)]"/>

        <views set-of="view"><xsl:for-each select="$steps">
            
            <xsl:copy-of select="@extendable | @deletable | @mainMenu"/>
            
            <view id="{@name}" name="{@label}" nameSet="{@set-label}">
                <xsl:variable name="view" select="."/>
                
                <columns set-of="column"><xsl:for-each select="descendant::*[self::xi:input|self::xi:print]">
                
                    <xsl:variable name="alias">
                        <xsl:choose>
                            <xsl:when test="@alias">
                                <xsl:value-of select="@alias"/>
                            </xsl:when>
                            <xsl:when test="key('id',@ref)/@alias">
                                <xsl:value-of select="key('id',@ref)/@alias"/>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:variable>
                    
                    <xsl:for-each select="key('id',@ref)">
                        <xsl:variable name="formAlias" select="
                            concat(
                                translate(substring(self::xi:form/@name,1,1),$ucletters,$lcletters)
                                , substring(self::xi:form/@name,2)
                            )
                        "/>
                        
                        <column id="{$view/@name}{$alias}{$formAlias}" name="{$alias}{$formAlias}" >
                            <xsl:attribute name="type">
                                <xsl:choose>
                                    <xsl:when test="@type='decimal'">float</xsl:when>
                                    <xsl:otherwise><xsl:value-of select="@type"/></xsl:otherwise>
                                </xsl:choose>
                            </xsl:attribute>
                            <xsl:copy-of select="@label"/>
                        </column>
                    </xsl:for-each>
                    
                </xsl:for-each></columns>
                
                <xsl:for-each select="xi:sql">
                    <xsl:copy>
                        <xsl:value-of select="."/>
                    </xsl:copy>
                </xsl:for-each>
                
            </view>
            
        </xsl:for-each></views>
        
    </xsl:template>


</xsl:transform>
