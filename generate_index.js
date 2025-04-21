const fs = require("fs");
const path = require("path");

const baseDir = path.join(__dirname, "historical-reports");
const outputFile = path.join(__dirname, "index.html");

/**
 * Retrieves the list of reports in the historical-reports directory.
 * Each report is expected to be inside a folder with an `index.html` file.
 * @param {string} dir - The directory containing reports.
 * @returns {Array} - List of report objects with name and URL.
 */
function getReportList(dir) {
    let reports = [];
    fs.readdirSync(dir, { withFileTypes: true }).forEach(entry => {
        if (entry.isDirectory()) {
            const reportPath = path.join(dir, entry.name, "index.html");
            if (fs.existsSync(reportPath)) {
                reports.push({
                    name: entry.name,
                    url: `historical-reports/${entry.name}/index.html`,
                });
            }
        }
    });

    // Sort reports (latest first)
    reports.sort((a, b) => parseReportDate(b.name) - parseReportDate(a.name));

    return reports;
}

/**
 * Extracts a timestamp from a report folder name (assumed format: "_Month_DD_YYYY_HH_MM").
 * @param {string} reportName - Report folder name.
 * @returns {number} - Timestamp for sorting or 0 if format is invalid.
 */
function parseReportDate(reportName) {
    const match = reportName.match(/_(\w+)_(\d{1,2})_(\d{4})_(\d{2})_(\d{2})$/);
    if (!match) return 0;
    const [_, month, day, year, hour, minute] = match;
    const months = { Jan: 0, Feb: 1, Mar: 2, Apr: 3, May: 4, Jun: 5, Jul: 6, Aug: 7, Sep: 8, Oct: 9, Nov: 10, Dec: 11 };
    return new Date(year, months[month], day, hour, minute).getTime();
}

const reports = getReportList(baseDir);

/**
 * Generates an HTML index page listing all reports.
 * @param {Array} reports - List of report objects.
 * @returns {string} - HTML content.
 */
function generateHTML(reports) {
    return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Historical Reports</title>
<style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    h1 { color: #333; }
    table { width: 100%; border-collapse: collapse; }
    th, td { padding: 10px; border: 1px solid #ccc; text-align: left; }
    th { background-color: #f4f4f4; }
    a { text-decoration: none; color: blue; }
    .latest { font-weight: bold; color: green; }
</style>
</head>
<body>
<h1>Historical Reports</h1>
<table>
<thead>
<tr>
    <th>Report</th>
</tr>
</thead>
<tbody>
${reports.map(report => `
<tr>
    <td><a href="${report.url}" class="${report.name === reports[0].name ? 'latest' : ''}">
        ${report.name} ${report.name === reports[0].name ? '⬅️ Latest' : ''}
    </a></td>
</tr>`).join('')}
</tbody>
</table>
</body>
</html>`;
}

// Generate and save the report index
const htmlContent = generateHTML(reports);
fs.writeFileSync(outputFile, htmlContent, "utf8");

console.log(`✅ Generated: ${outputFile}`);