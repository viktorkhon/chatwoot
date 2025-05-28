class Api::V1::Widget::EventsController < Api::V1::Widget::BaseController
  include Events::Types

  def create
    Rails.logger.info "[CONVERSATION DEBUG] 🔍 EVENT CREATE - Event: #{permitted_params[:name]}"
    Rails.logger.info "[CONVERSATION DEBUG] 🔍 EVENT CREATE - Event Info: #{permitted_params[:event_info].inspect}"
    Rails.logger.info "[CONVERSATION DEBUG] 🔍 EVENT CREATE - Caller: #{caller[0..2].join(', ')}"
    
    if permitted_params[:name] == 'webwidget.triggered'
      Rails.logger.warn "[CONVERSATION DEBUG] 🔍 EVENT CREATE - ⚠️ WEBWIDGET.TRIGGERED EVENT DETECTED!"
      Rails.logger.warn "[CONVERSATION DEBUG] 🔍 EVENT CREATE - ⚠️ This should only happen when widget is first opened"
      Rails.logger.warn "[CONVERSATION DEBUG] 🔍 EVENT CREATE - ⚠️ If this appears during message_update, it's a bug!"
    end
    
    Rails.configuration.dispatcher.dispatch(permitted_params[:name], Time.zone.now, contact_inbox: @contact_inbox,
                                                                                    event_info: permitted_params[:event_info].to_h.merge(event_info))
    
    Rails.logger.info "[CONVERSATION DEBUG] 🔍 EVENT CREATE COMPLETED - Event: #{permitted_params[:name]}"
    head :no_content
  end

  private

  def event_info
    {
      widget_language: params[:locale],
      browser_language: browser.accept_language.first&.code,
      browser: browser_params
    }
  end

  def permitted_params
    params.permit(:name, :website_token, event_info: [:page_url, :page_title, :referer, :initiated_at, browser_info: {}, page_info: {}, browser: {}])
  end
end
