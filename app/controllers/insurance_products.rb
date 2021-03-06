class InsuranceProducts < Application
  # provides :xml, :yaml, :js

  def index
    @insurance_products = InsuranceProduct.all
    display @insurance_products
  end

  def show(id)
    @insurance_product = InsuranceProduct.get(id)
    raise NotFound unless @insurance_product
    display @insurance_product
  end

  def new
    only_provides :html
    @insurance_product = InsuranceProduct.new
    display @insurance_product, :layout => (request.xhr? ? false : layout?)
  end

  def edit(id)
    only_provides :html
    @insurance_product = InsuranceProduct.get(id)
    raise NotFound unless @insurance_product
    display @insurance_product
  end

  def create(insurance_product)
    @insurance_product = InsuranceProduct.new(insurance_product)
    @insurance_product.fees = []
    params[:fees] = params[:fees] || {}
    params[:fees].each do |k,v|
      f = Fee.get(k.to_i)
      @insurance_product.fees << f if f
    end
    if @insurance_product.save
      redirect resource(@insurance_product), :message => {:notice => "InsuranceProduct was successfully created"}
    else
      message[:error] = "InsuranceProduct failed to be created"
      render :new
    end
  end

  def update(id, insurance_product)
    debugger
    @insurance_product = InsuranceProduct.get(id)
    raise NotFound unless @insurance_product
    fees = []
    if params[:fees]
      fees = params[:fees].keys.map{ |k,v| Fee.get(k.to_i) }
    end
    @insurance_product.update_attributes(insurance_product)
    @insurance_product.fees = fees
    if @insurance_product.save or @insurance_product.errors.empty?
       redirect resource(@insurance_product)
    else
      display @insurance_product, :edit
    end
  end

  def destroy(id)
    @insurance_product = InsuranceProduct.get(id)
    raise NotFound unless @insurance_product
    if @insurance_product.destroy
      redirect resource(:insurance_products)
    else
      raise InternalServerError
    end
  end

end # InsuranceProducts
