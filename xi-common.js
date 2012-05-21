var mobileIE=false;
var currentFocus=false;

function getIndex(element){

    for (i=element.form.elements.length-1;i>=0;i--)
        if (element.id == element.form.elements[i].id) return i;

    return -1;

}

function getParent(element) {
    if (mobileIE) return element.parentElement; else return element.parentNode;  
}

function moveFocus (element, dir, vdir) {
    var htmlobj=getParent(element);
    htmlobj=getParent(htmlobj);
    
    if (htmlobj.tagName.toLowerCase() == 'td' && vdir){

       var htmlrow=getParent(htmlobj);
       var htmltable=getParent(htmlrow);
	   
       for (newRow=htmlrow.rowIndex - (htmltable.childNodes[0]).rowIndex + dir; newRow >= 0 && newRow < htmltable.rows.length; newRow+=dir){
         targetCell=htmltable.rows[newRow].cells[htmlobj.cellIndex];
         targetCell=targetCell.childNodes[0];
         if (targetCell && getStyle(targetCell,'display')!='none')
         for (i=0; i<targetCell.childNodes.length; i++) {
             targetNode=targetCell.childNodes[i]; 
             targetTag= new String (targetNode.tagName);
             targetTag=targetTag.toLowerCase()
             
             if (targetTag=='input') { targetNode.focus(); targetNode.select();  return false; }
         }
       }
    }

    for (var next = getIndex(element) + dir; next<element.form.length && next>=0; next+=dir) {
        target = element.form.elements[next];
        targetTag= new String (target.tagName);
        targetTag=targetTag.toLowerCase()
        if (getStyle(getParent(getParent(target)),'display')!='none' && targetTag=='input' && (target.type=='radio' || target.type=='text' || target.type=='password' || target.getAttribute('class').match('focusable'))) {
			currentFocus=target;
            target.focus();
//            target.select();
            return true;
            break;
        }
    }
    
    return false;
}

function viewChange(element){
    location.replace(location.protocol+'//'+location.host+location.pathname+'?'+element.name+'='+element.options[element.selectedIndex].value);
}


function menupad (menuObj, menuId, mode) {
    
    var frm;

    if (menuId) frm=document.getElementById(menuId);
    
    if (frm && menuId){
        command=menuObj.getAttribute('href');
        if (!mode || !command) {
	        if (command) frm.action=command;
            frm.submit();
		}
        else
            xijax(menuObj.getAttribute('href'));
    } else {
        if (!mode) {
            menuObj.blur();
            location.replace(location.protocol+'//'+location.host+location.pathname+menuObj.getAttribute('href'));
        } else
            xijax(menuObj.getAttribute('href'));
    }
    
    return false;
}


function getStyle(oElm, strCssRule){
	var strValue = "";
	if(document.defaultView && document.defaultView.getComputedStyle){
		strValue = document.defaultView.getComputedStyle(oElm, "").getPropertyValue(strCssRule);
	}
	else if(oElm.currentStyle){
		strCssRule = strCssRule.replace(/\-(\w)/g, function (strMatch, p1){
			return p1.toUpperCase();
		});
		strValue = oElm.currentStyle[strCssRule];
	}
	return strValue;
}

