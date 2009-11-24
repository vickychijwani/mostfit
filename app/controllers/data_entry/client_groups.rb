module DataEntry
  class ClientGroups < DataEntry::Controller
    # provides :xml, :yaml, :js 
    def new
      only_provides :html
      @client_group = ClientGroup.new      
      @client_group.center_id = params[:center_id] if params[:center_id]
      request.xhr? ? display([@client_group], "client_groups/new", :layout => false) : display([@client_group], "client_groups/new")
    end

    def edit
      if (params[:id] and @client_group = ClientGroup.get(params[:id])) or (params[:group_id] and @client_group = ClientGroup.get(params[:group_id]) || ClientGroup.first(:name => params[:group_id]) || ClientGroup.first(:code => params[:group_id]))
        @center = @client_group.center
        @branch = @center.branch
        display([@client_group, @client, @center, @branch], "client_groups/edit")
      elsif params[:group_id] or params[:id]
        message[:error] = "No group by that id or name or code"
        display([], "client_groups/search")
      elsif params[:client_group] and params[:client_group][:center_id]
        @center  = Center.get(params[:client_group][:center_id])
        display([@center], "client_groups/search")
      else
        display([], "client_groups/search")
      end
    end

    def create(client_group)
      only_provides :html, :json
      @client_group = ClientGroup.new(client_group)
      if @client_group.save
        request.xhr? ? display(@client_group) : redirect(url(:data_entry), :message => {:notice => "Group was successfully created"})
      else
        message[:error] = "Group failed to be created"
        @client_group.center_id = params[:center_id] if params[:center_id] and not params[:center_id].blank?
        request.xhr? ? display(@client_group.errors, :status => 406) : display([@client_group], "client_groups/new")
      end
    end

    def update(id, client_group)
      @client_group = ClientGroup.get(id)
      raise NotFound unless @client_group
      if @client_group.update(client_group)
        request.xhr? ? display(@client_group) : redirect(url(:data_entry), :message => {:notice => "Group was successfully saved"})
      else
        message[:error] = "Group failed to be saved"
        request.xhr? ? display(@client_group.errors, :status => 406) : render(:new)
      end
    end    
  end # ClientGroups    
end
