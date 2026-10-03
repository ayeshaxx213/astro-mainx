const express = require("express");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

const USERS = {
  astro: {
    key: "ASTRO-MAIN-TEST-KEY",
    hwid: null
  }
};

app.get("/load/main", (req, res) => {
  res.sendFile(__dirname + "/index.html");
});

app.post("/api/check", (req, res) => {
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

  // First successful device gets bound.
  if (user.hwid === null) {
    user.hwid = String(hwid);
  }

  if (user.hwid !== String(hwid)) {
    return res.json({
      success: false,
      reason: "HWID mismatch"
    });
  }

  return res.json({
    success: true,
    username,
    message: "astro.MAIN HWID check passed"
  });
});

app.listen(PORT, () => {
  console.log(`astro.MAIN running on port ${PORT}`);
});
