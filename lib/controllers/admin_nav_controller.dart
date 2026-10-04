import 'package:get/get.dart';

class AdminNavController extends GetxController {
  final currentIndex = 0.obs;

  final campaignEventsTabIndex = 0.obs;

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