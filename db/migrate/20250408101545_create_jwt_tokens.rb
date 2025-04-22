class CreateJwtTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :jwt_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :jti
      t.datetime :exp

      t.timestamps
    end
    add_index :jwt_tokens, :jti
  end
end
