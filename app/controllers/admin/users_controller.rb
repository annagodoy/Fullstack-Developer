class Admin::UsersController < Admin::BaseController
  def index
    @users = User.order(:full_name, :id)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    unless @user.save
      return render :new, status: :unprocessable_entity
    end

    redirect_to admin_users_path,
    notice: "User created.",
    status: :see_other
  end

  private

  def user_params
    params.expect(
      user: %i[
        full_name
        email
        password
        role
      ]
    )
  end
end
