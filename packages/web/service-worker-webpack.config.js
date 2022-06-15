const path = require('path')

const config = {
  entry: path.resolve(__dirname, "./src/ServiceWorker/ServiceWorker.bs.js"),
  output: {
    path: path.resolve(__dirname, "./public"),
    filename: "service-worker.js",
  },
};

module.exports = config;
