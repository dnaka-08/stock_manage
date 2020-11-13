module SessionsHelper
  # ローカルログインユーザ情報取得
  #def current_user
  #  @current_user ||= User.find_by(id: session[:user_id])
  #end

  # SAMLログインユーザ情報取得
  def current_user_saml
    @current_user_saml ||= session[:user_name]
  end
  
  # ローカルログイン情報取得
  #def logged_in?
  #  !!current_user
  #end
  
  # SAMLログイン情報取得
  def logged_in_saml?
    current_user_saml.present?
  end
  
end
