class Admin::UserImportsController < Admin::BaseController
  def new
    @user_import = UserImport.new
  end

  def create
    @user_import = UserImport.new(user_import_params)

    unless @user_import.save
      return render :new, status: :unprocessable_entity
    end

    redirect_to admin_user_import_path(@user_import),
    notice: "Spreadsheet uploaded successfully",
    status: :see_other
  end

  def show
    @user_import = UserImport.find(params[:id])
  end

  private

  def user_import_params
    params.expect(user_import: [
      :spreadsheet
    ])
  end
end
