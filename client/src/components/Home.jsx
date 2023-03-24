import React, { useRef, useState, useEffect } from 'react'
import './Home.css'
import book from '../assets/book.png'

const Home = () => {


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

      
    </>
  )
}

export default Home