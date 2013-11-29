<?xml version="1.0" ?>
<?xml-stylesheet type="text/xsl" href="html-xsl.xsl"?>

<xsl:transform version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns="http://unact.net/xml/xi"
 xmlns:xi="http://unact.net/xml/xi"
 xmlns:php="http://php.net/xsl"
 exclude-result-prefixes="php"
 >
 
    <!--
    
    Робот-тестировщик может превьюшки генерить
    
    Данные нужно получать нормализованными запросами - одновременно лучше не строить и строку и структуру
    У каждого Data может быть запись, обновление, отмена, удаление и закрытие
    У Datum есть редактирование, для обработки всего этого нужны разные режимы.
    
    Можно проверять состоятельность отредактированных данных у разных юзеров.
    Историю лучше хранить в history/, а текущие знчения прямо сразу
    
    -->
    
    <?build-template new-data id ?>  

    <xsl:template match="xi:preload/@refresh-this | xi:data/@refresh-this | xi:data[@show-this]/@hidden"/>

    <!-- рефреш всего view-data для непараметризованных представлений-->
    <xsl:template match="xi:view[xi:menu[xi:option[@chosen][@name='refresh']]]/xi:view-data
                        [xi:data[not(xi:datum[@type='parameter']) and not(descendant::xi:exception)]]
                        ">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:comment>main/data/1</xsl:comment>
            <xsl:apply-templates select="../xi:view-schema/xi:form" mode="build-data">
                <xsl:with-param name="olddata" select="."/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <xsl:template
        match="xi:view [xi:menu[xi:option[@chosen][@name='refresh']]]
                /xi:view-data
                //xi:data[key('id',@ref)[@new-only or xi:parameter[@editable and not(@optional)]]
                            and not(ancestor::xi:data/xi:response[@ts]/xi:exception|descendant::xi:exception)
                ]
                |xi:view-data//*
                 [@refresh-this and key('id',@ref)/@new-only and not(descendant::xi:exception)]
        " priority="1000"
    >
        <xsl:comment>main/data/2</xsl:comment>
        
        <xsl:apply-templates select="key('id',@ref)" mode="build-data">
            <xsl:with-param name="olddata" select="."/>
        </xsl:apply-templates>
      
    </xsl:template>


    <!-- пришли свежие данные -->
    <xsl:template priority="1001" match="
        xi:view-data
        //* [xi:response
                [xi:result-set[*]
                    or (
                        (xi:exception/xi:not-found or xi:result-set[not(*)])
                        and key('id',../@ref)[@build-blank|@extendable]
                    )
                ]
            ]
    ">
        <xsl:comment>1001</xsl:comment>
        
        <xsl:choose>
            <xsl:when test="self::xi:data">
                <xsl:comment>1001-1</xsl:comment>
                <xsl:apply-templates select="key('id',@ref)" mode="build-data">
                    <xsl:with-param name="data" select="xi:response/xi:result-set/*"/>
                    <xsl:with-param name="set-thrshld">1</xsl:with-param>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="key('id',@ref)" mode="build-data">
                    <xsl:with-param name="data" select="xi:response/xi:result-set/*"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>

    <!-- пришел ответ на запрос, но данных нет -->
    <xsl:template match="
        xi:view-data//*[xi:response/xi:result-set[not(*[*])]]
        | xi:view-data//*[@refresh-this='true'][xi:response/xi:exception/xi:not-found]
    ">
        <xsl:copy>
            <xsl:apply-templates select="@*|xi:response/@ts"/>
            
            <xsl:comment>empty result-set</xsl:comment>
            
            <xsl:apply-templates select="*[@type='parameter']"/>
        </xsl:copy>
    </xsl:template>

    <!-- пришел ответ на запрос, но данных нет -->

    <xsl:template match="
        xi:view-data//xi:preload
            [not(xi:datum[@type='parameter'])]
            [xi:response[xi:exception[xi:not-found]]]
    "/>

    <xsl:template match="xi:view-data//xi:preload[xi:response/xi:exception]" name="build-not-found-data">
        <preload>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="key('id',@ref)/@name"/>
            <xsl:apply-templates select="xi:response"/>
        </preload>
    </xsl:template>

    <xsl:template match="xi:view-data//xi:preload[xi:response/xi:exception][key('id',@ref)/@is-set]">
        <set-of>
            <xsl:apply-templates select="@*[not(local-name()='preload')]"/>
            <xsl:call-template name="build-id"/>
            <xsl:apply-templates select="key('id',@ref)" mode="build-ref"/>
            <xsl:comment>preload exception</xsl:comment>
            <xsl:call-template name="build-not-found-data"/>
        </set-of>
    </xsl:template>
    
    <xsl:template match="xi:data[@chosen][not(@chosen='ignore' or key('id',@chosen))]">
        <xsl:copy>
            <xsl:copy-of select="@name|@ref|@id"/>
            <exception>
                <xsl:call-template name="build-not-found"/>
            </exception>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="xi:view-data//xi:exception[not(xi:ErrorText)]/xi:not-found" name="build-not-found">
        <xsl:variable name="metadata" select="key('id',@ref|self::*[not(@ref)]/../../../@ref)"/>
        <xsl:for-each select="$metadata/@label">
            <not-found/>
            <ErrorText>[<xsl:value-of select="."/>]<xsl:text> не найдено</xsl:text></ErrorText>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="xi:data[xi:response/xi:result-set]/@is-new"/>

    <xsl:template match="xi:data[xi:response/xi:rows-affected]/@delete-null">
        <xsl:attribute name="is-new">true</xsl:attribute>
    </xsl:template>

    <xsl:template match="xi:view-data//xi:sql | xi:request"/>

    <xsl:template match="xi:data[xi:response[@ts and not(xi:result-set) and xi:rows-affected]]/@is-new"/>
 

    <xsl:template match="xi:datum[@type='parameter' and ancestor::*[xi:response[@ts and xi:result-set]]]/@modified" />
    
    <xsl:template match="
        xi:data [xi:response[@ts and not(xi:result-set) and xi:rows-affected]] /xi:datum[@xpath-compute] /@modifiable
        |xi:data [xi:response[@ts and not(xi:result-set) and xi:rows-affected]] /xi:datum[@type='field'] /@modified
        |xi:data [xi:response[@ts and not(xi:result-set) and xi:rows-affected]] /xi:data[@choise] /@modified
    ">
      <xsl:attribute name="original-value">
         <xsl:value-of select="../."/>
      </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="xi:data/@ts [ancestor::*[xi:response[not(xi:result-set) and xi:rows-affected]]]"/>

    <xsl:template match="xi:data[xi:response[@ts][not(xi:result-set) and xi:rows-affected] and @delete-this]" priority="500">
        <xsl:if test="key('id',@ref)[@build-blank or xi:parameter]">
            <xsl:apply-templates select="key('id',@ref)" mode="build-data"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="xi:data[xi:response[@ts][not(xi:result-set) and xi:rows-affected]]">
        
        <xsl:copy>
            
            <xsl:apply-templates select="@*|xi:response/@ts"/>
            
            <xsl:comment>rows-affected=<xsl:value-of select="xi:rows-affected"/></xsl:comment>
            
            <xsl:apply-templates select="
                xi:data|xi:datum
                |self::*[not(key('id',@ref)/@autosave)]/xi:response
                |xi:extender|xi:set-of|xi:preload"
            />
            
        </xsl:copy>
        
    </xsl:template>

    <xsl:template match="xi:data[xi:response[@ts][not(xi:result-set) and xi:rows-affected]]/xi:set-of[@is-choise]/*[@id=../../@chosen]/@is-new"/>      

    <xsl:template match="xi:data[xi:response[@ts][not(xi:result-set) and xi:rows-affected]]/xi:set-of[@is-choise]/*[@id=../../@chosen]/xi:datum[key('id',@ref)/@modifiable]">
      <xsl:copy>
         <xsl:apply-templates select="@*"/>
         <xsl:value-of select="parent::xi:data/parent::xi:set-of[@is-choise]/parent::xi:data/xi:datum[@name=current()/@name]/text()"/>
      </xsl:copy>
    </xsl:template>


    <xsl:template match="xi:response[@ts]/xi:exception/xi:ErrorText[starts-with(text(),'RAISERROR executed:')]">
      <message><for-human><xsl:value-of select="normalize-space(substring-after(.,'RAISERROR executed:'))"/></for-human></message>
    </xsl:template>

	
    <xsl:template match="xi:response[not(xi:result-set) and not(xi:exception) and xi:rows-affected]/@ts"/>


</xsl:transform>