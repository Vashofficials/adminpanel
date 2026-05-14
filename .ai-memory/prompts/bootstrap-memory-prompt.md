# Bootstrap Memory Prompt

Copy the block below into your AI assistant. The assistant must reply using exactly the four Markdown sections requested at the end.

```text
You are helping populate the DevMemory AI memory store for an existing software project.

Detected technologies: Java / Kotlin (Maven/Gradle), Dart / Flutter, C / C++, Flutter / Mobile App.

Tracked files (these are the only files DevMemory AI has approved for analysis):
- android/app/build.gradle.kts
- android/app/src/debug/AndroidManifest.xml
- android/app/src/main/AndroidManifest.xml
- android/app/src/profile/AndroidManifest.xml
- android/build.gradle.kts
- android/gradle.properties
- android/settings.gradle.kts
- assets/1.mp3
- assets/alert.mp3
- ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md
- ios/Runner/GeneratedPluginRegistrant.h
- ios/Runner/Info.plist
- ios/Runner/Runner-Bridging-Header.h
- lib/config/admin_navigation.dart
- lib/controllers/add_provider_controller.dart
- lib/controllers/auth_controller.dart
- lib/controllers/banking_controller.dart
- lib/controllers/booking_overview_controller.dart
- lib/controllers/booking_report_controller.dart
- lib/controllers/dashboard_controller.dart
- lib/controllers/document_controller.dart
- lib/controllers/holiday_controller.dart
- lib/controllers/individual_provider_dashboard_controller.dart
- lib/controllers/location_controller.dart
- lib/controllers/onboarding_request_controller.dart
- lib/controllers/provider_controller.dart
- lib/controllers/provider_dashboard_controller.dart
- lib/controllers/provider_rating_controller.dart
- lib/controllers/refund_controller.dart
- lib/controllers/transaction_report_controller.dart
- lib/controllers/withdraw_controller.dart
- lib/main.dart
- lib/models/bank_model.dart
- lib/models/booking_models.dart
- lib/models/booking_report_model.dart
- lib/models/buffer_time_model.dart
- lib/models/coupon_model.dart
- lib/models/customer_models.dart
- lib/models/customer_refundbank.dart
- lib/models/data_models.dart
- lib/models/discount_model.dart
- lib/models/document_type_model.dart
- lib/models/employee_model.dart
- lib/models/location_model.dart
- lib/models/module_model.dart
- lib/models/nav_item.dart
- lib/models/permission_module.dart
- lib/models/provider_model.dart
- lib/models/service_provider_location.dart
- lib/models/service_provider_service.dart
- lib/models/slider_banner_model.dart
- lib/repositories/auth_repository.dart
- lib/repositories/booking_repository.dart
- lib/repositories/buffer_repository.dart
- lib/repositories/customer_repository.dart
- lib/repositories/provider_repository.dart
- lib/screens/add_coupon_screen.dart
- lib/screens/add_employee_screen.dart
- lib/screens/add_service_screen.dart
- lib/screens/addprovider/common_widgets.dart
- lib/screens/addprovider/tab_address.dart
- lib/screens/addprovider/tab_documents.dart
- lib/screens/addprovider/tab_financials.dart
- lib/screens/addprovider/tab_location.dart
- lib/screens/addprovider/tab_personal.dart
- lib/screens/addprovider/tab_services.dart
- lib/screens/all_transaction_report_screen.dart
- lib/screens/booking_details_screen.dart
- lib/screens/booking_overview_screen.dart
- lib/screens/booking_report_screen.dart
- lib/screens/buffer_config_screen.dart
- lib/screens/canceled_booking_screen.dart
- lib/screens/CategoryScreen.dart
- lib/screens/completed_booking_screen.dart
- lib/screens/coupon_list_screen.dart
- lib/screens/customer_list.dart
- lib/screens/customer_overview_screen.dart
- lib/screens/customer_update_screen.dart
- lib/screens/customized_booking_screen.dart
- lib/screens/dashboard_screen.dart
- lib/screens/discount_add_screen.dart
- lib/screens/discount_list_screen.dart
- lib/screens/employee_list_screen.dart
- lib/screens/employee_role_list_screen.dart
- lib/screens/employee_role_setup_screen.dart
- lib/screens/holiday_management_screen.dart
- lib/screens/individual_provider_dashboard_screen.dart
- lib/screens/keyword_analytics_screen.dart
- lib/screens/login_screen.dart
- lib/screens/MasterSetupScreen.dart
- lib/screens/module_permssion-screen.dart
- lib/screens/offline_payment_screen.dart
- lib/screens/ongoing_booking_screen.dart
- lib/screens/pending_booking_screen.dart
- lib/screens/personal_details_screen.dart
- lib/screens/promotional_banners_screen.dart
- lib/screens/provider_add_screen.dart
- lib/screens/provider_dashboard_screen.dart
- lib/screens/provider_list_screen.dart
- lib/screens/provider_onboarding_request_screen.dart
- lib/screens/provider_rating_screen.dart
- lib/screens/provider_report_screen.dart
- lib/screens/referral_management_screen.dart
- lib/screens/refund_management_screen.dart
- lib/screens/reschedule_dialog.dart
- lib/screens/role_update_screen.dart
- lib/screens/send_notification_screen.dart
- lib/screens/service_timing_management_screen.dart
- lib/screens/ServiceCategoryScreen.dart
- lib/screens/ServiceScreen.dart
- lib/screens/transaction_report_screen.dart
- lib/screens/update_coupon_screen.dart
- lib/screens/update_discount_screen.dart
- lib/screens/update_promotional_banner_screen.dart
- lib/screens/welcome_dashboard_screen.dart
- lib/screens/withdraw_request_screen.dart
- lib/screens/zone_setup_screen.dart
- lib/services/api_service.dart
- lib/services/booking_notification_service.dart
- lib/services/invoice_service.dart
- lib/services/permission_manager.dart
- lib/widgets/custom_center_dialog.dart
- lib/widgets/dashboard_sidebar.dart
- lib/widgets/dashboard_topbar.dart
- lib/widgets/image_preview_dialog.dart
- lib/widgets/searchable_selection_sheet.dart
- lib/widgets/sidebar_widgets.dart
- linux/CMakeLists.txt
- linux/flutter/CMakeLists.txt
- linux/flutter/generated_plugin_registrant.cc
- linux/flutter/generated_plugin_registrant.h
- linux/runner/CMakeLists.txt
- linux/runner/main.cc
- linux/runner/my_application.cc
- linux/runner/my_application.h
- pubspec.lock
- pubspec.yaml
- README.md
- test/widget_test.dart
- windows/CMakeLists.txt
- windows/flutter/CMakeLists.txt
- windows/flutter/generated_plugin_registrant.cc
- windows/flutter/generated_plugin_registrant.h
- windows/runner/CMakeLists.txt
- windows/runner/flutter_window.cpp
- windows/runner/flutter_window.h
- windows/runner/main.cpp
- windows/runner/resource.h
- windows/runner/utils.cpp
- windows/runner/utils.h
- windows/runner/win32_window.cpp
- windows/runner/win32_window.h

Rules:
- Do not include any secrets, credentials, tokens, environment variables, certificates, private keys, or local database paths.
- Do not invent facts. If something is unclear or unverified, write "Unknown".
- Base your analysis only on the tracked files above and on file contents the user explicitly shares with you.
- If you do not have access to the file contents yet, ask the user to paste the relevant files. Do not guess.
- Keep each section compact, factual, and actionable.

Reply using EXACTLY these four Markdown sections, in this order, with these exact headings (no extras, no surrounding prose):

## PROJECT_SUMMARY
One short paragraph describing what this project is, who it serves, and the main technology stack.

## ARCHITECTURE
Bullet list (or short prose) covering main modules, boundaries, and data flow.

## CURRENT_STATE
Bullets describing what is working, what is in progress, and known issues.

## NEXT_ACTIONS
Bullet list of concrete near-term actions the next AI session should take.
```

After the AI replies, copy the full response and click "Save Project Understanding" in the DevMemory AI sidebar.
