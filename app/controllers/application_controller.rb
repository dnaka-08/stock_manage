require 'microsoft_graph_auth'
require 'oauth2'

class ApplicationController < ActionController::Base
  include SessionsHelper
  include UsersHelper
  before_action :set_user
  
  MICROSOFT_TYPE_GROUP = "#microsoft.graph.group"

  def set_user
    @user_name = user_name
    @user_email = user_email
    @user_id = user_id
  end

  def set_user_session
    session[:user_admin] ||= get_user_admin
    session[:user_target_store] ||= get_user_target_store
    @user_admin = session[:user_admin]
    @user_target_store = session[:user_target_store]
  end

  def get_user_admin
    api_rec = make_api_call('get', "/v1.0/groups/#{ENV['ADMIN_GROUP']}/members", access_token, {'$count': 'true'})
    api_rec["value"].each do |rec|
      if rec["id"] == @user_id
        session[:user_admin] = true
        break
      else
        session[:user_admin] = false
      end
    end
    session[:user_admin]
  end
  
  def get_user_target_store
    api_rec = make_api_call('get', "/v1.0/groups/#{ENV['ADMIN_GROUP']}/members", access_token, {'$count': 'true'})
    api_rec["value"].each do |rec|
      if rec["id"] == @user_id
        session[:user_target_store] = []
        break
      else
        session[:user_target_store] = []
        api_rec["value"].each do |group_rec|
          if group_rec["@odata.type"] == MICROSOFT_TYPE_GROUP
            @store_rec = make_api_call('get', "/v1.0/groups/#{group_rec['id']}/members", access_token, {'$count': 'true'})
            @store_rec["value"].each do |store_rec|
              if store_rec["id"] == @user_id
                store_id = Store.where('ad_id = ?', group_rec['id'])
                session[:user_target_store].push(store_id[0].id)
                break
              end
            end
          end
        end
      end
    end
    session[:user_target_store]
  end
  # </BeforeActionSnippet>

  # <SaveInSessionSnippet>
  def save_in_session(auth_hash)
    puts auth_hash.dig(:credentials)
    # Save the token info
    session[:graph_token_hash] = auth_hash.dig(:credentials)
    # Save the user's display name
    session[:user_name] = auth_hash.dig(:extra, :raw_info, :displayName)
    # Save the user's email address
    # Use the mail field first. If that's empty, fall back on
    # userPrincipalName
    session[:user_email] = auth_hash.dig(:extra, :raw_info, :mail) ||
                           auth_hash.dig(:extra, :raw_info, :userPrincipalName)
    session[:id] = auth_hash.dig(:extra, :raw_info, :id)
  end
  # </SaveInSessionSnippet>

  def user_name
    session[:user_name]
  end

  def user_email
    session[:user_email]
  end

  def user_id
    session[:id]
  end

  # <AccessTokenSnippet>
  def access_token
    token_hash = session[:graph_token_hash]

    # Get the expiry time - 5 minutes
    expiry = Time.at(token_hash[:expires_at] - 300)

    if Time.now > expiry
      # Token expired, refresh
      new_hash = refresh_tokens token_hash
      new_hash[:token]
    else
      token_hash[:token]
    end
  end
  # </AccessTokenSnippet>

  # <RefreshTokensSnippet>
  def refresh_tokens(token_hash)
    oauth_strategy = OmniAuth::Strategies::MicrosoftGraphAuth.new(
      nil, ENV['AZURE_APP_ID'], ENV['AZURE_APP_SECRET']
    )

    token = OAuth2::AccessToken.new(
      oauth_strategy.client, token_hash[:token],
      refresh_token: token_hash[:refresh_token]
    )
    # Refresh the tokens
    new_tokens = token.refresh!.to_hash.slice(:access_token, :refresh_token, :expires_at)

    # Rename token key
    new_tokens[:token] = new_tokens.delete :access_token

    # Store the new hash
    session[:graph_token_hash] = new_tokens
  end
  
  private

  # SAMLログイン必須確認
  def authenticaet_user
    if @user_name.nil?
      redirect_to login_index_path
    end
  end
  
  def require_admin_user
    unless session[:user_admin]
      redirect_to root_url
    end
  end
end
