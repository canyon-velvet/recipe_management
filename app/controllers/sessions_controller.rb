class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :new, :create ]

  def new
  end

  def create
    user = User.find_by("LOWER(username) = ?", params[:username].to_s.downcase)
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to root_path, notice: "登录成功"
    else
      flash.now[:alert] = "用户名或密码错误"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to login_path, notice: "已退出登录"
  end
end
