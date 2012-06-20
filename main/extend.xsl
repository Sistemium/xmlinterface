<?xml version="1.0" ?>
<?xml-stylesheet type="text/xsl" href="html-xsl.xsl"?>

<xsl:transform version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://unact.net/xml/xi" 
  xmlns:xi="http://unact.net/xml/xi"
  xmlns:php="http://php.net/xsl"
  xmlns:e="http://exslt.org/common"
  extension-element-prefixes="e"
  exclude-result-prefixes="e"
>
    <xsl:include href="extend-build.xsl"/>

	<!--xsl:template match="/*/@pipeline">
		<xsl:attribute name="pipeline">
			<xsl:text>commit</xsl:text>
		</xsl:attribute>
	</xsl:template>

	<xsl:template match="/*/@pipeline[.='' or descendant::xi:data-request]">
		<xsl:attribute name="pipeline">
			<xsl:text>repeat</xsl:text>
		</xsl:attribute>
	</xsl:template>
	
	<xsl:template match="/*/@pipeline[.='repeat' or descendant::xi:response]">
		<xsl:attribute name="pipeline">
			<xsl:text>quit</xsl:text>
		</xsl:attribute>
	</xsl:template-->

    <xsl:template match="xi:view[xi:menu/xi:option/@chosen]//xi:data/xi:response"/>
    
    <xsl:template match="xi:data/@persist-this"/>
   
    <xsl:template match="xi:data/@refresh-this "/>

    <xsl:template match="xi:data[@delete-this and @is-new]" priority="1000"/>

    <xsl:template match=
     " xi:view[xi:menu[xi:option[@chosen][@name='refresh']]]/xi:view-data/xi:data[not(@is-new) or xi:datum[@type='parameter']]
     | xi:view-data//xi:data[xi:datum[@type='parameter' and
									  @modified and
									  (not(@editable) or ancestor::xi:view/xi:dialogue//*/@ref = ancestor::xi:data/@ref|@id|@ref)
									 ] and
							 not(xi:datum[@type='parameter' and not(key('id',@ref)/@optional)][not(text()) or text()=''])
							]
     ">
		<xsl:call-template name="needrefresh"/>
    </xsl:template>

    <xsl:template match=
	    "xi:view[xi:menu[xi:option[@chosen][@name='save']]]/xi:view-data//xi:data
	    |xi:data[*[@modified][key('id',@ref)/@autosave or (not(@xpath-compute) and ../@persist-this)]
	            or self::*[@delete-this or descendant-or-self::*/@persist-this][key('id',@ref)/@autosave]
				or (@is-new and xi:datum[@type='field' and @editable] and key('id',descendant::xi:data[@is-new]/@ref)[@autosave]/xi:join/@name=@name)
			    ]
	    ">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			
			<xsl:if test="key('id',@ref)/@new-only">
				<xsl:copy-of select="@refresh-this"/>
			</xsl:if>
			
			<xsl:variable name="xmlq-text">
				<xsl:apply-templates select="." mode="build-update"/>
			</xsl:variable>
			
			<xsl:variable name="xmlq-nodes" select="e:node-set($xmlq-text)"/>
			
			<xsl:variable name="delete-null"
						  select="xi:datum[(@modified='erase' or (key('id',@ref)/@type='int' and text()='0')) and key('id',@ref)/@when-null-then-delete]"/>
				
			<xsl:if test="$xmlq-nodes and $delete-null">
				<xsl:attribute name="delete-null">true</xsl:attribute>
			</xsl:if>
			
			<xsl:apply-templates select="$xmlq-nodes"/>
			<xsl:apply-templates select="xi:data|xi:datum|xi:extender|xi:chosen|xi:preload|xi:set-of[not(@is-choise)]"/>
			<xsl:copy-of select="xi:set-of[@is-choise]"/>
		</xsl:copy>
    </xsl:template>


</xsl:transform>