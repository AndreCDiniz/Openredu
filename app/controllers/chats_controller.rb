class ChatsController < ApplicationController
	def send_message
		recipient = User.find(params['contact_id'])

    authorize! :send_message, recipient

    text = params['text']

    conversation = Conversation.between(
      current_user.id,
      recipient.id
    ).first

    if conversation.blank?
      conversation = Conversation.create(
        sender: current_user,
        recipient: recipient
      )
    end

    message = conversation.chat_messages.build(user: current_user, body: text)

    if message.valid?
      message.save
      sender("/#{recipient.user_channel}", message.format_message)
    end

		head :ok, content_type: "text/html"
	end

  def last_messages_with
    recipient = User.find(params['contact_id'])

    authorize! :send_message, recipient

    conversation = Conversation.between(
      current_user.id,
      recipient.id
    ).first

    if conversation.blank?
      render json: []
    else
      render json: conversation.chat_messages.map {|x| x.format_message }
    end
  end

  def online
    authorize! :online, :chats
    sender(
      "/online/confirm",
      {
        current_user.user_channel => current_user.id
      }
    )
    head :ok, content_type: "text/html"
  end

  protected

  	def sender(channel, msg)
      message = {:channel => channel, :data => msg.merge(:authToken => 'openredu')}
      begin
        uri = URI.parse("http://localhost:9292/faye")
        Net::HTTP.post_form(uri, :message => message.to_json)
      rescue Exception => e
      end
    end
end