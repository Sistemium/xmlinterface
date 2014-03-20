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
    
    ini_set ( 'mssql.timeout', 120);
    
    $args=$_POST;
    
    if (isset($args['request'])) try {
        
        $link = mssql_connect($args['server'],$args['login'], $args['pwd']);
        if (!$link) throw new Exception("Can't connect to server. Server returned:".mssql_get_last_message());
        
        if ($args['db'] && $args['db']!='') mssql_select_db($args['db'],$link);
        
        $q=new SimpleXMLElement($args['request']);
        $sql=(string)$q->sql[0];
        
        $output->documentElement->appendChild($output->createElement('sql',$sql));
        
        $query = mssql_query('SET ANSI_NULLS ON');
        $query = mssql_query('SET ANSI_WARNINGS ON');
        $query = mssql_query('SET TEXTSIZE 40480000');
        $query = mssql_query($sql);
        
        if (!$query) throw new Exception(mssql_get_last_message());
        
        $result = new DOMDocument('1.0','UTF-8');
    
        if (!is_bool($query)) {
            $row = mssql_fetch_array($query);
            $output->documentElement->setAttribute('result-size',strlen($row[0]));
            $result->loadXML('<result-set>'.$row[0].'</result-set>');
            mssql_free_result($query);
        }
        else {
            $sql='select @@rowcount';
            $query = mssql_query($sql);
            $row = mssql_fetch_array($query);
            $result->loadXML('<rows-affected>'.$row[0].'</rows-affected>');
            mssql_free_result($query);
        }    
        
        $output->documentElement->appendChild($output->importNode($result->documentElement, true));
        
    } catch (Exception $e) {
    
        $output->documentElement->appendChild($output->createElement('exception',$e->getMessage()));
        
    }
    
    $output->documentElement->setAttribute('xmlns','http://unact.net/xml/xi');
    
    header('Content-Type: text/xml');
    
    echo $output->saveXML();


?>