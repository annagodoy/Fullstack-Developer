class Admin::DashboardController < Admin::BaseController
  def show
    @users_by_role = User.group(:role).count
    @total_users = @users_by_role.values.sum
  end
end
