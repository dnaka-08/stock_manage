class DistributesController < ApplicationController
  before_action :require_user_logged_in
  before_action :set_root, only: [:new]
  before_action :set_user_session, only: [:new]
  before_action :register_check, only: [:create]

  def new
    @stores = Store.all
  end

  def create
    i = 0
    params[:store_max].to_i.times do
      if params["num_#{i}"].to_i > 0 or params["num_#{i}"] != ""
        @stock_detail = StockDetail.new(
          store_id: params["store_id_#{i}"],
          product_id: params[:product_id],
          date: "#{params["date(1i)"]}-#{params["date(2i)"]}-#{params["date(3i)"]}",
          operation_id: 1,
          number: params["num_#{i}"],
          user_id: session[:user_id]
        )
        
        @result = @stock_detail.save
        if @result
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
        else
          break
        end
      end
      i = i + 1
    end

    if @result
      flash[:success] = '在庫詳細を登録しました。'
      redirect_to root_path
    else
      flash[:danger] = '在庫詳細の登録に失敗しました。'
      redirect_back(fallback_location: root_path)
    end      
  end
  
  private
  
  # 登録時チェック
  def register_check
        #必須チェック
    if params[:product_id] == "" or params[:dist_num] == ""
      flash[:danger] = '対象商品か分配数のいずれかが未入力です。'
      redirect_back(fallback_location: root_path)
      return  
    end
    
    #分配数数値チェック
    if params[:dist_num] !~ /^[0-9]+$/
      flash[:danger] = '分配数には数値を指定してください。'
      redirect_back(fallback_location: root_path)
      return
    end
    
    #分配数の整合性チェック
    sum_num = 0
    j = 0
    params[:store_max].to_i.times do
      if params["num_#{j}"] != ""
        #各店舗の数値チェック
        if params["num_#{j}"] !~ /^[0-9]+$/
          flash[:danger] = '各店舗の分配数には数値を指定してください。'
          redirect_back(fallback_location: root_path)
          return
        end
        #１以上チェック
        if params["num_#{j}"].to_i > 0
          flash[:danger] = '１以上を指定してください。'
          redirect_back(fallback_location: root_path)
          return
        end
        sum_num = sum_num + params["num_#{j}"].to_i
      end
      j = j + 1
    end
    
    if params[:dist_num].to_i != sum_num
      flash[:danger] = '分配数と各店舗の合計が一致しません。'
      redirect_back(fallback_location: root_path)
      return
    end
  end
  
end
