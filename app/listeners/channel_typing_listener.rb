class ChannelTypingListener < BaseListener
  def conversation_typing_on(event)
    handle_typing_status(Events::Types::CONVERSATION_TYPING_ON, event)
  end

  def conversation_typing_off(event)
    handle_typing_status(Events::Types::CONVERSATION_TYPING_OFF, event)
  end

  private

  def handle_typing_status(typing_status, event)
    conversation = event.data[:conversation]
    channel = conversation.inbox.channel

    # Only handle channels that support typing status
    return unless channel.respond_to?(:toggle_typing_status)

    channel.toggle_typing_status(typing_status, conversation: conversation)
  rescue StandardError => e
    Rails.logger.error "Failed to toggle typing status on channel: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end
