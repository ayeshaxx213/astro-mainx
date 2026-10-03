const loader = document.getElementById("loader");
const main = document.getElementById("main");
const progress = document.getElementById("progress");
const percent = document.getElementById("percent");
const continueButton = document.getElementById("continue");

let value = 0;

const timer = setInterval(() => {
  value += Math.floor(Math.random() * 5) + 2;

  if (value >= 100) {
    value = 100;
    clearInterval(timer);

    setTimeout(() => {
      loader.classList.add("hidden");
      main.classList.remove("hidden");
    }, 350);
  }

  progress.style.width = `${value}%`;
  percent.textContent = `${value}%`;
}, 90);

continueButton.addEventListener("click", () => {
  alert("astro.MAIN is ready.");
});