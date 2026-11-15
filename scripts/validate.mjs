// Repo checks for the port. Run: node scripts/validate.mjs
// Guards the skill's metadata and the CC BY 4.0 obligations (credit, license, link, notice of changes).
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const read = (p) => readFileSync(join(root, p), "utf8");
const errors = [];
const check = (ok, message) => { if (!ok) errors.push(message); };

const skillDir = "skills/unslop-portable";
const skill = read(`${skillDir}/SKILL.md`);
const front = skill.match(/^---\r?\n([\s\S]*?)\r?\n---/)?.[1] ?? "";
const field = (name) => front.match(new RegExp(`^${name}:\\s*(.+)$`, "m"))?.[1].trim();

check(field("name") === "unslop-portable", "SKILL.md: name must be unslop-portable (it must match the folder and differ from upstream's `unslop`)");
check(field("license") === "CC-BY-4.0", "SKILL.md: license must stay CC-BY-4.0");
check(field("description"), "SKILL.md: description is missing");
check(/Damir Sokolovsky/.test(skill) && /heydamir\/unslop/.test(skill), "SKILL.md: credit to Damir Sokolovsky and the upstream link are required");
check(/unofficial port/i.test(skill), "SKILL.md: the unofficial-port notice is required");

const readme = read("README.md");
check(/unofficial port/i.test(readme), "README.md: the unofficial-port notice is required");
check(/Damir Sokolovsky/.test(readme) && /github\.com\/heydamir\/unslop/.test(readme), "README.md: credit and upstream link are required");
check(/CC BY 4\.0/.test(readme), "README.md: must name the CC BY 4.0 license");
check(/What this port changes/.test(readme), "README.md: keep the 'What this port changes' section (CC BY 4.0 requires indicating changes)");

const license = read("LICENSE");
check(/Creative Commons Attribution 4\.0/i.test(license) || /CC BY 4\.0/i.test(license) || /Attribution 4\.0/i.test(license), "LICENSE: CC BY 4.0 text is missing");
const cff = read("CITATION.cff");
check(/Sokolovsky/.test(cff) && /heydamir\/unslop/.test(cff), "CITATION.cff: must credit Damir Sokolovsky and link upstream");

check(/^[0-9a-f]{40}$/.test(read("UPSTREAM").trim()), "UPSTREAM: must hold a full upstream commit sha");

// every relative markdown link in SKILL.md must resolve
for (const [, target] of skill.matchAll(/\]\((references\/[^)#]+)[^)]*\)/g)) {
  check(existsSync(join(root, skillDir, target)), `SKILL.md links to missing file: ${target}`);
}
for (const file of readdirSync(join(root, skillDir, "references"))) {
  if (!file.endsWith(".md")) continue;
  check(statSync(join(root, skillDir, "references", file)).size > 0, `references/${file} is empty`);
}

if (errors.length) {
  console.error(errors.map((e) => `- ${e}`).join("\n"));
  process.exit(1);
}
console.log("validate: ok");
