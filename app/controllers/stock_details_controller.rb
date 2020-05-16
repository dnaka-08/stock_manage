class StockDetailsController < ApplicationController
  before_action :require_user_logged_in
  before_action :set_root, only: [:index, :new, :create]
  before_action :set_user_session, only: [:index, :new, :create]
  before_action :set_stock_detail, only: [:destroy]

  def index
    @stock_details = StockDetail.joins(:store, :product, :operation).where("store_id = ? and product_id = ? and date = ?", params[:store_id], params[:product_id], params[:date]).order(updated_at: :desc).select("stock_details.*, operations.name as operation_name, stores.name as store_name, products.name as product_name").page(params[:page]).per(15)
    @store = Store.find(params[:store_id])
    @product = Product.find(params[:product_id])
    @date = params[:date]
  end

  def new
    @stock_detail = StockDetail.new
  end

  def create
    @stock_detail = StockDetail.new(stock_detail_params)
    if @stock_detail.save
      @stock = Stock.where('store_id = ? and product_id = ? and date = ?', @stock_detail.store_id, @stock_detail.product_id, @stock_detail.date)
      @stock_before = Stock.where('store_id = ? and product_id = ? and date < ?', @stock_detail.store_id, @stock_detail.product_id, @stock_detail.date).order(date: :desc).first
      @stock_after = Stock.where('store_id = ? and product_id = ? and date > ?', @stock_detail.store_id, @stock_detail.product_id, @stock_detail.date)
      if @stock.count == 0 and @stock_detail.number.nil? == false
        # 対象日付のデータなし
        if @stock_before.nil? == false
          # 前日以前の在庫あり
          @stock_before.with_lock do
            if @stock_detail.operation_id == 1
              # 入庫
              @stock = Stock.create(store_id: @stock_detail.store_id, product_id: @stock_detail.product_id, date: @stock_detail.date, total_number: @stock_detail.number, stock_number: @stock_before.stock_number + @stock_detail.number)
              @stock_after.update_all("stock_number = stock_number + #{@stock_detail.number}")
            else
              # 入庫以外
              @stock = Stock.create(store_id: @stock_detail.store_id, product_id: @stock_detail.product_id, date: @stock_detail.date, total_number: @stock_detail.number * (-1), stock_number: @stock_before.stock_number - @stock_detail.number)
              @stock_after.update_all("stock_number = stock_number - #{@stock_detail.number}")
            end
          end
        else
          # 前日以前の在庫なし
          if @stock_detail.operation_id == 1
            # 入庫
            @stock = Stock.create(store_id: @stock_detail.store_id, product_id: @stock_detail.product_id, date: @stock_detail.date, total_number: @stock_detail.number, stock_number: @stock_detail.number)
            @stock_after.update_all("stock_number = stock_number + #{@stock_detail.number}")
          else
            # 入庫以外
            @stock = Stock.create(store_id: @stock_detail.store_id, product_id: @stock_detail.product_id, date: @stock_detail.date, total_number: @stock_detail.number * (-1), stock_number: @stock_detail.number * (-1))
            @stock_after.update_all("stock_number = stock_number - #{@stock_detail.number}")
          end
        end
      elsif @stock_detail.number.nil? == false
        # 対象日付のデータあり
        @stock.first.with_lock do 
          if @stock_detail.operation_id == 1
            # 入庫
            @stock.first.total_number = @stock.first.total_number + @stock_detail.number
            @stock.first.stock_number = @stock.first.stock_number + @stock_detail.number
            @stock.first.save
            @stock_after.update_all("stock_number = stock_number + #{@stock_detail.number}")
          else
            # 入庫以外
            @stock.first.total_number = @stock.first.total_number - @stock_detail.number
            @stock.first.stock_number = @stock.first.stock_number - @stock_detail.number
            @stock.first.save
            @stock_after.update_all("stock_number = stock_number - #{@stock_detail.number}")
          end
        end
      end
    
      flash[:success] = '在庫詳細を登録しました。'
      redirect_to root_path
    else
      flash[:danger] = '在庫詳細の登録に失敗しました。'
      render :new
    end
    
  end

  def destroy
    
    @stock = Stock.where('store_id = ? and product_id = ? and date = ?', @stock_detail.store_id, @stock_detail.product_id, @stock_detail.date)
    @stock_after = Stock.where('store_id = ? and product_id = ? and date > ?', @stock_detail.store_id, @stock_detail.product_id, @stock_detail.date)
    
    @stock.first.with_lock do
      if @stock_detail.operation_id == 1
        # 入庫
        @stock.first.total_number = @stock.first.total_number - @stock_detail.number
        @stock.first.save
        @stock_after.update_all("stock_number = stock_number - #{@stock_detail.number}")
      else
        # 入庫以外
        @stock.first.total_number = @stock.first.total_number + @stock_detail.number
        @stock.first.save
        @stock_after.update_all("stock_number = stock_number + #{@stock_detail.number}")
      end

      @stock_detail.destroy
      flash[:success] = '正常に削除されました。'
      redirect_back(fallback_location: root_path)
    end
  end
  
  private
  
  def stock_detail_params
    params.require(:stock_detail).permit(:store_id, :product_id, :date, :operation_id, :number, :user_id)
  end
  
  def set_stock_detail
    @stock_detail = StockDetail.find(params[:id])
  end
end
