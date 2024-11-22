class CreateChatHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :chat_histories do |t|
      t.references :user, null: false, foreign_key: true
      t.text :question
      t.text :answer
      t.text :sql_query

      t.timestamps
    end
  end
end 