class Maintainer::HistoryItem

  include DataMapper::Resource
  include Merb::Helpers::DateAndTime
  
  ACTIONS = {
    'took_snapshot'    => 'took a database snapshot',
    'downloaded_dump'  => 'downloaded a database dump',
    'created_task'     => 'created a scheduled task',
    'edited_task'      => 'edited a scheduled task',
    'deleted_task'     => 'deleted a scheduled task',
    'deployed'         => 'performed a deployment'
  }
  
  property :id,         Serial
  property :user_name,  String,   :nullable => false
  property :ip,         String,   :nullable => false
  property :time,       DateTime, :nullable => false
  property :action,     String,   :nullable => false, :set => ACTIONS.keys
  property :data,       String
  
  def stringify
    desc = "#{user_name} #{ACTIONS[action]} "
    desc += "(#{data}) " if data
    desc += "from #{ip} <a href='#' title='#{time.strftime("%l:%M:%S %p, %d %b, %Y")}'>#{time_lost_in_words(time).sub(/\.0+/,"")} ago</a>"
  end
  
end
