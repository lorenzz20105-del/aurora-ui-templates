/**
 * real-shots.js  —  screenshot docs/real-ui.html, one image per tab.
 *
 * Usage (from the repo root, after tools/render.js has written the page):
 *   npm i -D playwright@1.49.1 && npx playwright install chromium
 *   node tools/real-shots.js
 *
 * Writes docs/screenshot-real-<tab>.jpg, cropped to the window itself so the
 * images read like product shots instead of browser captures.
 */

const { chromium } = require('playwright');
const path = require('path');

const PAGE = 'file://' + path.resolve(__dirname, '..', 'docs', 'real-ui.html');
const OUT = path.resolve(__dirname, '..', 'docs');
const MARGIN = 14;

(async () => {
	const browser = await chromium.launch();
	const page = await browser.newPage({ viewport: { width: 1500, height: 950 }, deviceScaleFactor: 2 });
	const errors = [];
	page.on('pageerror', (error) => errors.push(String(error)));

	await page.goto(PAGE);
	await page.waitForTimeout(400);

	const tabs = await page.$$eval('[data-tab]', (nodes) => nodes.map((node) => node.dataset.tab));
	const win = await page.locator('[data-name="Main"]').first().boundingBox();
	const clip = {
		x: Math.max(0, win.x - MARGIN),
		y: Math.max(0, win.y - MARGIN),
		width: win.width + MARGIN * 2,
		height: win.height + MARGIN * 2,
	};

	for (const tab of tabs) {
		await page.click(`[data-tab="${tab}"]`);
		await page.waitForTimeout(250);
		const file = path.join(OUT, `screenshot-real-${tab.toLowerCase()}.jpg`);
		await page.screenshot({ path: file, clip, type: 'jpeg', quality: 92 });
		console.log(`[shots] ${path.basename(file)}`);
	}

	console.log('errors:', errors.length ? errors : 'none');
	await browser.close();
})();
