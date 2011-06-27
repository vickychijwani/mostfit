$(function() {
    $("#time-section table input[type=radio]").change(function() { setup_select_enabler($(this).parent()) });

    (function preselect_task_schedule() {
	var components = ["minute", "hour", "day", "month", "weekday"];
	var i = 0;
	for(i=0; i<5; i++) {
            component_value = $("#task-data input.component[name="+components[i]+"_data]").val();
            if(component_value && component_value != "*") {
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
    })();

    function setup_select_enabler(el) {
	if(el.children(".select-enabler:checked").length == 0)
            el.children("select").disable();
	else
            el.children("select").enable();
    }
});