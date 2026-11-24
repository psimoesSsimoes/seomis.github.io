// Gallery lightbox: opens a gallery link's full-size image in a native
// <dialog>. Without JS (or <dialog> support) the link just opens the image.
(function () {
	'use strict';

	if (typeof HTMLDialogElement !== 'function') return;

	var dialog, img;

	function build() {
		dialog = document.createElement('dialog');
		dialog.className = 'lightbox';
		dialog.setAttribute('aria-label', 'Image viewer');
		dialog.innerHTML = '<button type="button" class="lightbox__close" aria-label="Close">&times;</button><img class="lightbox__img" alt="">';
		img = dialog.querySelector('img');
		dialog.addEventListener('click', function () { dialog.close(); });
		dialog.addEventListener('close', function () { img.removeAttribute('src'); });
		document.body.appendChild(dialog);
	}

	document.addEventListener('click', function (e) {
		if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
		var link = e.target.closest && e.target.closest('.gallery a');
		if (!link) return;
		e.preventDefault();
		if (!dialog) build();
		var thumb = link.querySelector('img');
		img.alt = thumb ? thumb.alt : '';
		img.src = link.href;
		dialog.showModal();
	});
}());
