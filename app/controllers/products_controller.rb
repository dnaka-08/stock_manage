class ProductsController < ApplicationController
  before_action :authenticaet_user
  before_action :require_admin_user
  #before_action :set_root, only: [:index, :new, :edit]
  before_action :set_user_session, only: [:index, :new, :edit]
  before_action :set_product, only: [:edit, :update, :destroy]


  def index
    @products = Product.order(id: :desc).page(params[:page]).per(15)
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)
    
    if @product.save
      flash[:success] = '商品を登録しました。'
      redirect_to products_path
    else
      set_root
      set_user_session
      flash[:danger] = '商品の登録に失敗しました。'
      render :new
    end  
  end

  def edit
  end

  def update
    if @product.update(product_params)
      flash[:success] = '正常に更新されました。'
      redirect_to products_path
    else
      flash.now[:danger] = '更新されませんでした。'
      render :edit
    end  
  end

  def destroy
    @product.destroy
    
    flash[:success] = '正常に削除されました。'
    redirect_back(fallback_location: root_path)    
  end
  
  private
  
  def product_params
    params.require(:product).permit(:name)
  end
  
  def set_product
    @product = Product.find(params[:id])
  end
end
