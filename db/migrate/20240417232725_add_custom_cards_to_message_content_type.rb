class AddCustomCardsToMessageContentType < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      ALTER TYPE message_content_type ADD VALUE IF NOT EXISTS 'custom_cards';
    SQL
  end

  def down
    # There's no safe way to remove an enum value in PostgreSQL
    # This is a one-way migration
  end
end 