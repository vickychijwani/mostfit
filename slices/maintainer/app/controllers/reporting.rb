class Maintainer::Reporting < Maintainer::Application

  require File.join(Merb.root,'lib/cache.rb')
  require File.join(Merb.root,'lib/graph_utils.rb')

  include Grapher
  include Merb::Utils::FileCache
  include Merb::Utils::Graph

  before :get_context
  before :display_from_cache, :exclude => [:index]
  after  :store_to_cache, :exclude => [:index]

  def index
    render :layout => false
  end

  def centers
    graph = BarGraph.new("Total centers")
    vals = Center.all(:creation_date.not => nil, :creation_date.lte => Date.today).aggregate(:all.count, :creation_date)
    graph.data_type = :cumulative
    
    data = vals.map{|c, d| {Date.new(d.year, d.month, 1) => c}}.inject({}){|s,x| s+=x}.to_a.sort_by{|d, c| d}
    data = group_dates(data)
    graph.x_axis.steps = get_axis
    graph.data(data, :last, :first)
    return graph.generate
  end

end
