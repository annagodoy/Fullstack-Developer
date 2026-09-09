class RequireFullNameOnUsers < ActiveRecord::Migration[8.1]
  def change
    change_column_null :users, :full_name, false

    add_check_constraint :users,
      "BTRIM(full_name) <> ''",
      name: "users_full_name_not_blank"
  end
end
