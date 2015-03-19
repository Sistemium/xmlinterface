<?php

    require_once ('XSLTWhatMatrix.php');
    require_once ('UOAuthClient.php');
    require_once ('../functions.php');

    set_time_limit(180);
    
    $rawPost = file_get_contents('php://input');
    
    $headers = apache_request_headers ();
    $authToken = $headers ['Authorization'];
    
    if (!$authToken) {
        header ('System-error: 401',1,401);
        $path = localPath('../data/upload/' . uniqid('err.401-') . '.headers.txt');
        $headersString = var_export($headers,true);
        file_put_contents ($path, $headersString);
        die ('Unauthorized'."\n");
    }
    
    if ($_SERVER['CONTENT_TYPE'] != 'text/xml') {
        header ('System-error: 400',1,400);
        die ("'Content-type' must be text/xml\n");
    }
    
    session_name('UOAuthClient');
    session_id($authToken);
    session_start();
    
    $uac = new UOAuthClient ('https://uoauth.sistemium.com/a/uoauth', $authToken);
    
    session_write_close();
    
    $org = $uac->hasRole('org');
    
    if (!$org) {
        header ('System-error: 403',1,403);
        die ('<h1>Not authorized</h1>'."\n");
    }
    
    if ($rawPost == '') {
        header ('System-error: 400',1,400);
        die ("Post data not found\n");
    }
    
    $xml = new DOMDocument ('1.0');
    $xml->loadXML($rawPost);
    
    $matrix = new XSLTWhatMatrix (
        $xml,
        DOMDocument::load (localPath('../../config/xsl/upload.instructions.xsl')),
        array("org" => $org)
    );
    $matrix->auth = $authToken;
    $matrix->resultPath = '../data/upload/' . $org . '.';
    
    file_put_contents($matrix->resultPath . uniqid('log-') . '.rawpost.xml', $rawPost);
    
    if (!$matrix -> instructions) {
        header ('System-error: 500',1,500);
        die("Response matrix\n");
    }
    
    $instructions = simplexml_import_dom ($matrix -> instructions);
    $matrix ->apply ($instructions, $xml);
    
    header('Content-type: text/xml', true);
    
    $dom = dom_import_simplexml($instructions) -> ownerDocument;
    $dom->formatOutput = true;
    
    $result = $dom->saveXML();
    file_put_contents($matrix->resultPath . uniqid('log-') . '.result.xml', $result);
    
    print $result;
    
?>