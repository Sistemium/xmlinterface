<?php

    class XSLTWhatMatrix extends XSLTProcessor {
        
        public $instructions;
        public $http;
        public $auth;
        public $resultPath;
        
        public function __construct($xml = false, $xsl = false, $params = array()) {
            
            if ($xsl) try {
                
                $this -> importStylesheet ($xsl);
                
                foreach ($params as $key=>$value)
                    $this->setParameter ('', $key, $value)
                ;
                
                if ($xml) {
                    $result = $this -> transformToDoc ($xml);
                    
                    if (!$result) return false;
                    
                    if ($result -> documentElement -> tagName == 'xsl:stylesheet') {
                        
                        //print $xsl->saveXML();
                        
                        if ( ! $this -> importStylesheet ($xsl)) {
                            print "xsl import error\n";
                            return false;
                        }
                        
                    } else {
                        $this -> instructions = $result;
                    }
                }
                
            } catch (Exception $e) {
                return false;
            }
            
            return $this;
            
        }
        
        public function apply ($instructions, $xml = false) {
            
            $result = false;
            
            if ($xml) foreach ($instructions->print as $print)
                die ($xml->saveXML());
            ;
            
            foreach ($instructions->execute as $task)
            if ( !isset($task['if-xpath'])
                || ($xml && DOMDocTestsXpath($xml,$task['if-xpath']))
            ){
                
                $file = (
                    $task['result-path'] = $this->newUploadFileName($this->resultPath)
                );
                
                if ($xsl = $task['xsl']){
                    
                    $xsl = DOMDocument::load ($xsl);
                    
                    foreach ($task->include as $param) {
                        $newElement = $xsl->createElementNS('http://www.w3.org/1999/XSL/Transform','xsl:include');
                        $newElement -> setAttribute ('href',$task);
                        $xsl -> documentElement -> appendChild($newElement);
                    }
                    
                    $this ->importStylesheet ($xsl);
                    
                    foreach ($task->param as $param) {
                        $this->setParameter ('', $param['name'], $param);
                    }
                    
                    $task ['result'] = ($result = $this->transformToDoc ($xml))
                        ? 'OK'
                        : 'ERROR'
                    ;
                    
                    if ($result)
                        $result->save($file . '.xsl-task' . '.xml')
                    ;
                    
                } elseif ($server = $task['server']) {
                    
                    $vars = '';
                    
                    foreach ($task->param as $param) {
                        
                        $parmname = $param['name'];
                        $parmval = urlencode($param);
                        
                        if (isset ($param['http-var'])) {
                            @$parmval = urlencode($_REQUEST[(string) $param['http-var']]);
                        }
                        
                        $parmval == '' || $vars .= '&' . urlencode($parmname) . '=' . $parmval;
                        
                    }
                    
                    if ( $vars != '' && strpos ($task['service'],'?') === false)
                        $vars = '?' . $vars
                    ;
                    
                    $url = $server . '/' . $task['service'] . $vars;
                    
                    $result = $this -> httpPost (
                        $url,
                        $xml ? $xml->saveXML() : false,
                        array('Authorization'=>$this->auth)
                    );
                    
                    $task['response-size'] = strlen($result);
                    file_put_contents($file . '.server-task' . '.xml', $result);
                    
                    $result = DOMDocument::loadXML($result);
                    
                }
                
                if ($result) {
                    $subResult = $this->apply($task, $result);
                    if ($subResult) $result = $subResult;
                }
                
                if ($task->break) return $result;
                
            }
            
            return $result;
            
        }
        
        private function newUploadFileName ($prefix = '') {
            return $prefix.uniqid('log-');
        }
        
        function httpPost ($urlString, $postData  = array(), $headers = array()) {
            
            $curlRequest = curl_init( $urlString );
            
            curl_setopt($curlRequest, CURLOPT_SSL_VERIFYPEER, false);
            curl_setopt($curlRequest, CURLOPT_SSL_VERIFYHOST, false);
            curl_setopt($curlRequest, CURLOPT_RETURNTRANSFER, true);
            
            $data = '';
            
            if (is_array($postData)) {
                foreach ($postData as $key=>$value)
                    $data .= ($data?'&':'').$key .'='. $value
                ;
                //curl_setopt($curlRequest, CURLOPT_POST, true);
            } elseif (is_string($postData)) {
                $headers ['Content-Type'] = 'text/xml';
                $data = $postData;
            }
            
            if (count($headers)){
                $headersToSend = array();
                foreach ($headers as $key=>$value)
                    array_push ($headersToSend, $key.': '.$value)
                ;
                curl_setopt($curlRequest, CURLOPT_HTTPHEADER, $headersToSend);
            }
            
            if ($data!='') {
                curl_setopt($curlRequest, CURLOPT_POSTFIELDS, $data);
            }
            
            $ret = curl_exec($curlRequest);
            
            $httpStatus = curl_getinfo($curlRequest, CURLINFO_HTTP_CODE);
            
            if ($httpStatus != 200) {
                header ('System-error: '.$urlString, 1 ,$httpStatus);
                die($ret."\n");
            }
            
            curl_close($curlRequest);
            
            return $ret;
            
        }
    }
    
    function DOMDocTestsXpath ($xml, $xpath) {
        
        $result = DOMXPath ($xml) -> evaluate($xpath);
        
        return $result;
        
    }

?>