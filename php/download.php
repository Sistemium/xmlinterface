<?php

    require_once ('XSLTWhatMatrix.php');

    $headers = apache_request_headers ();
    
    $auth = isset ($headers['Authorization'])
        ? $headers ['Authorization']
        : (isset ($_REQUEST['Authorization:'])
            ? $_REQUEST ['Authorization:']
            : false
        )
    ;
    
    if ( $auth ) {
        
        $matrix = new XSLTWhatMatrix ();
        
        $matrix->auth = $auth;
        $matrix->resultPath = '../data/download/';
        $matrix->instructions = DOMDocument::load('../config/xml/download.instructions.xml');
        
        if ($matrix -> instructions) {
            
            $result = $matrix -> apply (
                simplexml_import_dom ($matrix -> instructions)
            );
            
        } else {
            header ('error:400',1,400);
            die("no instructions\n");
        }
        
    } else {
        header ('error:400',1,400);
        die ("no auth\n");
    }
    
    if (isset($result)) {
        
        @header('Content-type: text/xml; charset=utf-8', true);
        $result = $result->saveXML();
        print $result;
        
    } else {
        
        print '<h2>ERROR</h2>';
        
    }
    
?>