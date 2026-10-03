const loader = document.getElementById("loader");
const main = document.getElementById("main");

const progress = document.getElementById("progress");
const percent = document.getElementById("percent");

const continueButton = document.getElementById("continue");

let value = 0;

const loadingTimer = setInterval(() => {
  value += Math.floor(Math.random() * 5) + 2;

  if (value >= 100) {
    value = 100;
    clearInterval(loadingTimer);

    progress.style.width = "100%";
    percent.textContent = "100%";

    setTimeout(() => {
      loader.classList.add("hidden");
      main.classList.remove("hidden");
    }, 400);

    return;
  }

  progress.style.width = `${value}%`;
  percent.textContent = `${value}%`;
}, 90);

continueButton.addEventListener("click", async () => {
  try {
    const response = await fetch("/load/main", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        username: "astro",
        key: "ASTRO-MAIN-TEST-KEY",
        hwid: "website-test-device"
      })
    });

    const data = await response.json();

    if (!data.success) {
      alert(`Authentication failed: ${data.reason}`);
      return;
    }

    alert("astro.MAIN authentication successful");
  } catch (error) {
    alert("Could not reach astro.MAIN server.");
    console.error(error);
  }
});
