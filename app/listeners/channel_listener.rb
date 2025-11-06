class ChannelListener < BaseListener
  def conversation_typing_on(event)
    Rails.logger.info '[TYPING STATUS] ===== CHANNEL LISTENER: conversation_typing_on ====='
    handle_typing_event(event)
  end

  def conversation_recording(event)
    Rails.logger.info '[TYPING STATUS] ===== CHANNEL LISTENER: conversation_recording ====='
    handle_typing_event(event)
  end

  def conversation_typing_off(event)
    Rails.logger.info '[TYPING STATUS] ===== CHANNEL LISTENER: conversation_typing_off ====='
    handle_typing_event(event)
  end

  def conversation_unread(event)
    conversation = event.data[:conversation]
    channel = conversation.inbox.channel
    return unless channel.respond_to?(:unread_conversation)

    channel.unread_conversation(conversation)
  end

  def account_presence_updated(event)
    account_id, user_id, status = event.data.values_at(:account_id, :user_id, :status)
    account = Account.find(account_id)

    account.inboxes.joins(:inbox_members).where(inbox_members: { user_id: user_id }).find_each do |inbox|
      next unless inbox.channel.respond_to?(:update_presence)

      inbox.channel.update_presence(status)
    end
  end

  def messages_read(event)
    conversation, last_seen_at = event.data.values_at(:conversation, :last_seen_at)

    channel = conversation.inbox.channel
    return unless channel.respond_to?(:read_messages)

    messages = conversation.messages.where(message_type: :incoming).where.not(status: :read)

    messages = messages.where('updated_at > ?', last_seen_at) if last_seen_at.present?

    channel.read_messages(messages, conversation: conversation) if messages.any?
  end

  private

  def handle_typing_event(event)
    Rails.logger.info '[TYPING STATUS] ===== CHANNEL LISTENER: handle_typing_event START ====='
    is_private, conversation = event.data.values_at(:is_private, :conversation)
    Rails.logger.info "[TYPING STATUS] Event name: #{event.name}"
    Rails.logger.info "[TYPING STATUS] Is private: #{is_private}"
    Rails.logger.info "[TYPING STATUS] Conversation ID: #{conversation&.id}"

    if is_private
      Rails.logger.info '[TYPING STATUS] Event is private, skipping channel notification'
      return
    end

    channel = conversation.inbox.channel
    Rails.logger.info "[TYPING STATUS] Channel type: #{channel.class.name}"
    Rails.logger.info "[TYPING STATUS] Channel ID: #{channel.id}"
    Rails.logger.info "[TYPING STATUS] Channel responds to toggle_typing_status? #{channel.respond_to?(:toggle_typing_status)}"

    unless channel.respond_to?(:toggle_typing_status)
      Rails.logger.warn '[TYPING STATUS] Channel does not support toggle_typing_status, skipping'
      return
    end

    Rails.logger.info '[TYPING STATUS] Calling channel.toggle_typing_status'
    channel.toggle_typing_status(event.name, conversation: conversation)
    Rails.logger.info '[TYPING STATUS] ===== CHANNEL LISTENER: handle_typing_event END ====='
  rescue StandardError => e
    Rails.logger.error '[TYPING STATUS] ===== ERROR IN CHANNEL LISTENER ====='
    Rails.logger.error "[TYPING STATUS] Error: #{e.message}"
    Rails.logger.error "[TYPING STATUS] Backtrace: #{e.backtrace.join("\n")}"
  end
end
