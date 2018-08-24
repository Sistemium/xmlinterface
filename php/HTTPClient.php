<?php

    class HTTPClient {

        static function post ($url, $data  = array(), $headers = array()) {

            $curlRequest = curl_init( $url );

            curl_setopt($curlRequest, CURLOPT_SSL_VERIFYPEER, false);
            curl_setopt($curlRequest, CURLOPT_SSL_VERIFYHOST, false);
            curl_setopt($curlRequest, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($curlRequest, CURLOPT_TIMEOUT, 160);

            $dataToPost = '';

            if (is_array($data)) {
                foreach ($data as $key=>$value)
                    $dataToPost .= ($dataToPost?'&':'').$key .'='. $value
                ;
            } elseif (is_string($data)) {
                $headers ['Content-Type'] = 'text/xml';
                $dataToPost = $data;
            }

            if (count($headers)){
                $headersToSend = array();
                foreach ($headers as $key=>$value)
                    array_push ($headersToSend, $key.': '.$value)
                ;
                curl_setopt($curlRequest, CURLOPT_HTTPHEADER, $headersToSend);
            }

            if ($dataToPost!='') {
                curl_setopt($curlRequest, CURLOPT_POSTFIELDS, $dataToPost);
            }

            $result = curl_exec($curlRequest);

            $httpStatus = curl_getinfo($curlRequest, CURLINFO_HTTP_CODE);

            curl_close($curlRequest);

            if ($httpStatus != 200) {
                throw new ErrorException ($result, $httpStatus);
            }

            return $result;

        }

    }
?>
