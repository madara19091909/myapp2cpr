# تحديث رسومات الحيوانات — Farm Party

## الملفات المعدّلة
- `lib/features/farm/screens/farm_screen.dart`: عرض صور PNG للحيوانات المدعومة داخل المرعى بدلاً من الإيموجي، مع إبقاء حركة الارتداد البصرية والرجوع للإيموجي عند غياب الصورة.
- `pubspec.yaml`: تسجيل مجلد `assets/animals/` كأصول Flutter ورفع الإصدار إلى `1.0.2+3`.

## الملفات المضافة
- `assets/animals/cow_brown.png`
- `assets/animals/cow_holstein.png`
- `assets/animals/cow_white.png`
- `assets/animals/calf_brown.png`
- `assets/animals/calf_holstein.png`
- `assets/animals/calf_white.png`
- `assets/animals/chicken_hen.png`
- `assets/animals/chicken_chick.png`
- `assets/animals/sheep.png`
- `assets/animals/goat.png`
- `assets/animals/cat_orange.png`

## الربط الحالي
- البقر `cow` ← صورة البقرة الهولشتاين.
- الدجاج `chicken` ← صورة الدجاجة.
- الغنم `sheep` ← صورة الخروف.
- القطط `cat` ← صورة القطة البرتقالية.
- الأنواع الأخرى تستعمل الإيموجي كخيار احتياطي حتى نضيف رسومات مطابقة لها.

## ملاحظات
- صور الحزمة المضافة صور ثابتة وليست Sprite Sheets متحركة؛ الحركة الحالية هي حركة بصرية بسيطة موجودة في واجهة المرعى.
- لم يتم تشغيل `flutter test` أو بناء APK في بيئة العمل هذه، لذا يلزم اختبار المشروع بعد فك الضغط وتشغيل `flutter pub get`.
- الحزمة الأصلية تحمل اسم DEMO؛ تحقق من ترخيصها وشروط الاستخدام قبل نشر اللعبة.
