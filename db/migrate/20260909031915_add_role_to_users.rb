class AddRoleToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :integer, null: false, default: 0

    add_check_constraint :users,
      "role IN (0, 1)",
      name: "users_roles_allowed_values"
  end
end
