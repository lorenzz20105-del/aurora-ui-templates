// Renders the GUI tree the Luau code actually built into a self-contained page.
//
//   node tools/render.js            # docs/real-ui.json  -> docs/real-ui.html
//   node tools/render.js --all      # docs/styles/*.json -> docs/templates.html
//
// Shared layout engine: tools/engine.css + tools/engine.js.
const fs = require("fs");
const path = require("path");

const ROOT = path.join(__dirname, "..");
const engineCss = fs.readFileSync(path.join(__dirname, "engine.css"), "utf8");
const engineJs = fs.readFileSync(path.join(__dirname, "engine.js"), "utf8");

function fill(template, values) {
	let html = template;
	for (const [marker, value] of Object.entries(values)) {
		html = html.split(marker).join(value);
	}
	return html;
}

function kb(text) {
	return (Buffer.byteLength(text) / 1024).toFixed(0);
}

function buildSingle() {
	const dataPath = path.join(ROOT, "docs", "real-ui.json");
	if (!fs.existsSync(dataPath)) {
		throw new Error("docs/real-ui.json is missing — run tools/dump.py first");
	}
	const templatePath = path.join(__dirname, "real-ui.template.html");
	const outPath = path.join(ROOT, "docs", "real-ui.html");

	const data = JSON.parse(fs.readFileSync(dataPath, "utf8"));
	const html = fill(fs.readFileSync(templatePath, "utf8"), {
		"/*__ENGINE_CSS__*/": engineCss,
		"/*__ENGINE_JS__*/": engineJs,
		"/*__DATA__*/null": JSON.stringify(data),
	});

	fs.writeFileSync(outPath, html);
	console.log(`[render] ${path.relative(ROOT, outPath)} (${kb(html)} KB)`);
}

function buildGallery() {
	const stylesDir = path.join(ROOT, "docs", "styles");
	if (!fs.existsSync(stylesDir)) {
		throw new Error("docs/styles/ is empty — run python3 tools/dump-all.py first");
	}

	const files = fs
		.readdirSync(stylesDir)
		.filter((name) => name.endsWith(".json"));

	const styles = files.map((name) => {
		const data = JSON.parse(fs.readFileSync(path.join(stylesDir, name), "utf8"));
		return {
			slug: name.replace(/\.json$/, ""),
			meta: data.meta || {},
			dump: data.window ? data : { window: data },
		};
	});

	// registry order, not file order
	styles.sort((a, b) => (a.meta.order || 0) - (b.meta.order || 0));

	const templatePath = path.join(__dirname, "templates.template.html");
	const outPath = path.join(ROOT, "docs", "templates.html");

	const html = fill(fs.readFileSync(templatePath, "utf8"), {
		"/*__ENGINE_CSS__*/": engineCss,
		"/*__ENGINE_JS__*/": engineJs,
		"/*__STYLES__*/[]": JSON.stringify(styles),
	});

	fs.writeFileSync(outPath, html);
	console.log(`[render] ${path.relative(ROOT, outPath)} (${kb(html)} KB, ${styles.length} styles)`);
}

const all = process.argv.includes("--all");
if (all) {
	buildGallery();
} else {
	buildSingle();
	if (process.argv.includes("--with-gallery")) {
		buildGallery();
	}
}
