class SalesTablesController < ApplicationController
  before_action :authenticaet_user
  before_action :require_admin_user
  before_action :set_user_session, only: [:index]
  
  def index
    if params[:target] == 'before' 
      @date_begin = (Date.strptime(params[:date], '%Y-%m-%d') << 1).beginning_of_month.to_s
      @date_end = (Date.strptime(params[:date], '%Y-%m-%d') << 1).end_of_month.to_s
    elsif params[:target] == 'after' 
      @date_begin = (Date.strptime(params[:date], '%Y-%m-%d') >> 1).beginning_of_month.to_s
      @date_end = (Date.strptime(params[:date], '%Y-%m-%d') >> 1).end_of_month.to_s
    elsif params[:target] == 'now' 
      @date_begin = (Date.strptime(params[:date], '%Y-%m-%d')).beginning_of_month.to_s
      @date_end = (Date.strptime(params[:date], '%Y-%m-%d')).end_of_month.to_s
    else
      @date_begin = Date.today.beginning_of_month.to_s
      @date_end = Date.today.end_of_month.to_s
    end
    session[:date] = @date_begin

    @stock_detail = StockDetail.joins(:store).where("stock_details.date >= ? and stock_details.date <= ? and stock_details.operation_id = ?", @date_begin, @date_end, 2)\
    .group("stores.name").group("stock_details.product_id").group("stock_details.date")\
    .select("stores.name as store_name, stock_details.date as date, stock_details.product_id as product_id, sum(stock_details.number) as stock_sum")\
    .order("store_name").order("product_id").order("date")
    @stock_detail_num_total = StockDetail.joins(:store).where("stock_details.date >= ? and stock_details.date <= ? and stock_details.operation_id = ?", @date_begin, @date_end, 2)\
    .group("stores.name").group("stock_details.product_id")\
    .select("stores.name as store_name, stock_details.product_id as product_id, sum(stock_details.number) as stock_num_total")\
    .order("store_name").order("product_id")
    @stock_detail_num_day_total = StockDetail.where("stock_details.date >= ? and stock_details.date <= ? and stock_details.operation_id = ?", @date_begin, @date_end, 2)\
    .group("stock_details.product_id").group("stock_details.date")\
    .select("stock_details.date as date, stock_details.product_id as product_id, sum(stock_details.number) as stock_sum_day_total")\
    .order("product_id").order("date")
    @stock_detail_num_all_total = StockDetail.where("stock_details.date >= ? and stock_details.date <= ? and stock_details.operation_id = ?", @date_begin, @date_end, 2)\
    .group("stock_details.product_id")\
    .select("stock_details.product_id as product_id, sum(stock_details.number) as stock_num_all_total")\
    .order("product_id")
    
    @stock_detail_price = StockDetail.joins(:store).where("stock_details.date >= ? and stock_details.date <= ? and stock_details.operation_id = ?", @date_begin, @date_end, 2)\
    .group("stores.name").group("stock_details.product_id").group("stock_details.date")\
    .select("stores.name as store_name, stock_details.date as date, stock_details.product_id as product_id, sum(stock_details.price) as stock_price")\
    .order("store_name").order("product_id").order("date")
    @stock_detail_price_total = StockDetail.joins(:store).where("stock_details.date >= ? and stock_details.date <= ? and stock_details.operation_id = ?", @date_begin, @date_end, 2)\
    .group("stores.name").group("stock_details.product_id")
    .select("stores.name as store_name, stock_details.product_id as product_id, sum(stock_details.price) as stock_price_total")\
    .order("store_name").order("product_id")
    @stock_detail_price_day_total = StockDetail.where("stock_details.date >= ? and stock_details.date <= ? and stock_details.operation_id = ?", @date_begin, @date_end, 2)\
    .group("stock_details.product_id").group("stock_details.date")\
    .select("stock_details.date as date, stock_details.product_id as product_id, sum(stock_details.price) as stock_price_day_total")\
    .order("product_id").order("date")
    @stock_detail_price_all_total = StockDetail.where("stock_details.date >= ? and stock_details.date <= ? and stock_details.operation_id = ?", @date_begin, @date_end, 2)\
    .group("stock_details.product_id")
    .select("stock_details.product_id as product_id, sum(stock_details.price) as stock_price_all_total")\
    .order("product_id")
    @stock_detail_price_day_sale_total = StockDetail.where("stock_details.date >= ? and stock_details.date <= ? and stock_details.operation_id = ?", @date_begin, @date_end, 2)\
    .group("stock_details.date")\
    .select("stock_details.date as date, sum(stock_details.price) as stock_price_day_sale_total")\
    .order("date")
    @stock_detail_price_all_sale_total = StockDetail.where("date >= ? and date <= ? and operation_id = ?", @date_begin, @date_end, 2)\
    .select("sum(price) as stock_price_all_sale_total")
    
    @store = StockDetail.joins(:store).where("date >= ? and date <= ?", @date_begin, @date_end).select("stores.name as store_name").distinct
    @product = Product.all
    
    #売上数表の作成
    @mng_table = []
    @store.each do |store|
      @product.each do |product|
        @mng_rec = {}
        @mng_rec.store("store", store.store_name)
        @mng_rec.store("product", product.name)
        @stock_detail_num_total.each do |total|
          if store.store_name == total.store_name and product.id == total.product_id
            @mng_rec.store("total", total.stock_num_total.to_s(:delimited, delimiter: ','))
            break
          end
        end
        if @mng_rec["total"].nil?
          @mng_rec.store("total", 0)
        end
        
        (Date.parse(@date_begin)..Date.parse(@date_end)).each do |date|
          @stock_detail.each do |stock_detail|
            if stock_detail.date == date and stock_detail.store_name == store.store_name and product.id == stock_detail.product_id
              @mng_rec.store(date, stock_detail.stock_sum.to_s(:delimited, delimiter: ','))
              break
            else
              @mng_rec.store(date, 0)
            end
          end
        end
        @mng_table.push(@mng_rec)
      end
    end
    
    @mng_rec = {}
    @product.each do |product|
      @mng_rec = {}
      @mng_rec.store("store", "日別合計")
      @mng_rec.store("product", product.name)
      @stock_detail_num_all_total.each do |total|
        if product.id == total.product_id
          @mng_rec.store("total", total.stock_num_all_total.to_s(:delimited, delimiter: ','))
          break
        end
      end
      if @mng_rec["total"].nil?
        @mng_rec.store("total", 0)
      end
      
      (Date.parse(@date_begin)..Date.parse(@date_end)).each do |date|
        @stock_detail_num_day_total.each do |stock_detail|
          if stock_detail.date == date and product.id == stock_detail.product_id
            @mng_rec.store(date, stock_detail.stock_sum_day_total.to_s(:delimited, delimiter: ','))
            break
          else
            @mng_rec.store(date, 0)
          end
        end
      end
      @mng_table.push(@mng_rec)
    end
    
    #売上金額表の作成
    @mng_price_table = []
    @store.each do |store|
      @product.each do |product|
        @mng_rec = {}
        @mng_rec.store("store", store.store_name)
        @mng_rec.store("product", product.name)
        @stock_detail_price_total.each do |total|
          if store.store_name == total.store_name and product.id == total.product_id
            @mng_rec.store("total", total.stock_price_total.to_s(:delimited, delimiter: ','))
            break
          end
        end
        if @mng_rec["total"].nil?
          @mng_rec.store("total", 0)
        end
        
        (Date.parse(@date_begin)..Date.parse(@date_end)).each do |date|
          @stock_detail_price.each do |stock_detail|
            if stock_detail.date == date and stock_detail.store_name == store.store_name and product.id == stock_detail.product_id
              @mng_rec.store(date, stock_detail.stock_price.to_s(:delimited, delimiter: ','))
              
              break
            else
              @mng_rec.store(date, 0)
            end
          end
        end
        @mng_price_table.push(@mng_rec)
      end
    end
    
    @mng_rec = {}
    @product.each do |product|
      @mng_rec = {}
      @mng_rec.store("store", "日別売上")
      @mng_rec.store("product", product.name)
      @stock_detail_price_all_total.each do |total|
        if product.id == total.product_id
          @mng_rec.store("total", total.stock_price_all_total.to_s(:delimited, delimiter: ','))
          break
        end
      end
      if @mng_rec["total"].nil?
        @mng_rec.store("total", 0)
      end
      
      (Date.parse(@date_begin)..Date.parse(@date_end)).each do |date|
        @stock_detail_price_day_total.each do |stock_detail|
          if stock_detail.date == date and product.id == stock_detail.product_id
            @mng_rec.store(date, stock_detail.stock_price_day_total.to_s(:delimited, delimiter: ','))
            break
          else
            @mng_rec.store(date, 0)
          end
        end
      end
      @mng_price_table.push(@mng_rec)
    end    
    
    @mng_rec = {}
    @mng_rec.store("store", "売上合計")
    @mng_rec.store("product", "")
    
    if @stock_detail_price_all_sale_total.take.stock_price_all_sale_total.nil?
      @mng_rec.store("total", 0)
    else
      @mng_rec.store("total", @stock_detail_price_all_sale_total.take.stock_price_all_sale_total.to_s(:delimited, delimiter: ','))
    end

    (Date.parse(@date_begin)..Date.parse(@date_end)).each do |date|
      @stock_detail_price_day_sale_total.each do |stock_detail|
        if stock_detail.date == date
          @mng_rec.store(date, stock_detail.stock_price_day_sale_total.to_s(:delimited, delimiter: ','))
          break
        else
          @mng_rec.store(date, 0)
        end
      end
    end
    @mng_price_table.push(@mng_rec)
    
    respond_to do |format|
      format.html
      format.pdf do
        html = render_to_string template: "sales_tables/index"
        pdf = PDFKit.new(html, encoding: "UTF-8")
        pdf.stylesheets << "#{Rails.root}/app/assets/stylesheets/bootstrap.min.css"
        send_data pdf.to_pdf,
          filename: "売上管理表_#{Time.zone.now.strftime('%Y%m%d%H%M%S')}.pdf",
          type: "application/pdf",
          disposition: "inline"
      end
    end    
    
    
  end
end
