class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  def require_admin!
    return if current_user&.admin?

    redirect_to root_path, alert: 'Acesso restrito ao administrador.' and return
  end

  def require_profissional!
    return if current_user&.profissional?

    redirect_to root_path, alert: 'Acesso restrito ao profissional.' and return
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
end
