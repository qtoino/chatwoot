class Conversations::TypingStatusManager
  include Events::Types

  attr_reader :conversation, :user, :params

  def initialize(conversation, user, params)
    @conversation = conversation
    @user = user
    @params = params
  end

  def trigger_typing_event(event, is_private)
    user = @user.presence || @resource
    Rails.logger.info '[TYPING STATUS] ===== TRIGGERING EVENT ====='
    Rails.logger.info "[TYPING STATUS] Event type: #{event}"
    Rails.logger.info "[TYPING STATUS] User: #{user.inspect}"
    Rails.logger.info "[TYPING STATUS] Is private: #{is_private}"
    Rails.logger.info "[TYPING STATUS] Conversation ID: #{@conversation.id}"
    Rails.configuration.dispatcher.dispatch(event, Time.zone.now, conversation: @conversation, user: user, is_private: is_private)
    Rails.logger.info '[TYPING STATUS] ===== EVENT DISPATCHED ====='
  end

  def toggle_typing_status
    Rails.logger.info '[TYPING STATUS] ===== TYPING STATUS MANAGER START ====='
    Rails.logger.info "[TYPING STATUS] typing_status param: #{params[:typing_status]}"

    case params[:typing_status]
    when 'on'
      Rails.logger.info '[TYPING STATUS] Case: ON - triggering CONVERSATION_TYPING_ON'
      trigger_typing_event(CONVERSATION_TYPING_ON, params[:is_private])
    when 'recording'
      Rails.logger.info '[TYPING STATUS] Case: RECORDING - triggering CONVERSATION_RECORDING'
      trigger_typing_event(CONVERSATION_RECORDING, params[:is_private])
    when 'off'
      Rails.logger.info '[TYPING STATUS] Case: OFF - triggering CONVERSATION_TYPING_OFF'
      trigger_typing_event(CONVERSATION_TYPING_OFF, params[:is_private])
    else
      Rails.logger.warn "[TYPING STATUS] Unknown typing_status value: #{params[:typing_status]}"
    end

    Rails.logger.info '[TYPING STATUS] ===== TYPING STATUS MANAGER END ====='
    # Return the head :ok response from the controller
  end
end
