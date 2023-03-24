# Askmybook.com clone using Rails and React
This is a clone of Askmybook.com using Rails and React.

## Local start guide
Backend:
```
cd server
bundle install
```
Followed by script run for initial setup (assuming you have a pdf file named book.pdf in the server directory):
```
ruby scripts/pdf_to_pages_embeddings.rb --pdf book.pdf
```
Setup db if first time:
```
rails db:create
rails db:migrate
```
Start server:
```
rails s
```

Frontend:
```
cd client
npm install
npm run dev
```