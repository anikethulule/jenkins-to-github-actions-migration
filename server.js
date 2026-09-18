const express = require("express");
const path = require("path");

const app = express();
const port = process.env.PORT || 8080;

app.disable("x-powered-by");
app.use(express.static(path.join(__dirname, "public")));

app.get("/health", (req, res) => {
  res.status(200).json({
    status: "UP",
    service: "aniket-devops-jenkins-github-actions-migration",
    timestamp: new Date().toISOString()
  });
});

app.get("/api/migration", (req, res) => {
  res.json({
    title: "Jenkins to GitHub Actions Migration",
    owner: "Aniket DevOps",
    status: "Demo Ready",
    stages: ["Source", "Test", "Build", "Security", "Container", "Deploy"]
  });
});

if (require.main === module) {
  app.listen(port, () => {
    console.log(`Aniket DevOps migration project running on port ${port}`);
  });
}

module.exports = app;
