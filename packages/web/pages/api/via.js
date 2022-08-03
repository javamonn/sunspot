import { init, track } from "@amplitude/analytics-node"
import * as Crypto from "crypto"

const client = init("12b1c3f0609d7a9a382a5359a9f0e97e")

export default function handler(request, response) {
  const targetUri = request.query.t ? decodeURIComponent(request.query.t) : "https://sunspot.gg"
  const ip = request.headers['x-forwarded-for'] || request.socket.remoteAddress
  const id = ip ? Crypto.createHash("md5").update(ip).digest("hex") : Crypto.randomBytes(32).toString("hex")

  return track("via", { targetUri: targetUri }, { device_id: id, ip: ip })
    .promise
    .then((result) => {
      console.log("result", result)
      response.redirect(302, targetUri) 
    })
}
