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

class CronEdit::Crontab
  def list_maintainer
    self.list.delete_if { |k,v| not /^maintainer/ =~ k }
  end
end

module Merb::Maintainer::Utils
  def log(data)
    h = DataMapper.repository(:maintainer) {
      Maintainer::HistoryItem.create(
        :user_name   => session.user.login,
        :ip          => data[:ip],
        :time        => Time.now,
        :action      => data[:action],
        :data        => data[:name]
      )
    }
  end
end
