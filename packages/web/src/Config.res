@module("./aws-exports.js")
external awsAmplifyConfig: Externals_AWSAmplify.Config.t = "default"

@val external nodeEnv: string = "process.env.NODE_ENV"
let isProduction = nodeEnv == "production"
let isBrowser = () => %raw(`typeof window !== 'undefined'`)

let openstoreContractAddress = "0x495f947276749ce646f68ac8c248420045cb7b5e"

let sentryDsn = "https://46f76de2bfc64d10a89fc90865bb1d47@o1060100.ingest.sentry.io/6049323"
let amplitudeApiKey = "12b1c3f0609d7a9a382a5359a9f0e97e"

let discordOAuthUrl = isProduction
  ? "https://discord.com/api/oauth2/authorize?client_id=909830001363394593&permissions=19456&redirect_uri=https%3A%2F%2Fsunspot.gg%2Fintegrations%2Fdiscord%2Finstall&response_type=code&scope=guilds%20bot%20applications.commands"
  : "https://discord.com/api/oauth2/authorize?client_id=909830001363394593&permissions=19456&redirect_uri=http%3A%2F%2Flocalhost%3A3000%2Fintegrations%2Fdiscord%2Finstall&response_type=code&scope=guilds%20bot%20applications.commands"

let slackOAuthUrl = "https://slack.com/oauth/v2/authorize?client_id=2851595757074.2853916229636&scope=incoming-webhook&user_scope="

let twitterOAuthUrl = isProduction
  ? "https://twitter.com/i/oauth2/authorize?response_type=code&client_id=clVTSDN2eDc2SExyNzFfdHNhNVc6MTpjaQ&redirect_uri=https%3A%2F%2Fsunspot.gg%2Fintegrations%2Ftwitter%2Finstall&scope=tweet.write%20users.read%20tweet.read%20offline.access&state=state&code_challenge=challenge&code_challenge_method=plain"
  : "https://twitter.com/i/oauth2/authorize?response_type=code&client_id=clVTSDN2eDc2SExyNzFfdHNhNVc6MTpjaQ&redirect_uri=http%3A%2F%2Flocalhost%3A3000%2Fintegrations%2Ftwitter%2Finstall&scope=tweet.write%20users.read%20tweet.read%20offline.access&state=state&code_challenge=challenge&code_challenge_method=plain"
