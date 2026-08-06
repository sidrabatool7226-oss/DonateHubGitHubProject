import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/campaign_controller.dart';
import '../controllers/event_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/reports_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/user_management_controller.dart';
import '../controllers/utilization_controller.dart';
import '../controllers/donor_campaign_controller.dart';
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(
            () => AuthController(), fenix: true);
    Get.lazyPut<CampaignController>(
            () => CampaignController(), fenix: true);
    Get.lazyPut<EventController>(
            () => EventController(), fenix: true);
    Get.lazyPut<InventoryController>(
            () => InventoryController(), fenix: true);
    Get.lazyPut<ReportsController>(
            () => ReportsController(), fenix: true);
    Get.lazyPut<ProfileController>(
            () => ProfileController(), fenix: true);
    Get.lazyPut<UserManagementController>(
            () => UserManagementController(), fenix: true);
    Get.lazyPut<UtilizationController>(
            () => UtilizationController(), fenix: true);
    Get.lazyPut<DonorCampaignController>(
            () => DonorCampaignController(), fenix: true);
  }
}