<?xml version="1.0" ?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns="http://unact.net/xml/xi"
>


    <xsl:template match="xi:session-control[/*/xi:session[@authenticated]]">
       <form id="session-wrapper" name="session-form" method="post" action="?">
           <xsl:attribute name="class">authenticated</xsl:attribute>
           
            <xsl:for-each select="/*[not(xi:userinput/@spb-agent)]/xi:views[xi:view][count(xi:menu[@label]/xi:option)&gt;1]">
                <div class="select">
                    <select name="views" onchange="viewChange(this)">
                        <option selected="selected">Выберите программу ...</option>
                        <xsl:for-each select="xi:menu[@label]">
                            <optgroup label="{@label}">
                                <xsl:for-each select="xi:option[@name]">
                                    <option>
                                        <xsl:attribute name="value">
                                            <xsl:value-of select="@name"/>
                                            <xsl:if test="@pipeline">
                                                <xsl:value-of select="concat('&amp;pipeline=',@pipeline)"/>
                                            </xsl:if>
                                        </xsl:attribute>
                                        <xsl:if test="ancestor::xi:views/xi:view[@name=current()/@name]">
                                            <xsl:attribute name="class">open</xsl:attribute>
                                        </xsl:if>
                                        <xsl:value-of select="@label"/>
                                    </option>
                                </xsl:for-each>
                            </optgroup>
                        </xsl:for-each>
                    </select>
                </div>
            </xsl:for-each>
            
            <div class="field">
                <label for="session-username"><span>Имя</span><span class="colon">:</span></label>
                <span id="session-username"><xsl:value-of select="/*/xi:session/@username"/></span>
            </div>
            <div id="clientDataControl"/>
            <xsl:if test="/*/descendant::xi:workflow[@geolocate] and /*/xi:userinput/@safari-agent">
                <div class="geolocate">
                    <a href="?" onclick="return showMap();">
                        <span id="longitude"/>
                        <span id="latitude"/>
                        <span id="geoacc"/>
                        <span id="geots"/>
                    </a>
                </div>
            </xsl:if>
            <div class="link">
                <a class="button">
                    <xsl:attribute name="href">
                        <xsl:text>?</xsl:text>
                        <xsl:apply-templates select="$userinput" mode="links"/>
                        <xsl:text>command=logoff</xsl:text>
                    </xsl:attribute>
                    <xsl:attribute name="onclick">
                        <xsl:text>return menupad(this,'session-form');</xsl:text>
                    </xsl:attribute>
                    <span>Завершить сеанс</span>
                </a>
            </div>
            <xsl:if test="$livechat">
                <div class="link">
                    <a class="button" href="?livechat=on">
                        <xsl:attribute name="onclick">
                            <xsl:choose>
                                <xsl:when test="/*/xi:session/@livechat">
                                        <xsl:text>return initChat();</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                        <xsl:text>return menupad(this,'session-form');</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <span>Техподдержка</span>
                    </a>
                </div>
            </xsl:if>
        </form>
    </xsl:template>

    
    <xsl:template match="xi:session-control">
        <div id="session-wrapper">
           <xsl:attribute name="class">not-authenticated</xsl:attribute>
           <div class="title">
              <span>Пожалуйста, представьтесь</span>
           </div>
           <form name="session" method="post">
                <xsl:attribute name="action">
                    <xsl:text>?</xsl:text>
                    <xsl:apply-templates select="$userinput" mode="links"/>
                    <xsl:text>command=authenticate</xsl:text>
                </xsl:attribute>
                <xsl:apply-templates select="/*/xi:session/*"/>
                <div class="field">
                    <label for="username">Имя:</label>
                    <xsl:call-template name="input">
                        <xsl:with-param name="id">username</xsl:with-param>
                    </xsl:call-template>
                </div>
                <div class="field">
                    <label for="password">Пароль:</label>
                    <xsl:call-template name="input">
                        <xsl:with-param name="id">password</xsl:with-param>
                    </xsl:call-template>
                </div>
                <div class="option">
                    <input type="submit" value="Вход" class="button">
                        <xsl:if test="/*/xi:userinput/@spb-agent">
                            <xsl:attribute name="onfocus">return onFocus(this)</xsl:attribute>
                        </xsl:if>
                    </input>
                </div>
            </form>
        </div>
    </xsl:template>
    
 
</xsl:transform>
