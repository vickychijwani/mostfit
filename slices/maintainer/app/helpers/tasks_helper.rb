module Merb::Maintainer::TasksHelper

  require 'slices/maintainer/lib/utils'
  MONTHS = %w(January February March April May June July August September October November December)
  WEEKDAYS = %w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)
  RAKE_TASKS_FILE = File.join(Merb.root,"slices/maintainer/data/mostfit_rake_tasks")

  def get_mostfit_rake_tasks
    rake_tasks = {}
    refresh_rake_tasks_file unless File.exists?(RAKE_TASKS_FILE)

    File.open(RAKE_TASKS_FILE) do |f|
      f.readlines.find_all{|t| /^rake mostfit/=~t}.each do |task|
        task_parts = task.split("# ").map(&:strip)
        rake_tasks[task_parts[0]] = task_parts[1]
      end
    end

    rake_tasks
  end

  def refresh_rake_tasks_file
    `rake -T mostfit > #{RAKE_TASKS_FILE}`
  end

  def schedule_to_s(task)
    minutes_str = (task[:minute] == "*") ? ("Every minute") : (task[:minute].split(",").map(&:to_i).map(&:ordinalize).join(", ")+" minute")
    hours_str = (task[:hour] == "*") ? ("every hour") : (task[:hour].split(",").map(&:to_i).map(&:ordinalize).join(", ")+" hour")
    days_str = (task[:day] == "*") ? ("every day") : (task[:day].split(",").map(&:to_i).map(&:ordinalize).join(", ")+" day")
    months_str = (task[:month] == "*") ? ("every month") : (task[:month].split(",").map(&:to_i).map {|m| MONTHS[m-1] }.join(", "))
    weekdays_str = (task[:weekday] == "*") ? ("every day of the week") : (task[:weekday].split(",").map(&:to_i).map {|w| WEEKDAYS[w] }.join(", "))
    "#{minutes_str} of #{hours_str} of #{days_str} of #{months_str} on #{weekdays_str}."
  end

end
