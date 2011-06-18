class Maintainer::Database < Maintainer::Application

  def index
    render :layout => false
  end

  def take_snapshot
    snapshot_path = database_backup
    log({
      :action => 'took_snapshot',
      :ip     => request.remote_ip,
      :name   => File.basename(snapshot_path)
    })
    "true"
  end

  def download_dump(file)
    log({
      :action => 'downloaded_dump',
      :ip     => request.remote_ip,
      :name   => file
    })
    send_data(File.open(File.join(DUMP_FOLDER, file)), :filename => file, :type => "bzip2") if file and File.exists?(File.join(DUMP_FOLDER, file))
  end

end
