# flutter_geolocation

A flutter web app to experiment with geolocations.

## Deployment

1. [Install firebase cli](https://firebase.google.com/docs/cli)
2. Under project root: `firebase login`.
3. `firebase init hosting`
    - Choose the firebase project you want to host.
    - Change `public` folder to `build/web`.
4. `firebase deploy --only hosting`.