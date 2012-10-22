class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.string :title
      t.text :content

      t.references :user
      t.references :next
      t.references :commentable, polymorphic: true

      t.string :state
      t.string :likes_state

      t.float :rating
      t.integer :likes_num

      t.boolean :featured
      t.boolean :hidden
      t.boolean :best

      t.timestamps
    end
  end
end