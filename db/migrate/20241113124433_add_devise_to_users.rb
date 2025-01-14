# frozen_string_literal: true

class AddDeviseToUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :role, default: "user"

      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Omniauthable
      t.string :provider
      t.string :uid

      ## API
      t.string :auth_token
    end

    add_index :users, :email,                unique: true
    add_index :users, :role
    add_index :users, :reset_password_token, unique: true
    add_index :users, [:provider, :uid]
    add_index :users, :auth_token
  end
end
