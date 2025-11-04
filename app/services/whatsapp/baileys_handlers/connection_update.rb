module Whatsapp::BaileysHandlers::ConnectionUpdate
  include Whatsapp::BaileysHandlers::Helpers

  private

  def process_connection_update
    data = processed_params[:data]

    Rails.logger.info '[BAILEYS] ===== WEBHOOK RECEIVED: connection.update ====='
    Rails.logger.info "[BAILEYS] Inbox ID: #{inbox.id}"
    Rails.logger.info "[BAILEYS] Channel ID: #{inbox.channel.id}"
    Rails.logger.info "[BAILEYS] Phone: #{inbox.channel.phone_number}"
    Rails.logger.info "[BAILEYS] Connection status: #{data[:connection]}"
    Rails.logger.info "[BAILEYS] Has QR code: #{data[:qrDataUrl].present?}"
    Rails.logger.info "[BAILEYS] QR data URL length: #{data[:qrDataUrl]&.length}" if data[:qrDataUrl].present?
    Rails.logger.info "[BAILEYS] Error: #{data[:error]}" if data[:error].present?
    Rails.logger.info "[BAILEYS] Full webhook data: #{data.inspect}"

    # NOTE: `connection` values
    #   - `close`: Never opened, or closed and no longer able to send/receive messages
    #   - `connecting`: In the process of connecting, expecting QR code to be read
    #   - `reconnecting`: Connection has been established, but not open (i.e. device is being linked for the first time, or Baileys server restart)
    #   - `open`: Open and ready to send/receive messages
    update_data = {
      connection: data[:connection] || inbox.channel.provider_connection['connection'],
      qr_data_url: data[:qrDataUrl] || nil,
      error: data[:error] ? I18n.t("errors.inboxes.channel.provider_connection.#{data[:error]}") : nil
    }.compact

    Rails.logger.info "[BAILEYS] Updating provider_connection with: #{update_data.inspect}"
    inbox.channel.update_provider_connection!(update_data)

    Rails.logger.info '[BAILEYS] Provider connection updated successfully'
    Rails.logger.info "[BAILEYS] Current provider_connection in DB: #{inbox.channel.reload.provider_connection.inspect}"
    Rails.logger.error "Baileys connection error: #{data[:error]}" if data[:error].present?
    Rails.logger.info '[BAILEYS] ===== WEBHOOK PROCESSING COMPLETE ====='
  end
end
