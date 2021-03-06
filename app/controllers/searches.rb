class Searches < Application
  def index
    if params[:query] and params[:query].length>=1
      per_page       = request.xhr? ? 11 : 100
      @branches      = Branch.search(params[:query], per_page)
      @clients       = Client.search(params[:query], per_page)
      @centers       = Center.search(params[:query], per_page)
      @loans         = Loan.search(params[:query], per_page)
      @client_groups = ClientGroup.search(params[:query], per_page)
      @staff_members = StaffMember.search(params[:query], per_page)
      @bookmarks     = Bookmark.search(params[:query], session.user, per_page)
    end
    @floating = true if request.xhr?
    render :layout => layout?
  end

  def advanced
    if params[:model] and [:branch, :center, :client, :loan, :client_group].include?(params[:model].to_sym)
      model = Kernel.const_get(params[:model].capitalize)
      hash  = params.deep_clone
      hash.delete(:controller)
      hash.delete(:action)
      hash.delete(:model)      
      instance_variable_set("@#{model.to_s.downcase.pluralize}", model.all(hash))
      @floating = false
      render :index
    else
      render :advanced
    end
  end

  #get fields for all the models selected in form
  def fields
    @properties = get_all_properties(params)
    partial :fields
  end

  def edit
    @hash  = YAML::load(params[:parameters])
    @properties = get_all_properties(@hash)
    render
  end  

  def reporting
    @counter = params[:counter]||1
    if request.xhr?
      @model = Kernel.const_get(params[:model].camelcase)
      if params[:more]=="chain"
        @model = @model.relationships.find_all{|key, prop| prop.class==DataMapper::Associations::OneToMany::Relationship}.map{|x| x[0].singularize}
      elsif params[:model]
        @properties = get_properties_for(@model)
      end
      partial :form
    elsif request.method==:get
      render :advanced, :layout => layout?
    elsif request.method==:post
      @search  = Search.new(params)
      @bookmark= Bookmark.new
      @objects = @search.process
      @model   = @objects.first.class
      @fields  = params[:fields]
      if params[:precedence]
        @precedence = params[:precedence]
      else
        @precedence = Marshal.load(Marshal.dump(@fields))
        counter = 1
        @precedence.each{|model, properties|
          properties.each{|k, v|
            properties[k] = counter
            counter+=1
          }
        }
      end
      render :reporting
    end
  end

  def get
    return "" if not params[:model] or params[:model].blank?
    #params[:counter] = (params[:counter] ? params[:counter].to_i : 0)
    model = Kernel.const_get(params[:model][params[:counter]].singularize.camelcase)

    if not params[:property] or not params[:property][params[:counter]] or params[:property][params[:counter]].blank?
      return "<option value=''>select property</option>"+get_properties_for(model).collect{|prop| "<option value='#{prop}'>#{prop}</option>"}.join, :layout => false
    end

    property = model.properties.find{|p| p.name.to_s==params[:property][params[:counter]]} || model.relationships[params[:property][params[:counter]]]

    if not params[:operator] or not params[:operator][params[:counter]] or params[:operator][params[:counter]].blank?
      ops = Search.get_operators(property)
      ops = [["", "Select operator"]] + ops
      return "#{ops.collect{|x| "<option value='#{x.first.to_s}'>#{x.last.to_s}"}.join('</option>')}</option>", :layout => false
    else
      return get_values(model, property, params[:counter])
    end

  end
  
  private
  def get_values(model, property, counter, value = nil)
    value = value.to_s if value
    if property.type==Date or property.type==DateTime
      return date_select("value[#{counter}][#{property.name}]", value||Date.today, :id => "value_#{counter}")
    elsif [DataMapper::Types::Serial, Integer, Float, String, DataMapper::Types::Text].include?(property.type)
      return text_field(:id => "value_#{counter}", :name => "value[#{counter}][#{property.name}]", :value => value)
    elsif property.class==DataMapper::Associations::ManyToOne::Relationship
      return select(:id => "value_#{counter}", :name => "value[#{counter}][#{property.name}]", :collection => property.parent_model.all, 
                    :value_method => :id, :text_method => :name,:prompt => "Choose #{property.name}", :selected => value)
    elsif property.type==DataMapper::Types::Boolean
      return select(:id => "value_#{counter}", :name => "value[#{counter}][#{property.name}]", 
                    :collection => [["true", "yes"], ["false", "no"]], :prompt => "Choose #{property.name}", :selected => value)
    elsif property.type == DataMapper::Types::Discriminator
      return select(:id => "value_#{counter}", :name => "value[#{counter}][#{property.name}]",
                    :collection => property.model.descendants.to_a.map{|e| [e.to_s, e.to_s]}, :prompt => "Choose #{property.name}", :selected => value)      
    elsif property.type.class==Class
      return select(:id => "value_#{counter}", :name => "value[#{counter}][#{property.name}]", 
                    :collection => property.type.flag_map.to_a, :prompt => "Choose #{property.name}", :selected => value)
    end
  end

  def get_properties_for(model)
    model.properties.collect{|x| 
      if relation = model.relationships.find{|rel| rel[1].child_key.map{|ck| ck.name}.include?(x.name)}
        relation[0]
      else
        x.name
      end
    }
  end

  def get_all_properties(params)
    hash  = params.deep_clone
    hash.delete(:controller)
    hash.delete(:action)
    properties = {}
    hash[:model].each{|counter, model|
      klass = Kernel.const_get(model.camelcase)
      properties[model] = get_properties_for(klass)
    }
    properties
  end
end
