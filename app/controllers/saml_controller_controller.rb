class SamlControllerController < ApplicationController
  
  def index
    @attrs = {}
  end
  
  def sso
    settings = Account.get_saml_settings(ENV['GET_URL_BASE'])
    if settings.nil?
      render :action => :no_settings
      return
    end
    
    request = Onelogin::RubySaml::Authrequest.new
    redirect_to(request.create(settings))
  end
    
end
