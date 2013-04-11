<?php

require_once('../libs/HTTPRetriever.php');

date_default_timezone_set('Europe/Moscow');
set_time_limit (180);


    function exceptions_error_handler($errno, $errstr, $errfile, $errline, $errcontext) { 
        
        throw new ErrorException($errstr, $errno, 0, $errfile, $errline); 
    
    };

    function dumpNice ($array) {
        foreach ($array as $key=>$value)
            print $key .' = '. $value."<br/>";
    }


    function dateAdd ($shift = 0, $start = 'now') {
        return date('Y/m/d G:i:s',strtotime($shift,strtotime($start)));
    }
    
    function initToday () {
        return date('d.m.Y',strtotime('now'));
    }
    
    
    function dateEach ($each) {
        $today = getdate();
        $datepart='hour';
        $num=1;
        $chunks = explode (" ", $each, 10);
    
        if (!isset($chunks[0])) return '';
        
        if (is_numeric($chunks[0])){
            $num=$chunks[0];
            $datepart=$chunks[1];
        } else $datepart=$chunks[0];
    
        if (substr($datepart,-1)=='s') $datepart=substr($datepart,0,-1);
        
        
        $day=1;
        $month=1;
        $minute=0;
        $hour=0;
        $second=0;
        $year=$today['year'];
        
        switch ($datepart) {
            case 'month':
                $month=$today['mon'];
                break;
            case 'day':
                $month=$today['mon'];
                $day=  $today['mday'];
                break;
            case 'hour':
                $month=$today['mon'];
                $day=  $today['mday'];
                $hour= $today['hours'];
                break;
            case 'minute':
                $month=$today['mon'];
                $day=  $today['mday'];
                $hour= $today['hours'];
                $minute= $today['minutes'];
                break;
            case 'week':
                $month=$today['mon'];
                $day=  $today['mday'];
                break;
        }
        
        $next=mktime($hour,$minute,$second,$month,$day,$year);
        
        if ($datepart=='week') $next=strtotime('- ' . ($today['wday'] + 6)%7 . ' days',$next);
        
        $next = strtotime("$num $datepart",$next);
        
        return date('Y/m/d G:i:s',$next);
    }
    
    function dateExpired($date1) {
        $d1= new DateTime($date1);
        $d2= new DateTime("now");
        
        return $d1<=$d2?'expired':'not expired';
    }
    
    function docAvailable($filename) {
        return isfile($filename)?'true':'false';
    }
    
    function getContext($contextName) {
        $doc=new DOMDocument();
    
        $doc->loadxml($_SESSION[$contextName]);
        
        return $doc;
    };
    
    
    function xmlRequest($request) {
        $doc=new DOMDocument();
        
        try {
            $http = new HTTPRetriever();
            $http->stream_timeout = 120;
            $private=simplexml_load_file('../secure.xml');
        
            $src=$request[0]->ownerDocument->documentElement->getAttribute('storage');
            $db=$request[0]->ownerDocument->documentElement->getAttribute('db');
            $server=$request[0]->ownerDocument->documentElement->getAttribute('server');
            
            if ($src!='mssql'){
                $http->auth_username = $private->username;
                $http->auth_password = $private->password;
                
                $httphost = isset($private->{$server}) ? $private->{$server} : ($server?'https://'.$server:$private->server[0]);
                
                $source_http=$httphost;
                if (!strpos( $httphost , '?')) $source_http .= '/xmlq';
            } else
                $source_http = $private->mssqlServer;
            
            //if (developerMode()) $request[0]->ownerDocument->save('data/lastrequest.xml');
            
            if($http->post($source_http,
                $http->make_query_string(array(
                        "request"=>$request[0]->ownerDocument->saveXML(),
                        "login"=>(string)$private->username,
                        "pwd"=>(string)$private->password,
                        "db"=>$db, "server"=>$server))
                )) try {
                    if (developerMode()) file_put_contents('data/last.response.http.xml',$http->response);
                    $doc->loadXML($http->response);
                } catch (Exception $loadError) {
                    throw new ErrorException($http->response); 
            } else throw new ErrorException('http error: '.$http->get_error());
            
        } catch (Exception $e) {
            $doc->loadXML('<exception xmlns="http://unact.net/xml/xi"><![CDATA['.$e->getMessage().']]></exception>');
        }
        
        $doc->documentElement->setAttribute('ts',dateAdd('+ 0 days'));
    
        return $doc;
    };
    
    
    function sqlRequest(
        $request, $storage = 'cat', $server='', $db = '', $expect = 'resultset', $username = false
        ){
        
        $username = isset($_SESSION['username'])?$_SESSION['username']:false;
        $uri = $_SERVER["REQUEST_URI"];
        $qrs = $_SERVER["QUERY_STRING"];
        
        if ($qrs != '') $uri = str_replace ('?'.$qrs, '', $uri);
    
        $doc=new DomDocument();
        $doc -> loadXML('<?xml version="1.0" encoding="utf-8" ?>'."<r show-sql='true'><sql><![CDATA[".$request."]]></sql></r>");
        if ($username) $doc -> documentElement -> setAttribute('username',$username);
        $doc -> documentElement -> setAttribute('expect',$expect);
        $doc -> documentElement -> setAttribute('storage',$storage);
        $doc -> documentElement -> setAttribute('server',$server);
        $doc -> documentElement -> setAttribute('ip',$_SERVER['REMOTE_ADDR']);
        $doc -> documentElement -> setAttribute('path',$uri);
        
        if ($db != '')  $doc -> documentElement -> setAttribute('db',$db);
        
        return xmlRequest(array(0 => $doc->documentElement));
    };
    
    function stringRequest($address, $request, $auth = false) {
    
        $http = new HTTPRetriever();
        
        if ($auth) {
            $http->auth_username = $auth->username;
            $http->auth_password = $auth->password;
        }
    
        $doc=new DOMDocument();
    
        try {
            if($http->post($address, $http->make_query_string(array("request"=>$request)))){
              $doc->loadXML($http->response) ;}
            else $doc->loadXML("<exception xmlns='http://unact.net/xml/xi'>HTTP request error: #{$http->result_code}: {$http->result_text}</exception>");
        }
        catch (Exception $e){
         $doc->loadxml("<exception xmlns='http://unact.net/xml/xi'>{$e->getMessage()}</exception>");
        };
        $doc->documentElement->setAttribute('ts',dateAdd('+ 0 days'));
        $doc->documentElement->setAttribute('xmlns','http://unact.net/xml/xi');
        $doc->loadXML($doc->saveXML());
        return $doc;
    }
    
    function mdxRequest($request, $server = 'bi', $db = 'uw') {
        return stringRequest('https://soa.unact.ru/xmlrawdata/Default.aspx?server='.$server.'&database='.$db, trim($request));    
    };
    
    
    function authenticateSOA($login, $password, &$extraData) {
        $address='https://soa.unact.ru/AuthenticationService/Default.aspx';
        $http = new HTTPRetriever();
        
        try { if ( $http->post(
                $address,
                $http->make_query_string(array(
                    "username" => urlencode($login),
                    "password" => urlencode($password)
                )
            ) ) ) {
                $result = new SimpleXMLElement($http->response);
                $extraData=$result;
                return (string) $result ['validator'];
            }
            else print "HTTP request error: #{$http->result_code}: {$http->result_text}";
        }
        catch (Exception $e){
            print "{$e->getMessage()}";
        };
    
        return false;
    }


    function developerMode() {
        $doc = new DOMDocument;
        $doc -> load('../secure.xml');
        if ($doc -> documentElement -> getAttribute ('environment') == 'developer') return true;
        
        return false;
    }
    
    function authenticateGeneric ($credentials,&$extraData) {
        if (isset($credentials['username'])) return authenticate ($credentials['username'], $credentials['password'], $extraData);
        else return uoauth ($credentials['access_token'], $extraData);
    }

    function uoauth ($access_token, &$extraData) {
        $address = secureParm () -> oauth ['roles-href'];
        $http = new HTTPRetriever();
        
        try { if ( $http->post (
                    $address,
                    $http->make_query_string ( array(
                        "access_token" => $access_token
                    )
            ) ) ) {
                $result = new SimpleXMLElement($http->response);
                $extraData=$result;
                //var_dump($result);
                //die();
                return isset($result -> roles) ? 'uoauth' : false;
            }
            else print "HTTP request error: #{$http->result_code}: {$http->result_text}";
        }
        catch (Exception $e){
            print "{$e->getMessage()}";
        };
    
        return false;
    }
    

    function authenticate($login, $password, &$extraData) {
    
        if (developerMode()) {
            $doc = new DOMDocument;
            $doc->load('config/auth.xml');   
            $xpath = new DOMXPath($doc);
            $xpath -> registerNamespace('xi','http://unact.net/xml/xi');
            $xpathRes = $xpath->query('/*/xi:user[@password and @name="'.$login.'"]');
            if ($xpathRes->length > 0) {
                $userNode= $xpathRes->item(0);
                
                if ($simplepass=$userNode->attributes->getNamedItem('password')->nodeValue)
                    return $password == $simplepass;
            }
        }
        
        return authenticateSOA($login, $password, $extraData);
    }

    function uuidSecure() {
       
        $pr_bits = null;
        $fp = @fopen('/dev/urandom','rb');
        if ($fp !== false) {
            $pr_bits .= @fread($fp, 16);
            @fclose($fp);
        } else {
            // If /dev/urandom isn't available (eg: in non-unix systems), use mt_rand().
            $pr_bits = "";
            for($cnt=0; $cnt < 16; $cnt++){
                $pr_bits .= chr(mt_rand(0, 255));
            }
        }
       
        $time_low = bin2hex(substr($pr_bits,0, 4));
        $time_mid = bin2hex(substr($pr_bits,4, 2));
        $time_hi_and_version = bin2hex(substr($pr_bits,6, 2));
        $clock_seq_hi_and_reserved = bin2hex(substr($pr_bits,8, 2));
        $node = bin2hex(substr($pr_bits,10, 6));
       
        /**
         * Set the four most significant bits (bits 12 through 15) of the
         * time_hi_and_version field to the 4-bit version number from
         * Section 4.1.3.
         * @see http://tools.ietf.org/html/rfc4122#section-4.1.3
         */
        $time_hi_and_version = hexdec($time_hi_and_version);
        $time_hi_and_version = $time_hi_and_version >> 4;
        $time_hi_and_version = $time_hi_and_version | 0x4000;
       
        /**
         * Set the two most significant bits (bits 6 and 7) of the
         * clock_seq_hi_and_reserved to zero and one, respectively.
         */
        $clock_seq_hi_and_reserved = hexdec($clock_seq_hi_and_reserved);
        $clock_seq_hi_and_reserved = $clock_seq_hi_and_reserved >> 2;
        $clock_seq_hi_and_reserved = $clock_seq_hi_and_reserved | 0x8000;
       
        return sprintf('%08s-%04s-%04x-%04x-%012s',
            $time_low, $time_mid, $time_hi_and_version, $clock_seq_hi_and_reserved, $node);
    }
    
    class ExSimpleXMLElement extends SimpleXMLElement {
        
        private function addCData($cdata_text) {
            $node= dom_import_simplexml($this);
            $no = $node->ownerDocument;
            $node->appendChild($no->createCDATASection($cdata_text));
        }
        
        public function addChildCData($name,$cdata_text) {
            $child = $this->addChild($name);
            $child->addCData($cdata_text);
        }
        
        public function appendXML($append) {
            if ($append) {
                if (strlen(trim((string) $append))==0) {
                    $xml = $this->addChild($append->getName());
                    foreach($append->children() as $child) {
                        $xml->appendXML($child);
                    }
                } else {
                    $xml = $this->addChild($append->getName(), (string) $append);
                }
                foreach($append->attributes() as $n => $v) {
                    $xml->addAttribute($n, $v);
                }
            }
        }
    }

    function getFileContents ( $path ) {
        $f = file_get_contents ( $path );
        
        /*$f = str_replace ( "'", "''", $f);
        $enc = mb_detect_encoding ($f, 'auto', true);
        return $enc === false ? mb_convert_encoding ($f, 'UTF-8', 'Windows-1251') : $f;
        */
        
        return base64_encode ($f);
        
    }
    
    function getCounter() {
        return (isset($_SESSION) && isset($_SESSION['id-counter']))?$_SESSION['id-counter']:0;
    }

    function pipeline( $name, $xmldata ) {
        
        $doc = new DOMDocument();
        $doc -> appendChild ($doc -> importNode ($xmldata[0], true));
        
        return $doc;
        
    }
    
    function directoryList( $name, $path = '.' ) {
        
        $path = $path.'/'.$name;
        
        if ( $handle = opendir( $path ) ) {
            
            $doc = new DOMDocument();
            $doc -> appendChild ($root = $doc -> createElementNS ('http://unact.net/xml/xi','directory'));
            $root -> setAttribute('name', $name);
            
            while (false !== ($file = readdir($handle))) {
                
                $filePath = $path.'/'.$file;
                
                if (substr($file, 0, 1) != '.' ) {
                    if (is_file($filePath))
                       $root->appendChild($doc -> createElementNS ('http://unact.net/xml/xi', 'file', $file) );
                    elseif ( is_dir($filePath) ) {
                        if ($subdir = directoryList ($file, $path))
                            $root -> appendChild ($doc -> importNode ($subdir -> documentElement, true));
                    }
                }
                
            }
            closedir($handle);
            
            return $doc;
        }
     
        return false;
    }
    
    function rmdirfiles($dir) {
        foreach(glob($dir . '/*') as $file) {
            if(is_dir($file))
                rrmdir($file);
            else
                unlink($file);
        }
    }
    
    function secureParm ($name = false) {
        
        $private=simplexml_load_file('../secure.xml');
        
        if ($name)
            return $private [0] [$name];
        else
            return $private
        ;
        
    }

    
?>