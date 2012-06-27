<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
    xmlns="http://unact.net/xml/xi"
    xmlns:xi="http://unact.net/xml/xi"
>

    <xsl:param name="model" />
 
    <xsl:template match="xi:view-definition" mode="build-secure" priority="1000">
        
        <view justopen="true">
            <xsl:apply-templates select="@name|@label"/>
            <menu>
                <option name="close" label="Закрыть"/>
                <option name="refresh" label="Обновить">
                    <xsl:copy-of select="@pipeline"/>
                    <xsl:if test="xi:workflow---[descendant::xi:command[@name='save']]">
                        <xsl:attribute name="disabled">true</xsl:attribute>
                    </xsl:if>
                </option>
                <option name="save" label="Сохранить">
                    <xsl:if test="xi:workflow[descendant::xi:command[@name='save']]">
                        <xsl:attribute name="disabled">true</xsl:attribute>
                    </xsl:if>
                </option>
                <xsl:if test="xi:workflow[count(xi:step) &gt; 1]">
                    <option name="backward" label="Вернуться" disabled="true"/>
                    <option name="forward" label="Продолжить" disabled="true"/>
                </xsl:if>
            </menu>
            <xsl:apply-templates/>
        </view>
        
    </xsl:template>

    <xsl:template match="xi:view-schema//*[not(@what-label)]/@label" mode="extend">
        <xsl:attribute name="what-label">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="xi:view-definition[@version]//xi:grid[not(@hide-empty or @show-empty)]" mode="extend">
        <xsl:attribute name="hide-empty">default</xsl:attribute>
    </xsl:template>

    <xsl:template match="xi:view-definition//xi:step" mode="extend">
        <xsl:apply-templates select="." mode="build-id"/>
        <xsl:apply-templates select="self::*[not(@name)]" mode="build-id">
            <xsl:with-param name="name">name</xsl:with-param>
        </xsl:apply-templates>
        <xsl:call-template name="build-role-attrs"/>
    </xsl:template>


    <xsl:template match="xi:all-labeled-fields|xi:add-labeled-fields" priority="1000">
        <xsl:variable name="this" select="."/>
        <xsl:variable name="form" select="ancestor::xi:form[count(ancestor-or-self::xi:form) = count(current()/ancestor::xi:form)]"/>
        <xsl:variable name="form-concept" select="$form/@concept|$form[not(@concept)]/@name"/>
        <xsl:variable name="sort-by" select="@sort-by"/>
        
        <xsl:for-each select="$model/xi:concept[@name=$form-concept]/xi:property[@label]
                             [not($this/self::xi:add-labeled-fields/../xi:field/@name = @name)]">
            <xsl:sort select="@*[local-name()=$sort-by]" data-type="text"/>
            <field>
                <!--xsl:apply-templates select="." mode="build-id"/-->
                <xsl:apply-templates select="@*"/>
                <xsl:apply-templates select="$this/../xi:field[@name=current()/@name]/@*"/>
            </field>
        </xsl:for-each>
        
    </xsl:template>
    
    <xsl:template match="xi:view-definition/xi:view-schema//*[xi:all-labeled-fields]/xi:field" priority="1000"/>

    <xsl:template match="xi:view-definition/xi:view-schema//*[not(@autofill-form)]/@autofill">
        <xsl:copy/>
        <xsl:attribute name="autofill-form">
            <xsl:value-of select="../../@name"/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="xi:view-definition/xi:view-schema//xi:markable">
        <field sql-compute="null">
            
            <xsl:attribute name="name">
                <xsl:value-of select="@for"/>
            </xsl:attribute>
            
            <xsl:attribute name="type">mark</xsl:attribute>
            
            <xsl:call-template name="view-build-default"/>            
            
        </field>
    </xsl:template>


    <xsl:template match="xi:view-definition/xi:view-schema//*" mode="build-secure">
        <xsl:copy>
            <xsl:call-template name="view-build-default"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="xi:view-definition/xi:view-schema//*">
        <xsl:copy>
            <xsl:call-template name="view-build-default"/>
        </xsl:copy>
    </xsl:template>


    <xsl:template match="xi:view-definition//*/@reuse">
        <xsl:variable name="this" select="."/>
        <xsl:for-each select="ancestor::xi:workflow/xi:reusables/*[@name=current()]">
            <xsl:apply-templates select="@*[not(local-name()=local-name($this/../@*))]|*"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="view-build-default" >
        <xsl:variable name="form" select="ancestor::xi:form[count(ancestor-or-self::xi:form) = count(current()/ancestor::xi:form)]"/>
        <xsl:variable name="form-concept" select="$form/@concept|$form[not(@concept)]/@name"/>
        <xsl:variable name="role" select="@role|self::*[not(@role)]/@name"/>
        <xsl:variable name="concept" select="self::xi:form[not(@concept)]/@name|self::xi:form/@concept"/>
        
        <xsl:apply-templates select="." mode="build-id"/>
        
        <xsl:if test="self::xi:form">
            <xsl:attribute name="concept"><xsl:value-of select="@name"/></xsl:attribute>
            <xsl:for-each select="$model/xi:concept[@name=$role]/xi:role[@actor=$form-concept]/@sql-name">
                <xsl:attribute name="parent-sql-name">
                    <xsl:value-of select="."/>
                </xsl:attribute>
            </xsl:for-each>
        </xsl:if>
        
        <xsl:apply-templates select="$model/xi:concept[@name=$form-concept]/*[@name=$role]" mode="build-schema"/>
        <xsl:apply-templates select="$model/xi:concept[@name=$model/xi:concept[@name=current()/../../@name]/xi:role[@name=current()/../@name]/@actor]/*[@name=current()/@name]" mode="build-schema"/>
        
        <xsl:for-each select="self::xi:field/ancestor::xi:form/descendant::*[@autofill=current()/@name and @autofill-form=current()/parent::*/@name]
                             |self::xi:field/parent::xi:form/xi:field[@autofill=current()/@name and not (@autofill-form) ]">
            <xsl:call-template name="build-id">
                <xsl:with-param name="name">autofill-for</xsl:with-param>
            </xsl:call-template>
        </xsl:for-each>
        
        <xsl:apply-templates select="xi:sql-compute" mode="as-attribute"/>
        
        <xsl:apply-templates select="@*|self::xi:field[@editable]/parent::xi:form/@autosave"/>
        
        <xsl:apply-templates select=".|@*" mode="extend"/>
        
        <xsl:if test="self::xi:form[@name='sysuser'][xi:parameter and not(xi:parameter[@name='device-name'])]">
            <parameter name="device-name">
                <init with="device-name"/>
            </parameter>
        </xsl:if>
        
        <!--xsl:if test="self::xi:form[@expect-choise or ../descendant::xi:join[not(@field)]/@name=@name]
                     [not(xi:field[@name='id']) and $model/xi:concept[@name=$form-concept]/xi:property[@name='id']]
                     ">
           <field name="id" key="true"/>
        </xsl:if-->
        
        <xsl:if test="self::xi:field[@name='xid']">
            <xsl:attribute name="key">true</xsl:attribute>
            <xsl:if test="not(xi:init)">
                <init with="uuid"/>
            </xsl:if>
        </xsl:if>
        
        <xsl:apply-templates select="node()"/>
        <!--xsl:apply-templates select="node()" mode="extend"/-->
        
        <xsl:if test="self::*[@name='username'][not(xi:init)]">
            <init with="username"/>
        </xsl:if>
        
        <xsl:if test="self::xi:spin">
            <less id="spin-{generate-id()}-less"/>
            <more id="spin-{generate-id()}-more"/>
        </xsl:if>
        
        <xsl:if test="self::xi:form[not(@role)]">
            <xsl:if test="not (xi:order-by or xi:natural-order)">
                <xsl:for-each select="xi:field[@name='name']">
                    <order-by name="{@name}" dir="asc"/>
                </xsl:for-each>
            </xsl:if>
        </xsl:if>
        
        <xsl:if test="self::xi:form">
            <xsl:for-each select=
                 "$model/xi:concept[@name=$form-concept]/xi:role[@name=@role]
                 |$model/xi:concept[@name=$concept]/xi:role[@actor=$form-concept]
                 ">
                <parent-join name="{$form-concept/../@name}" concept="{$form-concept}" role="{@name}">
                    <xsl:copy-of select="@sql-name"/>
                </parent-join>
            </xsl:for-each>
        </xsl:if>
        
    </xsl:template>

    <xsl:template match="xi:view-definition/xi:view-schema">
        <xsl:call-template name="id"/>
        <view-data/>
    </xsl:template>

    <xsl:template match="xi:view-definition//xi:workflow">
        <xsl:call-template name="id"/>
        <xsl:if test="not(following-sibling::*[1]/self::xi:dialogue)">
            <dialogue>
                <xsl:copy-of select="@name"/>
            </dialogue>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="xi:view-definition/xi:view-schema//*/@set">
        <xsl:attribute name="is-set"><xsl:value-of select="."/></xsl:attribute>
    </xsl:template>

    <xsl:template match="*" mode="build-schema">
        <xsl:copy-of select="@key|@sql-name|@sql-compute|@mdx-name|@mdx-compute|@type|@label"/>
        <xsl:if test="self::xi:role">
            <xsl:attribute name="role"><xsl:value-of select="@name"/></xsl:attribute>
            <xsl:attribute name="concept"><xsl:value-of select="@actor"/></xsl:attribute>
        </xsl:if>
    </xsl:template>
    
    
    <xsl:template match="xi:view-definition" mode="build-option">
        <xsl:apply-templates select="@*|*" mode="build-option"/>
    </xsl:template>

</xsl:stylesheet>
