class Maintainer::Tasks < Maintainer::Application

  before :initialize_crontab, :only => [:create,:edit,:update,:delete]

  def index
    render :layout => false
  end

  def new
    render :layout => false
  end

  def create
    schedule = create_schedule(params)

    cron_log = File.join(Merb.root,"slices/maintainer/log/cron.log") + " 2>&1"
    task = params['task']
    schedule[:command] = "/bin/bash -l -c 'cd #{Merb.root}; #{task} >> #{cron_log}'"

    index = (@crontab.list_maintainer.length > 0) ? (@crontab.list_maintainer.keys.sort.last[/\d+/].to_i + 1) : 1
    @crontab.add("maintainer_#{index}", schedule)
    @crontab.commit

    log({
      :action => 'created_task',
      :ip     => request.remote_ip,
      :name   => params["task"]
    })

    redirect("/maintain#tasks")
  end

  def edit
    @task_name = params[:task]
    @task = @crontab.list_maintainer[@task_name].to_cron_entry
    render :layout => false
  end

  def update
    schedule = create_schedule(params)
    schedule[:command] = params["task_command"]
    @crontab.add(params["task_name"], schedule)
    @crontab.commit
    log({
      :action => 'edited_task',
      :ip     => request.remote_ip,
      :name   => @crontab.list_maintainer[params["task_name"]].to_cron_entry[:rake_task]
    })
    redirect("/maintain#tasks")
  end

  def delete
    task = @crontab.list_maintainer[params[:task]].to_cron_entry[:rake_task]
    @crontab.remove(params[:task])
    @crontab.commit
    log({
      :action => 'deleted_task',
      :ip     => request.remote_ip,
      :name   => task
    })
    redirect("/maintain#tasks")
  end

  private
  def initialize_crontab
    @crontab = CronEdit::Crontab.new(`echo $USER`.chomp)
  end

  def create_schedule(params)
    schedule = {
      :minute => (params["minutes-selected"] == "0") ?  "*" : params["minute"].join(","),
      :hour => (params["hours-selected"] == "0") ?  "*" : params["hour"].join(","),
      :day => (params["days-selected"] == "0") ?  "*" : params["day"].join(","),
      :month => (params["months-selected"] == "0") ?  "*" : params["month"].join(","),
      :weekday => (params["weekdays-selected"] == "0") ?  "*" : params["weekday"].join(",")
    }
  end

end
