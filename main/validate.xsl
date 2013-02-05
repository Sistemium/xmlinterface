<?xml version="1.0" ?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns="http://unact.net/xml/xi"
>

    <xsl:template match="xi:when[@ref]" mode="validate">
        <xsl:if test="
            ancestor::xi:view/xi:view-data
            //xi:datum [@ref=current()/@ref]
            /text() [not(.='0' and key('id',../@ref)/@type='boolean')]
        ">
            <xsl:apply-templates select="*" mode="validate"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="xi:not-when[@ref]" mode="validate">
        <xsl:if test="not(
            ancestor::xi:view/xi:view-data
            //xi:datum [@ref=current()/@ref]
            [text() [key('id',../@ref)/@type='boolean' and . = '1'] or (not(text()) and key('id',@ref)/@type='boolean')]
        )">
            <xsl:apply-templates select="*" mode="validate"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="xi:step" mode="validate">
        <xsl:apply-templates select="xi:validate/*" mode="validate"/>
    </xsl:template>

    <xsl:template match="xi:step/xi:validate//xi:nonempty" mode="validate">
        <xsl:variable name="ref"
            select="key('id',self::*[not(@field)]/@ref)/xi:field[@key][1]/@id|self::*[@field]/@ref"
        />
        <xsl:variable name="not-found"
            select="ancestor::xi:view/xi:view-data/descendant::*[@ref=current()/@ref]
                    [not(ancestor::xi:set-of[@is-choise])]/xi:response/xi:exception/xi:not-found"
        />
        <xsl:variable name="checkdatum" select="
            ancestor::xi:view/xi:view-data/descendant::*
                [@ref=$ref]
                [not(ancestor::xi:set-of[@is-choise])]"
        />
        <xsl:variable name="check2" select="
            ancestor::xi:view/xi:view-data/descendant::*
                [@ref=current()/@ref]
                [not(ancestor::xi:set-of[@is-choise]|self::xi:set-of)]
        "/>
        <xsl:if test="
            $not-found
            or not(count($checkdatum)=count($check2))
            or $checkdatum[not(text() and string-length(normalize-space(text())) &gt; 0)]
        ">
            <exception>
                <message>
                    <result
                        ref="{$ref}"
                        current-ref="{current()/@ref}"
                        checkdatum-count="{count($checkdatum)}"
                        check2-count="{count($check2)}"
                    >invalid</result>
                    <for-human>
                        <xsl:text>Необходимо указать </xsl:text>
                        <xsl:apply-templates mode="label" select="
                            ancestor::xi:view/xi:view-schema/descendant::xi:form
                                [@name=current()/@form or not(current()/@form)]
                                /descendant-or-self::*
                                [(not(self::xi:form) and @id=current()/@ref) or (not(current()/@field) and self::xi:form and @name=current()/@form)]
                        "/>
                    </for-human>
                </message>
            </exception>
        </xsl:if>
        
        <xsl:apply-templates select="*" mode="validate">
            <xsl:with-param name="datum" select="$checkdatum"/>
        </xsl:apply-templates>
        
    </xsl:template>

    <xsl:template match="xi:step/xi:validate//xi:empty" mode="validate">
        <xsl:if test="ancestor::xi:view/xi:view-data/descendant::xi:data[not(ancestor::xi:set-of[@is-choise])][(@name=current()/@form or not(current()/@form))][descendant::xi:datum[not(ancestor::xi:set-of[@is-choise])][@ref=current()/@ref or (not(current()/@field) and key('id',@ref)/@key)][text() and string-length(normalize-space(text())) &gt; 0]]">
            <exception>
                <message>
                    <result>invalid</result>
                    <for-human>
                        <xsl:text>Продолжить нельзя, пока есть </xsl:text>
                        <xsl:apply-templates select="ancestor::xi:view/xi:view-schema/descendant::xi:form[@name=current()/@form or not(current()/@form)]/descendant-or-self::*[(not(self::xi:form) and @name=current()/@field) or (not(current()/@field) and self::xi:form and @name=current()/@form)]" mode="label"/>
                        <xsl:if test="@field and @form">
                            <xsl:text> в </xsl:text>
                            <xsl:apply-templates select="ancestor::xi:view/xi:view-schema/descendant::xi:form[@name=current()/@form]" mode="label"/>
                        </xsl:if>
                    </for-human>
                </message>
            </exception>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*/xi:match" mode="validate">
        
        <xsl:param name="datum" />
        
        <xsl:if test="xi:regexp( . , $datum) = 0">
            <exception>
                <message>
                    <result>invalid</result>
                    <for-human>
                        <xsl:apply-templates select="key('id',$datum/@ref)" mode="label"/>
                        <xsl:if test="@field and @form">
                            <xsl:text> в </xsl:text>
                            <xsl:apply-templates select="ancestor::xi:view/xi:view-schema/descendant::xi:form[@name=current()/parent::*/@form]" mode="label"/>
                        </xsl:if>
                        <xsl:text> должно быть </xsl:text>
                        <xsl:apply-templates select="." mode="label"/>
                    </for-human>
                </message>
            </exception>
        </xsl:if>
        
    </xsl:template>

    <xsl:template match="xi:step/xi:validate//xi:equals" mode="validate">
        <xsl:variable name="data-object"
                  select="ancestor::xi:view/xi:view-data/descendant::xi:data[not(ancestor::xi:set-of[@is-choise])][(@name=current()/@form or not(current()/@form))]/descendant::xi:datum[not(ancestor::xi:set-of[@is-choise])][@name=current()/@field or (not(current()/@field) and key('id',@ref)/@key)]"/>
        
        <xsl:if test="not(ancestor::xi:view/xi:view-data/descendant::xi:data[not(ancestor::xi:set-of[@is-choise])][(@name=current()/@form or not(current()/@form))][descendant::xi:datum[not(ancestor::xi:set-of[@is-choise])][@name=current()/@field or (not(current()/@field) and key('id',@ref)/@key)][text()=current()/text()]])">
            <exception>
                <message>
                    <result>invalid</result>
                    <xsl:if test="$data-object">
                        <for-human>
                            <xsl:apply-templates select="key('id',$data-object/@ref)" mode="label"/>
                            <xsl:if test="@field and @form">
                                <xsl:text> в </xsl:text>
                                <xsl:apply-templates select="ancestor::xi:view/xi:view-schema/descendant::xi:form[@name=current()/@form]" mode="label"/>
                            </xsl:if>
                            <xsl:text> должно быть равно </xsl:text>
                            <xsl:apply-templates select="." mode="value"/>
                        </for-human>
                    </xsl:if>
                </message>
            </exception>
        </xsl:if>
    </xsl:template>

</xsl:transform>