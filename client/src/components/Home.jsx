import React, { useRef, useState, useEffect } from 'react'
import './Home.css'
import book from '../assets/book.png'

const Home = () => {
  const formRef = useRef();
  const [form, setForm] = useState({
    question: "",
  });
  const [question, setQuestion] = useState('')
  const [answer, setAnswer] = useState('')
  const [audioSrcUrl, setAudioSrcUrl] = useState('')

  const fetchDefaultQuestion = async () => {
    const response = await fetch(`${import.meta.env.VITE_APP_API_URL}/questions`)
    const data = await response.json()
    setQuestion(data.default_question)
  }

  const handleChange = (e) => {
    const { target } = e
    const { name, value } = target

    setForm({
      ...form,
      [name]: value,
    })
    if (name === 'question') {
      setQuestion(value)
    }
  }

  const fetchAnswer = () => {
    try {
      fetch(`${import.meta.env.VITE_APP_API_URL}/questions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({ question })
      })
      .then(resp => resp.json())
      .then(data => {
        setAnswer(data.answer)
        setAudioSrcUrl(data.audio_src_url)
      })
      .catch(err => console.log(err))
    } catch (error) {
      console.log(error)
    }
  }

  const handleSubmit = (e) => {
    e.preventDefault()
    if (question === "") {
      alert("Please ask a question!")
      return false
    }
    fetchAnswer()
  }

  const handleRandomQuestion = () => {
    const options = [
      "How long it takes to write TME?", 
      "What is your definition of community?", 
      "How do I decide what kind of business I should start?"
    ];
    const random = ~~(Math.random() * options.length);
    setQuestion(options[random])
  }

  const handleAnotherQuestion = () => {
    setAnswer('')
    setQuestion('')
    setAudioSrcUrl('')
    formRef.current.reset()
  }

  useEffect(() => {
    fetchDefaultQuestion()
  }, [])

  return (
    <>
      <div className="header">
        <div className="logo">
          <a href="https://www.amazon.com/Minimalist-Entrepreneur-Great-Founders-More/dp/0593192397">
            <img src={book} loading="lazy" />
          </a>
          <h1>Ask My Book</h1>
        </div>
      </div>

      <div className="main">
        <p className="credits">This is an experiment in using AI to make my book's content more accessible. Ask a question and AI'll answer it in real-time:</p>

        <form ref={formRef} onSubmit={handleSubmit}>
          <textarea 
            name="question" 
            id="question" 
            value={question}
            onChange={handleChange}
          />

          <div className="buttons" style={{display: answer && "none"}}>
            <button type="submit" id="ask-button">Ask question</button>
            <button id="lucky-button" style={{background: "#eee", borderColor: "#eee", color: "#444"}} onClick={handleRandomQuestion}>I'm feeling lucky</button>
          </div>
        </form>

        {answer ? 
          <>
            <p id="answer-container" className="hidden showing"><strong>Answer:</strong><span id="answer">{answer}</span>
              <button id="ask-another-button" style={{display: "block"}} onClick={handleAnotherQuestion}>Ask another question</button>
            </p>
          </>
          : 
          <>
            <p id="answer-container" className="hidden"><strong>Answer:</strong> <span id="answer"></span> 
              <button id="ask-another-button" style={{display: "none"}} onClick={handleAnotherQuestion}>Ask another question</button>
            </p>
          </>
        }

        <audio id="audio" controls autoPlay>
          <source src={audioSrcUrl} type="audio/wav" />
        </audio>
      </div>
    </>
  )
}

export default Home