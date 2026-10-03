const express = require("express");
const path = require("path");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static(__dirname));

/*
  =========================
  ASTRO.MAIN USERS
  =========================
*/

const USERS = {
  astro: {
    key: "ASTRO-MAIN-TEST-KEY",
    hwid: null
  }
};


/*
  =========================
  MAIN WEBSITE
  =========================
*/

app.get("/load/main", (req, res) => {
  res.sendFile(path.join(__dirname, "index.html"));
});


/*
  =========================
  ASTRO.MAIN AUTH API
  =========================
*/

app.post("/load/main", (req, res) => {
  const { username, key, hwid } = req.body || {};

  if (!username || !key || !hwid) {
    return res.status(400).json({
      success: false,
      reason: "Missing username, key, or hwid"
    });
  }

  const user = USERS[username];

  if (!user) {
    return res.status(401).json({
      success: false,
      reason: "Invalid username"
    });
  }

  if (user.key !== key) {
    return res.status(401).json({
      success: false,
      reason: "Invalid key"
    });
  }

  /*
    First successful device becomes
    the user's current HWID.
  */
  if (user.hwid === null) {
    user.hwid = hwid;
  }

  if (user.hwid !== hwid) {
    return res.status(403).json({
      success: false,
      reason: "HWID mismatch"
    });
  }

  return res.json({
    success: true,
    username: username,
    message: "astro.MAIN authentication successful",
    config: {
      enabled: true
    }
  });
});


/*
  =========================
  404
  =========================
*/

app.use((req, res) => {
  res.status(404).send("404 - Page not found");
});


/*
  =========================
  START SERVER
  =========================
*/

app.listen(PORT, () => {
  console.log(`astro.MAIN running on port ${PORT}`);
});
