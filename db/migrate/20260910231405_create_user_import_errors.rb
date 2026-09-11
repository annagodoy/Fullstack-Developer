class CreateUserImportErrors < ActiveRecord::Migration[8.1]
  def change
    create_table :user_import_errors do |t|
      t.references :user_import, null: false, foreign_key: true
      t.integer :row_number, null: false
      t.text :message, null: false

      t.timestamps
    end

    add_index :user_import_errors,
      [ :user_import_id, :row_number ],
      unique: true

    add_check_constraint :user_import_errors,
      "row_number >= 2",
      name: "user_import_errors_valid_row_number"
  end
end
