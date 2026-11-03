// Adds a working Copy button to each code block that names a target with
// `data-copy-target`. The buttons ship hidden, so a browser without the
// Clipboard API, or without JavaScript, never shows a button that does nothing.
if (navigator.clipboard) {
  const status = document.getElementById("copy-status");

  for (const button of document.querySelectorAll("[data-copy-target]")) {
    const target = document.getElementById(button.dataset.copyTarget);
    if (!target) {
      continue;
    }

    let resetTimer;
    button.hidden = false;
    button.addEventListener("click", async () => {
      try {
        await navigator.clipboard.writeText(target.textContent);
        button.textContent = "Copied";
        status.textContent = "Commands copied to the clipboard.";
      } catch {
        button.textContent = "Copy failed";
        status.textContent = "Could not copy the commands.";
      }

      clearTimeout(resetTimer);
      resetTimer = setTimeout(() => {
        button.textContent = "Copy";
        status.textContent = "";
      }, 2000);
    });
  }
}
