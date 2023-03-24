require 'dotenv'
require 'openai'
require 'resemble'
require 'matrix'
require 'csv'

Dotenv.load

Resemble.api_key = ENV["RESEMBLE_API_KEY"]
$openai_client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])


COMPLETIONS_MODEL = "text-davinci-003"
MODEL_NAME = "curie"
DOC_EMBEDDINGS_MODEL = "text-search-#{MODEL_NAME}-doc-001"
QUERY_EMBEDDINGS_MODEL = "text-search-#{MODEL_NAME}-query-001"
MAX_SECTION_LEN = 500
SEPARATOR = "\n* "
separator_len = 3

COMPLETIONS_API_PARAMS = {
    # We use temperature of 0.0 because it gives the most predictable, factual answer.
    "temperature": 0.0,
    "max_tokens": 150,
    "model": COMPLETIONS_MODEL,
}

class QuestionsController < ApplicationController
  before_action :set_question, only: %i[ show update destroy ]

  # GET /questions
  def index
    render json: { "default_question": "How long it takes to write TME?" }
  end

  def get_embedding(text, model)
    result=$openai_client.embeddings(parameters: {model:model, input:text})
    return result["data"][0]["embedding"]
  end

  def get_doc_embedding(text)
    return get_embedding(text, DOC_EMBEDDINGS_MODEL)
  end

  def get_query_embedding(text)
    return get_embedding(text, QUERY_EMBEDDINGS_MODEL)
  end

  def vector_similarity(x, y)
    return Vector.elements(x).inner_product(Vector.elements(y))
  end

  def order_document_sections_by_query_similarity(query, contexts)
    query_embedding = get_query_embedding(query)

    document_similarities = contexts.map do |doc_index, doc_embedding|
      [vector_similarity(query_embedding, doc_embedding), doc_index]
    end.sort_by { |similarity, _| -similarity }

    return document_similarities
  end

  def load_pages(fname)
    page = {}
  
    rows = CSV.read(fname)
    rows[1..].each_with_index do |row, i|
      page[row[0]] = row[1]
    end

    return page
  end

  def load_embeddings(fname)
    embeddings = {}
  
    rows = CSV.read(fname)
    rows[1..].each_with_index do |row, i|
      embeddings[row[0]] = row[1..].map(&:to_f)
    end

    return embeddings
  end

  def get_relevent_context(query, pages, context_embeddings)
    query_embeddings = get_query_embedding(query)
    
    vector_similarities = {}
    context_embeddings.each do |key, dat|
        vector_similarities[key] = vector_similarity(dat, query_embeddings)
    end
    vector_similarities = vector_similarities.sort_by{|k , v| v}.reverse.to_h

    space_left = MAX_SECTION_LEN
    res = ""

    vector_similarities.each do |key, _|
        ctx = pages[key]
        tokens = ctx.split.size

        res << SEPARATOR

        if space_left - tokens - SEPARATOR.size < 0
            res << ctx[..space_left]
            break
        else
            res << ctx
            space_left -= tokens
        end
    end

    return res
  end

  def construct_prompt(question, pages, context_embeddings)
    chosen_sections = get_relevent_context(question, pages, context_embeddings)

    header = """Sahil Lavingia is the founder and CEO of Gumroad, and the author of the book The Minimalist Entrepreneur (also known as TME). These are questions and answers by him. Please keep your answers to three sentences maximum, and speak in complete sentences. Stop speaking once your point is made.\n\nContext that may be useful, pulled from The Minimalist Entrepreneur:\n"""

    question_1 = "\n\n\nQ: How to choose what business to start?\n\nA: First off don't be in a rush. Look around you, see what problems you or other people are facing, and solve one of these problems if you see some overlap with your passions or skills. Or, even if you don't see an overlap, imagine how you would solve that problem anyway. Start super, super small."
    question_2 = "\n\n\nQ: Q: Should we start the business on the side first or should we put full effort right from the start?\n\nA:   Always on the side. Things start small and get bigger from there, and I don't know if I would ever “fully” commit to something unless I had some semblance of customer traction. Like with this product I'm working on now!"
    question_3 = "\n\n\nQ: Should we sell first than build or the other way around?\n\nA: I would recommend building first. Building will teach you a lot, and too many people use “sales” as an excuse to never learn essential skills like building. You can't sell a house you can't build!"
    question_4 = "\n\n\nQ: Andrew Chen has a book on this so maybe touché, but how should founders think about the cold start problem? Businesses are hard to start, and even harder to sustain but the latter is somewhat defined and structured, whereas the former is the vast unknown. Not sure if it's worthy, but this is something I have personally struggled with\n\nA: Hey, this is about my book, not his! I would solve the problem from a single player perspective first. For example, Gumroad is useful to a creator looking to sell something even if no one is currently using the platform. Usage helps, but it's not necessary."
    question_5 = "\n\n\nQ: What is one business that you think is ripe for a minimalist Entrepreneur innovation that isn't currently being pursued by your community?\n\nA: I would move to a place outside of a big city and watch how broken, slow, and non-automated most things are. And of course the big categories like housing, transportation, toys, healthcare, supply chain, food, and more, are constantly being upturned. Go to an industry conference and it's all they talk about! Any industry…"
    question_6 = "\n\n\nQ: How can you tell if your pricing is right? If you are leaving money on the table\n\nA: I would work backwards from the kind of success you want, how many customers you think you can reasonably get to within a few years, and then reverse engineer how much it should be priced to make that work."
    question_7 = "\n\n\nQ: Why is the name of your book 'the minimalist entrepreneur' \n\nA: I think more people should start businesses, and was hoping that making it feel more “minimal” would make it feel more achievable and lead more people to starting-the hardest step."
    question_8 = "\n\n\nQ: How long it takes to write TME\n\nA: About 500 hours over the course of a year or two, including book proposal and outline."
    question_9 = "\n\n\nQ: What is the best way to distribute surveys to test my product idea\n\nA: I use Google Forms and my email list / Twitter account. Works great and is 100% free."
    question_10 = "\n\n\nQ: How do you know, when to quit\n\nA: When I'm bored, no longer learning, not earning enough, getting physically unhealthy, etc… loads of reasons. I think the default should be to “quit” and work on something new. Few things are worth holding your attention for a long period of time."

    return (header + chosen_sections + question_1 + question_2 + question_3 + question_4 + question_5 + question_6 + question_7 + question_8 + question_9 + question_10 + "\n\n\nQ: " + question + "\n\nA: "), (chosen_sections)
  end

  def answer_query_with_context(query, pages, document_embeddings)
    prompt, context = construct_prompt(query, pages, document_embeddings)
    puts "===\n#{prompt}"

    response = $openai_client.completions(
      parameters: {
        prompt: prompt,
        **COMPLETIONS_API_PARAMS
      }
    )

    return response["choices"][0]["text"].strip, context
  end

  # POST /questions
  def create
    @question = params[:question]

    if !@question.end_with?("?")
      @question << "?"
    end

    previous_question = Question.find_by(question: @question) or nil
    audio_src_url = nil
    if previous_question
      audio_src_url = previous_question.audio_src_url or nil
    end

    if audio_src_url
      previous_question_audio_src_url = previous_question.audio_src_url ? previous_question.audio_src_url : ''
      print "previously asked and answered: " + previous_question.answer + " ( " + previous_question_audio_src_url + ")"
      previous_question.ask_count = previous_question.ask_count + 1
      previous_question.save
      render json: { "question": previous_question.question, "answer": previous_question.answer, "audio_src_url": previous_question.audio_src_url, "id": previous_question.id }
    end

    pages = load_pages('book.pdf.pages.csv')
    document_embeddings = load_embeddings('book.pdf.embeddings.csv')
    answer, context = answer_query_with_context(@question, pages, document_embeddings)

    project_uuid = ENV["RESEMBLE_PROJECT_UUID"]
    voice_uuid = ENV["RESEMBLE_VOICE_UUID"]
    callback_uri = ENV["RESEMBLE_CALLBACK_URI"]

    response = Resemble::V2::Clip.create_async(
      project_uuid,
      voice_uuid,
      callback_uri,
      answer,
      title: @question,
      sample_rate: nil,
      output_format: nil,
      precision: nil,
      include_timestamps: nil,
      is_public: nil,
      is_archived: nil,
    )

    question = Question.new(question: @question, answer: answer, context: context)
    question.save

    render json: { "question": question.question, "answer": answer, "audio_src_url": question.audio_src_url, "id": question.id }

  end
end
