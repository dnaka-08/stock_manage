class OutputMngTalblesController < ApplicationController
  before_action :require_user_logged_in
  before_action :set_root, only: [:index]
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
    
    @stock_detail = StockDetail.joins(:operation, :store).where("stock_details.date >= '#{@date_begin}' and stock_details.date <= '#{@date_end}'").group("stores.name").group("stock_details.date").group("operations.name").select("stores.name as store_name, stock_details.date as date, operations.name as operation_name, sum(stock_details.number) as stock_sum")
    @stock = Stock.joins(:store).where("stocks.date >= '#{@date_begin}' and stocks.date <= '#{@date_end}'").select("stores.name as store_name, stocks.date as date, stocks.total_number")
    @stock_before = Stock.joins(:store).where("stocks.date < '#{@date_begin}'").group("stores.name").select("stores.name as store_name, sum(stocks.total_number) as total_number_sum")
    @store = StockDetail.joins(:store).where("date >= '#{@date_begin}' and date <= '#{@date_end}'").select("stores.name as store_name").distinct
    @operation = Operation.all

    @mng_table = []
    @store.each do |store|
      @operation.each do |ope|
        # 出庫の場合のみ
        if ope.id == 2
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
      end  
    end
    
    respond_to do |format|
      format.html
      format.pdf do
        html = render_to_string template: "output_mng_tables/index"
        pdf = PDFKit.new(html, encoding: "UTF-8")
        pdf.stylesheets << "#{Rails.root}/app/assets/stylesheets/bootstrap.min.css"
        send_data pdf.to_pdf,
          filename: "出庫管理表_#{Time.zone.now.strftime('%Y%m%d%H%M%S')}.pdf",
          type: "application/pdf",
          disposition: "inline"
      end
    end
    
  end
end
