<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns="http://www.w3.org/1999/xhtml"
>

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
                
                <xsl:when test="parent::xi:tabs|self::xi:print[key('id',@ref)/@format='true-only' and not($datum/text())]"/>
                
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

</xsl:stylesheet>
