<?php

    require_once ('HTTPClient.php');
    
    class UOAuthClient {
        
        private $token;
        private $server;
        
        private $roles;
        
        public function __construct($server, $token) {
            
            $this->server = $server;
            $this->token = $token;
            //@$this->roles = $_SESSION['UAC-roles'];
            
            if (!$this->roles) {
                $_SESSION['UAC-roles'] = $this->getRoles();
            }
            
            return $this;
        }
        
        public function hasRole ($code) {
            if (isset($this->roles[$code]))
                return $this->roles[$code];
        }
        
        private function getRoles () {
            
            $result = HTTPClient::post($this->server.'/roles', array("access_token" => $this->token));
            
            try {
                
                $roles = array();
                $rolesXML = new SimpleXMLElement ($result);
                
                if ($rolesXML->roles) foreach ( $rolesXML->roles->role as $role) {
                    $roles [(string) $role->code] = $role->data ? (string) $role->data : null;
                }
                
                $this->roles = $roles;
                
                return $roles;
                
            } catch (Exception $e) {
                return;
            }
            
        }
        
        
    }

?>