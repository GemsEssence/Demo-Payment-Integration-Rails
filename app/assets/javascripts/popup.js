document.addEventListener('DOMContentLoaded', () => {
  const popup = document.getElementById('popup');
  const message = popup.dataset.popupMessage;

  if (message) {
    popup.innerHTML = `
      <div>
        ${message}
        <span class="close">&times;</span>
      </div>
    `;
    popup.classList.add('visible');

    // Close the popup when the close button is clicked
    popup.querySelector('.close').addEventListener('click', () => {
      popup.classList.remove('visible');
    });
  }
});
