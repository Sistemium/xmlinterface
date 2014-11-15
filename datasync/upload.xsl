<?xml version="1.0" ?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://unact.net/xml/xi"
    xmlns:xi="http://unact.net/xml/xi"
    exclude-result-prefixes="xi">

    <xsl:key name="id" match="*" use="@id"/>
   
    <xsl:template match="/*">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    

    <xsl:template match="xi:context//node()">
        <xsl:apply-templates select="*"/>
    </xsl:template>

<!--            PREPARE             -->
    
    <xsl:template match="/*[xi:userinput/xi:command[@name='prepare']]">
        
        <xsl:variable name="prepare" select="xi:userinput/xi:command[@name='prepare']/text()"/>
        
        <xsl:for-each select="/*/xi:views/xi:view[1]/xi:view-schema//xi:form[@name=$prepare]">
            
            <form ref="{@id}">
                <xsl:attribute name="xid">
                    <xsl:value-of select="/*/xi:userinput/xi:command[@name='xid']"/>
                </xsl:attribute>
                <xsl:apply-templates select="..|xi:field" mode="prepare"/>
            </form>
            
        </xsl:for-each>
        
    </xsl:template>

    <xsl:template match="node()" mode="prepare"/>

    <xsl:template match="xi:field" mode="prepare">
        <xsl:param name="data" select="xi:init"/>
        <field id="{@id}" alias="{@name}">
            <xsl:copy-of select="@alias"/>
            <xsl:value-of select="$data/*[@name=current()/@name]"/>
        </field>
    </xsl:template>

    <xsl:template match="xi:form[not(@hidden)]" mode="prepare">
        <field id="{@id}">
            <xsl:attribute name="alias">
                <xsl:value-of select="
                    concat(
                        translate(substring(@name,1,1),$ucletters,$lcletters)
                        , substring(@name,2)
                    )
                "/>
            </xsl:attribute>
        </field>
    </xsl:template>


<!--            UPLOAD             -->

    <xsl:template match="/*[xi:userinput/xi:command[@name='upload']]">
        <xsl:apply-templates select="xi:userinput" mode="build-upload">
            <xsl:with-param name="form-id" select="xi:userinput/xi:command[@name='upload']/text()"/>
            <xsl:with-param name="datum-refs" select="xi:userinput/xi:command/@name"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="/*[xi:userinput/xi:import]">
        <uploads>
            <xsl:apply-templates select="xi:userinput/xi:import|xi:views|xi:session" mode="build-upload"/>
        </uploads>
    </xsl:template>
    
    <xsl:template match="*" mode="build-upload">
        <xsl:apply-templates select="*" mode="build-upload"/>
    </xsl:template>
    
    <xsl:template match="xi:views|xi:view|*[ancestor-or-self::xi:session|ancestor-or-self::xi:view-schema]" mode="build-upload">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="*" mode="build-upload"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="xi:userinput|xi:import/xi:data[@ref]" mode="build-upload">
        <xsl:param name="form-id" select="@ref"/>
        <xsl:param name="datum-refs" select="xi:datum/@ref"/>
        <xsl:param name="xid" select="*[@name='xid']"/>
        <xsl:param name="deleting" select="@delete-this"/>
        
        <upload xid="{$xid}" debug-="true">
            <xsl:copy-of select="@*"/>
            
            <xsl:for-each select="key('id',$form-id)">
                
                <xsl:variable name="form" select="."/>
                
                <xsl:if test="not($deleting)">
                    
                    <preload ref="{@id}" name="{@name}" retrieve="true" program="{ancestor::xi:view/@name}">
                        <datum type="parameter" name="xid">
                            <xsl:value-of select="$xid"/>
                        </datum>
                    </preload>
                    
                </xsl:if>
                
                <data ref="{@id}" name="{@name}" program="{ancestor::xi:view/@name}">
                    
                    <xsl:copy-of select="$deleting"/>
                    
                    <xsl:for-each select="xi:join|xi:parent-join[not(@name = parent::*/parent::*[not(@hidden)]/@name)]">
                        
                        <xsl:variable name="parentDatum">
                            <xsl:value-of select="@field"/>
                            <xsl:if test="not(@field)">id</xsl:if>
                        </xsl:variable>
                        
                        <xsl:variable name="parent" select="
                            ancestor::xi:form[@name=current()/@name]
                                /*[self::xi:field|self::xi:parameter][@name=$parentDatum]
                        "/>
                        
                        <datum type="field" name="{@role|@property}" editable="new-only">
                            <!--xsl:apply-templates select="." mode="build-ref"/-->
                            <xsl:copy-of select="@sql-name"/>
                            <xsl:value-of select="
                                ancestor::xi:view/xi:view-data//xi:datum[@ref=$parent/@id]/text()
                            "/>
                        </datum>
                        
                    </xsl:for-each>
                    
                    <xsl:for-each select="$datum-refs">
                        <xsl:variable name="userDatum" select=".."/>
                        <xsl:for-each select="key('id',.)[@modifiable or @editable or @name='xid' or self::xi:parent-join or self::xi:join or self::xi:form]">
                            <datum ref="{@id}" type="field">
                                <xsl:copy-of select="@name|@editable|@modifiable"/>
                                <xsl:if test="self::xi:parent-join">
                                    <xsl:attribute name="name">
                                        <xsl:value-of select="@role"/>
                                    </xsl:attribute>
                                    <xsl:attribute name="editable">true</xsl:attribute>
                                    <xsl:copy-of select="@sql-name"/>
                                </xsl:if>
                                <xsl:if test="self::xi:form">
                                    <xsl:attribute name="name">
                                        <xsl:value-of select="@concept"/>
                                    </xsl:attribute>
                                    <xsl:attribute name="editable">true</xsl:attribute>
                                    <xsl:attribute name="sql-name">
                                        <xsl:value-of select="$form/@parent-sql-name"/>
                                    </xsl:attribute>
                                </xsl:if>
                                <xsl:value-of select="$userDatum"/>
                            </datum>
                        </xsl:for-each>
                    </xsl:for-each>
                    
                </data>
                
                <xsl:if test="not($deleting)">
                    <response-preload ref="{@id}" name="{@name}" program="{ancestor::xi:view/@name}">
                        <datum type="parameter" name="xid">
                            <xsl:value-of select="$xid"/>
                        </datum>
                    </response-preload>
                </xsl:if>
                
            </xsl:for-each>
        </upload>
    </xsl:template>


<!--            SET MODIFIED            -->


    <xsl:template match="xi:preload[/*[@stage='set-modified']]"/>

    <xsl:template match="xi:data[/*[@stage='set-modified']]" mode="extend">
        
        <xsl:if test="preceding-sibling::xi:preload[descendant::xi:not-found]">
            <xsl:attribute name="is-new">true</xsl:attribute>
        </xsl:if>
        
    </xsl:template>
    
    <xsl:template match="xi:datum[@editable or @modifiable][/*[@stage='set-modified']]" mode="extend">
        
        <xsl:variable name="old" select="
            ../preceding-sibling::xi:preload
            /descendant::xi:data[@name=current()/../@name]
            /xi:datum[@name=current()/@name]
        "/>
        
        <xsl:if test="$old/text() != text() or (text() and not ($old/text()))">
            <xsl:if test="not(@editable='new-only' or ../preceding-sibling::xi:preload[descendant::xi:not-found])">
                <xsl:attribute name="modified">true</xsl:attribute>
            </xsl:if>
        </xsl:if>
        
    </xsl:template>

    
    <xsl:template match="/*[@stage='build-persist']//xi:data[xi:datum[@modified] or @is-new or @delete-this]">
        <data>
            <xsl:copy-of select="@*"/>
            <xsl:call-template name="data-build-update"/>
        </data>
    </xsl:template>

    <xsl:template match="/*[@stage='build-xmlq' or @stage='build-response']//xi:preload">
        <xsl:copy>
            <xsl:copy-of select="@*[not(local-name()='retrieve')]"/>
            <xsl:apply-templates select="." mode="build-request"/>
        </xsl:copy>
    </xsl:template>
    

<!--            RESPONSE             -->
    
    <xsl:template match="/*[@stage='build-persist']//xi:response-preload">
        <preload>
            <xsl:attribute name="retrieve">true</xsl:attribute>
            <xsl:attribute name="recursive">true</xsl:attribute>
            <xsl:copy-of select="@*|*"/>
        </preload>
    </xsl:template>

    <xsl:template match="/*[@stage='out'][xi:upload or self::xi:upload]">
        
        <response>
            <xsl:for-each select="xi:upload|self::xi:upload">
                
                <xsl:variable name="response" select="
                    xi:preload/xi:response/xi:result-set
                    | self::*[@delete-this]/xi:data/xi:response/xi:rows-affected
                "/>
                
                <xsl:choose>
                    
                    <xsl:when test="$response">
                        <xsl:for-each select="key('id',xi:preload/@ref|self::*[@delete-this]/@ref)">
                            
                            <xsl:variable name="data"
                                select="$response/xi:data[@name=current()/@name]"
                            />
                            
                            <xsl:element name="{@name}">
                                
                                <xsl:copy-of select="ancestor::xi:upload/@xid|$response/../@ts"/>
                                
                                <xsl:for-each select="xi:field[$data]">
                                    <xsl:element name="{@alias|self::*[not(@alias)]/@name}">
                                        <xsl:value-of select="$data/*[@name=current()/@name]"/>
                                    </xsl:element>
                                </xsl:for-each>
                                
                                <xsl:for-each select="xi:form[$data]">
                                    <xsl:apply-templates mode="build-upload-response"
                                        select="$data/xi:data[@name=current()/@name]"
                                    >
                                        <xsl:with-param name="form" select="."/>
                                    </xsl:apply-templates>
                                </xsl:for-each>
                                
                                <xsl:for-each select="$response/ancestor::xi:upload[@delete-this]">
                                    <xsl:copy-of select="@delete-this"/>
                                    <xsl:element name="xid">
                                        <xsl:value-of select="@xid"/>
                                    </xsl:element>
                                </xsl:for-each>
                                
                            </xsl:element>
                            
                        </xsl:for-each>
                    </xsl:when>
                    
                    <xsl:otherwise>
                        <xsl:copy-of select="(xi:data/xi:response/xi:exception | xi:preload//xi:exception)[1]"/>
                    </xsl:otherwise>
                    
                </xsl:choose>
                
            </xsl:for-each>
        </response>
        
    </xsl:template>
    
    
    <xsl:template mode="build-upload-response" match="xi:data" name="build-upload-response">
        
        <xsl:param name="form" select="/.."/>
        <xsl:param name="data" select="."/>
        
        <xsl:for-each select="$form">
            <xsl:element name="{@name}">
                
                <xsl:for-each select="xi:field[$data]">
                    <xsl:attribute name="{@alias|self::*[not(@alias)]/@name}">
                        <xsl:value-of select="$data/*[@name=current()/@name]"/>
                    </xsl:attribute>
                </xsl:for-each>
                
                <xsl:for-each select="$data/parent::*/*[@name='id']">
                    <xsl:attribute name="{$form/xi:parent-join/@role}">
                        <xsl:value-of select="."/>
                    </xsl:attribute>
                </xsl:for-each>
                
            </xsl:element>
        </xsl:for-each>
        
    </xsl:template>
    

</xsl:transform>