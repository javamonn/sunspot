@module("./aws-exports.js")
external awsAmplifyConfig: Externals_AWSAmplify.Config.t = "default"

@val external nodeEnv: string = "process.env.NODE_ENV"
let isProduction = nodeEnv == "production"
let isBrowser = () => %raw(`typeof window !== 'undefined'`)

let sentryDsn = "https://46f76de2bfc64d10a89fc90865bb1d47@o1060100.ingest.sentry.io/6049323"
let amplitudeApiKey = "12b1c3f0609d7a9a382a5359a9f0e97e"
