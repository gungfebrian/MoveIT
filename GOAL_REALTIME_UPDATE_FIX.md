# Goal Real-Time Update Fix

## Masalah
Ketika user mengubah goal di home tab, UI tidak otomatis refresh untuk menampilkan goal yang baru.

## Penyebab
Sebelumnya menggunakan `FutureBuilder` dengan `_fetchUserGoal()` yang dipanggil langsung di parameter `future:`. Future hanya dijalankan sekali saat widget pertama kali dibuild, sehingga tidak akan otomatis update ketika data di Firestore berubah.

## Solusi
Mengubah implementasi dari `FutureBuilder` menjadi kombinasi `StreamBuilder` + `FutureBuilder`:

### 1. Membuat Stream untuk Goal
```dart
Stream<int> _getUserGoalStream() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(100);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('settings')
      .doc('goal')
      .snapshots()
      .map((doc) {
    if (doc.exists && doc.data() != null) {
      return doc.data()!['targetPullUps'] as int? ?? 100;
    }
    return 100;
  });
}
```

### 2. Memisahkan Fungsi untuk Get Total Pull-Ups
```dart
Future<int> _getTotalPullUps() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    final workoutsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('workouts')
        .get();

    int totalPullUps = 0;
    for (var doc in workoutsSnapshot.docs) {
      totalPullUps += (doc.data()['pullUpCount'] as int? ?? 0);
    }

    return totalPullUps;
  } catch (e) {
    debugPrint('Error fetching total pull-ups: $e');
    return 0;
  }
}
```

### 3. Menggunakan Nested Builders
```dart
StreamBuilder<int>(
  stream: _getUserGoalStream(), // Real-time goal updates
  builder: (context, goalSnapshot) {
    final goal = goalSnapshot.data ?? 100;
    
    return FutureBuilder<int>(
      future: _getTotalPullUps(), // Get current total
      builder: (context, currentSnapshot) {
        final current = currentSnapshot.data ?? 0;
        // Build UI with goal and current
      },
    );
  },
)
```

## Keuntungan
✅ **Real-time Updates**: Goal otomatis update ketika diubah di Firestore
✅ **Tidak Perlu setState**: StreamBuilder otomatis rebuild saat data berubah
✅ **Lebih Efisien**: Hanya listen ke perubahan goal document, bukan seluruh collection
✅ **User Experience Lebih Baik**: User langsung melihat perubahan tanpa perlu refresh manual

## Cara Kerja
1. User klik tombol edit goal
2. Dialog terbuka untuk input goal baru
3. User save goal → data disimpan ke Firestore
4. Firestore mengirim event update ke StreamBuilder
5. StreamBuilder otomatis rebuild dengan goal baru
6. UI langsung menampilkan goal yang updated

## Testing
1. Buka app dan login
2. Lihat goal card di home tab (default: 100)
3. Klik tombol edit (icon pensil)
4. Ubah goal ke nilai lain (misal: 50)
5. Klik "Save Goal"
6. ✅ Goal card langsung update tanpa perlu refresh halaman
7. ✅ Progress bar dan percentage otomatis recalculate
8. ✅ Message "X more to reach your goal" otomatis update

## File yang Diubah
- `/lib/screens/home_tab.dart`:
  - Menghapus `_fetchUserGoal()` yang mengembalikan `Map<String, dynamic>`
  - Menambahkan `_getUserGoalStream()` untuk real-time goal updates
  - Menambahkan `_getTotalPullUps()` untuk mendapatkan total pull-ups
  - Mengubah Goals Card dari `FutureBuilder` ke nested `StreamBuilder` + `FutureBuilder`
  - Menghapus `setState(() {})` dari `_showSetGoalDialog` (tidak diperlukan lagi)
