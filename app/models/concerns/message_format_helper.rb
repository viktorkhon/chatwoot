module MessageFormatHelper
  extend ActiveSupport::Concern

  # Ensures content_type is always returned as a string for consistent serialization
  def formatted_content_type
    content_type.to_s
  end
  
  # Patch for webhook_data to use formatted_content_type
  included do
    # Override the original webhook_data method to use our formatted_content_type method
    def webhook_data_with_formatting
      data = webhook_data_without_formatting
      data[:content_type] = formatted_content_type
      data
    end
    
    # Use alias_method to swap the methods
    alias_method :webhook_data_without_formatting, :webhook_data
    alias_method :webhook_data, :webhook_data_with_formatting
  end
end 