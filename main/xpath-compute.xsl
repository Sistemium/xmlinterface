<?xml version="1.0" ?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://unact.net/xml/xi"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns:dyn="http://exslt.org/dynamic"
    exclude-result-prefixes="dyn"
    extension-element-prefixes="dyn"
>


    <xsl:decimal-format name="totals" decimal-separator="." grouping-separator="" NaN=""/>
    <xsl:decimal-format name="null-is-0" decimal-separator="." grouping-separator="" NaN="0"/>
    <xsl:decimal-format name="display" zero-digit="0" grouping-separator="," NaN=""/>


    <xsl:template match="xi:datum[@xpath-compute]">
        <xsl:copy>
           
            <xsl:apply-templates select="@*"/>
            
            <xsl:variable name="res" select="dyn:evaluate(@xpath-compute)"/>
            
            <xsl:variable name="val">
                <xsl:choose>
                    <xsl:when test="key('id',@ref)/@type='decimal'">
                        <xsl:value-of select="format-number($res,'0.0#','totals')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$res"/>
                    </xsl:otherwise>
               </xsl:choose>
            </xsl:variable>

            <xsl:if test="@type='parameter' and @modifiable='true' and not (. = $val)">
                <xsl:attribute name="modified">true</xsl:attribute>
            </xsl:if>
            
            <xsl:if test="@original-value and not(format-number(@original-value,'0.0#','totals') = $val) and key('id',@ref)/@type='decimal'">
              <xsl:attribute name="modified">true</xsl:attribute>
            </xsl:if>
            
            <xsl:if test="key('id',@ref)/@type='decimal'">
               <xsl:attribute name="formatted">
                  <xsl:value-of select="format-number($val,'#,##0.00','display')"/>
               </xsl:attribute>
            </xsl:if>
            
            <xsl:apply-templates select="." mode="extend"/>
            
            <xsl:value-of select="$val"/>
           
        </xsl:copy>
    </xsl:template>
 

</xsl:transform>