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
    $.notify_osd.setup({
	click_through : false,
	sticky : true,
	dismissable : true
    });
});

/* check if deployment is possible */
function check_if_deployment_possible() {
    ajax_fetch('/maintain/deployment/check_if_deployment_possible',function(data) {
        if(data.response == "true")
            notify_bottom({text : "Deployed code in current branch is out of date with the server."});
        else if(data.response == "false")
            notify_bottom({text : "Deployed code in current branch is up-to-date."});
    });
}

function setup_confirmation_handlers() {
    $("a.confirm").click(function(e) {
	var r = confirm($(this).attr('message') || "Are you sure?");
	var that = this;
	if(r) {
	    show_overlay();
	    data = {url : $(that).attr('reload_url'), success_text : $(that).attr('success') || "Success.", icon : $(that).attr('icon') || ""};
	    if($(that).attr('callback')) data.callback = $(that).attr('callback');
	    ajax_fetch($(that).attr('url'),handle,data);
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
	show_overlay();
	$.notify_osd.new({text: "Saving snapshot...", icon:"slices/maintainer/images/database.png", sticky: true, dismissable: false});
	ajax_fetch('/maintain/database/take_snapshot',handle,{url : '/maintain/database', success_text : 'Snapshot saved.', icon : 'slices/maintainer/images/database.png', callback : 'hide_overlay()'});
	e.preventDefault();
	return false;
    });
}

/* various event handlers called by ajax_fetch */
function handle(data) {
    hide_overlay();
    if(data.response == "true") {
	(data.arg.success_text) ? $.notify_osd.new({text: data.arg.success_text || "Done.", icon: data.arg.icon || ""}) : $.notify_osd.dismiss();
	if(data.arg.callback) eval(data.arg.callback);
	ajax_fetch(data.arg.url,render);
    }
    else {
	$.notify_osd.new({text: "An error occurred."});
    }
}
function render(data) {
    $(".tab:visible").html(data.response);
}

/* ajax fetch, display loader, display response */
function ajax_fetch(url,handler,extra) {
    if(handler == render)
	show_loader();
    $.ajax({
	url : url,
	success : function(response) {
	    (extra) ? handler({response:response, arg:extra}) : handler({response:response});
	},
	error : function() {
	    $.notify_osd.new({text: "An error occurred."});
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
    if($("#message-drawer:visible").length > 0)
	dismiss_notification();

    $("#message-inside span").html(notification.text);
    $("#message-drawer").show();

    if(notification.dismissable == false)
	show_overlay();
    else
	make_dismissable();
}

function notify_bottom(notification) {
    $("#bottom-message-inside span").html(notification.text);
    $("#bottom-message-drawer").show();
}

function make_dismissable() {
    if($("#message-inside a.dismiss").length == 0)
	$("<a class='dismiss' href='#' onclick='dismiss_notification()'>x</a>").appendTo("#message-inside");
}

/* overlay functions */
function show_overlay() {
    $("#overlay").css({'z-index':'890'}).show();
}

function hide_overlay() {
    $("#overlay").css({'z-index':'-1'}).hide();
}