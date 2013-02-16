
var popup;
function popupwindow(file,key,widt,heit) {

	if (popup == null || popup.closed) {

		popup = window.open(file,key,'status=yes,scrollbars=yes,resizable=yes,width=' + widt + ',height=' + heit);
		popup.focus();

	} else {

		popup.focus();

	}

}

function hrow(row, buttons, listname) {
	if (document.getElementById("c" + row).checked == true) {
		$("#r" + row).addClass('highlistrow');
	} else {
		$("#r" + row).removeClass('highlistrow');
	}

	togglebtns(buttons, listname);
}

function togglebtns(buttons, listname) {

	if (buttons == 1) {
		ticked(listname + "item", listname + "delete");
	} else if (buttons == 2) {
		ticked(listname + "item", listname + "copy");
		ticked(listname + "item", listname + "delete");
	} else if (buttons == 3) {
		ticked(listname + "item", listname + "copy");
		ticked(listname + "item", listname + "delete");
		ticked(listname + "item", listname + "publish");
	}

}

function checkall(field, checkvalue) {

	var checkboxes = document.getElementsByName(field);
	if(!checkboxes) {
		return;
	}
	var checkboxcount = checkboxes.length;
	if(!checkboxcount) {
		checkboxes.checked = checkvalue;
	} else {
		// set the check value for all check boxes
		for(var i = 0; i < checkboxcount; i++) {
			checkboxes[i].checked = checkvalue;
			checkboxes[i].onclick();
		}
	}
}

function ticked(name, button) {
	var checkflag = "false";

	var field = document.getElementsByName(name);
	for (i = 0; i < field.length; i++) {
		if (field[i].checked == true) {
			checkflag = "true";
		}
	}

	if (checkflag == "true") {
		document.getElementById(button).disabled = false;
	} else {
		document.getElementById(button).disabled = true;
	}

}


// Two jQuery plugins from http://blog.alexmaccaw.com/svbtle-image-uploading
(function($){
  function dragEnter(e) {
    $(e.target).addClass("dragOver");
    e.stopPropagation();
    e.preventDefault();
    return false;
  };
 
  function dragOver(e) {
    e.originalEvent.dataTransfer.dropEffect = "copy";
    e.stopPropagation();
    e.preventDefault();
    return false;
  };
 
  function dragLeave(e) {
    $(e.target).removeClass("dragOver");
    e.stopPropagation();
    e.preventDefault();
    return false;
  };
 
  $.fn.dropArea = function(){
    this.bind("dragenter", dragEnter).
         bind("dragover",  dragOver).
         bind("dragleave", dragLeave);
    return this;
  };
})(jQuery);

(function($){
  var insertAtCaret = function(value) {
    if (document.selection) { // IE
      this.focus();
      sel = document.selection.createRange();
      sel.text = value;
      this.focus();
    }
    else if (this.selectionStart || this.selectionStart == '0') {
      var startPos  = this.selectionStart;
      var endPos    = this.selectionEnd;
      var scrollTop = this.scrollTop;
 
      this.value = [
        this.value.substring(0, startPos),
        value,
        this.value.substring(endPos, this.value.length)
      ].join('');
 
      this.focus();
      this.selectionStart = startPos + value.length;
      this.selectionEnd   = startPos + value.length;
      this.scrollTop      = scrollTop;
 
    } else {
      throw new Error('insertAtCaret not supported');
    }
  };
 
  $.fn.insertAtCaret = function(value){
    $(this).each(function(){
      insertAtCaret.call(this, value);
    })
  };
})(jQuery);



