class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :email

      t.string :gender
      t.integer :posts_count

      t.boolean :admin
      t.boolean :moderator

      t.timestamps
    end
  end
end
