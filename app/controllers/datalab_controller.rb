class DatalabController < ApplicationController
  before_action :authenticate_user!
  def index
    if params[:reset_session]
      @chat_session_id = SecureRandom.uuid
      @chat_history = []
      return redirect_to datalab_index_path(session_id: @chat_session_id)
    end

    @chat_session_id = params[:session_id] || ChatHistory.for_user(current_user).recent.first&.session_id || SecureRandom.uuid
    @chat_history = ChatHistory.for_user(current_user).where(session_id: @chat_session_id).order(:created_at)

    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".datalab.titles.index")]
  end

  def chat
    chat_session_id = params[:session_id] || SecureRandom.uuid
    query = params[:query]
    @response = DatalabCommunicator.new(query, current_user, chat_session_id).process
    chat = ChatHistory.where(session_id: chat_session_id).order(:created_at).last

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.append('chats', partial: 'chat', locals: { chat: chat }) }
      format.html
    end
  end

  def chat_history
    @chat_history = ChatHistory.for_user(current_user)
                               .select('DISTINCT ON (session_id) *')
                               .order(:session_id, :created_at)

    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".datalab.titles.index"), datalab_index_path]
    @breadcrumbs << [I18n.t(".datalab.titles.chat_history")]
  end

  def chat_history_details
    @chat_history = ChatHistory.for_user(current_user).where(session_id: params[:session_id]).order(:created_at)

    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".datalab.titles.index"), datalab_index_path]
    @breadcrumbs << [I18n.t(".datalab.titles.chat_history"), chat_history_datalab_index_path]
    @breadcrumbs << [I18n.t(".datalab.titles.chat_history_details")]
  end
end
