class ProfilesController < ApplicationController
  before_action :set_current_user

  def show; end

  def edit; end

  def update
    unless @current_user.update(profile_params)
      return render :edit, status: :unprocessable_entity
    end

    redirect_to profile_path,
    notice: "Profile updated.",
    status: :see_other
  end

  private

  def set_current_user
    @current_user = Current.user
  end

  def profile_params
    params.expect(user: %i[full_name email])
  end
end
