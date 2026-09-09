class ProfilesController < ApplicationController
  before_action :set_current_user

  def show; end

  private

  def set_current_user
    @current_user = Current.user
  end
end
