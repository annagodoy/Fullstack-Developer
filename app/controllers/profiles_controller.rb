class ProfilesController < ApplicationController
  before_action :set_current_user

  def show; end

  def edit; end

  def avatar
    image = @current_user.avatar_image
    return head :not_found unless image.attached?

    response.headers["Cache-Control"] = "private, no-store"

    send_data image.download,
      type: image.content_type,
      disposition: "inline",
      filename: image.filename.to_s
  end

  def update
    unless @current_user.update(profile_params)
      return render :edit, status: :unprocessable_entity
    end

    redirect_to profile_path,
    notice: "Profile updated.",
    status: :see_other
  end

  def destroy
    @current_user.destroy!

    cookies.delete(:session_id)
    reset_session
    Current.reset

    redirect_to new_session_path,
    notice: "Profile deleted.",
    status: :see_other
  end

  private

  def set_current_user
    @current_user = Current.user
  end

  def profile_params
    params.expect(user: %i[full_name email avatar_image])
  end
end
