class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :email

      t.integer :age
      t.integer :weight
      t.integer :height

      t.text :about

      t.references :ref
      t.references :specable, polymorphic: true

      t.string :state

      t.decimal :dec, precision: 10, scale: 2
      t.float :rating
      t.float :floato
      t.float :floatum

      t.boolean :admin
      t.boolean :moderator

      t.date :created_at
      t.datetime :updated_at
      t.datetime :last_logged_at
    end
  end
end
