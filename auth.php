<?php

require_once('HTTPRetriever.php');

header("Content-Type: text/xml");

$login=!empty($_GET['login'])?$_GET['login']:'';
$password=!empty($_GET['password'])?$_GET['password']:'';

$result=new SimpleXMLElement ('<authenticated>false</authenticated>'); 

if ($login=='sasha')
 $result [0]='true'
;

echo $result->asXML()

?>