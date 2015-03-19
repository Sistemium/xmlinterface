<?xml version="1.0" ?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns="http://unact.net/xml/xi"
>

    <xsl:param name="config">../config/</xsl:param>
    
    <xsl:param name="auth" select="document(concat('../',$config,'auth.xml'))/*"/>
    
    <xsl:template match="xi:session[@authenticated][not(xi:role)]">
        
        <xsl:variable name="validator" select="$auth/xi:validator[@name=current()/@validator]"/>
        
        <xsl:variable name="userRoles" select="
            $validator/xi:role
            |$validator/xi:group [@name=current()/xi:group/@name]
            /xi:role
            |xi:group[@ref]
            |$auth/xi:user[@name=current()/@username]/xi:role
        "/>
        
        <xsl:for-each select="$userRoles[@ref=$validator/@username-role]">
            <xsl:attribute name="username">
                <xsl:value-of select="."/>
            </xsl:attribute>
        </xsl:for-each>
        
        <xsl:for-each select="
            $auth/xi:roles//xi:role
                [$userRoles/@ref=@name or ($userRoles/@ref='*' and not(@type='negative'))]
            /ancestor-or-self::xi:role
        ">
            <xsl:if test="not(preceding::xi:role[@name=current()/@name])">
                <xsl:copy>
                    <xsl:apply-templates select="@*|$userRoles[@ref=current()/@name]/node()"/>
                </xsl:copy>
            </xsl:if>
            
        </xsl:for-each>
        
        <domains verify-this="true">
            <domain href="{$config}domain.xml"
                concepts-count="{count(document(concat('../',$config,'domain.xml'))/*/xi:concept)}"
            />
            <xsl:apply-templates mode="import-domain" select="
                xi:directoryList(concat($config,'domain'))/*
            "/>
        </domains>
        
    </xsl:template>

    
    <xsl:template mode="import-domain" match="xi:file">
        
        <xsl:param name="href">
            <xsl:for-each select="ancestor::xi:directory">
                <xsl:value-of select="@name"/>
                <xsl:text>/</xsl:text>
            </xsl:for-each>
            <xsl:value-of select="text()"/>
        </xsl:param>
        
        <xsl:if test="string-length($href) and contains ($href,'.xml')">
            <xsl:variable name="doc" select="document(concat('../',$href))/xi:domain"/>
            <xsl:if test="$doc">
                <domain
                    
                    href="{$href}"
                    concepts-count="{count($doc/xi:concept)}"
                    
                />
            </xsl:if>
        </xsl:if>
        
    </xsl:template>

    <xsl:template mode="import-domain" match="*">
        <xsl:apply-templates mode="import-domain" select="*"/>
    </xsl:template>
    
    <xsl:template match="
        /*[xi:userinput/*[@name='livechat' and text()='on']]
        /xi:session [@authenticated]
    ">
        <xsl:attribute name="livechat">true</xsl:attribute>
    </xsl:template>
    

</xsl:transform>
