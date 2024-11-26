class CreateChatHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :chat_histories do |t|
      t.references :user, null: false, foreign_key: true
      t.string :session_id
      t.text :question
      t.text :sql_query
      t.jsonb :answer, default: []

      t.timestamps
    end
  end
end 