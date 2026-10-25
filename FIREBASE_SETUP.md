# إعداد Firebase

1. افتح https://console.firebase.google.com وأنشئ مشروعاً جديداً.
2. أضف تطبيق **Android** واكتب اسم الحزمة بالضبط: `com.farmparty.farm_party`
   (لا تحتاج تنزيل google-services.json).
3. من إعدادات المشروع (Project settings → Your apps) انسخ:
   apiKey، appId، messagingSenderId، projectId، storageBucket.
4. **Authentication → Sign-in method**: فعّل **Email/Password** و **Anonymous**.
5. **Firestore Database → Create database**، ثم في تبويب Rules الصق:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

6. ضع المفاتيح بإحدى طريقتين:
   - **الأسهل:** عدّل القيم في `lib/core/firebase/firebase_options.dart`.
   - **GitHub Secrets** (Settings → Secrets and variables → Actions) بهذه الأسماء:
     `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`,
     `FIREBASE_PROJECT_ID`, `FIREBASE_STORAGE_BUCKET`.

## ملاحظات قبل النشر العام

- مفاتيح Firebase الخاصة بتطبيقات الهاتف ليست كلمة مرور بحد ذاتها، لكن يجب تقييدها من Google Cloud حسب التطبيقات وواجهات API المستخدمة.
- قواعد Firestore التي تسمح للمستخدم بالكتابة إلى وثيقته تمنع الوصول إلى وثائق الآخرين، لكنها لا تمنع صاحب الحساب من تزوير حقول الرصيد والمستوى داخل وثيقته.
- إذا كانت العملات أو المشتريات ذات قيمة حقيقية أو كانت اللعبة تنافسية، انقل عمليات تعديل الرصيد والمكافآت إلى Cloud Functions أو خادم موثوق، مع التحقق من كل عملية. لا تعتمد على رصيد يرسله العميل.
- اختبر قواعد Firestore باستخدام Firebase Emulator قبل إطلاق نسخة عامة، ولا تترك قواعد الاختبار مفتوحة.

## البيع داخل متجر البذور

يمكن للاعب بيع البذور الموجودة في مخزونه من بطاقة المحصول. قيمة الاسترداد الحالية هي 60% من سعر الشراء، وتُحدّث المحفظة والمخزون معاً. هذه سياسة توازن أولية قابلة للتعديل لاحقاً.

## اقتصاد اللعبة والمكافآت اليومية

المكافآت اليومية وسجل المعاملات في النسخة الحالية يُداران من كود العميل، لذلك لا تعتبرهما آمنين ضد التلاعب. إذا كانت اللعبة ستتضمن مشتريات حقيقية أو ترتيباً تنافسياً، انقل منح المكافأة وتحديث الرصيد إلى Cloud Functions أو خادم موثوق، واستخدم معرّفاً فريداً لكل مطالبة لمنع تكرار الطلبات. يجب أن تمنع قواعد Firestore العميل من تعديل حقول `money` و`gold` و`dailyStreak` مباشرة، وأن تسمح للخادم وحده بتحديثها. لا تنشر قواعد مفتوحة مثل `allow read, write: if true`.
