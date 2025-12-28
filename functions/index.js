const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
admin.initializeApp();

// إعداد البريد الإلكتروني
// يمكنك استخدام Gmail أو أي خدمة SMTP أخرى
// لاستخدام Gmail: قم بتفعيل "App Passwords" في حساب Google
const mailTransport = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: 'osamammm018@gmail.com',
        pass: 'aunm rgxj gkjw ciut'
    }
});

// دالة إرسال كود OTP عبر البريد الإلكتروني
exports.sendOtpEmail = functions.https.onCall(async (data, context) => {
    const { email, otp, userId } = data;

    if (!email || !otp) {
        throw new functions.https.HttpsError('invalid-argument', 'Email and OTP are required');
    }

    const mailOptions = {
        from: '"RedSea App" <noreply@redsea.com>',
        to: email,
        subject: '🔐 رمز التحقق - RedSea',
        html: `
            <div dir="rtl" style="font-family: Arial, sans-serif; padding: 20px; background-color: #f5f5f5;">
                <div style="max-width: 400px; margin: 0 auto; background: white; border-radius: 10px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
                    <h2 style="color: #1976D2; text-align: center; margin-bottom: 20px;">🔐 رمز التحقق</h2>
                    <p style="text-align: center; color: #666; font-size: 16px;">استخدم الرمز التالي لتأكيد هويتك:</p>
                    <div style="background: #E3F2FD; border-radius: 8px; padding: 20px; margin: 20px 0; text-align: center;">
                        <span style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #1976D2;">${otp}</span>
                    </div>
                    <p style="text-align: center; color: #999; font-size: 14px;">⏱️ هذا الرمز صالح لمدة 5 دقائق فقط</p>
                    <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
                    <p style="text-align: center; color: #999; font-size: 12px;">إذا لم تطلب هذا الرمز، تجاهل هذا البريد.</p>
                    <p style="text-align: center; color: #1976D2; font-size: 14px; font-weight: bold;">RedSea App 🌊</p>
                </div>
            </div>
        `
    };

    try {
        await mailTransport.sendMail(mailOptions);
        console.log('✅ OTP email sent to:', email);
        return { success: true, message: 'Email sent successfully' };
    } catch (error) {
        console.error('❌ Error sending email:', error);
        throw new functions.https.HttpsError('internal', 'Failed to send email');
    }
});

exports.sendMessageNotification = functions.database.ref('/messages/{chatId}/{messageId}')
    .onCreate(async (snapshot, context) => {
        const message = snapshot.val();
        const chatId = context.params.chatId;
        const senderId = message.senderId;

        // الحصول على بيانات الدردشة
        const chatSnapshot = await admin.database().ref(`/chats/${chatId}`).once('value');
        const chatData = chatSnapshot.val();

        if (!chatData) return null;

        // تحديد المستقبل
        const receiverId = chatData.user1Id === senderId ? chatData.user2Id : chatData.user1Id;

        // الحصول على بيانات المرسل
        const senderSnapshot = await admin.database().ref(`/users/${senderId}`).once('value');
        const senderData = senderSnapshot.val();

        // الحصول على token الإشعارات للمستقبل
        const userDevicesSnapshot = await admin.database().ref(`/user_devices/${receiverId}`).once('value');
        const tokens = userDevicesSnapshot.val();

        if (!tokens || Object.keys(tokens).length === 0) {
            console.log('No tokens available for user:', receiverId);
            return null;
        }

        // إنشاء الإشعار
        const payload = {
            notification: {
                title: senderData ? senderData.name : 'New Message',
                body: message.text || 'You have a new message',
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
            },
            data: {
                type: 'message',
                chatId: chatId,
                senderId: senderId,
                senderName: senderData ? senderData.name : '',
                message: message.text || '',
                timestamp: String(message.timestamp || Date.now())
            }
        };

        // إرسال الإشعارات
        const response = await admin.messaging().sendToDevice(Object.keys(tokens), payload);

        // حذف Tokens غير النشطة
        const tokensToRemove = [];
        response.results.forEach((result, index) => {
            const error = result.error;
            if (error) {
                if (error.code === 'messaging/invalid-registration-token' ||
                    error.code === 'messaging/registration-token-not-registered') {
                    tokensToRemove.push(Object.keys(tokens)[index]);
                }
            }
        });

        if (tokensToRemove.length > 0) {
            const updates = {};
            tokensToRemove.forEach(token => {
                updates[token] = null;
            });
            await admin.database().ref(`/user_devices/${receiverId}`).update(updates);
        }

        return null;
    });
