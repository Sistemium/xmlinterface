<?php

    if (!function_exists('apache_request_headers')) {
        function apache_request_headers() {

           $headers = '';

           foreach ($_SERVER as $name => $value) {
               if (substr($name, 0, 5) == 'HTTP_') {
                   $headers[str_replace(' ', '-', ucwords(strtolower(str_replace('_', ' ', substr($name, 5)))))] = $value;
               }
           }

           return $headers;
        }
    }

?>