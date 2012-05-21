var currentFocus=false;
mobileIE=true;


function doScan(scanData, scanType, scanEtc, scanTime, scanLen){
    if (currentFocus)
        if (currentFocus.type=='text') {
            currentFocus.value=scanData;
            onAllKeys(13);
        }
}

function checkConnection (SignalStrength) {
    alert(SignalStrength);
}


function getStyle(oElm, strCssRule) { 
    return '';
}


function initialize(targetFocus){
    if (targetFocus) setfocus(targetFocus);    
}


function onFocus(elem) {
    if ((elem.type=='text' || elem.type=='password') && (1==1 || elem.id!=currentFocus.id)) elem.select();
    currentFocus=elem;
}


function onAllKeys(keyCode) {
    if (keyCode==13 && currentFocus && (currentFocus.type=='text' || currentFocus.type=='password' ) ) {
        if (currentFocus.getAttribute('class').match('option-forward') || !moveFocus(currentFocus, 1, 0)) currentFocus.form.submit();
    }
    else if (keyCode==112) moveFocus(currentFocus, -1, 0)
    else if (keyCode==113) moveFocus(currentFocus, 1, 0)
    else if (currentFocus && currentFocus.getAttribute('class').match('int')) {
        var increment;
        if (keyCode==125) increment = 1
        else if (keyCode==126) increment = -1;
        
        if (increment) {
            currentFocus.value=currentFocus.value==''?0:v=parseInt(currentFocus.value)+increment;
        }
    } 
    else setfocus();
}


function setfocus(elementId) {
    obj=elementId?document.getElementById(elementId):currentFocus;
    if (obj) obj.focus();
}


function autofill(elementId, newValue) {
    obj=document.getElementById(elementId);
    
    if (obj) {
        obj.value=newValue;
        setfocus(obj.id);
    } else alert ('no elementID')

}
