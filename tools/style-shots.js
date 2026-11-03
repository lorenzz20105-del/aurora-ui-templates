/**
 * style-shots.js — one screenshot per template, straight out of the gallery.
 *
 *   node tools/render.js --all && node tools/style-shots.js
 *
 * Writes docs/styles/<slug>.jpg for the README table.
 */

const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const PAGE = 'file://' + path.resolve(__dirname, '..', 'docs', 'templates.html');
const OUT = path.resolve(__dirname, '..', 'docs', 'styles');
const MARGIN = 14;

(async () => {
	fs.mkdirSync(OUT, { recursive: true });

	const browser = await chromium.launch();
	const page = await browser.newPage({ viewport: { width: 1500, height: 1050 }, deviceScaleFactor: 2 });
	const errors = [];
	page.on('pageerror', (error) => errors.push(String(error)));

	await page.goto(PAGE);
	await page.waitForTimeout(600);

	const slugs = await page.evaluate(() => STYLES.map((entry) => entry.slug));

	for (let index = 0; index < slugs.length; index++) {
		await page.click(`.chip:nth-child(${index + 1})`);
		await page.waitForTimeout(320);

		const box = await page.locator('[data-name="Main"]').first().boundingBox();
		const clip = {
			x: Math.max(0, box.x - MARGIN),
			y: Math.max(0, box.y - MARGIN),
			width: box.width + MARGIN * 2,
			height: box.height + MARGIN * 2,
		};

		const file = path.join(OUT, `${slugs[index]}.jpg`);
		await page.screenshot({ path: file, clip, type: 'jpeg', quality: 92 });
		console.log(`[style-shots] ${path.basename(file)}`);
	}

	console.log('errors:', errors.length ? errors : 'none');
	await browser.close();
})();
