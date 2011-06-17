$(function() {
    setup_snapshot_form_handler();
    setup_ajax_fetch_handler();

    $.fn.extend({
	disable : function() { $(this).attr('disabled','disabled'); },
	enable : function() { $(this).removeAttr('disabled'); },
	check : function() { $(this).attr('checked', 'checked'); },
	uncheck : function() { $(this).removeAttr('checked'); },
	select : function() { $(this).attr('selected', 'selected'); }
    });
});

function setup_confirmation_handlers() {
    $("a.confirm").click(function(e) {
	var r = confirm($(this).attr('message') || "Are you sure?");
	var that = this;
	if(r) {
	    ajax_fetch($(that).attr('url'),handle_notify_and_reload,{url : '/maintain/deployment', success_text : "Rollback successful."});
	}
	e.preventDefault();
	return false;
    });
}

function preselect_task_schedule() {
    var components = ["minute", "hour", "day", "month", "weekday"];
    var i = 0;
    for(i=0; i<5; i++) {
	component_value = $("#task-data input.component[name="+components[i]+"_data]").val();
	if(component_value != "*") {
	    var el = $("#"+components[i]+"s");
	    el.find("input[type=radio]:first").uncheck();
	    el.find("input.select-enabler").check();
	    setup_select_enabler(el);
	    
	    values = component_value.split(",");
	    el.find("option").each(function() {
		if($.inArray($(this).val(), values) != -1)
		    $(this).select();
	    });
	}
    }
}

function setup_select_enabler(el) {
    if(el.children(".select-enabler:checked").length == 0)
	el.children("select").disable();
    else
	el.children("select").enable();
}

function setup_ajax_fetch_handler() {
    $(".ajax-fetch").live('click',function(e) {
	show_loader();
	ajax_fetch($(this).attr('url'),render);
	e.preventDefault();
	return false;
    });
}

function setup_snapshot_form_handler() {
    $("#take-snapshot form input").live('click',function(e) {
	notify({text: "Saving snapshot...", dismissable: false});
	ajax_fetch('/maintain/database/take_snapshot',handle_notify_and_reload,{url : '/maintain/database', success_text : 'Snapshot saved.'});
	e.preventDefault();
	return false;
    });
}

/* various event handlers called by ajax_fetch */
function handle_notify_and_reload(data) {
    if(data.response == "true") {
	notify({text: data.arg.success_text || "Done."});
	ajax_fetch(data.arg.url,render);
    }
    else {
	notify({text: "An error occurred."});
    }
}

function handle_and_reload(data) {
    if(data.response == "true") {
	dismiss_notification();
	ajax_fetch(data.arg.url,render);
    }
    else if(data.response == "false") {
	notify({text: "An error occurred."});
    }
}
function render(data) {
    $(".tab:visible").html(data.response);
}

/* ajax fetch, display loader, display response */
function ajax_fetch(url,handler,extra) {
    $.ajax({
	url : url,
	success : function(response) {
	    (extra) ? handler({response:response, arg:extra}) : handler({response:response});
	},
	error : function() {
	    notify({text: "An error occurred."});
	}
    });
}

function show_loader() {
    $(".tab:visible").html("<div class='loader'><img src='slices/maintainer/images/progress-dots.gif' /></div>");
}

/* notification functions */
function dismiss_notification() {
    $("#message-inside span").html("");
    $("#message-drawer").hide();
    hide_overlay();
    $("#message-inside .dismiss").remove();
    return false;
}

function notify(notification) {
    if($("#message-drawer:visible").length > 0) {
	dismiss_notification();
    }
    $("#message-inside span").html(notification.text);
    $("#message-drawer").show();
    if(notification.dismissable == false)
	show_overlay();
    else
	make_dismissable();
}

function make_dismissable() {
    if($("#message-inside a.dismiss").length == 0)
	$("#message-inside").append("<a class='dismiss' href='"+window.location.hash+"' onclick='dismiss_notification()'>x</a>");
}

/* overlay functions */
function show_overlay() {
    $("#overlay").css({'z-index':'998'}).show();
}

function hide_overlay() {
    $("#overlay").css({'z-index':'-1'}).hide();
}