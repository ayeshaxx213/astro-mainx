const express = require("express");
const path = require("path");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static(__dirname));

const USERS = {
  ayesha: {
    key: "ANGELBOUNDS-1WQ1-CHM7SM3P-WF",
    hwid: null
  }
};

// HTML loader
app.get("/load/main", (req, res) => {
  res.sendFile(path.join(__dirname, "index.html"));
});

// Authentication API
app.post("/load/main", (req, res) => {
  const { username, key, hwid } = req.body || {};

  if (!username || !key || !hwid) {
    return res.json({
      success: false,
      reason: "Missing username, key, or hwid"
    });
  }

  const user = USERS[username];

  if (!user) {
    return res.json({
      success: false,
      reason: "Invalid username"
    });
  }

  if (user.key !== key) {
    return res.json({
      success: false,
      reason: "Invalid key"
    });
  }

  // First device binds to the account.
  if (user.hwid === null) {
    user.hwid = hwid;
  }

  if (user.hwid !== hwid) {
    return res.json({
      success: false,
      reason: "HWID mismatch"
    });
  }

  return res.json({
    success: true,
    username,
    message: "Authentication successful",
    config: {
      enabled: true
    }
  });
});

app.use((req, res) => {
  res.status(404).send("404 - Page not found");
});

app.listen(PORT, () => {
  console.log(`astro.MAIN running on port ${PORT}`);
});
