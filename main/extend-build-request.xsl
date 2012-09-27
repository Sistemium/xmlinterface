<?xml version="1.0" ?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns="http://unact.net/xml/xi"
    xmlns:php="http://php.net/xsl"
    xmlns:e="http://exslt.org/common"
    extension-element-prefixes="e"
    exclude-result-prefixes="e php"
>

    <xsl:template match="xi:set-of | xi:data | xi:data/xi:preload | xi:upload/xi:preload" mode="build-request">
		
        <xsl:param name="head"/>
		
        <data-request show-sql="true">
			
            <xsl:variable name="this" select="."/>
            <xsl:variable name="form" select="key('id',@ref)"/>
            <xsl:variable name="concept" select="$model/xi:concept[@name=$form/@concept]"/>
            
            <xsl:attribute name="id">
                <xsl:value-of select="php:function('uuidSecure','')"/>
            </xsl:attribute>
            
            <xsl:apply-templates select="$concept/@*" />
            <xsl:apply-templates select="$form/@*" mode="build-request"/>
            
			<xsl:if test="$form/@page-size">
				<xsl:attribute name="page-start">0</xsl:attribute>
			</xsl:if>
            
			<xsl:for-each select="self::*[@refresh-this='next']/@page-start">
				<xsl:attribute name="page-start">
					<xsl:value-of select=". + 1"/>
				</xsl:attribute>
			</xsl:for-each>
			
			<xsl:for-each select="self::*[@refresh-this='prev']/@page-start">
				<xsl:attribute name="page-start">
					<xsl:value-of select=". - 1"/>
				</xsl:attribute>
			</xsl:for-each>
			
			<xsl:for-each select="self::*[@refresh-this='true']/@page-start">
				<xsl:attribute name="page-start">
					<xsl:value-of select="."/>
				</xsl:attribute>
			</xsl:for-each>
			
            <xsl:choose>
    	        <xsl:when test="xi:datum[@type='parameter'][text()!='']">
                    <xsl:apply-templates select="xi:datum[@type='parameter' or @type='where'][text()!='']" mode="parameter"/>
                </xsl:when>
                <xsl:when test="*[key('id',@ref)/@key]">
                    <xsl:apply-templates select="*[key('id',@ref)/@key or @type='where']" mode="parameter"/>
                </xsl:when>
            </xsl:choose>
            
            <xsl:for-each select="$form/*[not(self::xi:parameter)][self::xi:field or not(current()/self::xi:preload[not(parent::xi:data)])]">
                <xsl:choose>
                    <xsl:when test="self::xi:form[xi:parameter[not(@optional) and not(xi:init)]] and $this/xi:data[@ref=current()/@id]">
            	        <xsl:apply-templates select="$this/xi:data[@ref=current()/@id]" mode="build-request"/>
                    </xsl:when>
                    <xsl:otherwise>
            	        <xsl:apply-templates select="." mode="build-subrequest"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
            
            <xsl:if test="
                    parent::xi:data
                    and not(
                        (@refresh-this or $head) and (parent::*[@is-new] or (@role and xi:datum[@type='parameter']))
                    )
            ">
                <xsl:apply-templates mode="join-on" select="
                        $concept/xi:role [@actor=$form/parent::xi:form[xi:field]/@concept]
                        |$model/xi:concept [@name=$form/parent::xi:form[xi:field]/@concept]
                        /xi:role [@actor=$concept/@name and (@name=$form/@role or not($form/@role))]
				">
                    <xsl:with-param name="form" select="$form"/>
                </xsl:apply-templates>
            </xsl:if>
            
            <xsl:if test="(@refresh-this or $head)">
                <!--xsl:apply-templates select="self::xi:data[not(@role)]/parent::xi:data" mode="parameter"/-->
    	        <etc>
        	        <xsl:apply-templates
                        select="ancestor::xi:data[not(ancestor::xi:set-of[@is-choise])]
						       |preceding-sibling::xi:data/descendant-or-self::xi:data
							    [@name=$form//xi:join/@name][not(ancestor::xi:set-of[@is-choise])]
						       " mode="parameter"/>
    	        </etc>
            </xsl:if>
			
        </data-request>
		
    </xsl:template>
    

    <xsl:template mode="build-request" priority="1000" match="
		*[xi:datum[@type='parameter' and not(key('id',@ref)/@optional) and (not(text()) or text()='')]]
	"/>
    
	
    <xsl:template mode="build-request" priority="1000" match="
        xi:data/xi:preload
            [@pipeline
                and /*/xi:userinput/*[@name='filter']
                and not( /*/xi:userinput/*[@name='filter']/text() =
                    (
                        ancestor-or-self::*/@name
                        | descendant::*/@name
                        | key('id',@ref)/descendant::xi:form/@name
                    )
                )
            ]"
	/>
    

	<xsl:template match="@*" mode="build-request"/>

	
    <xsl:template match="@concept|@name|@page-size" mode="build-request">
		<xsl:copy-of select="."/>
	</xsl:template>
    

</xsl:transform>
