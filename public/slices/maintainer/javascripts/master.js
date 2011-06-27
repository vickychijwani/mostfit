$(function() {
    setup_ajax_fetch_handlers();
    setup_confirmation_handlers();
    //setup_form_submit_handlers();
    check_if_deployment_possible();

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
    ajax_call({
	url: '/maintain/deployment/check_if_deployment_possible',
	handler: function(data) {
            if(data.response == "true")
		notify_bottom({text : "Deployed code in current branch is out of date with the server."});
            else if(data.response == "false")
		notify_bottom({text : "Deployed code in current branch is up-to-date."});
	}
    });
}

function setup_form_submit_handlers() {
    $("input.form-submit").live('click',function(e) {
	ajax_call({
	    url: $(this).closest("form").attr('action'),
	    data: $(this).closest("form").serialize(),
	    handler: handle,
	    extra: {
		url: "/maintain/tasks"
	    }
	});
	e.preventDefault();
	return false;
    });
}

function setup_confirmation_handlers() {
    $("a.confirm").live('click',function(e) {
	var r = confirm($(this).attr('message') || "Are you sure?");
	var that = this;
	if(r) {
	    show_overlay();
	    data = {url : $(that).attr('reload_url'), success_text : $(that).attr('success') || "Success.", icon : $(that).attr('icon') || ""};
	    if($(that).attr('callback')) data.callback = $(that).attr('callback');
	    ajax_call({
		url: $(that).attr('url'),
		handler: handle,
		data: data
	    });
	}
	e.preventDefault();
	return false;
    });
}

function setup_ajax_fetch_handlers() {
    $(".ajax-fetch").live('click',function(e) {
	show_loader();
	ajax_call({
	    url: $(this).attr('url'),
	    handler: render
	});
	e.preventDefault();
	return false;
    });
}

/* various event handlers to handle an ajax response sent by ajax_fetch */
function handle(data) {
    hide_overlay();
    if(data.response == "true") {
	(data.arg.success_text) ? $.notify_osd.new({text: data.arg.success_text || "Done.", icon: data.arg.icon || ""}) : $.notify_osd.dismiss();
	if(data.arg.callback)
	    eval(data.arg.callback);
	if(data.arg.url)
	    ajax_call({
		url: data.arg.url,
		handler: render
	    });
    }
    else {
	$.notify_osd.new({text: "An error occurred."});
    }
}
function render(data) {
    $(".tab:visible").html(data.response);
}

/* general function to make an ajax call to 'url', the response to which will be handled by 'handler' ('extra' represents additional information 'handler' may need) */
function ajax_call(params) {
    if(params.handler == render)
	show_loader();
    $.ajax({
	url : params.url,
	data : (params.data) ? (params.data) : (""),
	success : function(response) {
	    (params.extra) ? params.handler({response:response, arg:params.extra}) : params.handler({response:response});
	},
	error : function() {
	    hide_overlay();
	    $.notify_osd.new({text: "An error occurred."});
	}
    });
}

/* display an ajax loader in the currently active tab */
function show_loader() {
    $(".tab:visible").html("<div class='loader'><img src='slices/maintainer/images/progress-dots.gif' /></div>");
}

function notify_bottom(notification) {
    $("#bottom-message-inside span").html(notification.text);
    $("#bottom-message-drawer").show();
}

/* overlay functions */
function show_overlay() {
    $("#overlay").css({'z-index':'890'}).show();
}

function hide_overlay() {
    $("#overlay").css({'z-index':'-1'}).hide();
}