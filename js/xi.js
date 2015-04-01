var chatInit=false;

function isiPhone(){
    return (
        (navigator.platform.indexOf("iPhone") != -1) ||
        (navigator.platform.indexOf("iPod") != -1)
    );
}

function domready () {

//    isiPhone() ||
        $('input.date').prop('readonly', true)
    ;

    $('input.date').datepicker({
            showOn: 'button',
            buttonImage: 'images/calendar.gif',
            showAnim: '',
            onSelect: function(dateText, inst) {
                $(this).trigger('change');
                if (this.getAttribute('xi:option')) {
                    $(this).parents('.view').mask('Загрузка ...');
                    this.form.submit();
                }
            }
    });

    $('div.tabs').each(function(tabNumber, tab) {
        var viewId = $(tab).parents('.view').first().attr('id')
            , uiId = $(tab).attr('id')
            , selected = sessionStorage.getItem(viewId+'.'+uiId)
            tabToSelect = (selected ? selected : 0)
        ;
        $(tab).tabs({
            select: function(event, ui) {
                var viewId = $(ui.panel).parents('.view').first().attr('id')
                    , uiId = $(ui.panel).parent().attr('id')
                ;
                sessionStorage.setItem(viewId+'.'+uiId, ui.index);
            },
            selected: tabToSelect
        });
    });

    $('div.tabs .ui-tabs-nav').removeClass('ui-corner-all');
    $('div.tabs .ui-tabs-nav').addClass('ui-corner-top');

    $('.collapsable').addClass('collapsed');

    $('.collapsable > .label').click(function() {
        $(this).nextAll().toggle();
        $(this).parent().toggleClass('expanded');
        $(this).parent().toggleClass('collapsed');
    });

    $('.accordeon tr.group .cnt').addClass('x-button collapsed');

    $('.accordeon tr.group .cnt').click(function() {
        $(this).toggleClass('expanded');
        $(this).toggleClass('collapsed');
        $(this).parents('tr.group').first().nextUntil('tr.group','tr.data').toggle();
    });

    $('body').delegate('.boolean input, input.radio, a.button','click',
        function(e) {$(e.target).parents('.view').mask('Загрузка ...');}
    );

    $('body').delegate('input.text','keydown',
        function(e) {return keypress(e.target,e)}
    );

    $('body').delegate('input.text','blur',
        function(e) {return onBlur(e.target)}
    );

    $('body').delegate('input.text','click',
        function(e) {return onClick(e.target)}
    );

    $('div.view').delegate('input.text, input.file, textarea','change',
        function(e) {return itemChanged(e.target)}
    );

    $('tfoot .tools').hide();

    var showTools = function(evt){
        if (evt.ctrlKey)
            $(this).find('.tools').show();
    };

    $('tfoot').mouseenter(showTools);
    $('thead').mouseenter(showTools);

    $('div.grid').mouseleave(function() {
       $(this).find('.tools').hide();
    });


//    setTimeout (loadClientData, 100);
}


function xijax (url, data){
    if (!url) url='?';
    else url+='&';

    var postUrl=url+'pipeline=xijax';

    AjaxRequest.post(
      {
        'url':postUrl
        ,'queryString': data
        ,'onSuccess': xijaxSuccess
        ,'onError':function(req){ return false; //alert('Error!\nStatusText='+req.statusText+'\nContents='+req.responseText);
        }
      }
    );
}

function xijaxSuccess (req){
    var nl = req.responseXML.documentElement.childNodes;

//    if (nl.length==0) location.replace(location.protocol+'//'+location.host+location.pathname);
    $('.view.masked').unmask();

    for( var i = 0; i < nl.length; i++ )
    {
        var nli = nl.item( i );
        var elementId = nli.getAttribute ( 'id' );
        var obj = document.getElementById(elementId);

        if (obj) {
            $(obj).removeAttr('disabled');
            $(obj).removeClass('xiSent');

            if (obj.form) if (!$(obj.form.elements).hasClass('xiSent')) $(obj.form).removeClass('xiSent');

            switch (nli.tagName){
                case 'datum':
                    var newValue=nli.getAttribute('formatted');
                    if (!newValue) {
                        if (nli.childNodes.length) newValue=nli.childNodes[0].nodeValue
                        else newValue=''
                    }

                    if (nli.getAttribute('xpath-compute'))
                        $(obj).text(newValue);
                    else {
                        $(obj).attr('value',newValue);
                        $(obj).attr('xi:oldvalue',newValue);
                    }
                case 'data':
                    if ($(nli).children('data').length) fullReload();
                    if (nli.getAttribute ('modified')) $(obj).addClass('modified')
                    else $(obj).removeClass('modified');
                    $(obj).removeAttr('name');
                    break;
                case 'option':
                    var adv = nli.getAttribute ('advisor');
                    $(obj.parentNode).addClass(adv);
                    switch (adv) {
                        case 'recommended':
                             $(obj.parentNode).removeClass('avoid');
                             break;
                        case 'avoid':
                             $(obj.parentNode).removeClass('recommended');
                             break;
                    }
            }

        } else if (nli.tagName=='deleted' || nli.tagName=='inserted') fullReload();
    }

}

function fullReload() {
    location.replace(location.protocol+'//'+location.host+location.pathname);
}

function showMap() {

    if ($('#geomap').hasClass('hidden')) {
        $('#geomap').addClass('shown');
        $('#geomap').removeClass('hidden');
    } else if ($('#geomap').hasClass('shown')) {
        $('#geomap').addClass('hidden');
        $('#geomap').removeClass('shown');
    } else {
        YMaps.load(yMapInit);
        $('#geomap').addClass('shown');
    };

    return false;
}

function yMapInit () {
    var lat=37.64;
    var lng=55.76;
    // Создание экземпляра карты и его привязка к созданному контейнеру
    map = new YMaps.Map(YMaps.jQuery("#geomap")[0]);

    // Установка для карты ее центра и масштаба
    //  map.setCenter(new YMaps.GeoPoint(lat, lng), 15);
}


function initialize(targetFocus, geolocate){
    if (targetFocus) setfocus(targetFocus);

    if (geolocate) setTimeout(geoloc,5000);
}



function itemChanged (element) {

    if (element.type == 'file') {
        //alert(element.value);
        var fname = document.getElementById ($(element).attr('xi:file-name'));

        if (fname) {
                fname.value = element.value.length ? element.value.split(/(\\|\/)/g).pop() : 'file.txt';
                $(fname).attr('name',$(fname).attr('id'));
        }

        $(element).attr('name',$(element).attr('id'));
        element.form.enctype='multipart/form-data';
        element.form.submit();
    } else if (!element.name ) {

        var href=element.id+'='+element.value;

        $(element.form).addClass('xiSent');

        $(element).attr('name',$(element).attr('id'));
        $(element).addClass('xiSent');

        $(element).parents('.view').mask('Загрузка');

        xijax(undefined, href);

    }

}

function selectChanged(element){
    var href='';

    href=element.id+'='+element.options[element.selectedIndex].value;

    $(element).attr('name',$(element).attr('id'));
    $(element).addClass('xiSent');

//    element.disabled='disabled';

    xijax(undefined, href);

}

function listAttributes (element) {
    for (var i = 0, l = element.attributes.length; i < l; i++) {
        alert('name=' + element.attributes[i].name);
    }
}

function TurnAutocompleteOff(){

    $('input.text').attr('autocomplete','off');

}

function setfocus(elementId){
//  TurnAutocompleteOff();
    var obj=document.getElementById(elementId);
    if (obj){
        obj.focus();
        if (obj.type=='text') obj.select();
    }
}

function pingSnaps (){
    var ImageObject = new Image();
    ImageObject.src= "https://snapabug.appspot.com/snapabug.js/img/logo/snapabug_tagline.png";

    if(ImageObject.height>0){
    return true ;
    }
    return false;
}

function autofill(elementId, newValue) {
    var obj=document.getElementById(elementId);

    if (obj) {
        if (!newValue) newValue=obj.getAttribute('xi:autofill');
        if (newValue != obj.value) {
            obj.value=newValue;
            obj.setAttribute('xi:oldvalue', newValue);
            $(obj).trigger('change');
        }
    }

}


function keypress(element, event) {

//      alert(event.keyCode);

  var dir = 0;
  var vdir = 0;
  var option = element.getAttribute('xi:option');
  var autofill = element.getAttribute('xi:autofill');
  var beingEdited =  false;
  var oldvalue=element.getAttribute('xi:oldvalue');

  if (element.getAttribute('xi:editinprogress')=='true') beingEdited=true;

  switch (event.keyCode){
    case 38:
      vdir = -1;
      break;
    case 37:
      dir = -1;
      break;
    case 40:
      vdir = 1;
      break;
    case 13:
      if (event.ctrlKey) return toggleEdit(element)
      else if (event.shiftKey && autofill && autofill!=element.value) {
            element.value=autofill;
            $(element).trigger('change');
      } else if (option) {
//        element.form.action += option;
        if (!element.name) element.name=element.id;
        $(element).parents('.view').mask('Загрузка ...')
        element.form.submit();
        return false;
      } else {
        element.blur();
//        itemChanged(element);
      }
      if (beingEdited) toggleEditOff(element);
      beingEdited=false;
    case 39:
      dir =  1;
      break;
    case 27:
      if (beingEdited) {
        element.blur();
        element.value=oldvalue;
        element.select();
        return toggleEditOff(element);
      }
    default:
      if (!beingEdited && element.value!=element.getAttribute('xi:oldvalue')){
        element.setAttribute('xi:editinprogress', 'true');
      }
        return true;

  };

  if (vdir) {
    dir = vdir;
    if (beingEdited) {
      toggleEditOff(element);
      beingEdited=false;
    }
  }

  if (beingEdited) return true;

  if (dir) moveFocus (element, dir, vdir);

  return false;

}

function onselectstart(element){
   return element.nodeName!='INPUT';
}

function onClick(element,event){
//    if (!element.getAttribute('xi:editinprogress')=='true') element.select();
    if(!element.getAttribute('xi:editinprogress') || element.getAttribute('xi:editinprogress')=='false')
        setTimeout(function() {
            try {
                element.select();
            } catch (e) {
            }
        }, 0);
    element.setAttribute('xi:editinprogress', 'true');
    return true;
}

function restoreValue(element){
    element.value=element.getAttribute('xi:oldvalue');
}

function toggleEditOff(element){
    element.setAttribute('xi:editinprogress', 'false');
    element.setAttribute('xi:oldvalue',element.value);
    return true;
}

function toggleEdit(element){

    var oldValue=element.value;

    element.setAttribute('xi:editinprogress', 'true');

    if (oldValue){
        element.value='';
        element.value=oldValue;
    };

    return false;

}


function onFocus(element){
//    element.select();
    return true;
}


function keepFocus(element){
    var cnt=0;
    for (i=element.form.elements.length-1;i>=0;i--)
    if (element.form.elements[i].type=='text') cnt++;

    if (cnt==1) setfocus(element.id);
}

function onBlur(element){
    toggleEditOff(element);
//    keepFocus(element);
}


function geoloc() {
    navigator.geolocation.watchPosition(foundLocation, noLocation, {enableHighAccuracy:true,timeout:20000,maximumAge:0});
//    navigator.geolocation.getCurrentPosition(foundLocation, noLocation, {enableHighAccuracy:true,timeout:60000,maximumAge:30000});

}

function roundNumber(rnum, rlength) { // Arguments: number to round, number of decimal places
  return newnumber = Math.round(rnum*Math.pow(10,rlength))/Math.pow(10,rlength);
}

function nowTime() {
    var now = new Date();
    var hh=now.getHours();
    hh=hh>=10?hh:'0'+hh;
    var mm=now.getMinutes();
    mm=mm>=10?mm:'0'+mm;
    var ss=now.getSeconds();
    ss=ss>=10?ss:'0'+ss;

    return hh+':'+mm+':'+ss;
}

function setMap(lat,lng) {
    if(!map) return;
    map.setCenter(new YMaps.GeoPoint(lng, lat), 15);
    map.openBalloon(new YMaps.GeoPoint(lng, lat), "Тут");
}


function foundLocation(position) {
    var lat = roundNumber(position.coords.latitude,9);
    var lng = roundNumber(position.coords.longitude,9);

    var longSpan = document.getElementById('longitude');
    var latSpan = document.getElementById('latitude');
    var accSpan = document.getElementById('geoacc');
    var tsSpan = document.getElementById('geots');

    latSpan.innerText=roundNumber(lat,6);
    longSpan.innerText=roundNumber(lng,6);
    accSpan.innerText=Math.round(position.coords.accuracy);


    tsSpan.innerText=nowTime();

    setMap(lat,lng);
//    setTimeout(geoloc,10000);

//  alert('Found location: ' + lat + ', ' + long);
    var postUrl='?pipeline=geomonitor&long='+lng+'&lat='+lat+'&acc'+position.coords.accuracy;
//    alert (postUrl);
/*    AjaxRequest.get(
    {
        'url':postUrl
        ,'onSuccess':function(req) { setTimeout(geoloc,30000); }
        ,'onError':function(req){ alert('Error!\nStatusText='+req.statusText+'\nContents='+req.responseText); }
    }
    );
  */
}

function noLocation() {
    var accSpan=document.getElementById('geoacc');
    accSpan.innerText='!';
//  alert('Could not find location');
//  setTimeout(geoloc,30000);
}



    function init() {
        // quit if this function has already been called
        if (arguments.callee.done) return;

        // flag this function so we don't do the same thing twice
        arguments.callee.done = true;

        // kill the timer
        if (_timer) {
            clearInterval(_timer);
            _timer = null;
        }

        // create the "page loaded" message
        var text = document.createTextNode("Page loaded!");
        var message = document.getElementById("canvas");
        message.appendChild(text);

//        initChat(username);

    }



    function initChat () {
        return SnapABug.startLink();
    }


    function BlockMove(event) {
        event.preventDefault();
    }
