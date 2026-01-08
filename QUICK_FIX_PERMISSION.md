# 🔧 Quick Fix: Firestore Permission Denied

## ❌ Error
```
PERMISSION_DENIED: Missing or insufficient permissions
Error saving goal: permission-denied
```

## ✅ Solusi Cepat (5 Menit)

### Step-by-Step

**1. Buka Firebase Console**
```
https://console.firebase.google.com/
```

**2. Pilih Project**
- Klik project: **pull-up-detection-app**

**3. Go to Firestore Rules**
```
Sidebar → Firestore Database → Tab "Rules"
```

**4. Replace Semua Rules dengan:**

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /workouts/{workoutId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      match /settings/{settingId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

**5. Publish**
- Klik tombol **"Publish"** (biru, pojok kanan atas)
- Tunggu "Published successfully" muncul

**6. Test**
```bash
# Stop app
Ctrl+C (di terminal)

# Run lagi
flutter run -d QWBYPBQ4USXCUWQ4
```

**7. Test Set Goal**
- Buka app → Home tab
- Klik edit icon (pensil)
- Set goal baru → Save
- ✅ Seharusnya TIDAK ada error lagi!

---

## 🎯 Apa Yang Rules Ini Lakukan?

### Before (Error)
```
❌ Default rules = deny everything
❌ User tidak bisa write ke settings/goal
❌ Error: PERMISSION_DENIED
```

### After (Fixed)
```
✅ User yang login bisa read/write DATA MEREKA SENDIRI
✅ User A tidak bisa akses data User B
✅ Aman dan sesuai best practice
```

---

## 🔍 Cara Verify Rules Sudah Aktif

**Di Firebase Console:**
1. Go to: Firestore Database → Rules
2. Lihat timestamp "Last published"
3. Pastikan baru (beberapa menit yang lalu)

**Di App:**
1. Set goal baru
2. Cek terminal - tidak ada error PERMISSION_DENIED
3. Cek Firestore Console → users/{userId}/settings/goal → data tersimpan

---

## 💡 Troubleshooting

### Masih Error?

**1. Pastikan User Sudah Login**
```dart
// Di home_tab.dart, cek ini:
final user = FirebaseAuth.instance.currentUser;
print('User ID: ${user?.uid}'); // Harus ada ID, bukan null
```

**2. Clear Cache**
```bash
flutter clean
flutter pub get
flutter run
```

**3. Check Rules Format**
- Pastikan tidak ada typo
- Pastikan syntax JavaScript benar
- Pastikan ada closing brackets

**4. Internet Connection**
- Firestore butuh internet untuk sync rules
- Pastikan device connected

---

## 📝 Quick Reference

### Collection Structure
```
users/
  └── {userId}/
      ├── workouts/
      │   └── {workoutId}
      └── settings/
          └── goal
```

### Who Can Access What?
```
✅ User123 → users/User123/* (READ + WRITE)
❌ User123 → users/User456/* (BLOCKED)
❌ Anonymous → users/* (BLOCKED)
```

---

## ⚡ Next Steps

Setelah rules di-update:

1. ✅ Set goal feature akan work
2. ✅ Save workouts akan work
3. ✅ Read data akan work
4. ✅ Real-time updates akan work

**File yang sudah dibuat:**
- `/firestore.rules` → Template rules (bisa deploy via CLI)
- `/FIX_FIRESTORE_PERMISSION.md` → Dokumentasi lengkap
- `/QUICK_FIX_PERMISSION.md` → Guide ini

**Langkah selanjutnya:**
- Update rules di Firebase Console (WAJIB!)
- Test app
- Jika work, delete files dokumentasi ini (opsional)
