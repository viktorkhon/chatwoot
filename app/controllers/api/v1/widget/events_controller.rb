class Api::V1::Widget::EventsController < Api::V1::Widget::BaseController
  include Events::Types

  def create
    Rails.logger.info "[Widget] 🔍 EVENT CREATE - Event: #{permitted_params[:name]}"
    Rails.logger.info "[Widget] 🔍 EVENT CREATE - User-Agent: #{request.headers['User-Agent']}"
    Rails.logger.info "[Widget] 🔍 EVENT CREATE - Referer: #{request.headers['Referer']}"
    Rails.logger.info "[Widget] 🔍 EVENT CREATE - X-Visitor-ID: #{request.headers['X-Visitor-ID']}"
    Rails.logger.info "[Widget] 🔍 EVENT CREATE - Request IP: #{request.remote_ip}"
    Rails.logger.info "[Widget] 🔍 EVENT CREATE - Contact Inbox: #{@contact_inbox&.source_id}"
    
    Rails.configuration.dispatcher.dispatch(permitted_params[:name], Time.zone.now, contact_inbox: @contact_inbox,
                                                                                    event_info: permitted_params[:event_info].to_h.merge(event_info))
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
