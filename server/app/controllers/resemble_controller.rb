require 'dotenv'
require 'resemble'

Dotenv.load

Resemble.api_key = ENV["RESEMBLE_API_KEY"]

class ResembleController < ApplicationController

    # POST /callback
    def callback
        # print params
        clip_id = params[:id]
        audio_src_url = params[:url]
        project_uuid = ENV["RESEMBLE_PROJECT_UUID"]
        clip_uuid = clip_id
        
        response = Resemble::V2::Clip.get(project_uuid, clip_uuid)
        clip = response['item']
        clip_title = clip['title']
        question = Question.find_by(question: clip_title)
        question.audio_src_url = audio_src_url
        question.save
        
        render json: { "message": "ok" }
    end
end
