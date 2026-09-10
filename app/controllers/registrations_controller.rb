class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    unless @user.save(context: :registration)
      return render :new, status: :unprocessable_entity
    end

    start_new_session_for(@user)

    redirect_to profile_path,
    notice: "Profile created.",
    status: :see_other
  end

  private

  def registration_params
    params.expect(
      user: %i[
        full_name
        email
        password
        password_confirmation
      ]
    )
  end
end
