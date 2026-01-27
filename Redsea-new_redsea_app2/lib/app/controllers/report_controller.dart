import 'package:get/get.dart';
import 'package:redsea/models/report_model.dart';
import 'package:redsea/services/report_service.dart';

/// متحكم التقارير والإحصائيات
class ReportController extends GetxController {
  // البيانات
  final Rx<UserReport> report = UserReport().obs;
  final RxBool isLoading = false.obs;
  final Rx<ReportPeriod> selectedPeriod = ReportPeriod.thisMonth.obs;

  // للفترات المخصصة
  final Rx<DateTime> customStartDate =
      DateTime.now().subtract(const Duration(days: 30)).obs;
  final Rx<DateTime> customEndDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    loadReport();
  }

  /// تحميل التقرير
  Future<void> loadReport() async {
    isLoading.value = true;
    try {
      report.value = await ReportService.generateReport(
        period: selectedPeriod.value,
        customStartDate: selectedPeriod.value == ReportPeriod.custom
            ? customStartDate.value
            : null,
        customEndDate: selectedPeriod.value == ReportPeriod.custom
            ? customEndDate.value
            : null,
      );
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحميل التقرير');
    } finally {
      isLoading.value = false;
    }
  }

  /// تغيير الفترة الزمنية
  void changePeriod(ReportPeriod period) {
    selectedPeriod.value = period;
    loadReport();
  }

  /// تعيين فترة مخصصة
  void setCustomPeriod(DateTime start, DateTime end) {
    customStartDate.value = start;
    customEndDate.value = end;
    selectedPeriod.value = ReportPeriod.custom;
    loadReport();
  }
}
