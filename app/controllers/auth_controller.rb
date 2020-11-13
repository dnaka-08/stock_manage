class AuthController < ApplicationController
  skip_before_action :set_user
  
  def callback
    # Access the authentication hash for omniauth
    data = request.env['omniauth.auth']
    # Save the data in the session
    save_in_session data

    redirect_to root_url
  end
  # </CallbackSnippet>

  # <SignOutSnippet>
  def signout
    @api_rec = make_api_call('post', "/v1.0/users/#{session[:id]}/revokeSignInSessions", access_token, nil)
    reset_session
    redirect_to login_index_path
  end
end
