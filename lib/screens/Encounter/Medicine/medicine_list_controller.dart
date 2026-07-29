import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:stream_transform/stream_transform.dart';
import '../../../api/core_apis.dart';
import 'medicine_resp_model.dart';

class MedicinesListController extends GetxController {
  RxBool isLoading = false.obs;

  Rx<Future<RxList<Medicine>>> getMedicines = Future(() => RxList<Medicine>()).obs;
  RxList<Medicine> medicineList = RxList();
  Rx<Medicine> selectedMedicine = Medicine.fromJson({}).obs;
  RxBool isMedicineLastPage = false.obs;
  RxInt medicinePage = 1.obs;

  //Search
  RxBool isSearchMedicinesText = false.obs;
  TextEditingController searchMedicinesCont = TextEditingController();
  StreamController<String> searchMedicinesStream = StreamController<String>();
  final _scrollController = ScrollController();

  @override
  void onReady() {
    _scrollController.addListener(() => Get.context != null ? hideKeyboard(Get.context) : null);
    searchMedicinesStream.stream.debounce(const Duration(seconds: 1)).listen((s) {
      getMedicineList();
    });
    getMedicineList();
    super.onReady();
  }

  getMedicineList({bool showloader = true}) async {
    if (showloader) {
      isLoading(true);
    }
    await getMedicines(CoreServiceApis.getMedicineList(
      search: searchMedicinesCont.text.trim(),
      medicineList: medicineList,
      page: medicinePage.value,
      lastPageCallBack: (p0) {
        isMedicineLastPage(p0);
      },
    )).then((value) {}).catchError((e) {
      log("getClinicList err: $e");
    }).whenComplete(() => isLoading(false));
  }

  @override
  void onClose() {
    searchMedicinesStream.close();
    if (Get.context != null) {
      _scrollController.removeListener(() => hideKeyboard(Get.context));
    }
    super.onClose();
  }
}
