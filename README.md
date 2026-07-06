# Masr Train

A train ticket booking app for Egyptian National Railways, built with Flutter and Firebase.

Users can search trains, pick seats, pay, and get e-tickets with QR codes. There's also a conductor-side dashboard for managing passengers, scanning tickets, and updating train statuses in real time.

## Features

**Passenger side:**
- Sign up / login with Firebase Auth
- Search trains between 63 stations across Egypt
- Pick seat class (1st, 2nd, 3rd) and seat number
- Pay with card (Luhn-validated), e-wallet, or cash
- Get a digital ticket with a unique QR code
- Track your trip on a live map (OpenStreetMap)
- Get push notifications when your ticket is scanned or train status changes
- View all train schedules, prices, and stops
- Edit profile, dark/light mode toggle, Arabic/English switch

**Conductor / Admin side:**
- Select which train you're managing from a searchable list
- See all bookings for that train in real time (synced with Firestore)
- Scan passenger QR codes with the camera to validate tickets
- Issue new tickets on the spot
- File incident reports for violations
- Update train status (running, delayed, cancelled, breakdown) — affected passengers get notified automatically
- Track boarding and departure of passengers

## Tech Stack

| What | Why |
|------|-----|
| Flutter 3.x + Dart | Cross-platform UI |
| Firebase Auth | User authentication |
| Cloud Firestore | Real-time database for bookings, users, notifications |
| Firebase Cloud Messaging | Push notifications |
| Provider | State management |
| flutter_map + latlong2 | Map view (OpenStreetMap tiles) |
| qr_flutter | QR code generation |
| mobile_scanner | QR code scanning via camera |
| google_fonts (Cairo) | Arabic-friendly typography |
| flutter_local_notifications | Local notification display |

## Project Structure

```
lib/
  main.dart                             -- Entry point, Firebase init
  models/
    models.dart                         -- Data models + sample train data (25+ trains, 63 stations)
  screens/
    login_screen.dart                   -- Login (user or admin mode)
    register_screen.dart                -- Registration
    home_screen.dart                    -- Main screen with bottom nav
    booking_tab.dart                    -- Search & book trains
    train_list_screen.dart              -- Search results
    train_booking_screen.dart           -- Seat selection
    payment_screen.dart                 -- Payment flow
    ticket_screen.dart                  -- E-ticket with QR
    track_screen.dart                   -- Live trip tracking with map
    profile_screen.dart                 -- User profile & settings
    notifications_screen.dart           -- Notification list
    all_trains_schedule_screen.dart     -- Full train timetable
    help_screen.dart                    -- FAQ & support
    privacy_screen.dart                 -- Privacy policy
    rate_app_screen.dart                -- Rate the app
    train_selection_screen.dart         -- Conductor: pick a train
    conductor_dashboard.dart            -- Conductor: manage tickets/passengers
    admin_screen.dart                   -- Admin panel
    qr_scanner_screen.dart              -- QR scanner
    issue_ticket_screen.dart            -- Issue new ticket
    incident_report_screen.dart         -- File incident reports
    train_status_manager_screen.dart    -- Update train statuses
  services/
    app_state.dart                      -- App state (Provider) + Firestore listeners
    train_manager_service.dart          -- Train status logic + notifications
    notification_helper.dart            -- Local notifications setup
  theme/
    app_theme.dart                      -- Dark & light themes, color system
  widgets/
    common_widgets.dart                 -- Shared UI components
```

## Database (Firestore)

Four main collections:

**users** — name, email, phone, role, createdAt

**bookings** — ticketNumber, passengerName, trainNumber, from, to, departureTime, arrivalTime, date, seatClass, seatNumber, price, status (valid/scanned/invalid), userId, stops[], createdAt

**notifications** — userId, title, body, type, read, createdAt

**train_statuses** — trainNumber, status (running/delayed/cancelled/accident), reason, delayMinutes, updatedAt

## Setup

Prerequisites: Flutter SDK 3.x, a Firebase project with Auth + Firestore + FCM enabled.

```bash
git clone https://github.com/AhmedAbeed/trainapp.git
cd trainapp
flutter pub get
flutter run
```

You'll need to add your own `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) from Firebase Console.

## Train Coverage

The app includes data for 25+ trains covering the main Egyptian railway lines:

- Cairo <-> Alexandria (14 trains — special, Russian, AC, sleeper, Talgo)
- Cairo <-> Aswan (6 trains)
- Cairo <-> Asyut (1 train)
- Cairo <-> Banha (1 train)
- Mansoura <-> Alexandria (6 trains)

63 stations total, from Alexandria in the north to Aswan in the south.

## Language Support

Full Arabic (RTL) and English (LTR) support. Users can switch languages from the login screen or profile settings. The default is Arabic.

## License

MIT
