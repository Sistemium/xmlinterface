<?xml version="1.0" ?>

<xsl:transform version="1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xi="http://unact.net/xml/xi"
>

    <xsl:output method="xml"
        indent="yes" omit-xml-declaration="yes" encoding="utf-8" standalone="yes"
        media-type="text/html" doctype-system="about:legacy-compat"
    />
    
    <xsl:preserve-space elements="div form script span"/>

    <xsl:template match="/">
        <html lang="en">
            
            <head>
                <meta charset="utf-8"/>
                <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
                
                <title>A System</title>    
                
                <link href="../libs/bootstrap/css/bootstrap.css" rel="stylesheet"/>
                
                <style type="text/css">
                  body {
                    padding-top: 60px;
                    padding-bottom: 40px;
                  }
                </style>
                
                <link href="../libs/bootstrap-responsive.css" rel="stylesheet"/>
                
                <link rel="shortcut icon" href="../libs/ico/favicon.ico"/>
                <link rel="apple-touch-icon-precomposed" sizes="144x144" href="../libs/ico/apple-touch-icon-144-precomposed.png"/>
                <link rel="apple-touch-icon-precomposed" sizes="114x114" href="../libs/ico/apple-touch-icon-114-precomposed.png"/>
                <link rel="apple-touch-icon-precomposed" sizes="72x72" href="../libs/ico/apple-touch-icon-72-precomposed.png"/>
                <link rel="apple-touch-icon-precomposed" href="../libs/ico/apple-touch-icon-57-precomposed.png"/>
            </head>
            
            <body>
                
                <div class="navbar navbar-inverse navbar-fixed-top">
                    <div class="navbar-inner">
                        <xsl:apply-templates select="." mode="build-bootstrap-navbar"/>
                    </div>
                </div>
                
                <xsl:apply-templates select="." mode="build-bootstrap-content"/>
                
                <script type="text/javascript" src="../libs/jquery-1.8.2.min.js">
                </script>
                <script type="text/javascript" src="../libs/bootstrap/js/bootstrap.js">
                </script>
                
            </body>
            
        </html>
    </xsl:template>
    
    
    <xsl:template mode="build-bootstrap-navbar" match="/">
        <div class="container">
          
            <a class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
                <span class="icon-bar"> </span>
                <span class="icon-bar"> </span>
                <span class="icon-bar"> </span>
            </a>
          
            <a class="brand" href="#">Secur.tel</a>
          
            <div class="nav-collapse collapse">
                
                <ul class="nav">
                  
                    <li class="active"><a href="#">Home</a></li>
                    <li><a href="?about">About</a></li>
                    <li><a href="?contact">Contact</a></li>
                    <xsl:if test="*/xi:session[@authenticated]">
                        <li><a href="?command=logoff">Logoff</a></li>
                    </xsl:if>
                  
                </ul>
                
                <form class="navbar-form pull-right">
                  <input class="span2" type="text" placeholder="Login"/>
                  <input class="span2" type="password" placeholder="Password"/>
                  <button type="submit" class="btn">Sign in</button>
                </form>
                
            </div>
          
        </div>
    </xsl:template>
    
    
    <xsl:template mode="build-bootstrap-content" match="/">
        <div id="content-container" class="container">
          
          <div class="hero-unit">
            
            <h1>The cloud you can trust</h1>
            
            <p>It's mission is to provide ultimate possible privacy of communications for free</p>
            
            <p>
              <a class="btn btn-primary btn-large" href="register.bootstrap.html">Join Secur &#187;</a>
            </p>
            
          </div>
          
          <!-- Example row of columns -->
          <div class="row">
            <div class="span4">
              <h2>SSL Jabber</h2>
              <p>Ready to use, pre-configured desktop program is provided. As an option you may use a jabber-compliant client of your choise.</p>
              <p><a class="btn" href="#">Downloads &#187;</a></p>
            </div>
            <div class="span4">
              <h2>Safe history</h2>
              <p>Do not let your client program store history of conversations! Secur tracks and protects your chat transcripts confident.</p>
              <p><a class="btn" href="#">Recommendations &#187;</a></p>
            </div>
            <div class="span4">
              <h2>No third-parties</h2>
              <p>Your data is for your private use only. Secur shows no ads and does not use your data to make money or to gain any other advantage.</p>
              <p><a class="btn" href="#">Donate &#187;</a></p>
            </div>
          </div>
          
          <hr/>
          
          <footer>
            <p>&#169; Secur System 2012</p>
          </footer>
          
        </div>
    </xsl:template>

</xsl:transform>