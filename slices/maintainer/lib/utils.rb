class String
  def to_cron_entry
    parts = self.split("\t")
    {
      :minute    => parts[0],
      :hour      => parts[1],
      :day       => parts[2],
      :month     => parts[3],
      :weekday   => parts[4],
      :command   => parts[5],
      :rake_task => parts[5][/rake mostfit:.*? /].strip
    }
  end
end

class Dir
  def self.mkdir_if_absent(dir)
    Dir.mkdir(dir) unless File.exists?(dir) and File.directory?(dir)
  end
end

class CronEdit::Crontab
  def list_maintainer
    self.list.delete_if { |k,v| not /^maintainer/ =~ k }
  end
end

module Merb::Maintainer::Utils
  def log(data)
    h = DM_REPO.scope {
      Maintainer::HistoryItem.create(
        :user_name   => session.user.login,
        :ip          => data[:ip],
        :time        => Time.now,
        :action      => data[:action],
        :data        => data[:name]
      )
    }
  end

  def database_backup
    Dir.mkdir_if_absent(DB_FOLDER)
    Dir.mkdir_if_absent(DUMP_FOLDER)

    username = DB_CONFIG[Merb.env]["username"]
    password = DB_CONFIG[Merb.env]["password"]
    database = "intaglio" #DB_CONFIG[Merb.env]["database"]
    today = `date +%H:%M:%S.%Y-%m-%d`.chomp
    snapshot_path = File.join(DUMP_FOLDER,"#{database.sub(/^mostfit_/,'')}.#{today}.sql")

    `mysqldump -u #{username} -p#{password} #{database} > #{snapshot_path}; bzip2 #{snapshot_path}` unless File.exists?(snapshot_path+".bz2")

    snapshot_path
  end

  # returns a slice-level path for the given location
  def slice_path(*locations)
    File.join(Merb.root, SLICE_PATH, locations)
  end

  # returns an app-level path for the given location
  def app_path(*locations)
    File.join(Merb.root, locations)
  end
end
