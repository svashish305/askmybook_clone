class UpdateQuestionSchema < ActiveRecord::Migration[7.0]
  def change
    change_table :questions do |t|
      t.change(:question, :string, limit: 140)
      t.change(:context, :string, default: '', null: true)
      t.change(:answer, :string, limit: 1000, default: '', null: true)
      t.change(:ask_count, :integer, default: 1)
      t.change(:audio_src_url, :string, limit: 255, default: '', null: true)
    end
  end
end
