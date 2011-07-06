module Merb::Utils
  module FileCache
    def display_from_cache
      return false if params[:action]=="dashboard" and params[:id]=="center_day"
      file = get_cached_filename
      return true unless File.exists?(file)
      return true if not File.mtime(file).to_date==Date.today
      throw :halt, render(File.read(file), :layout => false)
    end
    
    def store_to_cache
      return false if params[:action]=="dashboard" and params[:id]=="center_day"
      file = get_cached_filename
      if not (File.exists?(file) and File.mtime(file).to_date==Date.today)
        File.open(file, "w"){|f|
          f.puts @body
        }
      end
    end
    
    def get_cached_filename
      hash = params.deep_clone
      controller = hash.delete(:controller).to_s
      action     = hash.delete(:action).to_s
      [:format, :submit].each{|x| hash.delete(x)}
      dir = File.join(Merb.root, "public", controller, action)
      unless File.exists?(dir)
        FileUtils.mkdir_p(dir)
      end
      File.join(dir, hash.collect{|k,v| "#{k}_#{v}"}.join("_"))
    end
  end
end
