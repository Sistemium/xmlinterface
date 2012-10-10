<?php
include('functions.php');

set_time_limit (180);
error_reporting ( E_ALL );
set_error_handler( 'exceptions_error_handler' );

try { if (isset( $_SERVER['REQUEST_METHOD'] )){
    
    ob_start('ob_gzhandler');
    execute ();

} else die (
    
    'Not implemented'
    
);} catch ( Exception $e ){
    
    header('Content-Type: text/html');
    header('Location:');
    
    print '<h1>Error</h1>';
    print '<pre>'.$e.'</pre>';
    
}

function execute ($config = 'init', $pipelineName = 'main', $disableOutput = false) {
    
    $uri = $_SERVER["REQUEST_URI"];
    $qrs = $_SERVER["QUERY_STRING"];
    $requestMethod=isset($_SERVER['REQUEST_METHOD'])?$_SERVER['REQUEST_METHOD']:'CLI';
    $user_agent =  isset($_SERVER['HTTP_USER_AGENT'])?$_SERVER['HTTP_USER_AGENT']:'CLI';
    $remote_addr = isset($_SERVER['REMOTE_ADDR'])?$_SERVER['REMOTE_ADDR']:'CLI';
    
    if ($qrs != '') $uri = str_replace ('?'.$qrs, '', $uri);

    $initName=isset($_GET['config'])?$_GET['config']:$config;
    $initFile = $initName . '.xml';
    $config=simplexml_load_file($initFile);
    $appname=$config['name'];

    session_name($appname);
    session_set_cookie_params (28800, $uri);

    if ( isset($_COOKIE["$appname"]) ) session_start();
    
    if ( isset($_SESSION['context']) ) {
        $Context=new SimpleXMLElement($_SESSION['context']);
        $Context['restored']='true';
    } else {
        $Context = new SimpleXMLElement (
           '<?xml version="1.0" encoding="utf-8"?>'
           .'<context xmlns="http://unact.net/xml/xi"'
           .' xmlns:xi="http://unact.net/xml/xi"><session-control/></context>'
        );
    }
    
    $Context['init-file'] = $initFile;
    $Context->userinput[0] = '';
    $Context->userinput['executed-by']=$requestMethod;
    $Context->userinput['user-agent'] =$user_agent;
    $Context->userinput['remote-host'] =$remote_addr;
    $Context->userinput['request-date'] =date('m.d.Y');
    $Context->userinput['request-time'] =date("H:i:s");
    $Context->userinput['host'] = strlen($_SERVER['HTTP_HOST'])?$_SERVER['HTTP_HOST']:$_SERVER['SERVER_NAME'];    
    $Context->userinput['request-path'] = $uri;
    $Context->userinput['query-string'] = $qrs;
    
    if (isset ($_SERVER['CONTENT_TYPE'])) $Context->userinput['Content-type'] = $_SERVER['CONTENT_TYPE'];
    
    $command='';
    $quitstage='';
    
    $ui = $context_part =  $Context->userinput[0];    
    
    foreach (array_merge($_GET,$_POST) as $key => $value)
        switch ($key) {
            case 'config':
                break;
            case 'quitstage':
                $quitstage=$value;
                break;
            case 'pipeline':
                $pipelineName=$value;
                break;
            case 'password':
                $password=$value;
                break;
            case 'debug-on':
                $Context['debug']='true';
                break;
            case 'command':
                $command=$value;
                break;
            case 'access_token':
                $access_token=$value;
                break;
            case 'username':
            case 'login':
                $username=trim($value);
                break;
            default:
                $context_part =  $ui -> addChild('command');
                $context_part -> addAttribute('name', $key);
                if ($value != '') $context_part[0] = $value;
    }
    
    foreach ($_FILES as $key => $value){
        $context_part =  $ui -> addChild('command');
        $context_part -> addAttribute('name', $key);
        $context_part[0] = $_FILES[$key]['tmp_name'];
    }

    $authenticated=isset($_SESSION['authenticated']);
    
    switch ($command) {
        case 'authenticate':
            if (!$authenticated) {
                
                $extraData=false;
                $credentials = array();
                
                if (isset($username) && isset($password)) {
                    $credentials['username'] = $username;
                    $credentials['password'] = $password;
                } else if (isset($access_token)) {
                    $credentials['access_token'] = $access_token;
                }
                
                if ( $validator = authenticateGeneric ($credentials,$extraData) ) {
                    
                    if (!isset($_COOKIE["$appname"])) session_start();
                    
                    $_SESSION ['authenticated'] = time();
                    $_SESSION ['username'] = isset($username)
                        ? $username : (string) ($extraData -> account[0] -> name [0]);
                    $_SESSION ['validator'] = $validator;
                    
                    if (isset($access_token))
                        $_SESSION ['access_token'] = $access_token
                    ;
                    
                    if ($extraData) {
                        
                        $Context->session[0]='';
                        
                        if (isset($extraData->groups[0]))
                            foreach ($extraData->groups[0]->group as $grp) {
                                $newChild=$Context->session[0]->addChild('group');
                                $newChild->addAttribute('name', (string) $grp['name']);
                        }
                        
                        if (isset($extraData->roles[0]))
                            foreach ($extraData->roles[0]->role as $role) {
                                $newChild=$Context->session[0]->addChild('group');
                                $newChild->addAttribute('ref', (string) $role[0]);
                        }
                        
                    }
                    
                } else {
                    $Context->session['username'] = isset($username) ? $username : '';
                    $Context->session->exception='Неверное имя или пароль';
                }
                
            }
            break;
        case 'logoff':
            if ($authenticated){
                session_unset();
                session_destroy();
            }
            break;
    }
    
    
    $authenticated=isset($_SESSION['authenticated']);
    
    if ($authenticated){
        $Context->session['id']=session_id();
        $Context->session['authenticated']=date('Y/m/d G:i:s',$_SESSION['authenticated']);
        $Context->session['username']=$_SESSION['username'];
        $Context->session['validator']=$_SESSION['validator'];
        setcookie(session_name(), session_id(), time()+28800, $uri);
    } elseif (isset($_COOKIE["$appname"]))
        setcookie(session_name(), '', time()-42000, $uri);
    
    $host = strlen($_SERVER['HTTP_HOST'])?$_SERVER['HTTP_HOST']:$_SERVER['SERVER_NAME'];

    if (
            ($initFile=='init.xml' && $pipelineName == 'main' && $requestMethod=='POST'
             && $_SERVER["CONTENT_TYPE"] == 'application/x-www-form-urlencoded' && $authenticated
            )
            || $command=='logoff' || $command=='cleanUrl' || ($command == 'authenticate' && isset($access_token))
       ) {
        $schema = $_SERVER['SERVER_PORT']=='443'?'https':'http';
        $querylen = strlen($_SERVER["QUERY_STRING"]);
        $querylen += $querylen ? 1 : (strpos ($_SERVER["REQUEST_URI"], '?') ? 1 : 0);
        $host .= $querylen ? substr($_SERVER["REQUEST_URI"],0,-$querylen) : $_SERVER["REQUEST_URI"];
        
        $location = '';
        if ($initName!='init') $location='config='.$initName;
        if ($location!='') $location ='?'.$location;
        header('Location: '.$schema.'://'.$host.$location);
        
        if ($command=='authenticate' && $authenticated)
            $_SESSION['context'] = $Context->asXML();
        if ($command=='authenticate' || $command=='logoff') {
            return;
        };
    } elseif (isset($_SESSION['redirect'])) {
        header ($_SESSION['redirected-content']);
        print $_SESSION['redirect'];
        unset($_SESSION['redirect']);
        unset($_SESSION['redirected-content']);
        return;
    }

    if (!$authenticated) {
        $private=simplexml_load_file('../secure.xml');
        if (isset ($private -> oauth ['login-page'])) {
            header ('Location:'.$private -> oauth ['login-page'], 302);
            die ('Redirecting...');
        }
    }

    $tracing = (strpos($host,'mac')!==false || strpos($host,'192.168')!==false || isset($Context['debug']));

    $xslt = new XSLTProcessor(); 
    $xslt->registerPHPFunctions();
    $xsl=new DOMDocument();
    
    $Context['pipeline-name']=$pipelineName;

    $uncommitted=new DOMDocument();
    $uncommitted->loadXML($Context->asXML());
    
    if ( isset ($_SERVER['CONTENT_TYPE']) && substr($_SERVER['CONTENT_TYPE'], -4) == '/xml' ) {
        
        $rawXML = new DOMDocument();
        $rawXML ->load ('php://input');
        
        if (!$rawXML->documentElement->getAttribute('xmlns')){
            $rawXML->documentElement->setAttribute('xmlns','http://unact.net/xml/unknown');
            $rawXML ->loadXML ( $rawXML -> saveXML() );
        }
        
        $ui = $uncommitted -> documentElement -> getElementsByTagName ('userinput') -> item(0);
        $ui = $ui -> appendChild( $uncommitted->createElementNS( 'http://unact.net/xml/xi', 'rawxml' ) );
        $ui -> appendChild( $uncommitted->importNode( $rawXML->documentElement, true ) );
        
    }

    $Context=$uncommitted;

//    var_dump ($_REQUEST);
//    echo $uncommitted->saveXML();
//    die($uncommitted->saveXML());

    $xsl_task='';
    $pipeline='';

    if (!isset($_SESSION['id-counter']))
        $_SESSION['id-counter']=0;
    
    $dir='init';
    
    if ($tracing) {
        foreach (array('stats', 'dump') as $name) {
            $dir = 'data/'.$name.'/'.$initName.'/'.$pipelineName;
            if (is_dir($dir)) rmdirfiles ($dir);
            else mkdir($dir, 0777, true);
        }
        $Context -> save(
            $dir.'/0.context.xml'
        );
        ini_set('xsl.security_prefs',0);
    }

    try { foreach ($config->pipeline as $pipeline) if ($pipeline['name'] == $pipelineName) {
        
        foreach ($pipeline->execute as $xsl_task){
            $xsl->load($xsl_task['href']);
            $stagename=$xsl_task['name'];
            
            foreach ($xsl_task->include as $include) {
                $newElement = $xsl->createElementNS('http://www.w3.org/1999/XSL/Transform','xsl:include');
                $newElement->setAttribute('href',$include['href']);
                $xsl->documentElement->appendChild($newElement);
            }
            
            $xslt->importStylesheet($xsl);
            if ($tracing) $xslt->setProfiling('data/stats/'.$initName.'/'.$pipelineName.'/'.$stagename.'.txt');
            
            $uncommitted->documentElement->setAttribute('stage',$stagename);
            
            if ($xsl_task['output']){
                $contentType='Content-Type: text/'.$xsl_task['output'];
                header($contentType);
                
                if (!(isset($xsl_task['header']) || $xsl_task['output']=='plain')){
                    $output = new DOMDocument('1.0','UTF-8');
                    $output->preserveWhiteSpace = false;
                    $output->formatOutput = false;
                    $output->loadXML($xslt->transformToDoc($uncommitted)->saveXML());
                    if ($tracing) $output->save('data/dump/'.$initName.'/'.$pipelineName.'/'.$stagename.'.xml');
                    $result=$output->saveXML();
                } else {
                    if (isset($_GET['file-name'])) {
                        header('Content-disposition: attachment;filename='.$_GET['file-name']);
                    } else {
                        header ($xsl_task['header']);
                    }
                    header('Cache-Control: private');
                    header('Pragma: private');
                    $result = $xslt->transformToXML($uncommitted);
                    if ($xsl_task['output']=='base64decode')
                        $result = base64_decode($result);
                }
                
                if (!isset($location)) print $result;
                else {
                     $_SESSION['redirect']=$result;
                     $_SESSION['redirected-content']=$contentType;
                }
                
                $dontPrint=true;
                break;
            }
            
            $repeatTransform = false;
            $repeatCount = 0;
            
            do {
                $xslt->setParameter('', 'counter', ++$_SESSION['id-counter']);
                $uncommitted = $xslt->transformToDoc($uncommitted);
                
                $command=$uncommitted->documentElement->getAttribute('pipeline');            
                $command=($command=='' && $stagename==$quitstage)?'quit':$command;
                
                if ($tracing)
                    $uncommitted->save('data/dump/'.$initName.'/'.$pipelineName.'/'.$stagename.($repeatCount?"($repeatCount)":'').'.xml');
                
                switch ($command) {
                    case 'quit':
                        $dontCommit=true; 
                    case 'save':
                        break 3;
                    case 'commit':
                        $Context=$uncommitted;
                        break;
                    case 'rollback':
                        $uncommitted=$Context;
                        break;
                    case 'repeat':
                        $repeatTransform = true;
                        $repeatCount++;
                        break;
                }
                
                if ($file=$xsl_task['save']){
                    $uncommitted->save($file);
                }
                
                if (isset($xsl_task['commit'])){
                    $commit=true;
                    $Context=$uncommitted;
                }
            } while ($repeatTransform && $repeatCount<5);
        }
        
        if (!(isset($dontCommit) || isset($commit))) $Context=$uncommitted;
        
        if (!isset($dontPrint) && !$disableOutput) {
            if ($uncommitted->documentElement->tagName == 'html')
                header('Content-Type: text/html');
            else
                header('Content-Type: text/xml')
            ;                
            if (!isset($location)) print $uncommitted->saveXML();
            else print 'redirecting';
        }
        
        if (!isset($dontCommit)){
            if ($pipeline['save'])
                $Context->save($pipeline['save']);
            elseif (isset($commit) && isset($_SESSION['authenticated']))
                $_SESSION['context'] = $Context->saveXML();
        }
        
    } } catch (Exception $e){
        
        header('Content-Type: text/html');
        header('Location:');
        
        print '<h1>Error</h1>';
        print '<pre>'.$e.'</pre>';
        
        print '<h1>Current task</h1>';
        print '<pre>';
        var_dump ($xsl_task);
        print '</pre>';
        
        //print $uncommitted->saveXML();
        
        die();
        
    }
}

?>