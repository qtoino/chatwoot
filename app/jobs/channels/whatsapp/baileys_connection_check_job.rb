class Channels::Whatsapp::BaileysConnectionCheckJob < ApplicationJob
  queue_as :low

  def perform(whatsapp_channel)
    Rails.logger.info "[BAILEYS] Setting up connection for phone: #{whatsapp_channel.phone_number}"
    whatsapp_channel.setup_channel_provider
    Rails.logger.info "[BAILEYS] Connection setup completed for phone: #{whatsapp_channel.phone_number}"
  rescue StandardError => e
    Rails.logger.error "[BAILEYS] Connection setup failed for phone: #{whatsapp_channel.phone_number} - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end
