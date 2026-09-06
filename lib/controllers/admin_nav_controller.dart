import 'package:get/get.dart';

class AdminNavController extends GetxController {
  final currentIndex = 0.obs;

  // 0 = Campaigns, 1 = Events
  final campaignEventsTabIndex = 0.obs;

  // Har request par increment hota hai taake same tab dobara
  // request karne par bhi listener trigger ho.
  final campaignEventsRequestId = 0.obs;

  void changeTab(int index) {
    currentIndex.value = index;
  }

  void openCampaignsEventsTab(int tabIndex) {
    campaignEventsTabIndex.value = tabIndex;
    campaignEventsRequestId.value++;
    currentIndex.value = 1;
  }
}