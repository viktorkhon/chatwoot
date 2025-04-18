class AddCustomCardsContentType < ActiveRecord::Migration[7.0]
  def up
    # Add custom_cards to the content_type enum
    execute <<-SQL
      ALTER TYPE message_content_type ADD VALUE IF NOT EXISTS 'custom_cards';
    SQL
  end

  def down
    # Note: PostgreSQL doesn't support removing enum values
    # This is a no-op as we can't safely remove the enum value
  end
end 