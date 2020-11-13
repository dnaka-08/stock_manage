class MngTablesController < ApplicationController
  before_action :authenticaet_user
  before_action :require_admin_user
  #before_action :set_root, only: [:index]
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
    
    @product_id = params[:product_id] # 選択された商品ID
    
    @stock_detail = StockDetail.joins(:operation, :store).where("stock_details.date >= ? and stock_details.date <= ? and stock_details.product_id = ?", @date_begin, @date_end, @product_id).group("stores.name").group("stock_details.date").group("operations.name").select("stores.name as store_name, stock_details.date as date, operations.name as operation_name, sum(stock_details.number) as stock_sum")
    @stock = Stock.joins(:store).where("stocks.date >= ? and stocks.date <= ? and stocks.product_id = ?", @date_begin, @date_end, @product_id).select("stores.name as store_name, stocks.date as date, stocks.total_number")
    @stock_before = Stock.joins(:store).where("stocks.date < ? and stocks.product_id = ?", @date_begin, @product_id).group("stores.name").select("stores.name as store_name, sum(stocks.total_number) as total_number_sum")
    @store = StockDetail.joins(:store).where("date >= ? and date <= ?", @date_begin, @date_end).select("stores.id as store_id, stores.name as store_name").distinct
     @product = Product.find(@product_id)
    @operation = Operation.all

    @mng_table = []
    @store.each do |store|
      @operation.each do |ope|
        @mng_rec = {}
        @mng_rec.store("store", store.store_name)
        @mng_rec.store("ope", ope.name)
        (Date.parse(@date_begin)..Date.parse(@date_end)).each do |date|
          @stock_detail.each do |stock_detail|
            if stock_detail.date == date and stock_detail.store_name == store.store_name and stock_detail.operation_name == ope.name
              @mng_rec.store(date, stock_detail.stock_sum)
              break
            else
              @mng_rec.store(date, 0)
            end
          end
        end
        @mng_table.push(@mng_rec)
      end
      
      @mng_rec = {}
      @mng_rec.store("store", store.store_name)
      @mng_rec.store("ope", "在庫")
      @mng_rec.store("store_id", store.store_id)
      @mng_rec.store("product_id", @product_id)
      total_number = 0
      @stock_before.each do |stock_before|
        if stock_before.store_name == store.store_name
          total_number = stock_before.total_number_sum
          break
        end
      end      
      (Date.parse(@date_begin)..Date.parse(@date_end)).each do |date|
        @stock.each do |stock|
          if stock.date == date and stock.store_name == store.store_name
            @mng_rec.store(date, total_number + stock.total_number)
            total_number = total_number + stock.total_number
            break
          else
            @mng_rec.store(date, total_number)
          end
        end
      end
      @mng_table.push(@mng_rec)
    end
    
    
    respond_to do |format|
      format.html
      format.pdf do
        html = render_to_string template: "mng_tables/index"
        pdf = PDFKit.new(html, encoding: "UTF-8")
        pdf.stylesheets << "#{Rails.root}/app/assets/stylesheets/bootstrap.min.css"
        send_data pdf.to_pdf,
          filename: "在庫管理表_#{Time.zone.now.strftime('%Y%m%d%H%M%S')}.pdf",
          type: "application/pdf",
          disposition: "inline"
      end
    end
  end
end
