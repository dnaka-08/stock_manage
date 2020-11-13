class StockDetailsController < ApplicationController
  before_action :authenticaet_user
  before_action :set_user_session, only: [:index, :new, :create]
  before_action :set_stock_detail, only: [:destroy]
  before_action :register_check, only: [:create]

  def index
    @stock_details = StockDetail.joins(:store, :product, :operation).where("store_id = ? and product_id = ? and date = ?", params[:store_id], params[:product_id], params[:date]).order(updated_at: :desc).select("stock_details.*, operations.name as operation_name, stores.name as store_name, products.name as product_name").page(params[:page]).per(15)
    @store = Store.find(params[:store_id])
    @product = Product.find(params[:product_id])
    @date = params[:date]
  end

  def new
    @button_name = "新規登録"
    @update_flg = false # 更新フラグ
    # 在庫数が修正の場合（各paramが存在する）
    if params[:product_id].nil? == false and params[:date].nil? == false and params[:store_id].nil? == false
      @detail_data = StockDetail.where("product_id = ? and date = ? and store_id = ?", params[:product_id], params[:date], params[:store_id])
      
      if @detail_data.count > 0
        @update_flg = true
        @button_name = "更新"
      end
      @in_number = 0
      @out_number = 0
      @drop_number = 0
      @detail_data.each do |rec|
        if rec.operation_id == 1
          @in_number = @in_number + rec.number
        elsif rec.operation_id == 2
          @out_number = @out_number + rec.number
        elsif rec.operation_id == 3
          @drop_number = @drop_number + rec.number
        end
      end
      
      @stock_detail = StockDetail.new(
        product_id: params[:product_id],
        store_id: params[:store_id],
        date: params[:date].to_date
       )
    else
      @stock_detail = StockDetail.new
    end

  end

  def create
    ActiveRecord::Base::transaction() do
      # 既存内容の更新の場合、既存データを削除
      if params[:stock_detail]["update_flg"] == "true"
        @date = params[:stock_detail]["date(1i)"] + "-" + sprintf("%002d", params[:stock_detail]["date(2i)"]) + "-" + sprintf("%002d", params[:stock_detail]["date(3i)"])
        @stock_details = StockDetail.where("product_id = ? and date = ? and store_id = ?", params[:stock_detail]["product_id"], @date, params[:stock_detail]["store_id"])
        @stock = Stock.where('store_id = ? and product_id = ? and date = ?', params[:stock_detail]["store_id"], params[:stock_detail]["product_id"], @date)
        @stock_after = Stock.where('store_id = ? and product_id = ? and date > ?', params[:stock_detail]["store_id"], params[:stock_detail]["product_id"], @date)
        
        @stock.first.with_lock do
          # 既存レコードを全て削除
          @stock_details.each do |stock_detail|
            if stock_detail.operation_id == 1
              # 入庫
              @stock.first.total_number = @stock.first.total_number - stock_detail.number
              @stock.first.save
              @stock_after.update_all("stock_number = stock_number - #{stock_detail.number}")
            elsif stock_detail.operation_id == 2
              # 出庫
              @stock.first.total_number = @stock.first.total_number + stock_detail.number
              @stock.first.out_number = @stock.first.out_number - stock_detail.number
              @stock.first.save
              @stock_after.update_all("stock_number = stock_number + #{stock_detail.number}")
            else
              # 破棄
              @stock.first.total_number = @stock.first.total_number + stock_detail.number
              @stock.first.save
              @stock_after.update_all("stock_number = stock_number + #{stock_detail.number}")
            end
            stock_detail.destroy
          end
        end        
      end
      
      operation_id = 1  #オペレーション区分のカウント変数
      if params[:stock_detail]["in_number"] == "0" and params[:stock_detail]["out_number"] == "0" and params[:stock_detail]["drop_number"] == "0"
        result = true
      end
      for number in [params[:stock_detail]["in_number"], params[:stock_detail]["out_number"], params[:stock_detail]["drop_number"]]
        if number.to_i > 0 and number != ""
          @stock_detail = StockDetail.new(store_id: params[:stock_detail]["store_id"], product_id: params[:stock_detail]["product_id"], \
          date: params[:stock_detail]["date(1i)"] + "-" + params[:stock_detail]["date(2i)"] + "-" + params[:stock_detail]["date(3i)"], \
          operation_id: operation_id, number: number, user_name: params[:stock_detail]["user_name"])
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
                    @stock = Stock.create(store_id: @stock_detail.store_id, product_id: @stock_detail.product_id, date: @stock_detail.date, total_number: @stock_detail.number, stock_number: @stock_before.stock_number + @stock_detail.number, out_number: 0)
                    @stock_after.update_all("stock_number = stock_number + #{@stock_detail.number}")
                  elsif @stock_detail.operation_id == 2
                    # 出庫
                    @stock = Stock.create(store_id: @stock_detail.store_id, product_id: @stock_detail.product_id, date: @stock_detail.date, total_number: @stock_detail.number * (-1), stock_number: @stock_before.stock_number - @stock_detail.number, out_number: @stock_detail.number)
                    @stock_after.update_all("stock_number = stock_number - #{@stock_detail.number}")
                  else
                    # 破棄
                    @stock = Stock.create(store_id: @stock_detail.store_id, product_id: @stock_detail.product_id, date: @stock_detail.date, total_number: @stock_detail.number * (-1), stock_number: @stock_before.stock_number - @stock_detail.number, out_number: 0)
                    @stock_after.update_all("stock_number = stock_number - #{@stock_detail.number}")
                  end
                end
              else
                # 前日以前の在庫なし
                if @stock_detail.operation_id == 1
                  # 入庫
                  @stock = Stock.create(store_id: @stock_detail.store_id, product_id: @stock_detail.product_id, date: @stock_detail.date, total_number: @stock_detail.number, stock_number: @stock_detail.number, out_number: 0)
                  @stock_after.update_all("stock_number = stock_number + #{@stock_detail.number}")
                elsif @stock_detail.operation_id == 2
                  # 出庫
                  @stock = Stock.create(store_id: @stock_detail.store_id, product_id: @stock_detail.product_id, date: @stock_detail.date, total_number: @stock_detail.number * (-1), stock_number: @stock_detail.number * (-1), out_number: @stock_detail.number)
                  @stock_after.update_all("stock_number = stock_number - #{@stock_detail.number}")
                else
                  # 破棄
                  @stock = Stock.create(store_id: @stock_detail.store_id, product_id: @stock_detail.product_id, date: @stock_detail.date, total_number: @stock_detail.number * (-1), stock_number: @stock_detail.number * (-1), out_number: 0)
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
                elsif @stock_detail.operation_id == 2
                  # 出庫
                  @stock.first.total_number = @stock.first.total_number - @stock_detail.number
                  @stock.first.stock_number = @stock.first.stock_number - @stock_detail.number
                  @stock.first.out_number = @stock.first.out_number + @stock_detail.number
                  @stock.first.save
                  @stock_after.update_all("stock_number = stock_number - #{@stock_detail.number}")
                else
                  # 破棄
                  @stock.first.total_number = @stock.first.total_number - @stock_detail.number
                  @stock.first.stock_number = @stock.first.stock_number - @stock_detail.number
                  @stock.first.save
                  @stock_after.update_all("stock_number = stock_number - #{@stock_detail.number}")
                end
              end
            end
          
            result = true
          else
            result = false
          end
        end
          
        operation_id = operation_id + 1
      end

      if result
        flash[:success] = '在庫詳細を登録しました。'
        redirect_to root_path
      else
        flash[:danger] = '在庫詳細の登録に失敗しました。'
        redirect_back(fallback_location: root_path)
      end
    end  
  end
  
  def edit
    @stock_detail = StockDetail.where("product_id = ? and date = ?", params[:product_id], params[:date])
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
      elsif @stock_detail.operation_id == 2
        # 出庫
        @stock.first.total_number = @stock.first.total_number + @stock_detail.number
        @stock.first.out_number = @stock.first.out_number - @stock_detail.number
        @stock.first.save
        @stock_after.update_all("stock_number = stock_number + #{@stock_detail.number}")
      else
        # 破棄
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
    params.require(:stock_detail).permit(:store_id, :product_id, :date, :operation_id, :in_number, :out_number, :drop_number, :user_id)
    binding.pry
  end
  
  def set_stock_detail
    @stock_detail = StockDetail.find(params[:id])
  end
  
  # 登録チェック
  def register_check
    #必須チェック（対象店舗）
    if params[:stock_detail]["store_id"] == ""
      flash[:danger] = '対象店舗が未入力です。'
      redirect_back(fallback_location: root_path)
      return  
    end
    
    #必須チェック（対象商品）
    if params[:stock_detail]["product_id"] == ""
      flash[:danger] = '対象商品が未入力です。'
      redirect_back(fallback_location: root_path)
      return  
    end

    #必須チェック（入庫数、出庫数、破棄数）
    if params[:stock_detail]["in_number"] == "" and params[:stock_detail]["out_number"] == "" and params[:stock_detail]["drop_number"] == ""
      flash[:danger] = '入庫数、出庫数、破棄数のいずれかを入力してください。'
      redirect_back(fallback_location: root_path)
      return  
    end
    
    #入庫数数値チェック
    if params[:stock_detail]["in_number"] != "" and params[:stock_detail]["in_number"] !~ /^[0-9]+$/
      flash[:danger] = '入庫数には数値を指定してください。'
      redirect_back(fallback_location: root_path)
      return
    end    

    #出庫数数値チェック
    if params[:stock_detail]["out_number"] != "" and params[:stock_detail]["out_number"] !~ /^[0-9]+$/
      flash[:danger] = '出庫数には数値を指定してください。'
      redirect_back(fallback_location: root_path)
      return
    end    

    #破棄数数値チェック
    if params[:stock_detail]["drop_number"] != "" and params[:stock_detail]["drop_number"] !~ /^[0-9]+$/
      flash[:danger] = '破棄数には数値を指定してください。'
      redirect_back(fallback_location: root_path)
      return
    end    
    
  end
end
