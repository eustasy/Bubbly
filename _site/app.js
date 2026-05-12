// app.js — vanilla interactivity for the Bubbly landing page.

(function () {
	'use strict';

	// ── Terminal templates ────────────────────────────────────────────────
	// `{pkg}` → distro install line. `{d}` → user-supplied domain (defaults to example.com).
	const TEMPLATES = {
		install: 'cd &&\n{pkg} &&\ngit clone https://github.com/eustasy/Bubbly',
		tickets: '~/Bubbly/bubbly_generate-tickets.sh',
		copy:    '~/Bubbly/bubbly_copy-configs.sh',
		verifyA: 'sudo cp /etc/nginx/sites-available/bubbly_verify.conf /etc/nginx/sites-available/{d}.conf\nsudo nano /etc/nginx/sites-available/{d}.conf',
		verifyB: 'sudo ln -s /etc/nginx/sites-available/{d}.conf /etc/nginx/sites-enabled/{d}.conf\nsudo nginx -t && sudo service nginx reload',
		renew:   '~/Bubbly/bubbly_renew-ssl.sh -d {d} -d www.{d}',
		swap:    'sudo rm /etc/nginx/sites-available/{d}.conf\nsudo cp /etc/nginx/sites-available/bubbly_live.conf /etc/nginx/sites-available/{d}.conf\nsudo nano /etc/nginx/sites-available/{d}.conf\nsudo nginx -t && sudo service nginx reload'
	};

	let currentDomain = 'example.com';
	let currentPkg = 'sudo apt install git certbot';

	function fill(tpl) {
		return tpl.split('{pkg}').join(currentPkg).split('{d}').join(currentDomain);
	}

	function renderTermBody(pre, text) {
		const lines = text.replace(/\n+$/, '').split('\n');
		const frag = document.createDocumentFragment();
		for (let i = 0; i < lines.length; i++) {
			const l = lines[i];
			const isComment = /^\s*#/.test(l);
			const prev = i > 0 ? lines[i - 1] : '';
			const isContinuation = i > 0 && /(\s&&\s*|\\)$/.test(prev);
			const lineEl = document.createElement('div');
			lineEl.className = 'b-term-line' + (isComment ? ' c' : '');
			const promptEl = document.createElement('span');
			promptEl.className = 'b-term-prompt';
			promptEl.textContent = isComment ? '#' : (isContinuation ? ' ' : '$');
			const textEl = document.createElement('span');
			textEl.className = 'b-term-text';
			textEl.textContent = l.replace(/^\s*#\s?/, '');
			lineEl.appendChild(promptEl);
			lineEl.appendChild(textEl);
			frag.appendChild(lineEl);
		}
		pre.replaceChildren(frag);
	}

	function renderAllTerms() {
		document.querySelectorAll('.b-term[data-term]').forEach(function (block) {
			const key = block.getAttribute('data-term');
			const tpl = TEMPLATES[key];
			if (!tpl) return;
			const text = fill(tpl);
			block.dataset.text = text;
			const body = block.querySelector('.b-term-body');
			if (body) renderTermBody(body, text);
		});
	}

	// ── Domain input ──────────────────────────────────────────────────────
	function initDomain() {
		const wrap = document.getElementById('b-domain');
		const input = document.getElementById('b-dom-input');
		const clear = document.getElementById('b-domain-clear');
		if (!input) return;
		const echo = document.querySelector('[data-domain]');

		function update() {
			const v = (input.value || '').trim();
			currentDomain = v || 'example.com';
			if (echo) echo.textContent = currentDomain;
			if (wrap) wrap.setAttribute('data-filled', v ? '1' : '0');
			renderAllTerms();
		}

		input.addEventListener('input', update);
		if (clear) clear.addEventListener('click', function () {
			input.value = '';
			update();
			input.focus();
		});
	}

	// ── Distro tabs ───────────────────────────────────────────────────────
	function initDistroTabs() {
		const tabs = Array.from(document.querySelectorAll('.b-distro-tab'));
		tabs.forEach(function (tab) {
			tab.addEventListener('click', function () {
				tabs.forEach(function (t) {
					t.classList.toggle('on', t === tab);
					t.setAttribute('aria-selected', t === tab ? 'true' : 'false');
				});
				currentPkg = tab.getAttribute('data-pkg') || currentPkg;
				renderAllTerms();
			});
		});
	}

	// ── Copy-to-clipboard ─────────────────────────────────────────────────
	function initCopyButtons() {
		document.querySelectorAll('.b-term .b-copy').forEach(function (btn) {
			const block = btn.closest('.b-term');
			btn.addEventListener('click', async function (e) {
				e.preventDefault();
				const text = (block && block.dataset.text) || '';
				const original = btn.innerHTML;
				try {
					await navigator.clipboard.writeText(text);
					btn.classList.add('ok');
					btn.classList.remove('err');
					btn.innerHTML = '<svg width="12" height="12" viewBox="0 0 16 16" fill="none" aria-hidden="true"><path d="M3 8.5 L 6.5 12 L 13 4.5" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" fill="none"/></svg> Copied';
				} catch (err) {
					btn.classList.add('err');
					btn.classList.remove('ok');
					btn.textContent = 'Failed';
				}
				setTimeout(function () {
					btn.classList.remove('ok', 'err');
					btn.innerHTML = original;
				}, 1400);
			});
		});
	}

	// ── Bubble field ──────────────────────────────────────────────────────
	// Port of the JSX BubbleField — outlined circles drifting up with per-bubble
	// speed and sideways sway. Seeded RNG so layout is stable across reloads.
	function initBubbles() {
		const host = document.getElementById('bubble-field');
		if (!host) return;
		const count = window.matchMedia('(max-width: 720px)').matches ? 9 : 18;
		let s = 3 * 9301 + 49297;
		const rnd = function () { s = (s * 9301 + 49297) % 233280; return s / 233280; };
		const frag = document.createDocumentFragment();
		for (let i = 0; i < count; i++) {
			const size = 18 + rnd() * 90;
			const left = rnd() * 100;
			const op = 0.12 + rnd() * 0.32;
			const speed = 18 + rnd() * 22 + (110 - size) * 0.15;
			const delay = -rnd() * speed;
			const sway = 14 + rnd() * 26;
			const swayDur = 4 + rnd() * 5;
			const swayDelay = -rnd() * swayDur;
			const swayDir = rnd() > 0.5 ? 1 : -1;
			const stroke = rnd() > 0.55 ? 1 : 1.5;
			const filled = rnd() > 0.78;

			const bubble = document.createElement('span');
			bubble.className = 'b-bubble';
			bubble.style.left = left + '%';
			bubble.style.bottom = -(size + 20) + 'px';
			bubble.style.width = size + 'px';
			bubble.style.height = size + 'px';
			bubble.style.opacity = String(op);

			const rise = document.createElement('span');
			rise.className = 'b-bubble-rise';
			rise.style.animation = 'bbRise ' + speed + 's linear ' + delay + 's infinite';

			const sw = document.createElement('span');
			sw.className = 'b-bubble-sway';
			sw.style.animation = 'bbSway ' + swayDur + 's ease-in-out ' + swayDelay + 's infinite alternate';
			sw.style.setProperty('--sway', (sway * swayDir) + 'px');

			const dot = document.createElement('span');
			dot.className = 'b-bubble-dot';
			dot.style.background = filled ? 'color-mix(in oklab, var(--accent) 10%, transparent)' : 'transparent';
			dot.style.border = stroke + 'px solid var(--accent)';

			sw.appendChild(dot);
			rise.appendChild(sw);
			bubble.appendChild(rise);
			frag.appendChild(bubble);
		}
		host.replaceChildren(frag);
	}

	// ── Boot ──────────────────────────────────────────────────────────────
	function boot() {
		renderAllTerms();
		initDomain();
		initDistroTabs();
		initCopyButtons();
		initBubbles();
	}

	if (document.readyState === 'loading') {
		document.addEventListener('DOMContentLoaded', boot);
	} else {
		boot();
	}
})();
