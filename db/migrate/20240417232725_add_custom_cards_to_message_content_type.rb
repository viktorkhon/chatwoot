class AddCustomCardsToMessageContentType < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      DO $$
      BEGIN
        -- Check if the type exists
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'message_content_type') THEN
          -- Create the type with existing values from the Message model enum
          CREATE TYPE message_content_type AS ENUM (
            'text', 'input_text', 'input_textarea', 'input_email', 'input_select',
            'form', 'article', 'incoming_email', 'input_csat', 'integrations', 'sticker'
          );
        END IF;
        -- Add 'custom_cards' value
        BEGIN
          ALTER TYPE message_content_type ADD VALUE IF NOT EXISTS 'custom_cards';
        EXCEPTION WHEN duplicate_object THEN
          -- Value already exists, do nothing
        END;
      END
      $$;
    SQL
  end

  def down
    # There's no safe way to remove an enum value in PostgreSQL
    # This is a one-way migration
  end
end 