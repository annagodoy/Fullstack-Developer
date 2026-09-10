class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: %i[ edit update destroy]

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

  def edit; end

  def update
    unless @user.update(update_params)
      return render :edit, status: :unprocessable_entity
    end

    redirect_to destination,
    notice: "User updated.",
    status: :see_other
  end

  def destroy
    self_deleting = @user.id == Current.user.id

    @user.destroy!

    if self_deleting
      cookies.delete(:session_id)
      reset_session
      Current.reset
    end

    redirect_to self_deleting ? new_session_path : admin_users_path,
    notice: "User deleted.",
    status: :see_other
  end

  private

  def destination
    Current.user.reload.admin? ? admin_users_path : profile_path
  end

  def set_user
    @user = User.find(params[:id])
  end

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

  def update_params
    params.expect(
      user: %i[
        full_name
        email
        role
      ]
    )
  end
end
