const express = require("express");
const path = require("path");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static(__dirname));

/*
==================================================
ASTRO.MAIN CONFIG
==================================================
*/

const ASTRO_KEY =
  process.env.ASTRO_KEY || "ASTRO-MAIN-TEST-KEY";

/*
  Keys are bound to Roblox UserIds after
  the first successful authentication.

  Example:
  astro: {
    key: "ASTRO-MAIN-TEST-KEY",
    userId: null
  }
*/

const USERS = {
  astro: {
    key: ASTRO_KEY,
    userId: null
  }
};


/*
==================================================
MAIN WEBSITE
==================================================
*/

app.get("/load/main", (req, res) => {
  res.sendFile(
    path.join(__dirname, "index.html")
  );
});


/*
==================================================
AUTHENTICATION API
==================================================
*/

app.post("/load/main", (req, res) => {
  try {
    const {
      username,
      key,
      userId
    } = req.body || {};

    /*
    ------------------------------------------
    Validate request
    ------------------------------------------
    */

    if (!username || !key || !userId) {
      return res.status(400).json({
        success: false,
        reason: "Missing username, key, or userId"
      });
    }

    /*
    ------------------------------------------
    Find account
    ------------------------------------------
    */

    const user = USERS[username];

    if (!user) {
      return res.status(401).json({
        success: false,
        reason: "Invalid username"
      });
    }

    /*
    ------------------------------------------
    Check key
    ------------------------------------------
    */

    if (user.key !== key) {
      return res.status(401).json({
        success: false,
        reason: "Invalid key"
      });
    }

    const incomingUserId =
      String(userId);

    /*
    ------------------------------------------
    First successful login:
    bind the key to this Roblox account
    ------------------------------------------
    */

    if (user.userId === null) {
      user.userId = incomingUserId;
    }

    /*
    ------------------------------------------
    Reject another account
    ------------------------------------------
    */

    if (user.userId !== incomingUserId) {
      return res.status(403).json({
        success: false,
        reason:
          "Key is already bound to another Roblox account"
      });
    }

    /*
    ------------------------------------------
    Success
    ------------------------------------------
    */

    return res.status(200).json({
      success: true,
      username,
      message:
        "astro.MAIN authentication successful",
      config: {
        enabled: true
      }
    });

  } catch (error) {

    console.error(
      "Authentication error:",
      error
    );

    return res.status(500).json({
      success: false,
      reason: "Internal server error"
    });
  }
});


/*
==================================================
HEALTH CHECK
==================================================
*/

app.get("/api/status", (req, res) => {
  res.json({
    success: true,
    name: "astro.MAIN",
    status: "online"
  });
});


/*
==================================================
404
==================================================
*/

app.use((req, res) => {
  res.status(404).send(
    "404 - Page not found"
  );
});


/*
==================================================
START SERVER
==================================================
*/

app.listen(PORT, () => {
  console.log(
    `astro.MAIN running on port ${PORT}`
  );
});
