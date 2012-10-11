<?php

    function exceptions_error_handler($errno, $errstr, $errfile, $errline, $errcontext) { 
        
        throw new ErrorException($errstr, $errno, 0, $errfile, $errline); 
    
    };
    
    
    date_default_timezone_set('Europe/Moscow');
    set_error_handler('exceptions_error_handler', E_ALL); 
    error_reporting(E_ALL);
    set_time_limit (180);
    
    $output = new DOMDocument('1.0','UTF-8');
    $output->preserveWhiteSpace = false;
    $output->formatOutput = false;
    $output->appendChild($output->createElement('response'));
    
	$args=$_POST;

	if (isset($args['request'])) try {

		$link = mysql_connect($args['server'],$args['login'], $args['pwd']);
		if (!$link) throw new Exception("Can't connect to server. Server returned:".mysql_error());
		
		if ($args['db'] && $args['db']!='') {
			$db_selected = mysql_select_db($args['db'],$link);
		}
		if (!$db_selected) throw new Exception("Can't select database. Server returned:".mysql_error());

		$q=new SimpleXMLElement($args['request']);
		$sql=(string)$q->sql[0];
		
		$output->documentElement->appendChild($output->createElement('sql',$sql));
		
		$query = mysql_query($sql);
		
		if (!$query) throw new Exception(mysql_error());

		$result = new DOMDocument('1.0','UTF-8');

	        if (!is_bool($query)) {
            		$row = mysql_fetch_array($query);
            		$output->documentElement->setAttribute('result-size',strlen($row[0]));
           		$result->loadXML('<result-set>'.$row[0].'</result-set>');
	            	mysql_free_result($query);
        	}
        	else {
        	    	$sql='select row_count();';
            		$query = mysql_query($sql);
	            	$row = mysql_fetch_array($query);
        	    	$result->loadXML('<rows-affected>'.$row[0].'</rows-affected>');
            		mysql_free_result($query);
        	}
		$output->documentElement->appendChild($output->importNode($result->documentElement, true));
		
        } catch (Exception $e) {
		$output->documentElement->appendChild($output->createElement('exception',$e->getMessage()));
    	}
	
	$output->documentElement->setAttribute('xmlns','http://unact.net/xml/xi');
 
	header('Content-Type: text/xml');
    	echo $output->saveXML();

?>
