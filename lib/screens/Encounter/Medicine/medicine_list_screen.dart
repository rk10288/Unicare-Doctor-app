import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../components/app_scaffold.dart';
import '../../../components/loader_widget.dart';
import '../../../main.dart';
import '../../../utils/empty_error_state_widget.dart';
import 'medicine_card_component.dart';
import 'medicine_list_controller.dart';
import 'search_medicine_widget.dart';

class MedicinesListScreen extends StatelessWidget {
  MedicinesListScreen({super.key});

  final MedicinesListController medicinesListCont = Get.put(MedicinesListController());

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      appBartitleText: "Medicines",
      isLoading: medicinesListCont.isLoading,
      appBarVerticalSize: Get.height * 0.12,
      actions: [
        IconButton(
          onPressed: () async {
            Get.back(result: medicinesListCont.selectedMedicine.value);
          },
          icon: const Icon(Icons.check, size: 20, color: Colors.white),
        ).paddingOnly(right: 8, top: 12, bottom: 12),
      ],
      body: SizedBox(
        height: Get.height,
        child: Obx(
          () => Column(
            children: [
              SearchMedicineWidget(
                  medicinesListCont: medicinesListCont,
                  onFieldSubmitted: (p0) {
                    hideKeyboard(context);
                  },
                  onClearButton: () {
                    medicinesListCont.searchMedicinesCont.clear();
                    medicinesListCont.getMedicineList();
                  }).paddingSymmetric(horizontal: 16),
              16.height,
              SnapHelperWidget(
                future: medicinesListCont.getMedicines.value,
                loadingWidget: medicinesListCont.isLoading.value ? const Offstage() : const LoaderWidget(),
                errorBuilder: (error) {
                  return NoDataWidget(
                    title: error,
                    retryText: locale.value.reload,
                    imageWidget: const ErrorStateWidget(),
                    onRetry: () {
                      medicinesListCont.medicinePage(1);
                      medicinesListCont.getMedicineList();
                    },
                  );
                },
                onSuccess: (res) {
                  return Obx(
                    () => AnimatedListView(
                      shrinkWrap: true,
                      itemCount: medicinesListCont.medicineList.length,
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      listAnimationType: ListAnimationType.None,
                      emptyWidget: NoDataWidget(
                        title: "No Medicines Found",
                        subTitle: "Oops! Medicines Found at the moment.Please try again later.",
                        imageWidget: const EmptyStateWidget(),
                        onRetry: () {
                          medicinesListCont.medicinePage(1);
                          medicinesListCont.getMedicineList();
                        },
                      ).paddingSymmetric(horizontal: 32).paddingBottom(Get.height * 0.15).visible(!medicinesListCont.isLoading.value),
                      onSwipeRefresh: () async {
                        medicinesListCont.medicinePage(1);
                        return await medicinesListCont.getMedicineList(showloader: false);
                      },
                      onNextPage: () async {
                        if (!medicinesListCont.isMedicineLastPage.value) {
                          medicinesListCont.medicinePage++;
                          medicinesListCont.getMedicineList();
                        }
                      },
                      itemBuilder: (ctx, index) {
                        return MedicineCardWidget(
                          medicinesListCont: medicinesListCont,
                          medicineData: medicinesListCont.medicineList[index],
                        ).paddingBottom(16);
                      },
                    ),
                  );
                },
              ).expand(),
            ],
          ),
        ).paddingTop(16),
      ),
    );
  }
}
