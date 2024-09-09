const express = require('express')
const fetch = require('node-fetch');
const app = express()
const port = 3000

//https://dummyjson.com/products/1
app.get('/', async (req, res) => {
  const phpResponse = await fetch(`${process.env.PHP_SERVICE_API_BASE}:3000`)
  const dbResponse = await fetch(`${process.env.DB_SERVICE_API_BASE}:3000`)
  const phpData = await phpResponse.json();
  const dbData = await dbResponse.json();
  res.json({
    msg: "Hello world! (from web)",
    php:{
      url: process.env.PHP_SERVICE_API_BASE,
      data: phpData,
    },
    web:{
      url: process.env.DB_SERVICE_API_BASE,
      data: dbData,
    }
  })
})

app.get('/healthcheck', (req, res) => {
  res.send('Hello World!')
})

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
})