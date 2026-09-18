const app = require("./server");
const http = require("http");

function request(url) {
  return new Promise((resolve, reject) => {
    http.get(url, (response) => {
      let body = "";

      response.setEncoding("utf8");
      response.on("data", (chunk) => {
        body += chunk;
      });
      response.on("end", () => {
        resolve({ ok: response.statusCode >= 200 && response.statusCode < 300, text: () => Promise.resolve(body), json: () => Promise.resolve(JSON.parse(body)) });
      });
    }).on("error", reject);
  });
}

async function runTests() {
  console.log("Running application tests...");

  const server = app.listen(0);
  const { port } = server.address();
  const baseUrl = `http://127.0.0.1:${port}`;

  try {
    const healthResponse = await request(`${baseUrl}/health`);
    const health = await healthResponse.json();

    if (!healthResponse.ok || health.status !== "UP") {
      throw new Error("Health endpoint test failed");
    }

    const pageResponse = await request(baseUrl);
    const page = await pageResponse.text();

    if (!pageResponse.ok || !page.includes("Jenkins to GitHub Actions Migration")) {
      throw new Error("UI route test failed");
    }

    const migrationResponse = await request(`${baseUrl}/api/migration`);
    const migration = await migrationResponse.json();

    if (!migrationResponse.ok || migration.stages.length !== 6) {
      throw new Error("Migration API test failed");
    }

    console.log("All tests passed");
  } finally {
    server.close();
  }
}

runTests().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
