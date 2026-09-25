class RegistrationsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :new, :create ]
  rate_limit to: 5, within: 1.hour, only: :create,
             with: -> { redirect_to register_path, alert: t("flash.rate_limited") }

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      log_in(@user)
      redirect_to root_path, notice: t("flash.registered")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.expect(user: [ :username, :password, :password_confirmation ])
  end
end
