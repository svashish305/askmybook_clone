class QuestionsController < ApplicationController
  before_action :set_question, only: %i[ show update destroy ]

  # GET /questions
  def index
    render json: { "default_question": "How long it takes to write TME?" }
  end

  # POST /questions
  def create
  end
end
