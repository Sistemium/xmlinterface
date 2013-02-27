<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:dict="dict"
    xmlns:xi="http://unact.net/xml/xi"
    xmlns="http://unact.net/xml/xi"
    exclude-result-prefixes="dict"
>

    <xsl:output method="xml" indent="yes" encoding="utf-8"/>
    
    <xsl:template match="/xi:metadata">
        <DDL tables-count="{count(xi:tables/xi:table)}">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="sql-metadata" select="xi:tables"/>
        </DDL>
    </xsl:template>
    
    
    <dict:term name="type" to="datatype">
        <dict:key name="float">decimal(18,4)</dict:key>
        <dict:key name="boolean">BOOL</dict:key>
        <dict:key name="string">STRING</dict:key>
        <dict:key name="date">date</dict:key>
        <dict:key name="datetime">datetime</dict:key>
        <dict:key name="int">integer</dict:key>
    </dict:term>
    
    
    <xsl:template mode="sql-translate" match="@*">
        <xsl:for-each select="document('')/*/dict:term[@name=local-name(current())]/*[starts-with(current(),@name)]">
            <xsl:attribute name="{../@to}">
                <xsl:value-of select="."/>
            </xsl:attribute>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="*" mode="sql-metadata">
        <xsl:apply-templates mode="sql-metadata" select="*"/>
    </xsl:template>
    
    
    <xsl:template match="xi:table" mode="sql-metadata">
        <table name="{@id}">
            <xsl:apply-templates mode="sql-metadata" select="xi:columns"/>
        </table>
    </xsl:template>
    
    
    <xsl:template match="xi:columns" mode="sql-metadata">
        
        <xsl:apply-templates mode="sql-metadata" select="xi:column[@name='id']"/>
        <xsl:apply-templates mode="sql-metadata" select="xi:column[not(@parent or @name='id' or @name='xid')]"/>
        
        <xsl:apply-templates mode="sql-metadata" select="xi:column[@parent]"/>
        
        <primary-key>
            <xsl:for-each select="xi:column[@key]">
                <part name="{@name}"/>
            </xsl:for-each>
        </primary-key>
        
        <column name="isPhantom" datatype="BOOL"/>
        <column name="xid" datatype="GUID"/>
        <column name="ts" datatype="TS"/>
        <column name="cts" datatype="CTS"/>
        
        <unique>
            <part name="xid"/>
        </unique>
        
        <xsl:if test="xi:column[@parent] | ../xi:deps">
            <trigger>
                
                <before>
                    <insert/>
                    <update/>
                </before>
                
                <sql>
                    <xsl:text>if UPDATING then</xsl:text>
                    <sql>set inserted.isPhantom=0;</sql>
                    <xsl:text>end if;</xsl:text>
                </sql>
                
                <xsl:for-each select="xi:column[@parent]">
                    <sql>
                        
                        <xsl:text>if inserted.</xsl:text>
                        <xsl:value-of select="@name"/>
                        <xsl:text> is not null and not exists (select * from </xsl:text>
                        <xsl:value-of select="@parent"/>
                        <xsl:text> where id = inserted.</xsl:text>
                        <xsl:value-of select="@name"/>
                        <xsl:text> and isPhantom = 0) then</xsl:text>
                        
                        <sql>set inserted.isPhantom = 1;</sql>
                        <sql>
                            <xsl:value-of select="concat(
                                'insert into '
                                ,@parent
                                , ' (id) select inserted.'
                                , @name
                                , ' where not exists (select * from '
                                , @parent
                                , ' where id = inserted.'
                                , @name
                                , ')'
                            )"/>
                        </sql>
                        
                        <xsl:text>end if;</xsl:text>
                        
                    </sql>
                </xsl:for-each>
                
                <xsl:for-each select="../xi:deps/xi:dep">
                    <sql>
                        <xsl:text>if UPDATING and inserted.isPhantom = 0 then</xsl:text>
                        <sql>
                            <xsl:value-of select="concat(
                                'update '
                                , @table_id
                                , ' set isPhantom = 0 where '
                                , ancestor::xi:table/@id
                                , ' = inserted.id;'
                            )"/>
                        </sql>
                        <xsl:text>end if;</xsl:text>
                    </sql>
                </xsl:for-each>
                
            </trigger>
        </xsl:if>
        
    </xsl:template>
    
    
    <xsl:template match="xi:column[@parent]" mode="sql-metadata">
        <foreign-key>
            <xsl:copy-of select="@parent|@name"/>
        </foreign-key>
    </xsl:template>
    
    
    <xsl:template match="xi:column[not(@parent)]" mode="sql-metadata">
        <column>
            <xsl:copy-of select="@name"/>
            <xsl:apply-templates select="@type" mode="sql-translate"/>
            <xsl:if test="@name='id'">
                <xsl:attribute name="datatype">ID</xsl:attribute>
            </xsl:if>
            <xsl:if test="@name='xid'">
                <xsl:attribute name="datatype">GUID</xsl:attribute>
            </xsl:if>
        </column>
    </xsl:template>
    
    
</xsl:stylesheet>