Flaperon Navigation 
A high-performance, visually polished Flutter navigation interface featuring custom-rendered Google Maps markers and smooth, curved polyline routing.

Features
**Custom Marker Engine**: Low-level Canvas painting for markers including a glowing motorcycle indicator and shadowed informational pins.
**Curved Routing**: Uses CatmullRomSpline interpolation to transform jagged GPS coordinates into smooth, organic road paths.
**Optimized UI**: Fully supports JointType.round and Cap.roundCap for a professional navigation look on Android devices.
**Dynamic Overlays**: High-fidelity glassmorphism-style navigation cards and a real-time speedometer interface.
**Dark Mode Support**: Integrated custom Google Maps JSON styling for high-contrast nighttime navigation.

Tech Stack
**Framework**: Flutter
**Maps**: google_maps_flutter
**Typography**: Google Fonts (Manrope & Poppins)
**Math/Geometry:** dart:ui for custom Canvas painting.

Screenshots:
<img width="716" height="1600" alt="image" src="https://github.com/user-attachments/assets/5e915add-0ea5-4840-b62b-c644913c1032" />

Future Enhancements (Updated)
**Dynamic Marker Animation**: Transition from static markers to an animated system where the bike marker glides smoothly between coordinates using AnimationController.
**Real-time Speedometer Integration**: Connect the existing UI speedometer to the device's GPS stream using the geolocator package.

📹 Deliverables Summary

Deliverable	Status
🎥 Video demo (≤ 2 min) -	✅ Link
📱 APK (release build)	✅ Link
