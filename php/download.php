<?php

    require_once ('headers.php');
    require_once ('XSLTWhatMatrix.php');
    require_once ('UOAuthClient.php');
    require_once ('../functions.php');

    $headers = apache_request_headers ();
    
    $auth = isset ($headers['Authorization'])
        ? $headers ['Authorization']
        : (isset ($_REQUEST['Authorization:'])
            ? $_REQUEST ['Authorization:']
            : false
        )
    ;
    
    if (!$auth) {
        header ('System-error: 401',1,401);
        die ('Unauthorized'."\n");
    }

    @$collection = $_REQUEST['collection'];

    if (!$collection) {
        $collection = getLastPathSegment ($_SERVER['REQUEST_URI']);
        if ($collection == 'download') {
            $collection = false;
        }
    }

    $result = false;
    
    session_name('UOAuthClient');
    session_id($auth);
    session_start();
    
    $uac = new UOAuthClient ('http://uoauth.sistemium.net/a/uoauth', $auth);
    
    session_write_close();
    
    $org = $uac->hasRole('org');
    
    if (!$org) {
        header ('System-error: 403',1,403);
        die ('<h1>Not authorized</h1>'."\n");
    }

    $params = array("org" => $org);

    if ($collection) {
        $params['collection'] = $collection;
    }
    
    $matrix = new XSLTWhatMatrix ();
    
    $matrix = new XSLTWhatMatrix (
        DOMDocument::load (localPath('../../secure.xml')),
        DOMDocument::load (localPath('../../config/xsl/download.instructions.xsl')),
        $params
    );
    $matrix->auth = $auth;
    $matrix->resultPath = '../data/download/' . $org . '.';
    
    if ($matrix -> instructions) {
        
        $result = $matrix -> apply (
            simplexml_import_dom ($matrix -> instructions)
        );
        
    } else {
        header ('error:400',1,400);
        die("no instructions\n");
    }
    
    if ($result) {
        
        @header('Content-type: text/xml; charset=utf-8', true);
        $result = $result->saveXML();
        print $result;
        
    } else {
        
        header ('error:400',1,400);
        print "<h2>ERROR</h2>\n";
        print $matrix -> instructions -> saveXML();
        
    }
    
?>