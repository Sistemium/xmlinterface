<?xml version="1.0" ?>
<?xml-stylesheet type="text/xsl" href="html-xsl.xsl"?>

<xsl:transform version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://unact.net/xml/xi" 
  xmlns:xi="http://unact.net/xml/xi"
  xmlns:php="http://php.net/xsl"
  xmlns:e="http://exslt.org/common"
  extension-element-prefixes="e"
  exclude-result-prefixes="e php"
>

    <xsl:param name="model" select="document('domain.xml')/xi:domain"/>

    <xsl:include href="extend-build-request.xsl"/>
    <xsl:include href="extend-build-subrequest.xsl"/>
    <xsl:include href="xmlq.xsl"/>

    <!--xsl:template match="xi:view-data//xi:preload[@pipeline='clientData']" priority="1000">
		<xsl:copy-of select="."/>
	</xsl:template-->
	
    
    <xsl:template name="needrefresh"
				  match="xi:data[@refresh-this]
						|xi:set-of[@refresh-this][not(@refresh-this='prev' and @page-start=0)]
				        |xi:view-data//xi:preload
							[not( ancestor::xi:set-of[@is-choise] )]
							[not( @pipeline[not(.=/*/@pipeline-name)] )]
							[not( @preload ) or @refresh-this]
						">
		<xsl:copy>
			
			<xsl:if test="key('id',@ref)/@new-only">
				<xsl:attribute name="refresh-this">true</xsl:attribute>
			</xsl:if>
			
			<xsl:copy-of select="@*|xi:data|xi:datum|xi:extender|xi:set-of"/>
			
			<xsl:if test="not(key('id',@ref)/@new-only)">
				
				<xsl:variable name="xmlq-text">
					<xsl:apply-templates select="." mode="build-request">
						<xsl:with-param name="head">true</xsl:with-param>
					</xsl:apply-templates>
					<xsl:copy-of select="key('id',@ref)"/>
				</xsl:variable>
				
				<xsl:variable name="xmlq-nodes" select="e:node-set($xmlq-text)"/>
				
				<xsl:apply-templates select="$xmlq-nodes/xi:data-request"/>
				
			</xsl:if>
			
		</xsl:copy>
    </xsl:template>



    <xsl:template match="xi:datum|text()" mode="build-update"/>

    <xsl:template match="xi:data" mode="build-update"/>

    <xsl:template
	   match=
	       "xi:data[@delete-this
                or (@is-new and not(@role) and (
						(xi:datum[@type='field'] and not(xi:datum[@type='field'][@editable] or xi:data[@choise]) )
						or xi:datum[key('id',@ref)/@use-with-insert]
					)
				)
                or xi:datum[@type='field'][@modified]
                or xi:data[((@modified or @ts) and @role)]
		or (@persist-this and (xi:datum[@type='field'][@editable or @modifiable][@modified] or xi:data[@role][@ts]))
		or (@is-new and xi:datum[@type='field' and @editable] and key('id',descendant::xi:data[@persist-this]/@ref)/xi:join/@name=@name)
		][not(xi:data[@role and @required and not(*[key('id',@ref)/@key])]) and not(key('id',@ref)/@read-only)]
		"
          mode="build-update"
		  name="data-build-update"
    >
		<xsl:variable name="delete-null" select="
			xi:datum [
				(@modified='erase' or (key('id',@ref)/@type='int' and text()='0'))
				and key('id',@ref)/@when-null-then-delete
			]
		"/>
		
		<data-update program="{ancestor::xi:view/@name}">
			<xsl:variable name="this" select="."/>
			<xsl:variable name="concept" select="key('id',current()/@ref)/@concept"/>
            
			<xsl:attribute name="id"><xsl:value-of select="php:function('uuidSecure','')"/></xsl:attribute>
			
			<xsl:for-each select="$model/xi:concept[@name=$concept]">
				<xsl:apply-templates select="parent::xi:domain/@server"/>
				<xsl:apply-templates select="@*"/>
			</xsl:for-each>
			
			<xsl:attribute name="type">
				<xsl:choose>
					<xsl:when test="@delete-this or $delete-null">
						<xsl:text>delete</xsl:text>
					</xsl:when>
					<xsl:when test="@is-new">
						<xsl:text>insert</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>update</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
				
			<xsl:if test="not(@type='delete')">
				
				<xsl:apply-templates mode="build-set" select="
					self::xi:data[not(@role)][@is-new or @ts or @modified]
					/ancestor::xi:data[1][key('id',@ref)/@concept=$model/xi:concept[@name=$concept]/*/@actor]
				">
					<xsl:with-param name="sql-name" select="key('id',@ref)/@parent-sql-name"/>
				</xsl:apply-templates>
				
				<xsl:apply-templates mode="build-set" select="
					xi:datum [@type='field']
						[@modified or @modifiable or ((../@is-new and (@editable or key('id',@ref)/@use-with-insert)) and text()!='')]
					| xi:data [key('id',@ref)/@role]
						[@modified or @ts or (current()/@is-new and descendant::xi:datum[@type='field'])]
				"/>
				
				<xsl:for-each select="key('id',self::*[@is-new]/@ref)/xi:join">
					<xsl:apply-templates mode="build-set" select="
						$this/ancestor::xi:data
							[@name=current()/@name] [not(current()/@field)]
						| $this/ancestor::xi:data
							[@name=current()/@name]
							/xi:datum [@name=current()/@field]
								[not(following-sibling::xi:datum[@name=current()/@field])]
					">
						<xsl:with-param name="sql-name" select="@sql-name"/>
					</xsl:apply-templates>
				</xsl:for-each>
				
			</xsl:if>
			
			<xsl:apply-templates select="*[key('id',@ref)/@key='true'][not(@editable)]" mode="parameter"/>
			
		</data-update>
    </xsl:template>

    <xsl:template match="*" mode="build-set"/>

    <xsl:template match="xi:data" mode="build-set">
        <xsl:param name="sql-name" select="key('id',@ref)/@sql-name"/>
        <xsl:apply-templates select="*[key('id',@ref)/@key='true' and not(@name='xid')]" mode="build-set">
            <xsl:with-param name="name" select="@role|self::*[not(@role)]/@name"/>
            <xsl:with-param name="sql-name" select="$sql-name"/>
        </xsl:apply-templates>
	</xsl:template>

    <xsl:template match="xi:data[not(xi:datum)]" mode="build-set">
        <xsl:param name="sql-name" select="key('id',@ref)/@sql-name"/>
		<set name="{@role|self::*[not(@role)]/@name}">
				<xsl:copy-of select="key('id',@ref)/@sql-name"/>
				<xsl:if test="$sql-name">
					<xsl:attribute name="sql-name"><xsl:value-of select="$sql-name"/></xsl:attribute>
				</xsl:if>
		</set>
	</xsl:template>

	<xsl:template match="xi:datum[key('id',@ref)/@local-data]" mode="build-set"/>
	
	<xsl:template match="xi:datum" mode="build-set">
        <xsl:param name="name" select="@name"/>
        <xsl:param name="sql-name" select="@sql-name"/>
		<set name="{$name}">
				<xsl:copy-of select="key('id',@ref)/@type | key('id',@ref)/@sql-name"/>
				<xsl:if test="$sql-name">
					<xsl:attribute name="sql-name"><xsl:value-of select="$sql-name"/></xsl:attribute>
				</xsl:if>
				<xsl:value-of select="."/>
		</set>
    </xsl:template>


    <xsl:template match="xi:data" mode="parameter">
        <data>
			<xsl:apply-templates select="key('id',@ref)" mode="parameter"/>
            <xsl:apply-templates select="@name
										|*[not(key('id',@ref)[self::xi:field[@type='string']])]
										  [text() and not(text()='')]
										  [not(preceding-sibling::*/@name=@name)]
										|self::*[@chosen='ignore']/xi:set-of[@is-choise]"
								  mode="parameter"/>
        </data>
        <xsl:apply-templates select="xi:data[key('id',@ref)/@key='true']" mode="parameter"/>
    </xsl:template>

    <xsl:template match="@*" mode="parameter">
    	<xsl:copy/>
    </xsl:template>
    
    <xsl:template match="xi:datum" mode="parameter">
        <xsl:param name="name" select="@name"/>
        <parameter property="{$name}">
            <xsl:apply-templates select="key('id',@ref)" mode="parameter"/>
            <xsl:apply-templates select="$name | text()"/>
        </parameter>
    </xsl:template>

    <xsl:template match="xi:view-schema//*" mode="parameter">
		<xsl:apply-templates select="@sql-name | @type | @key | @use-like | @property" mode="parameter"/>
	</xsl:template>

    <xsl:template match="xi:set-of[@is-choise]" mode="parameter">
		
		<set-of-parameters>
			<xsl:apply-templates select="xi:data/*[key('id',@ref)/@key]" mode="parameter"/>
		</set-of-parameters>
		
	</xsl:template>

    <xsl:template match="*" mode="join-on"/>
    
    <xsl:template match="xi:parameter" mode="join-on">
        <xsl:param name="join-itself"/>
        <use concept="{../@name}" parameter="{@name}" property="{@name}">
            <xsl:apply-templates select="$join-itself/@property"/>
			<xsl:apply-templates select="$join-itself/node()" mode="build-subrequest"/>
        </use>
    </xsl:template> 

    <xsl:template match="xi:field" mode="join-on">
        <xsl:param name="join-itself"/>
        <join type="field">
            <on concept="{../@concept}" property="{@name}" name="{../@name}"/>
            <xsl:apply-templates select="$join-itself/*"/>
            <on concept="{$join-itself/parent::xi:form/@concept}"
				property="{$join-itself/*/@name|self::*[not($join-itself/*[@name])]/@name}"
				name="{$join-itself/parent::xi:form/@name}">
				<xsl:apply-templates select="$join-itself/@property"/>
			</on>
        </join>
    </xsl:template> 

    <xsl:template match="xi:role" mode="join-on">
		
        <xsl:param name="join-itself"/>
        <xsl:param name="form" select="$join-itself/.."/>
        <xsl:param name="joined" select="$form/.."/>
		
		<xsl:if test="not($form/@parent-role) or $form/@parent-role=@name">
			<join type="role">
				<on concept="{@name}" property="id">
					<xsl:attribute name="name">
						<xsl:value-of select="($joined|$form)[@concept=current()/@actor][1]/@name"/>
					</xsl:attribute>
					<xsl:apply-templates select="$model/xi:concept[@name=current()/@actor]/*[@name='id']/@type"/>
				</on>
				<on>
					<xsl:attribute name="concept">
						<xsl:if test="$form">
							<xsl:value-of select="parent::*[not(@name=$form/@concept)]/@name | $form[@concept=current()/../@name]/@concept"/>
						</xsl:if>
						<xsl:if test="not($form)">
							<xsl:value-of select="../@name"/>
						</xsl:if>
					</xsl:attribute>
					<xsl:attribute name="property">
						<xsl:value-of select="@name"/> 
					</xsl:attribute>
					<xsl:attribute name="name">
						<xsl:choose>
							<xsl:when test="$form/self::xi:form">
								<xsl:value-of select="($joined|$form)[@concept=current()/../@name][last()]/@name"/> 
							</xsl:when>
							<xsl:when test="$form/self::xi:exists">
								<xsl:value-of select="$form/@concept"/> 
							</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</on>
				<!--on concept="{../@name}" property="{@name}"/-->
			</join>
		</xsl:if>
		
    </xsl:template>
      
    <xsl:template match="xi:role[@composite]" mode="join-on">
        <xsl:variable name="this" select ="."/>
        <xsl:for-each select="ancestor::xi:domain/xi:concept[@name=current()/@actor]/*[@key]">
            <join>
                <on concept="{$this/../@name}" property="{@name}"/>
                <on concept="{../@name}" property="{@name}"/>
            </join>
        </xsl:for-each>
    </xsl:template>

</xsl:transform>