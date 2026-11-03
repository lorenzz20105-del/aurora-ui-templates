// Captures the README screenshots from preview.html.
//   npm i -D playwright && npx playwright install chromium && node tools/shots.js
const { chromium } = require('playwright');
const path = require('path');
const OUT = require('path').join(__dirname, '..', 'docs');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1600, height: 1000 }, deviceScaleFactor: 1.5 });
  const errors = [];
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('pageerror', e => errors.push(String(e)));

  await page.goto('file://' + require('path').join(__dirname, '..', 'preview.html'));
  await page.waitForTimeout(900);

  const fit = await page.evaluate(() => {
    const sc = document.querySelector('.page.active .scroll') || document.querySelector('.page.active');
    return { scrollH: sc.scrollHeight, clientH: sc.clientHeight };
  });
  console.log('home fits:', JSON.stringify(fit));

  const clipShot = async (name) => {
    const box = await page.locator('.window').boundingBox();
    const clip = {
      x: Math.max(0, box.x - 22), y: Math.max(0, box.y - 22),
      width: box.width + 44, height: box.height + 44,
    };
    await page.screenshot({ path: path.join(OUT, name), type: 'jpeg', quality: 92, clip });
    console.log('shot', name);
  };

  // hero: whole scene
  await page.screenshot({ path: path.join(OUT, 'screenshot-home.jpg'), type: 'jpeg', quality: 92 });

  // components: gameplay + open dropdown
  await page.click('.rail-btn[data-tab="combat"]');
  await page.waitForTimeout(450);
  await page.click('.page.active .row:has(.row-name:text-is("Camera mode")) .drop');
  await page.waitForTimeout(420);
  await clipShot('screenshot-components.jpg');
  await page.keyboard.press('Escape');
  await page.waitForTimeout(250);

  // notifications: three stacked toasts on the utilities page
  await page.click('.rail-btn[data-tab="utilities"]');
  await page.waitForTimeout(450);
  await page.click('[data-toast-stack]');
  await page.waitForTimeout(1000);
  await clipShot('screenshot-toasts.jpg');

  // daylight theme
  await page.evaluate(() => { document.documentElement.dataset.theme = 'daylight'; });
  await page.click('.rail-btn[data-tab="settings"]');
  await page.waitForTimeout(700);
  await clipShot('screenshot-daylight.jpg');

  console.log('console errors:', errors.length ? errors : 'none');
  await browser.close();
})();
