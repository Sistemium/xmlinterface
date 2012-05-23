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

    <xsl:param name="model" select="document('domain.xml')/xi:domain"/>

    <xsl:include href="xmlq.xsl"/>

    <!--xsl:template match="xi:view-data//xi:preload[@pipeline='clientData']" priority="1000">
		<xsl:copy-of select="."/>
	</xsl:template-->
	
    
    <xsl:template name="needrefresh"
				  match="xi:data[@refresh-this]
						|xi:set-of[@refresh-this][not(@refresh-this='prev' and @page-start=0)]
				        |xi:view-data//xi:preload[not(ancestor::xi:set-of[@is-choise] or @pipeline[not(.=/*/@pipeline-name)])]
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
		or (@persist-this and (xi:datum[@type='field'][@editable or @modifiable] or xi:data[@role][@ts]))
		or (@is-new and xi:datum[@type='field' and @editable] and key('id',descendant::xi:data[@persist-this]/@ref)/xi:join/@name=@name)
		][not(xi:data[@role and @required and not(*[key('id',@ref)/@key])]) and not(key('id',@ref)/@read-only)]
		"
          mode="build-update"
		  name="data-build-update"
    >
		<xsl:variable name="delete-null" select="xi:datum[(@modified='erase' or (key('id',@ref)/@type='int' and text()='0')) and key('id',@ref)/@when-null-then-delete]"/>
						
		<data-update>
			<xsl:variable name="this" select="."/>
			<xsl:variable name="concept" select="key('id',current()/@ref)/@concept"/>
            
			<xsl:attribute name="id"><xsl:value-of select="php:function('uuidSecure','')"/></xsl:attribute>
			
			<xsl:apply-templates select="$model/xi:concept[@name=$concept]/@*"/>
				
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
				
				<xsl:apply-templates select="self::xi:data[not(@role)][@is-new or @ts or @modified]
				                            /ancestor::xi:data[1][key('id',@ref)/@concept=$model/xi:concept[@name=$concept]/*/@actor]"
									 mode="build-set">
					<xsl:with-param name="sql-name" select="key('id',@ref)/@parent-sql-name"/>
				</xsl:apply-templates>
				
				<xsl:apply-templates select="xi:datum[@type='field'][@modified or @modifiable or ((../@is-new and (@editable or key('id',@ref)/@use-with-insert)) and text()!='')]
						|xi:data[@modified or @ts or (current()/@is-new and descendant::xi:datum[@type='field'])][key('id',@ref)/@role]
						" mode="build-set"/>
				
				<xsl:for-each select="key('id',self::*[@is-new]/@ref)/xi:join">
					<xsl:apply-templates select="$this/ancestor::xi:data[@name=current()/@name][not(current()/@field)]
						|$this/ancestor::xi:data[@name=current()/@name]
						/xi:datum[@name=current()/@field][not(following-sibling::xi:datum[@name=current()/@field])]
						" mode="build-set">
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

    <xsl:template match="*[xi:datum[@type='parameter' and not(key('id',@ref)/@optional) and (not(text()) or text()='')]]" mode="build-request" priority="1000"/>
	
    <xsl:template match="xi:data/xi:preload
						[@pipeline
							and /*/xi:userinput/*[@name='filter']
							and not( /*/xi:userinput/*[@name='filter']/text() =
								(
									ancestor-or-self::*/@name
									| descendant::*/@name
								    | key('id',@ref)/descendant::xi:form/@name
								)
							)
						]" mode="build-request" priority="1000"
	/>

	<xsl:template match="@*" mode="build-request"/>

	<xsl:template match="@concept|@name|@page-size" mode="build-request">
		<xsl:copy-of select="."/>
	</xsl:template>

    <xsl:template match="xi:set-of | xi:data | xi:data/xi:preload | xi:upload/xi:preload" mode="build-request">
		
        <xsl:param name="head"/>
		
        <data-request show-sql="true">
			
            <xsl:variable name="this" select="."/>
            <xsl:variable name="form" select="key('id',@ref)"/>
            <xsl:variable name="concept" select="$model/xi:concept[@name=$form/@concept]"/>
            
            <xsl:attribute name="id"><xsl:value-of select="php:function('uuidSecure','')"/></xsl:attribute>
            
            <xsl:apply-templates select="$concept/@*" />
            <xsl:apply-templates select="$form/@*" mode="build-request"/>
            
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

            <xsl:for-each select="$form/*[not(self::xi:parameter)]">
                <xsl:choose>
                    <xsl:when test="self::xi:form[xi:parameter[not(@optional) and not(xi:init)]] and $this/xi:data[@ref=current()/@id]">
            	        <xsl:apply-templates select="$this/xi:data[@ref=current()/@id]" mode="build-request"/>
                    </xsl:when>
                    <xsl:otherwise>
            	        <xsl:apply-templates select="." mode="build-subrequest"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>

            <xsl:if test="not((@refresh-this or $head) and (parent::*[@is-new] or (@role and xi:datum[@type='parameter'])))">
                <xsl:apply-templates
                    select="$concept/xi:role[@actor=$form/parent::xi:form/@concept]
					       |$model/xi:concept[@name=$form/parent::xi:form/@concept]
					       /xi:role[@actor=$concept/@name and (@name=$form/@role or not($form/@role))]
					       " mode="join-on">
                    <xsl:with-param name="form" select="$form"/>
                </xsl:apply-templates>
            </xsl:if>

            <xsl:if test="(@refresh-this or $head)">
                <!--xsl:apply-templates select="self::xi:data[not(@role)]/parent::xi:data" mode="parameter"/-->
    	        <etc>
        	        <xsl:apply-templates
                        select="ancestor::xi:data[not(ancestor::xi:choise)]
						       |preceding-sibling::xi:data/descendant-or-self::xi:data
							    [@name=$form//xi:join/@name][not(ancestor::xi:choise)]
						       " mode="parameter"/>
    	        </etc>
            </xsl:if>
			
        </data-request>
		
    </xsl:template>


    <xsl:template match="xi:data" mode="parameter">
        <data>
			<xsl:apply-templates select="key('id',@ref)" mode="parameter"/>
            <xsl:apply-templates select="@name
										|*[not(key('id',@ref)[self::xi:field[@type='string']])]
										  [text() and not(text()='')]
										  [not(preceding-sibling::*/@name=@name)]"
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


    <xsl:template match="xi:form[@new-only or xi:parameter[not(@optional) and not(xi:init)]]" mode="build-subrequest"/>

    <xsl:template match="xi:form[@expect-choise]/xi:form[not(@no-preload)]
						|xi:form[@pipeline][not(@pipeline=/*/@pipeline-name)]"
				  mode="build-subrequest" >
        <preload id="{php:function('uuidSecure','')}" ref="{@id}">
            <xsl:copy-of select="@name|@pipeline"/>
        </preload>
    </xsl:template>
	
	<xsl:template match="xi:form[
			/*/xi:userinput/*[@name='filter']
			and not( /*/xi:userinput/*[@name='filter']/text() =
				(
					ancestor-or-self::xi:form/@name
					| descendant::xi:form/@name
				)
		)]" mode="build-subrequest" priority="1000"
	/>

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

    <xsl:template match="xi:join[not(@field)]" mode="build-subrequest">
		
		<xsl:variable name="concept" select="$model/xi:concept[@name=current()/../@concept]"/>
		<xsl:variable name="join-concept" select="ancestor::xi:view-schema//xi:form[@name=current()/@name]/@concept"/>
		
		<xsl:apply-templates select="$concept/xi:role[@actor=$join-concept and (@name=current()/@role or not (current()/@role))]
						|$model/xi:concept[@name=$join-concept]/xi:role[@actor=$concept/@name  and (@name=current()/@role or not (current()/@role))]
						" mode="join-on">
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
            <on concept="{../@concept}" property="{@name}" name="{../@name}" />
            <xsl:apply-templates select="$join-itself/*"/>
            <on concept="{$join-itself/parent::xi:form/@concept}"
				property="{$join-itself/*/@name|self::*[not($join-itself/*[@name])]/@name}"
				name="{$join-itself/parent::xi:form/@name}"/>
        </join>
    </xsl:template> 

    <xsl:template match="xi:role" mode="join-on">
        <xsl:param name="join-itself"/>
        <xsl:param name="form" select="$join-itself/.."/>
        <xsl:param name="joined" select="$form/.."/>
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
                    <xsl:if test="$form">
                        <xsl:value-of select="($joined|$form)[@concept=current()/../@name][last()]/@name"/> 
                    </xsl:if>
                </xsl:attribute>
            </on>
            <!--on concept="{../@name}" property="{@name}"/-->
        </join>
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