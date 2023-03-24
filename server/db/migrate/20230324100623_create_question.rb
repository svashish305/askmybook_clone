class CreateQuestion < ActiveRecord::Migration[7.0]
  def change
    create_table :questions do |t|
      t.text :question
      t.text :context
      t.text :answer
      t.integer :ask_count
      t.text :audio_src_url
      
      t.timestamps
    end
  end
end
