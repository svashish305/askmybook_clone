require 'dotenv'
require 'tokenizers'
require 'optparse'
require 'pdf-reader'
require 'matrix'
require 'csv'

Dotenv.load 

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