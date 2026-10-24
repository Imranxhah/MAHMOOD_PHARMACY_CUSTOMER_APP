# Run the customer app locally

[Back to the README](../README.md)

## 1. Prepare the backend

Follow the [backend setup guide](https://github.com/Imranxhah/MAHMOOD_PHARMACY_BACKEND). Use a local test database and synthetic records.

Edit [ApiConstants](../lib/src/constants/api_constants.dart). The checked-in active URLs point to a hosted backend; replace them before local development.

| Target | API base URL | Media origin |
| --- | --- | --- |
| Android emulator | `http://10.0.2.2:8000/api/` | `http://10.0.2.2:8000` |
| iOS simulator | `http://127.0.0.1:8000/api/` | `http://127.0.0.1:8000` |
| Physical device | `http://<computer-LAN-IP>:8000/api/` | `http://<computer-LAN-IP>:8000` |

Keep the trailing slash on API base URLs. The shared `mediaBaseUrl` must match the device you are testing. For a physical device, bind Django to `0.0.0.0:8000`, allow your development host in Django, and use the same local network. Permit local HTTP only in development platform settings; use HTTPS for deployment.

## 2. Configure Firebase

Startup calls `Firebase.initializeApp()` before showing the first screen.

- Create your own Firebase app matching the Android application ID in [build.gradle.kts](../android/app/build.gradle.kts).
- Replace `android/app/google-services.json` with the configuration for that app.
- For iOS, configure the matching Firebase iOS app and native configuration, plus the required notification capabilities.
- Set up the backend's Firebase Admin credentials for the **same Firebase project** to test push delivery.
- Keep server service-account credentials out of this Flutter repository.

The checked-in configuration belongs to an existing project. A successful build does not establish permission to use that project's services.

## 3. Run

```bash
flutter pub get
flutter devices
flutter run -d <device-id>
```

Registration and password recovery depend on backend email delivery. To exercise them, configure SMTP in the backend. Use only test addresses and non-sensitive prescription samples.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Startup fails during Firebase initialization | Native Firebase configuration matches the app ID and platform |
| Catalog is empty | Backend is reachable and contains active products/categories |
| Images fail to load | Media origin matches the backend and device network |
| Connection refused on Android emulator | Use `10.0.2.2` to reach the host, not emulator localhost |
| HTTP traffic blocked | Development network-security settings permit the local endpoint |
| Login or verification fails | Backend SMTP, OTP flow, active account status, and API URL |
| Push messages do not arrive | Device permission, token registration, Firebase project pairing, and backend credentials |

## Capturing a portfolio demo

Once configured, capture real screens from the running app: catalog, product details, cart, and order history. Use synthetic names, addresses, and orders. Keep screenshots in `docs/assets/` and describe the build/platform used. Generated cover artwork should not be presented as a screenshot.
