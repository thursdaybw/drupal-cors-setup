const puppeteer = require('puppeteer');

(async () => {
  try {
    const browser = await puppeteer.launch({
      headless: false,
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--display=:1',
        '--ignore-certificate-errors'
      ]
    });
    const page = await browser.newPage();
    await page.goto('https://drupal-headless-frontend.ddev.site', { waitUntil: 'networkidle2' });

    // Perform login
    await page.type('#username', 'admin');
    await page.type('#password', 'admin');
    await page.click('button[type="submit"]');

    // Wait for the login success message
    await page.waitForSelector('#message', { visible: true, timeout: 60000 });

    // Wait for the articles to load
    await page.waitForSelector('#articles-container article', { visible: true, timeout: 60000 });

    // Extract article titles
    const articles = await page.evaluate(() => {
      return Array.from(document.querySelectorAll('#articles-container article')).map(article => article.querySelector('h4').innerText);
    });

    console.log('Articles:', articles);
    await browser.close();
  } catch (error) {
    console.error('Error launching Puppeteer:', error);
    process.exit(1);
  }
})();

