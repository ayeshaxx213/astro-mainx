const loader = document.getElementById("loader");
const main = document.getElementById("main");

const progress = document.getElementById("progress");
const percent = document.getElementById("percent");

const continueButton =
  document.getElementById("continue");


/* =========================
   LOADING
========================= */

let value = 0;

const loadingTimer = setInterval(() => {

  const amount =
    Math.floor(Math.random() * 5) + 2;

  value += amount;

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

  progress.style.width =
    `${value}%`;

  percent.textContent =
    `${value}%`;

}, 90);


/* =========================
   CONTINUE BUTTON
========================= */

continueButton.addEventListener(
  "click",
  () => {

    alert(
      "astro.MAIN is ready."
    );

  }
);
