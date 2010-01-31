class LoanDisbursementRegister < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id

  def initialize(params, dates)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    
    @name   = "Report from #{@from_date} to #{@to_date}"
    @branch = if params and params[:branch_id] and not params[:branch_id].blank?
                Branch.all(:id => params[:branch_id])
              else
                Branch.all(:order => [:name])
              end    
    @center = Center.get(params[:center_id]) if params and params[:center_id] and not params[:center_id].blank?
 end
  
  def name
    "Report from #{@from_date} to #{@to_date}"
  end
  
  def self.name
    "Loan disbursment register"
  end
  
  def generate
    branches, centers, groups, loans, loan_products = {}, {}, {}, {}, {}
    @branch.each{|b|
      loans[b.id]||= {}
      branches[b.id] = b
      
      b.centers.each{|c|
        next if @center and not @center.find{|x| x.id==c.id}
        loans[b.id][c.id]||= {}
        centers[c.id]        = c
        c.client_groups.sort_by{|x| x.name}.each{|g|
          groups[g.id] = g
          loans[b.id][c.id][g.id] ||= []
        }
      }
    }
    #0      1           2           3               4             5                 6
    #ref_no,client_name,spouse_name,loan_product_id,loan_sequence,disbursement_date,amount
    #1: Applied on
    Loan.all(:disbursal_date.gte => from_date, :disbursal_date.lte => to_date).each{|l|
      client    = l.client
      center_id = client.center_id      
      next if not centers.key?(center_id)
      loan_products[l.loan_product_id] = l.loan_product if not loan_products.key?(l.loan_product_id)
      branch_id = centers[center_id].branch_id
      loans[branch_id][center_id][l.client.client_group_id].push([client.reference, client.name, client.spouse_name, l.loan_product_id, l.id, l.disbursal_date, l.amount])
    }
    return [groups, centers, branches, loans, loan_products]
  end

end
