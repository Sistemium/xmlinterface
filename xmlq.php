<?php

require_once('../http/class_HTTPRetriever.php');

require_once ("functions.php");

$xslt = new XSLTProcessor(); 
$xsl  = new DOMDocument();
$xml  = new DOMDocument();

$xml->loadXML($_POST['request']);
$xsl->load('xmlq.xsl');

$xslt->importStylesheet($xsl);
$xslt->registerPHPFunctions();

$xml = $xslt->transformToDoc($xml);

header ('Content-Type: text/xml');
print $xml->saveXML();

?>