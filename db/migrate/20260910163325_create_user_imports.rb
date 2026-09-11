class CreateUserImports < ActiveRecord::Migration[8.1]
  def change
    create_table :user_imports do |t|
      t.integer :status, null: false, default: 0
      t.integer :total_rows, null: false, default: 0
      t.integer :processed_rows, null: false, default: 0
      t.integer :failed_rows, null: false, default: 0
      t.text    :error_message
      t.timestamps
    end

    add_check_constraint :user_imports,
      "status IN (0, 1, 2, 3)",
      name: "user_imports_valid_status"

    add_check_constraint :user_imports,
      "total_rows >= 0 AND processed_rows >= 0 AND failed_rows >= 0 " \
      "AND failed_rows <= processed_rows AND processed_rows <= total_rows",
      name: "user_imports_valid_counts"
  end
end
