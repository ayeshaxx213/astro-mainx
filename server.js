const express = require("express");
const path = require("path");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static(__dirname));

const USERS = {
  astro: {
    key: process.env.ASTRO_KEY || "ASTRO-MAIN-TEST-KEY",
    userId: null
  }
};

app.get("/load/main", (req, res) => {
  res.sendFile(path.join(__dirname, "index.html"));
});

app.post("/load/main", (req, res) => {
  const { username, key, userId } = req.body || {};

  if (!username || !key || !userId) {
    return res.status(400).json({
      success: false,
      reason: "Missing username, key, or userId"
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

  if (user.userId === null) {
    user.userId = String(userId);
  }

  if (user.userId !== String(userId)) {
    return res.status(403).json({
      success: false,
      reason: "Key is already bound to another Roblox account"
    });
  }

  return res.json({
    success: true,
    username,
    message: "astro.MAIN authentication successful",
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
