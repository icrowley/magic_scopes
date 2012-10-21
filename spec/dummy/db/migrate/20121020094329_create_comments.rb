class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.string :title
      t.text :content

      t.references :user_id
      t.references :parent_id
      t.references :commentable, polymorphic: true

      t.string :state
      t.string :likes_state

      t.boolean :featured
      t.boolean :hidden
      t.boolean :best

      t.timestamps
    end
  end
end