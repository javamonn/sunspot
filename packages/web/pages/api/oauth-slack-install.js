export default function handler(req, res) {
  res.writeHead(302, {
    Location:
      "https://slack.com/oauth/v2/authorize?client_id=2851595757074.2853916229636&scope=incoming-webhook&user_scope=",
  });
  res.end();
}
