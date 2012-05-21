<?xml version="1.0" ?>
<xsl:transform version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns="http://unact.net/xml/xi"
 xmlns:xi="http://unact.net/xml/xi"
 >
  
 <xsl:output method="xml" indent="no"/> 
 
 <xsl:template match="/*[xi:session[xi:menu/xi:option[@chosen][@name='login']]]">
   <xsl:variable name="authsvc" 
      select="document(concat('http://macbook01.local/~sasha/XML/auth.php?login='
              ,xi:session/xi:data/xi:datum[@name='login']))"/>
   <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:choose>
        <xsl:when test="$authsvc/*[text()='true']">
          <xsl:apply-templates select='*' mode="loginsuccess"/>
          <xsl:apply-templates select="document('init.xml')/*/xi:context-extension[xi:views]/*" mode="loginsuccess"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select='*'/>
          <message type="exception">
            <xsl:text>Неверно указано имя или пароль</xsl:text>
          </message>
        </xsl:otherwise>
      </xsl:choose>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="*|@*" mode="loginsuccess">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()" mode="loginsuccess"/>
  </xsl:copy>
 </xsl:template>

 <xsl:template match="/*/xi:session" mode="loginsuccess">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()" mode="loginsuccess"/>
    <authorised/>
  </xsl:copy>
 </xsl:template> 

 <xsl:template match="xi:session/xi:data/xi:datum[@name='password']/text()" mode="loginsuccess"/>
 <xsl:template match="xi:session/xi:data/xi:datum/@editable" mode="loginsuccess"/>

 <xsl:template match="xi:session/xi:menu/xi:option[@name='login']" mode="loginsuccess">
  <option name="logoff" title="Завершить сеанс"/>
 </xsl:template>

 <xsl:template match="@href" mode="loginsuccess">
    <xsl:apply-templates select=".|document(.)/*/@*"/>
 </xsl:template>
 
</xsl:transform>
