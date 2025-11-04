class Channels::Whatsapp::BaileysConnectionCheckJob < ApplicationJob
  queue_as :low

  def perform(whatsapp_channel)
    Rails.logger.info '[BAILEYS JOB] ===== STARTING CONNECTION SETUP ====='
    Rails.logger.info "[BAILEYS JOB] Channel ID: #{whatsapp_channel.id}"
    Rails.logger.info "[BAILEYS JOB] Phone: #{whatsapp_channel.phone_number}"
    Rails.logger.info "[BAILEYS JOB] Inbox ID: #{whatsapp_channel.inbox&.id}"
    Rails.logger.info "[BAILEYS JOB] Callback webhook URL: #{whatsapp_channel.inbox&.callback_webhook_url}"

    whatsapp_channel.setup_channel_provider

    Rails.logger.info "[BAILEYS JOB] Connection setup API call completed for phone: #{whatsapp_channel.phone_number}"
    Rails.logger.info '[BAILEYS JOB] ===== CONNECTION SETUP COMPLETE ====='
  rescue StandardError => e
    Rails.logger.error '[BAILEYS JOB] ===== CONNECTION SETUP FAILED ====='
    Rails.logger.error "[BAILEYS JOB] Phone: #{whatsapp_channel.phone_number}"
    Rails.logger.error "[BAILEYS JOB] Error: #{e.message}"
    Rails.logger.error '[BAILEYS JOB] Backtrace:'
    Rails.logger.error e.backtrace.join("\n")
  end
end
