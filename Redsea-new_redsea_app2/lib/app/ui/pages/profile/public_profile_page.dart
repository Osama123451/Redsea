import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redsea/app/models/user_profile_model.dart';
import 'package:redsea/app/models/review_model.dart';
import 'package:redsea/app/ui/widgets/rating_star_widget.dart';
import 'package:redsea/app/ui/dialogs/add_review_dialog.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/product_details_page.dart';
import 'package:redsea/app/controllers/cart_controller.dart';

/// صفحة الملف الشخصي العام للمستخدم
class PublicProfilePage extends StatefulWidget {
  final String userId;

  const PublicProfilePage({super.key, required this.userId});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  UserProfile? _userProfile;
  List<Product> _userProducts = [];
  List<UserReview> _userReviews = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // تحميل بيانات المستخدم
      final userSnapshot = await _dbRef.child('users/${widget.userId}').once();
      if (userSnapshot.snapshot.value != null) {
        final userData =
            Map<String, dynamic>.from(userSnapshot.snapshot.value as Map);
        _userProfile = UserProfile.fromMap(widget.userId, userData);
      } else {
        _error = 'لم يتم العثور على المستخدم';
        setState(() => _isLoading = false);
        return;
      }

      // تحميل منتجات المستخدم
      final productsSnapshot = await _dbRef
          .child('products')
          .orderByChild('sellerId')
          .equalTo(widget.userId)
          .once();

      if (productsSnapshot.snapshot.value != null) {
        final productsData =
            Map<String, dynamic>.from(productsSnapshot.snapshot.value as Map);
        _userProducts = productsData.entries.map((e) {
          final data = Map<String, dynamic>.from(e.value);
          data['id'] = e.key;
          return Product.fromMap(data);
        }).toList();

        // ترتيب حسب الأحدث
        _userProducts.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      }

      // تحميل تقييمات المستخدم
      final reviewsSnapshot = await _dbRef
          .child('reviews')
          .orderByChild('ratedUserId')
          .equalTo(widget.userId)
          .once();

      if (reviewsSnapshot.snapshot.value != null) {
        final reviewsData =
            Map<String, dynamic>.from(reviewsSnapshot.snapshot.value as Map);
        _userReviews = reviewsData.entries.map((e) {
          return UserReview.fromMap(e.key, Map<String, dynamic>.from(e.value));
        }).toList();

        // ترتيب حسب الأحدث
        _userReviews.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'خطأ في تحميل البيانات: $e';
        _isLoading = false;
      });
    }
  }

  bool get _canReview {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    if (currentUser.uid == widget.userId) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUserData,
                  child: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      SliverToBoxAdapter(child: _buildProfileHeader()),
                      SliverToBoxAdapter(child: _buildStatsRow()),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _TabBarDelegate(
                          TabBar(
                            controller: _tabController,
                            labelColor: Colors.blue,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Colors.blue,
                            tabs: [
                              Tab(text: 'المنتجات (${_userProducts.length})'),
                              Tab(text: 'التقييمات (${_userReviews.length})'),
                            ],
                          ),
                        ),
                      ),
                    ],
                    body: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildProductsTab(),
                        _buildReviewsTab(),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: _canReview
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await showAddReviewDialog(
                  ratedUserId: widget.userId,
                  ratedUserName: _userProfile?.name ?? 'مستخدم',
                );
                if (result == true) {
                  _loadUserData();
                }
              },
              icon: const Icon(Icons.star),
              label: const Text('أضف تقييم'),
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade700, Colors.blue.shade500],
        ),
      ),
      child: Column(
        children: [
          // الصورة الشخصية
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: _userProfile?.photoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          _userProfile!.photoUrl!,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Text(
                            _userProfile?.initial ?? 'م',
                            style: const TextStyle(
                                fontSize: 40, color: Colors.blue),
                          ),
                        ),
                      )
                    : Text(
                        _userProfile?.initial ?? 'م',
                        style:
                            const TextStyle(fontSize: 40, color: Colors.blue),
                      ),
              ),
              if (_userProfile?.isVerified ?? false)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // الاسم
          Text(
            _userProfile?.name ?? 'مستخدم',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          // تاريخ الانضمام
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                'عضو منذ ${_userProfile?.formattedJoinDate ?? ''}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // التقييم
          if ((_userProfile?.trustScore ?? 0) > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RatingStarWidget(
                    rating: _userProfile?.trustScore ?? 0,
                    size: 20,
                    activeColor: Colors.amber,
                    showValue: true,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${_userProfile?.trustLevelText ?? ''})',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: Icons.inventory_2,
            value: '${_userProducts.length}',
            label: 'المنتجات',
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          _buildStatItem(
            icon: Icons.swap_horiz,
            value: '${_userProfile?.swapsCount ?? 0}',
            label: 'المقايضات',
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          _buildStatItem(
            icon: Icons.star,
            value: '${_userReviews.length}',
            label: 'التقييمات',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildProductsTab() {
    if (_userProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'لا توجد منتجات',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _userProducts.length,
      itemBuilder: (context, index) {
        final product = _userProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        final cartController = Get.find<CartController>();
        Get.to(() => ProductDetailsPage(
              product: product,
              cartItems: cartController.cartItems.toList(),
              onAddToCart: (p) => cartController.addToCart(p),
              onRemoveFromCart: (id) => cartController.removeFromCart(id),
              onUpdateQuantity: (id, qty) =>
                  cartController.updateQuantity(id, qty),
            ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصورة
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  image: product.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(product.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: product.imageUrl.isEmpty
                    ? const Center(
                        child: Icon(Icons.image, size: 40, color: Colors.grey))
                    : null,
              ),
            ),
            // المعلومات
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      '${product.price} ريال',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (_userReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.reviews_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'لا توجد تقييمات بعد',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            if (_canReview) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await showAddReviewDialog(
                    ratedUserId: widget.userId,
                    ratedUserName: _userProfile?.name ?? 'مستخدم',
                  );
                  if (result == true) {
                    _loadUserData();
                  }
                },
                icon: const Icon(Icons.star),
                label: const Text('كن أول من يُقيّم'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _userReviews.length,
      itemBuilder: (context, index) {
        final review = _userReviews[index];
        return _buildReviewCard(review);
      },
    );
  }

  Widget _buildReviewCard(UserReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس التقييم
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  review.raterName.isNotEmpty
                      ? review.raterName[0].toUpperCase()
                      : 'م',
                  style: const TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.raterName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatDate(review.timestamp),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              RatingStarWidget(
                rating: review.rating,
                size: 16,
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: const TextStyle(height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return 'منذ ${diff.inMinutes} دقيقة';
      }
      return 'منذ ${diff.inHours} ساعة';
    } else if (diff.inDays < 7) {
      return 'منذ ${diff.inDays} يوم';
    } else if (diff.inDays < 30) {
      return 'منذ ${(diff.inDays / 7).floor()} أسبوع';
    } else {
      return 'منذ ${(diff.inDays / 30).floor()} شهر';
    }
  }
}

/// مفوض لـ TabBar الثابت
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
