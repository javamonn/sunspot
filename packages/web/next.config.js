const bsconfig = require("./bsconfig.json");
const fs = require("fs");
const RemarkHTML = require("remark-html");
const webpack = require("webpack")

const transpileModules = ["rescript"].concat(bsconfig["bs-dependencies"]);
const withTM = require("next-transpile-modules")(transpileModules);
const activeDiscordClientId = "942444344978337802"

const config = {
  target: "serverless",
  pageExtensions: ["jsx", "js"],
  env: {
    ENV: process.env.NODE_ENV,
  },
  webpack: (config, options) => {
    const { isServer } = options;

    if (!isServer) {
      // We shim fs for things like the blog slugs component
      // where we need fs access in the server-side part
      config.resolve.fallback = {
        fs: false,
        path: false,
        stream: require.resolve("stream-browserify"),
        crypto: require.resolve("crypto-browserify"),
        http: require.resolve("stream-http"),
        https: require.resolve("https-browserify"),
        os: require.resolve("os-browserify"),
        assert: require.resolve("assert"),
        process: require.resolve("process/browser")
      };
    }

    // We need this additional rule to make sure that mjs files are
    // correctly detected within our src/ folder
    config.module.rules.push({
      test: /\.m?js$/,
      use: options.defaultLoaders.babel,
      exclude: /node_modules/,
      type: "javascript/auto",
      resolve: {
        fullySpecified: false,
      },
    });

    config.module.rules.push({
      test: /\.md$/,
      use: [
        {
          loader: "html-loader",
        },
        {
          loader: "remark-loader",
          options: {
            remarkOptions: {
              plugins: [RemarkHTML],
            },
          },
        },
      ],
    });

    config.plugins.push(
      new webpack.ProvidePlugin({
        process: "process/browser",
      })
    );

    return config;
  },
  redirects: () => [
    {
      source: "/install/discord",
      destination: `https://discord.com/api/oauth2/authorize?client_id=${activeDiscordClientId}&permissions=19456&redirect_uri=https%3A%2F%2Fsunspot.gg%2Fintegrations%2Fdiscord%2Finstall&response_type=code&scope=guilds%20bot%20applications.commands`,
      permanent: false,
    },
    {
      source: "/install/twitter",
      destination:
        "https://twitter.com/i/oauth2/authorize?response_type=code&client_id=clVTSDN2eDc2SExyNzFfdHNhNVc6MTpjaQ&redirect_uri=https%3A%2F%2Fsunspot.gg%2Fintegrations%2Ftwitter%2Finstall&scope=tweet.write%20users.read%20tweet.read%20offline.access&state=state&code_challenge=challenge&code_challenge_method=plain",
      permanent: false,
    },
    {
      source: "/install/slack",
      destination:
        "https://slack.com/oauth/v2/authorize?client_id=2851595757074.2853916229636&scope=incoming-webhook&user_scope=",
      permanent: false,
    },
  ],
};

module.exports = withTM(config);
