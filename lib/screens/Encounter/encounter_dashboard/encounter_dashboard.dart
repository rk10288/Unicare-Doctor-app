import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import '/screens/Encounter/encounter_dashboard/components/doctor_card_component.dart';
import '/screens/Encounter/encounter_dashboard/encounter_dashboard_controller.dart';
import '../../../components/app_scaffold.dart';
import '../../../main.dart';
import '../model/encounters_list_model.dart';
import '../add_encounter/add_encounter_screen.dart';
import 'components/more_info_component.dart';
import 'components/patient_card_componet.dart';

class EncountersDashboardScreen extends StatelessWidget {
  final EncounterElement encounterDetail;
  EncountersDashboardScreen({super.key, required this.encounterDetail});

  final EncountersDashboardController encountersCont = Get.put(
    EncountersDashboardController(),
  );

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      appBartitleText: locale.value.encounter,
      isLoading: encountersCont.isLoading,
      appBarVerticalSize: Get.height * 0.12,
      actions: [
        IconButton(
          onPressed: () {
            encountersCont.getEncounterInvoice();
          },
          icon: const Icon(Icons.download, size: 24, color: white),
        ).paddingOnly(right: 10).visible(!encounterDetail.status),
        // Create Follow-up Encounter button (if appointment_id exists)
        if (encounterDetail.appointmentId > 0)
          IconButton(
            onPressed: () {
              Get.to(
                () => AddEncounterScreen(),
                arguments: [
                  false, // isEdit
                  encounterDetail.appointmentId, // appointmentId
                ],
              )?.then((value) {
                if (value == true) {
                  Get.back(result: true); // Refresh parent
                }
              });
            },
            icon: const Icon(Icons.add_circle_outline, size: 24, color: white),
            tooltip: 'Create Follow-up Encounter',
          ).paddingOnly(right: 10),
      ],
      body: SizedBox(
        height: Get.height,
        child: AnimatedScrollView(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          padding: const EdgeInsets.all(16),
          listAnimationType: ListAnimationType.Slide,
          children: [
            PatientCardComponent(encounterData: encounterDetail),
            // DoctorCardComponent(encounterData: encounterDetail),
            MoreInfoComponent(encounterData: encounterDetail),
          ],
        ),
      ),
    );
  }
}
