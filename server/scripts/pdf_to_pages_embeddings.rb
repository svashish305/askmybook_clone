require 'dotenv'
require 'tokenizers'
require 'optparse'
require 'pdf-reader'
require 'matrix'
require 'openai'
require 'csv'

Dotenv.load

$openai_client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

$tokenizer = Tokenizers::Tokenizer.from_pretrained("gpt2")

def count_tokens(text)
    return $tokenizer.encode(text).tokens.length 
end

def extract_pages(page_text, index)
    if page_text.length == 0 
      return [] 
    end 

    content = page_text.split.join(" ") 
    # puts "page text: #{content}" 

    outputs = [["Page #{index}", content, count_tokens(content)+4]] 
end

options = {}
OptionParser.new do |opts|
  opts.on("--pdf FILENAME", "Name of PDF") do |pdf|
    options[:pdf] = pdf
  end
end.parse!
filename = options[:pdf]

reader = PDF::Reader.new(filename)

res = []
i = 1
reader.pages.each do |page|
    res += extract_pages(page.text, i)
    i += 1
end

page_headers = ["title", "content", "token"]
CSV.open("#{filename}.pages.csv", 'w') do |csv|
    csv << page_headers
    res.each_with_index do |row, i|
        csv << row
    end
end

def get_embedding(text, model)
    result=$openai_client.embeddings(parameters: {model:model, input:text})
    return result["data"][0]["embedding"]
end

def get_doc_embedding(text)
    return get_embedding(text, DOC_EMBEDDINGS_MODEL)
end


CSV.open("#{filename}.embeddings.csv", 'w') do |csv|
    csv<< ["title"] + (0..4095).to_a 
    reader.pages.each_with_index do |page, i|
        content = page.text.split.join(" ") 
        doc_embeddings = get_doc_embedding(content)
        csv << ["Page #{i+1}"] + doc_embeddings.map(&:to_s)
    end
end