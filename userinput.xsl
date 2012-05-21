<?xml version="1.0" ?>
<xsl:transform version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns="http://unact.net/xml/xi"
 xmlns:xi="http://unact.net/xml/xi">
  
    <xsl:import href="stage-1-import.xsl"/>

    <xsl:template match="xi:message"/>
    <xsl:template match="xi:option/@chosen|xi:events"/>
    
    
    <!-- недоделка: предусмотреть отправку сообщений в активное вью -->
    
    <xsl:template match="xi:view[not(@hidden)]//*[@editable or (@modifiable and not(@xpath-compute))]/text()"/>
    
    <xsl:template match="xi:view[not(@hidden)][/*/xi:userinput/xi:command[@name='views']] | xi:view[@hidden]">
        <xsl:copy-of select="."/>
    </xsl:template>

</xsl:transform>
