class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: %i[ edit update destroy]
  before_action :set_page, only: :index

  PAGE_SIZE = 25

  def index
    @has_next_page = records.size > PAGE_SIZE
    @users = records.first(PAGE_SIZE)
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

  def records
    User.order(:full_name, :id)
      .offset((@page - 1) * PAGE_SIZE)
      .limit(PAGE_SIZE + 1)
      .to_a
  end

  def set_page
    @page = [ Integer(params[:page].to_s, exception: false) || 1, 1 ].max
  end

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
