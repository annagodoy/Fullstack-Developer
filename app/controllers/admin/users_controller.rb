class Admin::UsersController < Admin::BaseController
  def index
    @users = User.order(:full_name, :id)
  end
end
