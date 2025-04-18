class AddCardsToMessageContentType < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
      ALTER TYPE message_content_type ADD VALUE IF NOT EXISTS 'cards';
    SQL
  end

  def down
    # Cannot remove enum values in PostgreSQL
    # This is a no-op
  end
end 