# Fix Firestore Permission Denied Error

## Error Yang Terjadi
```
Status{code=PERMISSION_DENIED, description=Missing or insufficient permissions., cause=null}
Error saving goal: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

## Penyebab
Firestore Security Rules belum dikonfigurasi dengan benar untuk mengizinkan user menulis ke subcollection `settings/goal`.

## Solusi: Update Firestore Security Rules

### Cara 1: Melalui Firebase Console (RECOMMENDED)

1. **Buka Firebase Console**
   - Go to: https://console.firebase.google.com/
   - Pilih project: `pull-up-detection-app`

2. **Navigasi ke Firestore Rules**
   - Di sidebar kiri, klik **Firestore Database**
   - Klik tab **Rules**

3. **Update Rules**
   - Copy paste rules berikut:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      // Allow read if authenticated and is the owner
      allow read: if isOwner(userId);
      
      // Allow write (create/update) if is the owner
      allow write: if isOwner(userId);
      
      // Workouts subcollection
      match /workouts/{workoutId} {
        // Allow read/write if is the owner
        allow read, write: if isOwner(userId);
      }
      
      // Settings subcollection (untuk goal, preferences, etc)
      match /settings/{settingId} {
        // Allow read/write if is the owner
        allow read, write: if isOwner(userId);
      }
    }
  }
}
```

4. **Publish Rules**
   - Klik tombol **Publish** (warna biru)
   - Tunggu beberapa detik sampai rules aktif

5. **Test Lagi**
   - Restart aplikasi Flutter
   - Coba set goal lagi
   - Seharusnya sudah bisa! ✅

---

### Cara 2: Menggunakan Firebase CLI (Advanced)

Jika kamu sudah install Firebase CLI:

```bash
# 1. Login ke Firebase
firebase login

# 2. Initialize Firestore (jika belum)
firebase init firestore

# 3. Deploy rules
firebase deploy --only firestore:rules
```

---

## Penjelasan Security Rules

### Structure Rules
```
users/{userId}/
  ├── workouts/{workoutId}     → Pull-up workout sessions
  └── settings/{settingId}     → User settings (goal, preferences)
      └── goal                 → Target pull-ups goal
```

### Permission Logic

1. **isAuthenticated()**
   - Cek apakah user sudah login
   - `request.auth != null`

2. **isOwner(userId)**
   - Cek apakah user yang login adalah pemilik data
   - `request.auth.uid == userId`

3. **Users Collection**
   - ✅ Read: Hanya owner yang bisa read data mereka
   - ✅ Write: Hanya owner yang bisa create/update data mereka

4. **Subcollections (workouts, settings)**
   - ✅ Read/Write: Hanya owner yang bisa akses
   - ❌ User A tidak bisa akses data user B

### Keamanan

✅ **Secure by Default**
- Hanya authenticated users yang bisa akses
- User hanya bisa akses data mereka sendiri

✅ **Privacy Protected**
- User A tidak bisa lihat/edit goal user B
- User A tidak bisa lihat/edit workouts user B

✅ **Prevents**
- Unauthorized access
- Data tampering dari user lain
- Anonymous writes

---

## Troubleshooting

### Error Masih Muncul Setelah Update Rules?

1. **Clear App Data**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Restart App Completely**
   - Stop app di device
   - Run lagi: `flutter run`

3. **Check Auth Status**
   - Pastikan user sudah login
   - Cek di Firestore Console apakah user ID cocok

4. **Verify Rules Active**
   - Go to Firebase Console → Firestore → Rules
   - Check "Last Published" timestamp
   - Pastikan rules sudah ter-publish

### Masih Bermasalah?

**Debug dengan Console Log:**

Di `home_tab.dart`, tambahkan debug:

```dart
Future<void> _saveUserGoal(int targetPullUps) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('❌ No user logged in!');
      return;
    }

    debugPrint('✅ User ID: ${user.uid}');
    debugPrint('📝 Saving goal: $targetPullUps');

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('goal')
        .set({
          'targetPullUps': targetPullUps,
          'updatedAt': FieldValue.serverTimestamp(),
        });

    debugPrint('✅ Goal saved successfully!');
  } catch (e) {
    debugPrint('❌ Error saving goal: $e');
  }
}
```

---

## Test Checklist

Setelah update rules, test ini:

- [ ] Login dengan Google/Email
- [ ] Buka Home tab
- [ ] Klik edit icon di goal card
- [ ] Ubah goal ke nilai baru (misal: 50)
- [ ] Klik "Save Goal"
- [ ] ✅ Tidak ada error "permission denied"
- [ ] ✅ Goal berubah di UI
- [ ] ✅ Refresh app → goal tetap tersimpan
- [ ] ✅ Cek Firestore Console → data tersimpan

---

## File Terkait

- `/firestore.rules` - Security rules (untuk deploy via CLI)
- `/lib/screens/home_tab.dart` - Kode yang akses Firestore
- Firebase Console - Tempat publish rules secara manual

**IMPORTANT**: Security rules HARUS di-update di Firebase Console untuk apply perubahan!
