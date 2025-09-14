class CreateAccounts < ActiveRecord::Migration[7.2]
  def change
    # Rodauth accounts table
    create_table :accounts do |t|
      t.string :email, null: false, index: { unique: true }
      t.string :planning_center_id, index: { unique: true }
      t.string :name
      t.timestamps
    end
  end
end
