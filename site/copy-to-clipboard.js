/**
 * Copies the text of the element named by the `for` attribute when its
 * button is clicked:
 *
 *   <copy-to-clipboard for="commands">
 *     <button type="button" hidden>Copy</button>
 *     <span class="visually-hidden" role="status"></span>
 *   </copy-to-clipboard>
 *
 * The button ships hidden and only appears where the Clipboard API exists,
 * so a browser without it, or without JavaScript, never shows a button that
 * does nothing. The status element tells screen reader users what happened.
 */
export class CopyToClipboard extends HTMLElement {
  #resetTimer;

  connectedCallback() {
    if (navigator.clipboard) {
      this.addEventListeners();
    }
  }

  addEventListeners() {
    const button = this.querySelector("button");
    if (!button || !this.#source) {
      return;
    }

    button.hidden = false;
    // The handler is the same function on every call, so the browser ignores
    // a second registration if the element is connected again.
    button.addEventListener("click", this.#copy);
  }

  get #source() {
    return document.getElementById(this.getAttribute("for"));
  }

  #copy = async (event) => {
    const button = event.currentTarget;
    const status = this.querySelector('[role="status"]');

    try {
      await navigator.clipboard.writeText(this.#source.textContent);
      this.#report(button, status, "Copied", "Copied to the clipboard.");
    } catch {
      this.#report(button, status, "Copy failed", "Could not copy to the clipboard.");
    }

    clearTimeout(this.#resetTimer);
    this.#resetTimer = setTimeout(() => {
      this.#report(button, status, "Copy", "");
    }, 2000);
  };

  #report(button, status, label, message) {
    button.textContent = label;
    if (status) {
      status.textContent = message;
    }
  }
}

// Defining the same name twice throws, so a second copy of this module on the
// page leaves the first registration in place.
if (!customElements.get("copy-to-clipboard")) {
  customElements.define("copy-to-clipboard", CopyToClipboard);
}
