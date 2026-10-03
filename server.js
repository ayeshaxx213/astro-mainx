const express = require("express");
const path = require("path");

const app = express();

const PORT =
  process.env.PORT || 3000;


/* =========================
   STATIC FILES
========================= */

app.use(
  express.static(__dirname)
);


/* =========================
   ROOT
========================= */

app.get("/", (req, res) => {

  res.redirect("/load/main");

});


/* =========================
   MAIN LOADER
========================= */

app.get("/load/main", (req, res) => {

  res.sendFile(
    path.join(
      __dirname,
      "index.html"
    )
  );

});


/* =========================
   404
========================= */

app.use((req, res) => {

  res
    .status(404)
    .send("404 - Page not found");

});


/* =========================
   START SERVER
========================= */

app.listen(
  PORT,
  () => {

    console.log(
      `astro.MAIN running on port ${PORT}`
    );

  }
);
