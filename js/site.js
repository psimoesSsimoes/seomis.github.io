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


// Reading progress in the bar, on posts: 0% at the top of the page, 100%
// once the end of the article is on screen.
(function () {
	'use strict';

	var out = document.querySelector('[data-progress]');
	var article = document.querySelector('article .window__body');
	if (!out || !article) return;

	var queued = false;

	function update() {
		queued = false;
		var scrolled = window.pageYOffset;
		var end = article.getBoundingClientRect().bottom + scrolled - window.innerHeight;
		var done = end > 0 ? scrolled / end : 1;
		out.textContent = Math.round(Math.max(0, Math.min(1, done)) * 100) + '%';
	}

	function queue() {
		if (queued) return;
		queued = true;
		window.requestAnimationFrame(update);
	}

	window.addEventListener('scroll', queue, { passive: true });
	window.addEventListener('resize', queue);
	update();
	out.hidden = false;
}());


// Theme toggle in the bar. The system setting decides until the visitor
// picks a theme; the choice is kept in localStorage and applied in <head>.
(function () {
	'use strict';

	var button = document.querySelector('[data-theme-toggle]');
	if (!button || !window.matchMedia) return;

	var root = document.documentElement;
	var system = window.matchMedia('(prefers-color-scheme: dark)');

	function current() {
		return root.getAttribute('data-theme') || (system.matches ? 'dark' : 'light');
	}

	// The button names the theme it switches to.
	function label() {
		var other = current() === 'dark' ? 'light' : 'dark';
		button.textContent = other;
		button.setAttribute('aria-label', 'Switch to ' + other + ' theme');
	}

	button.addEventListener('click', function () {
		var next = current() === 'dark' ? 'light' : 'dark';
		root.setAttribute('data-theme', next);
		try { localStorage.setItem('theme', next); } catch (e) {}
		label();
	});

	if (system.addEventListener) system.addEventListener('change', label);

	label();
	button.hidden = false;
}());


// Richer code colours. Rouge tags most identifiers as plain names (.n),
// so tell them apart by what follows: "name(" is a call, "name:" a field,
// "name{" a type literal. Only adds classes; without JS the code is
// still highlighted, just with fewer colours.
(function () {
	'use strict';

	var names = document.querySelectorAll('pre.highlight .n, pre.highlight .nx');

	for (var i = 0; i < names.length; i++) {
		var name = names[i];
		var next = name.nextSibling;
		// Skip when whitespace sits between the name and the next token.
		if (!next || next.nodeType !== 1) continue;

		var text = next.textContent;
		if (next.className === 'p' && text.charAt(0) === '(') {
			name.classList.add('nf');
		} else if (next.className === 'p' && text.charAt(0) === '{') {
			name.classList.add('nc');
		} else if (next.className === 'o' && text === ':') {
			name.classList.add('na');
		}
	}
}());
