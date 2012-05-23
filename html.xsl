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
    <xsl:param name="livechat" select="/*/xi:session[@authenticated and not(/*/xi:userinput/@mobile-agent)]"/>
    <xsl:param name="geo" select="descendant::xi:workflow[@geolocate] and /*/xi:userinput/@safari-agent"/>
    
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
            <title>Система Юнэкт</title>
            <link rel="shortcut icon" href="images/favicon.ico" type="image/x-icon"/>
            <link rel="apple-touch-icon" href="images/apple-touch-icon.png"/>
            
            <xsl:for-each select="xi:userinput/@*|.|*">
                <xsl:variable name="css-file">
                    <xsl:choose>
                        <xsl:when test="self::xi:userinput[not(@ipad-agent- or @safari-agent-)]">css/desktop</xsl:when>
                        <xsl:when test="xi:userinput[not(@spb-agent)]">jquery/css/jquery</xsl:when>
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
                <script type="text/javascript" src="jquery/js/jquery.js"></script>
                <script type="text/javascript" src="jquery/js/jquery-ui.js"></script>
                <xsl:if test="/*/xi:views/xi:view[not(@hidden)]/xi:dialogue/descendant::*[@clientData]">
                    <script type="text/javascript" src="js/clientData.js"></script>
                </xsl:if>
                <script type="text/javascript" src="jquery/js/jquery.ui.datepicker-ru.js"></script>
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
            
            <div id="canvas">
                <xsl:if test="$geo">
                     <div id="geomap" class="unset"/>
                </xsl:if>
                <xsl:apply-templates/>
            </div>
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
        <div class="{local-name()}">
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
        <xsl:apply-templates select="ancestor::xi:view/xi:view-data//xi:exception[key('id',(parent::xi:response/parent::xi:data|parent::xi:data)/@ref)[(ancestor::*/@id|descendant-or-self::*/@id)=current()//*/@ref]]"/>
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

    <xsl:template match="xi:dialogue">
        <xsl:apply-templates select="key('id',@current-step)" mode="render"/>
        <div class="dialogue">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="*[@label]" mode="label">
        <xsl:value-of select="@label"/>
    </xsl:template>
    
    <xsl:template match="*[not(label) and @ref]" mode="label">
        <xsl:apply-templates select="key('id',@ref)" mode="label"/>
    </xsl:template>

    <xsl:template match="*[not(@ref) and not(@label)]" mode="label">
        <xsl:apply-templates select=".." mode="label"/>
    </xsl:template>

    <xsl:template match="xi:dialogue/xi:choose">
        <div class="choose">
            <div class="exception">
                <span><xsl:value-of select="concat('Уточните [',@what-label,']')"/></span>
            </div>
            <xsl:for-each select="key('id',@ref)/xi:set-of/*">
                <div class="option">
                    <label for="{@id}">
                        <xsl:value-of select="xi:datum[@name='name']"/>
                    </label>
                    <input type="radio" class="radio" id="{@id}" value="{@id}" name="{../../@id}">
                        <xsl:attribute name="onclick">
                            <xsl:text>this.form.submit()</xsl:text>
                        </xsl:attribute>
                        <xsl:if test="/*/xi:userinput/@spb-agent">
                            <xsl:attribute name="onfocus">return onFocus(this)</xsl:attribute>
                        </xsl:if>
                    </input>
                </div>
            </xsl:for-each>
        </div>
    </xsl:template>

    <xsl:template match="xi:dialogue/xi:choose[@choise-style='table']" name="table-choise">
        <xsl:variable name="top" select="key('id',key('id',@ref)/@ref)"/>
        <xsl:variable name="column"
                      select="$top/descendant-or-self::xi:form
                                [(@no-preload or @id=$top/@id
                                    ) and not(
                                 ancestor-or-self::xi:form[@is-set][ancestor-or-self::xi:form/@id=$top/@id])]/xi:field
                                 [@label][not(@hidden or @editable or @xpath-compute)]"/>
        <table class="choose">
            <thead>
                <tr class="exception">
                    <th colspan="{count($column)+1}"><xsl:value-of select="concat('Уточните [',@what-label,']')"/></th>
                </tr>
                <tr>
                    <xsl:for-each select="$column">
                        <th><xsl:value-of select="@label"/></th>
                    </xsl:for-each>
                </tr>
            </thead>
            <tbody>
                <xsl:for-each select="key('id',@ref)/xi:set-of[@is-choise]/*">
                    <xsl:variable name="currentOption" select="."/>
                    <tr class="option">
                        <xsl:for-each select="$column">
                            <td>
                                <xsl:attribute name="class">
                                    <xsl:value-of select="concat('text ',@type)"/>
                                </xsl:attribute>
                                <xsl:for-each select="$currentOption/descendant::xi:datum[@ref=current()/@id]">
                                    <xsl:call-template name="print"/>
                                </xsl:for-each>
                            </td>
                        </xsl:for-each>
                        <td>
                            <input type="radio" class="radio" id="{@id}" value="{@id}" name="{../../@id}">
                                <xsl:attribute name="onclick">
                                    <xsl:text>this.form.submit()</xsl:text>
                                </xsl:attribute>
                                <xsl:if test="/*/xi:userinput/@spb-agent">
                                    <xsl:attribute name="onfocus">return onFocus(this)</xsl:attribute>
                                </xsl:if>
                            </input>
                        </td>
                    </tr>
                </xsl:for-each>
            </tbody>
        </table>
    </xsl:template>

    <xsl:template match="xi:grid">
        
        <xsl:variable name="this" select="."/>
        <xsl:variable name="colspan"
                      select="count($this/xi:columns/xi:column)+count($this//xi:option)+count($this/@deletable)"
        />
        
        <div id="{@id}">
            
            <xsl:attribute name="class">
                <xsl:text>grid</xsl:text>
                <xsl:if test="@accordeon">
                   <xsl:text> accordeon</xsl:text>
                </xsl:if>
            </xsl:attribute>
            
            <table class="grid">
                <thead>
                    
                    <xsl:apply-templates select="." mode="build-tools">
                        <xsl:with-param name="colspan" select="$colspan"/>
                    </xsl:apply-templates>
                    
                    <xsl:for-each select="@label">
                        <tr class="title">
                           <th colspan="{$colspan}">
                              <xsl:value-of select="."/>
                              <xsl:if test="key('id',../@ref)/@toggle-edit-off">
                                    <a type="button" href="?{key('id',../@ref)/@name}=toggle-edit&amp;command=cleanUrl"
                                       class="button ui-icon ui-icon-pencil" onclick="return menupad(this,false,false);"/>
                              </xsl:if>
                           </th>
                        </tr>
                    </xsl:for-each>
                    <tr class="header">
                        <xsl:if test="descendant::xi:option or @deletable">
                            <th class="options">
                                <xsl:apply-templates select="xi:option"/>
                            </th>
                        </xsl:if>
                        <xsl:for-each select="xi:columns/xi:column">
                            <th>
                                <span><xsl:apply-templates select="." mode="label"/></span>
                            </th>
                        </xsl:for-each>
                    </tr>
                </thead>
                
                <tbody>
                    <xsl:apply-templates select="xi:rows"/>
                </tbody>
                
                <tfoot>
                    <xsl:variable name="totals-footer">
                        <tr class="footer">
                            <xsl:if test="xi:option or @deletable">
                                <th/>
                            </xsl:if>
                            <xsl:for-each select="xi:columns/xi:column">
                                <th>
                                    <span>
                                        <xsl:apply-templates select="." mode="class"/>
                                        <xsl:apply-templates select="." mode="grid-totals"/>
                                    </span>
                                </th>
                            </xsl:for-each>
                        </tr>
                    </xsl:variable>
                    
                    <xsl:if test="string-length(normalize-space($totals-footer))>0">
                        <xsl:copy-of select="$totals-footer"/>
                    </xsl:if>
                    
                    <xsl:if test="xi:page-control[not(xi:final-page)]">
                        <tr class="page-control">
                            <th colspan="{$colspan}">
                                <xsl:for-each select="xi:page-control">
                                    <!--xsl:if test="position()=1">
                                        <span><a class="button" href="?{@ref}=prev&amp;command=cleanUrl">&lt;</a></span>
                                    </xsl:if-->
                                    <a class="button" href="?{@ref}=refresh&amp;command=cleanUrl">
                                        <xsl:if test="@visible"><span><xsl:text>Страница </xsl:text></span></xsl:if>
                                        <span><xsl:value-of select="@page-start + 1"/></span>
                                    </a>
                                    <xsl:if test="position()=last() and not(xi:final-page)">
                                        <span><a class="button" href="?{@ref}=next&amp;command=cleanUrl">&gt;</a></span>
                                    </xsl:if>
                                </xsl:for-each>
                            </th>
                        </tr>
                    </xsl:if>
                    
                    <xsl:apply-templates select="." mode="build-tools">
                        <xsl:with-param name="colspan" select="$colspan"/>
                    </xsl:apply-templates>
                    
                </tfoot>
            </table>
        </div>
    </xsl:template>

    <xsl:template match="*" mode="build-tools">
        <xsl:param name="colspan" />
        <tr class="tools" style="display:none">
            <td>
                <xsl:if test="$colspan">
                    <xsl:attribute name="colspan">
                        <xsl:value-of select="$colspan"/>
                    </xsl:attribute>
                </xsl:if>
                <a href="?pipeline=csv1251&amp;form={@ref}">csv</a>
            </td>
        </tr>
    </xsl:template>                    

    <xsl:template match="xi:column" mode="grid-totals">
         <xsl:if test="key('id',@ref)/@totals='sum'">
            <xsl:variable name="values" select="key('id',parent::*/parent::xi:grid/@top)//xi:datum[@ref=current()/@ref][text()!='']"/>
            <xsl:if test="$values">
               <xsl:value-of select="format-number(sum($values),'#,##0.00')"/>
            </xsl:if>
         </xsl:if>
    </xsl:template>

    <xsl:template match="xi:datum" mode="grid-group">
        <xsl:param name="colspan"/>
        <xsl:param name="cnt"/>
        <xsl:param name="cnt-show"/>
        <tr class="group" name="{@name}">
            <xsl:if test="../@removable">
                <td class="options">
                    <xsl:apply-templates select="../@removable"/>
                </td>
            </xsl:if>
            <td colspan="{$colspan}">
                <span><xsl:value-of select="."/></span>
                <xsl:if test="$cnt-show">
                    <span>(<xsl:value-of select="$cnt"/> шт.)</span>
                </xsl:if>
            </td>
        </tr>
    </xsl:template>

    <xsl:template match="xi:data" mode="gridrow">
        
        <xsl:param name="columns"/>
        <xsl:param name="groups"/>
        
        <xsl:variable name="data" select="."/>
        <xsl:variable name="datas-prev" select="preceding::xi:data[@ref=current()/@ref]"/>
        <xsl:variable name="data-prev" select="$datas-prev[last()]"/>

        <xsl:for-each select="$groups">
            <xsl:for-each select="xi:by">
                <xsl:variable name="current-value" select="$data//xi:datum[@ref=current()/@ref]|$data/ancestor::xi:data/xi:datum[@ref=current()/@ref]"/>
                <xsl:variable name="prev-value" select="$data-prev//xi:datum[@ref=current()/@ref]|$data-prev/ancestor::xi:data/xi:datum[@ref=current()/@ref]"/>
                
                <xsl:if test="not($current-value = $prev-value)">
                    <xsl:apply-templates select="$current-value" mode="grid-group">
                        <xsl:with-param name="colspan" select="count($columns/xi:column|$columns/parent::xi:grid[@deletable])"/>
                        <!--xsl:with-param name="cnt" select="count($data/following::xi:data[@ref=$data/@ref and (descendant::xi:datum|ancestor::xi:data/xi:datum)[@ref=current()/@ref][text()=($data//xi:datum|$data/ancestor::xi:data/xi:datum)[@ref=current()/@ref]]])+1"/>
                        <xsl:with-param name="cnt-show" select="$columns/../@accordeon"/-->
                    </xsl:apply-templates>
                </xsl:if>
            </xsl:for-each>
        </xsl:for-each>
        
        <tr xi:id="{@id}">
            
            <xsl:attribute name="class">
                <xsl:value-of select="concat('data ',local-name(xi:exception),' ',local-name(@is-new), ' ', local-name(@delete-this))"/>
                <xsl:for-each select="$groups/../xi:class[$data//xi:datum[text()]/@ref=@ref or $data/ancestor::xi:data/xi:datum[text()]/@ref=@ref]">
                    <xsl:value-of select="concat(' ',@name)"/>
                </xsl:for-each>
            </xsl:attribute>
            
            <xsl:if test="$columns/parent::*[xi:option or xi:rows[xi:option]] or $columns/../@deletable">
                <td class="options">
                    <xsl:apply-templates select="@deletable|$columns/../xi:rows/xi:option">
                        <xsl:with-param name="option-value" select="$data/@id"/>
                    </xsl:apply-templates>
                </td>
            </xsl:if>
            
            <xsl:for-each select="$columns/xi:column">
                
                <xsl:variable name="datum"
                              select="$data//*[@ref=current()/@ref]
                                     |$data/ancestor::xi:data/xi:datum[@ref=current()/@ref]"
                />
                
                <td>
                    
                    <xsl:for-each select="@extra-style">
                        <xsl:attribute name="style">
                            <xsl:value-of select="."/>
                        </xsl:attribute>
                    </xsl:for-each>
                    
                    <xsl:attribute name="class">
                        <xsl:value-of select="normalize-space(concat(local-name(@modified),' text ',key('id',@ref)/@type))"/>
                    </xsl:attribute>
                    
                    <xsl:if test="$datum/@modified">
                        <xsl:attribute name="class">modified</xsl:attribute>
                    </xsl:if>
                    
                    <xsl:choose>
                        
                        <xsl:when test="@display-only and $datum/self::xi:datum">
                            <xsl:for-each select="$datum">
                                <xsl:call-template name="print"/>
                            </xsl:for-each>
                        </xsl:when>
                        
                        <xsl:when test="xi:navigate">
                            <a>
                                <xsl:attribute name="href">
                                    <xsl:value-of select="concat('?views=',xi:navigate/@to)"/>
                                    <xsl:for-each select="key('id',xi:navigate/@ref)/xi:pass">
                                        <xsl:value-of select="concat('&amp;', @name, '=', $datum/ancestor::*/xi:datum[@ref=current()/@ref])"/>
                                    </xsl:for-each>
                                </xsl:attribute>
                                <xsl:for-each select="$datum">
                                    <xsl:call-template name="print"/>
                                </xsl:for-each>
                            </a>
                        </xsl:when>
                        
                        <xsl:otherwise>
                            <xsl:apply-templates select="$datum" mode="render"/>
                        </xsl:otherwise>
                        
                    </xsl:choose>
                    
                    <xsl:apply-templates select="*[not($datum)]">
                        <xsl:with-param name="data" select="$data"/>
                    </xsl:apply-templates>
                    
                </td>
                
                <xsl:for-each select="key('id',$datum/@ref)/xi:spin">
                    
                    <xsl:apply-templates select="." mode="render">
                        <xsl:with-param name="datum" select="$datum"/>
                    </xsl:apply-templates>
                    
                </xsl:for-each>
                
            </xsl:for-each>
            
        </tr>
        
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


    <xsl:template match="xi:rows[@ref]">
        
        <xsl:for-each select="@clientData">
            <xsl:attribute name="class">clientData empty </xsl:attribute>
            <xsl:attribute name="id"><xsl:value-of select="."/></xsl:attribute>
        </xsl:for-each>
        
        <xsl:apply-templates select="
                    key('id',parent::xi:grid/@top)//xi:data
                    [not(@hidden)]
                    [not(ancestor::xi:set-of[@is-choise])]
                    [@ref=current()/@ref]
                " mode="gridrow"
        >
            
            <xsl:with-param name="columns" select="../xi:columns"/>
            <xsl:with-param name="groups" select="xi:group"/>
            
        </xsl:apply-templates>
        
    </xsl:template>

    <!--xsl:template match="xi:rows/xi:row">
        <xsl:apply-templates select="key('id',@ref)[1]">
            <xsl:with-param name="columns" select="ancestor::xi:grid/xi:columns"/>
        </xsl:apply-templates>
    </xsl:template-->

    <xsl:template match="xi:export">
        <div class="export">
            <a>
                <xsl:attribute name="href">
                    <xsl:value-of select="concat('?pipeline=',@type,'&amp;form=',@ref)"/>
                    <xsl:apply-templates select="@*" mode="build-export-query"/>
                </xsl:attribute>
                <xsl:text>Экспорт данных в </xsl:text>
                <xsl:value-of select="@type"/>
            </a>
        </div>
    </xsl:template>

    <xsl:template match="@*" mode="build-export-query"/>

    <xsl:template match="@file-name" mode="build-export-query">
        <xsl:value-of select="concat('&amp;',local-name(),'=',.)"/>
    </xsl:template>

    <xsl:template match="xi:input|xi:print">
        
        <xsl:param name="data" select="xi:null"/>
        
        <xsl:variable name="datum"
                      select="key( 'id', self::*[not($data)]/@ref
                                        |$data/descendant::*[@ref=current()/@ref]/@id
                                        |$data/ancestor::*/xi:datum[@ref=current()/@ref]/@id
                      )"
        />
        
        <div>
            
            <xsl:attribute name="class">
                <xsl:text>datum </xsl:text>
                <xsl:value-of select="normalize-space(concat(local-name(.),' ',@name,' ',local-name($datum/@modified)))"/>
            </xsl:attribute>
            
            <xsl:for-each select="@extra-style">
                <xsl:attribute name="style">
                    <xsl:value-of select="."/>
                </xsl:attribute>
            </xsl:for-each>
            
            <xsl:if test="ancestor::xi:region | ancestor::xi:tabs">
                <xsl:attribute name="id">
                    <xsl:value-of select="@id"/>
                </xsl:attribute>
            </xsl:if>
            
            <xsl:choose> <!-- build label -->
                
                <xsl:when test="parent::xi:tabs"/>
                
                <xsl:when test="/*/xi:userinput/@spb-agent and $datum/self::xi:data[@choise and not(@chosen)]">
                    <div>
                        <span><xsl:apply-templates select="$datum[1]" mode="label"/></span>
                        <span class="colon"><xsl:text>:</xsl:text></span>               
                    </div>
                </xsl:when>
                
                <xsl:otherwise>
                    <label for="{@ref}">
                        <span><xsl:apply-templates select="$datum[1]" mode="label"/></span>
                        <span class="colon"><xsl:text>:</xsl:text></span>               
                    </label>
                </xsl:otherwise>
                
            </xsl:choose>
            
            <xsl:if test="self::xi:exists">
                <span>
                    <xsl:choose>
                        <xsl:when test="$datum/*[@name=current()/@child]">
                            <xsl:text>Есть </xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="class">exception</xsl:attribute>
                            <xsl:text>Нет </xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:apply-templates select="key('id',$datum/@ref)/*[@name=current()/@child]" mode="label"/>
                </span>
            </xsl:if>
            
            <xsl:choose>
                <xsl:when test="self::xi:input[not(@noforward)
                 and not(following-sibling::xi:input or parent::xi:region/following-sibling::xi:region/xi:input or ($datum[not(@type='parameter')] and following-sibling::xi:grid))]">
                    <xsl:apply-templates select="$datum" mode="render">
                        <xsl:with-param name="command">forward</xsl:with-param>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="key('id',self::xi:input/@ref)" mode="render"/>
                </xsl:otherwise>
            </xsl:choose>
            
            <xsl:for-each select="key('id',self::xi:input/@ref)[@type='parameter'][text()][not(@modified)]">
                <a type="button"
                   href="?{parent::xi:data/@id}=refresh&amp;command=cleanUrl"
                   class="button ui-icon ui-icon-refresh"
                   onclick="return menupad(this,false,false);"
                />
            </xsl:for-each>
            
            <xsl:for-each select="$datum[current()/self::xi:print/@ref]">
                <xsl:call-template name="print"/>
            </xsl:for-each>
            
        </div>
        
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


    <xsl:template match="xi:field[@autofill-for]" mode="render-value">
        <xsl:param name="value"/>
        
        <xsl:if test="string-length($value) &gt; 0">
            
            <xsl:variable name="obj"
                          select="$value/parent::xi:data/following-sibling::xi:data/descendant::xi:datum[@ref=current()/@autofill-for]
                                 |$value/parent::xi:data/descendant::xi:datum[@ref=current()/@autofill-for]
                                 |$value/ancestor::xi:data/xi:datum[@ref=current()/@autofill-for]
                                 "/>
            
            <input type="button" class="button" id="{@id}"
                   onclick="autofill('{$obj/@id}','{$value}')">
                <xsl:attribute name="class">
                    <xsl:text>button</xsl:text>
                    <xsl:if test="/*/xi:userinput/@spb-agent">
                        <xsl:text> focusable</xsl:text>
                    </xsl:if>
                </xsl:attribute>
                <xsl:if test="/*/xi:userinput/@spb-agent">
                    <xsl:attribute name="onfocus">return onFocus(this)</xsl:attribute>
                </xsl:if>
                <xsl:attribute name="value">
                    <xsl:call-template name="render-simple-text">
                        <xsl:with-param name="value" select="$value"/>
                    </xsl:call-template>
                </xsl:attribute>
            </input>
        </xsl:if>
    </xsl:template>
    

    <xsl:template match="*" mode="render-value" name="render-simple-text">
        <xsl:param name="value"/>
        <xsl:choose>
            <xsl:when test="@pipeline">
                <a href="?pipeline={@pipeline}&amp;datum={$value/@id}&amp;file-name={$value/../xi:datum[@name='name']}">Скачать файл</a>
            </xsl:when>
            <xsl:when test="@type='int' and not(@editable) and string-length($value)>0">
                <xsl:if test="not($value='0')">
                    <xsl:value-of select="format-number($value,'#')"/>
                </xsl:if>
            </xsl:when>
            <xsl:when test="@type='decimal' and not(@editable) and string-length($value)>0">
                <xsl:value-of select="format-number($value,'#,##0.00')"/>
            </xsl:when>
            <xsl:when test="@format='smalltime' and not(@aggregate)">
                <xsl:value-of select="concat(substring($value,1,6),substring($value,9,8))"/>
            </xsl:when>
            <xsl:when test="@format='hh:mm'">
                <xsl:value-of select="substring($value,12,5)"/>
            </xsl:when>
            <xsl:when test="@type='boolean' and $value='1'">
                <xsl:text>Да</xsl:text>
            </xsl:when>
            <xsl:when test="@type='xml'">
                <xsl:apply-templates select="$value" mode="xml-print"/>
            </xsl:when>
            <xsl:when test="@type='boolean' and @format='true-only'"/>
            <xsl:when test="@type='boolean' and not (@format='true-only')">
                <xsl:text>Нет</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$value"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <xsl:template match="*[(@name and text()) or text() or not(@*)]" mode="xml-print">
        <div>
            <xsl:if test="@name">
                <span class="xmlname">
                    <xsl:value-of select="concat(@name,':')"/>
                </span>
            </xsl:if>
            <span>
                <xsl:value-of select="text()"/>
            </span>
            <xsl:apply-templates select="*" mode="xml-print"/>
        </div>
    </xsl:template>
    
    <xsl:template match="xi:datum" mode="xml-print" priority="1000">
        <xsl:apply-templates select="*" mode="xml-print"/>
    </xsl:template>


    <xsl:template match="xi:datum[*[count(@*) &gt; 1]]" mode="xml-print" priority="1000">
        <xsl:param name="this" select="."/>
        <div class="tabs">
            <ul>
                <xsl:for-each select="*">
                    <li>
                        <a href="#{$this/@id}-{local-name()}-{count(preceding-sibling::*)}">
                            <xsl:value-of select="local-name()"/>
                        </a>
                    </li>
                </xsl:for-each>
            </ul>
            <xsl:apply-templates select="*" mode="xml-print"/>
        </div>
    </xsl:template>
    
    
    <xsl:template match="*[not(@name) or count(@*) &gt; 1]" mode="xml-print">
        <div id="{ancestor::xi:datum[1]/@id}-{local-name()}-{count(preceding-sibling::*)}">
            <!--h4><xsl:value-of select="concat(local-name(),':')"/></h4-->
            <xsl:for-each select="@*">
                <div>
                    <span class="xmlname">
                        <xsl:value-of select="concat(local-name(),':')"/>
                    </span>
                    <span>
                        <xsl:value-of select="."/>
                    </span>
                </div>
            </xsl:for-each>
            <xsl:apply-templates select="*" mode="xml-print"/>
        </div>
    </xsl:template>


    <xsl:template match="xi:datum | xi:data[@delete-this]/xi:data[@choise]" mode="render" name="print">
        
        <xsl:variable name="element">
            <xsl:choose>
                <xsl:when test="self::xi:datum[key('id',@ref)/@type='xml']">
                    <xsl:text>div</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>span</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:element name="{$element}">
            
            <xsl:if test="@xpath-compute">
               <xsl:attribute name="id">
                  <xsl:value-of select="@id"/>
               </xsl:attribute>
            </xsl:if>
            
            <xsl:apply-templates select="." mode="class"/>
            
            <xsl:apply-templates select="key('id',@ref)" mode="render-value">
                <xsl:with-param name="value"
                                select="self::xi:datum
                                       |self::xi:data/ancestor-or-self::xi:data/xi:data
                                       [@id=current()/@chosen]/xi:datum[@name='name']"/>
            </xsl:apply-templates>
            
        </xsl:element>
        
    </xsl:template>


    <xsl:template match="xi:data[not(@delete-this)]/xi:datum[@editable]
                        |xi:data[not(@delete-this)]/xi:data[@choise]
                        |xi:view-data/xi:data[@choise]"
                  mode="render" name="input">
        
        <xsl:param name="id" select="@id"/>
        <xsl:param name="command" />
        <xsl:param name="element">
            <xsl:choose>
                <xsl:when test="/*/xi:userinput/@spb-agent and self::xi:data[@choise and not(@chosen)]">option</xsl:when>
                <xsl:when test="self::xi:data">select</xsl:when>
                <xsl:when test="self::xi:datum[key('id',@ref)/@type='text']">textarea</xsl:when>
                <xsl:otherwise>input</xsl:otherwise>
            </xsl:choose>
        </xsl:param>
        
        <xsl:variable name="this" select="."/>
        <xsl:variable name="file-name" select="self::xi:datum[@editable='file']/../xi:datum[@editable='file-name']/@id"/>
        <xsl:variable name="def" select="key('id',@ref)"/>
        
        <span>
            <xsl:apply-templates select="self::*" mode="class"/>
            <xsl:choose>
                <xsl:when test="$def/@type='boolean'">
                    <span class="bool">
                        <input type="radio" name="{$id}" id="{concat($id,'-1')}" value="1" onclick="this.form.submit()" >
                            <xsl:if test="text()='1'">
                                <xsl:attribute name="checked">checked</xsl:attribute>
                            </xsl:if>
                        </input>
                        <label for="{concat($id,'-1')}">
                            <xsl:choose>
                                <xsl:when test="$def[@true-only and @true-only-label] and not(text()='1')">
                                    <xsl:value-of select="$def/@true-only-label"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>Да</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </label>
                    </span>
                    <xsl:if test="not($def/@true-only and text()='1')">
                        <span class="bool">
                            <input type="radio" name="{$id}" id="{concat($id,'-0')}" value="0" onclick="this.form.submit()">
                                <xsl:if test="text()!='1'">
                                    <xsl:attribute name="checked">checked</xsl:attribute>
                                </xsl:if>
                            </input>
                            <label for="{concat($id,'-0')}">Нет</label>
                        </span>
                    </xsl:if>
                    <xsl:if test="$def/self::xi:parameter[@optional]">
                        <span class="bool">
                            <input type="radio" name="{$id}" id="{concat($id,'-c')}" value="" onclick="this.form.submit()">
                                <xsl:if test="not(text())">
                                    <xsl:attribute name="checked">checked</xsl:attribute>
                                </xsl:if>
                            </input>
                            <label for="{concat($id,'-c')}">Не  важно</label>
                        </span>
                    </xsl:if>
                </xsl:when>
        
                <xsl:when test="$element='option'">
                    <xsl:for-each select="self::*[@choise][not(xi:set-of[@is-choise])]/ancestor::xi:view-data//xi:data[@name=current()/@choise]
                                         |xi:set-of[@is-choise][@id=current()/@choise]/*
                                         ">
                        <div class="option">
                            <label for="{@id}">
                                <xsl:value-of select="@label|self::*[not(@label)]/xi:datum[@name='name']"/>
                                <xsl:text>:</xsl:text>
                            </label>
                            <input class="focusable" type="radio" name="{$id}" id="{@id}" onclick="this.form.submit()">
                                <xsl:if test="$this/@chosen=@id">
                                    <xsl:attribute name="checked">checked</xsl:attribute>
                                </xsl:if>
                                <xsl:attribute name="onfocus">return onFocus(this)</xsl:attribute>
                                <xsl:attribute name="value">
                                    <xsl:value-of select="@id"/>
                                </xsl:attribute>
                           </input>
                        </div>
                    </xsl:for-each>
                </xsl:when>
    
                <xsl:otherwise>
                    <xsl:element name="{$element}">
                        <xsl:if test="/*/xi:userinput/@spb-agent or not (self::xi:datum[@type='field']) or self::xi:data[xi:set-of[@is-choise]]">
                            <xsl:attribute name="name"><xsl:value-of select="$id"/></xsl:attribute>
                        </xsl:if>
                        <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
                        
                        <xsl:if test="parent::xi:data/@delete-this">
                            <xsl:attribute name="disabled">disabled</xsl:attribute>
                        </xsl:if>
                        
                        <xsl:choose>
                            <xsl:when test="self::xi:data">
                                <xsl:attribute name="onchange">
                                    <xsl:choose>
                                        <xsl:when test="/*/xi:userinput/@spb-agent or xi:set-of[@is-choise]">this.form.submit()</xsl:when>
                                        <xsl:otherwise>
                                            <xsl:text>return selectChanged(this)</xsl:text>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>
                                <xsl:attribute name="onfocus">return onFocus(this)</xsl:attribute>
                                <xsl:if test="not(@chosen)">
                                    <option value="">(Значение не указано)</option>
                                </xsl:if>
                                <xsl:for-each select="self::*[@choise][not(xi:set-of[@is-choise])]/ancestor::xi:view-data//xi:data[@name=current()/@choise][not(ancestor::xi:set-of[@is-choise])]
                                                     |xi:set-of[@is-choise][@id=current()/@choise]/*
                                                     ">
                                    <option value="{@id}">
                                        <xsl:if test="$this/@chosen=@id">
                                            <xsl:attribute name="selected">selected</xsl:attribute>
                                        </xsl:if>
                                        <xsl:value-of select="@label|self::*[not(@label)]/xi:datum[@name='name']"/>
                                   </option>
                                </xsl:for-each>
                            </xsl:when>
                            
                            <xsl:otherwise>
                                <xsl:attribute name="type">
                                    <xsl:choose>
                                        <xsl:when test="key('id',@ref)/@type='file'">file</xsl:when>
                                        <xsl:when test="/*/xi:userinput/@ipad-agent and key('id',@ref)[@type='int' or @type='decimal']">number</xsl:when>
                                        <xsl:otherwise>text</xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>
                                <xsl:attribute name="class">
                                    <xsl:value-of select="normalize-space(concat(local-name(@modified),' ',key('id',@ref)/@type))"/>
                                    <xsl:if test="not(key('id',@ref)/@type='file')">
                                        <xsl:text> text</xsl:text>
                                    </xsl:if>
                                    <xsl:if test="$command">
                                        <xsl:text> option-forward</xsl:text>
                                    </xsl:if>
                                </xsl:attribute>
                                <xsl:if test="$id=''">
                                    <xsl:attribute name="name">
                                        <xsl:value-of select="local-name()" />
                                    </xsl:attribute>
                                </xsl:if>
                                <xsl:if test="$id='password' or @editable='password'">
                                    <xsl:attribute name="type">password</xsl:attribute>
                                </xsl:if>
                                <xsl:if test="$id='username'">
                                    <xsl:attribute name="autocapitalize">off</xsl:attribute>
                                    <xsl:attribute name="autocorrect">off</xsl:attribute>
                                </xsl:if>
                                <xsl:if test="not(/*/xi:userinput/@spb-agent)">
                                    <xsl:for-each select="($this/descendant::xi:data|$this/ancestor-or-self::xi:data)[@name=key('id',current()/@ref)/@autofill-form]/xi:datum[@name=key('id',current()/@ref)/@autofill]">
                                        <xsl:attribute name="xi:autofill">
                                            <xsl:value-of select="."/>
                                        </xsl:attribute>
                                    </xsl:for-each>
                                </xsl:if>
                                <xsl:choose>
                                    <xsl:when test="not(/*/xi:userinput/@spb-agent)">
                                        <xsl:if test="$id='password' or @type='parameter'">
                                            <xsl:attribute name="xi:option">
                                                <xsl:text> </xsl:text>
                                            </xsl:attribute>
                                        </xsl:if>
                                        <xsl:if test="$command">
                                            <xsl:attribute name="xi:option">
                                                <xsl:text>forward</xsl:text>
                                            </xsl:attribute>
                                        </xsl:if>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:attribute name="onfocus">return onFocus(this)</xsl:attribute>
                                    </xsl:otherwise>
                                </xsl:choose>
                                <xsl:if test="$file-name">
                                    <xsl:attribute name="xi:file-name">
                                        <xsl:value-of select="$file-name"/>
                                    </xsl:attribute>
                                </xsl:if>
                                <xsl:if test="not($element='textarea')">
                                    <xsl:if test="text()">
                                        <xsl:attribute name="value"><xsl:value-of select="."/></xsl:attribute>
                                    </xsl:if>
                                    <xsl:attribute name="size">
                                        <xsl:variable name="size-default">
                                            <xsl:apply-templates select="key('id',@ref)" mode="input-size"/>
                                        </xsl:variable>
                                        <xsl:choose>
                                            <xsl:when test="key('id',@ref)/@autofill">
                                                <xsl:value-of select="string-length(ancestor::xi:data/xi:datum[key('id',@ref)/@autofill-for=current()/@ref])+1"/>
                                            </xsl:when>
                                            <xsl:when test="string-length(.) = 0">
                                                <xsl:value-of select="$size-default"/>
                                            </xsl:when>
                                            <xsl:when test="string-length(.) &lt; 12">
                                                <xsl:value-of select="12"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="string-length(.)+2"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:attribute>
                                </xsl:if>
                                <xsl:if test="$element='textarea'">
                                    <xsl:attribute name="cols">30</xsl:attribute>
                                    <xsl:attribute name="rows">3</xsl:attribute>
                                    <xsl:value-of select="text()"/>
                                </xsl:if>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:element>
                </xsl:otherwise>
                
            </xsl:choose>
        </span>

        <xsl:if test="$file-name">
            <input type="hidden" id="{$file-name}" />
        </xsl:if>

        <!--xsl:apply-templates select="key('id',self::xi:datum/@ref)/*" mode="render">
            <xsl:with-param name="datum" select="."/>
        </xsl:apply-templates-->
    </xsl:template>

    <xsl:template match="*" mode="input-size">12</xsl:template>

    <xsl:template match="*[@type='string' or not(@type)]" mode="input-size">18</xsl:template>
    <xsl:template match="*[@type='number' or @type='decimal']" mode="input-size">12</xsl:template>
    <xsl:template match="*[@type='int']" mode="input-size">6</xsl:template>

    <xsl:template match="xi:view-schema | xi:view-data | xi:workflow | /*/xi:views[xi:view]/xi:menu"/>

    <xsl:template match="xi:data">
        <div class="data">
            <xsl:apply-templates select="key('id',@ref)/@label" mode="build-text"/>        
            <xsl:apply-templates select="*"/>
        </div>
    </xsl:template>    

    <xsl:template match="xi:sql"/>

    <xsl:template match="xi:rows-affected">
        <div class="message">
            <span>Данные успешно сохранены</span><span>Изменено записей:<xsl:value-of select="."/></span>
        </div>
    </xsl:template>
 
    <xsl:template match="xi:form/*/@label">
        <xsl:value-of select="concat(.,':')"/>
    </xsl:template>

    <xsl:template match="xi:datum"/>

    <xsl:template match="xi:view[@hidden]" /> 

    <xsl:template match="xi:dialogue//xi:region">
        
        <xsl:param name="data" select="xi:null"/>
        
        <div>
            
            <xsl:attribute name="class">
                <xsl:text>region </xsl:text>
                <xsl:value-of select="concat(' ',@name, ' ',local-name(@collapsable), ' ', @class)"/>
                <xsl:if test="descendant::*[@clientData]">
                    <xsl:text> ajaxloading</xsl:text>
                </xsl:if>
            </xsl:attribute>
            
            <xsl:copy-of select="@id"/>
            
            <xsl:apply-templates select="@label" mode="build-text"/>
            
            <xsl:if test="self::*[@class='tabs']">
                <xsl:call-template name="build-tabs"/>
            </xsl:if>
            
            <xsl:apply-templates>
                <xsl:with-param name="data" select="$data"/>
            </xsl:apply-templates>
            
        </div>
        
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


    <xsl:template name="build-tabs">
        <ul>
            <xsl:for-each select="*[@id]">
                <li><a href="#{@id}">
                    <xsl:choose>
                        <xsl:when test="@label">
                            <xsl:value-of select="@label"/>
                        </xsl:when>
                        <xsl:when test="key('id',@ref)/@label">
                            <xsl:value-of select="key('id',@ref)/@label"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="position()"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </a></li>
            </xsl:for-each>
        </ul>
    </xsl:template>
    
    
    <xsl:template match="xi:dialogue//xi:tabs">
        <xsl:param name="data" select="xi:null"/>
        <div class="tabs">
            <xsl:call-template name="build-tabs"/>
            <xsl:apply-templates>
                <xsl:with-param name="data" select="$data"/>
            </xsl:apply-templates>
        </div>
    </xsl:template>
    
    <xsl:template match="xi:region[@class='tabs']/xi:region/@label" mode="build-text" />
    
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

    <xsl:template match="xi:session-control[/*/xi:session[@authenticated]]">
       <form id="session-wrapper" name="session-form" method="post" action="?">
           <xsl:attribute name="class">authenticated</xsl:attribute>
            <xsl:for-each select="/*[not(xi:userinput/@spb-agent)]/xi:views[xi:view]/xi:menu[xi:option[@name][2]]">
                <div class="select">
                    <select name="views" onchange="viewChange(this)">
                        <option selected="selected"><xsl:value-of select="@label"/></option>
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
 
 <xsl:template match="xi:menu">
    <div>
        <xsl:attribute name="class">
            <xsl:value-of select="local-name()"/>
            <xsl:choose>
                <xsl:when test="xi:option[@chosen] or following-sibling::xi:view">
                    <xsl:text> chosen</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text> not-chosen</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="not(xi:option)">
                <xsl:text> empty</xsl:text>
            </xsl:if>
        </xsl:attribute>
        <!--xsl:apply-templates select="@name"/-->
        <xsl:if test="@label">
            <div class="title"><span><xsl:value-of select="@label"/></span></div>
        </xsl:if>
        <xsl:apply-templates />
    </div>
 </xsl:template>

 <xsl:template match="xi:option[@disabled]"/>
 
 <xsl:template match="xi:choise/xi:option
                     [xi:command[text()='next' or text()='unchoose']
                         [not(ancestor::xi:view//xi:data[@chosen][xi:set-of[@is-choise][count(*) > 1]]/@name=@name)]
                     ]"/>
 
 <xsl:template match="xi:choise/xi:option
                     [xi:command[ancestor::xi:view/xi:view-schema//*/@name=@name or ancestor::xi:view/xi:view-schema//*/@id=@ref]
                        [not(ancestor::xi:view/xi:view-data//*/@name=@name or ancestor::xi:view/xi:view-data//*/@ref=@ref)]
                     ]"/>

 <xsl:template match="xi:option | xi:data/@deletable | xi:data/@removable">
    <xsl:param name="option-value" select="@name"/>
    <div>
        <xsl:apply-templates select="@name|@chosen" />
        <xsl:attribute name="class">
            <xsl:value-of select="normalize-space(concat('option ',@advisor))"/>
            <xsl:for-each select="xi:command[@field]">
               <xsl:if test="ancestor::xi:view/xi:view-data//*[not(ancestor::xi:set-of[@is-choise])]/xi:datum[@ref=current()/@ref and text()=current()/text()]">
                  <xsl:text> avoid</xsl:text>
               </xsl:if>
            </xsl:for-each>
            <xsl:if test="descendant::xi:menu">
                <xsl:text> submenu</xsl:text>
            </xsl:if>
            <xsl:if test="@chosen">
                <xsl:text> chosen</xsl:text>
            </xsl:if>
            <xsl:if test="position()=1">
                <xsl:text> first</xsl:text>
            </xsl:if>
        </xsl:attribute>
        <xsl:variable name="element">
            <xsl:choose>
                <xsl:when test="/*/xi:userinput[@spb-agent or @ipad-agent]">input</xsl:when>
                <xsl:otherwise>a</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="{$element}">
            <xsl:apply-templates select="@id" />
            <xsl:attribute name="class">button</xsl:attribute>
            <xsl:attribute name="type">button</xsl:attribute>
            <!--xsl:attribute name="accesskey"><xsl:value-of select="count(preceding-sibling::xi:option)+1"/></xsl:attribute-->
            
            <xsl:if test="not(@iframe)">
                <xsl:attribute name="href">
                    <xsl:text>?</xsl:text>
                    <xsl:apply-templates select="$userinput" mode="links"/>
                    <xsl:for-each select="ancestor-or-self::xi:option">
                        <xsl:value-of select="concat(parent::xi:menu/@name,@id[not(parent::xi:option[parent::xi:menu])]|@ref,'=',$option-value)"/>
                        <xsl:if test="@pipeline">
                            <xsl:value-of select="concat('&amp;pipeline=',@pipeline)"/>
                        </xsl:if>
                        <xsl:if test="position()!=last()">&amp;</xsl:if>
                        <xsl:if test="parent::xi:menu and position()=last() and position()=2" xi:attention="lazha">
                            <xsl:value-of select="concat('#the-',@name)"/>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:for-each select="parent::xi:data/@deletable">
                        <xsl:value-of select="concat(parent::xi:data/@id,'=delete')"/>
                    </xsl:for-each>
                    <xsl:for-each select="parent::xi:data/@removable">
                        <xsl:value-of select="concat(parent::xi:data/@id,'=remove')"/>
                    </xsl:for-each>
                </xsl:attribute>
            </xsl:if>
            
            <xsl:if test="/*/xi:userinput/@spb-agent">
                <xsl:attribute name="onfocus">return onFocus(this)</xsl:attribute>
            </xsl:if>
            
            <xsl:if test="$element='input'">
                <xsl:attribute name="value">
                    <xsl:value-of select="@label"/>
                    <xsl:if test="parent::xi:data[@deletable or @removable]">x</xsl:if>
                </xsl:attribute>
            </xsl:if>
            
            <xsl:attribute name="onclick">
                <xsl:choose>
                    <xsl:when test="@iframe">
                        <xsl:text>location.replace(&apos;</xsl:text>
                        <xsl:value-of select="@iframe"/>
                        <xsl:text>&apos;)</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>return menupad(this</xsl:text>
                        <xsl:if test="ancestor::xi:view/@name">
                            <xsl:text>,&apos;</xsl:text>
                            <xsl:value-of select="concat(ancestor::xi:view/@name,'-form')"/>
                            <xsl:text>&apos;</xsl:text>
                        </xsl:if>
                        <xsl:text>)</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            
            <xsl:if test="$element='a'">
                <xsl:attribute name="title">
                    <xsl:value-of select="@label"/>
                    <xsl:if test="parent::xi:data[@deletable or @removable]">x</xsl:if>
                </xsl:attribute>
                <span>
                    <xsl:value-of select="@label"/>
                    <xsl:if test="parent::xi:data[@deletable or @removable]">x</xsl:if>
                </span>
            </xsl:if>
            
        </xsl:element>
        <xsl:apply-templates select="xi:menu|*/xi:menu" />
    </div>
 </xsl:template>
 
 <xsl:template match="xi:userinput"/>
 
 
</xsl:transform>
