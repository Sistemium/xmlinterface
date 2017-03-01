<?php

    require_once ('headers.php');
    require_once ('XSLTWhatMatrix.php');
    require_once ('UOAuthClient.php');
    require_once ('../functions.php');

    setlocale(LC_CTYPE, array('ru_RU.utf8'));
    setlocale(LC_ALL, array('ru_RU.utf8'));

    function http_exceptions_error_handler ($errno, $errstr, $errfile, $errline ) {
        header ('System-error: 500',1,500);
        die($errstr."\n".'lineno:'.$errline."\n".'file:'.$errfile."\n");
    }

    function cleanX ($search) {
      return preg_replace('/[^А-Яа-яЁё[:print:]\x00-\xFF]/iu', '', $search);
    }

    set_error_handler( 'http_exceptions_error_handler' );
    
    

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
        $path = localPath('../data/upload/' . uniqid('err.400-') . '.headers.txt');
        $headersString = var_export($headers,true);
        file_put_contents ($path, $headersString);
        $path = localPath('../data/upload/' . uniqid('err.400-') . '.rawpost.txt');
        file_put_contents ($path, $rawPost);
        die ("'Content-type' must be text/xml\n");
    }
    
    session_name('UOAuthClient');
    session_id($authToken);
    session_start();
    
    $uac = new UOAuthClient ('http://uoauth.sistemium.net/a/uoauth', $authToken);
    
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

    $siteRole = $uac->hasRole('site');

    $site = isset($_REQUEST['site']) ? $_REQUEST['site'] : false;

    if (!$site) {
        $site = getLastPathSegment ($_SERVER['REQUEST_URI']);
        if ($site == 'upload') {
            $site = '1';
        }
    }

    if ($siteRole && $siteRole != $site) {
        header ('System-error: 401',1,401);
        die ('<h1>Not authorized on this site</h1>'."\n");
    }
    
    $xml = new DOMDocument ('1.0');
    $xml->loadXML($rawPost);
    $instructions = new DOMDocument ('1.0');
    $instructions -> load (localPath('../../config/xsl/upload.instructions.xsl'));

    $params = array("org" => $org);

    if ($site) {
        $params['site'] = $site;
    }

    $matrix = new XSLTWhatMatrix (
        $xml,
        $instructions,
        $params
    );

    $matrix->auth = $authToken;
    $matrix->resultPath = '../data/upload/' . $org . '.';
    
    file_put_contents($matrix->resultPath . uniqid('log-') . '.rawpost.xml', $rawPost);
    
    if (!$matrix -> instructions) {
        header ('System-error: 500',1,500);
        die("Response matrix\n");
    }
    
    $instructions = simplexml_import_dom ($matrix -> instructions);
    $jobDone = $matrix ->apply ($instructions, $xml);
    
    if (!$jobDone) {
        header ('System-error: 500',1,500);
        die("Server busy\n");
    }
    
    header('Content-type: text/xml', true);
    
    $dom = dom_import_simplexml($instructions) -> ownerDocument;
    $dom->formatOutput = true;
    
    $result = $dom->saveXML();
    file_put_contents($matrix->resultPath . uniqid('log-') . '.result.xml', $result);
    
    print $result;
    
?>
