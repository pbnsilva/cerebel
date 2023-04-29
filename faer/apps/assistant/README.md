# Faer for Google Voice Assistant (Dialogflow)


## Deploy Cloud Function


0. Install Firebase tools if necessary: `npm install -g firebase-tools` and login `firebase login`
1. Ensure `functions/package.json` contains all dependencies
2. Run `npm install` inside the `functions` folder
3. Deploy function using `firebase deploy --only functions` inside the `functions` folder
4. Set or update the URL in the agent's Fulfillment Webhook as necessary 