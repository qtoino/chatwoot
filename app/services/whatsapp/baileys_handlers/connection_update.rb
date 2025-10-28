module Whatsapp::BaileysHandlers::ConnectionUpdate
  include Whatsapp::BaileysHandlers::Helpers

  private

  def process_connection_update
    data = processed_params[:data]

    Rails.logger.info '[BAILEYS] Webhook received: connection.update'
    Rails.logger.info "[BAILEYS] Connection status: #{data[:connection]}"
    Rails.logger.info "[BAILEYS] Has QR code: #{data[:qrDataUrl].present?}"
    Rails.logger.info "[BAILEYS] Error: #{data[:error]}" if data[:error].present?

    # NOTE: `connection` values
    #   - `close`: Never opened, or closed and no longer able to send/receive messages
    #   - `connecting`: In the process of connecting, expecting QR code to be read
    #   - `reconnecting`: Connection has been established, but not open (i.e. device is being linked for the first time, or Baileys server restart)
    #   - `open`: Open and ready to send/receive messages
    inbox.channel.update_provider_connection!({
      connection: data[:connection] || inbox.channel.provider_connection['connection'],
      qr_data_url: data[:qrDataUrl] || nil,
      error: data[:error] ? I18n.t("errors.inboxes.channel.provider_connection.#{data[:error]}") : nil
    }.compact)

    Rails.logger.info '[BAILEYS] Provider connection updated successfully'
    Rails.logger.error "Baileys connection error: #{data[:error]}" if data[:error].present?
  end
end
