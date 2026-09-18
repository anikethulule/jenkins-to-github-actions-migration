const express = require("express");
const path = require("path");

const app = express();
const port = process.env.PORT || 8080;

app.disable("x-powered-by");
app.use(express.static(path.join(__dirname, "public")));

app.get("/health", (req, res) => {
  res.status(200).json({
    status: "UP",
    service: "jenkins-to-github-actions-migration",
    timestamp: new Date().toISOString()
  });
});

app.get("/api/migration", (req, res) => {
  res.json({
    title: "Jenkins to GitHub Actions Migration",
    owner: "jenkins-to-github-actions-migration",
    status: "Demo Ready",
    stages: ["Source", "Test", "Build", "Security", "Container", "Deploy"]
  });
});

if (require.main === module) {
  app.listen(port, () => {
    console.log(`jenkins-to-github-actions-migration running on port ${port}`);
  });
}

module.exports = app;
