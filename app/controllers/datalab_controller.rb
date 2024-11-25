class DatalabController < ApplicationController
  def index
    @chat_history = ChatHistory.for_user(current_user).recent
  end

  def chat
    @query = params[:query]
    @response = DatalabCommunicator.new(@query, current_user).process
    
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.append('chat_results', partial: 'results', locals: { response: @response }) }
      format.html
    end
  end
end