<?xml version="1.0" ?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://unact.net/xml/xi"
    xmlns:xi="http://unact.net/xml/xi"
    exclude-result-prefixes="xi">

    <xsl:key name="id" match="*" use="@id"/>
    <xsl:variable name="lcletters">abcdefghijklmnopqrstuvwxyz</xsl:variable>
    <xsl:variable name="ucletters">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
   
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
                <xsl:value-of select="translate(@name,$ucletters,$lcletters)"/>
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
        <xsl:for-each select="xi:userinput">
            <uploads>
                <xsl:apply-templates select="xi:import/xi:data[@ref]" mode="build-upload"/>
            </uploads>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="*" mode="build-upload">
        <xsl:param name="form-id" select="@ref"/>
        <xsl:param name="datum-refs" select="xi:datum/@ref"/>
        <xsl:param name="xid" select="*[@name='xid']"/>
        
        <upload xid="{$xid}" debug-="true">
            <xsl:copy-of select="@*"/>
            
            <xsl:for-each select="key('id',$form-id)">
                
                <xsl:variable name="form" select="."/>
                
                <preload ref="{@id}" name="{@name}" retrieve="true">
                    <datum type="parameter" name="xid">
                        <xsl:value-of select="$xid"/>
                    </datum>
                </preload>
                
                <data ref="{@id}" name="{@name}">
                    
                    <xsl:for-each select="xi:join|xi:parent-join[not(@name = parent::*/parent::*[not(@hidden)]/@name)]">
                        <xsl:variable name="parent" select="ancestor::xi:form[@name=current()/@name]/xi:field[@name='id']"/>
                        <datum type="field" name="{@role}" editable="new-only">
                            <!--xsl:apply-templates select="." mode="build-ref"/-->
                            <xsl:copy-of select="@sql-name"/>
                            <xsl:value-of select="ancestor::xi:view/xi:view-data//xi:datum[@ref=$parent/@id]/text()"/>
                        </datum>
                    </xsl:for-each>
                    
                    <xsl:for-each select="$datum-refs">
                        <xsl:variable name="userDatum" select=".."/>
                        <xsl:for-each select="key('id',.)[@modifiable or @editable or @name='xid' or self::xi:join or self::xi:form]">
                            <datum ref="{@id}" type="field">
                                <xsl:copy-of select="@name|@editable|@modifiable"/>
                                <xsl:if test="self::xi:form">
                                    <xsl:attribute name="name">
                                        <xsl:value-of select="@concept"/>
                                    </xsl:attribute>
                                    <xsl:attribute name="editable">new-only</xsl:attribute>
                                    <xsl:attribute name="sql-name">
                                        <xsl:value-of select="$form/@parent-sql-name"/>
                                    </xsl:attribute>
                                </xsl:if>
                                <xsl:value-of select="$userDatum"/>
                            </datum>
                        </xsl:for-each>
                    </xsl:for-each>
                    
                </data>
                
                <view-schema>
                    <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:copy-of select="xi:field"/>
                    </xsl:copy>
                </view-schema>
                
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
        
        <xsl:variable name="old" select="../preceding-sibling::xi:preload/descendant::xi:data[@name=current()/../@name]/xi:datum[@name=current()/@name]"/>
        <xsl:if test="$old/text() != text() or (text() and not ($old/text()))">
            <xsl:if test="not(@editable='new-only' or ../preceding-sibling::xi:preload[descendant::xi:not-found])">
                <xsl:attribute name="modified">true</xsl:attribute>
            </xsl:if>
        </xsl:if>
        
    </xsl:template>

    
    <xsl:template match="/*[@stage='build-persist']//xi:data[xi:datum[@modified] or @is-new]">
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
    
    <xsl:template match="/*[@stage='build-persist']//xi:view-schema[parent::xi:upload]">
        
        <xsl:for-each select="xi:form">
            <preload ref="{@id}" name="{@name}" retrieve="true">
                <datum type="parameter" name="xid">
                    <xsl:value-of select="ancestor::xi:upload[1]/@xid"/>
                </datum>
            </preload>
        </xsl:for-each>
        
        <xsl:copy-of select="."/>
        
    </xsl:template>

    <xsl:template match="/*[@stage='out'][xi:upload or self::xi:upload]">
        
        <response>
            <xsl:for-each select="xi:upload|self::xi:upload">
                
                <xsl:variable name="response" select="xi:preload/xi:response/xi:result-set"/>
                
                <xsl:choose>
                    
                    <xsl:when test="$response">
                        <xsl:for-each select="xi:view-schema/*">
                            <xsl:variable name="data"
                                          select="$response/xi:data[@name=current()/@name]"/>
                            <xsl:element name="{@name}">
                                <xsl:copy-of select="/*/@xid|$response/../@ts"/>
                                <xsl:for-each select="xi:field" mode="prepare">
                                    <xsl:element name="{@alias|self::*[not(@alias)]/@name}">
                                        <xsl:value-of select="$data/*[@name=current()/@name]"/>
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

</xsl:transform>