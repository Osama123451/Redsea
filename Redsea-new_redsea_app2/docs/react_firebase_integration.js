// ============================================
// 🔗 كود ربط React Admin Dashboard مع Firebase
// RedSea E-Commerce Platform
// ============================================

// ============================================
// 📦 1. تثبيت المكتبات المطلوبة
// ============================================
// npm install firebase react-router-dom

// ============================================
// 🔧 2. إعدادات Firebase - src/config/firebase.js
// ============================================

// firebase.js
import { initializeApp } from "firebase/app";
import { getDatabase } from "firebase/database";
import { getAuth } from "firebase/auth";
import { getStorage } from "firebase/storage";

// إعدادات Firebase الأصلية لمشروع RedSea
const firebaseConfig = {
  apiKey: "AIzaSyBA_up6goSlfs8eOH2C51zM6ViIazeU-w8",
  authDomain: "redsea-shop-23e0a.firebaseapp.com",
  databaseURL: "https://redsea-shop-23e0a-default-rtdb.firebaseio.com",
  projectId: "redsea-shop-23e0a",
  storageBucket: "redsea-shop-23e0a.firebasestorage.app",
  messagingSenderId: "523935837025",
  appId: "1:523935837025:web:c54a0c1993b54a5bccf320",
  measurementId: "G-J4820YK9PX"
};

// تهيئة Firebase
const app = initializeApp(firebaseConfig);

// تصدير الخدمات
export const db = getDatabase(app);
export const auth = getAuth(app);
export const storage = getStorage(app);
export default app;

// ============================================
// 👥 3. خدمة المستخدمين - src/services/usersService.js
// ============================================

// usersService.js
import { ref, get, update, remove, onValue, query, orderByChild, equalTo } from "firebase/database";
import { db } from "../config/firebase";

// جلب جميع المستخدمين
export const getAllUsers = async () => {
  const usersRef = ref(db, 'users');
  const snapshot = await get(usersRef);
  if (snapshot.exists()) {
    const usersData = snapshot.val();
    return Object.keys(usersData).map(key => ({
      id: key,
      ...usersData[key]
    }));
  }
  return [];
};

// جلب مستخدم واحد
export const getUserById = async (userId) => {
  const userRef = ref(db, `users/${userId}`);
  const snapshot = await get(userRef);
  if (snapshot.exists()) {
    return { id: userId, ...snapshot.val() };
  }
  return null;
};

// تحديث بيانات مستخدم
export const updateUser = async (userId, userData) => {
  const userRef = ref(db, `users/${userId}`);
  await update(userRef, {
    ...userData,
    updatedAt: Date.now()
  });
};

// حظر/إلغاء حظر مستخدم
export const toggleUserBan = async (userId, isBanned) => {
  const userRef = ref(db, `users/${userId}`);
  await update(userRef, {
    isBanned: isBanned,
    bannedAt: isBanned ? Date.now() : null
  });
};

// ترقية مستخدم لأدمن
export const promoteToAdmin = async (userId) => {
  const userRef = ref(db, `users/${userId}`);
  await update(userRef, { userType: 'admin' });
};

// حذف مستخدم
export const deleteUser = async (userId) => {
  const userRef = ref(db, `users/${userId}`);
  await remove(userRef);

  // حذف من جدول البحث أيضاً
  const userSnapshot = await get(userRef);
  if (userSnapshot.exists()) {
    const phone = userSnapshot.val().phone;
    if (phone) {
      const lookupRef = ref(db, `user_lookup/${phone}`);
      await remove(lookupRef);
    }
  }
};

// الاستماع للتغييرات في المستخدمين (Realtime)
export const subscribeToUsers = (callback) => {
  const usersRef = ref(db, 'users');
  return onValue(usersRef, (snapshot) => {
    if (snapshot.exists()) {
      const usersData = snapshot.val();
      const users = Object.keys(usersData).map(key => ({
        id: key,
        ...usersData[key]
      }));
      callback(users);
    } else {
      callback([]);
    }
  });
};

// إحصائيات المستخدمين
export const getUsersStats = async () => {
  const users = await getAllUsers();
  return {
    total: users.length,
    active: users.filter(u => !u.isBanned).length,
    banned: users.filter(u => u.isBanned).length,
    admins: users.filter(u => u.userType === 'admin').length,
    newThisWeek: users.filter(u => {
      const weekAgo = Date.now() - (7 * 24 * 60 * 60 * 1000);
      return u.createdAt > weekAgo;
    }).length
  };
};

// ============================================
// 📦 4. خدمة المنتجات - src/services/productsService.js
// ============================================

// productsService.js
import { ref, get, set, update, remove, push, onValue } from "firebase/database";
import { db } from "../config/firebase";

// جلب جميع المنتجات
export const getAllProducts = async () => {
  const productsRef = ref(db, 'products');
  const snapshot = await get(productsRef);
  if (snapshot.exists()) {
    const productsData = snapshot.val();
    return Object.keys(productsData).map(key => ({
      id: key,
      ...productsData[key]
    }));
  }
  return [];
};

// جلب منتجات مستخدم معين
export const getProductsByUser = async (userId) => {
  const products = await getAllProducts();
  return products.filter(p => p.userId === userId);
};

// جلب منتجات حسب التصنيف
export const getProductsByCategory = async (category) => {
  const products = await getAllProducts();
  return products.filter(p => p.category === category);
};

// إضافة منتج جديد
export const addProduct = async (productData) => {
  const productsRef = ref(db, 'products');
  const newProductRef = push(productsRef);
  await set(newProductRef, {
    ...productData,
    id: newProductRef.key,
    createdAt: Date.now(),
    updatedAt: Date.now()
  });
  return newProductRef.key;
};

// تحديث منتج
export const updateProduct = async (productId, productData) => {
  const productRef = ref(db, `products/${productId}`);
  await update(productRef, {
    ...productData,
    updatedAt: Date.now()
  });
};

// حذف منتج
export const deleteProduct = async (productId) => {
  const productRef = ref(db, `products/${productId}`);
  await remove(productRef);
};

// تفعيل/إلغاء تفعيل منتج
export const toggleProductStatus = async (productId, isActive) => {
  const productRef = ref(db, `products/${productId}`);
  await update(productRef, {
    isActive: isActive,
    updatedAt: Date.now()
  });
};

// الاستماع للتغييرات في المنتجات
export const subscribeToProducts = (callback) => {
  const productsRef = ref(db, 'products');
  return onValue(productsRef, (snapshot) => {
    if (snapshot.exists()) {
      const productsData = snapshot.val();
      const products = Object.keys(productsData).map(key => ({
        id: key,
        ...productsData[key]
      }));
      callback(products);
    } else {
      callback([]);
    }
  });
};

// إحصائيات المنتجات
export const getProductsStats = async () => {
  const products = await getAllProducts();
  const categories = [...new Set(products.map(p => p.category))];

  return {
    total: products.length,
    active: products.filter(p => p.isActive !== false).length,
    specialOffers: products.filter(p => p.isSpecialOffer).length,
    swappable: products.filter(p => p.negotiable).length,
    byCategory: categories.map(cat => ({
      category: cat,
      count: products.filter(p => p.category === cat).length
    }))
  };
};

// ============================================
// 🛒 5. خدمة الطلبات - src/services/ordersService.js
// ============================================

// ordersService.js
import { ref, get, update, remove, onValue } from "firebase/database";
import { db } from "../config/firebase";

// حالات الطلب
export const OrderStatus = {
  PENDING: 'pending',
  PAYMENT_PENDING: 'payment_pending',
  PAYMENT_CONFIRMED: 'payment_confirmed',
  SHIPPED: 'shipped',
  DELIVERED: 'delivered',
  COMPLETED: 'completed',
  CANCELLED: 'cancelled',
  REFUNDED: 'refunded'
};

// جلب جميع الطلبات
export const getAllOrders = async () => {
  const ordersRef = ref(db, 'orders');
  const snapshot = await get(ordersRef);
  if (snapshot.exists()) {
    const ordersData = snapshot.val();
    return Object.keys(ordersData).map(key => ({
      id: key,
      ...ordersData[key]
    }));
  }
  return [];
};

// جلب طلبات مستخدم (كمشتري)
export const getOrdersByBuyer = async (buyerId) => {
  const orders = await getAllOrders();
  return orders.filter(o => o.buyerId === buyerId);
};

// جلب طلبات مستخدم (كبائع)
export const getOrdersBySeller = async (sellerId) => {
  const orders = await getAllOrders();
  return orders.filter(o => o.sellerId === sellerId);
};

// تحديث حالة الطلب
export const updateOrderStatus = async (orderId, status, notes = '') => {
  const orderRef = ref(db, `orders/${orderId}`);
  await update(orderRef, {
    status,
    statusNotes: notes,
    updatedAt: Date.now(),
    statusHistory: {
      [Date.now()]: { status, notes, updatedBy: 'admin' }
    }
  });
};

// تأكيد الدفع
export const confirmPayment = async (orderId) => {
  await updateOrderStatus(orderId, OrderStatus.PAYMENT_CONFIRMED, 'تم تأكيد الدفع بواسطة الأدمن');
};

// إلغاء طلب
export const cancelOrder = async (orderId, reason) => {
  await updateOrderStatus(orderId, OrderStatus.CANCELLED, reason);
};

// استرداد المبلغ
export const refundOrder = async (orderId, reason) => {
  await updateOrderStatus(orderId, OrderStatus.REFUNDED, reason);
};

// الاستماع للطلبات الجديدة
export const subscribeToOrders = (callback) => {
  const ordersRef = ref(db, 'orders');
  return onValue(ordersRef, (snapshot) => {
    if (snapshot.exists()) {
      const ordersData = snapshot.val();
      const orders = Object.keys(ordersData).map(key => ({
        id: key,
        ...ordersData[key]
      }));
      callback(orders);
    } else {
      callback([]);
    }
  });
};

// إحصائيات الطلبات
export const getOrdersStats = async () => {
  const orders = await getAllOrders();
  const totalRevenue = orders
    .filter(o => o.status === OrderStatus.COMPLETED)
    .reduce((sum, o) => sum + (o.totalAmount || 0), 0);

  return {
    total: orders.length,
    pending: orders.filter(o => o.status === OrderStatus.PENDING).length,
    paymentPending: orders.filter(o => o.status === OrderStatus.PAYMENT_PENDING).length,
    completed: orders.filter(o => o.status === OrderStatus.COMPLETED).length,
    cancelled: orders.filter(o => o.status === OrderStatus.CANCELLED).length,
    totalRevenue,
    todayOrders: orders.filter(o => {
      const today = new Date().setHours(0, 0, 0, 0);
      return o.createdAt >= today;
    }).length
  };
};

// ============================================
// 🔄 6. خدمة المقايضات - src/services/swapsService.js
// ============================================

// swapsService.js
import { ref, get, update, remove, onValue } from "firebase/database";
import { db } from "../config/firebase";

// حالات المقايضة
export const SwapStatus = {
  PENDING: 'pending',
  ACCEPTED: 'accepted',
  REJECTED: 'rejected',
  COMPLETED: 'completed',
  CANCELLED: 'cancelled'
};

// جلب جميع طلبات المقايضة
export const getAllSwapRequests = async () => {
  const swapsRef = ref(db, 'swapRequests');
  const snapshot = await get(swapsRef);
  if (snapshot.exists()) {
    const swapsData = snapshot.val();
    return Object.keys(swapsData).map(key => ({
      id: key,
      ...swapsData[key]
    }));
  }
  return [];
};

// تحديث حالة المقايضة
export const updateSwapStatus = async (swapId, status, notes = '') => {
  const swapRef = ref(db, `swapRequests/${swapId}`);
  await update(swapRef, {
    status,
    adminNotes: notes,
    updatedAt: Date.now()
  });
};

// إلغاء مقايضة
export const cancelSwap = async (swapId, reason) => {
  await updateSwapStatus(swapId, SwapStatus.CANCELLED, reason);
};

// الاستماع للمقايضات
export const subscribeToSwaps = (callback) => {
  const swapsRef = ref(db, 'swapRequests');
  return onValue(swapsRef, (snapshot) => {
    if (snapshot.exists()) {
      const swapsData = snapshot.val();
      const swaps = Object.keys(swapsData).map(key => ({
        id: key,
        ...swapsData[key]
      }));
      callback(swaps);
    } else {
      callback([]);
    }
  });
};

// إحصائيات المقايضات
export const getSwapsStats = async () => {
  const swaps = await getAllSwapRequests();
  const totalValue = swaps
    .filter(s => s.status === SwapStatus.COMPLETED)
    .reduce((sum, s) => sum + (s.estimatedValue || 0), 0);

  return {
    total: swaps.length,
    pending: swaps.filter(s => s.status === SwapStatus.PENDING).length,
    completed: swaps.filter(s => s.status === SwapStatus.COMPLETED).length,
    rejected: swaps.filter(s => s.status === SwapStatus.REJECTED).length,
    totalValue
  };
};

// ============================================
// 🛠️ 7. خدمة الخدمات - src/services/servicesService.js
// ============================================

// servicesService.js
import { ref, get, update, remove, onValue } from "firebase/database";
import { db } from "../config/firebase";

// جلب جميع الخدمات
export const getAllServices = async () => {
  const servicesRef = ref(db, 'services');
  const snapshot = await get(servicesRef);
  if (snapshot.exists()) {
    const servicesData = snapshot.val();
    return Object.keys(servicesData).map(key => ({
      id: key,
      ...servicesData[key]
    }));
  }
  return [];
};

// تحديث خدمة
export const updateService = async (serviceId, serviceData) => {
  const serviceRef = ref(db, `services/${serviceId}`);
  await update(serviceRef, {
    ...serviceData,
    updatedAt: Date.now()
  });
};

// حذف خدمة
export const deleteService = async (serviceId) => {
  const serviceRef = ref(db, `services/${serviceId}`);
  await remove(serviceRef);
};

// تفعيل/إلغاء تفعيل خدمة
export const toggleServiceStatus = async (serviceId, isActive) => {
  const serviceRef = ref(db, `services/${serviceId}`);
  await update(serviceRef, {
    isActive: isActive,
    updatedAt: Date.now()
  });
};

// جلب طلبات الخدمات
export const getAllServiceOrders = async () => {
  const ordersRef = ref(db, 'serviceOrders');
  const snapshot = await get(ordersRef);
  if (snapshot.exists()) {
    const ordersData = snapshot.val();
    return Object.keys(ordersData).map(key => ({
      id: key,
      ...ordersData[key]
    }));
  }
  return [];
};

// إحصائيات الخدمات
export const getServicesStats = async () => {
  const services = await getAllServices();
  const serviceOrders = await getAllServiceOrders();

  return {
    totalServices: services.length,
    activeServices: services.filter(s => s.isActive !== false).length,
    totalOrders: serviceOrders.length,
    completedOrders: serviceOrders.filter(o => o.status === 'completed').length
  };
};

// ============================================
// 📂 8. خدمة التصنيفات - src/services/categoriesService.js
// ============================================

// categoriesService.js
import { ref, get, set, update, remove, push, onValue } from "firebase/database";
import { db } from "../config/firebase";

// التصنيفات الافتراضية
export const defaultCategories = [
  { name: 'الكل', icon: 'Apps', color: '#2196F3' },
  { name: 'الكترونيات', icon: 'Computer', color: '#3F51B5' },
  { name: 'أجهزة منزلية', icon: 'Kitchen', color: '#009688' },
  { name: 'ملابس', icon: 'Checkroom', color: '#E91E63' },
  { name: 'عطور', icon: 'Spa', color: '#9C27B0' },
  { name: 'ساعات', icon: 'Watch', color: '#FFC107' },
  { name: 'سيارات', icon: 'DirectionsCar', color: '#F44336' },
  { name: 'أثاث', icon: 'Chair', color: '#795548' },
  { name: 'خدمات', icon: 'DesignServices', color: '#4CAF50' },
  { name: 'أخرى', icon: 'Category', color: '#9E9E9E' }
];

// جلب جميع التصنيفات
export const getAllCategories = async () => {
  const categoriesRef = ref(db, 'categories');
  const snapshot = await get(categoriesRef);

  let customCategories = [];
  if (snapshot.exists()) {
    const categoriesData = snapshot.val();
    customCategories = Object.keys(categoriesData).map(key => ({
      id: key,
      isCustom: true,
      ...categoriesData[key]
    }));
  }

  return [...defaultCategories, ...customCategories];
};

// إضافة تصنيف جديد
export const addCategory = async (categoryData) => {
  const categoriesRef = ref(db, 'categories');
  const newCategoryRef = push(categoriesRef);
  await set(newCategoryRef, {
    ...categoryData,
    id: newCategoryRef.key,
    isCustom: true,
    createdAt: Date.now()
  });
  return newCategoryRef.key;
};

// تحديث تصنيف
export const updateCategory = async (categoryId, categoryData) => {
  const categoryRef = ref(db, `categories/${categoryId}`);
  await update(categoryRef, categoryData);
};

// حذف تصنيف
export const deleteCategory = async (categoryId) => {
  const categoryRef = ref(db, `categories/${categoryId}`);
  await remove(categoryRef);
};

// ============================================
// 📊 9. خدمة التقارير والإحصائيات - src/services/reportsService.js
// ============================================

// reportsService.js
import { getUsersStats } from './usersService';
import { getProductsStats } from './productsService';
import { getOrdersStats } from './ordersService';
import { getSwapsStats } from './swapsService';
import { getServicesStats } from './servicesService';

// جلب جميع الإحصائيات للوحة التحكم
export const getDashboardStats = async () => {
  const [users, products, orders, swaps, services] = await Promise.all([
    getUsersStats(),
    getProductsStats(),
    getOrdersStats(),
    getSwapsStats(),
    getServicesStats()
  ]);

  return {
    users,
    products,
    orders,
    swaps,
    services,
    summary: {
      totalUsers: users.total,
      totalProducts: products.total,
      totalOrders: orders.total,
      totalRevenue: orders.totalRevenue,
      activeSwaps: swaps.pending
    }
  };
};

// تقرير المبيعات
export const getSalesReport = async (startDate, endDate) => {
  const orders = await getAllOrders();

  return orders.filter(order => {
    const orderDate = order.createdAt;
    return orderDate >= startDate && orderDate <= endDate;
  });
};

// ============================================
// 🔐 10. خدمة المصادقة للأدمن - src/services/authService.js
// ============================================

// authService.js
import { signInWithEmailAndPassword, signOut, onAuthStateChanged } from "firebase/auth";
import { ref, get } from "firebase/database";
import { auth, db } from "../config/firebase";

// تسجيل دخول الأدمن
export const adminLogin = async (email, password) => {
  try {
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    const userId = userCredential.user.uid;

    // التحقق من أن المستخدم أدمن
    const userRef = ref(db, `users/${userId}`);
    const snapshot = await get(userRef);

    if (snapshot.exists()) {
      const userData = snapshot.val();
      if (userData.userType === 'admin') {
        return {
          success: true,
          user: { id: userId, ...userData }
        };
      } else {
        await signOut(auth);
        return {
          success: false,
          error: 'ليس لديك صلاحيات الأدمن'
        };
      }
    }

    await signOut(auth);
    return {
      success: false,
      error: 'المستخدم غير موجود'
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
};

// تسجيل الخروج
export const adminLogout = async () => {
  await signOut(auth);
};

// مراقبة حالة المصادقة
export const onAuthChange = (callback) => {
  return onAuthStateChanged(auth, async (user) => {
    if (user) {
      const userRef = ref(db, `users/${user.uid}`);
      const snapshot = await get(userRef);
      if (snapshot.exists() && snapshot.val().userType === 'admin') {
        callback({ id: user.uid, ...snapshot.val() });
      } else {
        callback(null);
      }
    } else {
      callback(null);
    }
  });
};

// ============================================
// 🖥️ 11. مكون لوحة التحكم الرئيسية - src/pages/Dashboard.jsx
// ============================================

/*
// Dashboard.jsx

import React, { useState, useEffect } from 'react';
import { getDashboardStats } from '../services/reportsService';
import { subscribeToOrders } from '../services/ordersService';
import { subscribeToUsers } from '../services/usersService';

const Dashboard = () => {
  const [stats, setStats] = useState(null);
  const [recentOrders, setRecentOrders] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // جلب الإحصائيات
    const loadStats = async () => {
      const data = await getDashboardStats();
      setStats(data);
      setLoading(false);
    };
    loadStats();

    // الاستماع للطلبات الجديدة
    const unsubscribe = subscribeToOrders((orders) => {
      // آخر 10 طلبات
      const recent = orders
        .sort((a, b) => b.createdAt - a.createdAt)
        .slice(0, 10);
      setRecentOrders(recent);
    });

    return () => unsubscribe();
  }, []);

  if (loading) {
    return (
      <div className="loading">
        <div className="spinner"></div>
        <p>جاري التحميل...</p>
      </div>
    );
  }

  return (
    <div className="dashboard" dir="rtl">
      <h1>لوحة تحكم RedSea</h1>
      
      {/* بطاقات الإحصائيات */}
<div className="stats-grid">
  <div className="stat-card users">
    <div className="stat-icon">👥</div>
    <div className="stat-info">
      <h3>المستخدمين</h3>
      <p className="stat-number">{stats.users.total}</p>
      <span className="stat-detail">+{stats.users.newThisWeek} هذا الأسبوع</span>
    </div>
  </div>

  <div className="stat-card products">
    <div className="stat-icon">📦</div>
    <div className="stat-info">
      <h3>المنتجات</h3>
      <p className="stat-number">{stats.products.total}</p>
      <span className="stat-detail">{stats.products.specialOffers} عرض خاص</span>
    </div>
  </div>

  <div className="stat-card orders">
    <div className="stat-icon">🛒</div>
    <div className="stat-info">
      <h3>الطلبات</h3>
      <p className="stat-number">{stats.orders.total}</p>
      <span className="stat-detail">{stats.orders.pending} قيد الانتظار</span>
    </div>
  </div>

  <div className="stat-card revenue">
    <div className="stat-icon">💰</div>
    <div className="stat-info">
      <h3>الإيرادات</h3>
      <p className="stat-number">{stats.orders.totalRevenue.toLocaleString()}</p>
      <span className="stat-detail">ريال يمني</span>
    </div>
  </div>

  <div className="stat-card swaps">
    <div className="stat-icon">🔄</div>
    <div className="stat-info">
      <h3>المقايضات</h3>
      <p className="stat-number">{stats.swaps.total}</p>
      <span className="stat-detail">{stats.swaps.completed} مكتمل</span>
    </div>
  </div>

  <div className="stat-card services">
    <div className="stat-icon">🛠️</div>
    <div className="stat-info">
      <h3>الخدمات</h3>
      <p className="stat-number">{stats.services.totalServices}</p>
      <span className="stat-detail">{stats.services.totalOrders} طلب</span>
    </div>
  </div>
</div>

{/* آخر الطلبات */ }
<section className="recent-orders">
  <h2>آخر الطلبات</h2>
  <table>
    <thead>
      <tr>
        <th>رقم الطلب</th>
        <th>المشتري</th>
        <th>المبلغ</th>
        <th>الحالة</th>
        <th>التاريخ</th>
        <th>إجراءات</th>
      </tr>
    </thead>
    <tbody>
      {recentOrders.map(order => (
        <tr key={order.id}>
          <td>#{order.id.slice(-6)}</td>
          <td>{order.buyerName || 'غير محدد'}</td>
          <td>{order.totalAmount} ر.ي</td>
          <td>
            <span className={`status-badge ${order.status}`}>
              {getStatusLabel(order.status)}
            </span>
          </td>
          <td>{new Date(order.createdAt).toLocaleDateString('ar-YE')}</td>
          <td>
            <button className="btn-view">عرض</button>
          </td>
        </tr>
      ))}
    </tbody>
  </table>
</section>
    </div >
  );
};

// دالة مساعدة لتحويل الحالة للعربية
const getStatusLabel = (status) => {
  const labels = {
    'pending': 'قيد الانتظار',
    'payment_pending': 'بانتظار الدفع',
    'payment_confirmed': 'تم التأكيد',
    'shipped': 'تم الشحن',
    'delivered': 'تم التوصيل',
    'completed': 'مكتمل',
    'cancelled': 'ملغي',
    'refunded': 'مسترد'
  };
  return labels[status] || status;
};

export default Dashboard;
*/

  // ============================================
  // 🎨 12. ملف CSS للوحة التحكم - src/styles/dashboard.css
  // ============================================

  /*
  /* dashboard.css */

  .dashboard {
  padding: 20px;
  background: #f5f7fa;
  min - height: 100vh;
}

.dashboard h1 {
  color: #2196F3;
  margin - bottom: 30px;
}

.stats - grid {
  display: grid;
  grid - template - columns: repeat(auto - fit, minmax(200px, 1fr));
  gap: 20px;
  margin - bottom: 40px;
}

.stat - card {
  background: white;
  border - radius: 16px;
  padding: 20px;
  box - shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
  display: flex;
  align - items: center;
  gap: 16px;
  transition: transform 0.2s, box - shadow 0.2s;
}

.stat - card:hover {
  transform: translateY(-4px);
  box - shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
}

.stat - icon {
  font - size: 40px;
}

.stat - number {
  font - size: 28px;
  font - weight: bold;
  color: #333;
}

.stat - detail {
  font - size: 12px;
  color: #666;
}

.stat - card.users { border - right: 4px solid #2196F3; }
.stat - card.products { border - right: 4px solid #4CAF50; }
.stat - card.orders { border - right: 4px solid #FF9800; }
.stat - card.revenue { border - right: 4px solid #9C27B0; }
.stat - card.swaps { border - right: 4px solid #00BCD4; }
.stat - card.services { border - right: 4px solid #F44336; }

.recent - orders table {
  width: 100 %;
  background: white;
  border - radius: 12px;
  overflow: hidden;
  box - shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
}

.recent - orders th {
  background: #2196F3;
  color: white;
  padding: 16px;
  text - align: right;
}

.recent - orders td {
  padding: 14px 16px;
  border - bottom: 1px solid #eee;
}

.status - badge {
  padding: 4px 12px;
  border - radius: 20px;
  font - size: 12px;
}

.status - badge.pending { background: #FFF3E0; color: #E65100; }
.status - badge.completed { background: #E8F5E9; color: #2E7D32; }
.status - badge.cancelled { background: #FFEBEE; color: #C62828; }

.btn - view {
  background: #2196F3;
  color: white;
  border: none;
  padding: 6px 16px;
  border - radius: 6px;
  cursor: pointer;
}

.loading {
  display: flex;
  flex - direction: column;
  align - items: center;
  justify - content: center;
  height: 100vh;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #eee;
  border - top - color: #2196F3;
  border - radius: 50 %;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
*/

// ============================================
// 🔒 13. قواعد الأمان للأدمن - Firebase Rules
// ============================================

/*
{
  "rules": {
    // دالة التحقق من الأدمن
    ".read": false,
    ".write": false,
    
    // جدول البحث عن المستخدمين - للقراءة العامة
    "user_lookup": {
      ".read": true,
      ".write": "auth != null"
    },
    
    // المستخدمين
    "users": {
      ".read": "auth != null",
      "$uid": {
        ".write": "auth != null && (auth.uid == $uid || root.child('users').child(auth.uid).child('userType').val() == 'admin')",
        ".read": "auth != null"
      }
    },
    
    // المنتجات - قراءة عامة، كتابة للمسجلين
    "products": {
      ".read": true,
      ".write": "auth != null",
      "$productId": {
        // يمكن للمالك أو الأدمن التعديل
        ".write": "auth != null && (data.child('userId').val() == auth.uid || root.child('users').child(auth.uid).child('userType').val() == 'admin')"
      }
    },
    
    // الطلبات
    "orders": {
      ".read": "auth != null",
      ".write": "auth != null",
      "$orderId": {
        // يمكن للمشتري أو البائع أو الأدمن الوصول
        ".read": "auth != null && (data.child('buyerId').val() == auth.uid || data.child('sellerId').val() == auth.uid || root.child('users').child(auth.uid).child('userType').val() == 'admin')"
      }
    },
    
    // المقايضات
    "swapRequests": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    
    // الخدمات - قراءة عامة
    "services": {
      ".read": true,
      ".write": "auth != null"
    },
    
    // طلبات الخدمات
    "serviceOrders": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    
    // التصنيفات
    "categories": {
      ".read": true,
      ".write": "auth != null"
    },
    
    // الإشعارات
    "notifications": {
      "$uid": {
        ".read": "auth != null && auth.uid == $uid",
        ".write": "auth != null"
      }
    },
    
    // المفضلات
    "favorites": {
      "$uid": {
        ".read": "auth != null && auth.uid == $uid",
        ".write": "auth != null && auth.uid == $uid"
      }
    },
    
    // المحادثات
    "chats": {
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
}
*/

// ============================================
// ✅ ملاحظات مهمة
// ============================================

/*
📋 خطوات الإعداد:

1. أنشئ مشروع React جديد:
   npx create-react-app redsea-admin --template typescript
   
2. ثبّت المكتبات:
   npm install firebase react-router-dom

3. انسخ الملفات إلى المجلدات المناسبة:
   - src/config/firebase.js
   - src/services/*.js (جميع خدمات الـ API)
   - src/pages/*.jsx (مكونات الصفحات)
   - src/styles/*.css (ملفات الأنماط)

4. أضف مسارات التنقل في App.jsx

5. اختبر الاتصال بـ Firebase

⚠️ ملاحظات أمنية:
- لا تشارك ملف firebase.js علناً
- استخدم متغيرات البيئة (.env) لحفظ المفاتيح
- تأكد من قواعد الأمان في Firebase
- أضف نظام تسجيل دخول للأدمن

🔥 الميزات المتوفرة:
✅ إدارة المستخدمين (حظر/ترقية/حذف)
✅ إدارة المنتجات (تعديل/حذف/تفعيل)
✅ إدارة الطلبات (تحديث الحالة/إلغاء/استرداد)
✅ إدارة المقايضات
✅ إدارة الخدمات
✅ إحصائيات ولوحة تحكم
✅ تحديثات في الوقت الفعلي (Realtime)
*/

console.log("✅ تم إعداد كود ربط React Admin Dashboard مع Firebase بنجاح!");
console.log("📁 الملف: docs/react_firebase_integration_complete.js");
