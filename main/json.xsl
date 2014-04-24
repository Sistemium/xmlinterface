<?xml version="1.0" ?>

<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="str"
 >    
    <xsl:output method="text" encoding="utf-8" />
        
    <xsl:template name="padding">
        <xsl:value-of select="str:padding(count(ancestor::*),'&#x9;')"/>
    </xsl:template>
    
    <xsl:template match="/">
        <xsl:text>{</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>}</xsl:text>
    </xsl:template>
        
    <xsl:template name="quoted-name">
        <xsl:text>"</xsl:text>
        <xsl:value-of select="local-name()"/>
        <xsl:text>"</xsl:text>
    </xsl:template>
    
    <xsl:template match="*">
        <xsl:variable name="isSet" select="following-sibling::*[local-name()=local-name(current())]"/>
        <xsl:variable name="textNode" select="text()[not(normalize-space(.)='')]"/>
        
        <xsl:call-template name="padding"/>
        
        <xsl:call-template name="quoted-name"/>
        <xsl:text>: </xsl:text>
        
        <xsl:choose>
            
            <xsl:when test="$isSet">
                <xsl:text>[&#xA;</xsl:text>
                <xsl:for-each select=". | $isSet">
                    <xsl:call-template name="padding"/>
                    <xsl:apply-templates select="." mode="set-member"/>
                    <xsl:if test="not(position() = last())">,&#xA;</xsl:if>
                </xsl:for-each>
                <xsl:text>]</xsl:text>
            </xsl:when>
            
            <xsl:when test="not($textNode or @* or *)">
                <xsl:text>true</xsl:text>
            </xsl:when>
            
            <xsl:when test="$textNode and not (@*|*)">
                <xsl:call-template name="escape-string">
                    <xsl:with-param name="s" select="normalize-space(.)"/>
                </xsl:call-template>
            </xsl:when>
            
            <xsl:otherwise>
                <xsl:call-template name="set-member"/>
            </xsl:otherwise>
            
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="*" mode="set-member" name="set-member">
        <xsl:variable name="textNode" select="text()[not(normalize-space(.)='')]"/>
        
        <xsl:text>{&#xA;</xsl:text>

        <xsl:for-each select="@*">
            <xsl:apply-templates select="."/>
            <xsl:if test="not(position() = last()) or parent::*[*|$textNode]">,&#xA;</xsl:if>
        </xsl:for-each>

        <xsl:apply-templates select="$textNode"/>

        <xsl:for-each select="*">
            <xsl:if test="not(preceding-sibling::*[local-name()=local-name(current())])">
                <xsl:apply-templates select="."/>
                <xsl:variable name="hasFollowing">
                    <xsl:for-each select="following-sibling::*[not(local-name()=local-name(current()))]">
                        <xsl:if test="not(preceding-sibling::*[local-name()=local-name(current())])">
                            <xsl:text>1</xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:if test="string-length($hasFollowing) &gt; 0">,&#xA;</xsl:if>
            </xsl:if>
        </xsl:for-each>
        
        <xsl:text>&#xA;</xsl:text>
        <xsl:call-template name="padding"/>
        <xsl:text>}</xsl:text>
        
    </xsl:template>

    <xsl:template match="@*">
        <xsl:call-template name="padding"/>
        <xsl:call-template name="quoted-name"/>
        <xsl:text>: </xsl:text>
        <xsl:call-template name="escape-string"/>
    </xsl:template>

    <xsl:template match="text()">
        <xsl:call-template name="padding"/>
        <xsl:text>"text": </xsl:text>
        <xsl:call-template name="escape-string">
            <xsl:with-param name="s" select="normalize-space(.)"/>
        </xsl:call-template>
    </xsl:template>

    <!-- Остальное стырено у гугла -->

    <xsl:template match="text()[not(string(number())='NaN' or
                         (starts-with(.,'0' ) and . != '0'))]" mode="value">
        <xsl:value-of select="."/>
    </xsl:template>

  <!-- boolean, case-insensitive -->
    <xsl:template match="text()[translate(.,'TRUE','true')='true']" mode="value">true</xsl:template>
    <xsl:template match="text()[translate(.,'FALSE','false')='false']" mode="value">false</xsl:template>

    
  <xsl:template name="escape-string">
    <xsl:param name="s" select="."/>
    <xsl:text>"</xsl:text>
    <xsl:call-template name="escape-bs-string">
      <xsl:with-param name="s" select="$s"/>
    </xsl:call-template>
    <xsl:text>"</xsl:text>
  </xsl:template>
  
  <!-- Escape the backslash (\) before everything else. -->
  <xsl:template name="escape-bs-string">
    <xsl:param name="s"/>
    <xsl:choose>
      <xsl:when test="contains($s,'\')">
        <xsl:call-template name="escape-quot-string">
          <xsl:with-param name="s" select="concat(substring-before($s,'\'),'\\')"/>
        </xsl:call-template>
        <xsl:call-template name="escape-bs-string">
          <xsl:with-param name="s" select="substring-after($s,'\')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="escape-quot-string">
          <xsl:with-param name="s" select="$s"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Escape the double quote ("). -->
  <xsl:template name="escape-quot-string">
    <xsl:param name="s"/>
    <xsl:choose>
      <xsl:when test="contains($s,'&quot;')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,'&quot;'),'\&quot;')"/>
        </xsl:call-template>
        <xsl:call-template name="escape-quot-string">
          <xsl:with-param name="s" select="substring-after($s,'&quot;')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="$s"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Replace tab, line feed and/or carriage return by its matching escape code. Can't escape backslash
       or double quote here, because they don't replace characters (&#x0; becomes \t), but they prefix 
       characters (\ becomes \\). Besides, backslash should be seperate anyway, because it should be 
       processed first. This function can't do that. -->
  <xsl:template name="encode-string">
    <xsl:param name="s"/>
    <xsl:choose>
      <!-- tab -->
      <xsl:when test="contains($s,'&#x9;')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,'&#x9;'),'\t',substring-after($s,'&#x9;'))"/>
        </xsl:call-template>
      </xsl:when>
      <!-- line feed -->
      <xsl:when test="contains($s,'&#xA;')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,'&#xA;'),'\n',substring-after($s,'&#xA;'))"/>
        </xsl:call-template>
      </xsl:when>
      <!-- carriage return -->
      <xsl:when test="contains($s,'&#xD;')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,'&#xD;'),'\r',substring-after($s,'&#xD;'))"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$s"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

    
</xsl:transform>