module Merb::Utils
  module Graph
    def group_by_values(model, collection, group_by, opts = {})
      opts[:allow_blank]=false if not opts.key?(:allow_blank)
      property = model.properties.find{|x| x.name==group_by} 

      if property and property.type.class==Class
        lookup = property.type.flag_map
      elsif property
        lookup = false
      elsif model.relationships.key?(group_by)
        lookup = {}
        model.relationships[group_by].parent_model.all.each{|x| lookup[x.id]=x.name}
        group_by = model.relationships[group_by].child_key.first.name
      end

      if lookup
        lookup[""]  = lookup[nil] = "Not specified" if opts[:allow_blank]
        return [] if collection.count == 0
        return collection.aggregate(:all.count, group_by).map{|c|
          id = c[1].to_i
          [c[0], lookup[id]]
        }.reject{|x| x[1].nil? or x[1].blank?}
      else
        if opts[:allow_blank]
          return collection.aggregate(:all.count, group_by)
        else
          return collection.aggregate(:all.count, group_by).reject{|x| x.nil? or x.blank?}
        end
      end
    end
    
    def get_steps(max)
      divisor = power(max)
      (max/(10**divisor)).to_i*10*divisor
    end
    
    def power(val, base=10)
      itr=1
      while val/(base**itr) > 1
        itr+=1
      end
      return itr-1
    end

    def get_clients
      hash = {}
      [:branch_id, :center_id, :staff_member_id].each{|attr| hash[attr] = params[attr] if params[attr] and not params[attr].blank?}
      if hash.empty?
        return Client
      else
        if hash[:center_id]
          hash.delete(:branch_id)
          Client.all(hash)
        elsif hash[:staff_member_id]
          StaffMember.get(hash[:staff_member_id]).clients
        elsif hash[:branch_id]
          Center.all(hash).clients(:fields => [:id, :date_joined, :religion, :caste])
        else
          Client
        end
      end
    end

    def get_context
      @branch = Branch.get(params[:branch_id]) if params[:branch_id] and not params[:branch_id].nil? and /\d+/.match(params[:branch_id])
      @center = Center.get(params[:center_id]) if params[:center_id] and not params[:center_id].nil?
      @staff_member = StaffMember.get(params[:staff_member_id]) if params[:staff_member_id] and not params[:staff_member_id].nil?
    end

    def quarter(date)
      if date.month<=3
        return "#{date.year-1}-#{date.year} Q4"
      elsif date.month>3 and date.month<7
        return "#{date.year}-#{date.year+1} Q1"
      elsif date.month>=7 and date.month<=9
        return "#{date.year}-#{date.year+1} Q2"
      elsif date.month>=10 and date.month<=12
        return "#{date.year}-#{date.year+1} Q3"
      end
    end

    # accounting year
    def year(date)
      if date.month<=3
        return "#{date.year-1}-#{date.year}"
      else
        return "#{date.year}-#{date.year+1}"
      end
    end

    def group_dates(data)
      if not params[:time_period] or params[:time_period]=="monthly"
        return data.group_by{|d, c| Date.new(d.year, d.month, 1)}.map{|k, v| [k, v.map{|x| x[1]}.inject(0){|s,x| s+=x}]}.sort_by{|d, c| d}.map{|k, v| [k.strftime("%Y %b"), v]}
      elsif params[:time_period]=="quarterly"
        return data.group_by{|d, c| quarter(d)}.map{|k, v| [k, v.map{|x| x[1]}.inject(0){|s,x| s+=x}]}.sort_by{|d, c| d}
      elsif params[:time_period]=="yearly"
        return data.group_by{|d, c| year(d)}.map{|d, c| [d, c.map{|d, c| c}.inject(0){|s, x| s+=x}]}.sort_by{|d, c| d}
      end
    end

    def get_axis
      if not params[:time_period] or params[:time_period]=="monthly"
        return 3
      elsif params[:time_period]=="quarterly"
        return 2
      elsif params[:time_period]=="yearly"
        return 1
      end    
    end

    def get_period_text
      if not params[:time_period] or params[:time_period]=="monthly"
        "month on month"
      elsif params[:time_period]=="quarterly"
        "quarter on quarter"
      elsif params[:time_period]=="yearly"
        "year on year"
      end    
    end
  end
end
