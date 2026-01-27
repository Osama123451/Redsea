/**
 * سكريبت رفع البيانات التجريبية إلى Firebase
 * 
 * الاستخدام:
 * 1. تأكد من أن لديك firebase-admin مثبت في مجلد functions
 * 2. قم بتعديل مسار ملف الاعتماد serviceAccount
 * 3. شغل الأمر: node upload_test_data.js
 */

const admin = require('firebase-admin');
const productsData = require('./products_data.json');
const servicesData = require('./services_data.json');

// ========================================
// تهيئة Firebase Admin
// ========================================

// الطريقة 1: استخدام ملف اعتماد الخدمة (موصى بها)
// const serviceAccount = require('../functions/serviceAccountKey.json');
// admin.initializeApp({
//   credential: admin.credential.cert(serviceAccount),
//   databaseURL: "https://your-project-id.firebaseio.com"
// });

// الطريقة 2: استخدام اعتماد التطبيق الافتراضي
admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    databaseURL: "https://redsea-shop-23e0a-default-rtdb.firebaseio.com"
});

const db = admin.database();

// ========================================
// دالة رفع المنتجات
// ========================================
async function uploadProducts() {
    console.log('\n📦 جاري رفع المنتجات...');
    console.log('-'.repeat(40));

    let successCount = 0;
    let errorCount = 0;

    for (const [productId, productData] of Object.entries(productsData)) {
        try {
            await db.ref(`products/${productId}`).set(productData);
            console.log(`✅ ${productData.category}: ${productData.name}`);
            successCount++;
        } catch (error) {
            console.log(`❌ فشل رفع ${productData.name}: ${error.message}`);
            errorCount++;
        }
    }

    console.log('-'.repeat(40));
    console.log(`نجح: ${successCount} | فشل: ${errorCount}`);
    return { successCount, errorCount };
}

// ========================================
// دالة رفع الخدمات
// ========================================
async function uploadServices() {
    console.log('\n🔧 جاري رفع الخدمات...');
    console.log('-'.repeat(40));

    let successCount = 0;
    let errorCount = 0;

    for (const [serviceId, serviceData] of Object.entries(servicesData)) {
        try {
            await db.ref(`services/${serviceId}`).set(serviceData);
            console.log(`✅ ${serviceData.category}: ${serviceData.title}`);
            successCount++;
        } catch (error) {
            console.log(`❌ فشل رفع ${serviceData.title}: ${error.message}`);
            errorCount++;
        }
    }

    console.log('-'.repeat(40));
    console.log(`نجح: ${successCount} | فشل: ${errorCount}`);
    return { successCount, errorCount };
}

// ========================================
// الدالة الرئيسية
// ========================================
async function main() {
    console.log('='.repeat(50));
    console.log('سكريبت رفع البيانات التجريبية إلى Firebase');
    console.log('='.repeat(50));
    console.log(`المستخدم المستهدف: ahmed000 (771727798)`);
    console.log(`عدد المنتجات: ${Object.keys(productsData).length}`);
    console.log(`عدد الخدمات: ${Object.keys(servicesData).length}`);

    try {
        // رفع المنتجات
        const productsResult = await uploadProducts();

        // رفع الخدمات
        const servicesResult = await uploadServices();

        // ملخص النتائج
        console.log('\n' + '='.repeat(50));
        console.log('📊 ملخص النتائج:');
        console.log('='.repeat(50));
        console.log(`المنتجات: ${productsResult.successCount} ناجح، ${productsResult.errorCount} فشل`);
        console.log(`الخدمات: ${servicesResult.successCount} ناجح، ${servicesResult.errorCount} فشل`);
        console.log('='.repeat(50));

        console.log('\n✅ تم الانتهاء!');
        process.exit(0);
    } catch (error) {
        console.error('\n❌ خطأ عام:', error.message);
        process.exit(1);
    }
}

// تشغيل السكريبت
main();
