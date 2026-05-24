# Backend-Mobile Integration Fix Plan

Connect the Flutter mobile app to the FastAPI backend, fix all errors, and ensure Hive offline caching is used when the backend is unreachable.

## Issues Found

1. **Git merge conflicts** in [main.dart](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/lib/main.dart), [socket_service.dart](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/lib/services/socket_service.dart), [alerts_screen.dart](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/lib/screens/alerts_screen.dart) — files won't compile done
2. **Wrong endpoint** in [satellite_service.dart](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/lib/services/satellite_service.dart): calls `/krishi/get-ndvi` but backend exposes `/krishi-saathi/ndvi` done
3. **Schema mismatch** in [iot.py](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/backend/app/routers/iot.py) legacy `/sensor` endpoint: accesses `data.user_id`, but [SensorData](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/backend/app/schemas.py#48-50) schema has no `user_id` field
4. **Missing offline fallback**: [iot_service.dart](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/lib/services/iot_service.dart), [weather_service.dart](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/lib/services/weather_service.dart), and [yield_service.dart](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/lib/services/yield_service.dart) (fertilizer recommendation) don't cache or serve Hive data on connection failure done
5. **Hive adapter mismatch**: [crop_data.g.dart](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/lib/models/crop_data.g.dart) writes only 9 fields but [CropData](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/lib/models/crop_data.dart#6-57) model has 11 (`latitude`/`longitude` at indices 9/10 are never written) done
6. **[pubspec.yaml](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/pubspec.yaml)** missing `connectivity_plus` package needed for robust offline detection

## Proposed Changes

---

### Mobile App Fixes

#### [MODIFY] [main.dart](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/lib/main.dart)

- Resolve git merge conflict: keep `Hive.registerAdapter(CropDataAdapter())` before `runApp`

#### [MODIFY] [socket_service.dart](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/lib/services/socket_service.dart)

- Resolve git merge conflict: adopt the **new version** (with `StreamController`, `_isConnected` flag, reconnect guard, [dispose()](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/lib/services/socket_service.dart#84-90) method — this is strictly better)

#### [MODIFY] [alerts_screen.dart](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/lib/screens/alerts_screen.dart)

- Resolve git merge conflict: adopt the **new version** (with `StreamSubscription`, throttling timer, `_handleIncomingData`, proper [dispose()](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/lib/services/socket_service.dart#84-90) — strictly better)

#### [MODIFY] [satellite_service.dart](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/lib/services/satellite_service.dart)

- Fix endpoint: `/krishi/get-ndvi` → `/krishi-saathi/ndvi?lat=&lon=`
- Add auth header (JWT token) since NDVI endpoint is accessed through [yield_service.dart](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/lib/services/yield_service.dart) fine but this old service was calling without auth
- Return the correct field names (`ndvi_peak`, `ndvi_flowering`) matching backend response

#### [MODIFY] [iot_service.dart](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/lib/services/iot_service.dart)

- Add Hive offline caching: on success write data to `'iot_latest'` box; on failure read from box and return cached data

#### [MODIFY] [weather_service.dart](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/lib/services/weather_service.dart)

- Add Hive offline caching for [getBackendWeather()](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/lib/services/weather_service.dart#26-53): on success write to `'weather_cache'` box; on failure return cached data
- Weekly forecast also falls back gracefully (already passes through exceptions — add explicit fallback)

#### [MODIFY] [yield_service.dart](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/lib/services/yield_service.dart)

- [getFertilizerRecommendation()](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/lib/services/yield_service.dart#152-192): cache successful response in `'last_recommendation'` box and return it on failure (currently just returns null on error)
- [getIoTData()](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/lib/services/yield_service.dart#44-68): use Hive cache on failure (currently just returns null)

#### [MODIFY] [crop_data.g.dart](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/lib/models/crop_data.g.dart)

- Fix `write()` method to also write `latitude` (field 9) and `longitude` (field 10), and update count from 9 to 11
- Fix [read()](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/backend/app/main.py#156-159) method to read `latitude` and `longitude` back out

#### [MODIFY] [pubspec.yaml](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/pubspec.yaml)

- Add `connectivity_plus: ^6.1.1` for offline detection

---

### Backend Fixes

#### [MODIFY] [iot.py](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/backend/app/routers/iot.py)

- Fix legacy `/sensor` endpoint: `data.user_id` doesn't exist on [SensorData](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/backend/app/schemas.py#48-50) schema. Replace with null/default since this is a legacy compatibility endpoint.

---

## Verification Plan

### Automated Tests

- The existing test file [mobile/test/widget_test.dart](file:///c:/Users/Dipankar%20Ghosh/Coding/agnisutra/mobile/test/widget_test.dart) is a minimal widget smoke test. It can be run (after fixing merge conflicts) with:
  ```
  cd c:\Users\Dipankar Ghosh\Coding\agnisutra\mobile
  flutter test
  ```

### Manual Verification (after backend is running)

1. **Compile check** — run `flutter analyze` in `mobile/` directory to confirm zero errors
2. **Backend compile** — run `python -m uvicorn app.main:app --reload` from `backend/` to confirm the Python server starts without import errors
3. **Backend endpoints** — hit `http://localhost:8000/docs` (Swagger UI) and verify all routes are listed:
   - `POST /auth/register`, `POST /auth/login`, `GET /auth/me`
   - `GET /iot/latest`, `POST /iot/update`
   - `GET /krishi-saathi/ndvi`, `GET /krishi-saathi/weather`
   - `POST /krishi-saathi/recommend`, `POST /krishi-saathi/chat`
   - `POST /disease/predict`
4. **Offline Hive** — Launch the app on a device/emulator, load data while connected, then turn off WiFi/switch to airplane mode and navigate through screens to confirm cached data is displayed instead of errors
