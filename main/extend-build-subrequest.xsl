<?xml version="1.0" ?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns="http://unact.net/xml/xi"
    xmlns:php="http://php.net/xsl"
    xmlns:e="http://exslt.org/common"
    extension-element-prefixes="e"
    exclude-result-prefixes="e"
>

    <xsl:template match="xi:form[@new-only or xi:parameter[not(@optional) and not(xi:init)]]" mode="build-subrequest"/>

	
    <xsl:template match="xi:form[@expect-choise]/xi:form[not(@no-preload)]
						|xi:form[@pipeline][not(@pipeline=/*/@pipeline-name)]
						|xi:form[@preload]"
				  mode="build-subrequest" >
        <preload id="{php:function('uuidSecure','')}" ref="{@id}">
            <xsl:copy-of select="@name|@pipeline|@preload"/>
        </preload>
    </xsl:template>
	
	
	<xsl:template mode="build-subrequest" priority="1000" match="
		xi:form[
			/*/xi:userinput/*[@name='filter']
			and not( /*/xi:userinput/*[@name='filter']/text() =
				(
					self::*[not(/*/xi:userinput/*[@name='filter-strict'])]/ancestor::xi:form/@name
					| descendant-or-self::xi:form/@name
				)
		)]
	"/>

	
    <xsl:template match="xi:form" mode="build-subrequest">
        <xsl:variable name="concept" select="$model/xi:concept[@name=current()/@concept]"/>
        <data-request>
            <xsl:if test="parent::xi:xor">
                <xsl:attribute name="optional">true</xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="$concept/@*"/>
            <xsl:apply-templates select="@name|@sql-name|@concept|@constrain-parent|@page-size"/>
            <xsl:variable name="roles"
			 select="$concept/xi:role[@actor=current()/parent::xi:form/@concept and (@name=current()/@role or not(current()/@role))]
				|$model/xi:concept[@name=current()/parent::xi:form/@concept]
	    			/xi:role[@actor=$concept/@name and (@name=current()/@role or not(current()/@role))]
    				"/>
            <xsl:apply-templates select="$roles" mode="join-on">
                <xsl:with-param name="form" select="."/>
                <xsl:with-param name="joined" select=".."/>
            </xsl:apply-templates>
            <xsl:apply-templates select="*" mode="build-subrequest"/>
        </data-request>
    </xsl:template>

    <xsl:template match="xi:init" mode="build-subrequest">
       <xsl:apply-templates select="." mode="build-data"/>
    </xsl:template>

    <xsl:template match="xi:parameter | xi:field[xi:compute]" mode="build-subrequest"/>

    <xsl:template match="*" mode="build-subrequest">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:apply-templates select="node()" mode="build-subrequest"/>
		</xsl:copy>
    </xsl:template>

    <xsl:template match="xi:where|xi:parameter[xi:init]" mode="build-subrequest">
		<parameter property="{@name}">
			<xsl:apply-templates select="@name|@type|@use-like|@property"/>
			<xsl:apply-templates select="*|self::*[not(*)]/text()" mode="build-subrequest"/>
		</parameter>
    </xsl:template>

	<xsl:template match="xi:field[@pipeline][not(@pipeline=/*/@pipeline-name)]" mode="build-subrequest"/>

    <xsl:template match="xi:field" mode="build-subrequest">
       <column>
			<xsl:apply-templates select="@*"/>
       </column>
    </xsl:template>

    <xsl:template match="xi:order-by" mode="build-subrequest">
		<xsl:copy-of select="."/>
    </xsl:template>

<!--  join @name @field-value 
      check if it's valued yet before retrieve
-->

    <xsl:template match="xi:join[@by][xi:beta]" mode="build-subrequest">
		
		<xsl:param name="this" select="."/>
		<xsl:variable name="concept" select="$model/xi:concept[@name=current()/../@concept]"/>
		<xsl:variable name="by-concept" select="$model/xi:concept[@name=current()/@by]"/>
		<xsl:variable name="join-concept" select="ancestor::xi:view-schema//xi:form[@name=current()/@name]/@concept"/>
		
		<xsl:for-each select="
			$concept/xi:role [@actor=$by-concept/@name and (@name=current()/@by-role or not (current()/@by-role))]
			|$by-concept/xi:role [@actor=$concept/@name and (@name=current()/@by-role or not (current()/@by-role))]
		">
			<join type="by">
				<on name="{$this/@id}" property="id">
					<xsl:attribute name="concept">
						<xsl:choose>
							<xsl:when test="current()/@actor = $by/concept/@name">
								
							</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</on>
			</join>
		</xsl:for-each>
		
    </xsl:template>

    <xsl:template match="xi:join[not(@field|@by)]" mode="build-subrequest">
		
		<xsl:variable name="concept" select="$model/xi:concept[@name=current()/../@concept]"/>
		<xsl:variable name="join-concept" select="ancestor::xi:view-schema//xi:form[@name=current()/@name]/@concept"/>
		
		<xsl:apply-templates mode="join-on" select="
			$concept/xi:role [@actor=$join-concept and (@name=current()/@role or not (current()/@role))]
			|$model/xi:concept [@name=$join-concept]/xi:role[@actor=$concept/@name and (@name=current()/@role or not (current()/@role))]
		">
			<xsl:with-param name="form" select=".."/>
			<xsl:with-param name="joined" select="$join-concept/.."/>            
			<xsl:with-param name="join-itself" select="."/>
		</xsl:apply-templates>
		
    </xsl:template>

    <xsl:template match="xi:or" mode="build-subrequest">
		<xsl:copy>
			<xsl:apply-templates select="*" mode="build-subrequest"/>
		</xsl:copy>
	</xsl:template>
	
    <xsl:template match="xi:join[@field]" mode="build-subrequest">
		<xsl:apply-templates
				 select="preceding::xi:form[@name=current()/@name]/*[@name=current()/@field][not(preceding-sibling::*[@name=current()/@field])]
						|ancestor::xi:form[@name=current()/@name] /*[@name=current()/@field][not(preceding-sibling::*[@name=current()/@field])]"
					 mode="join-on">
			<xsl:with-param name="form" select=".."/>
			<xsl:with-param name="join-itself" select="."/>
			<xsl:with-param name="joined" select="preceding::xi:form[@name=current()/@name]|ancestor::xi:form[@name=current()/@name]"/>
		</xsl:apply-templates>
    </xsl:template>

</xsl:transform>
