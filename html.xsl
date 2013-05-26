<?xml version="1.0" ?>
<?xml-stylesheet type="text/xsl" href="html-xsl.xsl"?>

<xsl:transform version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:xi="http://unact.net/xml/xi"
 xmlns:rule="http://unact.net/rules"
 xmlns="http://www.w3.org/1999/xhtml"
 >
 
    <!--
    
    build-name, build-inner
    
    -->

    <xsl:output method="xml"
                doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
                doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
                omit-xml-declaration="yes"
                encoding="utf-8"
                cdata-section-elements="xi:cdata"
    />  
    
    <xsl:param name="userinput" select="/*/xi:userinput/xi:command"/>
    <xsl:param name="developer" select="/*/xi:userinput[contains(@host,'macbook')]"/>
    <xsl:param name="livechat" select="/*/xi:session[/*/xi:session/xi:role[@name='livechat']][@authenticated and not(/*/xi:userinput/@mobile-agent)]"/>
    <xsl:param name="geo" select="descendant::xi:workflow[@geolocate] and /*/xi:userinput/@safari-agent"/>
    
    <xsl:include href="html/html-grid.xsl"/>
    <xsl:include href="html/html-choose.xsl"/>
    <xsl:include href="html/html-inputprint.xsl"/>
    <xsl:include href="html/html-session.xsl"/>
    <xsl:include href="html/html-menu.xsl"/>
    <xsl:include href="html/html-region.xsl"/>
    
    <xsl:key name="id" match="*" use="@id"/>
    
    <xsl:template match="xi:command" mode="links"/>
    
    <xsl:template match="xi:command[@name='as-svg' or @name='interface']" mode="links">
        <xsl:value-of select="@name"/>
        <xsl:if test="text()">
            <xsl:text>=</xsl:text>
            <xsl:value-of select="."/>
        </xsl:if>
        <xsl:text>&amp;</xsl:text>
    </xsl:template>
    
    <xsl:decimal-format zero-digit="0" grouping-separator=","/>

    
    <xsl:template match="xi:interface|xi:context">
    <html xmlns="http://www.w3.org/1999/xhtml" lang="rus">
        <!--ontouchmove="event.preventDefault();"-->
        <head>
            <meta http-equiv="Content-Type" content="text/html;charset=utf-8"/>
            <meta http-equiv="X-UA-Compatible" content="IE=100" />
            <title><xsl:value-of select="/*/@label"/></title>
            <link rel="shortcut icon" href="images/favicon.ico" type="image/x-icon"/>
            <link rel="apple-touch-icon" href="images/apple-touch-icon.png"/>
            
            <xsl:for-each select="xi:userinput/@*|.|*">
                <xsl:variable name="css-file">
                    <xsl:choose>
                        <xsl:when test="self::xi:userinput[not(@ipad-agent- or @safari-agent-)]">css/desktop</xsl:when>
                        <xsl:when test="xi:userinput[not(@spb-agent)]">../libs/jquery-for-xi/css/jquery</xsl:when>
                        <xsl:when test="local-name()='msie-agent-'">css/ie</xsl:when>
                        <xsl:when test="local-name()='safari-agent-'">css/touch</xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <xsl:if test="string-length($css-file)&gt;0">
                    <link rel="stylesheet" type="text/css" href="{$css-file}.css"/>
                </xsl:if>
            </xsl:for-each>
            
            <script type="text/javascript" src="js/xi-common.js"></script>
            <xsl:if test="descendant::xi:dialogue//xi:input[key('id',@ref)/@name='barcode']">
                <meta http-equiv="scanner" content="enabled"/>
                <!--meta http-equiv="scanner" content="autoenter"/-->
                <META HTTP-Equiv="scannernavigate" Content="javascript:doScan('%s', '%s', %s, '%s', %s);"/>
            </xsl:if>
            <meta name="viewport" content="user-scalable=no, width=device-width" />
            <meta name="apple-mobile-web-app-capable" content="yes" />
            <meta name="format-detection" content="telephone=no"/>
            <xsl:if test="/*/xi:userinput/@spb-agent">
                <META HTTP-Equiv="Signal" content="show"/>
                <META HTTP-Equiv="SIPbutton" content="show"/>
                <META HTTP-Equiv="quitbutton" Content="show"/>
                <META HTTP-Equiv="reloadbutton" Content="show"/>
                <META HTTP-Equiv="Signal" content="x=1"/>
                <META HTTP-Equiv="Signal" content="y=305"/>
                <META HTTP-Equiv="Signal" content="Left_GrowFromBottom"/>
                <META HTTP-Equiv="SIPControl" Content="Automatic"/>
                <META HTTP-Equiv="SIPbutton" content="x=5"/>
                <META HTTP-Equiv="SIPbutton" content="y=25"/>
                <META HTTP-Equiv="quitbutton" Content="x=5"/>
                <META HTTP-Equiv="quitbutton" Content="y=6"/>
                <META HTTP-Equiv="reloadbutton" Content="x=217"/>
                <META HTTP-Equiv="reloadbutton" Content="y=6"/>
                <META HTTP-Equiv="OnAllKeysDispatch" Content="javascript:onAllKeys(%s)"/>
                <xsl:if test="/*/xi:views/xi:view[not(@hidden)][xi:dialogue/xi:choose or xi:exception/xi:message/xi:for-human]">
                    <META HTTP-Equiv="invokenotification" content="3,350,3,500"/>
                    <META HTTP-Equiv="invokenotification" content="2,350,2,500"/>
                </xsl:if>
                <script type="text/javascript" src="js/xi-mobile.js"></script>
                <xsl:if test="not(/*/xi:session[@authenticated])">
                    <META HTTP-Equiv="WritePersistentRegSetting" Content="hkcu\\Software\Symbol\SymbolPB\Styles=dword:0000"/>
                    <META HTTP-Equiv="WritePersistentRegSetting" Content="hkcu\\Software\Symbol\SymbolPB\No Scrollbars=dword:0000"/>
                </xsl:if>
            </xsl:if>
            <xsl:if test="$livechat and /*/xi:session/@livechat">
                 <script type="text/javascript" src="https://snapabug.appspot.com/snapabug.js"></script>
            </xsl:if>
            <xsl:if test="$geo">
                <script type="text/javascript">
                    <xsl:attribute name="src">
                        <xsl:text>http://api-maps.yandex.ru/1.1/index.xml?loadByRequire=1&amp;key=</xsl:text>
                        <xsl:choose>
                            <xsl:when test="/*/xi:userinput/@host='macbook01.local'">
                                <xsl:text>AAGCGE0BAAAAu2_MHgIAW1ysJTOP5GHbkITEHJJ8eUk2PIMAAAAAAAAAAABuSDZUyqIpw-ShWWmEig4GV2YMag==</xsl:text>
                            </xsl:when>
                            <xsl:when test="/*/xi:userinput/@host='macbook01.unact.ru'">
                                <xsl:text>AKOEGE0BAAAAmPZOZQMA1TKy4ANba8TNMVFVtbZD2FN362sAAAAAAAAAAAAQuzKkQVneGGbVtYVwmZ_zfCkDXg==</xsl:text>
                            </xsl:when>
                            <xsl:when test="/*/xi:userinput/@host='system.unact.ru'">
                                <xsl:text>AM5zGE0BAAAAmpeaQwMAyJxW2ULxZ-9AaY01p8qr3XkNKaAAAAAAAAAAAABX0AetYKJ1nTm2uY1Rh2SH_p8Kmg==</xsl:text>
                            </xsl:when>
                            <xsl:when test="/*/xi:userinput/@host='php.unact.ru'">
                                <xsl:text>AHK7Lk0BAAAAZteCGwMA-2aQ1xdXIoDEjIcaBRWvj1wn8ToAAAAAAAAAAAA7DJ1ojztotCQmbxN8o5qx4mZnGA==</xsl:text>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:attribute>
                </script>
                <script type="text/javascript">var map=false;</script>
            </xsl:if>
            <xsl:if test="not(/*/xi:userinput/@spb-agent)">
                <script type="text/javascript" src="js/xi.js"></script>
                <script type="text/javascript" src="js/AjaxRequest.js"></script>
                <script type="text/javascript" src="../libs/jquery-for-xi/js/jquery.js"></script>
                <script type="text/javascript" src="../libs/jquery-for-xi/js/jquery-ui.js"></script>
                <xsl:if test="/*/xi:views/xi:view[not(@hidden)]/xi:dialogue/descendant::*[@clientData]">
                    <script type="text/javascript" src="js/clientData.js"></script>
                </xsl:if>
                <script type="text/javascript" src="../libs/jquery-for-xi/js/jquery.ui.datepicker-ru.js"></script>
                <script type="text/javascript">$(document).ready(domready);</script>
                
                <link href="../libs/loadmask/jquery.loadmask.css" rel="stylesheet" type="text/css" />
                <script type="text/javascript" src="../libs/loadmask/jquery.loadmask.min.js"></script>
                
            </xsl:if>
            <xsl:for-each select="xi:views/xi:view[not(@hidden) and xi:view-schema/@client-js]">
                <script type="text/javascript" src="views/{@name}.js"></script>
            </xsl:for-each>
        </head>
        <body>
            <xsl:variable name="viewport" select="xi:views/xi:view[not(@hidden)]"/>
            <xsl:variable
                name="editables"
                select="key('id',$viewport/xi:dialogue//xi:input/@ref)[@editable or @choise]
                       |$viewport//xi:datum[@editable][ancestor::xi:data[not(ancestor::xi:set-of[@is-choise])][@ref=$viewport/xi:dialogue//xi:grid/xi:rows/@ref]]
                       "/>
            <xsl:variable name="setfocus-input">
                <xsl:variable name="editables-empty"
                              select="$editables[parent::xi:data[@is-new and not(xi:datum[@editable][text()!=''])]]"/>
                <xsl:variable name="editables-old"
                              select="$editables[self::xi:datum[not(text()) or text()='']]"/>
                <xsl:choose>
                    <xsl:when test="$editables-empty">
                        <xsl:for-each select="$editables-empty">
                            <xsl:if test="position()=1">
                                <xsl:value-of select="@id"/>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:when test="$editables-old">
                        <xsl:for-each select="$editables-old">
                            <xsl:if test="position()=1">
                                <xsl:value-of select="@id"/>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$editables[not(@chosen)][1]/@id"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="setfocus">
                <xsl:choose>
                    <xsl:when test="string-length($setfocus-input)=0
                                    or (key('id',$viewport/xi:dialogue/@current-step)/xi:choise/xi:option[1]
                                       and key('id',$setfocus-input)[@type='parameter' and ancestor::xi:data/descendant::xi:response/xi:rows-affected]
                                       )">
                        <xsl:value-of select="key('id',$viewport/xi:dialogue/@current-step)/xi:choise/xi:option[1]/@id"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$setfocus-input"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:attribute name="onload">
                <xsl:text>initialize('</xsl:text>
                <xsl:if test="not($setfocus='') or not(/*/xi:session[@authenticated])">
                    <xsl:value-of select="$setfocus"/>
                    <xsl:if test="string-length($setfocus)=0"><xsl:text>username</xsl:text></xsl:if>
                </xsl:if>
                <xsl:text>'</xsl:text>
                <xsl:if test="$geo">
                    <text>,true</text>
                </xsl:if>
                <xsl:text>)</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="class">
                
                <xsl:choose>
                    <xsl:when test="/*/xi:userinput/@mobile-agent">
                        <xsl:text>mobile</xsl:text>
                        <xsl:if test="/*/xi:userinput/@spb-agent">
                            <xsl:text> spb</xsl:text>
                        </xsl:if>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>desktop</xsl:text>
                        <xsl:if test="/*/xi:userinput/@ipad-agent">
                            <xsl:text> ipad</xsl:text>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
                
                <xsl:if test="/*/xi:userinput/@android-agent">
                    <xsl:text> android</xsl:text>
                </xsl:if>
                
                <xsl:value-of select="concat(' ',local-name(/*/xi:userinput/@iphone-agent))"/>
                
                <xsl:choose>
                    <xsl:when test="descendant::xi:option[@chosen] or descendant::xi:menu[@chosen] or descendant::xi:view">
                        <xsl:text> sub-page</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text> index-page</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="$developer">
                    <xsl:text> developer</xsl:text>
                </xsl:if>
                <xsl:if test="not(xi:userinput/@msie-agent)">
                    <xsl:text> not-ie</xsl:text>
                </xsl:if>
            </xsl:attribute>
            
            <xsl:call-template name="build-canvas"/>
            
        	<xsl:if test="$livechat and /*/xi:session/@livechat">
                <script type="text/javascript">
                <xsl:text>
                SnapABug.setLocale("ru");
                SnapABug.init('9c4bf44b-fa28-4a0e-a8b8-f4d856723ed6',"0","55%");
                SnapABug.allowScreenshot(true);
                SnapABug.setUserEmail('</xsl:text>
                <xsl:value-of select="concat(/*/xi:session/@username,'@unact.ru')"/>
                <xsl:text>', true);</xsl:text>
                <xsl:if test="$userinput[@name='livechat' and text()='on']">
                    initChat();
                </xsl:if>
                </script>
            </xsl:if>
            
        </body>
    </html>
    </xsl:template>
    
    
    <xsl:template name="build-canvas">
        <div id="canvas">
            <!--xsl:if test="count(xi:views) &gt; 1">
                <xsl:attribute name="class">tabs</xsl:attribute>
                <ul>
                    <xsl:for-each select="xi:views">
                        <li><a href="#{@name}">
                            <xsl:value-of select="xi:menu/@label"/>
                        </a></li>
                    </xsl:for-each>
                </ul>
            </xsl:if-->
            <xsl:if test="$geo">
                 <div id="geomap" class="unset"/>
            </xsl:if>
            <xsl:apply-templates/>
        </div>        
    </xsl:template>

    <xsl:template match="xi:views-">
        <div id="{@name}" class="views">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
 
 
    <xsl:template match="node()|@*" name="rename" mode="rename">
        <xsl:param name="name" select="name()"/>
        <xsl:element name="{$name}">
            <xsl:apply-templates select="@*"/>
            <xsl:value-of select="."/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="node()|@*" mode="attribute">
        <xsl:param name="name" select="name()"/>
        <xsl:attribute name="{$name}">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="/*[xi:userinput/@spb-agent]/xi:views[xi:menu/xi:option[2]]/xi:view/@label" mode="build-text">
        <xsl:variable name="this" select=".."/>
        <div class="{local-name()}">
            <select name="views" onchange="viewChange(this)">
                <xsl:for-each select="ancestor::xi:views/xi:menu/xi:option">
                    <option value="{@name}">
                        <xsl:if test="$this/@name=@name">
                            <xsl:attribute name="selected">selected</xsl:attribute>
                        </xsl:if>
                        <xsl:value-of select="@label"/>
                    </option>
                </xsl:for-each>
            </select>
        </div>
    </xsl:template>
 

    <xsl:template match="@*|*" mode="build-text">
        <xsl:param name="class" select="local-name()"/>
        <div class="{$class}">
            <span>
                <xsl:value-of select="."/>
            </span>
        </div>
    </xsl:template>
 
    <xsl:template match="@name">
        <xsl:attribute name="id">
            <xsl:value-of select="."/>
            <xsl:text>-</xsl:text>
            <xsl:value-of select="local-name(..)"/>            
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="xi:column/@type">
        <xsl:call-template name="id">
            <xsl:with-param name="name">class</xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="xi:ts | xi:expire">
        <div class="{local-name()}">
            <label><xsl:apply-templates select="." mode="usertext"/></label>
            <span><xsl:value-of select="."/></span>
        </div>
    </xsl:template>

    <xsl:template match="xi:ts" mode="usertext">Данные обновлены:</xsl:template>
    <xsl:template match="xi:expire" mode="usertext">Следующее плановое обновление:</xsl:template>


    <xsl:template match="@*" name="id">
        <xsl:param name="name" select="local-name()"/>
        <xsl:attribute name="{$name}">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="*" mode="render">
       <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="xi:freeform" mode="render">
        <form name="{@concept}" method="post">
            <xsl:attribute name="action">
                <xsl:text>?</xsl:text>
                <xsl:apply-templates select="$userinput" mode="links"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </form>
    </xsl:template>

    <xsl:template match="xi:view" mode="render">
        <form id="{concat(@name,'-form')}" method="post" action="{concat('?',@name,'=',xi:dialogue/@action)}">
            <xsl:apply-templates select="*" />
        </form>
    </xsl:template>

    <xsl:template match="xi:step" mode="render">
        <xsl:if test="@label">
            <div class="step title">
                <span>
                    <xsl:value-of select="@label"/>
                </span>
                <xsl:if test="count(../xi:step[xi:validate]) &gt; 1">
                    <span class="progress">
                        <xsl:value-of select="concat('[шаг ',count(preceding-sibling::xi:step[xi:validate])+1,' из ',count(../xi:step[not(@hidden)]),']')"/>
                    </span>
                </xsl:if>
            </div>
        </xsl:if>
        <xsl:apply-templates select="ancestor::xi:view/xi:view-data//xi:exception[key('id',(parent::xi:response/parent::*[self::xi:data|self::xi:preload]|parent::xi:data)/@ref)[(ancestor::*/@id|descendant-or-self::*/@id)=current()//*/@ref]]"/>
        <xsl:variable name="rows-affected" select="sum(ancestor::xi:view/xi:view-data//xi:response/xi:rows-affected)"/>
        <xsl:if test="$rows-affected != 0">
            <div class="success message">
                <span>Данные успешно сохранены. Изменено записей:</span>
                <span><xsl:value-of select="$rows-affected"/></span>
            </div>
        </xsl:if>
        <xsl:apply-templates select="xi:choise"/>
    </xsl:template>

    <xsl:template match="xi:choise">
        <div class="choise">
            <xsl:apply-templates />
        </div>
    </xsl:template>

    <xsl:template match="xi:when[@ref]">
        <xsl:if test="ancestor::xi:view[1]/xi:view-data//xi:datum[@ref=current()/@ref]">
            <xsl:apply-templates/>
        </xsl:if>
    </xsl:template>
        
    <xsl:template match="xi:dialogue">
        <xsl:apply-templates select="key('id',@current-step)" mode="render"/>
        <div class="dialogue">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="*[@label]" mode="label">
        <xsl:value-of select="@label"/>
    </xsl:template>
    
    <xsl:template match="*[not(@label) and @ref]" mode="label">
        <xsl:apply-templates select="key('id',@ref)" mode="label"/>
    </xsl:template>

    <xsl:template match="*[not(@ref) and not(@label)]" mode="label">
        <xsl:apply-templates select=".." mode="label"/>
    </xsl:template>


    <xsl:template match="xi:spin" mode="render">
        
        <xsl:param name="datum"/>
        <xsl:for-each select="*">
            <td class="spin">
            <a class="button {local-name()}" href="?{@id}={$datum/@id}">
                <xsl:attribute name="onclick">
                    <xsl:text>return menupad(this</xsl:text>
                    <xsl:if test="ancestor::xi:view/@name">
                        <xsl:text>,&apos;</xsl:text>
                        <xsl:value-of select="concat(ancestor::xi:view/@name,'-form')"/>
                        <xsl:text>&apos;</xsl:text>
                    </xsl:if>
                    <xsl:text>, true)</xsl:text>
                </xsl:attribute>
                <xsl:apply-templates select="." mode="label"/>
            </a>
            </td>
        </xsl:for-each>
        
    </xsl:template>

    <xsl:template match="xi:spin/xi:more" mode="label">+</xsl:template>
    <xsl:template match="xi:spin/xi:less" mode="label">-</xsl:template>


    <xsl:template match="xi:export">
        <div class="export">
            <a>
                <xsl:attribute name="href">
                    <xsl:value-of select="concat('?pipeline=',@type,'&amp;form=',@ref)"/>
                    <xsl:apply-templates select="@*" mode="build-export-query"/>
                </xsl:attribute>
                <xsl:value-of select="@label"/>
                <xsl:if test="not(@label)">
                    <xsl:text>Экспорт данных в </xsl:text>
                    <xsl:value-of select="@type"/>
                </xsl:if>
            </a>
        </div>
    </xsl:template>

    <xsl:template match="@*" mode="build-export-query"/>

    <xsl:template match="@file-name" mode="build-export-query">
        <xsl:value-of select="concat('&amp;',local-name(),'=',.)"/>
    </xsl:template>


    <xsl:template match="*[@ref]" mode="class">
        <xsl:apply-templates select="key('id',@ref)" mode="class"/>
    </xsl:template>

    <xsl:template match="text()" mode="class"/>
    
    
    <xsl:template match="xi:view-schema//*[@type or @choise] | xi:data[@choise]" mode="class">
        <xsl:attribute name="class">
            <xsl:value-of select="@type"/>
            <xsl:if test="@editable">
                <xsl:text> editable</xsl:text>
            </xsl:if>
            <xsl:if test="@choise">
                <xsl:text> choise</xsl:text>
            </xsl:if>
            <!--xsl:if test="self::xi:field or self::xi:parameter">
                <xsl:text> </xsl:text>
                <xsl:value-of select="substring(local-name(),1,1)"/>
            </xsl:if-->
        </xsl:attribute>
    </xsl:template>


    <xsl:template match="
        
        xi:view-schema
        | xi:view-data
        | xi:workflow
        | xi:sql
        | xi:datum
        | xi:view[@hidden]
        | xi:userinput
    "/>
    
    <xsl:template match="xi:data">
        <div class="data">
            <xsl:apply-templates select="key('id',@ref)/@label" mode="build-text"/>        
            <xsl:apply-templates select="*"/>
        </div>
    </xsl:template>    

    <xsl:template match="xi:rows-affected">
        <div class="message">
            <span>Данные успешно сохранены</span><span>Изменено записей:<xsl:value-of select="."/></span>
        </div>
    </xsl:template>
 
    <xsl:template match="xi:form/*/@label">
        <xsl:value-of select="concat(.,':')"/>
    </xsl:template>


    <xsl:template match="xi:text[@class='delimiter']">
        <br/>
    </xsl:template>

    <xsl:template match="xi:text | xi:freeform | xi:summary | xi:view">
        <div>
            <xsl:attribute name="class">
                <xsl:value-of select="concat(local-name(), ' ',local-name(@collapsable), ' ', local-name(@title), ' ', @class)"/>
            </xsl:attribute>
            <xsl:apply-templates select="@id | @name"/>
            <xsl:apply-templates select="@label" mode="build-text"/>
            <xsl:apply-templates select="." mode="render"/>
        </div>
    </xsl:template>

    
    <xsl:template match="xi:iframe">
        <!--iframe src="https://info.unact.ru" width="600px" height="400px" scrolling="yes"/-->
    </xsl:template>
    

    <xsl:template match="xi:content" name="content">
        <div class="content">
            <xsl:apply-templates select="(self::xi:page|self::xi:content/..)/*[descendant-or-self::xi:option[@chosen or xi:table or *[@src]]]" mode="menu-choise"/>
        </div>
    </xsl:template>

    <xsl:template match="xi:page | xi:image | xi:table" mode="menu-choise">
        <xsl:apply-templates select="."/>
    </xsl:template>

    <xsl:template match="xi:p/text()">
        <span><xsl:value-of select="."/></span>
    </xsl:template>

    <xsl:template match="xi:p">
        <p>
            <xsl:apply-templates select="@name"/>
            <xsl:apply-templates select="@label" mode="build-text"/>
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="xi:link">
        <a><xsl:copy-of select="@href"/><xsl:apply-templates select="@name|node()"/></a>
    </xsl:template>

    <xsl:template match="xi:field[@editable]" mode="render">
        <input type="text" id="{generate-id()}">
            <xsl:attribute name="value"><xsl:value-of select="."/></xsl:attribute>
        </input>
    </xsl:template>

    <xsl:template match="xi:field">
        <div class="field">
            <xsl:apply-templates select="@name"/>
            <label for="{generate-id()}">
                <xsl:value-of select="@label"/>
            </label>
            <span>
                <xsl:apply-templates select="." mode="render"/>
            </span>
        </div>
    </xsl:template>

    <xsl:template match="xi:p[@title]">
        <h1 class="title">
            <xsl:apply-templates />
        </h1>
    </xsl:template>

    <xsl:template match="xi:label">
        <label>
            <xsl:apply-templates select="@for|node()"/>
        </label>
    </xsl:template>

    <xsl:template match="xi:session"/>
    
    <xsl:template match="xi:SQLSTATE"/>
    
    <xsl:template match="xi:exception/xi:message/xi:result"/>
    
    <xsl:template match="xi:ErrorText|xi:exception/xi:message/xi:for-human">
        <div>
            <xsl:attribute name="class">
                <xsl:text>error message</xsl:text>
            </xsl:attribute>
            <span><xsl:value-of select="."/></span>
        </div>
    </xsl:template>

    <xsl:template match="xi:dialogue/xi:exception | xi:exception">
        <xsl:if test="descendant::xi:for-human or xi:ErrorText or text()">
            <div>
                <xsl:attribute name="class">
                    <xsl:text>exception</xsl:text>
                    <xsl:if test="preceding::xi:exception">
                        <xsl:text> secondary</xsl:text>
                    </xsl:if>
                </xsl:attribute>
                <xsl:apply-templates select="*|text()"/>
            </div>
        </xsl:if>
    </xsl:template>


    <xsl:template match="xi:table">
       <a name="the-{@name}"/>
       <div class="datagram">
           <xsl:apply-templates select="@label|xi:self[not(@label)]/@name" mode="build-text"/>
           <xsl:apply-templates select="xi:summary"/>
           <table>
               <xsl:apply-templates select="xi:thead|xi:tbody"/>
           </table>
           <xsl:apply-templates select="xi:ts"/>
           <xsl:apply-templates select="xi:expire"/>
       </div>
    </xsl:template>
    
    <xsl:template match="xi:thead">
       <thead>
           <xsl:for-each select="xi:column">
               <th><xsl:apply-templates select="@type"/><xsl:value-of select="@name"/></th>
           </xsl:for-each>
       </thead>
    </xsl:template>
    
    <xsl:template match="xi:tbody">
       <tbody>
           <xsl:for-each select="xi:row">
               <tr>
                   <xsl:apply-templates select="@name"/>
                   <xsl:apply-templates select="xi:column"/>
                   <xsl:if test="../../xi:thead/xi:column[@type='totals-column']">
                       <xsl:apply-templates select="@sum"/>
                   </xsl:if>
               </tr>
           </xsl:for-each>
       </tbody>
    </xsl:template>
    
    <xsl:template match="xi:column|xi:row/@sum|xi:row/@name">
       <td class="{local-name()}">
           <xsl:value-of select="."/>
       </td>
    </xsl:template>
    
    <xsl:template match="node()|@*" mode="td">
       <td><xsl:value-of select="."/></td>
    </xsl:template>
    
    <xsl:template match="xi:page//xi:image/@src">
       <xsl:attribute name="src">
           <xsl:value-of select="concat(.,'.png')"/>
       </xsl:attribute>
       <xsl:copy-of select="document(concat('images/',../@name,'.svg'))/*/@width"/>
       <xsl:copy-of select="document(concat('images/',../@name,'.svg'))/*/@height"/>
    </xsl:template>
    
    <xsl:template match="xi:page//xi:image/@src" mode="object">
       <xsl:attribute name="data">
           <xsl:value-of select="concat(.,'.svg')"/>
       </xsl:attribute>
       <xsl:copy-of select="document(concat('images/',../@name,'.svg'))/*/@width"/>
       <xsl:copy-of select="document(concat('images/',../@name,'.svg'))/*/@height"/>
    </xsl:template>
    
    <xsl:template match="xi:image" name="image-default">
       <img id="{@name}">
           <xsl:apply-templates select="@width|@height|@src"/>
           <xsl:apply-templates select="@label">
               <xsl:with-param name="name">alt</xsl:with-param>
           </xsl:apply-templates>
       </img>
    </xsl:template>
    
    <xsl:template match="xi:image" mode="image-object" name="image-object">
       <object id="{@name}" type="image/svg+xml" class="svg">
           <xsl:apply-templates select="@src" mode="object"/>
       </object>
    </xsl:template>
    
    <xsl:template match="xi:legend">
       <div class="legend">
           <xsl:apply-templates select= "../@columns-label"/>
           <xsl:apply-templates />
       </div>
    </xsl:template>
    
    <xsl:template match="@columns-label">
       <span class="label"><xsl:value-of select="."/>:</span>
    </xsl:template>
    
    <xsl:template match="xi:serie">
       <span class="serie obj{position()}">
           <span class="serie-box"/>
           <span class="serie-label"><xsl:value-of select="@name"/></span>
       </span>
    </xsl:template>
    
    <xsl:template match="xi:page//xi:image" xi:attention="bullshit">
       <a id="the-{@name}"/>
       <div class="datagram">
           <xsl:apply-templates select="@label|xi:self[not(@label)]/@name" mode="build-text"/>
           <xsl:apply-templates select="xi:summary"/>
           <!--xsl:apply-templates select="document('data/data.xml')/*/*[@name=current()/../@name]//xi:legend"/-->
           <div class="chart">
               <xsl:choose>
                   <xsl:when test="@as-svg">
                       <xsl:call-template name="image-object"/>
                   </xsl:when>
                   <xsl:otherwise>
                       <xsl:call-template name="image-default"/>
                   </xsl:otherwise>
               </xsl:choose>
           </div>
           <xsl:apply-templates select="xi:ts"/>
           <xsl:apply-templates select="xi:expire"/>
       </div>
    </xsl:template>


</xsl:transform>
