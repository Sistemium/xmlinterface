<?xml version="1.0" ?>
<xsl:transform version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns="http://unact.net/xml/xi"
 xmlns:xi="http://unact.net/xml/xi"
 xmlns:dyn="http://exslt.org/dynamic"
 exclude-result-prefixes="dyn"
 extension-element-prefixes="dyn"
>
    
    <xsl:param name="auth" select="document('../auth.xml')/*"/>
    
    <xsl:template match="/*">
        <xsl:attribute name="pipeline">
            <xsl:value-of select="/*/xi:userinput/xi:command[@name='stage1']"/>
        </xsl:attribute>
       <!--xsl:apply-templates select="document('init.xml')/*/xi:context-extension[xi:session]/*"/-->
    </xsl:template>
    
    
    <xsl:template match="xi:userinput">
        <xsl:choose>
            <xsl:when test="contains(@user-agent,'Windows CE') or contains(@user-agent,'Android') or @user-agent='Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)'">
                <xsl:attribute name="mobile-agent">true</xsl:attribute>
                <xsl:choose>
                    <xsl:when test="contains(@user-agent,'Windows CE') or @user-agent='Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)'">
                        <xsl:attribute name="spb-agent">true</xsl:attribute>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="android-agent">true</xsl:attribute>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="contains(@user-agent,'WebKit')">
                <xsl:attribute name="safari-agent">true</xsl:attribute>
            </xsl:when>
            <xsl:when test="contains(@user-agent,'Firefox')">
                <xsl:attribute name="firefox-agent">true</xsl:attribute>
            </xsl:when>
            <xsl:when test="contains(@user-agent,'MSIE')">
                <xsl:attribute name="msie-agent">true</xsl:attribute>
            </xsl:when>
        </xsl:choose>
        <xsl:if test="contains(@user-agent,'iPad') or contains(@user-agent,'iPhone')">
            <xsl:attribute name="ipad-agent">true</xsl:attribute>
        </xsl:if>
    </xsl:template>

    <xsl:template match="xi:session[@authenticated][not(xi:role)]">
        
        <xsl:variable name="userRoles" select="$auth/xi:user[@name=current()/@username]/xi:role"/>
        <xsl:variable name="validator" select="$auth/xi:validator[@name=current()/@validator]"/>
        <xsl:variable name="validatorRoles" select="$validator/xi:role|$validator/xi:group[@name=current()/xi:group/@name]/xi:role"/>
        
        <xsl:for-each select="$auth/xi:roles//xi:role[($userRoles|$validatorRoles)/@ref=@name or ($userRoles|$validatorRoles)/@ref='*']/ancestor-or-self::xi:role">
            <xsl:if test="not(preceding::xi:role[@name=current()/@name])">
                <xsl:copy>
                    <xsl:apply-templates select="@*"/>
                </xsl:copy>
            </xsl:if>
        </xsl:for-each>
        
    </xsl:template>

    <xsl:template match="/*[xi:userinput/*[@name='livechat' and text()='on']]/xi:session[@authenticated]">
        <xsl:attribute name="livechat">true</xsl:attribute>
    </xsl:template>
    
    <xsl:template match="xi:menu/xi:option">
        <xsl:if test="$userinput[@name = current()/ancestor::xi:view/xi:workflow/xi:step/xi:choise/xi:option
                                        [xi:command/@name=current()/@name]/@id
                                    or ((
                                            @name=current()/ancestor::*/@name
                                            or @name=local-name(current()/../..)
                                        ) and text()=current()/@name
                                    )
                                ]"
        >
            <xsl:attribute name="chosen">true</xsl:attribute>
        </xsl:if>
    </xsl:template>

    <xsl:template match="xi:extender[not(ancestor::xi:set-of[@is-choise])]">
        
        <xsl:apply-templates
            
            select="$userinput[@name=current()/@id]
                   |key('id',ancestor::xi:view/xi:dialogue/@current-step)/xi:choise/xi:option
                    [@id=$userinput/@name]/xi:command[@name=current()/@name][text()='extend']
            "
        />
        
    </xsl:template>

    <xsl:template match="xi:view[not(@hidden)]//xi:dialogue">
        <xsl:variable name="ui"
             select="$userinput[@name=current()/../@name]
                    |key('id',ancestor::xi:view/xi:dialogue/@current-step)
                    //xi:option[@id=$userinput/@name]/xi:command
                    "/>
        <events>
            <xsl:for-each select="$ui[current()/../xi:menu/xi:option/@name=text()]">
                <xsl:element name="{text()}"/>
            </xsl:for-each>
            <xsl:for-each select="$ui[not(text())]">
                <event name="{@name}"/>
            </xsl:for-each>
            <xsl:for-each select="$ui[current()/../xi:workflow/xi:step/@name=text()]">
                <xsl:element name="jump">
                    <xsl:attribute name="to"><xsl:value-of select="current()/text()"/></xsl:attribute>
                </xsl:element>
            </xsl:for-each>
        </events>
    </xsl:template>


    <xsl:template match="
        
        xi:view//xi:data
            [not(ancestor::xi:set-of[@is-choise]) or @removable]
        |
        xi:view//xi:set-of
            [not(ancestor::xi:set-of[@is-choise]) or @removable]
        |
        xi:view//xi:preload[@preload]
            [not(ancestor::xi:set-of[@is-choise]) or @removable]
        
    ">
        
        <xsl:variable name="ui"
             select="
                    ($userinput
                     |key('id',ancestor::xi:view/xi:dialogue/@current-step)
                      //xi:option[@id=$userinput/@name]/xi:command
                    )[@name=current()[not(self::xi:set-of and preceding-sibling::xi:set-of/@name=@name)]/@name or @name=current()/@id
                      or (@ref=current()/@ref and $userinput[text()=current()/@id]/@name=../@id)
                     ]
        "/>
        
        <xsl:if test="ancestor::xi:set-of[@is-choise]/parent::*/@chosen=@id and $ui[text()='remove']">
            <xsl:attribute name="remove-this">true</xsl:attribute>
        </xsl:if>
        
        <xsl:if test="not(ancestor::xi:set-of[@is-choise]) and $ui">
            <xsl:if test="(@toggle-edit-off|@toggle-edit-on and $ui[text()='toggle-edit'])
                         or (@toggle-edit-off and $ui[text()='toggle-edit-on'])
                         or (@toggle-edit-on and $ui[text()='toggle-edit-off'])
                         "
            >
                <xsl:attribute name="toggle-edit">true</xsl:attribute>
            </xsl:if>
            <xsl:if test="@chosen and $ui[text()='unchoose' or text()='next']">
               <xsl:attribute name="unchoose-this">true</xsl:attribute>
            </xsl:if>
            <xsl:if test="$ui[text()='hide']">
               <xsl:attribute name="hidden">true</xsl:attribute>
            </xsl:if>
            <xsl:if test="$ui[text()='show']">
               <xsl:attribute name="show-this">true</xsl:attribute>
            </xsl:if>
            <xsl:if test="$ui[text()='refresh']">
               <xsl:attribute name="refresh-this">true</xsl:attribute>
            </xsl:if>
            <xsl:if test="$ui[text()='save']">
               <xsl:attribute name="persist-this">true</xsl:attribute>
            </xsl:if>
            <xsl:if test="key('id',@ref)/@expect-choise='optional' and $ui[text()='ignore']">
               <xsl:attribute name="ignore-this">true</xsl:attribute>
            </xsl:if>
            <xsl:if test="@deletable and $ui[text()='delete']">
               <xsl:attribute name="delete-this">true</xsl:attribute>
            </xsl:if>
            <xsl:if test="not(@choise) and @removable and $ui[text()='remove']">
               <xsl:attribute name="remove-this">true</xsl:attribute>
            </xsl:if>
            <xsl:if test="@delete-this and $userinput[text()='undelete']">
               <xsl:attribute name="undelete-this">true</xsl:attribute>
            </xsl:if>
        </xsl:if>
        
        <xsl:if test="@choise">
            
            <xsl:for-each select="$ui[(text()=current()/xi:set-of[@is-choise]/xi:data/@id
                                       or text()=current()/ancestor::xi:view-data//xi:data[@name=current()/@choise]/@id
                                       )and not( text()=current()/@chosen )
                                     ]">
                <chosen ref="{text()}"/>
            </xsl:for-each>
            
            <xsl:for-each select="key('id',self::*[$ui[text()='next']]/@chosen)">
                <xsl:for-each select="following-sibling::xi:data[@ref=current()/@ref][1]">
                    <chosen ref="{@id}"/>
                </xsl:for-each>
            </xsl:for-each>
            
            <xsl:if test="self::*[$ui[text()='next'] and not(@chosen)]">
                <xsl:for-each select="key('id',@choise)/xi:data[@ref=current()/@ref][1]">
                    <chosen ref="{@id}"/>
                </xsl:for-each>
            </xsl:if>
            
            <xsl:if test="$ui[@xpath-compute]">
                <xsl:variable name="dyn" select="dyn:map(key('id',$userinput[@name=$ui/../@id]/text()),$ui/@xpath-compute)"/>
                <!--xsl:comment>c=<xsl:value-of select="$dyn"/></xsl:comment-->
                <xsl:for-each select="set-of[@is-choise]/xi:data[xi:datum[@name='id']=$dyn]">
                    <chosen ref="{@id}"/>
                </xsl:for-each>
            </xsl:if>
            
        </xsl:if>
        
        <xsl:if test="self::xi:set-of[@page-size and $ui[text()='next' or text()='prev']]">
            <xsl:attribute name="refresh-this">
                <xsl:value-of select="$ui/text()"/>
            </xsl:attribute>
        </xsl:if>
        
    </xsl:template>

    <xsl:template match="xi:view[not(@hidden)]//xi:datum[@editable or (@modifiable and not(@xpath-compute))]">
        
        <xsl:variable name="ui" select="($userinput|key('id',ancestor::xi:view/xi:dialogue/@current-step)
                                    //xi:option[@id=$userinput/@name]/xi:command)
                                    [@name=current()/@name or @name=current()/@id
                                     or (@ref=current()/@ref and ($userinput[text()=current()/ancestor::*/@id]/@name=../@id or not($userinput[text()]/@name=../@id)))
                                    ]"/>
        
        <xsl:variable name="newValue"
                      select="$ui[not(@xpath-compute)]
                             |dyn:map(key('id',$userinput[@name=$ui/../@id]/text())|self::*[$userinput[@name=$ui/../@id and not(text())]],$ui/@xpath-compute)"/>
        
        <!--xsl:if test="@name='details-xid'">
            <xsl:attribute name="test"><xsl:value-of select="key('id',$userinput[@name=$ui/../@id]/text())/@id"/></xsl:attribute>
        </xsl:if-->
        
        <xsl:variable name="spin"
                      select="key('id',current()/@ref)/xi:spin/*[@id=$userinput[text()=current()/@id]/@name]"/>
        
        <xsl:variable name="numval">
            <xsl:choose>
                <xsl:when test="not(number())">0</xsl:when>
                <xsl:otherwise><xsl:value-of select="number()"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="$spin or ($newValue and ((text() and $newValue/text() and $newValue!=.) 
                                        or (not(text()) and $newValue/text())
                                        or (text() and not($newValue/text())) ))">
                <xsl:variable name="value">
                    <xsl:choose>
                        <xsl:when test="$spin/self::xi:less">
                            <xsl:value-of select="$numval - (ancestor::xi:data/xi:datum)[@ref=$spin/parent::xi:spin/@ref]"/>
                        </xsl:when>
                        <xsl:when test="$spin/self::xi:more">
                            <xsl:value-of select="$numval + (ancestor::xi:data/xi:datum)[@ref=$spin/parent::xi:spin/@ref]"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$newValue"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:attribute name="modified">
                    <xsl:if test="text() and $value!=''">
                        <xsl:text>true</xsl:text>
                    </xsl:if>
                    <xsl:if test="not(text())">
                        <xsl:text>fill</xsl:text>
                    </xsl:if>
                    <xsl:if test="$value=''">
                        <xsl:text>erase</xsl:text>
                    </xsl:if>
                </xsl:attribute>
                <xsl:value-of select="$value"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="text()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:transform>
